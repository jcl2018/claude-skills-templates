---
name: "cj_goal local happy-path E2E harness"
type: feature
id: "F000071"
status: active
created: "2026-06-30"
updated: "2026-06-30"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-happy-e2e"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_goal_local_e2e_harness`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [x] **Part A (S000120, SHIPPED v6.0.99):** the `scripts/cj-e2e-gate.sh` verdict helper lands; the four cj_goal pipelines branch on it with uniform seam prose; `.cj-e2e-sandbox` is gitignored AND a `validate.sh` marker-absence check hard-fails if it is tracked; `tests/cj-e2e-gate.test.sh` asserts the verdict matrix (no Claude); a normal run is behavior-unchanged; CI-green.
- [x] **Part B (S000121):** `scripts/e2e-local.sh` runs a real `/CJ_goal_task` build in a sandbox unattended via the seam, stops at the `/ship` boundary (no real PR), and writes a materialized run report (md + json) distinguishing deterministic vs claude-print steps. Deterministic half CI-tested (`tests/e2e-local.test.sh`); the real run is a LOCAL manual E2E.
- [x] **Part C (S000121):** a workflow-docs roster entry (extending `docs/workflows/utilities-and-phase-steps.md`) documents the harness; `docs/tests/test-hierarchy.md` is updated; Check 27 green; no work-item IDs in human-docs.
- [x] The seam NEVER touches ship/merge/deploy gates; `validate.sh` 0 errors; `test.sh` green.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [x] Ship S000120 (Part A — the dormant build-gate auto-answer seam) — SHIPPED v6.0.99
- [x] Scaffold + ship Part B follow-on (the local-E2E harness + materialized report) — S000121
- [x] Scaffold + ship Part C follow-on (workflow-docs roster entry + test-hierarchy update) — S000121

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-30: Created. cj_goal local happy-path E2E harness — Part A scaffolded as child story S000120 (the dormant, CI-green build-gate auto-answer seam); Parts B and C captured as tracked follow-on.
- 2026-06-30: Part A (S000120) shipped as v6.0.99 (PR #302). Parts B + C built as child story S000121 (the local-E2E harness `scripts/e2e-local.sh` + `lib/{sandbox,report}.sh` + the deterministic smoke `tests/e2e-local.test.sh`, the materialized report, the workflow-docs roster entry, and the test-hierarchy update). validate.sh 0 errors; test.sh green.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-e2e-gate.sh` (new — Part A verdict helper)
- `scripts/validate.sh` (modified — Part A marker-absence check)
- `scripts/test.sh` (modified — Part A test runner block + zzz-test-scaffold fixture row)
- `tests/cj-e2e-gate.test.sh` (new — Part A deterministic verdict matrix)
- `skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_task/pipeline.md`, `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_todo_fix/pipeline.md` (modified — Part A seam prose)
- `.gitignore` (modified — Part A marker ignore)
- `docs/tests/test-hierarchy.md` (modified — Part A test-hierarchy note)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The cj_goal AUQs are the autonomy ceiling. The seam can NEVER become auto-ship: it is build-gates-only (`{design-gate, qa-audit}` allowlist), green-only continue (reuses `todo_fix --quiet`'s predicate), double-hard-guarded (`CJ_GOAL_E2E_AUTO=1` AND `.cj-e2e-sandbox`), and marker-leak-guarded (gitignore + validate hard-fail).
- The gates are agent-emitted `AskUserQuestion` calls (prose in pipeline.md), NOT shell — a shell helper cannot suppress them. So the design is split: (a) a pure deterministic verdict helper (`AUTO=continue|halt|inactive`) and (b) agent-prose in each pipeline.md AUQ step that runs the helper first and branches on its verdict.
- design-gate is feature-only (only `CJ_goal_feature` has Step 2.7); the qa-audit seam is the one shared across all four orchestrators.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Story split (operator-decided): THIS feature's first shipped story is Part A ONLY — the dormant, CI-green seam + its non-activation proof. Summary: Part A changes no real run's behavior (guard off by default), is fully unit-tested (no Claude), and lands as one low-risk mergeable PR; it is the prerequisite the real-run harness (Part B) needs. Parts B and C are tracked follow-on, captured in this feature's DESIGN/ROADMAP but not built in S000120.
- [decision] Helper home: standalone `scripts/cj-e2e-gate.sh` rather than a `cj-goal-common.sh` phase. Summary: simplest to unit-test as a pure deterministic verdict function.
