# frozen_string_literal: true

require "sequel"

ENV["RACK_ENV"] ||= "development"
DATABASE_URL = ENV.fetch("DATABASE_URL") { "postgres://localhost/ruby_elixir_quiz_#{ENV['RACK_ENV']}" }
DB = Sequel.connect(DATABASE_URL)
DB.extension :pg_array, :pg_json
