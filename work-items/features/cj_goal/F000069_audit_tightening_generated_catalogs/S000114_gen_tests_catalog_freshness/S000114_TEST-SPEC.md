---
type: test-spec
parent: S000114
feature: F000069
title: "Generated docs/tests/ catalog + freshness primitive — Test Specification"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE story S000114. Smoke + E2E together cover every SPEC P0 AC.
     AC column maps each row to a SPEC story # (acceptance-criteria block). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `--render-docs` writes the catalog | One `docs/tests/<family>.md` per family + `docs/test-catalog.md` index are produced from the merged registry | `scripts/test-spec.sh --render-docs && ls docs/tests/ docs/test-catalog.md` |
| S2 | resilience | AC-2 | Deterministic + ID-free output | Two consecutive renders are byte-identical AND no rendered file contains `[FSTD][0-9]{6}` | `tests/test-spec-render.test.sh` (stability + ID-free asserts) |
| S3 | observability | AC-3 | `--render-docs --check` round-trip | `--check` exits 0 on a fresh render; exits non-zero (naming the file) on a hand-edited/missing catalog | `scripts/test-spec.sh --render-docs --check; echo $?` + `tests/test-spec-render.test.sh` |
| S4 | integration | AC-4 | Check 26 freshness gate + test.sh fixture | `validate.sh` Check 26 ERRORs on a stale catalog; `scripts/test.sh` contains the parallel Check-26 integration fixture | `scripts/validate.sh` (Check 26 line) + `grep -n 'Check 26' scripts/test.sh` |
| S5 | integration | AC-5, AC-6 | Registry declarations + coverage resolve | Generated docs declared as human-docs (no orphan, no IDs); new units rows resolve in the reverse-sweep | `scripts/doc-spec.sh --check-on-disk && scripts/test-spec.sh --validate --check-coverage` |

<!-- Soft cap: 5 rows — met. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2 | Fresh maintainer generates + reads the catalog | From repo root, run `scripts/test-spec.sh --render-docs`, then open `docs/test-catalog.md` and a `docs/tests/<family>.md` | The index lists every family with counts and links; each family page shows label/purpose/layer/disposition/trigger + an anchor code reference; re-running render produces no git diff | PASS if the catalog is complete, legible, ID-free, and a second render is a no-op diff |
| E2 | observability | AC-3, AC-4 | Operator proves the freshness gate catches drift | Hand-edit a line in `docs/test-catalog.md`; run `scripts/test-spec.sh --render-docs --check` then `scripts/validate.sh`; then regenerate and re-run both | `--check` and Check 26 both fail and name the stale file before regenerate; both pass after regenerate | PASS if the gate fails-on-stale and passes-on-fresh, naming the file |
| E3 | integration | AC-6 | Audit owns freshness standalone | Run `/CJ_test_audit` (Stage 1 + Stage 3) against the repo with a fresh catalog, then with a hand-edited one | Stage 1 reports a freshness finding on the stale catalog (clean when fresh); Stage 3 does NOT flag `docs/tests/` as an orphan/uncontemplated surface | PASS if Stage 1 catches staleness and Stage 3 treats `docs/tests/` as generated |
| E4 | core | AC-7 | Suite proves the renderer | Run the full suite: `scripts/test.sh` (includes `tests/test-spec-render.test.sh` + the Check-26 fixture) | The suite is green; `tests/test-spec-render.test.sh` exercises stability, ID-freeness, and `--check` pass/fail | PASS if `scripts/test.sh` is green incl. the new test + Check-26 fixture |

<!-- Soft cap: 5 rows — met. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| `doc-spec.sh` `tests-subfolder` presence check (SPEC P2 #9) | Deferrable to a follow-up if it widens scope — not core to the freshness primitive | A consumer repo could carry an empty `docs/tests/` without a presence-check complaint until the follow-up lands |
| Cross-machine consumer-repo enforcement | Belongs to deferred Story 4 (consumer Stage-1 gate), not this story | Portable enforcement via the gate hook is unproven until Story 4 |
| Byte-fidelity of generated content vs a human's preferred prose | The catalog is machine-rendered by design; prose is registry-sourced, not hand-tuned | A human may find a rendered phrasing terse; acceptable since the registry is the single source of truth |
