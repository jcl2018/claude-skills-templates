---
type: test-spec
parent: S000010_bundle_artifact_completeness
feature: F000004_work_copilot
title: "Bundle Artifact Completeness — Test Specification"
version: 2
status: Draft
date: 2026-04-26
updated: 2026-05-05
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Migrated from Test Matrix + Test Tiers shape to Smoke + E2E on 2026-05-05.
     Original 19 Test Matrix rows + 5 smoke + 4 E2E consolidated. The 24
     byte-identity comparisons (1 WORKFLOW + 7 reference + 3 philosophy +
     14 examples + 3 flat fixtures + 2 nested fixtures) collapse into one
     smoke row enforced by validate.sh's MIRROR_SPECS array. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-5, AC-6 | Mirror byte-identity across all upstream artifacts | `MIRROR_SPECS` enforces byte-identity for top-level WORKFLOW.md + 4 dirs (reference/, philosophy/, examples/, fixtures/); covers 24+ files; closed fixture gap (DESIGN.md missing, TRACKER.md drifted, 3 flat-file gaps) | `scripts/validate.sh` (Error check 10) |
| S2 | usability | AC-7 | 8 KB budget on `copilot-instructions.md` | File stays within Copilot's ambient-context budget after v2 pointer additions | `[ "$(wc -c < work-copilot/instructions/copilot-instructions.md)" -le 8192 ]` |
| S3 | usability | AC-7, AC-11 | Bundle-layout pointers reference all 5 dirs under one grouping header | `copilot-instructions.md` literally references each new bundle dir path; all 5 paths grouped under one "## Bundle layout" header | `grep -F` per path string (5 grep calls); manual review of grouping at ship time |
| S4 | core | AC-8, AC-9 | Installer round-trip + idempotence + DRIFT detection | New artifacts land under target's `.github/work-copilot/`; re-install reports `installed=0 skipped=N`; doctor catches mutation | Extension to existing `scripts/test.sh` round-trip block (5 spot-checks + 1 DRIFT) |
| S5 | observability | AC-10 | Budget enforcement gate documented in S000010_ARCHITECTURE.md | Existing 8192-byte gate in scripts/test.sh or scripts/validate.sh is cited, OR a new gate is added with location described | `grep -E '8192\|wc -c' scripts/test.sh scripts/validate.sh && grep -F '8192' work-items/features/work-copilot/F000004_work_copilot/S000010_*/S000010_ARCHITECTURE.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Copilot cites WORKFLOW.md for procedural questions | (a) Install bundle into target via `copilot-deploy.py install`. (b) Open VS Code with Copilot. (c) Ask "what are the workflow phases?" in Copilot Chat | Copilot's response includes a citation to `.github/work-copilot/WORKFLOW.md`; cited content matches upstream phase definitions | Pass = explicit path citation + content match |
| E2 | core | AC-2 | Copilot cites reference/ for "how do I write a TEST-SPEC?" | Same setup as E1; ask the question | Citation to `.github/work-copilot/reference/guide-test-spec.md` | Same rubric as E1 |
| E3 | core | AC-3 | Copilot cites philosophy/ for rationale questions | Same setup; ask "why is the PRD structured this way?" | Citation to `.github/work-copilot/philosophy/rationale-PRD.md` | Same rubric as E1 |
| E4 | core | AC-4 | Copilot cites examples/ for concrete templates | Same setup; ask "show me an example architecture doc" | Citation to `.github/work-copilot/examples/example-doc-ARCHITECTURE.md` | Same rubric as E1 |

E2E tests run on the Windows work box as part of S000009's checklist.
Results recorded in S000009_TRACKER.md or a dedicated v2 E2E log.

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Copilot citation rate across many phrasings of the same question | Manual E2E uses one canonical phrasing per topic; broader phrasing requires an automated harness | Mitigation: monitor real usage and add phrasings to the E2E checklist as they come up |
| Cross-platform install on Linux | Already covered by S000008 / scripts/test.sh round-trip; not re-tested in S000010 | Low — S000008's coverage is sufficient |
| Behavior when target repo has pre-existing files at collision paths | Not exercised; covered by F000004 v1 risks-row 4 policy in installer | Low — installer policy refuses to clobber non-bundle files without `--overwrite` |
| Long-tail Copilot reluctance to follow path references | Mitigation requires platform-level Copilot behavior change; we test what we can observe (E1–E4) | Med — fall back to inlining critical pointers within 8 KB budget if observed |
