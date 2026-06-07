---
type: test-spec
parent: S000092
feature: F000052
title: "Front-table format convention — Test Specification"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Smoke = automated regression (CI). E2E = manual user-scenario verification. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | `--list-front-table-docs` prints exactly the two flagged docs | The new subcommand reads the registry and emits `docs/philosophy.md` + `docs/workflow.md`, nothing else | `bash scripts/doc-spec.sh --list-front-table-docs` |
| S2 | core | AC-1 | Registry schema still validates | The new `front_table` field + extended requirement strings don't break the schema; COMMON block intact | `bash scripts/doc-spec.sh --validate` (expect `OK schema_version=1`) |
| S3 | core | AC-3, AC-4 | `validate.sh` is green on the repo | Both real docs have leading front tables; Check 20 passes alongside Check 15/15a/15b + 19 | `bash scripts/validate.sh` |
| S4 | resilience | AC-3, AC-5 | Check 20 fails when a leading table is removed (plant-and-restore) | Strip a flagged doc's leading table, assert non-zero exit + `  ERROR:` Check-20 prefix, then restore — the negative test in scripts/test.sh | `bash scripts/test.sh` (plant-and-restore Check-20 block) |
| S5 | resilience | AC-5 | `--list-front-table-docs` filters on the flag (unit) | Synthetic temp registry: entry WITH `front_table: required` is emitted; entry WITHOUT it is not | `bash tests/cj-document-release-config.test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-4 | Reader opens each doc and sees a leading index | Open `docs/philosophy.md` and `docs/workflow.md`; read from the top | A summary table appears before the first `## ` heading in each (philosophy: every principle; workflow: every workflow/entry point); no work-item IDs in any cell | PASS if both docs open with a leading table and no `[FSTD]NNNNNN` appears; FAIL otherwise |
| E2 | core | AC-6 | Maintainer confirms no stale enumerations | Read CLAUDE.md `## Doc contract` check list + Scripts-reference `doc-spec.sh` row; architecture.md doc-spec section; CJ_document-release SKILL.md subcommand list | Check 20 + `--list-front-table-docs` appear in every enumeration; USAGE.md `last-updated` is bumped (no Check-14 drift flag) | PASS if all four doc-touches reflect the new subcommand/check and `validate.sh` Check 14 does not flag USAGE.md; FAIL otherwise |
| E3 | resilience | AC-3 | Registry-driven scoping holds for an unflagged doc | Confirm `docs/architecture.md` (a human-doc) is NOT in `--list-front-table-docs` output and is exempt from Check 20 | architecture.md is absent from the subcommand output and validate.sh does not require a leading table for it | PASS if architecture.md is exempt (demonstrates the registry-driven scoping); FAIL if Check 20 flags it |

<!-- No dedicated E2E test skill for this feature; the checks above are run by hand
     against the repo before /ship. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Exact column headers of each front table | The gate asserts a leading table, not specific columns (Open Question) | A table with unexpected-but-valid columns still passes — acceptable; columns are a human-readability choice |
| Portable propagation of `front_table` to adopting repos via the seed | Out of scope — deliberately kept workbench-local (Approach B rejected) | Adopting repos won't inherit the convention until/unless it is later seeded — acceptable for this workbench-local change |
| Windows Git Bash behavior of the new awk paths | Covered transitively by the existing `windows-latest` CI job running `validate.sh`; no separate row added | A GNU-vs-BSD awk divergence would surface in the windows-latest job rather than a dedicated local test — acceptable given POSIX-awk-only constraint |
