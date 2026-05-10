---
name: "Deliberately broken task fixture"
type: task
id: "T000099"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000099"
repo: "/eval/fixture"
branch: "eval-fixture-branch"
blocked_by: ""
---

<!-- This tracker is deliberately malformed for the eval harness:
     Phase 3 (Ship) is missing entirely. /CJ_personal-workflow check should
     surface the missing phase + below-minimum checkbox count. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from parent's acceptance criteria + your Todos
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

<!-- NOTE: ### Phase 3: Ship is intentionally missing from this fixture.
     This is what /CJ_personal-workflow check should surface. -->

## Todos

- [x] Implement the broken thing
- [x] Update the docs

## Log

- 2026-05-09: Created. Eval-harness fixture; deliberately missing Phase 3.

## PRs

## Files

- src/broken_thing.py (new)

## Insights

This fixture is intentionally malformed to test eval coverage of the
"missing lifecycle phase" failure mode in `/CJ_personal-workflow check`.

## Journal

- 2026-05-09 [decision] Authored as eval fixture; Phase 3 omitted on purpose.
