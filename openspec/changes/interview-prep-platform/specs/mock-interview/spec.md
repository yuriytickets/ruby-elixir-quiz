## Purpose

Simulates an interview round: a fixed set of mixed items answered in sequence with a final score, so
the learner practises under conditions closer to the real thing.

## ADDED Requirements

### Requirement: A mock interview is a fixed ordered set of items
Starting a mock interview for a language SHALL select N items (default 10) spanning kinds and
difficulties, present them one at a time in order, and allow skipping forward only.

#### Scenario: Start with defaults
- **WHEN** the learner starts a Ruby mock interview
- **THEN** 10 Ruby items are chosen, including at least one `code` and one `open` item when available

### Requirement: Summary at the end
After the last item the system SHALL show correct / incorrect / skipped counts, time elapsed, and a list
of items with links to review each one.

#### Scenario: Summary after completion
- **WHEN** the learner answers the tenth item
- **THEN** a summary page lists all ten items with their results
