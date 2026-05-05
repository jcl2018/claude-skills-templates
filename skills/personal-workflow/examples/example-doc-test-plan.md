---
type: test-plan
parent: T000001_implement_update
title: "Implement update subcommand — Test Plan"
date: 2026-03-10
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

The `update` subcommand changes a book's status field by id. Touches
`cmd/update.go` and the shared `store.Save` writer. Nothing outside those
files moves; the JSON schema and surrounding subcommands are unchanged.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Update existing book status | `reading-list update abc123 --status finished` | Status changes in file; UpdatedAt refreshed; exit 0 | Pass |
| 2 | Update with invalid status value | `reading-list update abc123 --status invalid` | stderr: `Error: status must be one of: to-read, reading, finished`; exit 1; file unchanged | Pass |
| 3 | Update nonexistent ID | `reading-list update bad-id --status reading` | stderr: `Error: book "bad-id" not found. Run 'list' to see available books.`; exit 1 | Pending |
| 4 | Update without --status flag | `reading-list update abc123` | stderr: `Error: --status flag is required`; exit 1 | Pass |
| 5 | Update on empty store | `reading-list update abc123 --status reading` (file has no books) | stderr: `Error: no books found. Run 'add' first.`; exit 1 | Pending |

## Verification Steps

- [ ] Local build succeeds (`go build ./...`)
- [ ] L1 regression suite passes (`go test ./...`)
- [ ] Manual reproduction of all 5 cases above with `--status finished` test data
- [ ] After update, `list` shows the new status (no stale cached value)
- [ ] After update, the JSON file is valid (not truncated or doubled)
- [ ] `UpdatedAt` timestamp is strictly newer than `CreatedAt`

## Environments Tested

| Environment | Build | Result |
|-------------|-------|--------|
| macOS 14 (arm64) | local `go build` | Pass |
| Ubuntu 22.04 (amd64) | CI `go test` | Pass |
