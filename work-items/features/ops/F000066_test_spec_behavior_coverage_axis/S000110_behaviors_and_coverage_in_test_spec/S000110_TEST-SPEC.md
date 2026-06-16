---
type: test-spec
parent: S000110
feature: F000066
title: "Behaviors + coverage in the test-spec contract — Test Specification"
version: 1
status: Draft
date: 2026-06-16
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier (advisory, not a violation). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-7 | Seed byte-identity | `spec/test-spec.md` is byte-identical to `test-spec.sh --seed` after the prose+enum edit; `schema_version` still 1 | `diff <(scripts/test-spec.sh --seed) spec/test-spec.md` |
| S2 | core | AC-2 | level-enum + id-uniqueness gate | An out-of-enum `level` or a duplicate `behaviors[].id` halts with `[test-spec-no-config]` | `scripts/test-spec.sh --validate` (against a fixture overlay with a bad level / dup id) |
| S3 | core | AC-3 | Coverage-link resolution | A dangling/dup `behavior` ref and a `validate\|ci\|hook`-family `unit` ref each surface as a finding | `scripts/test-spec.sh --check-coverage` (bad-link fixture) |
| S4 | core | AC-4 | Live-anchor + ≥1-cover | A non-live `anchor` (grep -F miss) and an uncovered behavior each surface as a finding; a good fixture passes | `scripts/test-spec.sh --check-coverage` (anchor + uncovered fixtures) |
| S5 | resilience | AC-6 | Consumer parity | Absent registry ⇒ `REGISTRY=absent` + exit 0; `units:` but no `behaviors:` ⇒ "behavior coverage inactive" + exit 0 | `scripts/test-spec.sh --check-coverage` (REPO_ROOT-overridden temp dirs) |
| S6 | integration | AC-8 | Hard-gate + suite + fixture wiring | `validate.sh` Check 24 runs the behavior checks in its hard loop; `tests/test-spec.test.sh` exercises them; the `test.sh` integration fixture is updated in lockstep | `scripts/validate.sh && scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-10 | Dogfood green end-to-end | Add the ~8 test-spec behavior + coverage rows; run `scripts/validate.sh` then `scripts/test.sh` | Both green; every dogfood behavior resolves to a real, anchored, test-bearing cover | PASS iff validate.sh + test.sh exit 0 and `--check-coverage` reports no behavior findings |
| E2 | core | AC-9 | Agent-judged substance flags a bad row | Author a deliberately vague / over-claimed / mis-leveled behavior row linked to a broad suite; run `/CJ_test_audit` | Stage-2 emits a `stage2/behavior:<id>` finding with cited evidence; a faithful row produces none | PASS iff the bad row is flagged AND a faithful row is not |
| E3 | usability | AC-5 | List + lint the new blocks | Run `scripts/test-spec.sh --list-behaviors` and `--list-behavior-coverage`; run `--validate` against a row with a work-item ID in `statement` | Lists print in registry order; `--validate` flags the work-item-ID-bearing field | PASS iff both lists render and the ID lint fires |
| E4 | core | AC-1 | Parser isolation under a full merged registry | With behaviors/behavior_coverage present, run `--list-rules` / `--list-units` / `--list-behaviors` | rules/units/layers/gates parse unchanged; the new keys do not bleed into them | PASS iff every existing list is identical to its pre-change output |

<!-- Post-ship rows: none — all verification is runnable pre-merge on the live tree. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Per-`area` pyramid-distribution reporting | `area` is PARSED-AND-IGNORED in v1 (Approach B) | A mis-bucketed `area` has no v1 consequence — no check reads it. |
| Diff-aware "behavior-adding change with no behavior row" detection | Deferred to Approach B | A new behavior shipped without a row is not auto-flagged in v1; relies on author discipline + the audit. |
| Cross-repo consumer adoption (a real portfolio repo declaring a short-put behavior) | v1 dogfoods the workbench's own test-spec only | A consumer-specific parsing edge could surface only on first external adoption; the consumer-parity smoke (S5) is the closest proxy. |
| Whether the linked test genuinely proves (vs mentions) the behavior in EVERY case | Inherently agent-judged; the deterministic check only proves the anchor greps live | A `grep -F`-passing-but-semantically-empty anchor relies on the agent-judged Stage-2 (E2) to catch — a coarse Stage-2 pass could miss a subtle over-claim. |
