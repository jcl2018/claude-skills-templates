---
name: "Batched rename CJ_run → CJ_goal_run + CJ_goal → CJ_goal_todo_fix"
type: user-story
id: "S000044"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000021"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_run_cj_goal_batch_rename` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (parent F000021 design)
- [ ] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI
3. Walk E2E manually
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version (3.6.5 → 4.0.0), updates changelog
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `git mv skills/CJ_run skills/CJ_goal_run` and `git mv skills/CJ_goal skills/CJ_goal_todo_fix` complete cleanly with all references updated.
- [ ] `skills-catalog.json` has both renamed entries (2 entries renamed) with updated paths.
- [ ] `rules/skill-routing.md` ~12 entries updated to new names (no stale `/CJ_run` or `/CJ_goal` references except in the alias-banner files).
- [ ] CLAUDE.md (workbench + global) routing block updated.
- [ ] Old `/CJ_run` and `/CJ_goal` invocations succeed during v4.x: skill prints a one-line deprecation banner ("renamed to /CJ_goal_run; will be removed in v5.0.0") then delegates to the new skill.
- [ ] Telemetry path migration: skills read `~/.gstack/analytics/CJ_run.jsonl` as fallback during v4.x; new writes go to `CJ_goal_run.jsonl`. Same for /CJ_goal → /CJ_goal_todo_fix.
- [ ] VERSION bumped 3.6.5 → 4.0.0 (major; rename-only break).
- [ ] All existing `/CJ_run` and `/CJ_goal` workflow tests (`scripts/test.sh`, eval cases) pass against the renamed skills.
- [ ] Squash-merged PR via `gh pr merge <PR#> --squash --delete-branch` (per workbench CLAUDE.md convention; no `--auto`).

## Todos

