---
type: test-spec
parent: S000111
feature: F000067
title: "docs/workflows/ subfolder — full split + contract/engine/validator/test/prose changes — Test Specification"
version: 1
status: Draft
date: 2026-06-27
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0
     acceptance criterion. AC column maps each row to a SPEC story number. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | Seed 3-way byte-identity | `spec/doc-spec.md` == `templates/doc-spec-common.md` == `doc-spec.sh --seed` after the reword + mandate prose | `bash tests/cj-document-release-config.test.sh` |
| S2 | core | AC-3 | Engine mandate + recursion | `doc-spec.sh --check-on-disk` reports `workflows-subfolder` PASS and requires every `docs/workflows/*.md` declared (recursed orphan scan) | `scripts/doc-spec.sh --check-on-disk` |
| S3 | resilience | AC-4 | Registry-gated skip | a `REGISTRY=absent` temp-dir repo reports `REGISTRY=absent` + exit 0 (mandate does not fire) | `bash tests/doc-spec-overlay.test.sh` (registry-absent drill) |
| S4 | core | AC-5 | Validator green (15a/15b/15c/16/17/19 + 24) | recursed orphan scan, retargeted Check 15b, new Check 15c, human-doc no-ID lint, merged registry validate, coverage cross-check all pass | `scripts/validate.sh` |
| S5 | observability | AC-6 | Full suite green | the whole test suite incl. the zzz-test-scaffold integration fixture and the new engine-check coverage passes | `scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-1 | Content preserved in the split | Open the six `docs/workflows/*.md`; diff each against the corresponding moved section in the pre-split `docs/workflow.md` (via `git show HEAD:docs/workflow.md`) | Each moved section appears verbatim in its new file; nothing lost | PASS if all six sections match verbatim; FAIL if any prose is dropped or altered |
| E2 | usability | AC-1 | `workflow.md` is a pure index that names every workflow | Read `docs/workflow.md`; confirm it is ~80–120 lines and links each `docs/workflows/*.md` (incl. all four `CJ_goal_*` orchestrators) | The overview links every workflow; no deep detail remains inline | PASS if the index links all six files and stays ~80–120 lines; FAIL if a workflow is unlinked or deep detail lingers |
| E3 | core | AC-5 | No-vanish guarantee (Check 15c) | Temporarily remove one orchestrator's link from `docs/workflow.md`; run `scripts/validate.sh`; restore | Check 15c errors on the missing link; restoring makes it green | PASS if Check 15c flags the dropped link; FAIL if validate stays green with a workflow unlinked |
| E4 | core | AC-3 | Orphan enforcement on the subfolder | Add an undeclared `docs/workflows/zzz_tmp.md`; run `scripts/doc-spec.sh --check-on-disk`; remove it | The recursed orphan scan emits `FINDING: stage1/orphans` for the undeclared file | PASS if the undeclared subfolder file is flagged; FAIL if it is silently accepted |
| E5 | observability | AC-6 | Post-sync audits clean | After doc-sync, run `/CJ_doc_audit` + `/CJ_test_audit` | No stale single-file refs; every new `docs/workflows/*.md` declared; every new unit declared | PASS if both audits report no findings on the new surfaces; FAIL on any stale-ref or undeclared-unit finding |

<!-- If an E2E test skill exists for this feature, reference it here. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Downstream adopting-repo impact (a real consumer repo lacking `docs/workflows/` now gets a finding) | This is the user's explicit uniform-mandate choice; the workbench itself goes green by creating the 6 files | A consumer repo that adopted the contract will get a new `stage1/workflows-subfolder` finding until it creates the subfolder — accepted as intended behavior |
| Exact line-count band of the index (~80–120) is a soft target | Line count is a guideline, not a hard gate; the no-vanish Check 15c + the content-preservation E2E are the real guards | The index could land slightly outside the band without harm; reviewer judgment at the PR |
| Prose-sync correctness in `CLAUDE.md`/architecture/philosophy (P1) | Agent-judged at the post-sync doc audit rather than a deterministic test | A stale single-file phrasing could survive if the audit misses it; mitigated by the full-migration secondary-ref sweep |
