---
type: roadmap
parent: F000001_reading_list_cli
title: "Reading List CLI — Roadmap"
date: 2026-03-01
author: chjiang
status: Draft
---

<!-- Example ROADMAP for a hypothetical Reading List CLI feature. Demonstrates
     the v3 shape: Scope, Non-Goals, Success Criteria, Decomposition,
     Delivery Timeline (with Delivery History sub-section), Dependency Graph,
     Open Questions. -->

## Scope

A single-binary CLI for tracking books across three states (`to-read`, `reading`, `finished`). Persists a JSON file at `~/.reading-list.json`. Installable via `go install`. Solo-dev tool — no auth, no sync, no GUI.

## Non-Goals

- Multi-user sync — staying single-user simplifies the storage model.
- ISBN lookup / external metadata fetch — adds API key management; out of scope for v1.
- Reading-statistics dashboard — pure CLI output, no charts.
- Mobile companion app — different scope entirely.

## Success Criteria

- [ ] `go install github.com/jcl2018/reading-list@latest` produces a working binary on macOS and Linux.
- [ ] All 5 acceptance criteria from S000001 verified with `bin/test-lane`.
- [ ] Adding 1000 books and listing all of them takes < 100ms on a 2024 MacBook.
- [ ] Binary size < 8MB.
- [ ] Zero runtime errors on a fresh install with no existing `~/.reading-list.json`.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000001](S000001_core_crud/S000001_TRACKER.md) | Core CRUD Operations | In Progress |
| [S000002](S000002_search_filtering/S000002_TRACKER.md) | Search and Filtering | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | S000001 Core CRUD shipped (add/list/update/remove) | 2026-03-15 | In Progress | chjiang | First usable end-to-end flow | — |
| 2 | S000002 Search + filtering shipped | 2026-03-22 | Not Started | chjiang | `--query`, `--tag`, fuzzy match | #1 |
| 3 | v0.1.0 release on GitHub Releases + go install path verified | 2026-03-25 | Not Started | chjiang | First public version | #2 |

### Delivery History

<!-- Backward-looking record. Append-only. -->

- _none yet — feature is pre-ship_

## Dependency Graph

```
#1 (S000001 Core CRUD) ──> #2 (S000002 Search) ──> #3 (v0.1.0 release)
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Should we ship a Homebrew formula in v0.1.0 or wait for v0.2.0? | Decide after v0.1.0 install path is verified |
| Any value in a `--reading-list-dir` env override for the storage path? | Defer until a user with multiple machines asks for it |
