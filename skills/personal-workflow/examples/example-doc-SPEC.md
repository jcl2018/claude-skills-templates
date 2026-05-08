---
type: spec
parent: S000001
feature: F000001
title: "Reading List Add Command — Specification"
version: 1
status: Draft
date: 2026-03-01
author: chjiang
reviewers: []
---

<!-- Example SPEC: merged content from the prior example-doc-PRD.md +
     example-doc-ARCHITECTURE.md. Demonstrates the v3 shape (Requirements
     with P0/P1/P2 sub-sections, Acceptance Criteria, Architecture,
     Tradeoffs, Open Questions). -->

<!-- ===== From example-doc-PRD.md ===== -->

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

<!-- ===== From example-doc-ARCHITECTURE.md ===== -->

## Overview

A Go CLI with three layers: command routing (cobra), business logic (internal/cmd/),
and persistence (internal/store/). Single JSON file for storage. No external services.

## Architecture Diagram

```
  CLI Input
     │
     ▼
  cobra router (cmd/reading-list/main.go)
     │
     ├── add    → internal/cmd/add.go
     ├── list   → internal/cmd/list.go
     ├── update → internal/cmd/update.go
     └── remove → internal/cmd/remove.go
                      │
                      ▼
              internal/store/store.go
                      │
                      ▼
              ~/.reading-list.json
```

## Key Decisions

### 1. Go over Python/Rust
- **Chosen:** Go
- **Why:** Single binary distribution (no runtime), fast compilation, cross-platform
- **Tradeoff:** Larger binary than Rust, but faster to develop
- **Revisit if:** Binary size exceeds 20MB

### 2. JSON file over SQLite
- **Chosen:** JSON file at ~/.reading-list.json
- **Why:** Human-readable, portable, no C dependency (CGO_ENABLED=0)
- **Tradeoff:** No concurrent access safety, O(n) reads
- **Revisit if:** List exceeds 10,000 books (unlikely for personal use)

### 3. cobra over stdlib flag
- **Chosen:** cobra CLI framework
- **Why:** Subcommand routing, auto-generated help, shell completions
- **Tradeoff:** Adds ~5MB to binary
- **Revisit if:** Binary size becomes a deployment concern

## Data Model

```go
type Book struct {
    ID        string    `json:"id"`
    Title     string    `json:"title"`
    Author    string    `json:"author"`
    Status    string    `json:"status"`    // to-read, reading, finished
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

## Error Handling Strategy

- File not found → create empty list, continue
- Corrupt JSON → backup to .bak, start fresh, warn user
- Invalid status value → reject with allowed values list
- Book ID not found → clear error with suggestion to run `list`
