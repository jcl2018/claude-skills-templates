---
type: test-plan
parent: T000008_implement_prompt_and_validator
title: "Implement validate.prompt.md + manifest — Test Plan"
date: 2026-04-22
author: chjiang
status: Draft
---

<!-- Scope: ONE task. Cases must be concrete and reproducible. -->

## Scope

This task produces the `validate.prompt.md` prompt file, the
`copilot-artifact-manifests.json` manifest, and mirrors
`templates/company-workflow/` into `work-copilot/templates/`. Test scope is
the prompt's behavior when invoked in Copilot Chat on the bundled
fixtures.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Prompt file has valid Copilot frontmatter | `head -n 3 work-copilot/prompts/validate.prompt.md` shows `---` / `mode: agent` / `description:` | Frontmatter parses; Copilot lists the prompt | Pending |
| 2 | Manifest JSON parses | `python -c "import json; json.load(open('work-copilot/copilot-artifact-manifests.json'))"` | No exception | Pending |
| 3 | Templates mirror is complete | `diff -rq templates/company-workflow/ work-copilot/templates/` | No missing files on the bundle side | Pending |
| 4 | Good-feature fixture passes | In Copilot Chat: `/validate work-copilot/fixtures/good-feature/` | All PASS, zero MISSING/DRIFT, summary footer present | Pending |
| 5 | Missing-artifact fixture flags MISSING | In Copilot Chat: `/validate work-copilot/fixtures/missing-milestones/` | `[MISSING] milestones.md` line present | Pending |
| 6 | Drift fixture flags DRIFT | In Copilot Chat: `/validate work-copilot/fixtures/drift-tracker/` | `[DRIFT]` line with the specific field name | Pending |
| 7 | File mode (single tracker) | In Copilot Chat: `/validate work-copilot/fixtures/good-feature/F000001_TRACKER.md` | File-mode output, no manifest iteration | Pending |
| 8 | Parity with Claude Code | Run `/company-workflow check` and `/validate` on the same fixture; diff outputs | Status lines identical (order-insensitive) | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds on macOS (bundle builds, fixtures present)
- [ ] Prompt validated by `scripts/validate.sh` (Tier 1 smoke checks S1–S5 from TEST-SPEC)
- [ ] Manual run on the Windows work machine (E2E #1 from parent TEST-SPEC)
- [ ] Prompt body is under 2 KB (budget guard against context bloat)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (development) | feat/work-copilot HEAD | Pending |
| Windows 11 + VS Code Copilot Chat | feat/work-copilot HEAD | Pending |
