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
