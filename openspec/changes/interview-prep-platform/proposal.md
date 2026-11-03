## Why

I have one month to prepare for Ruby and Elixir developer interviews and need a single place to drill
theory questions, multiple-choice checks, and small coding tasks with instant feedback. Scattered blog
lists are not interactive, do not track weak spots, and cannot run my code. Building the tool itself in
Ruby + PostgreSQL also doubles as a portfolio project I can push to GitHub.

## What Changes

- New Sinatra web app (`app.rb`) backed by PostgreSQL via Sequel, single local user, no auth.
- New versioned content bank: ≥500 items per language under `content/<lang>/<topic>.yml`, each item
  one of four kinds: `mcq` (multiple choice), `open` (explain, then self-grade against a model answer),
  `code` (write code, run against bundled tests), `theory` (short lesson card with a recap question).
- New seed task that upserts YAML items into Postgres by stable slug, so content edits are re-seedable.
- New study flow: filter by language / topic / kind / difficulty, answer, see explanation + source link.
- New code runner that executes Ruby (Minitest) and Elixir (ExUnit) submissions in a sandboxed
  subprocess with a timeout and shows the test output.
- New spaced-repetition scheduling (SM-2) driven by self-grades, with a "due today" queue.
- New mock-interview mode: a fixed-length, mixed session with a result summary.
- New progress dashboard: accuracy and coverage per language / topic / difficulty, weakest topics.
- New content validator (`bin/validate_content`) that checks schema and runs every `code` item's
  reference solution against its tests, so the bank stays green.

## Capabilities

### New Capabilities
- `content-bank`: the item format, its validation rules, and the seed/upsert behaviour.
- `study-session`: browsing, filtering, answering items and recording attempts.
- `code-runner`: executing Ruby / Elixir submissions against item tests with limits.
- `spaced-repetition`: scheduling reviews from self-grades and serving the due queue.
- `progress-dashboard`: aggregate statistics and weak-spot reporting.
- `mock-interview`: fixed-length mixed sessions with a summary.

### Modified Capabilities
<!-- none: greenfield project -->

## Non-goals

- Multi-user accounts, authentication, or deployment to a public host.
- A JavaScript front-end framework, websockets, or background job queue.
- Hardened sandboxing for untrusted code: the runner is for the owner's own machine only.
- Automatic grading of `open` answers by an LLM.

## Success criteria

- `bundle exec rake db:setup db:seed` loads ≥500 Ruby and ≥500 Elixir items; `rake stats` prints the
  counts per language, topic and kind.
- `bin/validate_content` exits 0: every YAML item passes schema checks and every `code` item's
  reference solution passes its tests in both languages.
- From a browser I can filter, answer each kind of item, run code, self-grade, and see my dashboard
  update; `bundle exec rake test` is green.

## Impact

- New repository; no existing code affected.
- Runtime dependencies: Ruby 3.3, PostgreSQL 16, Elixir 1.19 / OTP 27 (only for Elixir code tasks).
- Gems: sinatra, puma, sequel, pg, kramdown, rouge, rake, minitest, rack-test.
