---
name: "Core CRUD Operations"
type: test-spec
parent: "S000001_core_crud"
feature: "F000001_reading_list_cli"
created: "2026-03-02"
updated: "2026-03-05"
author: "chjiang"
---

## Test Strategy

Unit tests for store layer (pure logic). Integration tests for CLI subcommands
(exercise full command with temp file). No E2E since this is a CLI tool.

## Test Matrix

| # | AC | Scenario | Type | Input | Expected | Priority |
|---|-----|----------|------|-------|----------|----------|
| 1 | AC-1 | Add book with title and author | integration | `add "Dune" --author "Herbert"` | Book in file with status "to-read" | P0 |
| 2 | AC-1 | Add book without author flag | integration | `add "Dune"` | Error: --author is required | P0 |
| 3 | AC-2 | List all books | integration | `list` (3 books in file) | Table with 3 rows | P0 |
| 4 | AC-2 | List with empty file | integration | `list` (empty file) | "No books yet. Run 'add' to get started." | P0 |
| 5 | AC-3 | Filter by status | integration | `list --status reading` | Only "reading" books shown | P0 |
| 6 | AC-3 | Filter with no matches | integration | `list --status finished` (none finished) | "No books with status 'finished'." | P1 |
| 7 | AC-4 | Update status | integration | `update abc123 --status finished` | Book status changed in file | P0 |
| 8 | AC-4 | Update nonexistent ID | integration | `update bad-id --status reading` | Error: book not found | P0 |
| 9 | AC-5 | Remove with confirmation | integration | `remove abc123` + confirm "y" | Book gone from file | P0 |
| 10 | AC-5 | Remove cancelled | integration | `remove abc123` + confirm "n" | Book still in file | P1 |

## Edge Cases

- Book title with special characters (quotes, unicode, emoji)
- Concurrent add operations (file locking not implemented in v1, document as known limitation)
- JSON file larger than 1MB (performance test, P2)
- Status value with typo (e.g., "reding") should suggest correct value
