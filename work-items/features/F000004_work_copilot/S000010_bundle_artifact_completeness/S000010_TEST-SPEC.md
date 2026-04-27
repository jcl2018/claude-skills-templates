---
type: test-spec
parent: S000010_bundle_artifact_completeness
feature: F000004_work_copilot
title: "Bundle Artifact Completeness — Test Specification"
version: 1
status: Draft
date: 2026-04-26
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Test Matrix must cover every PRD acceptance criterion
     across happy/edge/error paths. T000011 has its own test-plan covering
     the sync-check extension's negative paths in isolation. -->

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | WORKFLOW.md byte-identity | AC-5 | `skills/company-workflow/WORKFLOW.md` exists | `cmp -s skills/company-workflow/WORKFLOW.md work-copilot/WORKFLOW.md` | exit 0 (files identical) | P0 | Unit |
| 2 | core | reference/ byte-identity (7 files) | AC-5 | All 7 `guide-*.md` files exist upstream | For each guide: `cmp -s skills/company-workflow/reference/$g work-copilot/reference/$g` | exit 0 for all 7 | P0 | Unit |
| 3 | core | philosophy/ byte-identity (3 files) | AC-5 | All 3 `rationale-*.md` files exist upstream | For each rationale: `cmp -s skills/company-workflow/philosophy/$r work-copilot/philosophy/$r` | exit 0 for all 3 | P0 | Unit |
| 4 | core | examples/ byte-identity (14 files) | AC-5 | All 14 `example-*.md` files exist upstream | For each example: `cmp -s skills/company-workflow/examples/$e work-copilot/examples/$e` | exit 0 for all 14 | P0 | Unit |
| 5 | resilience | Closed fixture gap (3 flat) | AC-6 | Bundle has historical drift on flat fixtures | `cmp -s skills/company-workflow/fixtures/invalid-bad-frontmatter.md work-copilot/fixtures/invalid-bad-frontmatter.md` (and the other 2 flat files) | exit 0 for all 3 | P0 | Unit |
| 6 | resilience | Closed fixture gap (1 nested missing) | AC-6 | `valid-feature-dir/DESIGN.md` was missing from bundle | `cmp -s skills/company-workflow/fixtures/valid-feature-dir/DESIGN.md work-copilot/fixtures/valid-feature-dir/DESIGN.md` | exit 0 | P0 | Unit |
| 7 | resilience | Closed fixture drift (1 nested) | AC-6 | `valid-feature-dir/TRACKER.md` had drift | `cmp -s skills/company-workflow/fixtures/valid-feature-dir/TRACKER.md work-copilot/fixtures/valid-feature-dir/TRACKER.md` | exit 0 | P0 | Unit |
| 8 | usability | 8 KB budget compliance | AC-7 | `copilot-instructions.md` updated with v2 pointer section | `wc -c < work-copilot/instructions/copilot-instructions.md` | output ≤ 8192 | P0 | Smoke |
| 9 | usability | Bundle-layout pointer references all 5 dirs | AC-7 | `copilot-instructions.md` updated | For each path string: `grep -F "$path" work-copilot/instructions/copilot-instructions.md` | exit 0 for all 5 (`work-copilot/WORKFLOW.md`, `work-copilot/reference/`, `work-copilot/philosophy/`, `work-copilot/examples/`, `work-copilot/fixtures/`) | P0 | Smoke |
| 10 | core | Installer auto-pickup (5 spot-checks) | AC-8 | Fresh tmpdir target, no `.github/` | `python scripts/copilot-deploy.py install $TMPDIR` then assert each of 5 spot-checks present: `WORKFLOW.md`, `reference/guide-general.md`, `philosophy/rationale-PRD.md`, `examples/example-doc-ARCHITECTURE.md`, `fixtures/invalid-bad-frontmatter.md` | All 5 exist under `$TMPDIR/.github/work-copilot/` | P0 | Integration |
| 11 | core | Installer idempotence on re-install | AC-8 | After Test #10 | Re-run `install` on same target; capture install summary | Summary reports `installed=0 skipped=N` (N=existing artifact count); no checksum mismatches | P0 | Integration |
| 12 | resilience | Doctor reports DRIFT after mutation | AC-8, AC-9 | After Test #10; mutate one new-dir file post-install (e.g., `echo extra >> $TMPDIR/.github/work-copilot/WORKFLOW.md`) | `python scripts/copilot-deploy.py doctor $TMPDIR` | Reports DRIFT for the mutated file; exits non-zero | P0 | Integration |
| 13 | observability | Doctor enumerates new artifacts | AC-9 | After Test #10 | `python scripts/copilot-deploy.py doctor $TMPDIR` | Output lists each new mirror artifact with OK status (where unmutated) | P1 | Integration |
| 14 | observability | Budget enforcement location documented | AC-10 | S000010_ARCHITECTURE.md exists | `grep -E '8192|wc -c' scripts/test.sh scripts/validate.sh` and read S000010_ARCHITECTURE.md | Either an existing 8192-byte gate is found (and ARCHITECTURE.md cites its location), or a new gate is added (and ARCHITECTURE.md describes the new check) | P1 | Smoke |
| 15 | usability | Bundle-layout grouping | AC-11 | `copilot-instructions.md` updated | Read the file; locate the "## Bundle layout" header (or equivalent grouping); confirm each of the 5 path strings appears under that header | All 5 paths grouped under one header; no inlined upstream content | P2 | Manual |
| 16 | core | Manual E2E — Copilot cites WORKFLOW.md | AC-1 | Windows work box, Copilot Chat, target repo with bundle installed | Ask: "what are the workflow phases?" | Copilot's answer cites `.github/work-copilot/WORKFLOW.md` by path; cited content matches upstream | P0 | E2E |
| 17 | core | Manual E2E — Copilot cites reference/ | AC-2 | Same as #16 | Ask: "how do I write a TEST-SPEC?" | Copilot's answer cites `.github/work-copilot/reference/guide-test-spec.md` | P0 | E2E |
| 18 | core | Manual E2E — Copilot cites philosophy/ | AC-3 | Same as #16 | Ask: "why is the PRD structured this way?" | Copilot's answer cites `.github/work-copilot/philosophy/rationale-PRD.md` | P0 | E2E |
| 19 | core | Manual E2E — Copilot cites examples/ | AC-4 | Same as #16 | Ask: "show me an example architecture doc" | Copilot's answer cites `.github/work-copilot/examples/example-doc-ARCHITECTURE.md` | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | Mirror byte-identity (top-level + 4 dirs) | All upstream artifacts have matching bundle copies; `MIRROR_SPECS` array enforces this | `scripts/validate.sh` (Error check 10, extended in T000011) |
| S2 | usability | 8 KB budget on `copilot-instructions.md` | File stays within Copilot's ambient-context budget after v2 pointer additions | `[ "$(wc -c < work-copilot/instructions/copilot-instructions.md)" -le 8192 ]` |
| S3 | usability | Bundle-layout pointers present | `copilot-instructions.md` literally references each new bundle dir path | `grep -F` per path string (5 grep calls) |
| S4 | core | Installer round-trip (5 spot-checks + 1 DRIFT) | New artifacts land under target's `.github/work-copilot/`; doctor catches drift | Extension to existing `scripts/test.sh:1448-1512` round-trip block |
| S5 | core | Idempotent re-install | Re-running install on same target reports `installed=0 skipped=N` | Same as S4 — second install call asserts skip count |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Copilot cites `WORKFLOW.md` for procedural questions | (a) Install bundle into target via `copilot-deploy.py install`. (b) Open VS Code with Copilot. (c) Ask "what are the workflow phases?" in Copilot Chat | Copilot's response includes a citation to `.github/work-copilot/WORKFLOW.md`; the cited content matches upstream phase definitions | Pass: explicit path citation + content match. Fail: answer from training only / no citation / wrong content |
| E2 | core | Copilot cites `reference/guide-test-spec.md` for "how do I write a TEST-SPEC?" | Same setup; ask the question | Citation to `.github/work-copilot/reference/guide-test-spec.md` | Same rubric as E1 |
| E3 | core | Copilot cites `philosophy/rationale-PRD.md` for "why is the PRD structured this way?" | Same setup; ask the question | Citation to `.github/work-copilot/philosophy/rationale-PRD.md` | Same rubric as E1 |
| E4 | core | Copilot cites `examples/example-doc-ARCHITECTURE.md` for "show me an example architecture doc" | Same setup; ask the question | Citation to `.github/work-copilot/examples/example-doc-ARCHITECTURE.md` | Same rubric as E1 |

