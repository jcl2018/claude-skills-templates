---
type: test-spec
parent: universal-4phase-lifecycle
feature: universal-4phase-lifecycle
title: "Universal 4-Phase Work Lifecycle — Test Specification"
version: 2
status: Active
date: 2026-04-10
author: ""
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | Build-forward reads doc triplet | AC-1 | Feature item with populated PRD+ARCH+TEST-SPEC | Invoke `work-implement` on feature | Command presents plan derived from doc triplet | P0 | E2E |
| 2 | Build-forward without triplet | AC-2 | Feature item without doc triplet | Invoke `work-implement` on feature | Command reads tracker and drafts own plan | P0 | E2E |
| 3 | Debug-backward enters on defect | AC-3 | Defect work item | Invoke `work-implement` on defect | Command enters symptom collection mode | P0 | E2E |
| 4 | 3-strike escalation | AC-4 | Debug-backward mode, 3 failed hypotheses | Reject 3 hypotheses in sequence | Command stops, asks to escalate | P0 | E2E |
| 5 | Template has 4-phase lifecycle | AC-5 | Fresh scaffold of feature, defect, task, user-story, review | Read Lifecycle section | Exactly 4 checkboxes: Track, Implement, Review, Ship | P0 | Smoke |
| 6 | Router suggests implement (feature) | AC-6a | Feature with Track checked, Implement unchecked | Run `work` | Router suggests `work-implement` | P0 | E2E |
| 7 | Router skips implement (review) | AC-6b | Review item with Track checked | Run `work` | Router suggests `work-review` directly | P0 | E2E |
| 8 | work-audit runs at any stage | AC-7 | Any work item at any lifecycle stage | Invoke `work-audit` | Runs tracking + alignment + inline checks, writes findings to journal | P0 | E2E |
| 9 | work-audit never modifies lifecycle | AC-8 | work-audit completes | Check lifecycle checkboxes | No checkboxes changed by work-audit | P0 | Smoke |
| 10 | Session resume (build-forward) | AC-9 | Interrupted build-forward session | Re-invoke `work-implement` | Detects incomplete entries, resumes | P1 | E2E |
| 11 | Audit zero FAILs | AC-10 | All changes deployed | Run project-level audit | Zero lifecycle-related FAILs | P1 | E2E |
| 12 | Journal logging (build-forward) | AC-9 | Build-forward mode completing work | Complete a plan item | Journal entry with file path + commit SHA | P2 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no command execution)

| # | Check | What It Validates | Script/Command |
|---|-------|-------------------|---------------|
| S1 | contract.json requires 4 phases | Contract enforces lifecycle | `jq '.lifecycle.min_checkboxes' spec/contract.json` returns 4 |
| S2 | Feature tracker has 4-phase lifecycle | Template correct | `grep -c 'Track\|Implement\|Review\|Ship' spec/templates/tracker-feature.md` returns 4 |
| S3 | Defect tracker has 4-phase lifecycle | Template correct | `grep -c 'Track\|Implement\|Review\|Ship' spec/templates/tracker-defect.md` returns 4 |
| S4 | Review tracker has 4-phase lifecycle | Template correct | `grep -c 'Track\|Implement\|Review\|Ship' spec/templates/tracker-review.md` returns 4 |
| S5 | Task tracker has 4-phase lifecycle | Template correct | `grep -c 'Track\|Implement\|Review\|Ship' spec/templates/tracker-task.md` returns 4 |
| S6 | User-story tracker has 4-phase lifecycle | Template correct | `grep -c 'Track\|Implement\|Review\|Ship' spec/templates/tracker-user-story.md` returns 4 |
| S7 | artifact-manifests.json maps all 5 types | All types covered | `jq 'keys' artifact-manifests.json` includes feature, defect, user-story, task, review |
| S8 | Invalid examples fail `workpipe audit` | Contract enforcement works | `workpipe audit spec/reference/invalid-bad-frontmatter.md` exits non-zero |
| S9 | Rationale triplet is internally consistent | PRD↔ARCH↔TEST-SPEC aligned | `test -f spec/philosophy/rationale-PRD.md && test -f spec/philosophy/rationale-ARCHITECTURE.md && test -f spec/philosophy/rationale-TEST-SPEC.md` |

### Tier 2: E2E Tests (real command execution)

| # | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|----------|----------------------------|-----------------|--------|
| E1 | Build-forward on feature | 1. Create feature work item with populated doc triplet. 2. Invoke `work-implement`. 3. Approve plan. | Command reads triplet, presents plan, begins execution. Journal entry created. | Plan references PRD stories. Journal has file+SHA. |
| E2 | Debug-backward on defect | 1. Create defect work item. 2. Invoke `work-implement`. 3. Provide symptoms. | Command enters debug mode, forms hypotheses, logs to journal. | Hypothesis H1 appears in journal with prediction. |
| E3 | 3-strike escalation | 1. In debug-backward, reject 3 hypotheses. | Command stops, presents escalation message. | Message includes "3 hypotheses" and asks user for direction. |
| E4 | Router phase suggestion | 1. Create item, mark Track done. 2. Run `work`. | Router shows "Next: work-implement" in menu. | implement appears as suggested next phase. |
| E5 | Full feature lifecycle | 1. Create feature. 2. work-track. 3. work-implement. 4. work-review. 5. work-ship. | All 4 checkboxes marked (Track, Implement, Review, Ship), handoff blocks for each phase. | All `- [x]` present. 4 handoff blocks in journal. |
| E6 | Review item minimal path | 1. Create review item. 2. work-track. 3. work-review. 4. work-ship. | Track, Review, Ship checked. Implement stays unchecked. | Router never suggested work-implement. 3 handoff blocks. |
| E7 | work-audit mid-lifecycle | 1. Create feature, complete Track. 2. Invoke `work-audit`. | Command runs checks, writes findings to journal. No lifecycle checkboxes modified. | Journal has findings table. Lifecycle unchanged. |
| E9 | work-audit catches issues | 1. Create feature with incomplete doc triplet. 2. Invoke `work-audit`. | Command reports FAILs for missing alignment. | FAIL entries in journal. |
| E10 | work-audit on clean item | 1. Create feature with complete doc triplet. 2. Invoke `work-audit`. | Command reports "All checks passed". | Journal entry says all passed. |

## Coverage Gaps

- **Linux CI integration in work-review**: Out of scope for this feature. Deferred.
- **Multi-repo template drift**: Template and command deploys happen separately. Drift tested by `workpipe audit`, not E2E.
- **User-story and task full paths**: Covered by feature/task similarity; not separately E2E tested.
- **work-audit on multi-triplet items**: Tested in work-audit's own test suite, not duplicated here.
