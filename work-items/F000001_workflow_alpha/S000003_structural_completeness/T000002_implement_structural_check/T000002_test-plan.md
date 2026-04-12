---
type: test-plan
parent: T000002_implement_structural_check
title: "Implement structural completeness check — Test Plan"
date: 2026-04-11
author: chjiang
status: Draft
---

## Scope

Implements Steps 15-17 in check.md, separates the claims.json gate, adds badge taxonomy mapping, lifecycle cross-reference, `/docs tree` subcommand, and hierarchy field in artifact-manifests.json.

Files modified: artifact-manifests.json, skills/docs/check.md, skills/docs/tree.md (new), skills/docs/SKILL.md, skills-catalog.json.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | F000002 flagged INCOMPLETE | Run `/docs check` | `[INCOMPLETE] F000002_system_health_v1 — feature has 0 user-story children` | Pending |
| 2 | F000001 passes structural check | Run `/docs check` | `[PASS] F000001_workflow_alpha — 3 user-story children` | Pending |
| 3 | S000002 flagged INCOMPLETE | Run `/docs check` | `[INCOMPLETE] S000002_template_consolidation — user-story has 0 task children` | Pending |
| 4 | Tree report renders | Run `/docs check` | Tree shows all nodes with 4 badges per line | Pending |
| 5 | Graph artifact emitted | Run `/docs check` | `.docs/work-item-graph.json` exists with valid schema | Pending |
| 6 | /docs check without claims.json | Delete `.docs/claims.json`, run `/docs check` | Staleness skipped, work item checks run | Pending |
| 7 | /docs tree renders | Run `/docs tree` | Tree with structural badges, others show "—" | Pending |
| 8 | Hierarchy field required | Remove `hierarchy` from manifest, run `/docs check` | Warning about missing hierarchy, structural checks skipped | Pending |
| 9 | Existing checks unchanged | Run `/docs check` on clean repo | Checks 1-3 produce same output as before | Pending |
| 10 | validate.sh passes | Run `./scripts/validate.sh` | Exit 0 | Pending |

## Verification Steps

- [ ] `/docs check` on repo with F000001 (complete) + F000002 (incomplete)
- [ ] `/docs tree` standalone
- [ ] `/docs check` without `.docs/claims.json`
- [ ] `./scripts/validate.sh` passes
- [ ] `./scripts/test.sh` passes
- [ ] Graph JSON validates against expected schema

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin) | main branch | Pending |
