---
name: "Implement update subcommand"
type: test-plan
parent: "T000001_implement_update"
created: "2026-03-08"
updated: "2026-03-10"
author: "chjiang"
---

## Scope

Test the `reading-list update <id> --status <value>` subcommand. Covers happy path,
validation errors, and edge cases.

## Test Scenarios

| # | Scenario | Input | Expected | Status |
|---|----------|-------|----------|--------|
| 1 | Update existing book status | `update abc123 --status finished` | Status changed, UpdatedAt refreshed | Passing |
| 2 | Update with invalid status | `update abc123 --status invalid` | Error: status must be one of: to-read, reading, finished | Passing |
| 3 | Update nonexistent ID | `update bad-id --status reading` | Error: book "bad-id" not found. Run `list` to see available books. | Not started |
| 4 | Update without --status flag | `update abc123` | Error: --status flag is required | Passing |
| 5 | Update on empty file | `update abc123 --status reading` (no books) | Error: no books found. Run `add` first. | Not started |

## Regression Tests

- After update, `list` shows the new status (not cached old value)
- After update, JSON file is valid (not truncated or doubled)
- UpdatedAt timestamp is newer than CreatedAt
