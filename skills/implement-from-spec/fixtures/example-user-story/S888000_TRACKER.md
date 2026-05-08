---
name: "Greeting writer fixture"
type: user-story
id: "S888000"
status: active
created: "2026-05-08"
updated: "2026-05-08"
parent: "F888888"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/implement-from-spec"
blocked_by: ""
---

<!-- Synthetic fixture for /implement-from-spec. NOT a real work item — lives
     under skills/implement-from-spec/fixtures/, invisible to the work-items/
     tree walk. The SPEC describes a single-file write (`output/greeting.txt`
     with content "Hello from /implement-from-spec\n"). After dogfooding, the
     written file is removed to restore canonical state. -->

## Lifecycle

### Phase 1: Track

1. (synthetic) Track this fixture
2. SPEC describes the implementation contract; trivial scope

**Gates:**
- [x] /office-hours design referenced (synthetic — none)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read SPEC for the implementation contract
2. Write `output/greeting.txt` with the asserted content
3. Update tracker journal

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work
- [ ] Files section updated with changed files

### Phase 3: Ship

1. (synthetic) Not applicable for fixtures

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `output/greeting.txt` exists relative to this fixture dir
- [ ] Its content is exactly `Hello from /implement-from-spec\n` (one line, trailing newline)

## Todos

- [ ] /implement-from-spec writes `output/greeting.txt` per SPEC
- [ ] Tracker journal records the implementation step

## Log

- 2026-05-08: Created. Synthetic fixture for /implement-from-spec v1 manual testing.

## PRs

<!-- N/A — fixture, not real work. -->

## Files

<!-- Populated by /implement-from-spec dogfood run. Canonical state: empty (modulo .gitkeep). -->

## Insights

- **Triviality:** SPEC has 1 file in Components Affected (excluding TRACKER) and no sensitive-surface change. The skill should classify this as TRIVIAL=true. With `--auto` flag, MODE=auto. Without, MODE=propose (the default safety net).
- **Why output/ subdirectory:** keeps the produced file isolated under the fixture so cleanup is `rm output/greeting.txt` without touching anything else.

## Journal

- 2026-05-08 [decision] Fixture lives at `skills/implement-from-spec/fixtures/example-user-story/` (parallel to `qa-work-item`'s fixture pattern). Synthetic ID S888000 (parent F888888) doesn't pollute the real work-items tree.
- 2026-05-08 [decision] One golden fixture is the v1 design (Issue 3.1A from /plan-eng-review). Variations (sensitive-surface AUQ, propose-and-confirm preview, --auto demotion on non-trivial) are documented in fixtures/README.md as hand-toggle exercises rather than separate fixtures.
