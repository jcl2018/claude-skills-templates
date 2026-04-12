---
type: test-plan
parent: T000002_copy_spec_scaffold
title: "Copy Spec Templates and Create Skill Scaffold — Test Plan"
date: 2026-04-11
author: chjiang
status: Draft
---

## Scope

Copies 13 template files from `~/Downloads/spec/templates/` to `templates/company-workflow/`,
creates `skills/company-workflow/` with SKILL.md, contract.json, reference guides,
philosophy docs, and validation fixtures, and adds a catalog entry to `skills-catalog.json`.

## Regression Test Cases

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

## Verification Steps

- [x] Local build succeeds (validate.sh PASS + test.sh PASS)
- [x] Manual inspection of templates/company-workflow/ matches spec structure (13 files)
- [x] Manual inspection of skills/company-workflow/ has all subdirectories (reference/, philosophy/, fixtures/)
- [x] git diff confirms only new files added, no existing files modified

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (local dev) | claude/nostalgic-volhard | Pass (9/9 TC, 4/4 verification) |
