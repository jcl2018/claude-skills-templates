---
type: test-plan
parent: T000002_implement_company_workflow
title: "Implement Company Workflow — Test Plan"
date: 2026-04-11
author: chjiang
status: Draft
---

## Scope

Full company-workflow implementation: template import, skill scaffold, registry,
validation, artifact enforcement, and scaffolding. Covers templates/company-workflow/
(13 files), skills/company-workflow/ (SKILL.md + manifest + reference + philosophy +
fixtures), template-registry.json, and skills-catalog.json.

## Regression Test Cases

### Template Registry (from original T000002)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | All 13 company templates present | `ls templates/company-workflow/ \| wc -l` | 13 files | Pass |
| 2 | SKILL.md has valid frontmatter | `grep 'name:' skills/company-workflow/SKILL.md` | name: company-workflow | Pass |
| 3 | contract.json matches spec | `diff ~/Downloads/spec/contract.json skills/company-workflow/contract.json` | No diff | Pass |
| 4 | Reference guides copied | `ls skills/company-workflow/reference/guide-*.md \| wc -l` | 7 files | Pass |
| 5 | Philosophy docs copied | `ls skills/company-workflow/philosophy/rationale-*.md \| wc -l` | 3 files | Pass |
| 6 | Fixtures copied | `ls skills/company-workflow/fixtures/invalid-*.md \| wc -l` | 3 files | Pass |
| 7 | Catalog entry added | `grep company-workflow skills-catalog.json` | Entry found | Pass |
| 8 | validate.sh passes | `./scripts/validate.sh` | Exit code 0 | Pass |
| 9 | Personal-dev templates unchanged | `git diff templates/*.md` | Empty output | Pass |

### Artifact Enforcement (from original T000003)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 10 | Manifest parses | Parse company-artifact-manifests.json | Valid JSON | Pending |
| 11 | Manifest has 5 types | Count type keys | feature, defect, task, userstory, review | Pending |
| 12 | Feature artifact count | Read feature.required length | 5 | Pending |
| 13 | Defect artifact count | Read defect.required length | 3 | Pending |
| 14 | Task artifact count | Read task.required length | 2 | Pending |
| 15 | Userstory artifact count | Read userstory.required length | 5 | Pending |
| 16 | Review artifact count | Read review.required length | 2 | Pending |
| 17 | Complete feature passes check | Scaffold all 5, run check | 5x [PASS] | Pending |
| 18 | Incomplete feature caught | Remove PRD, run check | [MISSING] PRD.md | Pending |
| 19 | Drift caught | Remove workflow_type, run check | [DRIFT] | Pending |
| 20 | /docs check unaffected | Run before and after | Identical output | Pending |

### Scaffolding (from original T000004)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 21 | Feature scaffolds 5 artifacts | create --type feature --name test | 5 .md files | Pending |
| 22 | Defect scaffolds 3 artifacts | create --type defect --name test | 3 .md files | Pending |
| 23 | Task scaffolds 2 artifacts | create --type task --name test --parent S000003 | 2 .md files, parent in frontmatter | Pending |
| 24 | Userstory scaffolds 5 artifacts | create --type userstory --name test | 5 .md files, type=userstory | Pending |
| 25 | Review scaffolds 2 artifacts | create --type review --name test | 2 .md files, deadline present | Pending |
| 26 | ID increments correctly | Scaffold two features in sequence | Second ID = first + 1 | Pending |
| 27 | Placeholders filled | Read scaffolded tracker | name, id, date, branch populated | Pending |
| 28 | Scaffolded tracker validates | Run validate on new tracker | Exit 0 | Pending |
| 29 | Existing templates unchanged | git diff templates/*.md after scaffold | Empty | Pending |

## Verification Steps

- [x] Local build succeeds (validate.sh PASS + test.sh PASS) -- template registry phase
- [x] Manual inspection of templates/company-workflow/ matches spec (13 files)
- [x] git diff confirms only new files added, no existing files modified
- [ ] Manifest JSON valid and complete (enforcement phase)
- [ ] check subcommand exits 0 on complete, non-zero on incomplete (enforcement phase)
- [ ] E2E tests E1-E8 from TEST-SPEC all pass (scaffolding phase)
- [ ] Clean up test work items after verification

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (local dev) | claude/nostalgic-volhard | Pass (9/9 registry, enforcement+scaffolding pending) |
