# frozen_string_literal: true

ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "rack/test"
require_relative "../app"
require_relative "../lib/seed"

Sequel.extension :migration
Sequel::Migrator.run(DB, File.expand_path("../db/migrations", __dir__))

class QuizTest < Minitest::Test
  include Rack::Test::Methods

  FIXTURES = File.expand_path("fixtures/content", __dir__)

  def app = App

  def setup
    DB[:items].delete # cascades to attempts and reviews
  end

  def make_item(**attrs)
    defaults = { slug: "ruby-t-#{SecureRandom.hex(4)}", language: "ruby", topic: "t", kind: "mcq", difficulty: "junior",
                 title: "T", body: "B", choices: Sequel.pg_jsonb(%w[a b c]), answer: "1", explanation: "E", source: "s" }
    Item.create(defaults.merge(attrs))
  end
end
require "securerandom"
