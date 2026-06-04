---
name: "Pre-build base-freshness + skills-sync for the cj_goal entry points"
type: feature
id: "F000045"
status: active
created: "2026-06-04"
updated: "2026-06-04"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-000025-81623"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/prebuild_freshness_skills_sync`
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

- [ ] Starting any cj_goal build on a machine whose local `main` is behind `origin/main` results in the build worktree being branched off `origin/main`'s tip (verified: `git merge-base --is-ancestor origin/main <worktree-base>` true).
- [ ] Diverged local `main` → a warning in the worktree `note`, build still proceeds (no halt).
- [ ] Offline (`git fetch` fails) → build proceeds on local `main`, no error surfaced to the operator, exit 0.
- [ ] `--phase sync` runs `skills-deploy install` from `.source` (never the worktree) and reports `collection_version` before→after; a guard refusal yields `PHASE_RESULT=skipped`, not `failed`.
- [ ] `--no-sync` skips the install phase (fast start) while Fork-1 ff still runs.
- [ ] All three orchestrators (feature/defect/todo_fix) exhibit the above; `todo_fix` gains the update-check snippet.
- [ ] `scripts/validate.sh` and `scripts/test.sh` pass, including the new `cj-worktree-init.test.sh` cases and the `zzz-test-scaffold` fixture update.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Implement S000081 (single child story carries all three pieces — Fork 1, Fork 2, all-3-orchestrator wiring)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Pre-build base-freshness (ff local main in cj-worktree-init.sh) + always-sync skills (new `--phase sync` in cj-goal-common.sh reusing post-land-sync.sh) wired into all three cj_goal orchestrators.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-worktree-init.sh` — new fast-forward step (Piece 1)
- `scripts/cj-goal-common.sh` — new `--phase sync` + `--no-sync` flag (Piece 2)
- `scripts/post-land-sync.sh` — reusable guarded pull+install core (Piece 2)
- `skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_defect/SKILL.md`, `skills/CJ_goal_todo_fix/SKILL.md` — preamble wiring (Piece 3)
- `tests/cj-worktree-init.test.sh`, `scripts/test.sh` — test coverage
- `CLAUDE.md`, `doc/ARCHITECTURE.md` — doc-sync (Step 5.5)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The fix belongs at the shared cj_goal entry-point path (worktree-creation + a shared preamble phase), not as three separate per-orchestrator edits — one shared implementation covers all three entry points.
- `.source == repo root` collapse (the common self-dev case): Fork 2's `git pull --ff-only` on `.source` and Fork 1's ff target the same `main` ref. Because Fork 2 runs first, Fork 1's ff then finds main already current (no-op). No double-pull, no conflict.
- `--no-sync` governs only the heavy global-state install half; Fork-1 ff is cheap/local and always runs (core to the value).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-04: Base-freshness mechanism is fast-forward local `main` (Fork 1), warning + proceeding if local `main` has diverged (never a hard halt). Rejected: branch worktree off origin/main directly (Approach C) — would silently skip rare unpushed local main commits.
- [decision] 2026-06-04: Skills-sync runs unconditionally at every build start from `.source` (Fork 2, the strong-guarantee option), with a `--no-sync` opt-out for the latency. Rejected: warn-only + tighten skills-update-check (Approach B) — doesn't deliver a fresh base; operator chose the strong guarantee.
