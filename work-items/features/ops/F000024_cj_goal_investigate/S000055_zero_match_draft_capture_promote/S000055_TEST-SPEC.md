---
type: test-spec
parent: S000055
feature: F000024
title: "/CJ_goal_investigate zero-match draft capture + promote — Test Specification"
version: 1
status: Draft
date: 2026-05-16
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
     that could exist. AC column maps each row to a SPEC acceptance criterion.

     NOTE: exceeding the 5-row soft cap is justified here — these 9 rows each
     guard a distinct binding contract item (C1-C7) or a structurally-distinct
     crash/idempotency path. Collapsing them would lose regression coverage of
     a specific pinned requirement. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Zero-match fragment creates `.inbox/<slug>/DRAFT.md`, no D-ID; Step 3 idempotency resolves Row 1 | The `0)` body creates a non-canonical draft and the pipeline continues at Row 1 by construction | `scripts/test-resume-table.sh` (new case: zero-match draft create + Row 1) |
| S2 | core | AC-2, AC-7 | Same fragment re-invoked pre-promotion resolves the existing draft (no duplicate dir); stored `fragment:` echoed | Idempotent draft re-resolution + C5 stored-fragment echo | `scripts/test-resume-table.sh` (new case: verbatim pre-promotion re-invoke) |
| S3 | resilience | AC-3 | `pipeline.md` lines 105-107 do NOT clobber draft vars when `IS_DRAFT=1` | C1 regression guard — TRACKER stays `$DRAFT_DIR/DRAFT.md`, RCA_PATH/TEST_PLAN_PATH stay empty | `scripts/test-resume-table.sh` (new case: C1 var-clobber guard) |
| S4 | resilience | AC-4 | Iron-Law fail → no promotion, no D-ID; draft remains; halt `resume_cmd` uses the fragment, not empty `$DEFECT_ID` | C2 — blank `$DEFECT_ID` never leaks into Step 7 halts | `scripts/test-resume-table.sh` (new case: Iron-Law fail keeps draft, fragment resume_cmd) |
| S5 | resilience | AC-5 | Iron-Law pass → promotion mints D-ID, canonical TRACKER written BEFORE draft removed, draft removed | C3 commit-point ordering — TRACKER is the durable commit point | `scripts/test-resume-table.sh` (new case: promotion ordering) |
| S6 | resilience | AC-5 | Crash injected after `mkdir $CANON_DIR` but before TRACKER write → re-invoke does NOT allocate a second D-ID; orphan empty dir is harmless | C3 duplicate-D-ID crash window closed | `scripts/test-resume-table.sh` (new case: crash-before-TRACKER no second D-ID) |
| S7 | core | AC-10 | `--dry-run` on zero-match prints plan + pinned message, creates nothing, exits 0 (`end_state=dry_run_preview`) | Story #10 — dry-run zero side effects | `scripts/test-resume-table.sh` (new case: --dry-run zero-match) |
| S8 | observability | AC-6 | mkdir-lock held by stale `.scaffold.lock.d` → clean halt after >10s with `[promote-lock-timeout]` journal + telemetry `end_state=halted_at_promote_lock_timeout` | C4 lock-timeout full bookkeeping + 13th end-state | `scripts/test-resume-table.sh` (new case: stale-lock timeout halt) |
| S9 | resilience | AC-8 | Canonical resolver still ignores `.inbox/` drafts; lowercasing keeps a `D000099 …`-style fragment out of canonical resolution | C6 slug-isolation regression guard (resolver unchanged + lowercasing load-bearing) | `scripts/test-resume-table.sh` (new case: resolver ignores .inbox + lowercasing isolation) |
| S10 | integration | AC-12 | A TRACKER with `auto_scaffolded: true` + `promoted_from_draft: .inbox/x` frontmatter passes `./scripts/validate.sh` (and `/CJ_personal-workflow check`) with no `[DRIFT]`/`VIOLATION` on those keys | The two promotion-added frontmatter keys are tolerated by the validator (pass-through, or the strict allowlist was extended in this PR) | `./scripts/validate.sh` against a fixture defect TRACKER carrying both keys |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section
     below for semantics — applies to E2E rows only; smoke rows do not support
     post-ship deferral). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     You drive the feature as a real user would and observe the outcome.
     Soft cap: 5 rows. Each row should be one user-visible scenario,
     not one branch in the code. AC column maps each row to a SPEC
     acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-7 | One-command zero-match flow captures a draft and resumes it | Run `/CJ_goal_investigate "scratch demo bug for s000055 e2e"` against a tree with no matching canonical defect; observe; re-run the exact same phrase | First run: terminal prints the C7 draft-capture message naming `.inbox/scratch_demo_bug_for_s000055_e2e/`, no D-ID; `DRAFT.md` exists. Second run: terminal prints the C7 draft-resume message echoing the stored fragment; no duplicate dir | PASS if a single draft dir exists after both runs, both C7 messages are plain-English and name the path, and no D-ID was allocated |
