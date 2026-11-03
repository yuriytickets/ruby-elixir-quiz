# frozen_string_literal: true

require_relative "test_helper"

class SeedTest < QuizTest
  def test_seed_is_idempotent_and_keeps_history
    assert_equal 3, Seed.run(FIXTURES)
    assert_equal 3, Item.count
    item = Item.first(slug: "ruby-sample-mcq")
    assert_equal %w[0 nil ""], item.choices
    assert_equal "1", item.answer
    assert_equal ["truthiness"], item.tags.to_a
    record_attempt(item, correct: true, response: "1", grade: "good")

    Seed.run(FIXTURES)
    assert_equal 3, Item.count
    assert_equal 1, Attempt.count
    assert_equal 1, Review.count
  end

  def test_prune_removes_items_missing_from_content
    Seed.run(FIXTURES)
    make_item(slug: "ruby-gone-item")
    assert_equal 1, Seed.prune(FIXTURES)
    assert_nil Item.first(slug: "ruby-gone-item")
  end
end
