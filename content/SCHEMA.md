# Content schema

All questions and tasks live in `content/<language>/<topic>.yml`, one file per topic.
`bin/validate_content` enforces everything on this page and **executes every `code` item's
reference solution against its tests**, so a green validator means the bank is trustworthy.

```bash
bin/validate_content                      # whole bank, runs all code items (slow-ish, ~1s per Elixir item)
bin/validate_content content/ruby/blocks.yml
bin/validate_content --no-run             # schema only
```

## File layout

```yaml
language: ruby          # ruby | elixir — must match the directory name
topic: blocks           # must match the file name (without .yml); kebab-case
items:
  - slug: ruby-blocks-yield-basics   # globally unique, ^[a-z]+-[a-z0-9-]+$, must start with "<language>-"
    kind: mcq                         # mcq | open | code | theory
    difficulty: junior                # junior | middle | senior
    title: What does `yield` do without a block?
    body: |                           # markdown; the prompt the learner sees
      ...
    choices: [...]                    # mcq only
    answer: 0                         # mcq: integer index; open/theory: markdown model answer
    explanation: |                    # required for every kind; shown after answering
      ...
    tags: [yield, blocks]             # optional list
    source: https://...               # required: URL or citation ("Ruby docs: Proc", "Elixir Getting Started")
```

## Kinds

| kind     | what the learner does                                   | required fields                           |
|----------|---------------------------------------------------------|-------------------------------------------|
| `mcq`    | picks one of 2–6 choices, auto-graded                   | `choices`, `answer` (int index)            |
| `open`   | explains out loud / in writing, reveals model answer, self-grades | `answer` (markdown)              |
| `code`   | writes code in the browser, runs bundled tests          | `starter_code`, `tests`, `solution`        |
| `theory` | reads a short lesson card, then checks the recap question | `body` is the lesson, `answer` is the recap Q&A |

Every kind also requires `title`, `body`, `explanation`, `difficulty`, `source`.

### `mcq`
- Exactly one correct choice. Distractors must be plausible (things people actually get wrong in interviews).
- `answer` is the 0-based index. Shuffle correct answers across indexes; don't always use 0.
- `explanation` says why the right answer is right **and** why the tempting wrong one is wrong.

### `open`
- `body` is the interview question as an interviewer would ask it (may include a code snippet to discuss).
- `answer` is the model answer: 3–12 lines, the points a strong candidate would hit. Use bullets.
- `explanation` adds follow-up questions the interviewer might ask, or common mistakes.

### `code`
- `body`: task statement with the exact function/module name and signature the tests call, plus 1–2 examples.
- `starter_code`: a stub with the right name/signature and a `# TODO` / `# your code here`.
- `tests`: a complete, self-contained test script fragment that is appended **after** the submission.
- `solution`: the reference solution; the validator runs `solution + tests` and requires exit 0.
- Keep tasks small: 5–20 lines of solution. Interview-style: string/collection manipulation, recursion,
  pattern matching, small data transforms, a tiny GenServer/class, parsing, etc.
- Tests must not depend on the network, the filesystem, randomness or time.

**Ruby tests** must start with `require "minitest/autorun"` and define a `Minitest::Test` class:

```ruby
require "minitest/autorun"

class SolutionTest < Minitest::Test
  def test_adds
    assert_equal 3, add(1, 2)
  end
end
```

**Elixir tests** must start with `ExUnit.start()` and define an `ExUnit.Case` module. The submission
defines a module (default name `Solution`) that the tests call:

```elixir
ExUnit.start()

defmodule SolutionTest do
  use ExUnit.Case

  test "adds" do
    assert Solution.add(1, 2) == 3
  end
end
```

Elixir note: the whole file is one `.exs` script run with `elixir run.exs`. Do not call `Mix` or use
`use Mix.Project`; stdlib only (`Enum`, `Map`, `String`, `GenServer`, `Agent`, `Task`, `Regex`, …).
Ruby note: run with `ruby -W0 run.rb`; stdlib only (`set`, `json`, `date`, `bigdecimal` are fine).

### `theory`
- `body` is a compact lesson (10–30 lines of markdown with a code example) on one concept.
- `answer` is a one-question recap in the form `**Q:** … **A:** …` so the card can be self-graded.
- Good for things interviewers expect you to *explain*: method lookup path, GIL, BEAM scheduler,
  supervision strategies, Ecto changeset pipeline, ActiveRecord callbacks order, etc.

## Difficulty guide

- `junior`: syntax and semantics, what prints, standard library basics, definitions.
- `middle`: idioms, trade-offs, framework internals you use daily, debugging reasoning, small design.
- `senior`: internals (GC, VM, scheduler), performance, architecture, failure modes, "how would you design…".

Aim per topic file for roughly 30% junior / 45% middle / 25% senior and a mix of kinds
(about 35% mcq, 30% open, 20% code, 15% theory; `code` can be lower on pure-theory topics such as
"beam-vm" and higher on "coding-tasks").

## Quality bar

- Questions must be ones that actually come up in Ruby / Elixir interviews or that test knowledge
  interviewers probe. Prefer "why / what happens / compare" over trivia.
- Every item needs a `source`: official docs, a well-known interview-question list, a conference talk,
  a book, or a blog post you actually consulted. Facts in `answer` / `explanation` must be correct for
  Ruby 3.3 / Rails 7.x and Elixir 1.17+ / OTP 26+ / Phoenix 1.7.
- Markdown: use fenced code blocks with a language tag (```ruby, ```elixir). Use YAML `|` block scalars
  for any multi-line field. No tabs.
- Slugs are permanent identifiers: the database upserts by slug, so renaming a slug orphans history.
