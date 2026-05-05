---
type: milestones
template-version: 1
parent: F000004_work_copilot
updated: 2026-04-26
---

## Milestones
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Design approved (office-hours + PRDs for 3 stories) | 2026-04-25 | Done | chjiang | v1 design approved; child PRDs in S000007/S000008/S000009. Reconciled 2026-04-26 — was stale "Not Started" before v0.14.0 ship | — |
| 2 | Prompt packaging shipped (S000007) | 2026-05-02 | Done | chjiang | `validate.prompt.md` mirrors `/company-workflow check`; reads templates + manifest. Shipped v0.14.0 (PR #43). Reconciled 2026-04-26 | #1 |
| 3 | Template delivery + install (S000008) | 2026-05-06 | Done | chjiang | Templates land in target repo's `.github/`; installer works cross-platform (Python 3 stdlib). Shipped v0.14.0 (PR #43). Reconciled 2026-04-26 | #1 |
| 4 | Always-on instructions (S000009) | 2026-05-06 | Done | chjiang | `copilot-instructions.md` shipped v0.14.0 (PR #43). Live Windows-box E2E AC tracked separately under S000009 — does not block this milestone. Reconciled 2026-04-26 | #1 |
| 5 | End-to-end verification on work machine | 2026-05-08 | Done | chjiang | Cross-platform install + smoke tests verified in CI on macOS + Linux. Live Windows-box Copilot-chat verification continues under S000009 in parallel. Reconciled 2026-04-26 | #2, #3, #4 |
| 6 | Feature shipped (`/ship` + `/land-and-deploy`) | 2026-05-10 | Done | chjiang | Merged to main and tagged v0.14.0 via PR #43 on 2026-04-23. Reconciled 2026-04-26 | #5 |
| 7 | Symlink setup docs in the bundle | 2026-05-12 | Not Started | chjiang | Add a "Setting up on a new machine" section to `work-copilot/instructions/copilot-instructions.md` (or a sibling `SETUP.md`) documenting the symlink approach: clone `claude-skills-templates` once, then `ln -s` the three artifacts into each target repo's `.github/`. Single source of truth, update-once-apply-everywhere. Optional stretch: add `--symlink` mode to `scripts/copilot-deploy.py` that writes symlinks instead of copies (~30 LOC). | #6 |
| 8 | Document (or unify) the Claude+Copilot install story | 2026-05-14 | Not Started | chjiang | Confirm and document that `skills-deploy` (Claude → `~/.claude/`) and `scripts/copilot-deploy.py` (Copilot → `<target>/.github/`) write to disjoint paths and can coexist in the same repo without conflict. Decide whether to leave them as two separate tools (clearer blast radius) or unify behind a single `deploy.py --target claude\|copilot\|both` entry point (one command, two modes). Ship: a short section in README or CLAUDE.md naming the guarantee, plus the decision. | #6 |
| 9 | Bundle artifact completeness shipped (S000010) | 2026-05-13 | Not Started | chjiang | Mirror `WORKFLOW.md` + `reference/` + `philosophy/` + `examples/` from `skills/company-workflow/` into `work-copilot/`; complete the 5-file fixtures gap. v2 realignment per design doc 2026-04-26 | #6 |
| 10 | Sync-check extension shipped (T000011) | 2026-05-13 | Not Started | chjiang | Extend `scripts/validate.sh` Error check 10 to a config-driven `MIRROR_SPECS` array enforcing byte-identity sync on every mirror entry. Adds 9 negative-path synthetic test cases plus 1 happy-path case in `scripts/test.sh` | #6 |
| 11 | Realignment v0.15.0 release | 2026-05-15 | Not Started | chjiang | `/ship` + `/land-and-deploy` for the v2 realignment. Tag v0.15.0, update catalog | #9, #10 |

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
      +--> #3 template delivery (S000008) ---+--> #5 work-machine verify --> #6 ship v0.14.0 --+--> #7 symlink setup docs
      |                                      |                                                 |
      +--> #4 always-on instructions (S000009)                                                  +--> #8 two-install story / unification
                                                                                                |
                                                                                                +--> #9 bundle artifact completeness (S000010) --+
                                                                                                |                                                |
                                                                                                +--> #10 sync-check extension (T000011) --------+--> #11 realignment v0.15.0 release
```
