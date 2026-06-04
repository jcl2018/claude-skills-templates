---
name: "Flatten /CJ_goal_todo_fix off /CJ_personal-pipeline and retire the skill"
type: feature
id: "F000039"
status: active
created: "2026-06-03"
updated: "2026-06-03"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-132322-16015"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/{slug}`
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

- [ ] `/CJ_goal_todo_fix` single-TODO mode dispatches `/CJ_implement-from-spec` → `/CJ_qa-work-item` as leaf Agent subagents; no `/CJ_personal-pipeline` reference remains in its SKILL.md / pipeline.md / scripts.
- [ ] Drain mode dispatches impl→qa per drained TODO; the `cj-worktree-init.sh --force-create` per-iteration isolation (`drain-one-todo.sh:255`) is unchanged and still asserted by any existing regression grep.
- [ ] `skills/CJ_personal-pipeline/` is deleted; its `skills-catalog.json` entry is removed; `CJ_goal_todo_fix`'s `depends.skills` no longer names it and lists the real dispatch deps.
- [ ] All live-surface references cleaned (doc/SKILL-CATALOG.md, doc/PHILOSOPHY.md, CLAUDE.md, rules/skill-routing.md, README.md regenerated, CJ_suggest, impl/qa/scaffold USAGE files, cj-handoff-gate.sh, validate.sh Check 12).
- [ ] Halt taxonomy renamed (`halted_at_pipeline_implement` / `halted_at_pipeline_qa` → `halted_at_impl` / `halted_at_qa`) in `CJ_goal_todo_fix/SKILL.md` + any telemetry end-states.
- [ ] `validate.sh` Check 12 block removed AND `test.sh` (~line 1138) reconciled in the SAME change — no red on the deleted `pipeline.md`.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` both green.
- [ ] `grep -rI "CJ_personal-pipeline" skills/ scripts/ doc/ rules/ CLAUDE.md README.md` returns nothing (work-items/ history out of scope and retained).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship child story S000072 (carries the full flatten + delete + reference-cleanup implementation).
- [ ] End-to-end verification: validate.sh + test.sh green; live-surface grep sweep returns nothing.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Flatten /CJ_goal_todo_fix to dispatch impl→qa leaf subagents directly (the F000027 feature/defect pattern), then delete /CJ_personal-pipeline — its last caller — and clean ~18 live-surface reference files.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_goal_todo_fix/SKILL.md` — flatten orchestration prose; rename halt taxonomy; update ASCII chart
- `skills/CJ_goal_todo_fix/pipeline.md` — rewrite handoff to dispatch impl→qa leaf subagents
- `skills/CJ_goal_todo_fix/scripts/todo_fix.sh` — DISPATCH_CHAIN echo (lines 678, 870); drop `--suppress-final-gate`
- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` — handoff + comments (lines 14, 34, 321); leave line 255 unchanged
- `skills/CJ_goal_todo_fix/USAGE.md` — drop personal-pipeline from Mental model / Related skills
- `skills/CJ_personal-pipeline/` — DELETE (SKILL.md, pipeline.md, USAGE.md, fixtures/)
- `skills-catalog.json` — remove CJ_personal-pipeline object; rewrite CJ_goal_todo_fix depends.skills
- `doc/SKILL-CATALOG.md`, `doc/PHILOSOPHY.md`, `CLAUDE.md`, `rules/skill-routing.md`, `README.md` (regenerated)
- `skills/CJ_suggest/{scripts/suggest.sh,SKILL.md}`, `skills/CJ_implement-from-spec/USAGE.md`, `skills/CJ_qa-work-item/{qa.md,USAGE.md}`, `skills/CJ_scaffold-work-item/USAGE.md`
- `scripts/cj-handoff-gate.sh` (denylist line 81 + comment line 66), `scripts/validate.sh` (Check 12 block), `scripts/test.sh` (~line 1138)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- After this change all three cj_goal orchestrators (feature / defect / todo_fix) share ONE flatten shape: orchestrator → leaf subagents, depth ≤ 2. Removes the last two-flat-plus-one-nested asymmetry.
- The flatten removes an indirection LAYER, not adds nesting: todo_fix dispatching impl→qa directly is depth ≤ 2, identical to feature/defect (the F000027 nested-subagent wall is respected).
- Per-TODO worktree isolation is owned by `drain-one-todo.sh:255` (`--force-create`) + the todo_fix preamble, NOT by personal-pipeline — so the flatten must not disturb them (verified at the D1 gate).
- `--work-item-dir` mode in personal-pipeline = "skip scaffold, run impl→qa" (`pipeline.md:158`); todo_fix already scaffolds the T-task dir in pure bash (lines 608-693), so the flattened chain is exactly impl→qa with the scaffold step omitted.
- The single most likely thing to be forgotten (per the known implement-subagent blind spot): validate.sh Check 12 removal MUST be paired with the test.sh ~line 1138 pipeline.md-guard reconciliation in the SAME change.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-03: Approach A (flatten both modes + delete /CJ_personal-pipeline in ONE PR) chosen at the D2 gate over B (flatten now, delete later — leaves a zero-caller experimental skill + a second PR) and C (re-consolidate all three orchestrators into personal-pipeline — re-introduces the F000027 nested-subagent wall). Summary: directly fulfills "retire"; flatten pattern is battle-tested by feature/defect; the PR is the review gate.
- [decision] 2026-06-03: "Retire" = straight delete, no shim. personal-pipeline is `experimental`, never a routable front door; F000035 already removed deprecation infrastructure, so no alias / `deprecated/` machinery to honor. Summary: tree left in its final state.
- [decision] 2026-06-03: `--suppress-final-gate` flag is DROPPED, not translated — it is a personal-pipeline-only concept (suppresses that skill's Step 8.5/9.2 AUQs); the impl/qa leaf subagents have no such gate. Summary: the leaf subagents run silent/no-AUQ exactly as in CJ_goal_feature; drain mode is already `--quiet`-friendly, so no AUQ regression.
