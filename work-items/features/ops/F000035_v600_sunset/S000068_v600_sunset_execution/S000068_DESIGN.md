---
type: design
parent: F000035
title: "v6.0.0 sunset execution (atomic full-nuke commit) — Feature Design"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
reviewers: []
---

<!-- Atomic-story design stub. The parent F000035 DESIGN.md owns the
     cross-story design rationale; this stub names the execution shape
     of the single user-story. -->

## Problem

S000068 executes the F000035 v6.0.0 sunset as one atomic-commit user-story. The closed-enum change in `scripts/validate.sh` Check 9b must be staged together with the catalog filter that removes the 5 deprecated entries — splitting across commits or stories risks a transient validate.sh red state in the staged tree (pre-commit hook would block). One story, one commit, all 15 surgical edits plus the ordering constraint (Step 16 of the parent design).

See parent [F000035_DESIGN.md](../F000035_DESIGN.md) for the cross-story rationale and Approach B selection.

## Shape of the solution

15 distinct edit surfaces, executed in any order during Phase 2 (each is independent on disk), staged as one commit at the end. Pre-commit validate.sh runs against the fully-staged tree; either green or surgical fix-and-restage.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Delete 5 deprecated skill dirs + `deprecated/` tree | S000068 (this) | [S000068_SPEC.md](S000068_SPEC.md) |
| Filter catalog + close enum + remove flag + simplify generator | S000068 (this) | [S000068_SPEC.md](S000068_SPEC.md) |
| CLAUDE.md + PHILOSOPHY.md + ARCHITECTURE.md + skill-routing.md surgeries | S000068 (this) | [S000068_SPEC.md](S000068_SPEC.md) |
| Tests delete + inspect-update + TODOS + memory + VERSION + CHANGELOG + README regen | S000068 (this) | [S000068_SPEC.md](S000068_SPEC.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Atomic single-commit execution | Check 9b enum change must stage with catalog filter — splitting risks transient red. |
| 2 | No automatic merge; PR-stop | Skill-surface change hits cj-handoff-gate denylist per memory `project_workbench_auto_deploy_unsafe`. |
| 3 | Validate.sh Check 13/14/15 predicates stay `status != "deprecated"` | Forward-compat with future re-introduction; filters nothing today. |
| 4 | `scripts/generate-readme.sh` simplified, not just gated | With zero deprecated entries, the `if DEPRECATED_COUNT > 0` block has nothing to write. Simpler script = cleaner end-state. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Pre-commit validate.sh red on partial stage | Stage once via `git add -A` after all edits land; never commit a partial. |
| `tests/cj-worktree-init.test.sh` investigate references — surgical vs no-op | Phase 2: grep + inspect; surgical update preserves feature/defect/todo cases. |
| `tests/eval/` parent dir cleanup | Phase 2: after deleting `tests/eval/CJ_goal_run/`, `ls tests/eval/` — delete parent only if empty. |
| Memory file deletion ordering | Phase 2 last step: delete `project_investigate_retire_candidate.md` + update `MEMORY.md` index line in one stage. |

## Definition of done

- [ ] All 12 Success Criteria from parent F000035 ROADMAP pass.
- [ ] Single sunset commit on top of `chore: WIP hygiene` — two and only two commits ahead of origin/main.
- [ ] `/CJ_personal-workflow check work-items/features/ops/F000035_v600_sunset/` passes.

## Not in scope

- work-copilot/ bundle — out of workbench scope.
- Re-design of a future deprecation pattern — deferred to a hypothetical future retirement.
- `tests/eval/` parent dir restructuring beyond the CJ_goal_run subdir removal.

## Pointers

- Parent tracker: [F000035_TRACKER.md](../F000035_TRACKER.md)
- Parent design: [F000035_DESIGN.md](../F000035_DESIGN.md)
- Parent roadmap: [F000035_ROADMAP.md](../F000035_ROADMAP.md)
- Source design (/office-hours): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260602-010655-sunset-design-20260602-010702.md`
