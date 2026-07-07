---
type: test-spec
parent: S000137
feature: F000088
title: "Render docs/testing.md from the merged test-spec registry — Test Specification"
version: 1
status: Draft
date: 2026-07-06
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0
     acceptance criterion. AC column maps each row to a SPEC # story number. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. AC maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `docs/testing.md` renders with all nine sections + the GENERATED-FILE/Check-26 header | `--render-docs` writes the front-door page with the required section headings | `bash scripts/test-spec.sh --render-docs && grep -q 'GENERATED FILE' docs/testing.md` |
| S2 | integration | AC-2 | `--render-docs --check` catches a hand-edit | A modified `docs/testing.md` makes the freshness diff exit non-zero (the Check 26 engine) | `bash scripts/test-spec.sh --render-docs --check` |
| S3 | core | AC-3 | Behaviors + categories indexes match the live registry | Rendered index row counts equal `--list-behaviors` / `--list-categories` output (17 + 28 today) | `bash tests/test-spec.test.sh` |
| S4 | integration | AC-4 | `docs/testing.md` declared, no orphan, no work-item IDs | `doc-spec.sh --validate` + `--check-on-disk` green; no `[FSTD]NNNNNN` in the page | `bash scripts/doc-spec.sh --validate && bash scripts/doc-spec.sh --check-on-disk` |
| S5 | resilience | AC-5 | Render is idempotent + `spec/test-spec.md` seed byte-identical | Re-render is byte-identical; seed matches `--seed` (seed-identity test) | `bash tests/test-spec.test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. Each row is one user-visible scenario. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-1 | A maintainer opens the front door | Run `bash scripts/test-spec.sh --render-docs`, then open `docs/testing.md` | The page reads as one coherent place to understand + run + audit + verify the tests, with links to `docs/philosophy.md` §Verification + `spec/test-spec.md` + the catalog/topics | Nine sections present, prose is coherent, links resolve |
| E2 | integration | AC-2 | Full gate green on the generated page | Run `bash scripts/validate.sh` (or at least Check 26) after regenerating | Check 26 passes on `docs/testing.md`; a deliberate hand-edit then makes it fail | Green when fresh; red on a hand-edit |
| E3 | core | AC-3 | Indexes track a registry change | Add/remove a `categories:` row in `spec/test-spec-custom.md`, re-render | The `docs/testing.md` category index reflects the change without a hand-edit | Rendered index matches the new registry state |

<!-- If an E2E test skill exists for this feature, reference it here. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Prose quality / readability of the generated narrative | Subjective; not a deterministic check — covered by the E1 manual read | A future prose edit could read awkwardly without failing a gate |
| Repo-portability of the front door on a consumer repo | Out of scope (Phase 3 of the saga) | The generator may need adjustment before Phase 3 adoption |
| Exact rendered ordering of index rows across shells | Idempotency (S5) covers stability; canonical ordering is an engine detail | A locale/sort difference could reorder rows if the engine ever stops normalizing |
