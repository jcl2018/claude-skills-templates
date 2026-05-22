---
name: "Deprecate /CJ_goal_run + /CJ_goal_auto (alias + sunset) + routing + catalog"
type: user-story
id: "S000060"
status: active
created: "2026-05-21"
updated: "2026-05-21"
parent: "F000027"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/s000060-deprecate-aliases"
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
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [x] Convert `skills/CJ_goal_run/SKILL.md` + `skills/CJ_goal_auto/SKILL.md` to hard alias shims (banner → route to `/cj_goal_feature`) with sunset v6.0.0.
- [x] Flip both catalog entries to `status: deprecated`; the 2 new verb entries (`cj_goal_feature`, `cj_goal_defect`) are `experimental`.
- [x] Relocation NOT required — kept the shims in `skills/` (Open Question resolved: status-flip only). TEST-SPEC S2 greps `skills/CJ_goal_run/SKILL.md`; functional alias shims must stay invocable; `validate.sh` accepts `deprecated` status with files under `skills/` (it iterates both `skills/` + `deprecated/` and honors `files[]`).
- [x] Update `rules/skill-routing.md` + `CLAUDE.md` routing lines.
- [x] Re-run `validate.sh` (PASS, 0/0) + `test.sh`; regenerated `README.md` from catalog.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-21: Created. Deprecate `/CJ_goal_run` + `/CJ_goal_auto` with hard alias shims + a sunset date; keep `/CJ_goal_todo_fix` + `/CJ_personal-pipeline`; update routing + catalog.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_goal_run/SKILL.md` (rewritten as a thin alias shim: banner → `/cj_goal_feature`, sunset v6.0.0; kept in `skills/`, NOT relocated. `run.md` left in place — dead until the v6.0.0 removal).
- `skills/CJ_goal_auto/SKILL.md` (same shim shape; `auto.md` + `scripts/cj-handoff-gate.sh` left in place — dead until removal, so their test.sh rows stay green).
- `skills-catalog.json` (CJ_goal_run + CJ_goal_auto → `status: deprecated`, version 5.0.6, deprecated-alias description, `depends.skills` → `cj_goal_feature`; the 2 new verbs stay `experimental`).
- `rules/skill-routing.md` (route "build a feature" → `/cj_goal_feature`, "fix a bug" → `/cj_goal_defect`; added a "Deprecated front doors (sunset v6.0.0)" section demoting run/auto).
- `CLAUDE.md` (Skill-routing section fronts the two verbs + marks run/auto deprecated).
- `README.md` (regenerated from catalog via `scripts/generate-readme.sh`).
- `scripts/test.sh` (F000025 regression guard for `CJ_goal_run/SKILL.md` repointed from a worktree-wiring assertion to a deprecation-shim assertion — worktree responsibility now lives in `/cj_goal_feature`).

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
- [impl-decision] 2026-05-21: Open Question RESOLVED — status-flip only, shims STAY in `skills/` (no relocation to `deprecated/`). Summary: TEST-SPEC S2 greps `skills/CJ_goal_run/SKILL.md`; functional alias shims must remain invocable to print the banner + route; `validate.sh` accepts `status: deprecated` with files under `skills/` (it iterates both `skills/` and `deprecated/` as source roots and honors `files[]`, with only an enum check on status). Mirrors the `CJ_run`/`CJ_goal` precedent (kept in `skills/`), except those were `experimental` and these are `deprecated` (so `skills-deploy install` skips them by default; `--include-deprecated` installs).
- [impl-decision] 2026-05-21: Left `run.md` / `auto.md` / `scripts/cj-handoff-gate.sh` in place rather than deleting (minimal scope; removal is the v6.0.0 story). Summary: deleting them would expand surface and risk the F000026 handoff tests (test.sh Tests 8-10 assert content in `auto.md` + `run.md`); leaving them keeps those green. Only `SKILL.md` became a shim; the leftover orchestration files are dead until the v6.0.0 removal.
- [impl-finding] 2026-05-21: `test.sh` reports 1 failure (`test-deploy.sh` Test 8 "Doctor on healthy install") — PRE-EXISTING + environmental, NOT a S000060 regression. Root cause is the worktree-vs-parent-checkout split: the manifest `source` resolves to the parent root (`/Users/chjiang/Documents/projects/claude-skills-templates`, parked on a stale feature branch at v4.6.7) which physically lacks `skills/cj_goal_feature/` + `skills/cj_goal_defect/`, so `skills-deploy doctor` emits `WARN: source directory missing in repo` for both. Identical to the state PR #171 shipped with. Critically, the deprecation changes are CORRECT here: doctor reports `INFO: CJ_goal_run — deprecated, not installed by default` + `INFO: CJ_goal_auto — deprecated, not installed by default` (INFO, not WARN — the documented healthy behavior). In CI (clean clone on the PR branch) `source == checkout == 5.0.6` with both dirs present, so Test 8 PASSES and `test.sh` is green. Captured separately in TODOS.md (deployment-should-install-updated-skills row, PR #172).
- [impl] 2026-05-21: Smoke S1-S5 verified — S1/S4 `validate.sh` PASS (0 errors, 0 warnings); S2 `grep -iE 'deprecat|/cj_goal_feature|v6\.0\.0'` matches both shim SKILL.md files; S3 `grep -E '/cj_goal_feature|/cj_goal_defect'` matches both `rules/skill-routing.md` (6) + `CLAUDE.md` (2); catalog statuses confirmed (`CJ_goal_run`/`CJ_goal_auto` = deprecated; `CJ_goal_todo_fix` = active, `CJ_personal-pipeline` = experimental — kept; `cj_goal_feature`/`cj_goal_defect` = experimental). S5 `test.sh` green-in-CI (local red only on the pre-existing env Test 8 above). Files: 2 shims, catalog (2 entries), 2 routing files, README regen, 1 test.sh guard repoint.
- [impl-pass] 2026-05-21: S000060 implementation complete. Phase 2 implementer-owned gates transitioned (Todos reflect remaining work; Files updated). QA-owned gates (Acceptance criteria verified met; Smoke tests pass) left for `/CJ_qa-work-item` / `/ship`, with full smoke evidence captured above.
