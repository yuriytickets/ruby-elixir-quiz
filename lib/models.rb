# frozen_string_literal: true

require_relative "db"

LANGUAGES = %w[ruby elixir].freeze
KINDS = %w[mcq open code theory].freeze
DIFFICULTIES = %w[junior middle senior].freeze

class Item < Sequel::Model
  one_to_many :attempts, order: Sequel.desc(:created_at)
  one_to_one :review

  dataset_module do
    # f: hash with optional string keys language/topic/kind/difficulty/q
    def filtered(f)
      ds = self
      %w[language topic kind difficulty].each do |k|
        ds = ds.where(Sequel[:items][k.to_sym] => f[k]) if f[k] && !f[k].empty?
      end
      ds = ds.where(Sequel.ilike(Sequel[:items][:title], "%#{f['q']}%")) if f["q"] && !f["q"].empty?
      ds
    end
  end

  def mcq? = kind == "mcq"
  def code? = kind == "code"
  def self_graded? = kind == "open" || kind == "theory"
  def correct_choice = answer.to_i

  # Due items first, then never attempted, then least recently attempted.
  def self.next_for(filter, exclude_id: nil)
    last = DB[:attempts].select_group(:item_id).select_append { max(created_at).as(:last_at) }
    ds = filtered(filter)
         .left_join(:reviews, item_id: Sequel[:items][:id])
         .left_join(last.as(:a), item_id: Sequel[:items][:id])
         .select_all(:items)
    ds = ds.exclude(Sequel[:items][:id] => exclude_id) if exclude_id
    ds.order(
      Sequel.desc(Sequel.lit("coalesce(reviews.due_on <= current_date, false)")),
      Sequel.asc(Sequel[:a][:last_at], nulls: :first),
      Sequel.function(:random)
    ).first
  end

  # Mixed set for a mock interview: at least one code and one open item when available.
  def self.pick_interview(language, n)
    base = where(language: language)
    must = %w[code open].filter_map { |k| base.where(kind: k).order(Sequel.function(:random)).get(:id) }
    rest = base.exclude(id: must).order(Sequel.function(:random)).limit([n - must.size, 0].max).select_map(:id)
    (must + rest).shuffle
  end
end

class Attempt < Sequel::Model
  many_to_one :item
end

class Review < Sequel::Model
  unrestrict_primary_key
  many_to_one :item
end

# Records an attempt and reschedules the item with SM-2.
def record_attempt(item, correct:, response:, grade:)
  Attempt.create(item_id: item.id, correct: correct, response: response)
  review = Review[item.id] || Review.new(item_id: item.id, ease: 2.5, interval_days: 0, reps: 0)
  review.set(SM2.next({ ease: review.ease, interval_days: review.interval_days, reps: review.reps }, grade))
  review.save
end
