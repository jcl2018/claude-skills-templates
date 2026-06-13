---
type: test-plan
parent: T000048
title: "Post-land recap convention — Test Plan"
date: 2026-06-13
author: chjiang
status: Draft
---

<!-- Scope: ONE task — add the `## Post-land recap` convention section to CLAUDE.md.
     This is a pure documentation/convention addition; no behavioral surface is
     touched, so the cases are doc-content assertions + the standard repo-health gates. -->

## Scope

Adds one new prose section — `## Post-land recap` — to the project `CLAUDE.md`,
placed adjacent to the existing `## CI/CD merge convention` section. No code, no
script, no skill-catalog change, no test-spec change, no pipeline edit.

Files modified:
- `CLAUDE.md` (add the `## Post-land recap` section)

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Section exists | `grep -c '^## Post-land recap' CLAUDE.md` | Prints `1` (exactly one such section) | Pending |
| 2 | Two recap parts named | Read the new section | It states both recap parts: **What this merge did** (change + version + PR#/merge SHA) and **How to verify it** (concrete commands/checks) | Pending |
| 3 | Both trigger paths named | Read the new section | It names the direct `/land-and-deploy` path AND the `cj_goal` orchestrator land step (`CJ_goal_defect` Step 10 + `CJ_goal_todo_fix`'s `/ship → /land-and-deploy` tail) | Pending |
| 4 | Advisory posture stated | Read the new section | It states the recap never blocks, never changes the land outcome, and fires only after the merge is verified MERGED | Pending |
| 5 | Placement | Inspect CLAUDE.md section order | The new section sits adjacent to `## CI/CD merge convention` | Pending |
| 6 | Doc contract green | `./scripts/validate.sh` | `RESULT: PASS` — CLAUDE.md still a declared root operational doc (Check 15/17 declared⇔on-disk); Check 19 N/A (operational, not human-doc) | Pending |
| 7 | Full suite green | `./scripts/test.sh` | Full suite passes; no behavioral surface touched | Pending |

## Verification Steps

<!-- How was the change verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` → `RESULT: PASS`
- [ ] `./scripts/test.sh` → full suite green
- [ ] Manual read-through: the new `## Post-land recap` section is unambiguous,
      names both trigger paths, and states the two recap parts + the advisory posture
- [ ] Doc-sync (`/CJ_document-release`) green — no other registered doc goes stale

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (local) | claude/cool-lichterman-cbb4b0 | Pending |
