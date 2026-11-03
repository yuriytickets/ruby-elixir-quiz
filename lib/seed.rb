# frozen_string_literal: true

require "yaml"
require_relative "db"

# Upserts content/**/*.yml into items by slug. Attempts/reviews attached to a slug survive re-seeding.
module Seed
  COLUMNS = %i[language topic kind difficulty title body choices answer explanation starter_code tests solution tags source].freeze

  def self.rows(dir)
    Dir[File.join(dir, "*", "*.yml")].sort.flat_map do |file|
      data = YAML.safe_load_file(file)
      data["items"].map do |it|
        {
          slug: it["slug"], language: data["language"], topic: data["topic"], kind: it["kind"],
          difficulty: it["difficulty"], title: it["title"], body: it["body"],
          choices: it["choices"] && Sequel.pg_jsonb(it["choices"]),
          answer: it["answer"]&.to_s, explanation: it["explanation"],
          starter_code: it["starter_code"], tests: it["tests"], solution: it["solution"],
          tags: Sequel.pg_array(Array(it["tags"]).map(&:to_s), :text), source: it["source"]
        }
      end
    end
  end

  def self.run(dir = File.expand_path("../content", __dir__))
    rows = rows(dir)
    update = COLUMNS.to_h { |c| [c, Sequel[:excluded][c]] }
    rows.each_slice(200) do |batch|
      DB[:items].insert_conflict(target: :slug, update: update).multi_insert(batch)
    end
    rows.size
  end

  # Deletes DB items whose slug no longer exists in the content directory.
  def self.prune(dir = File.expand_path("../content", __dir__))
    DB[:items].exclude(slug: rows(dir).map { _1[:slug] }).delete
  end
end
