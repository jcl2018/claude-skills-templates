---
type: design
parent: F000039
title: "Flatten /CJ_goal_todo_fix off /CJ_personal-pipeline and retire the skill — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories. -->

## Problem

`/CJ_personal-pipeline` is an `experimental`, internal-only orchestrator: it chains
scaffold→implement→qa as fresh-context subagents and returns a `PIPELINE_END_STATE` +
`SMOKE/E2E/PHASE2_GATES` contract. F000027 already flattened `/CJ_goal_feature` and
`/CJ_goal_defect` off it (they dispatch the leaf subagents directly to avoid the
nested-subagent wall), leaving `/CJ_goal_todo_fix` as its **only** live caller — in
both single-TODO mode (`todo_fix.sh:870` emits `DISPATCH_CHAIN=/CJ_personal-pipeline
--work-item-dir … --suppress-final-gate`) and drain mode (`drain-one-todo.sh`). The
skill's own docs still reference the long-retired `/CJ_goal_run` as its caller. It is a
near-vestigial middle layer: one consumer, a stale contract, and a duplicate of the
dispatch logic feature/defect already inline.

Flattening `/CJ_goal_todo_fix` to dispatch impl→qa directly (the proven feature/defect
pattern) removes the last caller, after which `/CJ_personal-pipeline` can be deleted
outright. The payoff: one fewer indirection layer in the hot path — all three cj_goal
orchestrators then share ONE flatten shape (orchestrator → leaf subagents, depth ≤ 2)
instead of two-flat-plus-one-nested. Less surface, less drift, one mental model.

## Shape of the solution

Approach A (one PR): replace the personal-pipeline dispatch in todo_fix's single-TODO
+ drain paths with the direct impl→qa leaf-subagent pattern, rename the halt taxonomy,
and delete the skill + all catalog/doc/test references in the same PR. The work is one
cohesive change with no parallel sub-units, so it decomposes into a single
implementation user-story.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Flatten todo_fix (both modes) off personal-pipeline, rename halt taxonomy, delete the skill, clean ~18 reference files, reconcile validate.sh Check 12 + test.sh, rewrite depends.skills | S000072 | [S000072_flatten_and_retire_impl/S000072_TRACKER.md](S000072_flatten_and_retire_impl/S000072_TRACKER.md) |

The flattened chain is exactly **`/CJ_implement-from-spec` → `/CJ_qa-work-item`** leaf
Agent subagents — `CJ_goal_feature` Steps 3.2-3.3 (both Agent-tool, silent/no-AUQ),
minus the scaffold step (3.1, which todo_fix already does in pure bash at
`todo_fix.sh:608-693`).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A: flatten both modes + delete personal-pipeline in ONE PR | Directly fulfills "retire"; the flatten pattern is battle-tested by feature/defect; P1 confirms isolation is preserved; the PR is the review gate before merge. B (delete in a follow-up) leaves an orphaned zero-caller experimental skill + a second PR; C (re-consolidate all 3 orchestrators into personal-pipeline) re-introduces the F000027 nested-subagent wall and reverts a deliberate decision. |
| 2 | "Retire" = straight delete, no shim | personal-pipeline is `experimental` and was never a routable front door (`rules/skill-routing.md`: "do not route to them directly"); F000035 already removed the deprecation infrastructure, so there is no alias to preserve and no `deprecated/` machinery to honor. |
| 3 | Drop `--suppress-final-gate` (do not translate) | It is a personal-pipeline-only concept (suppresses that skill's Step 8.5/9.2 AUQs). The impl/qa leaf subagents have no such gate, so the flag is simply dropped. The "AUQs pre-collected at orchestrator" contract dissolves; impl/qa leaf subagents run silent/no-AUQ exactly as in CJ_goal_feature (drain mode is already `--quiet`-friendly → no AUQ regression). |
| 4 | Rename halt taxonomy `halted_at_pipeline_*` → `halted_at_impl`/`halted_at_qa` | todo_fix now parses the impl + qa subagents' RESULT lines instead of personal-pipeline's `PIPELINE_END_STATE`; the end-state strings must name the actual phase that halted. |
| 5 | `/CJ_personal-workflow` (the validator) is untouched | A different skill, still invoked by scaffold/impl/qa at their boundaries. Only `/CJ_personal-pipeline` (the orchestrator) is deleted. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `validate.sh` Check 12 (~lines 514-535) is NOT a structural validator — it's a `grep -qF '[ -x ./scripts/validate.sh ]'` guard-token check on personal-pipeline's `pipeline.md`. Removing the skill means removing the WHOLE Check 12 block, AND reconciling `scripts/test.sh` (~line 1138 parallel guard reference) in the SAME change so test.sh does not go red on the deleted file. **Most likely thing to be forgotten.** | S000072 SPEC AC #6 + TEST-SPEC S3/E2; pre-flight called out explicitly in the impl handoff (known implement-subagent blind spot). |
| `depends.skills` rewrite: after the flatten, drop `CJ_personal-pipeline` and list the real dispatch deps (`CJ_implement-from-spec`, `CJ_qa-work-item`, and `CJ_scaffold-work-item` if the bash scaffold counts). | Resolve during implementation against the real dispatch list; S000072 SPEC AC #3. |
| Per-TODO worktree isolation must be preserved (owned by `drain-one-todo.sh:255` + the todo_fix preamble, not personal-pipeline). | S000072 TEST-SPEC asserts line 255 `--force-create` block is unchanged by any existing regression grep. |
| The `[qa-severity-scale-fictional]` learning references `skills/CJ_personal-pipeline/pipeline.md` and will go stale on delete. | Informational; staleness detection may flag it — acceptable, out of scope. |

## Definition of done

- [ ] `/CJ_goal_todo_fix` single-TODO mode dispatches impl→qa leaf subagents; no `/CJ_personal-pipeline` reference in its SKILL.md / pipeline.md / scripts.
- [ ] Drain mode dispatches impl→qa per drained TODO; `drain-one-todo.sh:255` isolation unchanged.
- [ ] `skills/CJ_personal-pipeline/` deleted; catalog entry removed; `depends.skills` rewritten.
- [ ] All live-surface references cleaned (the ~18-file list in S000072 SPEC).
- [ ] Halt taxonomy renamed.
- [ ] `validate.sh` Check 12 block removed + `test.sh` ~line 1138 reconciled in the same change.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` both green.
- [ ] `grep -rI "CJ_personal-pipeline" skills/ scripts/ doc/ rules/ CLAUDE.md README.md` returns nothing.

## Not in scope

- Whether `/CJ_goal_todo_fix` needs its own downstream-portability guard (the rationale Check 12 protected dies with the skill) — separate out-of-scope follow-up.
- `work-items/` history references to `CJ_personal-pipeline` — retained; only LIVE surfaces (skills/, scripts/, doc/, rules/, CLAUDE.md, README.md) are swept.
- The `[qa-severity-scale-fictional]` learning's stale pointer — informational, not cleaned here.
- Re-consolidating the three orchestrators into a shared engine (Approach C) — explicitly rejected.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000039_TRACKER.md](F000039_TRACKER.md)
- Roadmap: [F000039_ROADMAP.md](F000039_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-132322-16015-design-20260603-133145.md`
- Prior art: F000027 (flattened feature/defect off personal-pipeline — the pattern this extends to todo_fix)
