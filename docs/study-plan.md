# 30-day study plan

Goal: walk into Ruby and Elixir interviews able to *explain* the fundamentals out loud, *reason*
about internals and trade-offs, and *write* small idiomatic solutions under time pressure.

Each day: ~45 minutes. Dashboard → clear "due today" for both languages → new items in the day's
focus topic → one coding task. Grade honestly; the scheduler only works if `again` means "again".

## Week 1 — language cores

| Day | Ruby | Elixir |
|---|---|---|
| 1 | core-language | core-language |
| 2 | oop-and-modules | pattern-matching-and-control-flow |
| 3 | blocks-procs-lambdas | functions-modules-protocols |
| 4 | collections-and-enumerable | collections-enum-stream |
| 5 | errors-and-exceptions | processes-and-messaging |
| 6 | coding-tasks (junior) | coding-tasks (junior) |
| 7 | mock interview + review misses | mock interview + review misses |

## Week 2 — runtime and concurrency

| Day | Ruby | Elixir |
|---|---|---|
| 8 | concurrency | genserver-and-otp-behaviours |
| 9 | memory-gc-performance | supervision-and-fault-tolerance |
| 10 | metaprogramming | beam-vm-and-runtime |
| 11 | coding-tasks (middle) | coding-tasks (middle) |
| 12 | review weakest topic | review weakest topic |
| 13 | mock interview | mock interview |
| 14 | rest / due queue only | rest / due queue only |

## Week 3 — frameworks and tooling

| Day | Ruby | Elixir |
|---|---|---|
| 15 | rails-activerecord | ecto |
| 16 | rails-web-layer | phoenix |
| 17 | testing | testing |
| 18 | tooling-and-modern-ruby | tooling-and-ecosystem |
| 19 | design-and-architecture | macros-and-metaprogramming |
| 20 | coding-tasks (senior) | coding-tasks (senior) |
| 21 | mock interview | mock interview |

## Week 4 — consolidation

- Days 22–26: due queue + the two weakest topics per language from the dashboard, alternating.
  Re-do every `code` item you failed on the first pass without looking at the solution.
- Days 27–28: two mock interviews per day, one per language, timed. Say answers out loud.
- Days 29–30: skim all `theory` cards (`/items?kind=theory`) as a final sweep; only the due queue.

## Interview-day checklist

- Ruby: object model and method lookup, blocks/procs/lambdas, GVL and threads, GC basics,
  ActiveRecord query pitfalls (N+1, callbacks, transactions), RSpec doubles, SOLID in Ruby terms.
- Elixir: immutability and pattern matching, processes/links/monitors, GenServer call vs cast,
  supervision strategies, BEAM scheduling and per-process GC, Ecto changesets and Multi,
  Phoenix request lifecycle and LiveView mount.
- Both: complexity of common operations, how you would debug a production incident, a system you
  designed and what you would change.
