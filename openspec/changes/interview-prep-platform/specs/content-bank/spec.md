## Purpose

Defines the versioned question/task bank: the on-disk item format, validation rules, and how items are
loaded into the database so that content can be edited, re-seeded and shared without data loss.

## ADDED Requirements

### Requirement: Items are stored as YAML files per language and topic
The system SHALL read items from `content/<language>/<topic>.yml` where `<language>` is `ruby` or
`elixir`. Each file SHALL declare `language`, `topic`, and a list of `items`.

#### Scenario: Well-formed file is accepted
- **WHEN** a file declares `language: ruby`, `topic: blocks`, and a non-empty `items` list
- **THEN** every item in the list is available for seeding under language `ruby` and topic `blocks`

#### Scenario: Language/topic mismatch is rejected
- **WHEN** a file under `content/ruby/` declares `language: elixir`
- **THEN** validation fails and names the file

### Requirement: Every item has a stable slug and a kind
Each item SHALL have a globally unique `slug` matching `^[a-z]+-[a-z0-9-]+$`, a `kind` from
`mcq | open | code | theory`, a `difficulty` from `junior | middle | senior`, a `title`, and a markdown
`body`.

#### Scenario: Duplicate slug across files
- **WHEN** two items in any files share the same `slug`
- **THEN** validation fails and reports both file names

#### Scenario: Unknown kind
- **WHEN** an item declares `kind: essay`
- **THEN** validation fails and reports the slug

### Requirement: Kind-specific fields are enforced
- `mcq` items MUST have `choices` (2–6 strings) and an integer `answer` index into `choices`.
- `open` and `theory` items MUST have a markdown `answer` (model answer or recap).
- `code` items MUST have `starter_code`, `tests`, and `solution`; `tests` MUST be a Minitest script
  fragment for Ruby or an ExUnit script fragment for Elixir.
- All items MAY have `explanation`, `tags` (list), and `source` (URL or citation).

#### Scenario: MCQ answer out of range
- **WHEN** an `mcq` item has 4 choices and `answer: 4`
- **THEN** validation fails and reports the slug

#### Scenario: Code item solution passes its tests
- **WHEN** the validator runs a `code` item's `solution` concatenated with its `tests`
- **THEN** the process exits 0; otherwise validation fails and prints the test output

### Requirement: Seeding is idempotent by slug
The seed command SHALL insert new items and update existing ones matched by `slug`, never duplicating,
and SHALL preserve attempt and review history attached to an existing slug.

#### Scenario: Re-seed after editing a body
- **WHEN** an item's body is edited in YAML and the seed command runs again
- **THEN** the database row for that slug has the new body and its attempts remain

### Requirement: Minimum bank size is reported
The system SHALL provide a stats command printing item counts per language, topic, kind and difficulty.

#### Scenario: Stats after full seed
- **WHEN** the stats command runs after seeding the shipped content
- **THEN** it prints at least 500 items for `ruby` and at least 500 for `elixir`
