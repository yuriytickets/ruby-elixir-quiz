## Purpose

Schedules repeat exposure to each item from the learner's self-grades so weak material returns sooner
and mastered material fades out, maximising retention in a one-month window.

## ADDED Requirements

### Requirement: Grades update a per-item review schedule
After each attempt the system SHALL update the item's review state (ease, interval in days, due date,
repetition count) using the SM-2 algorithm. MCQ and code results map to `again` (incorrect) or `good`
(correct).

#### Scenario: First correct answer
- **WHEN** an item with no review state is graded `good`
- **THEN** its interval becomes 1 day and it is due tomorrow

#### Scenario: Lapse resets interval
- **WHEN** an item with interval 10 is graded `again`
- **THEN** its interval becomes 0, it is due today, and its ease drops but never below 1.3

### Requirement: Due queue is served first
The system SHALL expose the count of items due today per language and SHALL serve due items before
new items in study mode.

#### Scenario: Due item is served
- **WHEN** one item is due today and one is unattempted in the same filter
- **THEN** the due item is served first