- [ ] `git mv skills/CJ_run skills/CJ_goal_run`
- [ ] `git mv skills/CJ_goal skills/CJ_goal_todo_fix`
- [ ] Update `skills-catalog.json` (2 entries renamed)
- [ ] Update `rules/skill-routing.md` (~12 entries)
- [ ] Update `CLAUDE.md` (workbench routing block + naming-convention notes)
- [ ] Update `~/.claude/CLAUDE.md` (global routing block — apparent at install time)
- [ ] Write alias `skills/CJ_run/SKILL.md` (thin alias printing deprecation banner + delegating)
- [ ] Write alias `skills/CJ_goal/SKILL.md` (same pattern)
- [ ] Update telemetry paths: read both old + new; write new only
- [ ] Rename `skills/CJ_goal/scripts/goal.sh` → `skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (cosmetic for internal consistency)
- [ ] Run `./scripts/skills-deploy install` to verify deployment paths
- [ ] Run `./scripts/validate.sh` and `./scripts/test.sh` to verify regression-free
- [ ] Update VERSION (3.6.5 → 4.0.0) — major bump for rename-only break
- [ ] Update CHANGELOG.md v4.0.0 entry — document rename + alias retention through v4.x
- [ ] Regenerate README via `./scripts/generate-readme.sh`

## Log

- 2026-05-15: Created. Batched rename of /CJ_run → /CJ_goal_run + /CJ_goal → /CJ_goal_todo_fix in a single chore PR. Pure mechanical `git mv` + reference updates; ~800 LOC fully-grep-able diff. Major version bump (rename-only break, v3.6.5 → v4.0.0).

## PRs

## Files

- skills/CJ_run/ → skills/CJ_goal_run/ (rename)
- skills/CJ_goal/ → skills/CJ_goal_todo_fix/ (rename)
- skills/CJ_run/SKILL.md (NEW — thin alias with deprecation banner)
- skills/CJ_goal/SKILL.md (NEW — thin alias with deprecation banner)
- skills-catalog.json (2 entries renamed)
- rules/skill-routing.md (~12 entries updated)
- CLAUDE.md (workbench)
- ~/.claude/CLAUDE.md (global; if applicable to deploy)
- skills/CJ_goal_todo_fix/scripts/goal.sh → todo_fix.sh (cosmetic rename)
- VERSION (3.6.5 → 4.0.0)
- CHANGELOG.md (v4.0.0 entry)
- README.md (regenerated)

## Insights

- Batching renames in a single PR avoids the awkward "PR 1 shipped, PR 2 didn't" intermediate state where one rename is live and the other isn't. Autoplan-gate confirmed this approach (auto-approved per P3 pragmatic).
- Alias delegation: `skills/CJ_run/SKILL.md` becomes a thin wrapper that prints the deprecation banner THEN delegates to the new skill. Operator muscle memory protected; no broken invocations during v4.x.
- Telemetry fallback-read pattern: new skill reads both old + new paths and merges before sunset trip-wire scans the prior 5 invocations. Avoids history loss during the rename window.

## Journal

- [decision] 2026-05-15: Batched PR 1 + PR 2 (rename CJ_run + rename CJ_goal) per autoplan-gate approval — single chore PR, ~800 LOC mechanical diff. Cuts release-train from 5 PRs to 4.
- [decision] 2026-05-15: Major version bump v3.6.5 → v4.0.0 — rename-only break, no semantic changes. Aliases retained through v4.x with deprecation banner; removed in v5.0.0 (soft cutover).

- [orchestrator] 2026-05-15 17:25: --work-item-dir mode (Branch (e)) — using pre-staged dir; Phase 1 scaffold skipped. RUN_ID=20260515-172551-28106. SUPPRESS_FINAL_GATE=1.
- [orchestrator] 2026-05-15 17:32: Phase 2 implementation complete.
  Files modified:
  - skills/CJ_run/ → skills/CJ_goal_run/ (git mv) + internal refs updated in SKILL.md, run.md (1100+ lines, all /CJ_run → /CJ_goal_run except 1 historical "formerly /CJ_run" preserved); description.formerly preserved; version bumped 0.5.0 → 1.0.0.
  - skills/CJ_goal/ → skills/CJ_goal_todo_fix/ (git mv) + internal refs updated in SKILL.md, scripts/goal.sh → todo_fix.sh; parent_skill in telemetry JSON updated; description.formerly preserved; version bumped 1.1.0 → 2.0.0.
  - skills/CJ_run/SKILL.md (NEW thin alias, version 4.0.0, status experimental) — prints deprecation banner + Skill: CJ_goal_run delegation.
  - skills/CJ_goal/SKILL.md (NEW thin alias, version 4.0.0, status experimental) — prints deprecation banner + Skill: CJ_goal_todo_fix delegation.
  - skills-catalog.json: 2 renamed entries (CJ_goal_run, CJ_goal_todo_fix) + 2 new alias entries (CJ_run, CJ_goal). CJ_personal-pipeline + CJ_suggest descriptions also updated to reference new names. Total entries: 11 → 13.
  - rules/skill-routing.md: 12 routing entries updated; "Legacy aliases" footer block added.
  - CLAUDE.md (workbench): top routing block + TODOS.md hygiene section updated; legacy alias note added.
  - scripts/validate.sh: line 665 doctor message updated /CJ_goal → /CJ_goal_todo_fix.
  - templates/CJ_personal-workflow/tracker-user-story.md: comment line /CJ_run → /CJ_goal_run.
  - skills/CJ_personal-pipeline/SKILL.md, pipeline.md: cross-references updated.
  - skills/CJ_goal_run/run.md: telemetry sunset trip-wire fallback-reads legacy ~/.gstack/analytics/CJ_run.jsonl.
  - VERSION: 3.6.5 → 4.0.0.
  - CHANGELOG.md: v4.0.0 entry with rename rationale, migration notes, and follow-up work.
  - README.md: regenerated via ./scripts/generate-readme.sh from updated catalog.
  - ~/.claude/skills/CJ_run/{fixtures,run.md} and ~/.claude/skills/CJ_goal/scripts: stale dangling symlinks cleaned post-deploy.
  Sensitive-surface AUQs (Step 5.2) auto-approved per pipeline contract: catalog wiring (in-blast-radius) + skill scripts surface (cosmetic rename per Tradeoffs row 5).
- [validate-pass] 2026-05-15 17:38: scripts/validate.sh — 0 errors, 0 warnings.
- [test-pass] 2026-05-15 17:42: scripts/test.sh — 0 failures, RESULT: PASS.
- [qa-smoke-summary] 2026-05-15 17:43: Smoke Tests S1-S5 from TEST-SPEC: green
  - S1 (structure): PASS — skills/CJ_goal_run/, skills/CJ_goal_todo_fix/, skills/CJ_run/SKILL.md, skills/CJ_goal/SKILL.md all exist
  - S2 (validate.sh regression-free): PASS — 0 errors, 0 warnings
  - S3 (catalog + manifest consistency): PASS — skills-deploy doctor shows OK for CJ_run, CJ_goal, CJ_goal_run, CJ_goal_todo_fix
  - S4 (alias delegation grep): PASS — both alias SKILL.md files contain the "renamed to /CJ_goal_*" deprecation phrase
  - S5 (VERSION + CHANGELOG): PASS — VERSION = 4.0.0; CHANGELOG.md has [4.0.0] entry
- [qa-pass] 2026-05-15 17:43: All 5 smoke tests green; E2E tests E1-E5 are integration / post-ship (deferred to /ship + /land-and-deploy + downstream consumer pickup verification per TEST-SPEC).
- [auto-final-gate-suppressed] 1 mechanical, 0 taste, 2 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (filter run_id=20260515-172551-28106)
