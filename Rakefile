# frozen_string_literal: true

require "rake/testtask"
require "uri"

def db_name(env = ENV.fetch("RACK_ENV", "development"))
  ENV["DATABASE_URL"] ? URI(ENV["DATABASE_URL"]).path.delete_prefix("/") : "ruby_elixir_quiz_#{env}"
end

# Connects to the maintenance database on the same server (no reliance on createdb/dropdb being on PATH).
def admin_db
  require "sequel"
  url = ENV.fetch("DATABASE_URL", "postgres://localhost/x").sub(%r{/[^/]*\z}, "/postgres")
  Sequel.connect(url)
end

def createdb(name)
  admin_db.run("CREATE DATABASE #{admin_db.literal(Sequel.identifier(name))}")
  puts "created database #{name}"
rescue Sequel::DatabaseError => e
  raise unless e.message.include?("already exists")
  puts "database #{name} already exists"
end

def dropdb(name)
  admin_db.run("DROP DATABASE IF EXISTS #{admin_db.literal(Sequel.identifier(name))}")
  puts "dropped database #{name}"
end

def migrate
  require_relative "lib/db"
  Sequel.extension :migration
  Sequel::Migrator.run(DB, File.join(__dir__, "db/migrations"))
  puts "migrated #{db_name}"
end

namespace :db do
  desc "Create the database"
  task(:create) { createdb(db_name) }

  desc "Drop the database"
  task(:drop) { dropdb(db_name) }

  desc "Run migrations"
  task(:migrate) { migrate }

  desc "Create + migrate"
  task setup: %i[create migrate]

  desc "Upsert content/**/*.yml into the database (idempotent by slug)"
  task :seed do
    require_relative "lib/seed"
    puts "seeded #{Seed.run} items"
  end

  desc "Delete items whose slug is no longer in content/"
  task :prune do
    require_relative "lib/seed"
    puts "pruned #{Seed.prune} items"
  end

  desc "Create + migrate the test database"
  task :test_prepare do
    ENV["RACK_ENV"] = "test"
    createdb(db_name("test"))
    migrate
  end
end

desc "Print item counts per language, topic, kind and difficulty"
task :stats do
  require_relative "lib/db"
  %w[ruby elixir].each do |lang|
    ds = DB[:items].where(language: lang)
    puts "#{lang}: #{ds.count} items"
    %i[kind difficulty topic].each do |col|
      row = ds.group_and_count(col).order(col).map { |r| "#{r[col]}=#{r[:count]}" }
      puts "  #{col.to_s.ljust(10)} #{row.join('  ')}"
    end
  end
end

desc "Validate content and run code items (same as bin/validate_content)"
task(:validate) { sh "bin/validate_content" }

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end
task test: "db:test_prepare"
task default: :test
