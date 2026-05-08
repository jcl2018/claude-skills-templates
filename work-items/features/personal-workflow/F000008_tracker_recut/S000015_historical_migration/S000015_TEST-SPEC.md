---
type: test-spec
parent: S000015
feature: F000008
title: "Historical migration — Test Specification"
version: 1
status: Draft
date: 2026-05-05
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | All 5 historical features have ROADMAP, no feature-summary or milestones | Walk features dirs; assert ROADMAP.md exists for each, source files deleted | `for d in work-items/features/*/F00000{1,2,4,5,6}_*; do test -f "$d"/*_ROADMAP.md || { echo "FAIL: $d missing ROADMAP"; exit 1; }; test ! -f "$d"/*_feature-summary.md || { echo "FAIL: $d still has feature-summary"; exit 1; }; test ! -f "$d"/*_milestones.md || { echo "FAIL: $d still has milestones"; exit 1; }; done` |
| S2 | core | AC-2 | All 8 historical user-stories have SPEC + DESIGN, no PRD or ARCHITECTURE | Walk user-story dirs; assert new files exist, old files deleted | `for d in $(find work-items -type d -name "S00000{1,6,7,8,9}_*" -o -name "S000010_*" -o -name "S00001{2,3}_*"); do test -f "$d"/*_SPEC.md && test -f "$d"/*_DESIGN.md && test ! -f "$d"/*_PRD.md && test ! -f "$d"/*_ARCHITECTURE.md \|\| { echo "FAIL: $d"; exit 1; }; done` |
| S3 | core | AC-3 | F000008 itself migrated to new shape | F000008 has TRACKER + DESIGN + ROADMAP, no feature-summary/milestones; each child has TRACKER + DESIGN + SPEC + TEST-SPEC | `D=work-items/features/personal-workflow/F000008_tracker_recut; test -f $D/F000008_ROADMAP.md && test ! -f $D/F000008_feature-summary.md && test ! -f $D/F000008_milestones.md && for c in S00001{4,5,6}_*; do test -f $D/$c/*_SPEC.md && test -f $D/$c/*_DESIGN.md && test ! -f $D/$c/*_PRD.md; done` |
| S4 | core | AC-2 | TEST-SPEC frontmatter updated on all 8 migrated user-stories | grep for stale `prd:` or `architecture:` keys in TEST-SPEC frontmatter | `! find work-items -name "S*_TEST-SPEC.md" \| xargs grep -lE "^(prd\|architecture):"` |
| S5 | core | AC-5 | Full work-items/ tree passes /personal-workflow check | (Manual: run `/personal-workflow check` and assert zero findings) | Manual via `/personal-workflow check` — see E1 |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-5 | Run full validator on migrated work-items/ | (1) After all migrations complete; (2) Run `/personal-workflow check` (no path arg); (3) Read the WORK ITEM TREE report | All 14 work items show template: PASS, lifecycle: PASS, traceability: PASS where applicable; SUMMARY: 0 missing, 0 drift; FINDINGS: empty Critical + empty Warnings sections | 0 errors, 0 critical findings, 0 warnings |
| E2 | core | AC-4 | Verify Step 18 traceability on a migrated user-story with known P0 coverage | (1) Pre-migration: save `/personal-workflow check work-items/.../S000012_deprecated_status_semantics/` output to /tmp/baseline.txt; (2) Migrate S000012; (3) Re-run check on same path; (4) Diff outputs for Step 18 PASS lines | Post-migration shows same PASS line "All P0 stories have TEST-SPEC coverage"; no new [UNTESTED] findings | diff between baseline and post shows no regression in Step 18 PASS lines |
| E3 | usability | AC-1 | Verify ROADMAP preserves milestone history | (1) Pre-migration: open F000005_milestones.md, note its content (had merge-date entries); (2) Migrate F000005; (3) Open F000005_ROADMAP.md | ROADMAP's `### Delivery History` sub-section contains the prior milestone entries verbatim or near-verbatim | Manual read; historical PR links + merge dates present |
| E4 | resilience | AC-3 | F000008's child SPEC.md preserves the original PRD's P0/P1/P2 structure | After F000008 self-migration, open S000014_SPEC.md; locate `## Requirements` section | `## Requirements` contains `### P0 (Must-Have)`, `### P1 (Important)`, `### P2 (Nice-to-Have)` sub-sections, each with the original story rows from S000014_PRD.md | Manual read; sub-section headers present in same order |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Migration of `deprecated/work-items/F000003_*` | Out of scope per design (sealed history) | F000003's content stays on old shape forever; not exposed to /personal-workflow check (different walk root) |
| Migration script regression test | This story does pure file ops, no reusable script | If a re-migration is ever needed, would need a fresh approach |
| Performance — migration time | Migration is one-shot for 14 items | If items grow to hundreds, would need batching; not the case today |
| Hand-distillation of DESIGN.md from `~/.gstack/projects/` for items with matching design docs | Out of scope; default is stub per Open Question 1 | DESIGN.md content quality is low for historical items; acceptable for sealed-history user-stories |
