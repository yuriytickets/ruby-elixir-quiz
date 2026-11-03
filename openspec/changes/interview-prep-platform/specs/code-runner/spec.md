## Purpose

Executes a learner's Ruby or Elixir submission against an item's bundled tests on the local machine
and returns the outcome, so coding tasks give the same feedback loop as a real interview exercise.

## ADDED Requirements

### Requirement: Submissions run against item tests
The runner SHALL combine the submission with the item's `tests`, execute it with the language's
interpreter, and return exit status, stdout and stderr.

#### Scenario: Ruby submission
- **WHEN** a Ruby submission is executed
- **THEN** the combined script is run with `ruby` and Minitest output is returned

#### Scenario: Elixir submission
- **WHEN** an Elixir submission is executed
- **THEN** the combined script is run with `elixir` as an `.exs` script and ExUnit output is returned

### Requirement: Execution is bounded
Each run SHALL be killed after 10 seconds and its output truncated to 20 000 characters. Runs SHALL
happen in a fresh temporary directory that is deleted afterwards.

#### Scenario: Infinite loop
- **WHEN** a submission never terminates
- **THEN** the runner returns a failure with a "timed out" message within ~10 seconds

### Requirement: Missing interpreter is reported, not crashed
If the language interpreter is not available, the runner SHALL return a failure explaining which binary
is missing and how to install it.

#### Scenario: Elixir not installed
- **WHEN** `elixir` is not on PATH
- **THEN** the item page shows a message naming `elixir` and the pinned version in `.tool-versions`
