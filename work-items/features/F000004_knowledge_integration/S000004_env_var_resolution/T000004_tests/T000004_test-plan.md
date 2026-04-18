---
type: test-plan
parent: T000004
title: "tests — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Adds automated tests for S000004 (env-var resolution + missing-folder warning). Covers Tier 1 structural assertions, Tier 2 E2E scenarios, and a regression diff against existing fixtures. No production code changes — this task only adds test code and wiring.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Tier 1: SKILL.md has Knowledge Resolution section | Run `scripts/test.sh`; check grep result | Assertion passes | Pending |
| 2 | Tier 1: SKILL.md references `AI_KNOWLEDGE_DIR` and exposes `_KNOWLEDGE_DIR` | grep both symbols | Both present | Pending |
| 3 | Tier 1: WORKFLOW.md documents `AI_KNOWLEDGE_DIR` | grep workflow doc | Non-empty | Pending |
| 4 | Tier 1: repo `./scripts/validate.sh` passes | Run validate | Exit 0 | Pending |
| 5 | Tier 2 E1: env unset → warning | `unset AI_KNOWLEDGE_DIR`; invoke skill validate on fixture | Exactly one stderr warning; exit 0; stdout byte-identical to pre-change baseline | Pending |
| 6 | Tier 2 E2: env set to valid dir → silent | `export AI_KNOWLEDGE_DIR=$(mktemp -d)`; invoke | Zero warnings; exit 0 | Pending |
| 7 | Tier 2 E3: env set to non-existent path | `export AI_KNOWLEDGE_DIR=/does/not/exist`; invoke | Warning names path + "not found"; exit 0 | Pending |
| 8 | Tier 2 E4: env set to file | `touch /tmp/kx; export AI_KNOWLEDGE_DIR=/tmp/kx`; invoke | Warning mentions "not a directory"; exit 0 | Pending |
| 9 | Regression diff: validate output stable | Run validate twice (env unset, env=valid dir); `diff` stdout | Empty diff | Pending |

## Verification Steps

- [ ] `./scripts/test.sh` passes locally
- [ ] All Tier 2 scenarios reproduced manually in a terminal (not just script run)
- [ ] New assertions added run in under 5 seconds (fast enough for pre-commit hook)
- [ ] Warning text in assertions references the SAME constant used in SKILL.md (single source of truth)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
