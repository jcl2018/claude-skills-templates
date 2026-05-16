---
name: "CJ_goal family rename and native drain semantics"
type: feature
id: "F000021"
status: active
created: "2026-05-15"
updated: "2026-05-15"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

<!-- Source design doc: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-165033.md -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_goal_family_rename_and_drain`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [ ] Working branch created (`branch` field populated)
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

- [ ] `/CJ_goal_run <design-doc>` on a single-story design produces 1 feature PR + 0-5 drain PRs in one invocation, capped at 5 children.
- [ ] `/CJ_goal_todo_fix` with no args drains up to 10 easy-fix TODOs and cleanly emits a summary (drained N of M, K remaining). No `/loop` needed for the typical drain.
- [ ] `/CJ_goal_todo_fix --max-drain 3 --quiet` is invocable from `/schedule`-managed cron and produces 3 PRs queued for review without AUQ summary noise in the cron log.
- [ ] Both skills halt-on-red; partial drain emits `drained_partial` with per-child PR URLs in the telemetry line.
- [ ] Idempotent on re-invocation: re-running on a partly-drained state picks up where it left off (skip-list + T-tracker idempotency inherited from /CJ_goal v1.1).
- [ ] Old `/CJ_run` and `/CJ_goal` invocations succeed during v4.x with a one-line deprecation banner; removed cleanly in v5.0.0.
- [ ] Existing `/CJ_run` workflow tests (`scripts/test.sh`, eval cases) all pass against the renamed skills.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000044 — chore: batched rename `/CJ_run` → `/CJ_goal_run` + `/CJ_goal` → `/CJ_goal_todo_fix` (mechanical git mv + reference updates).
- [ ] Ship S000045 — add Phase 5 drain to `/CJ_goal_run` (~200 LOC: TODOS.md diff + per-child drain loop, cap=5).
- [ ] Ship S000046 — native drain semantics in `/CJ_goal_todo_fix` (default = drain-mode; cap=10) + extract shared `scripts/drain-one-todo.sh` helper (DRY).
- [ ] Ship S000047 — schedule-friendly `--quiet` flag + cron pattern doc in CLAUDE.md/SKILL.md.
- [ ] End-to-end pipeline run (this feature) — validate the four children compose into the dream-state delta.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-15: Created. CJ_goal family rename (/CJ_run → /CJ_goal_run, /CJ_goal → /CJ_goal_todo_fix) plus native drain semantics — both skills gain drain-until-cap loops; /CJ_goal_run drains in-scope TODOs from each feature ship; /CJ_goal_todo_fix becomes cron-eligible without /loop.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills/CJ_run/ → skills/CJ_goal_run/ (rename)
- skills/CJ_goal/ → skills/CJ_goal_todo_fix/ (rename)
- skills-catalog.json (catalog entries renamed)
- rules/skill-routing.md (~12 entries updated)
- CLAUDE.md (routing block + naming convention notes) — workbench + ~/.claude/
- VERSION (3.6.5 → 4.0.0 → 4.1.0 → 4.2.0 → 4.3.0)
- scripts/drain-one-todo.sh (new — shared helper extracted in S000046)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Completeness as a first-class shipping concept: feature green = feature shipped + its own debt drained. The naming convention `CJ_goal_*` telegraphs intent.
- `/ship` Gate #2 caps autonomy. "Schedule-friendly" means PRs queue for human review at scheduled cadence, NOT autonomous merge. Documenting this constraint explicitly keeps the ambition honest.
- Muscle-memory protection is non-negotiable: aliases (`/CJ_run`, `/CJ_goal`) retained through all of v4.x with one-line deprecation banner; removed in v5.0.0. Soft cutover.
- DRY: per-TODO inner loop (preflight → scaffold → pipeline → ship → deploy) shared by S000045's Phase 5 drain and S000046's native drain. Extracted into `scripts/drain-one-todo.sh` in S000046 to avoid ~150 LOC duplication.
- Hardcode caps (5 for /CJ_goal_run, 10 for /CJ_goal_todo_fix) per P5 explicit-over-clever; greppable in SKILL.md.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-15: Batch PR 1 + PR 2 into a single chore rename PR (S000044) — both are pure `git mv` + reference updates, fully reviewable in one diff. Cuts the chain from 5 PRs to 4. Auto-decided per autoplan-gate; user explicit "go" on batch.
- [decision] 2026-05-15: Per-child /ship Gate #2 (not batched) for the Phase 5 drain loop — same as `/CJ_run` Branch (b) multi-story today. Batching would create a "review 5 diffs at once" UX which is worse than 5 sequential targeted reviews.
- [decision] 2026-05-15: Drain caps hardcoded: 5 for /CJ_goal_run Phase 5 (scope = this run's TODOs, naturally smaller), 10 for /CJ_goal_todo_fix (default backlog drain). Cap exhaustion emits `drained_partial` with progress report.
- [decision] 2026-05-15: Defer drain-of-drain recursion to v5+ (risk of unbounded scope per-feature). Defer /schedule skill binding to documentation-only (smaller blast radius).
- [decision] 2026-05-15: Extract `scripts/drain-one-todo.sh` shared helper in S000046 per P4 DRY — Phase 5 drain in /CJ_goal_run and Phase 2 drain in /CJ_goal_todo_fix reuse the same per-TODO inner loop. Otherwise ~150 LOC duplicates.
- [decision] 2026-05-15: Keep `_todo_fix` suffix asymmetry (vs parallel-noun `_todos` or parallel-verb `_drain`) — matches user mental model "fix the TODOs" per P5 explicit-over-clever.
- [orchestrator] 2026-05-15: Multi-story feature halt at scaffold gate (pipeline.md Step 4 sub-step 3). Feature has 4 user-story children (S000044, S000045, S000046, S000047). end_state=green; per-child implement+QA deferred to /CJ_run Branch (b) auto-iterate or manual /CJ_implement-from-spec + /CJ_qa-work-item invocations.
- [auto-pipeline-clean] 2026-05-15: --suppress-final-gate mode; zero Taste / zero User-Challenge-Approved decisions accumulated. Pipeline ended green at multi-story scaffold halt.
