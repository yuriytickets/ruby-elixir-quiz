## Purpose

Lets the learner find items by language, topic, kind and difficulty, answer them, and get immediate
feedback with an explanation and source, recording each attempt for progress tracking.

## ADDED Requirements

### Requirement: Items can be filtered and browsed
The system SHALL list items filtered by any combination of language, topic, kind, difficulty and
free-text search over title, showing the learner's last result per item.

#### Scenario: Filter by language and kind
- **WHEN** the learner requests `language=elixir` and `kind=code`
- **THEN** only Elixir code items are listed with their title, difficulty and last result

### Requirement: Study mode serves the next item
"Study" SHALL pick the next item for the current filter, preferring items that are due for review, then
never-attempted items, then the least recently attempted.

#### Scenario: Unattempted items come before attempted ones
- **WHEN** the filter matches one attempted and one unattempted item, neither due
- **THEN** the unattempted item is served first

### Requirement: MCQ items are auto-graded
Submitting a choice SHALL record an attempt as correct or incorrect, reveal the right choice and show the
explanation and source link.

#### Scenario: Wrong choice
- **WHEN** the learner submits choice 2 and the answer index is 0
- **THEN** an incorrect attempt is recorded and choices 0 (correct) and 2 (chosen) are highlighted

### Requirement: Open and theory items are self-graded
After the learner reveals the model answer, they SHALL grade themselves on a 4-point scale
(again / hard / good / easy); `good` and `easy` count as correct attempts.

#### Scenario: Self-grade "again"
- **WHEN** the learner reveals the answer and picks "again"
- **THEN** an incorrect attempt is recorded and the item becomes due again today

### Requirement: Code items are graded by test outcome
Submitting code SHALL run it through the code runner; an attempt is correct iff all tests pass. The
learner MAY reveal the reference solution at any time.

#### Scenario: All tests pass
- **WHEN** the runner reports exit status 0
- **THEN** a correct attempt is recorded and the test output is shown

### Requirement: Every attempt is persisted
Each attempt SHALL store the item, correctness, the learner's response (choice index, self-grade or
submitted code) and a timestamp.

#### Scenario: Attempt history is visible on the item page
- **WHEN** the learner opens an item they attempted twice
- **THEN** both attempts are listed with result and time
