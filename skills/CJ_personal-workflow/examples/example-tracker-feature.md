---
name: "Reading List CLI"
type: feature
id: "F000001_reading_list_cli"
status: active
created: "2026-03-01"
updated: "2026-03-15"
repo: "reading-list"
branch: "feat/reading-list-cli"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship
- [ ] `/personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

- [ ] Users can add books with title, author, and status (to-read, reading, finished)
- [ ] Users can list books filtered by status
- [ ] Users can update book status
- [ ] Data persists in a local JSON file (~/.reading-list.json)
- [ ] CLI is installable via `go install`

## Todos

- [ ] Implement S000001 (core CRUD operations)
- [ ] Implement S000002 (search and filtering)
- [ ] Write README with installation instructions

## Log

- 2026-03-01: Feature scoped from /office-hours design doc
- 2026-03-02: Decomposed into 2 user stories

## PRs

(none yet)

## Files

- cmd/reading-list/main.go
- internal/store/store.go
- internal/model/book.go

## Insights

- Users care more about "what should I read next" than tracking what they've read.
  The recommendation angle could be a v2 feature.

## Journal

### 2026-03-01 — Initial scoping
- **Decision:** Use Go for the CLI (fast binary, easy cross-compilation)
- **Decision:** JSON file storage over SQLite (simpler for v1, portable)
- **Finding:** Existing tools (goodreads CLI, booklog) are all abandoned. Green field.
