---
type: test-spec
parent: S000014
feature: F000008
title: "Templates + manifest + check.md — Test Specification"
version: 1
status: Draft
date: 2026-05-05
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Smoke + E2E together cover every PRD P0 acceptance criterion.
     Soft cap: 5 rows per tier (validator emits [INFO] if exceeded). -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | New templates exist with required sections | Both doc-SPEC.md and doc-ROADMAP.md present in templates/personal-workflow/; SPEC has `## Requirements` with `### P0 (Must-Have)`, `### P1 (Important)`, `### P2 (Nice-to-Have)`; ROADMAP has `## Scope`, `## Decomposition`, `## Delivery Timeline` with `### Delivery History` | `test -f templates/personal-workflow/doc-SPEC.md && grep -q '### P0 (Must-Have)' templates/personal-workflow/doc-SPEC.md && test -f templates/personal-workflow/doc-ROADMAP.md && grep -q '### Delivery History' templates/personal-workflow/doc-ROADMAP.md` |
| S2 | core | AC-1, AC-2 | Old templates deleted | doc-PRD, doc-ARCHITECTURE, doc-feature-summary, doc-milestones absent | `for f in doc-PRD.md doc-ARCHITECTURE.md doc-feature-summary.md doc-milestones.md; do test ! -f templates/personal-workflow/$f \|\| { echo "FAIL: $f still exists"; exit 1; }; done` |
| S3 | core | AC-3 | Manifest declares new artifact set | personal-artifact-manifests.json types.feature.required lists tracker, design, roadmap (3 artifacts); types.user-story.required lists tracker, design, spec, test-spec (4 artifacts) | `jq '.types.feature.required \| map(.artifact)' skills/personal-workflow/personal-artifact-manifests.json \| grep -qE '"design".*"roadmap"\|"roadmap".*"design"'` |
| S4 | core | AC-5 | No stale references in active skill files | grep across skills/personal-workflow/ and templates/personal-workflow/ for old artifact names returns no matches outside error messages and the 4 known check.md incidentals (now updated) | `! grep -REn "doc-PRD\|doc-ARCHITECTURE\|doc-feature-summary\|doc-milestones" skills/personal-workflow/ templates/personal-workflow/` |
| S5 | core | AC-4 | check.md Step 18 references SPEC not PRD | Step 18 source filename is SPEC.md, no PRD.md remaining at lines 303-329, line 330 legacy clause deleted | `! sed -n '300,335p' skills/personal-workflow/check.md \| grep -q 'PRD\.md' && ! sed -n '300,335p' skills/personal-workflow/check.md \| grep -q 'Test Matrix'` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-3 | Scaffold a fresh feature using new templates and verify check passes | (1) `mkdir -p /tmp/F999_smoke_test`; (2) Copy + substitute placeholders in TRACKER, DESIGN, ROADMAP from new templates; (3) Run `/personal-workflow check /tmp/F999_smoke_test/` | Report shows ARTIFACTS: PASS for TRACKER, DESIGN, ROADMAP; LIFECYCLE: PASS; SUMMARY: 3 artifacts checked, 0 missing, 0 drift | 0 errors, 0 [MISSING], 0 [DRIFT] |
| E2 | core | AC-2, AC-3 | Scaffold a fresh user-story using new templates and verify check passes | (1) `mkdir -p /tmp/S999_smoke_test`; (2) Copy + substitute placeholders in TRACKER, DESIGN, SPEC, TEST-SPEC from new templates; (3) Run `/personal-workflow check /tmp/S999_smoke_test/` | Report shows ARTIFACTS: PASS for all 4; no PRD.md or ARCHITECTURE.md flagged as missing or extra | 0 errors, 0 [MISSING], 0 [DRIFT] |
| E3 | core | AC-4 | Verify Step 18 traceability works on SPEC.md with P0 story | Same /tmp/S999_smoke_test from E2; populate SPEC's `### P0 (Must-Have)` row #1 with a real story; populate TEST-SPEC's Smoke Tests AC column with `AC-1`; run `/personal-workflow check /tmp/S999_smoke_test/` | Step 18 reports `[PASS] All P0 stories have TEST-SPEC coverage`; no [UNTESTED] | Step 18 PASS line present, no UNTESTED |
| E4 | observability | AC-5 | Confirm WORKFLOW.md narrative reads consistently after the 7-line update | Open WORKFLOW.md, scan lines 21, 22, 38, 41, 49, 64-65, 190; verify each reads naturally with new artifact names; verify the Type-to-Artifact Mapping table shows feature=3, user-story=4, task=2, defect=3 | All 7 surfaces updated; table counts match manifest; no orphan PRD/ARCHITECTURE references | Manual read; no awkward phrasing |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Migration of historical work items | Owned by S000015 | Until S000015 ships, full `/personal-workflow check` will show DRIFT/MISSING on historical items — expected per design |
| F000008 self-migration | Owned by S000015 sweep | F000008 itself stays on old shape until S000015 lands |
| Examples + fixtures + repo-level surfaces | Owned by S000016 | example trackers and PHILOSOPHY/CONTRIBUTING/registry will reference old names until S000016 lands; not exposed to engineer's daily flow |
| Backward-compat verification | Out of scope per design | If old-shape branches not yet merged exist on remote, they will fail check after this lands. Acceptable per design Big Decision #5 |
