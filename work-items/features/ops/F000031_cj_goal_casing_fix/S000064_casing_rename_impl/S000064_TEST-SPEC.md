---
type: test-spec
parent: S000064
feature: F000031
title: "Casing rename + shim creation + catalog + cross-reference flips — Test Specification"
version: 1
status: Draft
date: 2026-05-31
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. For a single fix or task, use test-plan.md instead.

     Two tiers, distinguished by who edits them and when they run:
     - Smoke = automated regression. Lives in CI. You write it once and
       never touch it again.
     - E2E   = manual user-scenario verification. You sit down and run it
       after implementing and before /ship.

     Soft cap: 5 rows per tier. Validator emits [INFO] advisory if exceeded;
     not a violation. Exceed only when justified — the cap is a forcing
     function to pick the tests that prove the story works, not the tests
     that demonstrate completeness. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Once written, you should not need to edit these. Soft cap: 5 rows.
     Pick the structural checks that catch real regressions, not all checks
     that could exist. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2, AC-3, AC-4 | Renamed dirs + new shim dirs exist (per git's case-sensitive index); old lowercase skill paths absent from git index | Two-step git mv landed + shims created in correct location. NOTE: cannot use `! test -d skills/cj_goal_feature` because macOS APFS is case-insensitive and resolves the lowercase path to the same inode as the uppercase one — use `git ls-files` which is case-sensitive against git's stored path | `test -d skills/CJ_goal_feature && test -d skills/CJ_goal_defect && test -d deprecated/cj_goal_feature && test -d deprecated/cj_goal_defect && [ "$(git ls-files skills/cj_goal_feature 2>/dev/null \| wc -l)" -eq 0 ] && [ "$(git ls-files skills/cj_goal_defect 2>/dev/null \| wc -l)" -eq 0 ] && echo OK` |
| S2 | core | AC-5 | Catalog has 6 edits applied + validate.sh passes | The catalog correctly reflects the new state and passes the cross-check. NOTE: active entries inherit `status: experimental` from F000027 (no promotion to `active` was in scope for this casing-fix story) — widen the predicate to accept either | `jq -e '[.[] | select(.name=="CJ_goal_feature" and (.status=="active" or .status=="experimental") and .files[0]=="skills/CJ_goal_feature/SKILL.md")] \| length == 1' skills-catalog.json && jq -e '[.[] | select(.name=="cj_goal_feature" and .status=="deprecated" and .files[0]=="deprecated/cj_goal_feature/SKILL.md")] \| length == 1' skills-catalog.json && ./scripts/validate.sh` |
| S3 | core | AC-6, AC-8 | F000027 shim cross-refs flipped + S000060 regression test now asserts uppercase | The deprecation chain is one hop + test.sh continues to gate the assertion correctly | `grep -qE '/CJ_goal_feature' skills/CJ_goal_run/SKILL.md && grep -qE '/CJ_goal_feature' skills/CJ_goal_auto/SKILL.md && grep -qE "'/CJ_goal_feature'" scripts/test.sh && ./scripts/test.sh` |
| S4 | core | AC-2, AC-3, AC-7 | Self-references in renamed SKILL.md/pipeline.md flipped; runtime-state dirs preserved | No active-routing lowercase mentions in renamed skills; resume state dirs intact | `! grep -nE '/cj_goal_(feature\|defect)' skills/CJ_goal_feature/SKILL.md skills/CJ_goal_defect/SKILL.md skills/CJ_goal_feature/pipeline.md skills/CJ_goal_defect/pipeline.md && grep -q '\.cj-goal-feature/' skills/CJ_goal_feature/pipeline.md` |
| S5 | usability | AC-4 | Shim invocation prints the deprecation banner and routes to the uppercase canonical | The deprecation chain is intact end-to-end via the Skill tool | Manual: invoke `/cj_goal_feature "<dummy-topic>"` via Skill tool in a scratch session; verify one-line deprecation banner appears AND the Skill tool routes to `CJ_goal_feature`. (Captured as E2E E1 below — moved to E2E because requires a fresh-context invocation, not amenable to a one-line shell check.) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section
     below for semantics — applies to E2E rows only; smoke rows do not support
     post-ship deferral). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     You drive the feature as a real user would and observe the outcome.
     Soft cap: 5 rows. Each row should be one user-visible scenario,
     not one branch in the code. AC column maps each row to a SPEC
     acceptance criterion.

     Post-ship rows: if a row is structurally only verifiable AFTER the PR
     merges to main (e.g., `gh workflow run` against a CI workflow that
     doesn't exist on remote refs until merge), add the literal token
     `post-ship` to the row's Tag column (e.g., Tag = `core post-ship`
     or just `post-ship`). /CJ_qa-work-item Step 4 will filter these rows
     out of the E2E subagent dispatch and record a [qa-e2e-deferred] journal
     entry naming the row + its AC instead of forcing a pretend-green
     adjudication. Verification of post-ship rows happens after merge (via
     manual `gh workflow run` or via post-merge tooling). -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-4, AC-6 | Deprecation banner + auto-route works for lowercase invocation | (1) Operator invokes `/cj_goal_feature "test topic"` in a fresh Claude Code session (after `skills-deploy install --include-deprecated`). (2) Observe console output. | Output begins with one-line deprecation banner pointing at `/CJ_goal_feature`. The pipeline then proceeds identically to a direct `/CJ_goal_feature` invocation (worktree creation, office-hours, etc.). | PASS: banner appears AND pipeline runs through office-hours phase without re-prompting for skill resolution. FAIL: banner missing OR pipeline halts at routing. |
