# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/sm2"

class SM2Test < Minitest::Test
  TODAY = Date.new(2026, 11, 3)
  FRESH = { ease: 2.5, interval_days: 0, reps: 0 }.freeze

  def test_first_good_is_due_tomorrow
    s = SM2.next(FRESH, "good", today: TODAY)
    assert_equal 1, s[:interval_days]
    assert_equal TODAY + 1, s[:due_on]
    assert_equal 1, s[:reps]
  end

  def test_second_good_is_six_days
    s = SM2.next(SM2.next(FRESH, "good", today: TODAY), "good", today: TODAY)
    assert_equal 6, s[:interval_days]
  end

  def test_again_resets_and_is_due_today
    s = SM2.next({ ease: 2.5, interval_days: 10, reps: 3 }, "again", today: TODAY)
    assert_equal 0, s[:interval_days]
    assert_equal 0, s[:reps]
    assert_equal TODAY, s[:due_on]
    assert_operator s[:ease], :<, 2.5
  end

  def test_ease_never_below_floor
    s = FRESH
    10.times { s = SM2.next(s, "again", today: TODAY) }
    assert_equal 1.3, s[:ease]
  end

  def test_easy_raises_ease
    assert_operator SM2.next(FRESH, "easy", today: TODAY)[:ease], :>, 2.5
  end
end
