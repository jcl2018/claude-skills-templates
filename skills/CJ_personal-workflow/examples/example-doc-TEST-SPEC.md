---
type: test-spec
parent: S000001_core_crud
feature: F000001_reading_list_cli
title: "Core CRUD Operations — Test Specification"
version: 1
status: Draft
date: 2026-03-05
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every PRD P0
     acceptance criterion. For a single fix or task, use test-plan.md instead.

     Two tiers, distinguished by who edits them and when they run:
     - Smoke = automated regression. Lives in CI. You write it once and
       never touch it again.
     - E2E   = manual user-scenario verification. You sit down and run it
       after implementing and before /ship.

     Soft cap: 5 rows per tier. Validator emits [INFO] advisory if exceeded;
     not a violation. -->

## Smoke Tests

<!-- Automated regression. Runnable from a script or CI. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `add` writes book to file with status "to-read" | New entry persisted; default status applied | `reading-list add "Test" --author "X" && jq '.books[-1].status' file.json` |
| S2 | core | AC-2 | `list` returns all books in tabular form | Output has one row per stored book; columns match schema | `reading-list list \| wc -l` (asserts row count) |
| S3 | core | AC-3, AC-4 | Status filter and update mutate file correctly | Filter shows only matching status; update changes file in place | `reading-list update <id> --status finished && jq '.books[] \| select(.id=="<id>").status' file.json` |
| S4 | resilience | AC-1, AC-4 | Invalid input emits non-zero exit + stderr error | Missing required flag or bad ID exits 1; stderr names the field | `reading-list add "Test"; echo $?` (no --author → exit 1) |
| S5 | core | AC-5 | Remove deletes the entry from file | Removed book is no longer in `list` output | `reading-list remove <id> --force && reading-list list \| grep -v "<id>"` |

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     One row = one user-visible scenario, not one code branch. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-1, AC-2 | First-time user adds and lists their first book | `reading-list add "Dune" --author "Herbert"`; then `reading-list list` | Single row appears with title, author, status "to-read"; no errors | Pass = row visible; Fail = empty/error |
| E2 | usability | AC-2 | Empty-state message guides user to next action | `reading-list list` on a fresh file | Output reads "No books yet. Run 'add' to get started." | Pass = exact message; Fail = blank or generic error |
| E3 | core | AC-3, AC-4 | Reader marks a book finished and confirms via filter | After E1: `reading-list update <id> --status finished`; then `reading-list list --status finished` | Updated row appears in filtered list with status "finished" | Pass = row in filtered output; Fail = absent or wrong status |
| E4 | usability | AC-5 | Remove with confirmation prompt — user cancels | `reading-list remove <id>` and answer "n" at confirm prompt | Book remains in file; "Cancelled." printed | Pass = book still listed; Fail = book removed or no prompt |
| E5 | resilience | AC-4 | Helpful error when updating a nonexistent ID | `reading-list update bad-id --status reading` | Stderr: `Error: book "bad-id" not found. Run 'list' to see available books.`; exit 1 | Pass = exact error format; Fail = generic error or exit 0 |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Concurrent `add` from multiple shells | Single-user CLI; file-locking out of scope for v1 | Lost-update on race; documented as known limitation |
| JSON file > 1 MB performance | No real users at this scale yet | Slow `list` if a heavy user accumulates 10k+ books |
| Title with special characters (emoji, unicode quotes) | Stored as-is; printf rendering varies by terminal | Display oddity, not data loss |
