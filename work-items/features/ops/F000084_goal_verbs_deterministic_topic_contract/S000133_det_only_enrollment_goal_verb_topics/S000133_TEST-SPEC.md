---
type: test-spec
parent: S000133
feature: F000084
title: "Deterministic-only enrollment seam + per-verb goal topics — Test Specification"
version: 1
status: Draft
date: 2026-07-06
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. AC column maps each row to a SPEC story number.
     Soft cap: 5 rows per tier — exceeded here by justification: this story
     lands a contract-engine seam + 4 test scripts + 2 doc surfaces + an
     enrollment, each with its own deterministic proof command; collapsing
     them would hide which check proves which AC. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Registry validates with the new key | `topic_contracts_deterministic:` parses; invalid slug / cross-list duplicate fixtures fail with a named error | `bash scripts/test-spec.sh --validate` |
| S2 | core | AC-2, AC-10 | Topic contract green under both arms | det arm: three points each for `goal-feature`/`goal-task`/`goal-defect`; both-modes arm: `portability` unchanged (four points) | `bash scripts/test-spec.sh --check-topic-contract` |
| S3 | resilience | AC-3, AC-5 | Union activation + planted faults | either-list-non-empty = active; `enrolled=` counts the union; 3-arm drill: nightly-row removal → finding; agentic-eval removal → det topics green; hidden dream doc (`TESTDOC_OUT`) → topic-docs finding | targeted drill block in `bash scripts/test.sh` (engine-only invocations) |
| S4 | integration | AC-4 | Seed identity | `spec/test-spec.md` byte-identical to `test-spec.sh --seed` after the topic-axis prose edit | seed-identity test in `bash scripts/test.sh` |
| S5 | core | AC-6 | The 4 new scripts pass; chains gated | defect smoke + 3 chain drills pass standalone; `TEST_FAST=1` skips the 3 chains, full run executes them | `bash tests/cj-goal-defect-smoke.test.sh && bash tests/goal-feature-chain.test.sh && bash tests/goal-task-chain.test.sh && bash tests/goal-defect-chain.test.sh` |
| S6 | integration | AC-7 | Structure + unit anchors | folders per declared (category,layer) pair; 9 front-door docs + INDEX + three sections; Check 24 forward/reverse anchors for the new `units:` rows; no `cj-goal-eval` in the registry | `bash scripts/test-spec.sh --check-structure && bash scripts/validate.sh` |
| S7 | usability | AC-8 | Topic docs surfaces | dream doc + topic subdir (index + CI-push/CI-nightly/local-hook pages) per det-enrolled topic; all declared, no work-item IDs in human-docs | `bash scripts/test-spec.sh --check-topic-docs && bash scripts/doc-spec.sh --check-on-disk` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (E2E rows only). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-10 | Full gate green on the landing tree | Run `bash scripts/validate.sh` from the worktree root after enrollment (the LAST edit) | All checks green incl. 24/26/27/30/31; Check 30 banner names the two-list model | Any red or stale-banner text = fail |
| E2 | core | AC-6 | Nightly-vs-push cadence split | Run `TEST_FAST=1 bash scripts/test.sh`, then `bash scripts/test.sh` (full) | Fast run prints SKIP for the 3 chain drills; full run executes them and they pass, driving each verb's helper chain in a temp clone | Chain drills running in the fast path, or failing in the full path = fail |
| E3 | resilience | AC-2, AC-5 | Agentic-removal robustness (the operator's future path) | In a scratch registry copy, delete the `goal-feature-eval` row; run `bash scripts/test-spec.sh --check-topic-contract` against the copy (env overrides) | The three det-enrolled topics still report green; only agentic-dependent surfaces (not Check 30) reference the deleted row | Any det-topic finding after the deletion = fail |
| E4 | usability | AC-8, AC-9 | Maintainer legibility walk | Open `docs/goals/goal-defect.md`, follow its reference from `docs/tests/topics/goal-defect/index.md`, open `CI-nightly.md`, copy the drill command and run it | Dream doc states the end goal + deterministic-only posture; layer page names the drill + how to run; command passes as documented | A missing/wrong how-to-run or a page not referencing the dream doc = fail |
| E5 | integration | AC-7, AC-10 | Registry truthfulness sweep | `grep -rn "cj-goal-eval" spec/` (expect nothing); read the `topic_contracts:` header comment + Check 30/31 units purposes + TEST_FAST prose | Retired label absent; every self-describing surface states the two-list model and names the chain drills under TEST_FAST | Any stale "portability only" / "skips only test-deploy" claim = fail |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The agent-driven path of each verb (the `pipeline.md` prose the AGENT executes) | Deterministic drills can only reach the helper SCRIPTS; with deterministic-only enrollment NO required test covers the agent path (operator choice — the F000082 green-but-inert blind spot re-opens for these topics) | A prose-level pipeline regression ships silently until an operator run or an on-demand eval catches it; evals stay runnable while they live |
| Agentic eval execution (`goal-feature-eval` / `goal-task-eval`) | Re-topic'd but required by nothing; this Windows box has no `claude` CLI, and `mode: agentic ⇒ tier ≠ free` keeps them out of CI | Eval rot is invisible to the contract; acceptable because the rows are scheduled for removal |
| Defect verb agentic coverage | Its on-disk eval case stays UNDECLARED on the category axis (no new agentic row — operator directive) | Defect's agent path has no declared proof at all; deterministic smoke + chain + land-sync are the accepted proxy |
| The `/ship` + `/land-and-deploy` gstack tails inside the chain drills | Upstream gstack skills; drills stop at deterministic seams (`pr-check`, recap, `post-land-sync.sh --dry-run` via `POST_LAND_SYNC_MANIFEST` fixture) | An upstream gstack regression is caught by gstack, not this repo's drills |
| Later harness removal breaking feature/task local-det fills (`cj-e2e-gate.test.sh`, `e2e-local.test.sh`) | Future state; out of scope | Documented fallback: re-declare the verb's chain drill at `local-hook` (two rows, one command — the `test-deploy`/`portability-deploy` precedent) |
