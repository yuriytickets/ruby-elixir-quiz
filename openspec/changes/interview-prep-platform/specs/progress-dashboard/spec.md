## Purpose

Shows where the learner stands: coverage, accuracy and the weakest topics per language, so study time
goes where it pays off most.

## ADDED Requirements

### Requirement: Dashboard summarises coverage and accuracy
The dashboard SHALL show, per language: total items, items attempted, items due today, overall accuracy
(share of correct attempts), and a per-topic table with items, attempted, accuracy.

#### Scenario: Fresh database
- **WHEN** no attempts exist
- **THEN** attempted counts and accuracy show 0 and no topic is marked weak

### Requirement: Weakest topics are highlighted
Topics with at least 3 attempts and accuracy below 60% SHALL be marked as weak and linked to a study
session filtered to that topic.

#### Scenario: Weak topic link
- **WHEN** topic `otp` has 5 attempts, 2 correct
- **THEN** it is marked weak and links to study mode filtered by `language=elixir&topic=otp`

### Requirement: Daily activity is shown
The dashboard SHALL show attempts per day for the last 30 days and the current streak of consecutive
days with at least one attempt.

#### Scenario: Streak counts today
- **WHEN** attempts exist today and yesterday but not the day before
- **THEN** the streak shows 2
