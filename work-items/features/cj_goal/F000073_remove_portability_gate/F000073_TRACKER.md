---
name: "Remove the portability-audit gate from the cj_goal orchestrators"
type: feature
id: "F000073"
status: active
created: "2026-07-02"
updated: "2026-07-02"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/inspiring-torvalds-0e7e5d"
branch: "claude/inspiring-torvalds-0e7e5d"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/remove_portability_gate`
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

- [ ] `grep -rn "phase portability-audit\|portability-red\|halted_at_portability"` over `scripts/cj-goal-common.sh` + the four `skills/CJ_goal_*/` dirs returns nothing (the gate is gone from the build path).
- [ ] `./scripts/validate.sh` passes (Check 18 still strict; Check 24 marker cross-check consistent; Check 27 workflow docs fresh).
- [ ] `./scripts/test.sh` passes (no reference to the deleted test/integration block; the `task`-enum probe repointed and green).
- [ ] `/CJ_portability-audit` + `validate.sh` Check 18 still function unchanged (the separate test survives).
- [ ] A dry-run of a cj_goal orchestrator no longer lists a portability gate node.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] `scripts/cj-goal-common.sh`: delete the `--phase portability-audit` block, the `resolve_portability_engine()` helper, and remove `portability-audit` from the phase enum + usage string + header/phase-list comments.
- [ ] Four orchestrators (`CJ_goal_feature`, `CJ_goal_task`, `CJ_goal_defect`, `CJ_goal_todo_fix`): remove the Step 5.7 portability gate handler, the `[portability-red]`/`halted_at_portability` halt-taxonomy rows, the PR-body `### Portability` verdict surfacing, the `.cj-goal-feature/portability-verdict.md` write, the overview-chain portability node, and Usage/Notes/Error-Handling/resume mentions (pipeline.md + SKILL.md + USAGE.md each).
- [ ] `spec/test-spec-custom.md`: remove the `gates:` portability row (order 60) + the cj_goal-gate `units:` rows + the ratchet row; KEEP the Check 18 unit row + engine unit row; adjust the goal-common phase-integration unit row to drop `portability-audit`.
- [ ] `spec/workflow-spec.md`: remove the portability-gate node + verdict wording from all four charts/Touches; drop `portability-audit` from the `cj-goal-common` phase list; KEEP the `/CJ_portability-audit` roster entry; then `bash scripts/workflow-spec.sh --render-docs`.
- [ ] Tests: delete `tests/cj-goal-common-portability.test.sh`; in `scripts/test.sh` remove the Step 6b integration block + the deleted-test runner line, and REPOINT the `task`-enum probe to a surviving phase (`--phase recap --mode task` or `--phase sync --mode task --dry-run`); update any enumerated-phase assertions in `tests/test-spec.test.sh` / `tests/cj-goal-common-sync.test.sh`; KEEP the F000047/S000083 engine fixture block.
- [ ] `CLAUDE.md`: delete the "Pre-ship portability gate (F000051 / S000091)" section + drop `halted_at_portability` from halt-taxonomy prose; KEEP standalone `/CJ_portability-audit` + Check 18 prose.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-02: Created. Remove the portability-audit gate from all four cj_goal orchestrators; portability stays enforced by the standalone test (validate.sh Check 18 + /CJ_portability-audit).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-goal-common.sh`
- `skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_feature/USAGE.md`
- `skills/CJ_goal_task/` (pipeline.md or SKILL.md) + `SKILL.md` + `USAGE.md`
- `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_defect/SKILL.md`, `skills/CJ_goal_defect/USAGE.md`
- `skills/CJ_goal_todo_fix/pipeline.md`, `skills/CJ_goal_todo_fix/SKILL.md`, `skills/CJ_goal_todo_fix/USAGE.md`
- `spec/test-spec-custom.md`
- `spec/workflow-spec.md`, `docs/workflow.md`, `docs/workflows/*.md` (regenerated)
- `tests/cj-goal-common-portability.test.sh` (deleted), `scripts/test.sh`, `tests/test-spec.test.sh`, `tests/cj-goal-common-sync.test.sh`
- `CLAUDE.md`

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The portability gate is redundant belt-and-suspenders, not the primary guarantee: `validate.sh` Check 18 is strict-by-default globally (T000054), so a dishonest `portability` declaration already hard-fails every commit + CI + manual `validate.sh`. A cj_goal build commits at least twice (Step 3.5 pre-doc-sync commit + `/ship`), each firing the pre-commit hook → Check 18 strict. Removing the dedicated gate therefore creates NO portability hole.
- The gate already no-ops in consumer repos (engine absent → `PHASE_RESULT=skipped`), so the motivation is conceptual cleanliness (no workbench-specific logic in portable orchestrators), not fixing a live break elsewhere.
- Portability is a workbench-only concern — it audits `skills-catalog.json` declarations, which only exist in this repo. A portable orchestrator should not carry a check that only means something in one repo (separation-of-concerns / portability-of-the-pipeline-itself instinct).
- Self-modifying-pipeline note: this build edits the very orchestrator running it. Once implement removes the portability phase, the orchestrator's own later `--phase portability-audit` call no longer exists — the run recognizes the gate is removed by this change and proceeds to `/ship`. No skill's `portability` tier is relabeled, so nothing would have failed the gate anyway.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Chose Approach A (Full extraction) over B (Minimal unwire — leaves dead code + workbench-specific logic) and C (Soft-remove — still runs inside the orchestrators, adds behavior instead of removing it). Summary: fully remove the `--phase portability-audit` mechanism and all four orchestrators' wiring so the portable orchestrators carry zero portability logic; Check 18 preserves the guarantee.
