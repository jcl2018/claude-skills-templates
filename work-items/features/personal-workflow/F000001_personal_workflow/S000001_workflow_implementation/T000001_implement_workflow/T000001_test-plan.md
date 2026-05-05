---
type: test-plan
parent: T000001_implement_workflow
title: "Workflow Alpha Implementation — Test Plan"
date: 2026-04-11
author: chjiang
status: Done
---

## Scope

Implements Steps 15-17 in check.md, separates the claims.json gate, adds badge taxonomy mapping, lifecycle cross-reference, `/docs tree` subcommand, and hierarchy field in artifact-manifests.json.

Files modified: artifact-manifests.json, skills/docs/check.md, skills/docs/tree.md (new), skills/docs/SKILL.md, skills-catalog.json.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | F000002 flagged INCOMPLETE | Run `/docs check` | `[INCOMPLETE] F000002_system_health — feature has 0 user-story children` | Pass |
| 2 | F000001 passes structural check | Run `/docs check` | `[PASS] F000001_personal_workflow — 1 user-story child` | Pass |
| 3 | Tree report renders | Run `/docs check` | Tree shows all nodes with 4 badges per line | Pass |
| 4 | Graph artifact emitted | Run `/docs check` | `.docs/work-item-graph.json` exists with valid schema | Pass |
| 5 | /docs check without claims.json | Delete `.docs/claims.json`, run `/docs check` | Staleness skipped, work item checks run | Pass |
| 6 | /docs tree renders | Run `/docs tree` | Tree with structural badges, others show "-" | Pass |
| 7 | Hierarchy field required | Remove `hierarchy` from manifest, run `/docs check` | Warning about missing hierarchy, structural checks skipped | Pass |
| 8 | Existing checks unchanged | Run `/docs check` on clean repo | Checks 1-3 produce same output as before | Pass |
| 9 | validate.sh passes | Run `./scripts/validate.sh` | Exit 0 | Pass |
| 10 | test.sh passes | Run `./scripts/test.sh` | RESULT: PASS, 0 failures | Pass |

## Verification Steps

- [x] `/docs check` on repo with F000001 (complete) + F000002 (incomplete)
- [x] `/docs tree` standalone
- [x] `/docs check` without `.docs/claims.json`
- [x] `./scripts/validate.sh` passes
- [x] `./scripts/test.sh` passes
- [x] Graph JSON validates against expected schema

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin) | main branch | Pass |
