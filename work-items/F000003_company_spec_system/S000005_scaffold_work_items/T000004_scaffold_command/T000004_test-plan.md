---
type: test-plan
parent: T000004_scaffold_command
title: "Implement Scaffold Create Subcommand — Test Plan"
date: 2026-04-12
author: chjiang
status: Draft
---

## Scope

Adds `create` subcommand to company-workflow SKILL.md. Reads company templates,
generates next ID, creates work item directory with all required artifacts, fills
placeholders, and validates the result.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Feature scaffolds 5 artifacts | `create --type feature --name test-feature` | 5 .md files in new directory | Pending |
| 2 | Defect scaffolds 3 artifacts | `create --type defect --name test-defect` | 3 .md files | Pending |
| 3 | Task scaffolds 2 artifacts | `create --type task --name test-task --parent S000003` | 2 .md files, parent in frontmatter | Pending |
| 4 | Userstory scaffolds 5 artifacts | `create --type userstory --name test-story` | 5 .md files, type=userstory | Pending |
| 5 | Review scaffolds 2 artifacts | `create --type review --name test-review` | 2 .md files, deadline field present | Pending |
| 6 | ID increments correctly | Scaffold two features in sequence | Second ID = first + 1 | Pending |
| 7 | Placeholders filled | Read scaffolded tracker | name, id, date, branch all populated | Pending |
| 8 | Scaffolded tracker validates | Run company-workflow validate on new tracker | Exit 0 | Pending |
| 9 | Existing templates unchanged | git diff templates/*.md after scaffold | Empty | Pending |

## Verification Steps

- [ ] E2E tests E1-E8 from S000005_TEST-SPEC all pass
- [ ] validate.sh still passes after scaffolding test items
- [ ] Clean up test work items after verification

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (local dev) | claude/nostalgic-volhard | Pending |