E2E tests run on the Windows work box as part of S000009's checklist.
Results recorded in S000009_TRACKER.md or a dedicated v2 E2E log.

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Copilot citation rate across many phrasings of the same question | Manual E2E uses one canonical phrasing per topic; broader phrasing coverage requires an automated harness | If Copilot is sensitive to phrasing, work-box users may miss citations on edge-case questions. Mitigation: monitor real usage and add phrasings to the E2E checklist as they come up |
| Cross-platform install on Linux | Already covered by S000008 / scripts/test.sh round-trip; not re-tested in S000010 | Low — S000008's coverage is sufficient; S000010 adds no platform-specific behavior |
| Behavior when target repo has pre-existing files at collision paths | Not exercised by S000010 tests; covered by F000004 v1 risks-row 4 policy in installer | Low — installer policy already refuses to clobber non-bundle files without `--overwrite`; S000010 doesn't add new collision surfaces (bundle installs under `.github/work-copilot/`, not directly under `.github/`) |
| Long-tail Copilot reluctance to follow path references in `copilot-instructions.md` | Mitigation requires platform-level Copilot behavior change; we test what we can observe (E1–E4 manual checks) | Med — if Copilot proves reluctant, fall back to inlining critical pointers within the 8 KB budget; file as a follow-up risk |
