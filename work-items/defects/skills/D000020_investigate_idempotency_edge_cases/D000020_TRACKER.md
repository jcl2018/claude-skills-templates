---
name: "/CJ_goal_investigate idempotency table — two edge cases break Row 4 detection on shipped defects"
type: defect
id: "D000020"
status: active
created: "2026-05-16"
updated: "2026-05-16"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "dogfood-investigate-20260515-235220"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch (already done: dogfood-investigate-20260515-235220)
3. Scaffold required docs: D000020_RCA.md + D000020_test-plan.md
4. Run `/investigate` to diagnose root cause — N/A here (dogfood discovery)
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Defect reproduces (deterministically, on D000017_cj_suggest_zsh_crash dry-run)
- [x] Working branch created
- [x] RCA.md scaffolded
- [x] test-plan.md scaffolded

### Phase 2: Implement

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work
- [x] Files section updated with changed files

### Phase 3: Ship

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] **Bug A**: `R` (RCA-populated) detection correctly identifies prose under `## Root Cause` even when the section is followed by another `## ` heading. Re-running on D000017 (which has 17 lines of prose under that heading) now returns `R=1` instead of `R=0`.
- [x] **Bug B**: Resume-row dispatch checks `M=1` (PR merged terminal state) BEFORE the R=0+F=1 anomaly check. Re-running on D000017 now selects Row 4 (no-op) instead of Row 5 (anomaly).
- [x] No existing rows of the idempotency table regress (Rows 1, 2, 3, 5 unaffected).
- [x] `./scripts/validate.sh` PASS post-fix.
- [x] `./scripts/test.sh` PASS post-fix (modulo the known worktree-version-mismatch flake).

## Todos

- [x] Fix Bug A: replace degenerate awk range with stateful flag.
- [x] Fix Bug B: hoist M=1 check above R=0+F=1 anomaly check.
- [x] Verify both fixes via re-running the dry-run logic against D000017.

## Log

- 2026-05-16: Created. Two bugs discovered during the F000024 v0.1.0 dogfood validation (first invocation of `/CJ_goal_investigate --dry-run D000017`). Both bugs trace to idempotency-table edge cases in `skills/CJ_goal_investigate/pipeline.md` Step 3.

## PRs

<!-- PR link added at /ship time. -->

## Files

- `skills/CJ_goal_investigate/pipeline.md` — Step 3 idempotency block (two edits: stateful-flag awk for `R` detection, hoisted `M=1` check in resume-row dispatch).

## Insights

- **Shared root cause:** Both bugs trace to incomplete handling of idempotency-table edge cases. Bug A is a defensive-read failure (awk range degenerate when start/end patterns overlap). Bug B is a defensive-dispatch failure (anomaly check fires before terminal-state check). Same architectural premise — "happy path covers common case" — left the edge cases exposed.
- **Dogfood found bugs in 30 seconds.** First `--dry-run` invocation of `/CJ_goal_investigate` against an already-shipped defect (D000017) surfaced both. Confirms the value of running new skills against the existing backlog before claiming v0.1.0 stable.
- **Sentinel-emission contract still untested.** D000020's fix doesn't exercise `/investigate` end-to-end (we only ran `--dry-run`, which exits before dispatch). The follow-up dogfood after D000020 lands should pick a defect with `M=0` to actually observe `DEBUG_REPORT_BEGIN_JSON ... END_JSON`.

## Journal

- [decision] 2026-05-16: Bundled both bugs in one D-defect (shared idempotency-table-edge-case root cause). Approach A from /office-hours: one RCA articulates the shared cause; one PR closes both.
- [impl] 2026-05-16: Applied both fixes to `skills/CJ_goal_investigate/pipeline.md` Step 3. Bug A awk range → stateful flag (~8-line edit). Bug B resume-row dispatch → `M=1` hoisted to top (~5-line edit). Total: 2 edits in 1 file, ~13 lines.
- [smoke-pass] 2026-05-16: Re-ran the dry-run idempotency logic against D000017 post-fix. AFTER FIXES: `R=1 F=1 P=0 M=1`, Resume row: 4 (expected 4). Bug A: R correctly flips 0→1 because the awk now extracts the 17 lines of prose under `## Root Cause`. Bug B: dispatch correctly picks Row 4 (no-op) instead of Row 5 (anomaly) because the `M=1` terminal-state check runs first.
- [smoke-pass] 2026-05-16: `./scripts/validate.sh` PASS, 0 errors / 0 warnings post-fix.
