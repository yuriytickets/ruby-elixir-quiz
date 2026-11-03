# frozen_string_literal: true

require "date"

# SuperMemo-2 scheduling. Grades map to SM-2 quality: again=0 hard=3 good=4 easy=5.
# State is a hash with :ease, :interval_days, :reps; returns the next state plus :due_on.
module SM2
  GRADES = { "again" => 0, "hard" => 3, "good" => 4, "easy" => 5 }.freeze
  MIN_EASE = 1.3

  def self.next(state, grade, today: Date.today)
    q = GRADES.fetch(grade)
    ease = state.fetch(:ease, 2.5)
    interval = state.fetch(:interval_days, 0)
    reps = state.fetch(:reps, 0)

    if q < 3
      reps = 0
      interval = 0
    else
      interval = case reps
                 when 0 then 1
                 when 1 then 6
                 else (interval * ease).round
                 end
      reps += 1
    end
    ease = [MIN_EASE, ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))].max

    { ease: ease.round(2), interval_days: interval, reps: reps, due_on: today + interval }
  end
end
