---
type: test-spec
parent: S000084
feature: F000048
title: "Scaffold-time atomic ID claim — Test Specification"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. The seven design-doc test cases map onto these rows.

     Soft cap: 5 rows per tier. The smoke tier exceeds the cap deliberately —
     each row is one isolatable behavior of the claim engine (race, both reap
     modes, idempotent reuse, prefix isolation, worktree resolution) and is the
     unit-test surface that makes Approach A worth choosing over the inline
     Approach C. The cap is advisory ([INFO]), not a violation. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Single claim above floor returns floor+1 | `cj-id-claim.sh --prefix F --floor 47` prints `CLAIMED_ID=F000048`, exit 0 | `bash tests/cj-id-claim.test.sh` |
| S2 | resilience | AC-2 | Concurrent race, looped 20+ rounds, distinct IDs | two parallel invocations at the same floor never return a duplicate ID | `bash tests/cj-id-claim.test.sh` |
| S3 | resilience | AC-3 | Reap on origin | a claim whose ID is on origin/main is removed and not counted | `bash tests/cj-id-claim.test.sh` |
| S4 | resilience | AC-4 | Reap on TTL | a claim dir older than `--ttl-hours` is removed and not counted | `bash tests/cj-id-claim.test.sh` |
| S5 | usability | AC-5 | Same-branch reuse | re-run with a live same-branch claim + no work-item dir reuses the same ID | `bash tests/cj-id-claim.test.sh` |
| S6 | resilience | AC-7 | Prefix isolation + worktree common-dir resolution | F vs S claims independent; claim visible from the root checkout of a linked worktree | `bash tests/cj-id-claim.test.sh` |
| S7 | integration | AC-1,AC-2 | Test file is registered + executed | `tests/cj-id-claim.test.sh` name appears in the test.sh suite output (not a silent no-op) | `bash scripts/test.sh 2>&1 \| grep -q cj-id-claim` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     You drive the feature as a real user would and observe the outcome.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | integration | AC-6 | Helper-absent fallback in a real scaffold | Temporarily make `scripts/cj-id-claim.sh` non-executable (`chmod -x`), then run `/CJ_scaffold-work-item <a design doc>` | Scaffold still mints a fresh ID via the 3-source `printf` fallback and completes; restore `chmod +x` after | PASS if scaffold completes with a valid sequential ID and no error; FAIL if scaffold breaks or mints a blank/colliding ID |
| E2 | resilience | AC-2 | Two real concurrent scaffolds don't collide | Open two worktrees of one clone; run `/CJ_scaffold-work-item` in each at the same baseline before either pushes | The two scaffolds receive distinct IDs; no post-merge renumber needed | PASS if the two work-item dirs carry different IDs; FAIL if both mint the same ID |

<!-- If an E2E test skill exists for this feature, reference it here. None for this story. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Cross-machine pre-push pre-emption (two clones, neither pushed) | Out of v1 scope — covered post-push by Sources 2+3, not pre-empted | A cross-machine pre-push pair can still collide and is recovered at merge as today (no regression) |
| `--dry-run` read-only preview (AC-8, P2) | Nice-to-have, not P0; behavior is a read-only subset of the claim path | Low — `--dry-run` only ever skips the `mkdir`; if it regressed, no IDs are mutated |
| Pathological claim-loop exhaustion (100 retries) | Requires ~100 simultaneous live claims at one floor — not realistically reachable | The loop exits 1 and Step 5.1's fallback mints an ID; worst case is a skipped number |
