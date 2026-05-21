---
name: "Helper prep — cj-worktree-init.sh --caller extension + cj-goal-common.sh + early feature smoke harness"
type: user-story
id: "S000057"
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
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
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

- [x] `cj-worktree-init.sh --caller feature` resolves to prefix `cj-feat` and `--caller defect` to `cj-def`; both exit 0 (no longer `state:failed`/`exit 1`).
- [x] `cj-goal-common.sh` exposes deterministic worktree-init, telemetry/audit-receipt write, and PR-existence-check operations gated by explicit mode flags (`--phase <p> --mode feature|defect`).
- [x] An early `feature` smoke harness validates the feature path (worktree → leaf-subagent dispatch shape) and is runnable before the `/cj_goal_feature` skill (S000059) lands.
- [x] Existing callers of `cj-worktree-init.sh` (`cj-run`, `cj-todo`, `cj-inv`) keep working unchanged; `validate.sh` stays green. *(Non-regression met: matrix h3/h4/h5. NOTE: full `test.sh` is not globally green — `test-deploy.sh` Test 8 fails PRE-EXISTING + UNRELATED, see [qa-pass] journal.)*

## Todos

<!-- Actionable items for this story. -->

- [x] Add `feature`→`cj-feat`, `defect`→`cj-def` to the `cj-worktree-init.sh` `--caller` validator `case` (lines 55-57) + prefix map.
- [x] Write `scripts/cj-goal-common.sh` with `--phase`/`--mode` flags covering worktree init, telemetry write, PR checks.
- [x] Add an early `feature` smoke harness (e.g. `tests/cj-goal-feature-smoke.test.sh`).
- [x] Add/extend `tests/cj-worktree-init.test.sh` rows for the two new callers.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-21: Created. Foundation story — extend the worktree-init caller validator, add the deterministic common helper, and stand up an early feature smoke harness before the verb skills land.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/cj-worktree-init.sh` (modified) — added `feature`→`cj-feat`, `defect`→`cj-def` to the `--caller` validator `case` + prefix map; header comment updated. Existing `run`/`investigate`/`todo` rows unchanged.
- `scripts/cj-goal-common.sh` (new) — deterministic helper gated by `--phase {worktree|telemetry|pr-check|ship}` / `--mode {feature|defect}`. Trio: worktree-init (delegates to `cj-worktree-init.sh`), telemetry JSONL audit-receipt write, read-only PR-existence check. KEY=VALUE stdout; shellcheck-clean.
- `tests/cj-worktree-init.test.sh` (modified) — added the Case (h) caller→prefix matrix: 2 new callers resolve (h1/h2), 3 existing callers non-regressed (h3/h4/h5), unknown caller still rejected (h6).
- `tests/cj-goal-feature-smoke.test.sh` (new) — early feature-path SHAPE harness (worktree entry → shared-plumbing dispatch → workbench-owned leaf dispatch targets present), independent of the not-yet-existing `/cj_goal_feature` skill.

## Insights

<!-- Non-obvious findings worth remembering. -->

- The shipped `/CJ_goal_auto --caller auto` already trips the unknown-caller rejection (lines 55-57) — a latent bug, moot once `auto` is deprecated in S000060.
- The early smoke harness exists specifically because the defect-first sequencing never exercises the feature tail; without it the riskier skill is unvalidated until PR #2.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-21: Common bits become deterministic bash (`cj-goal-common.sh`) with mode flags, not an LLM-followed orchestrator. Summary: keeps the common logic testable and drift-free while leaving skill-tool invocations inline in each verb skill (Approach A).
- 2026-05-21 [impl-decision] Resolved the SPEC Open Question (which phases `cj-goal-common.sh` covers): kept the phase set MINIMAL at the agreed floor — `worktree`, `telemetry`, `pr-check` — the trio named in the SPEC. `--phase ship` is accepted as an alias for `pr-check` (the PR-creation seam where the verb skills run the PR existence check), so TEST-SPEC S3 (`--phase ship --mode feature`) passes without widening the operation set. Did not add speculative phases (scaffold/impl/qa stay inline skill-tool invocations per Approach A / F000027_DESIGN #4).
- 2026-05-21 [impl-decision] cj-goal-common.sh mirrors repo conventions: KEY=VALUE stdout schema (like `cj-handoff-gate.sh`), `set -u` not `-e` (explicit error handling so a phase op failure yields a clean exit code), JSONL audit-receipt via jq with sanitized-echo fallback (like `auto.md` `_write_receipt`), and a 2-level worktree-helper resolver (sibling dir, then manifest `.source`) matching `drain-one-todo.sh`. Telemetry receipt path is per-verb: `~/.gstack/analytics/cj-goal-<mode>.jsonl`.
- 2026-05-21 [impl-decision] pr-check phase is read-only + fail-SOFT (PR_CHECK=skipped / exit 0 when `gh` is offline/unauthenticated), mirroring `check-version-queue.sh` offline tolerance — a hard failure here would block both verb skills on a network blip. The feature smoke harness's S3 row accepts both `ok` and `skipped` so it stays green in offline CI.
- 2026-05-21 [impl-finding] The skill's own sensitive-surface heuristic (implement.md Step 6.4) does NOT flag `scripts/cj-worktree-init.sh` (its list names validate.sh/test.sh/test-deploy.sh, manifests, catalog, templates, .git/hooks). The orchestrator separately flagged cj-worktree-init.sh as load-bearing (4 shipped callers: run/investigate/todo + auto) and PRE-APPROVED the `--caller` extension. Honored that approval; extended NON-REGRESSIVELY (widened the allow-list `case` + prefix map only; existing run/investigate/todo behavior byte-unchanged, proven by matrix cases h3/h4/h5).
- 2026-05-21 [impl-finding] `scripts/test.sh` (full suite) reports 1 FAIL: `test-deploy.sh` Test 8 "Doctor on healthy install" → `WARN: CJ_goal_auto — source directory missing in repo`. PRE-EXISTING + UNRELATED: reproduces with my tracked edits stashed (clean-tree EXIT=1, identical WARN); `skills/CJ_goal_auto/` exists in-repo; the WARN fires in test-deploy's temp install sandbox against a stale deployed manifest (installed 4.6.7 vs current 5.0.2, `.source` → parent checkout). Touches none of my 4 files. Flagged via spawn_task for a separate /investigate. Not a blocker for S000057.
- 2026-05-21 [impl] Modified 2 files (scripts/cj-worktree-init.sh, tests/cj-worktree-init.test.sh); created 2 (scripts/cj-goal-common.sh, tests/cj-goal-feature-smoke.test.sh). New `.sh` files chmod +x. `bash tests/cj-worktree-init.test.sh` PASS (all cases incl. new matrix h1-h6); `bash tests/cj-goal-feature-smoke.test.sh` PASS (6/6); `bash scripts/validate.sh` PASS (0 errors, 0 warnings); shellcheck clean on cj-goal-common.sh + cj-worktree-init.sh. 6 journal entries added.
- 2026-05-21 [impl-auto] Auto-equivalent run (--auto): 4 files touched (> the 2-file triviality bar → normally MODE=propose), but the orchestrator pre-collected the one sensitive-surface AUQ (cj-worktree-init.sh extension = APPROVED) and this runner has no AUQ tool, so proceeded without a propose-and-confirm preview per the orchestrator contract.
- 2026-05-21 [impl-pass] S000057: implementation complete. Phase 2 implementer-owned gates transitioned (Todos section reflects remaining work; Files section updated with changed files). QA-owned gates (Acceptance criteria verified met; Smoke tests pass) left for /CJ_qa-work-item.
- 2026-05-21 [qa-smoke-summary] green — 5/5 smoke rows PASS: S1/S2 (`--caller feature`→cj-feat, `--caller defect`→cj-def accepted, exit 0), S3 (`cj-goal-common.sh --phase ship --mode feature` exit 0; `ship` is the documented `pr-check` alias per the impl-decision above), S4 (existing run/investigate/todo callers non-regressed — matrix h3/h4/h5), S5 (`cj-goal-feature-smoke.test.sh` 6/6). `validate.sh` PASS (0/0).
- 2026-05-21 [qa-e2e] green — E1: feature-caller prefix resolution validated via smoke S1 (worktree CREATION not exercisable from inside a worktree — `cj-worktree-init` returns `state:detected`; accepted env limitation). E2: `cj-goal-common.sh` ran clean across `--phase worktree|telemetry|pr-check --mode feature`, each deterministic exit 0. E3 = feature smoke harness PASS. (Rows are pure-bash; run parent-inline, no E2E subagent needed.)
- 2026-05-21 [qa-pass] S000057: QA green for this story's scope. AC-1/AC-2/AC-3 fully verified met. AC-4 non-regression met (existing callers byte-unchanged + matrix h3/h4/h5 green + `validate.sh` green). NOTE: AC-4's literal "test.sh stays green" is NOT globally true — `test-deploy.sh` Test 8 (`CJ_goal_auto` source-dir WARN) fails, but it is PRE-EXISTING + UNRELATED (reproduces with S000057 edits stashed; deployed-manifest version skew 4.6.7 vs 5.0.2), NOT a regression from S000057; tracked separately for /investigate. Phase 2 QA-owned gates transitioned. Ran top-level (not as a pipeline subagent) to keep /CJ_qa-work-item's E2E dispatch wall-safe.
