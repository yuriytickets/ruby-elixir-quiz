## Context

Greenfield, single-user, runs on the owner's Mac. Ruby 3.3, PostgreSQL 16 and an Elixir 1.19 / OTP 27
pair are already installed via asdf (the global Elixir shim is broken against the global Erlang, so the
project pins a working pair in `.tool-versions`). See proposal.md for motivation; the specs under
`specs/` are the behaviour contract.

## Goals / Non-Goals

**Goals:**
- Smallest app that satisfies the specs; everything server-rendered.
- Content is the asset: human-readable YAML, validated and test-backed, reviewable in a PR.
- Reproducible from a clean clone with three commands.

**Non-Goals:**
- Hardened sandboxing, multi-tenancy, deploy pipeline, API for other clients.

## Decisions

**Sinatra (modular) + Sequel + pg over Rails.** The surface is six pages and four POST actions; Rails
would add generators, asset pipeline and ~60 gems for no benefit. Sequel gives migrations, a query DSL
and `insert_conflict` for the slug upsert. Alternative: Roda — equally small but less familiar to
interviewers reading the repo.

**Four item kinds in one `items` table with nullable kind-specific columns.** `choices` is `jsonb`,
`tags` is `text[]`. One table keeps queries trivial (`WHERE language=? AND topic=?`). Alternative:
STI-style tables per kind — more joins, nothing gained at this size.

**Attempts are append-only; review state is one row per item (`reviews`).** Attempts feed the dashboard,
reviews feed scheduling. Keeping them apart avoids recomputing SM-2 from history.

**SM-2 in ~15 lines in `lib/sm2.rb`.** Well-known, good enough for a 30-day horizon. Grades: again=0,
hard=3, good=4, easy=5 on the SM-2 quality scale. Alternative: FSRS — better but far more code.

**Mock interview state lives in the URL** (`/interview/ruby?ids=1,5,9&i=2&score=2.1.0`). No session
table, no cookies beyond Rack's. Ceiling: not shareable across devices, which is fine.

**Code runner = `Open3.capture3` + `Timeout` + `Dir.mktmpdir`.** Ruby: `ruby -W0 run.rb` where
`run.rb` = submission + `\n` + tests (tests start with `require "minitest/autorun"`). Elixir:
`elixir run.exs` where the file = submission + tests (tests start with `ExUnit.start()`). Environment
is scrubbed to `PATH`, `HOME`, `LANG` plus the asdf version variables from `.tool-versions`.
`ponytail:` no seccomp/containers; this is the owner's machine running the owner's code.

**Markdown via kramdown + rouge.** Pure Ruby, fenced code with syntax highlight, no native build.

**Content validator is dependency-free** (`bin/validate_content`, stdlib YAML only) so content
authors — including the parallel generation agents — can run it without Postgres.

**Seed = upsert by slug** (`INSERT ... ON CONFLICT (slug) DO UPDATE`). Items removed from YAML are
left in the DB on purpose so history is never lost; `rake db:prune` can delete them explicitly.

### Data model

```
items     id, slug UNIQUE, language, topic, kind, difficulty, title, body, choices jsonb,
          answer text, explanation, starter_code, tests, solution, tags text[], source, created_at
attempts  id, item_id FK, correct bool, response text, created_at
reviews   item_id PK FK, ease real (2.5), interval_days int (0), reps int (0), due_on date
```

Indexes: `items(language, topic)`, `attempts(item_id)`, `attempts(created_at)`, `reviews(due_on)`.

### Routes

```
GET  /                         dashboard
GET  /items                    browse + filters
GET  /items/:id                show one item (+ attempt history, reveal answer)
POST /items/:id/attempt        mcq choice | self grade | code submission
GET  /study                    redirect to next item for the filter
GET  /interview/:language      start (picks ids) or step (ids,i) or summary
```

### Content layout

```
content/
  SCHEMA.md                    the item format, authoring rules, test conventions
  ruby/<topic>.yml             ~14 topics
  elixir/<topic>.yml           ~14 topics
```

## Risks / Trade-offs

- [Generated content may contain wrong answers] → every `code` item is executed by the validator;
  `mcq`/`open` items carry a `source` URL and are spot-checked; mistakes are one YAML edit away.
- [Elixir toolchain drift] → `.tool-versions` pins the working pair; runner reports a missing binary
  instead of crashing.
- [Running arbitrary code from the browser] → local-only app bound to 127.0.0.1; documented in README.
- [YAML size] → ~1000 items ≈ 1–2 MB; seeding takes seconds; acceptable.

## Migration Plan

Fresh project: `bundle install && bundle exec rake db:setup db:seed && bundle exec rackup`.
Rollback is `rake db:drop`.
