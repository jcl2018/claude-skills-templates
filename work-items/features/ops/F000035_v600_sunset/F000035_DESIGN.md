---
type: design
parent: F000035
title: "v6.0.0 sunset — full nuke of deprecated shims + deprecation infrastructure — Feature Design"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The workbench has accumulated 5 deprecated alias shims (`/CJ_goal_run`, `/CJ_goal_auto`, `/CJ_goal_investigate`, `/cj_goal_feature`, `/cj_goal_defect`) and a layered deprecation-infrastructure surface that supports them: the `status: deprecated` enum value in `skills-catalog.json` (closed enum enforced by `validate.sh` Check 9b), the `deprecated/{name}/` directory convention (F000031), the `--include-deprecated` flag on `scripts/skills-deploy`, the F000030 retired-skill drift audit in CLAUDE.md, and tombstone sections across `doc/PHILOSOPHY.md` (`## Retired skills`), `doc/ARCHITECTURE.md` (`## Deprecation tombstones`), and `rules/skill-routing.md` (`## Deprecated front doors`). All of it was justified for backward-compat with operators running in-flight pipelines on the deprecated entry points — a real concern in a multi-operator world.

This is a solo project. There are no other operators. There are no in-flight pipelines stuck on the lowercase `/cj_goal_feature` or on `/CJ_goal_investigate`. The 5 shims are dead weight; the infrastructure supporting them is dead weight; the audit checks and convention sections that exist solely to enforce graceful deprecation are dead weight. CLAUDE.md's planned-but-deferred "v6.0.0 sunset wave" can execute now — and Approach B (chosen via /office-hours AUQ) takes it further than the documented v6.0.0 plan: it also retires the deprecation INFRASTRUCTURE. Future deprecations re-introduce the pattern when needed, designed around whatever the next retirement actually requires.

## Shape of the solution

