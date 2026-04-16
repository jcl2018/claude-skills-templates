---
name: "List command crashes on empty JSON file"
type: defect
id: "D000001_empty_json_crash"
status: active
created: "2026-03-12"
updated: "2026-03-12"
repo: "reading-list"
branch: "fix/empty-json-crash"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Defect scoped (reproduction steps documented)
- [x] Required docs scaffolded (RCA + test-plan)

### Phase 2: Implement
- [ ] Root cause identified in RCA
- [ ] Fix implemented and committed
- [ ] Regression test passing

### Phase 3: Ship
- [ ] `/personal-workflow check` — validation passed
- [ ] `/ship` — PR created

## Reproduction Steps

1. Delete ~/.reading-list.json (or start fresh)
2. Run `reading-list add "Test Book" --author "Test Author"`
3. Ctrl+C during write (simulate interrupted write)
4. Run `reading-list list`
5. **Expected:** Empty list or error message
6. **Actual:** Panic: `unexpected end of JSON input` at store.go:42

## Todos

- [x] Document reproduction steps
- [ ] Root cause analysis in RCA.md
- [ ] Fix the JSON parsing to handle empty/corrupt files
- [ ] Add regression test for empty file case
- [ ] Add regression test for truncated JSON case

## Log

- 2026-03-12: Bug reported. Reproduced consistently with empty file.

## PRs

(none yet)

## Files

- internal/store/store.go (line 42: json.Unmarshal without error recovery)
- internal/store/store_test.go

## Insights

- The store layer assumes the JSON file is always valid. Every read path needs
  a recovery strategy (empty file = empty list, corrupt file = backup + warning).

## Journal

### 2026-03-12 — Bug discovery
- **Finding:** json.Unmarshal panics on empty input. The store.Load() function
  reads the file but doesn't check for zero bytes before parsing.
- **Decision:** Fix with a length check + graceful fallback to empty list.
  Backup corrupt files to ~/.reading-list.json.bak before overwriting.
