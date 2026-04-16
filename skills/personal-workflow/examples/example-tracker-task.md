---
name: "Implement update subcommand"
type: task
id: "T000001_implement_update"
status: active
created: "2026-03-08"
updated: "2026-03-10"
parent: "S000001_core_crud"
repo: "reading-list"
branch: "feat/reading-list-cli"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Scope understood from parent work item (parent tracker read)
- [x] Required docs scaffolded (test-plan)
- [x] Todos populated from parent acceptance criteria

### Phase 2: Implement
- [x] Implementation committed
- [ ] Test plan scenarios passing
- [ ] Files section updated

### Phase 3: Ship
- [ ] `/personal-workflow check` — validation passed
- [ ] `/ship` — PR created

## Todos

- [x] Parse `update <id> --status <value>` args
- [x] Validate status is one of: to-read, reading, finished
- [ ] Write updated record back to JSON file
- [ ] Add error message for invalid book ID
- [ ] Test: update nonexistent ID returns clear error

## Log

- 2026-03-08: Task scoped from S000001 acceptance criteria
- 2026-03-10: Arg parsing and validation working (commit jkl3456)

## PRs

(none yet)

## Files

- internal/cmd/update.go
- internal/cmd/update_test.go
- internal/store/store.go

## Journal

### 2026-03-10 — Arg parsing done
- **Implementation:** cobra subcommand with `--status` flag, validates against allowed values
- **Finding:** Need to handle the case where the JSON file doesn't exist yet (user runs `update` before `add`)
