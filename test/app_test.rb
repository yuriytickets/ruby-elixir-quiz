# frozen_string_literal: true

require_relative "test_helper"

class AppTest < QuizTest
  def test_dashboard_renders_empty
    get "/"
    assert last_response.ok?
    assert_includes last_response.body, "Dashboard"
    assert_includes last_response.body, "Streak: <b>0</b>"
  end

  def test_browse_filters
    make_item(title: "Ruby MCQ")
    make_item(title: "Elixir Code", language: "elixir", kind: "code", starter_code: "x", tests: "t", solution: "s")
    get "/items", language: "elixir", kind: "code"
    assert_includes last_response.body, "Elixir Code"
    refute_includes last_response.body, "Ruby MCQ"
    get "/items", q: "ruby"
    assert_includes last_response.body, "Ruby MCQ"
    refute_includes last_response.body, "Elixir Code"
  end

  def test_mcq_attempt_records_and_highlights
    item = make_item
    post "/items/#{item.id}/attempt", choice: "2"
    assert last_response.ok?
    assert_includes last_response.body, "Wrong"
    assert_includes last_response.body, 'class="right"'
    assert_includes last_response.body, 'class="wrong"'
    a = Attempt.first
    refute a.correct
    assert_equal "2", a.response
    assert_equal Date.today, Review[item.id].due_on

    post "/items/#{item.id}/attempt", choice: "1"
    assert_includes last_response.body, "Correct"
    assert_equal 2, Attempt.count
    assert_equal Date.today + 1, Review[item.id].due_on
  end

  def test_open_item_reveal_and_self_grade
    item = make_item(kind: "open", choices: nil, answer: "Model answer here")
    get "/items/#{item.id}"
    refute_includes last_response.body, "Model answer here"
    get "/items/#{item.id}", reveal: "1"
    assert_includes last_response.body, "Model answer here"
    assert_includes last_response.body, 'value="again"'
    post "/items/#{item.id}/attempt", grade: "easy"
    assert Attempt.first.correct
    assert_equal "easy", Attempt.first.response
    post "/items/#{item.id}/attempt", grade: "again"
    refute Attempt.order(:id).last.correct
  end

  def test_code_attempt_runs_tests
    tests = "require \"minitest/autorun\"\nclass T < Minitest::Test\n  def test_a = assert_equal 3, add(1, 2)\nend\n"
    item = make_item(kind: "code", choices: nil, starter_code: "def add(a, b)\nend", tests: tests, solution: "def add(a, b) = a + b")
    post "/items/#{item.id}/attempt", code: "def add(a, b) = a * b"
    assert_includes last_response.body, "Tests failed"
    refute Attempt.first.correct
    post "/items/#{item.id}/attempt", code: "def add(a, b) = a + b"
    assert_includes last_response.body, "All tests passed"
    assert Attempt.order(:id).last.correct
    get "/items/#{item.id}", reveal: "1"
    assert_includes last_response.body, "Reference solution"
  end

  def test_bad_attempt_is_400
    item = make_item
    post "/items/#{item.id}/attempt", grade: "good"
    assert_equal 400, last_response.status
  end

  def test_study_prefers_due_then_new_then_oldest
    due = make_item(title: "due")
    fresh = make_item(title: "fresh")
    old = make_item(title: "old")
    Review.create(item_id: due.id, due_on: Date.today - 1, interval_days: 1, reps: 1)
    Attempt.create(item_id: due.id, correct: false, created_at: Time.now - 60)
    Attempt.create(item_id: old.id, correct: true, created_at: Time.now - 3600)
    Review.create(item_id: old.id, due_on: Date.today + 5, interval_days: 6, reps: 2)

    assert_equal due.id, Item.next_for({}).id
    assert_equal fresh.id, Item.next_for({}, exclude_id: due.id).id
    assert_equal old.id, Item.next_for({ "q" => "old" }).id

    get "/study", language: "ruby"
    assert_equal 302, last_response.status
    assert_includes last_response.location, "/items/#{due.id}?language=ruby"
  end

  def test_study_with_no_match_redirects_to_browse
    get "/study", language: "elixir"
    assert_includes last_response.location, "/items?language=elixir&empty=1"
  end

  def test_interview_walkthrough
    a = make_item(title: "A")
    b = make_item(title: "B", kind: "open", choices: nil, answer: "ans")
    c = make_item(title: "C", kind: "code", choices: nil, starter_code: "", solution: "", tests: "require \"minitest/autorun\"")

    get "/interview/ruby", n: 3
    assert_equal 302, last_response.status
    loc = last_response.location
    assert_match %r{/interview/ruby\?ids=\d+(-\d+){2}&i=0&t=\d+}, loc
    ids = loc[/ids=([\d-]+)/, 1].split("-").map(&:to_i)
    assert_equal [a.id, b.id, c.id].sort, ids.sort

    # step 0 redirects to item with interview params
    get loc
    assert_includes last_response.location, "/items/#{ids[0]}?ids="
    get last_response.location
    assert_includes last_response.body, "Interview question 1 of 3"

    # skip two, answer the third via the summary url shape
    get "/interview/ruby", ids: ids.join("-"), i: 1, r: "s", t: Time.now.to_i - 90
    get "/interview/ruby", ids: ids.join("-"), i: 3, r: "s10", t: Time.now.to_i - 90
    assert last_response.ok?
    body = last_response.body
    assert_includes body, "Interview summary"
    assert_includes body, "<b>1</b><span>correct"
    assert_includes body, "<b>1</b><span>incorrect"
    assert_includes body, "<b>1</b><span>skipped"
    assert_includes body, "1m 30s"
  end

  def test_interview_unknown_language_or_empty
    get "/interview/cobol"
    assert_equal 404, last_response.status
    get "/interview/elixir"
    assert_equal 404, last_response.status
  end

  def test_dashboard_weak_topics_and_streak
    item = make_item(topic: "otp", language: "elixir")
    3.times { Attempt.create(item_id: item.id, correct: false) }
    Attempt.create(item_id: item.id, correct: true, created_at: Time.now - 86_400)
    Attempt.create(item_id: item.id, correct: true, created_at: Time.now - 3 * 86_400)
    get "/"
    assert_includes last_response.body, "Weak spots:"
    assert_includes last_response.body, "topic=otp\">otp</a> (40%)"
    assert_includes last_response.body, "Streak: <b>2</b>"
  end
end
