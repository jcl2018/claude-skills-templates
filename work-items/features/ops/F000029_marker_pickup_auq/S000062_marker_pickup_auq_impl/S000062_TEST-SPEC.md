---
type: test-spec
parent: S000062
feature: F000029
title: "Marker-pickup AUQ implementation — Test Specification"
version: 1
status: Approved
date: 2026-05-30
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
| S1 | core | AC-1 | Script exists, executable, shellcheck-clean | `scripts/skills-doc-sync-check` is present, has exec bit, passes shellcheck | `test -x scripts/skills-doc-sync-check && shellcheck scripts/skills-doc-sync-check` |
| S2 | core | AC-2 | Default invocation emits on hit, silent otherwise (cases a + b from design) | Marker present + clean cache → `DOC_SYNC_PENDING <path>`; no marker → silent. Both exit 0. | `bash tests/skills-doc-sync-check.test.sh` (cases a + b) |
| S3 | core | AC-3, AC-4 | Snooze + Skip suppress correctly (cases c + d) | `--snooze 24` silences for 24h then re-fires; `--skip <sha>` silences while sha matches, re-fires on new sha | `bash tests/skills-doc-sync-check.test.sh` (cases c + d) |
| S4 | core | AC-5 | --resolved closes loop + idempotent (cases e + e2) | `--resolved` deletes marker + clears cache; calling again on absent marker is silent success | `bash tests/skills-doc-sync-check.test.sh` (cases e + e2) |
| S5 | resilience | AC-6, AC-7 | Stale head_sha + corrupted JSON self-clean (cases f + g) | Unreachable head_sha → silent delete; truncated JSON → silent delete via stale-SHA path | `bash tests/skills-doc-sync-check.test.sh` (cases f + g) |
| S6 | integration | AC-8, AC-9, AC-10 | All 3 SKILL.md preambles have identical-modulo-comment bash block + AUQ prose | `diff` extracted preamble blocks across 3 SKILL.md files; grep prose for branch-detection + auto-commit text | `diff <(sed -n '/Doc-sync pending check/,/^$/p' skills/cj_goal_feature/SKILL.md) <(sed -n '/Doc-sync pending check/,/^$/p' skills/cj_goal_defect/SKILL.md)` (and same for CJ_goal_investigate); plus `grep -l "docs: post-merge sync for" skills/*/SKILL.md` returns all 3 |
| S7 | integration | AC-11 | Test file present and runs case h | `tests/skills-doc-sync-check.test.sh` exists; case (h) confirms script silent on non-main branches too | `test -f tests/skills-doc-sync-check.test.sh && bash tests/skills-doc-sync-check.test.sh` (case h) |
| S8 | observability | AC-12 | CLAUDE.md doc-sync subsection added | `grep -c "Doc-sync check mechanism (F000028 follow-up)" CLAUDE.md` returns 1; section is below F000009's | `grep -A2 "Doc-sync check mechanism (F000028 follow-up)" CLAUDE.md` |

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
| E1 | usability | AC-2, AC-9, AC-10 | Plant a marker on main; invoke `/cj_goal_feature "test topic"`; verify AUQ surfaces with all 3 marker fields populated and operator can pick Y → /document-release runs → auto-commit happens → marker deleted → pipeline continues | (1) Plant marker: `echo '{"head_sha":"'$(git rev-parse HEAD)'","main_moved_at":"2026-05-30T22:00:00Z","changed_files":3}' > ~/.gstack/doc-sync-pending/claude-skills-templates.json`. (2) From repo root on main, run `/cj_goal_feature "test topic"`. (3) When AUQ surfaces, pick option A. (4) Verify `/document-release` runs to green. (5) Verify auto-commit happened (`git log -1 --format=%s` shows `docs: post-merge sync for claude-skills-templates (auto via doc-sync-check)`). (6) Verify marker deleted (`test ! -f ~/.gstack/doc-sync-pending/claude-skills-templates.json`). (7) Verify pipeline proceeds to Step 1.9 with clean tree. | AUQ surfaces with `head_sha`, `main_moved_at`, `changed_files` all populated from the marker; A path completes end-to-end without HALT at Step 1.9. | All 7 steps observable; no error messages; pipeline reaches Step 1.9 isolation gate cleanly. |
| E2 | usability post-ship | AC-2, AC-9 | Plant a marker on a feature branch; invoke `/cj_goal_defect "test bug"`; verify AUQ recommends "Snooze 1h" (not "Run /document-release") because branch is not main | (1) Plant marker (same as E1 step 1). (2) `cd` into an existing `.claude/worktrees/<some-branch>/` (not main). (3) Run `/cj_goal_defect "test bug"`. (4) Verify AUQ surfaces. (5) Verify the AUQ option ordering puts "Snooze 1h" as the recommended/default (not "Run /document-release"). (6) Pick option B (snooze 1h). (7) Verify pipeline continues. | AUQ surfaces; recommended option is "Snooze 1h" (not A); operator can complete B path; pipeline continues without invoking `/document-release` on the wrong branch. | Observable AUQ recommendation; no invocation of `/document-release` on non-main branch. Tag: post-ship because requires already-merged F000029 in the live preamble. |
| E3 | resilience post-ship | AC-3, AC-4 | Verify snooze and skip both work across separate cj_goal invocations in the same shell + across new shells | (1) Plant marker. (2) Run `/cj_goal_feature`, hit "Snooze 24h" at the AUQ. (3) Immediately re-invoke `/cj_goal_feature` in same shell. (4) Verify NO AUQ surfaces (silent). (5) Open a new shell, re-invoke. (6) Verify NO AUQ surfaces (silent — cache is user-global, not shell-scoped). (7) `bash scripts/skills-doc-sync-check --resolved` to reset; plant new marker; verify AUQ surfaces again. (8) This time hit "Skip" → re-invoke → silent. (9) Plant a NEW marker with a different head_sha → invoke → AUQ surfaces again. | Snooze silences across both same-shell and new-shell invocations for 24h; skip silences only the specific head_sha; new head_sha re-fires AUQ. | All 9 steps observable; silence behavior consistent; new head_sha behavior correct. Tag: post-ship for the live-preamble behavior. |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| `/document-release` itself failing mid-write (partial doc edits) and the fallback "Snooze 1h + leave marker" path | Hard to deterministically trigger `/document-release` failure in a fixture; the fallback path is documented in SKILL.md prose but only exercised live. | Operator notices half-updated docs in `git status` after Y-path Skill returns non-green; reverts via `git checkout -- <files>` or commits by hand. |
| Cross-repo basename collision (two repos with the same basename overwriting each other's marker) | Inherited limitation from F000028's hook; same edge case, not introduced by F000029. | Operator with two repos named `foo/` on the same machine sees marker collisions; documented as known limitation in F000028's tracker. |
| Auto-commit on A-path with a non-default git config (e.g., signing required, no signing key available) | Operator's git config drives commit behavior; we don't override. | If signing required + no key, commit fails; operator sees the error and resolves manually. Same behavior as any other auto-commit in the workbench. |
| `tests/skills-doc-sync-check.test.sh` running against operator's real `$HOME` (could trash their real cache) | Test fixture uses `HOME=$TMPDIR` per row + `trap` cleanup; cannot affect real state. | Documented in the test file's preamble; reviewed at QA. |
