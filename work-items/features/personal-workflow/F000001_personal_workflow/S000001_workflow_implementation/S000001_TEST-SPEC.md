---
type: test-spec
parent: S000001_workflow_implementation
feature: F000001_personal_workflow
title: "Workflow Alpha Implementation — Test Specification"
version: 4
status: Done
date: 2026-04-11
updated: 2026-05-05
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Migrated from Test Matrix + Test Tiers shape to Smoke + E2E shape on 2026-05-05.
     PRD has P0 stories 1-7. AC values updated to map every P0 story to at least
     one Smoke or E2E row. Original AC-9..AC-23 references (which used per-AC
     numbering rather than per-story) consolidated and replaced. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-6 | Templates are solo-dev clean + machine-readable graph emitted | No multi-person fields (reviewer noted, Linux branch, JIRA, workflow_type); tracker-review.md does not exist; `.docs/work-item-graph.json` produced after `/docs check` | `! grep -E 'reviewer noted\|Linux branch\|JIRA\|workflow_type' templates/personal-workflow/*.md && [ ! -f templates/personal-workflow/tracker-review.md ] && [ -f .docs/work-item-graph.json ]` |
| S2 | core | AC-2, AC-3 | Per-type artifacts mapping + structured IDs | personal-artifact-manifests.json declares 4 types with required artifacts; F/S/D/T 6-digit ID prefix in all templates | `jq '.types \| keys' skills/personal-workflow/personal-artifact-manifests.json` and grep `{TYPE_ID}` placeholders |
| S3 | core | AC-5, AC-7 | Tree-at-a-glance + configurable hierarchy from manifest | `/docs tree` subcommand spec present in SKILL.md; structural hierarchy rules read from `personal-artifact-manifests.json` (configurable); tree.md exists | `[ -f skills/personal-workflow/tree.md ] && grep -q 'tree' skills/personal-workflow/SKILL.md && jq '.types' skills/personal-workflow/personal-artifact-manifests.json` |
| S4 | core | — | Frontmatter parseable across templates and SKILLs | All template/SKILL frontmatter is valid YAML | `./scripts/validate.sh` |
| S5 | core | — | Catalog is valid JSON | `skills-catalog.json` parseable | `jq -e . skills-catalog.json >/dev/null` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-4 | `/docs check` flags structural completeness gaps | Run `/docs check` on a tree where one feature has 0 stories and one story has 0 tasks | The 0-story feature flagged INCOMPLETE; the 0-task story flagged INCOMPLETE | Pass = both INCOMPLETE labels appear; Fail = silent or wrong target |
| E2 | core | AC-5 | `/docs check` tree renders 4 badges with worst-severity fold | Run `/docs check`, inspect tree output | Tree depth-first sorted; each node line shows template/lifecycle/traceability/structure badges; DRIFT + PASS folds to DRIFT; `/docs tree` standalone works | Pass = ordering + badge count + worst-of fold all visible |
| E3 | core | AC-6 | Graph artifact emitted with full schema | After `/docs check`, inspect `.docs/work-item-graph.json` | File created; each node has id, slug, type, state, path, parent, children, badges, completeness | Pass = schema validates; Fail = missing field or malformed JSON |
| E4 | resilience | — | `/docs check` survives missing claims.json | Delete `.docs/claims.json`, run `/docs check` | Steps 1-5 (staleness) skipped with INFO; Steps 6+ run normally; exit 0 | Pass = run completes without error |
| E5 | core | — | Misplaced + lifecycle-inconsistent items detected | Set up: task placed directly under feature (skipping user-story); set tracker "Broken down" check but item has 0 children | `[MISPLACED]` flag for the task; `[LIFECYCLE_INCONSISTENT]` flag for the broken-down-with-no-children case | Pass = both flags appear with correct work item IDs |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Catalog valid-JSON regression beyond S5 | `validate.sh` already exits non-zero on parse failure; S5 just confirms the gate is wired | If `validate.sh` regresses, that's a different failure surface |
| Tree depth-first sort tested implicitly via E2 ordering | E2 asserts ordering as part of badge rendering; not a separate test | If sort breaks, E2 catches it via wrong tree shape |
| Live multi-template comparison across workflows | Out of scope — personal-workflow has its own template set | Cross-workflow diffs handled in deprecated F000003 |
