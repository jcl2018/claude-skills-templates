---
name: "Core CRUD Operations"
type: prd
parent: "S000001_core_crud"
feature: "F000001_reading_list_cli"
created: "2026-03-02"
updated: "2026-03-05"
author: "chjiang"
---

## Problem Statement

Readers track books across multiple apps (Goodreads, spreadsheets, Notes app) with
no single source of truth. Existing CLI tools are abandoned. Need a fast, local-first
tool that works from the terminal where developers already live.

## User Stories

### P0 (Must-Have)

| # | As a... | I want to... | So that... | Acceptance Criteria |
|---|---------|--------------|------------|---------------------|
| 1 | reader | add a book with title and author | I can track what I want to read | Book appears in list with status "to-read" |
| 2 | reader | list all my books | I can see my full reading list | Table shows title, author, status, date added |
| 3 | reader | filter books by status | I can see only what I'm currently reading | `--status` flag filters correctly |
| 4 | reader | update a book's status | I can mark progress | Status changes persist across sessions |
| 5 | reader | remove a book | I can clean up my list | Book is gone after confirmation |

### P1 (Important)

| # | As a... | I want to... | So that... | Acceptance Criteria |
|---|---------|--------------|------------|---------------------|
| 6 | reader | see reading stats | I know how many books I've finished | `stats` subcommand shows counts by status |
| 7 | reader | export to CSV | I can share or backup my list | `export --format csv` writes valid CSV |

## Non-Goals

- No cloud sync (local-first for v1)
- No recommendation engine (v2)
- No ISBN lookup or cover art

## Technical Constraints

- Single binary, no runtime dependencies
- Data stored in ~/.reading-list.json
- Must work on macOS and Linux
