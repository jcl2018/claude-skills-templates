---
name: "Core CRUD Operations"
type: architecture
parent: "S000001_core_crud"
feature: "F000001_reading_list_cli"
created: "2026-03-02"
updated: "2026-03-05"
author: "chjiang"
---

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
