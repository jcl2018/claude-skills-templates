---
type: milestones
template-version: 1
parent: F000006_relocate_deprecated_skills
updated: 2026-05-02
---

## Milestones
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Feature scaffolded (F000006 + S000013 + T000014 docs) | 2026-05-02 | Done | chjiang | Track-phase artifacts created; `/personal-workflow check` clean | — |
| 2 | Working branch created (`feat/relocate-deprecated-skills`) | 2026-05-02 | Done | chjiang | Branch off main; populate `branch` field in trackers | #1 |
| 3 | S000013 implementation: file moves + catalog updates + skills-deploy / validate.sh / test.sh refactor + CLAUDE.md + deprecated/README.md + README regen | 2026-05-02 | Done | chjiang | Q1 + Q2 resolved during implementation: templates_source catalog field added; source-root derived from dirname(files[0]). Catalog-driven helpers added to all 3 scripts. | #2 |
| 4 | T000014 verification: clean-target install with and without `--include-deprecated`; mirror invariant byte-check; doctor INFO at new path | 2026-05-02 | Done | chjiang | All 6 regression cases PASS (see T000014_test-plan.md) | #3 |
| 5 | `/personal-workflow check` + `./scripts/validate.sh` + `./scripts/test.sh` clean on feature branch | 2026-05-02 | Done | chjiang | validate.sh PASS (0 errors / 0 warnings; Error check 10 byte-identical for all 7 mirror entries); test.sh PASS (Failures: 0) | #4 |
| 6 | PR shipped via `/ship`; merged + deployed via `/land-and-deploy` | 2026-05-06 | Not Started | chjiang | Squash-merge per repo CI/CD convention; remote branch deletion via `gh api -X DELETE` if worktree-blocked | #5 |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 scaffold --> #2 branch --> #3 implement S000013 --> #4 verify T000014 --> #5 validate clean --> #6 ship
```
