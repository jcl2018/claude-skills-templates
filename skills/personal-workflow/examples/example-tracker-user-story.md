---
name: "Core CRUD Operations"
type: user-story
id: "S000001_core_crud"
status: active
created: "2026-03-02"
updated: "2026-03-10"
parent: "F000001_reading_list_cli"
repo: "reading-list"
branch: "feat/reading-list-cli"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Scope understood from parent work item (parent tracker read)
- [x] Working branch created
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down

### Phase 2: Implement
- [x] Implementation committed (3 commits in Log)
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work
- [ ] Files section updated

### Phase 3: Ship
- [ ] `/personal-workflow check` — validation passed
- [ ] All children shipped
- [ ] `/ship` — PR created

## Acceptance Criteria

- [x] `reading-list add "Book Title" --author "Author Name"` adds a book with status "to-read"
- [x] `reading-list list` shows all books in a formatted table
- [x] `reading-list list --status reading` filters by status
- [ ] `reading-list update <id> --status finished` changes book status
- [ ] `reading-list remove <id>` deletes a book with confirmation prompt

## Todos

- [ ] Implement `update` subcommand
- [ ] Implement `remove` subcommand with confirmation
- [ ] Add table formatting for `list` output

## Log

- 2026-03-02: Story scoped from parent feature
- 2026-03-05: `add` and `list` subcommands working (commit abc1234)
- 2026-03-08: Filter flag working for `list --status` (commit def5678)
- 2026-03-10: Started `update` subcommand (commit ghi9012)

## PRs

(none yet)

## Files

- cmd/reading-list/main.go
- internal/cmd/add.go
- internal/cmd/list.go
- internal/cmd/update.go
- internal/store/store.go
- internal/store/store_test.go

## Insights

- cobra library works well for subcommand routing but adds 5MB to the binary.
  Consider switching to stdlib flag package if binary size matters.

## Journal

### 2026-03-05 — First working prototype
- **Implementation:** `add` writes to ~/.reading-list.json, `list` reads and formats
- **Finding:** JSON file locking needed for concurrent access (deferred to v2)
- **Decision:** Use cobra for CLI framework despite binary size (developer ergonomics win)
