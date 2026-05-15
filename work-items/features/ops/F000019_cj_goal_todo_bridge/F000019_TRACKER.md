---
name: "/CJ_goal — auto-resolve TODOs that other tasks drop into TODOS.md"
type: feature
id: "F000019"
status: active
created: "2026-05-14"
updated: "2026-05-14"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

<!-- Scaffolded from /CJ_personal-pipeline on 2026-05-14 against design doc
     chjiang-main-design-20260514-162927.md. Single-child user-story shape:
     all build work lives in S000041_skill_skeleton. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_goal_todo_bridge`
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

- [ ] `/CJ_goal` skill installed (`skills/CJ_goal/SKILL.md` + `scripts/goal.sh` deployed)
- [ ] Catalog entry present in `skills-catalog.json` with `status: experimental`
- [ ] Routing rule added to `rules/skill-routing.md` for TODO-bridging triggers
- [ ] CLAUDE.md routing block updated
- [ ] Eval case `tests/eval/CJ_goal/preflight-halts/` with preflight-halt fixtures
- [ ] `scripts/validate.sh` clean

## Todos

- [ ] S000041 — build skill skeleton + scripts/goal.sh + catalog + routing + eval

## Log

- 2026-05-14: Created. /CJ_goal feature scaffold per design 20260514-162927.

## PRs

## Files

- `skills/CJ_goal/SKILL.md` (new)
- `skills/CJ_goal/scripts/goal.sh` (new)
- `skills-catalog.json` (modified — new entry)
- `rules/skill-routing.md` (modified — new triggers)
- `CLAUDE.md` (modified — routing block update)
- `tests/eval/CJ_goal/preflight-halts/` (new)

## Insights

- Design doc resolved via `/office-hours` produced 4 iterations (v1 → v4 via autoplan). Themes A (substrate), C (placeholder QA), B (continue set + per-session skip list) all addressed. Theme D deferred to a later cycle.
- Substrate dependencies all shipped within the past 24h: v3.4.1 (D000019 task-type pipeline), v3.4.2 (T000022 chmod +x), v3.4.3 (T000023 placeholder-test-plan refuse gate). /CJ_goal is the first skill to consume the full audited substrate.

## Journal

- [orchestrator] 2026-05-15T05:59:48Z pre-scaffold check: branch (d) clean-slate; Phase 1 scaffolded F000019 feature with 1 user-story child (S000041). Multi-story feature halt: pipeline halts here per Step 4 sub-step 3; end_state=green. Per-child iteration (S000041 impl + QA) deferred to manual or per-child /CJ_run dispatch. RUN_ID=20260514-225412-53566.
