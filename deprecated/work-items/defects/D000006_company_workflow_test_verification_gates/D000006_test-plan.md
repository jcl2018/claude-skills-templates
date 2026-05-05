---
type: test-plan
parent: D000006
title: "company-workflow phase 2 lacks test-verification gate; test-plan vs test-spec roles unclear — Regression Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

## Scope

Template-only edits across:

- `templates/company-workflow/tracker-defect.md`, `tracker-task.md`, `tracker-user-story.md`, `tracker-feature.md` — Phase 2 gate additions/changes
- `templates/company-workflow/doc-test-plan.md`, `doc-TEST-SPEC.md` — top-of-file scope comments
- `templates/company-workflow/doc-test-plan.md` — title placeholder generalization
- `templates/personal-workflow/doc-test-plan.md`, `doc-TEST-SPEC.md` — mirrored scope comments
- `skills/company-workflow/WORKFLOW.md` — Scaffolding Conventions paragraph addition

No `contract.json` changes in the minimum-landing scope. No SKILL.md validator code changes.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | tracker-defect Phase 2 mentions test-plan verification | `grep -n "test-plan.md marked Pass" templates/company-workflow/tracker-defect.md` | Match found inside `### Phase 2: Implement` Gates list | Pass (line 26) |
| 2 | tracker-task Phase 2 has new test-verification gate | `grep -n "test-plan.md marked Pass" templates/company-workflow/tracker-task.md` | Match found inside Phase 2 Gates list | Pass (line 25) |
| 3 | tracker-user-story Phase 2 references TEST-SPEC | `grep -n "TEST-SPEC.md marked Pass" templates/company-workflow/tracker-user-story.md` | Match found inside Phase 2 Gates list | Pass (line 25) |
| 4 | tracker-feature Phase 2 has roll-up gate | `grep -n "child user-story.*TEST-SPEC" templates/company-workflow/tracker-feature.md` | Match found inside Phase 2 Gates list | Pass (line 26) |
| 5 | doc-test-plan.md has scope comment | `grep -n "ONE fix .defect. or ONE task" templates/company-workflow/doc-test-plan.md` | Match found near top of file (before first `##` header) | Pass (line 10) |
| 6 | doc-test-plan.md title generalized | `grep -c "{Defect Name} — Regression Test Plan" templates/company-workflow/doc-test-plan.md` | Count is `0` (the defect-specific phrasing has been generalized) | Pass (count=0) |
| 7 | doc-TEST-SPEC.md has scope comment | `grep -n "ENTIRE user story" templates/company-workflow/doc-TEST-SPEC.md` | Match found near top of file (before first `##` header) | Pass (line 15) |
| 8 | personal-workflow scope comments mirrored | `grep -l "ONE fix .defect. or ONE task" templates/personal-workflow/doc-test-plan.md && grep -l "ENTIRE user story" templates/personal-workflow/doc-TEST-SPEC.md` | Both files match | Pass |
| 9 | WORKFLOW.md has test-plan vs TEST-SPEC paragraph | `grep -n "test-plan vs TEST-SPEC" skills/company-workflow/WORKFLOW.md` | Match found in Scaffolding Conventions section | Pass (line 91) |
| 10 | `/personal-workflow check` clean against this defect | Run `/personal-workflow check work-items/defects/D000006_company_workflow_test_verification_gates/` | All structural checks Pass; 0 errors | Pass (manual: required sections + lifecycle + no unresolved placeholders verified) |
| 11 | No regression on existing trackers | Run `./scripts/validate.sh` and `./scripts/test.sh` | Both Pass; no new errors | Pass (validate.sh 0/0; test.sh 0 failures) |
| 12 | No tooling depends on the old test-plan title string | `grep -rn "{Defect Name} — Regression Test Plan" scripts/ skills/` | 0 matches (no caller depends on the old phrasing) | Pass (0 matches) |

## Verification Steps

- [x] `./scripts/validate.sh` Pass
- [x] `./scripts/test.sh` Pass
- [x] `/personal-workflow check work-items/defects/D000006_company_workflow_test_verification_gates/` Pass (manual structural check: all required sections + lifecycle + zero unresolved `{PLACEHOLDER}` patterns)
- [x] Manually scaffolded a company-workflow task tracker (read template post-edit) — Phase 2 shows `All test cases in test-plan.md marked Pass`
- [x] Manually scaffolded a company-workflow user-story tracker (read template post-edit) — Phase 2 shows the TEST-SPEC.md gate
- [x] Manually scaffolded a company-workflow defect's test-plan.md (read template post-edit) — scope comment present at top, title placeholder reads `{Item Name} — Test Plan`, parent placeholder generalized to `{ITEM_ID}`
- [x] Read the WORKFLOW.md addition end-to-end — `### test-plan vs TEST-SPEC` subsection answers the scope question without needing to consult the templates

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 | branch `claude/nostalgic-volhard` | Pass |