| E2 | core | AC-1, AC-5 | Direct canonical invocation works without banner | (1) Operator invokes `/CJ_goal_feature "test topic"` in a fresh Claude Code session. (2) Observe console output. | No deprecation banner. Pipeline runs through worktree creation + office-hours phase normally. | PASS: zero deprecation lines in output AND pipeline progresses. FAIL: spurious banner OR halt. |
| E3 | core | AC-7, AC-9, AC-11, AC-12 | Fresh-reader scan of routing surfaces shows uniform uppercase | (1) Operator opens `rules/skill-routing.md`, `CLAUDE.md`, `doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `README.md`, `CHANGELOG.md` (v5.0.12 entry). (2) Skim each for `cj_goal_feature` / `cj_goal_defect` mentions. | Every active-routing reference shows uppercase `CJ_goal_*`. Only annotated mentions (Deprecated front doors block, historical refs in CHANGELOG describing past lowercase state) remain lowercase. CHANGELOG v5.0.12 entry reads naturally in `## For users` voice. | PASS: zero active-routing lowercase mentions; CHANGELOG entry tells the migration story clearly. FAIL: any unannotated lowercase active-routing mention. |
| E4 | resilience | AC-10 | Version-slot preflight executed pre-`/ship` | (1) Implementer runs `./scripts/check-version-queue.sh && cat VERSION` immediately before `/ship`. (2) If reported slot != 5.0.12, implementer hand-edits the 3 baked-in literals. (3) Implementer runs `/ship`. | Either: slot == 5.0.12 (no edits needed), OR slot != 5.0.12 and the 3 literals (2 shim frontmatters + 2 catalog entries) are hand-edited to match before `/ship` commits. | PASS: `/ship` commits with all `version: X.Y.Z` strings agreeing across shim files + catalog entries + the VERSION file `/ship` bumps to. FAIL: post-`/ship` `git diff VERSION` shows a different number than the baked-in literals. |
| E5 | core | AC-1, AC-2, AC-3, AC-5, AC-6, AC-7, AC-8 | Pre-commit hook gates the rename PR | (1) Implementer stages all changes via `git add`. (2) Runs `git commit -m "<message>"`. (3) Observes pre-commit hook output. | Pre-commit hook runs `./scripts/validate.sh` + `./scripts/test.sh`. Both exit 0 (validate confirms catalog/filesystem cross-check passes against new state; test.sh confirms the just-flipped S000060 regression assertion passes). Commit succeeds. | PASS: commit succeeds without hook failures. FAIL: hook reports any validate or test failure — implementer must fix before re-committing. |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Memory-file references (`~/.claude/projects/.../memory/`) | Operator-local state per `feedback_workbench_scope`; excluded from PR diff. | Memory files may briefly show stale lowercase references after merge until operator runs the local follow-up grep. Low-impact — memory files are personal context, not routing infrastructure. |
| F000027 commit-history references in `git log` | Cannot rewrite history. | Historical commits keep their lowercase wording. Acceptable because shims preserve the lowercase invocation path; old bash examples in commit messages still execute. |
| Downstream-consumer repos (portfolio, exploration) | Workbench-only scope per `feedback_workbench_scope`. | Downstream repos with hardcoded `/cj_goal_feature` invocations continue to work via the shim. No automated migration; users update on their own cadence. |
| `/loop /cj_goal_feature` cron jobs / shell history | Operator-managed runtime artifacts. | Shims preserve the lowercase invocation. Users update cron entries manually if desired. |
| Migrating F000027's existing `CJ_goal_run` + `CJ_goal_auto` shims from `skills/` to `deprecated/` | DEFERRED to v6.0.0 sunset PR (TODOS row tagged `[v6.0.0 sunset]`). | Convention is documented but not uniformly applied across all 4 shims until v6.0.0 — acceptable because the F000027 shims will be removed entirely at sunset, so mid-life migration is pure churn. |
| Worktree branch prefix `cj-feat-*` / resume state dirs `.cj-goal-feature/` casing | KEEP lowercase per design Open Q #4 + #5 — runtime artifacts, not skill identity. | Operator typing `cj-feat-` in a branch list will see lowercase indefinitely. Documented in S000064_SPEC.md Story #7 + Story #3. Low cognitive load because branch prefixes are seen rarely vs. skill names. |