A single atomic-commit user-story executes all 16 steps from the Recommended Approach in one squash-merge PR. The pre-commit hook runs `validate.sh`; with the closed-enum change and catalog filter staged together, validate runs clean. The two-commit feature branch (already-staged `chore: WIP hygiene` + the v6.0.0 sunset itself) collapses to one commit on origin/main via squash.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Execute the full v6.0.0 sunset (skill dirs, catalog, validate.sh enum, skills-deploy flag, generate-readme.sh, CLAUDE.md, PHILOSOPHY.md, ARCHITECTURE.md, skill-routing.md, tests, TODOS, memory, VERSION, CHANGELOG, README regen) as one atomic commit | S000068 | [S000068_v600_sunset_execution/S000068_TRACKER.md](S000068_v600_sunset_execution/S000068_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach B (full nuke) over A (sunset shims only) | Solo project collapses the deprecation infrastructure's justification to zero. Half-measures leave dead weight on disk. |
| 2 | VERSION 5.0.19 → 6.0.0 (MAJOR) | Documented sunset wave; MAJOR signals the breaking change for muscle-memory invocations. SemVer-honest. |
| 3 | Single atomic commit (no decomposition into multiple stories) | Check 9b closed-enum change must be staged together with the catalog filter so the staged enum matches the staged catalog. Splitting risks a transient validate.sh red state. |
| 4 | Validate.sh Check 13/14/15 predicates intentionally stay `status != "deprecated"` | Robust to future re-introduction of the enum value; filters nothing today. One fewer downstream change at minimal cost. |
| 5 | No tombstone breadcrumb left behind | CHANGELOG entry + git history + the F000027 / F000031 / T000035 / F000035 PR titles form the audit trail. The `## Retired skills` section was the per-deprecation tombstone home; with the deprecation pattern itself retired, the tombstones are retired too. |
| 6 | Workbench-only scope (work-copilot/ untouched) | work-copilot/ is byte-mirrored and ships its own templates; deletions to `skills/` + `deprecated/` don't propagate there. Per memory `feedback_workbench_scope`. |
| 7 | PR-stop, no automatic merge | Per memory `project_workbench_auto_deploy_unsafe`: skill-surface-touching changes hit the cj-handoff-gate denylist. Operator merges manually. |
| 8 | Simplify `scripts/generate-readme.sh` (drop the `DEPRECATED_COUNT > 0` block entirely) | With zero deprecated entries the block has nothing to write. Cleaner script is the cleaner end-state. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Operator muscle memory may still type `/cj_goal_feature` (lowercase) post-sunset and get "skill not found" — by design, but verify the error message is informative. | Post-merge: invoke each retired entry and confirm the error UX is acceptable. The Assignment section of the design doc names this as the post-ship sanity check. |
| `tests/cj-worktree-init.test.sh` may reference `cj-inv-*` worktree prefix or investigate paths; needs surgical update, not delete. | S000068 Phase 2: grep the file; remove the investigate-specific case; keep the feature/defect/todo cases intact. |
| `tests/cj-goal-doc-sync-auq-recommendation.test.sh` may assert deprecated-related behavior. | S000068 Phase 2: grep + inspect; update or no-op as needed. |
| `tests/eval/CJ_goal_run/` deletion: should the empty `tests/eval/` parent also go? | S000068 Phase 2: after deletion, check if `tests/eval/` has other children (per design Open Q #6); delete parent only if empty. |
| `--include-deprecated` flag removal: any cron / scheduled task depending on it? | Per design Open Q #5: solo project, no scheduled tasks reference the flag. Confirm by `grep --include-deprecated ~/.claude/ ~/.gstack/ 2>/dev/null` before commit. |
| Atomic-commit ordering: 16 steps in one commit is large. Risk of intermediate validate.sh red during staging. | Stage everything via `git add -A` once after all edits land; pre-commit runs validate.sh against the fully-staged tree; either green or surgical fix-and-restage. |

## Definition of done

- [ ] All 12 Success Criteria from the design doc pass (catalog count, status enum, deprecated/ gone, shim dirs gone, skills-deploy clean, CLAUDE.md cleaned, PHILOSOPHY/ARCHITECTURE/skill-routing tombstones gone, validate.sh passes, test.sh passes, VERSION=6.0.0, CHANGELOG entry, README has no Deprecated table).
- [ ] Two-and-only-two commits ahead of origin/main on the feature branch (`chore: WIP hygiene` + the v6.0.0 sunset).
- [ ] PR opened with title `v6.0.0 feat: F000035 sunset deprecated shims + deprecation infrastructure (full nuke)`.
- [ ] Post-ship sanity: `/cj_goal_feature` (lowercase) and `/CJ_goal_investigate` both error with "skill not found".

## Not in scope

- work-copilot/ bundle — byte-mirrored; ships its own templates; out of workbench scope per memory `feedback_workbench_scope`.
- Re-design of the deprecation pattern for hypothetical future deprecations — Open Q #2: re-introduce when an actual retirement needs it.
- Eval-hardening (D000023 scope) — `tests/eval/CJ_goal_run/` deletion is incidental cleanup; D000023 itself stays deferred per memory `project_eval_hardening_deferred`.
- Automatic merge / land-and-deploy — PR-stop only; operator merges manually per memory `project_workbench_auto_deploy_unsafe`.
- Backward-compat preservation — Approach B explicitly retires the infrastructure that would have provided it.

## Pointers

- Parent tracker: [F000035_TRACKER.md](F000035_TRACKER.md)
- Roadmap: [F000035_ROADMAP.md](F000035_ROADMAP.md)
- Source design (/office-hours): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260602-010655-sunset-design-20260602-010702.md`
- Predecessor work items: F000027 (two-verb refactor), F000030 (doc/ folder + audit conventions), F000031 (casing-fix + `deprecated/` convention), F000032 / F000033 / F000034 (Check 13/14/15), T000035 (investigate retirement to shim)
