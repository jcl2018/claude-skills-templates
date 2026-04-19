---
type: test-plan
parent: T000005
title: "build-fixtures — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Creates `skills/company-workflow/fixtures/valid-knowledge-dir/` with five categories covering every `.knowledge.yml` state the impl tasks need. No skill or script code changes — pure fixture authoring.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Root fixture dir exists | `test -d skills/company-workflow/fixtures/valid-knowledge-dir` | Exit 0 | Pending |
| 2 | `coding/` always-on with nested md | `test -f .../coding/.knowledge.yml && test -f .../coding/cpp/errors.md` | All present | Pending |
| 3 | `coding/.knowledge.yml` declares `surface: always` | `grep -q "surface: always" .../coding/.knowledge.yml` | Match | Pending |
| 4 | `runbooks/` on-demand with phrase trigger | `grep -Eq 'triggers:.*"pricing engine"' .../runbooks/.knowledge.yml` | Match | Pending |
| 5 | `notes/` has NO `.knowledge.yml` | `test ! -f .../notes/.knowledge.yml` | Assertion true | Pending |
| 6 | `broken/.knowledge.yml` is actually malformed | Test parses successfully with `yq`-strict; on malformed it should fail | Parse fails | Pending |
| 7 | `empty-triggers/` declares `triggers: []` | `grep -q "triggers: \[\]" .../empty-triggers/.knowledge.yml` | Match | Pending |
| 8 | Each md file contains a unique canary string | `grep -l CANARY_ .../[cat]/*.md` returns one per file | Canary hit rate = 1/file | Pending |
| 9 | Fixture README documents every category | `test -f .../README.md && grep -q coding .../README.md` | README present, covers all cats | Pending |
| 10 | No fixture file exceeds 1 KB (keeps fixtures readable) | `find .../valid-knowledge-dir -name '*.md' -size +1k` | Empty result | Pending |

## Verification Steps

- [ ] Fixture tree committed with git-tracked content (no `.gitignore` regressions)
- [ ] Manual walk: `tree .../valid-knowledge-dir` produces the expected layout
- [ ] Each canary string is unique across the whole fixture (for unambiguous E2E assertions downstream)
- [ ] `./scripts/validate.sh` still passes (catalog/manifest unaffected)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