| E2 | core | AC-2, AC-11 | Iron-Law pass promotes the draft to a canonical D-ID | Drive `/CJ_goal_investigate` on a zero-match fragment for a real, root-causable scratch defect through to Iron-Law pass | Terminal prints the C7 promotion message naming the new `D000NNN` and `uncategorized/` path; `.inbox/<slug>/` is gone; canonical TRACKER/RCA/test-plan exist; telemetry line has `auto_scaffolded: true` | PASS if the canonical dir + 3 artifacts exist, the inbox draft is removed, exactly one D-ID was consumed, and telemetry shows `auto_scaffolded: true` |
| E3 | resilience | AC-3 | Iron-Law fail leaves the draft recoverable, no D-ID burned | Force `/investigate` to finish without a populated root cause on a zero-match draft; observe the halt; re-invoke the same fragment | Step 7 Halt 3 fires; C7 3-line block printed (`Why it stopped` / `State preserved: draft retained …, no D-ID consumed` / `Next: /CJ_goal_investigate "<fragment>"`); re-invocation resumes the same draft | PASS if no D-ID was allocated, the draft survives in `.inbox/`, the resume_cmd is copy-pasteable and fragment-based, and re-invoke resumes (not duplicates) |
| E4 | usability | AC-9, AC-13 | Operator can follow the whole flow from terminal output + docs only | Read `SKILL.md` (version + "Not in scope" → v1.1 + 13th end-state row), then run the zero-match flow and a `--dry-run` without reading `pipeline.md` | SKILL.md frontmatter shows `version: 1.1.0`, the ad-hoc-bug line is a v1.1 feature, the halt-taxonomy table has the 13th `halted_at_promote_lock_timeout` row; every non-happy transition is legible from terminal copy alone; `--dry-run` prints its pinned no-side-effects message | PASS if a reader who has never seen `pipeline.md` can explain what each printed message means and what to run next, and the SKILL.md doc deltas are all present |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Re-worded re-invocation pre-promotion creating a second `.inbox/` draft | Accepted v1.1 limitation (Open Q #4 fuzzy match is v1.2); behavior is correct-by-design, not a regression to guard | A user who re-words the fragment gets a second draft; bounded to non-canonical `.inbox/`, never pollutes canonical resolution; recovery is `rm -rf .inbox/<dup>` |
| Resumed-draft dirty-tree rerun after a prior partial `/investigate` write (C5) | Accepted v1.1 limitation (Open Q #6 is v1.2); the existing canonical R/F/P/M ladder has the same pre-RCA blind spot and `/investigate` self-checks `git status` | A rerun may start on a dirty tree; C5's stored-fragment echo lets the operator spot a wrong-bug slug collision before damage |
| True concurrent-process D-ID race (two real parallel invocations) | The mkdir-lock is unit-tested via a stale-lock-dir simulation (S8), not a live two-process fork — concurrency harness is heavier than v1.1 warrants | A genuine race is mitigated by the POSIX-atomic mkdir-lock; residual risk is a lock-timeout halt (recoverable, C4-instrumented), not a duplicate D-ID |
| Domain inference correctness | Domain is hardcoded `uncategorized` in v1.1 (Open Q #2 is v1.2); nothing to test beyond the literal default | A promoted defect always lands in `uncategorized/`; documented manual `mv` in the auto-scaffolded journal line is the v1.1 recourse |
