---
type: test-spec
parent: S000109
feature: F000065
title: "Reconcile engines + audit-skill wiring — Test Specification"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0
     acceptance criterion. Smoke = automated regression (CI). E2E = manual
     user-scenario verification before /ship. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `--classify` labels four states | On absent / canonical / legacy / duplicate fixtures, `doc-spec.sh --classify` emits the right `GENERATION`/`DUPLICATE`/`CANONICAL_PATH`; legacy only when the old-generation signature matches | `bash tests/doc-spec-reconcile.test.sh` (classify cases: absent→`GENERATION=absent`, canonical→`canonical`, legacy YAML→`legacy`, two-position→`DUPLICATE=1`) |
| S2 | core | AC-2 | `--reconcile` preserves rows + atomic + `.bak` + idempotent | A 40+-row legacy YAML fixture migrates to canonical Markdown with all rows present; `--validate` exits 0; a `.bak` exists; a re-run prints `RECONCILE: already canonical` | `bash tests/doc-spec-reconcile.test.sh` (reconcile case: row-count in == row-count out; `scripts/doc-spec.sh --validate` on the migrated file; `[ -f <fixture>.bak ]`; second `--reconcile` is a no-op) |
| S3 | resilience | AC-3 | `audit_class` asymmetry guard fires | A legacy `docs/*` row declared `operational` yields a `RECONCILE-WARN: … audit_class was 'operational' but path derives 'human-doc'` line | `scripts/doc-spec.sh --reconcile <asymmetry-fixture> \| grep -q "RECONCILE-WARN.*audit_class was 'operational'"` |
| S4 | core | AC-4 | `test-spec.sh` symmetric classify/reconcile | `test-spec.sh --classify` labels absent/canonical/legacy/duplicate; `--reconcile` migrates the legacy form (or is a clean dedup/no-op) | `bash tests/test-spec-reconcile.test.sh` |
| S5 | usability,integration | AC-5, AC-6 | Read-mostly default, no canonical noise, suite green | A plain audit on a canonical repo emits ZERO `RECONCILE:` lines and writes nothing; `validate.sh` + `test.sh` pass; new tests registered in `scripts/test.sh` + `spec/test-spec-custom.md` | `scripts/doc-spec.sh --classify \| grep -q 'GENERATION=canonical' && ! (scripts/doc-spec.sh --check-on-disk \| grep -q '^RECONCILE:') && scripts/validate.sh && scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Each row is one user-visible scenario. AC column maps to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-5 | Legacy repo: directive on plain run, migrate under the flag | In a temp git repo seeded with a legacy YAML `doc-spec.md`, run `/CJ_doc_audit`, then `/CJ_doc_audit --reconcile`, then `/CJ_doc_audit` again | The plain run surfaces a `RECONCILE:` directive in the Stage-1 report and writes nothing; `--reconcile` migrates legacy→canonical preserving every row (`.bak` written); the final plain run is clean (`GENERATION=canonical`, no reconcile lines) | PASS if the plain run is read-only + advisory and `--reconcile` migrates with no row loss; FAIL on any plain-run write or dropped row |
| E2 | usability | AC-5 | Canonical workbench: zero reconcile noise | From the workbench root, run `/CJ_doc_audit` and `/CJ_test_audit` (no flag) | Both classify `canonical`, run their Stage-1 engine clean, and emit ZERO `RECONCILE:` / `RECONCILE-WARN:` lines | PASS if neither audit emits any reconcile line on the already-canonical workbench; FAIL on any reconcile noise |
| E3 | integration | AC-4 | test-spec self-heal symmetric to doc-spec | In a temp repo with a non-canonical `test-spec.md` (legacy form if one exists, else a duplicate), run `/CJ_test_audit` then `/CJ_test_audit --reconcile` | `--classify` labels it correctly; the plain run surfaces the advisory directive; `--reconcile` migrates/dedups symmetrically to the doc-spec path | PASS if test-spec reconcile mirrors doc-spec behavior; FAIL on a divergence not explained by the absence of a test-spec legacy on-disk format |

<!-- Post-ship rows: none — all rows are verifiable pre-merge from the branch. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Auto-delete of a duplicate contract file | Out of scope in v1 (OQ1) — `--reconcile` reports + reconciles the canonical copy but never deletes; `--prune-duplicates` is deferred | A redundant root copy persists until a future opt-in prune; reported every run so it is never silently forgotten |
| Root→spec relocation of a root-only contract | Out of scope in v1 (OQ2) — root is an accepted position; root-only is advisory `wrong-position`, not moved | A root-only file keeps working (root is accepted); relocation is opt-in future work |
| A `test-spec.sh --reconcile` migrate of a real legacy on-disk test-spec format | The exact legacy test-spec signature is TBD from git history (OQ3); if none ever diverged, `--reconcile` is a dedup/no-op with no legacy form to exercise | If a divergent legacy test-spec format is later found, a follow-up adds its fixture; the doc-spec path proves the migrate mechanism |
| Behavior on a genuinely-malformed (non-signature) no-table canonical file | By design that case stays the `[doc-sync-no-config]` halt (NOT `legacy`); S1 asserts legacy requires the signature, so the malformed file is never reconciled | A hand-broken canonical file halts loudly rather than getting clobbered — the intended safe behavior |
