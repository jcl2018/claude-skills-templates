---
type: test-plan
parent: T000003_enforcement_skill
title: "Implement Enforcement Check Subcommand — Test Plan"
date: 2026-04-11
author: chjiang
status: Draft
---

## Scope

Adds `company-artifact-manifests.json` and a `check` subcommand to the company-workflow
skill. The check subcommand validates that company work items have all required
companion artifacts for their type, and that each artifact's frontmatter and sections
match the template.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Manifest parses | `python3 -c "import json; json.load(open('skills/company-workflow/company-artifact-manifests.json'))"` | Exit 0 | Pending |
| 2 | Manifest has 5 types | Parse and count type keys | feature, defect, task, userstory, review | Pending |
| 3 | Feature artifact count | Read feature.required array length | 5 | Pending |
| 4 | Defect artifact count | Read defect.required array length | 3 | Pending |
| 5 | Task artifact count | Read task.required array length | 2 | Pending |
| 6 | Userstory artifact count | Read userstory.required array length | 5 | Pending |
| 7 | Review artifact count | Read review.required array length | 2 | Pending |
| 8 | Complete feature passes check | Scaffold all 5 artifacts, run check | 5x [PASS] | Pending |
| 9 | Incomplete feature caught | Remove PRD from feature, run check | [MISSING] PRD.md | Pending |
| 10 | Drift caught | Remove workflow_type from tracker, run check | [DRIFT] missing "workflow_type" | Pending |
| 11 | /docs check unaffected | Run /docs check before and after | Identical output | Pending |

## Verification Steps

- [ ] Manifest JSON valid and complete
- [ ] check subcommand exits 0 on complete work items, non-zero on incomplete
- [ ] /docs check output unchanged (no cross-contamination)
- [ ] validate.sh still passes

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (local dev) | claude/nostalgic-volhard | Pending |
