---
type: design
parent: S000038
title: "Rename + Branch(g) — Story Design"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
reviewers: []
---

## Problem

`/CJ_ship-feature` is misnamed (sounds feature-specific, not like a pipeline
entry point). `/CJ_personal-pipeline` is a second public entry point that
overlaps with `/CJ_ship-feature` and creates routing confusion. Users want to
invoke a single command and resume from the current state — not start fresh.

This story addresses the rename (cosmetic) and adds the no-arg branch-scan
mode (functional). The work-item-dir input mode is S000039's concern.

## Shape of the solution

Atomic story: mechanical rename + one new code path in `run.md` Step 1.

- `git mv skills/CJ_ship-feature skills/CJ_run`
- Update SKILL.md frontmatter, rename `ship-feature.md` → `run.md`
- Update catalog + routing rules + CJ_personal-pipeline SKILL.md description
- Add Branch(g) logic at Step 1 of `run.md`: scans `work-items/` for in-progress
  user-story TRACKERs on the current branch; if 1 found, dispatch to work-item-dir
  mode (S000039 provides the dispatch); if multiple, AUQ to pick; if none, print
  guidance and exit.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Bundle rename + Branch(g) in one story | Both touch the same file (`run.md`); split would cause merge conflicts |
| 2 | bash 3.2 compatibility (`while IFS= read -r`, not `mapfile -t`) | macOS ships with bash 3.2; skill scripts run there |
| 3 | Branch(g) v0.2 limited to user-story TRACKERs | Gate strings (`Todos section reflects remaining work`) are user-story-specific; defect/task add complexity for low value in v0.2 |
| 4 | No backward-compat shim for `/CJ_ship-feature` | Shims recreate the naming confusion this story fixes |
| 5 | Fresh `CJ_run.jsonl` telemetry log; sunset counter resets | Clean break; old log kept as historical reference |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `git mv` rename might confuse `skills-deploy install` if it caches paths | Run `skills-deploy doctor` after rename; fix any cache drift |
| Branch(g) on a branch with multiple in-progress user-stories needs disambiguation AUQ | Implementation reads candidate count; if >1, AUQ before dispatching |
| Telemetry log rename loses pre-rename sunset history | Acceptable; clean break is the explicit decision |

## Definition of done

- [ ] Rename complete; `validate.sh` passes
- [ ] `/CJ_run` (no args) on a branch with 1 in-progress user-story → resumes correctly
- [ ] `/CJ_run` (no args) with no `work-items/` → graceful exit message
- [ ] Routing rules cleaned (no `/CJ_ship-feature` or `/CJ_personal-pipeline` entries)
- [ ] Tests for Branch(g) (smoke + E2E) pass

## Not in scope

- Branch(f) work-item-dir input mode — S000039
- Multi-story auto-iterate behavior — already delivered by F000016/S000037
- Defect/task TRACKER support in Branch(g) — v0.3
- `--all` flag for iterating multiple in-progress items — v0.3

## Pointers

- Parent tracker: [S000038_TRACKER.md](S000038_TRACKER.md)
- Parent feature: [../F000017_DESIGN.md](../F000017_DESIGN.md)
- SPEC: [S000038_SPEC.md](S000038_SPEC.md)
- TEST-SPEC: [S000038_TEST-SPEC.md](S000038_TEST-SPEC.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-awesome-pasteur-36565c-design-20260513-154622.md`
