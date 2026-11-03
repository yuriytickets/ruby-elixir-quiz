## 1. Project skeleton

- [x] 1.1 Add `Gemfile`, `.tool-versions`, `.gitignore`, `config.ru`, `Rakefile`; verify `bundle install` and `bundle exec rake -T` succeed
- [x] 1.2 Add `db/migrations/001_initial.rb` creating `items`, `attempts`, `reviews`; verify `rake db:setup` creates the tables (`psql -c '\dt'`)

## 2. Content bank

- [x] 2.1 Write `content/SCHEMA.md` describing fields, kinds, test conventions and difficulty guide; verify it matches `specs/content-bank`
- [x] 2.2 Write `bin/validate_content` (stdlib only) enforcing schema, unique slugs and running `code` solutions; verify it fails on a deliberately broken fixture and passes on a good one
- [x] 2.3 Author ≥500 Ruby items across ~14 topics in `content/ruby/*.yml`; verify `bin/validate_content` exits 0 and reports ≥500
- [x] 2.4 Author ≥500 Elixir items across ~14 topics in `content/elixir/*.yml`; verify `bin/validate_content` exits 0 and reports ≥500
- [x] 2.5 Implement `rake db:seed` as a slug upsert and `rake stats`; verify re-running seed does not change row counts and stats prints per-language totals

## 3. Application

- [x] 3.1 Implement `app.rb` with models (`lib/models.rb`), markdown helper and layout; verify `GET /` renders
- [x] 3.2 Implement browse (`GET /items`) with filters and search; verify filtered lists in rack-test
- [x] 3.3 Implement item page and `POST /items/:id/attempt` for mcq / self-grade; verify attempts are recorded in tests
- [x] 3.4 Implement `lib/runner.rb` and wire `code` attempts; verify a passing and a failing Ruby and Elixir submission plus a timeout in tests
- [x] 3.5 Implement `lib/sm2.rb` and review updates; verify unit tests for first pass, lapse and ease floor
- [x] 3.6 Implement `GET /study` next-item ordering (due → new → oldest); verify ordering test
- [x] 3.7 Implement mock interview routes and summary; verify a 3-item walkthrough in rack-test
- [x] 3.8 Implement dashboard aggregates, weak topics, daily activity and streak; verify streak test

## 4. Docs and release

- [x] 4.1 Write `README.md` (setup, usage, content authoring, architecture, screenshots-free); verify a clean clone follows it successfully
- [x] 4.2 Write `docs/` pages: study strategy for the month, content coverage map, decision log pointer to openspec; verify links resolve
- [x] 4.3 `git init`, initial commit with `.gitignore`; verify `git status` clean and `bundle exec rake test` green
