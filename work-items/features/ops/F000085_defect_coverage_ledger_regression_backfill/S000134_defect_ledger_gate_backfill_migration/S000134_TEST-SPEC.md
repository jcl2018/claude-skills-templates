---
type: test-spec
parent: S000134
feature: F000085
title: "Defect-coverage ledger + regression migration — Test Specification"
version: 1
status: Draft
date: 2026-07-06
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `defect_coverage:` axis parses + lists | `--validate` exits 0 with the new LAST block; `--list-defect-coverage` echoes all rows in the three disposition forms; no sibling axis's parsing regresses | `bash scripts/test-spec.sh --validate && bash scripts/test-spec.sh --list-defect-coverage` |
| S2 | core | AC-5 | 38/38 backfill fully dispositioned, proofs live | Forward: every defect dir has exactly one row; reverse: every anchor greps live, every `covered-by` resolves deterministic, every waiver has a reason; summary prints `dirs=38 rows=38 findings=0` | `bash scripts/test-spec.sh --check-defect-coverage` |
| S3 | resilience | AC-4 | Negative test proves the gate fires (two plants) | Plant an unmapped defect dir → forward FINDING; plant a `covered-by` citing a `mode: agentic` row → mode FINDING; each restore → exit 0 (hermetic temp-dir overrides, engine-only) | the negative test in `scripts/test.sh` (plant → `! bash scripts/test-spec.sh --check-defect-coverage` → restore → pass) |
| S4 | integration | AC-3 | Check 32 wired HARD into `validate.sh`, banner owned | `validate.sh` green on this repo including Check 32; Check 24 reverse sweep resolves the new banner to the `validate-check-32` units row; zero model spend | `bash scripts/validate.sh` |
| S5 | core | AC-6 | Reverse-sweep token grammar + orphan resolution | Check 24 green with full relative-path tokens + recursed glob; `tests/workflow/local-hook/doc-sync.test.sh` invoked by `scripts/test.sh` and owned by exactly one units row; no existing forward anchor breaks | `bash scripts/test-spec.sh --check-coverage` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-8 | Run the regression category by name, model-free | 1. `bash scripts/test-spec.sh --list-categories --category regression` and count rows + check mode/tier columns. 2. Run `/CJ_test_run --category regression`. 3. Open one `docs/tests/regression/CI-push/<name>.md` and read the three sections. | ≥4 rows, ALL `mode: deterministic` + `tier: free`; the run is green with zero model spend and writes a `mode: category` ledger; the doc carries `## What it is` / `## How to run` / `## Explanation` in words with no D-IDs | Pass iff row count ≥4, all deterministic+free, run aggregate `pass`, doc sections present + ID-free |
| E2 | core | AC-7 | Migrated drills still run under the full suite (CI-gate parity) | 1. Run full `bash scripts/test.sh` locally. 2. Run shellcheck as CI does. 3. Confirm the 4 moved drills execute from `tests/regression/CI-push/` (their PASS lines appear). | Full suite green including the 4 moved drills at their new paths; shellcheck clean; Check 24 + Check 32 green at HEAD | Pass iff test.sh exits 0 with all 4 moved-drill PASS lines present and shellcheck reports no findings |
| E3 | resilience | AC-2 | Consumer-repo vacuous skip (standalone safety) | 1. `git init` a bare temp repo (no registry, no `work-items/defects/`). 2. Run `bash scripts/test-spec.sh --check-defect-coverage` from it (engine resolved from the workbench). 3. Repeat in a repo with a registry but no `defect_coverage:` axis. | Each run prints the named `defect coverage inactive — <reason>` line and exits 0 — never a finding, never a halt | Pass iff both runs exit 0 with the named inactive reason and zero FINDINGs |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Waived-gap defects have no drill (only a `waived: "gap — …"` row + TODOS entry) | Gap-drill authoring is deliberately deferred to filed TODOS follow-ups (≤30-line/cap-3 exception aside) — keeps the PR bounded | A waived defect could regress undetected until its follow-up drill ships; the ledger at least makes the gap enumerable |
| Cross-machine proof (`/CJ_test_run --category regression` on the Mac) | Post-land assignment — requires the other machine after merge | A platform-specific breakage in a migrated drill surfaces only at the post-land run |
| The agentic-purge/Check-30 collision path (portability un-enrollment) | Out of scope; tracked as a TODOS row that must precede any purge | Purging agentic tests before un-enrolling `portability` would hard-fail Check 30 — accepted because the TODOS row gates the sequence |
| The 11 inline `scripts/test.sh` D-blocks stay collectively owned (no per-defect runnability) | Approach C rejected — extraction destabilizes a proven battery | A single battery failure implicates a block, not a named defect row; `covered-by-anchor` still pins each defect to its block |
