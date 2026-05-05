---
type: milestones
template-version: 1
parent: F000005_deprecated_skill_status
updated: 2026-05-02
---

## Milestones
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Feature scaffolded (F000005 + S000012 + T000013 docs) | 2026-05-02 | Done | chjiang | Track-phase artifacts created on `feat/deprecated-skill-status`; `/personal-workflow check` clean | — |
| 2 | S000012 implementation: catalog schema, install filter, `--include-deprecated`, doctor INFO, README rendering | 2026-05-02 | Done | chjiang | Edits to skills-deploy (install + doctor), validate.sh (Error check 9b), generate-readme.sh, CLAUDE.md | #1 |
| 3 | T000013 migration: flip `company-workflow` to `deprecated`; verify install skips it on clean target | 2026-05-02 | Done | chjiang | Catalog flipped, README regenerated, all 10 regression cases Pass | #2 |
| 4 | `/personal-workflow check` + `./scripts/test.sh` clean on feature branch | 2026-05-02 | Done | chjiang | validate.sh PASS (0 errors / 0 warnings); test.sh PASS (Failures: 0); work-copilot mirror intact | #3 |
| 5 | PR shipped via `/ship`; merged + deployed via `/land-and-deploy` | 2026-05-05 | Not Started | chjiang | Squash-merge per repo CI/CD convention; remote branch deletion via `gh api -X DELETE` if worktree-blocked | #4 |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 scaffold --> #2 implement S000012 --> #3 migrate company-workflow (T000013) --> #4 validate clean --> #5 ship
```
