# Ruby & Elixir Interview Prep

A self-hosted drill tool for Ruby and Elixir developer interviews: multiple-choice checks, open
"explain it to the interviewer" questions, short theory cards, and coding tasks you solve in the
browser and run against real tests. Progress is tracked per topic with spaced repetition, and a mock
interview mode throws a mixed set at you with a timer.

Built with Ruby 3.3, Sinatra, Sequel and PostgreSQL. The content bank (1000+ items, YAML) is the
real asset; the app is the thinnest thing that makes it interactive.

## Features

- **Four item kinds**: `mcq` (auto-graded), `open` (reveal model answer, self-grade),
  `theory` (lesson card + recap), `code` (editor + Minitest / ExUnit run in a sandboxed subprocess).
- **Study mode** picks the next item for any filter: due reviews first, then unseen, then oldest.
- **Spaced repetition** (SM-2) from your self-grades. The dashboard shows what is due today.
- **Mock interview**: 10 mixed questions per language, skip or answer, summary with timing.
- **Dashboard**: per-topic coverage and accuracy, weakest topics, 30-day activity, streak.
- **Versioned content**: `content/<language>/<topic>.yml`, validated and executed by
  `bin/validate_content`; reseeding is an upsert by slug so your history is never lost.

## Setup

Requirements: Ruby 3.3, PostgreSQL 14+ running locally, and (for Elixir coding tasks) Elixir 1.17+
with OTP 26+. Versions are pinned in [.tool-versions](.tool-versions) for asdf.

```bash
bundle install
bundle exec rake db:setup       # creates ruby_elixir_quiz_development and runs migrations
bundle exec rake db:seed        # loads content/**/*.yml (idempotent)
bundle exec rackup              # http://127.0.0.1:9292
```

Set `DATABASE_URL` to use another server, e.g. `postgres://user:pass@host/dbname`.

Other tasks:

```bash
bundle exec rake stats          # item counts per language / topic / kind / difficulty
bundle exec rake test           # creates + migrates the test DB, runs Minitest
bin/validate_content            # schema check + executes every code item's reference solution
bin/content_map                 # regenerate docs/content-map.md
bundle exec rake db:prune       # delete DB items whose slug was removed from content/
```

## How to use it for a month

See [docs/study-plan.md](docs/study-plan.md) for a week-by-week plan. The short version:

1. **Daily, 30–45 min**: open the dashboard, clear the "due today" queue for both languages, then
   study 10–15 new items in the topic you are weakest in.
2. **Grade honestly** on open/theory cards: `again` if you could not say it out loud, `hard` if
   you got the gist but missed key points, `good` if you nailed it, `easy` if it is trivial.
3. **Code tasks**: write the solution before looking at the reference, run tests, then read the
   explanation for the idiomatic version and complexity notes.
4. **Twice a week**: a mock interview per language. Review every ❌ and ⏭ item from the summary.

## Content

Every item lives in `content/<language>/<topic>.yml` and follows [content/SCHEMA.md](content/SCHEMA.md).
Items have a stable `slug`, a `kind`, a `difficulty` (junior / middle / senior), markdown `body`,
an `explanation` and a `source` link. Code items also carry `starter_code`, `tests` and a reference
`solution` that the validator executes, so a green `bin/validate_content` means every task is
solvable as stated.

Topic coverage is listed in [docs/content-map.md](docs/content-map.md) (regenerate with `bin/content_map`).

To add or fix content: edit the YAML, run `bin/validate_content content/<lang>/<topic>.yml`, then
`bundle exec rake db:seed`.

## Architecture

```
app.rb                 Sinatra routes + view helpers (markdown, filters, interview state)
lib/models.rb          Sequel models: Item, Attempt, Review; next-item and interview selection
lib/sm2.rb             SM-2 scheduling (pure function)
lib/runner.rb          runs submission + tests with `ruby` / `elixir` under a timeout (stdlib only)
lib/seed.rb            YAML -> items upsert by slug
bin/validate_content   content linter + executor, no DB needed
db/migrations/         Sequel migrations (items, attempts, reviews)
views/                 ERB: layout, dashboard, items (browse), item, interview_summary
content/               the question bank
openspec/              proposal, specs, design and tasks for this project (spec-driven workflow)
test/                  Minitest + rack-test
```

Design decisions and the behaviour specs are in
[openspec/changes/interview-prep-platform](openspec/changes/interview-prep-platform/):
`proposal.md` (why), `specs/*/spec.md` (what, as testable scenarios), `design.md` (how),
`tasks.md` (the checklist that was followed).

The app binds to `127.0.0.1` and runs whatever you type in the code editor on your machine; it is a
personal tool, not something to expose publicly.

## Routes

| Route | Purpose |
|---|---|
| `GET /` | dashboard |
| `GET /items` | browse with filters (`language`, `topic`, `kind`, `difficulty`, `q`, `page`) |
| `GET /items/:id` | one item; `reveal=1` shows the answer / solution |
| `POST /items/:id/attempt` | `choice=` (mcq), `grade=` (open/theory), `code=` (code) |
| `GET /study` | redirects to the next item for the current filter |
| `GET /interview/:language` | starts a mock interview; `n=` sets the length |

## License

MIT for the code. Content items cite their sources; see each item's `source` field.
