---
type: spec
parent: S000001_core_crud
feature: F000001_reading_list_cli
title: "Core CRUD Operations — Specification"
version: 1
status: Draft
date: 2026-03-02
author: chjiang
reviewers: []
---

<!-- Example SPEC for the Reading List CLI's "Core CRUD Operations" user-story.
     Demonstrates the v3 shape: Requirements with P0/P1/P2 sub-sections, Acceptance
     Criteria, Architecture, Tradeoffs, Open Questions. Story-scope detail (this doc)
     pairs with the parent feature's DESIGN.md and ROADMAP.md. -->

## Problem Statement

A solo developer wants to track what they've read, are reading, and plan to read — without booting up a notes app, signing into a SaaS, or syncing a database. They want a CLI they can `go install` once and call from anywhere on their machine. The pain today: existing tools (goodreads CLI, booklog) are abandoned, GUI alternatives have heavyweight UX, and a mental list in `notes.txt` doesn't filter well.

## Mental Model

The CLI has one verb-form (`reading-list <subcommand> [args]`) and exactly four states a book can be in: `to-read`, `reading`, `finished`, and `deleted` (soft-delete). Each subcommand maps to one storage operation against a single JSON file at `~/.reading-list.json`. No daemons, no syncing, no remote API.

## Requirements

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | Can a user add a book with a title, author, and initial status? | reader | run `reading-list add "Title" --author "Name"` | a book appears in the JSON store with status `to-read` |
| 2 | core | Can a user list books, optionally filtered by status? | reader | run `reading-list list [--status reading]` | I see only books matching the filter (or all books with no filter) |
| 3 | core | Can a user update a book's status by ID? | reader | run `reading-list update <id> --status finished` | the book's status changes and the JSON store reflects it |

### P1 (Important)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 4 | usability | Can a user remove a book by ID with a confirmation prompt? | reader | run `reading-list remove <id>` and confirm | I don't accidentally delete a book by typo |

### P2 (Nice-to-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 5 | usability | Can the `list` output show table-formatted columns? | reader | run `reading-list list` | output is readable on a 80-char terminal without horizontal scroll |

## Acceptance Criteria

### Story #1: Add command persists a book [core]

```
GIVEN no ~/.reading-list.json file exists
WHEN  I run `reading-list add "Designing Data-Intensive Applications" --author "Martin Kleppmann"`
THEN  ~/.reading-list.json is created
AND   it contains an entry with title, author, and status="to-read"
```

### Story #2: List command honors --status filter [core]

```
GIVEN ~/.reading-list.json has 3 books: 1 to-read, 1 reading, 1 finished
WHEN  I run `reading-list list --status reading`
THEN  only the 1 "reading" book is printed
AND   exit code is 0
```

### Story #3: Update command changes status [core]

```
GIVEN ~/.reading-list.json has a book with id=1, status=to-read
WHEN  I run `reading-list update 1 --status finished`
THEN  the book's status field is "finished"
AND   the file's last-modified timestamp updates
```

## Architecture

```
+---------------+   +---------------+   +-----------------------+
| cmd/main.go   |-->| internal/cmd/ |-->| internal/store/store  |
| (cobra root)  |   | (subcommands) |   | (JSON read/write)     |
+---------------+   +---------------+   +-----------------------+
                          |                       |
                          v                       v
                    internal/model/         ~/.reading-list.json
                    (Book struct)
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `cmd/reading-list/main.go` | reading-list | New | Cobra root command, registers subcommands |
| `internal/cmd/{add,list,update,remove}.go` | reading-list | New | One file per subcommand |
| `internal/store/store.go` | reading-list | New | Read/write `~/.reading-list.json`; mutex for concurrent invocations (deferred to v2) |
| `internal/model/book.go` | reading-list | New | `Book` struct with id, title, author, status |

### Data Flow

1. User runs `reading-list <verb> [args]`.
2. Cobra dispatches to the matching subcommand handler in `internal/cmd/`.
3. Handler calls `store.Load()` to read `~/.reading-list.json` (or initialize empty if missing).
4. Handler mutates the in-memory slice, then calls `store.Save()` to write back atomically (via temp file + rename).

## Tradeoffs

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Storage format | JSON file at `~/.reading-list.json` | SQLite, BoltDB | Portable; users can `cat` and `vim` the file; no driver dependency in the binary |
| CLI framework | cobra | stdlib `flag` package | Subcommand routing + help generation are essentially free; binary-size cost (~5MB) acceptable for v1 |
| Concurrency | Single-process assumption (no file locking) | flock-based locking | A reader running two CLI invocations simultaneously is rare; defer to v2 if it becomes real |

## Open Questions

| Question | Next check |
|----------|-----------|
| Should `remove` soft-delete (preserve history) or hard-delete? | Decide after first user reports an "I removed it by accident" issue |
| Where should we store API keys for a future `--lookup-by-isbn` feature? | Out of scope for v1; revisit when user asks for it |
