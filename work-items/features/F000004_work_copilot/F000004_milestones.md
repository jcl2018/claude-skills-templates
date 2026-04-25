---
type: milestones
template-version: 1
parent: F000004_work_copilot
updated: 2026-04-23
---

## Milestones
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Design approved (office-hours + PRDs for 3 stories) | 2026-04-25 | Not Started | chjiang | Decide the exact Copilot surfaces, installer shape, and template delivery path | — |
| 2 | Prompt packaging shipped (S000007) | 2026-05-02 | Not Started | chjiang | `.prompt.md` that mirrors `/company-workflow check`; reads templates + manifest | #1 |
| 3 | Template delivery + install (S000008) | 2026-05-06 | Not Started | chjiang | Templates land in target repo's `.github/prompts/`; installer works on Windows | #1 |
| 4 | Always-on instructions (S000009) | 2026-05-06 | Not Started | chjiang | `copilot-instructions.md` with work-item conventions (hierarchy, naming, lifecycle) | #1 |
| 5 | End-to-end verification on work machine | 2026-05-08 | Not Started | chjiang | Install on the Windows work box, scaffold + validate a real work item via Copilot chat | #2, #3, #4 |
| 6 | Feature shipped (`/ship` + `/land-and-deploy`) | 2026-05-10 | Not Started | chjiang | Merge to main, tag, update catalog | #5 |
| 7 | Symlink setup docs in the bundle | 2026-05-12 | Not Started | chjiang | Add a "Setting up on a new machine" section to `work-copilot/instructions/copilot-instructions.md` (or a sibling `SETUP.md`) documenting the symlink approach: clone `claude-skills-templates` once, then `ln -s` the three artifacts into each target repo's `.github/`. Single source of truth, update-once-apply-everywhere. Optional stretch: add `--symlink` mode to `scripts/copilot-deploy.py` that writes symlinks instead of copies (~30 LOC). | #6 |
| 8 | Document (or unify) the Claude+Copilot install story | 2026-05-14 | Not Started | chjiang | Confirm and document that `skills-deploy` (Claude → `~/.claude/`) and `scripts/copilot-deploy.py` (Copilot → `<target>/.github/`) write to disjoint paths and can coexist in the same repo without conflict. Decide whether to leave them as two separate tools (clearer blast radius) or unify behind a single `deploy.py --target claude\|copilot\|both` entry point (one command, two modes). Ship: a short section in README or CLAUDE.md naming the guarantee, plus the decision. | #6 |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 design approved
      |
      +--> #2 prompt packaging (S000007) ---+
      |                                      |
      +--> #3 template delivery (S000008) ---+--> #5 work-machine verify --> #6 ship --+--> #7 symlink setup docs
      |                                      |                                         |
      +--> #4 always-on instructions (S000009)                                          +--> #8 two-install story / unification
```
