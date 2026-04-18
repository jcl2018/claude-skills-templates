---
type: test-plan
parent: T000003
title: "implement-resolution-block — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

This task adds the Knowledge Resolution bash block to `skills/company-workflow/SKILL.md` and a matching configuration section to `skills/company-workflow/WORKFLOW.md`. It does not change `company-artifact-manifests.json`, the catalog, or any template. Tests for this change live in T000004.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Env unset → warning | `unset AI_KNOWLEDGE_DIR`; invoke validate on an existing fixture | One stderr warning naming `AI_KNOWLEDGE_DIR`; exit 0 | Pending |
| 2 | Env empty string → warning | `export AI_KNOWLEDGE_DIR=""`; invoke validate | Same warning as #1; exit 0 | Pending |
| 3 | Env points to non-existent path → warning | `export AI_KNOWLEDGE_DIR=/no/such/path`; invoke validate | Warning naming the path + "not found"; exit 0 | Pending |
| 4 | Env points to a file not a dir | `touch /tmp/kf; export AI_KNOWLEDGE_DIR=/tmp/kf`; invoke validate | Warning naming the path + "not a directory"; exit 0 | Pending |
| 5 | Env points to a valid dir → silent | `export AI_KNOWLEDGE_DIR=$(mktemp -d)`; invoke validate | Zero warnings; `$_KNOWLEDGE_DIR` set to the path internally | Pending |
| 6 | Zero regression on existing fixture output | Run validate on `fixtures/valid-feature-dir/` with env unset and with env set to a valid dir; diff stdout | Diff is empty | Pending |
| 7 | WORKFLOW.md documents env var | `grep AI_KNOWLEDGE_DIR skills/company-workflow/WORKFLOW.md` | Non-empty output | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (macOS dev machine)
- [ ] Local build succeeds (Linux CI)
- [ ] `./scripts/validate.sh` passes
- [ ] Manual reproduction of each scenario in the Regression Test Cases table
- [ ] Warning text rendered in a real Claude Code session matches the drafted copy (no surprise escaping)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
