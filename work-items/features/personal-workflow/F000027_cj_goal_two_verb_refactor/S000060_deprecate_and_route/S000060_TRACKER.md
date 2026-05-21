---
name: "Deprecate /CJ_goal_run + /CJ_goal_auto (alias + sunset) + routing + catalog"
type: user-story
id: "S000060"
status: active
created: "2026-05-21"
updated: "2026-05-21"
parent: "F000027"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/hardcore-hermann-c2b955"
blocked_by: ""
# pr: ""
---

<!-- Prerequisite: derives directly from the parent feature's /office-hours
     session; the parent F000027_DESIGN.md is sufficient design context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_two_verb_refactor` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
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
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `/CJ_goal_run` and `/CJ_goal_auto` each become a hard alias shim: print a one-line deprecation banner, then route to `/cj_goal_feature`.
- [ ] Both carry a sunset date (next major, e.g. v6.0.0), mirroring the existing `CJ_run → CJ_goal_run` alias pattern.
- [ ] `/CJ_goal_todo_fix` + `/CJ_personal-pipeline` are kept and still work; `/schedule` + `/loop` integrations unaffected.
- [ ] `rules/skill-routing.md` + `CLAUDE.md` routing updated to point "build a feature"/"fix a bug" at the two new verbs.
- [ ] `skills-catalog.json`: 2 new `experimental` entries (`cj_goal_feature`, `cj_goal_defect`) present; `CJ_goal_run` + `CJ_goal_auto` → `deprecated`. Deprecated skills stay installable via `--include-deprecated`; in-flight items finish under them.
- [ ] `validate.sh` + `test.sh` green after the catalog/routing changes.

## Todos

<!-- Actionable items for this story. -->

- [ ] Convert `skills/CJ_goal_run/SKILL.md` + `skills/CJ_goal_auto/SKILL.md` to hard alias shims (banner → route to `/cj_goal_feature`) with a sunset date.
- [ ] Flip both catalog entries to `status: deprecated`; ensure the 2 new verb entries are `experimental`.
- [ ] Relocate deprecated skill sources per the deprecation convention if required (catalog path is source of truth).
- [ ] Update `rules/skill-routing.md` + `CLAUDE.md` routing lines.
- [ ] Re-run `validate.sh` + `test.sh`; regenerate README from catalog if needed.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-21: Created. Deprecate `/CJ_goal_run` + `/CJ_goal_auto` with hard alias shims + a sunset date; keep `/CJ_goal_todo_fix` + `/CJ_personal-pipeline`; update routing + catalog.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_goal_run/SKILL.md` (→ alias shim; possibly relocated under `deprecated/` per convention)
- `skills/CJ_goal_auto/SKILL.md` (→ alias shim; possibly relocated under `deprecated/` per convention)
- `skills-catalog.json`
- `rules/skill-routing.md`
- `CLAUDE.md`
- `README.md` (regenerated from catalog if needed)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Deprecation in this repo is three paired layers (catalog status + skill source relocation + work-item history relocation); the catalog is the source of truth for paths, so consumer scripts derive `dirname(files[0])`.
- Keep `/CJ_personal-pipeline` because it's still `/CJ_goal_todo_fix`'s internal engine — migrating todo_fix off it is a deferred follow-up, after which personal-pipeline could be deprecated too.
- Deprecated skills must stay installable (`--include-deprecated`) so items mid-pipeline can finish under them (in-flight migration).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-21: Hard alias shims (banner → route to `/cj_goal_feature`) + sunset at the next major (D5 CONFIRMED + alias/sunset added at GATE #1). Summary: mirrors the existing `CJ_run → CJ_goal_run` alias pattern; gives consumers a clear migration path and a removal date.
- [decision] 2026-05-21: Keep `/CJ_goal_todo_fix` + `/CJ_personal-pipeline`; deprecate only `run` + `auto`. Summary: the drain utility is orthogonal and working; only the cluttered front-door middle is collapsed.
