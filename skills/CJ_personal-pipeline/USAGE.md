---
skill-name: "CJ_personal-pipeline"
version: 1.1.0
status: experimental
created: "2026-06-01"
last-updated: "2026-06-01"
---

# Skill Usage: CJ_personal-pipeline

## When to use

- INTERNAL — called by `/CJ_goal_todo_fix` per-TODO chain to scaffold → implement → QA
- Input is either an /office-hours design doc OR an already-scaffolded work-item dir
- Each phase runs in a fresh-context Agent subagent with file-only handoff between
  phases; inter-step quality gates halt on red

## When NOT to use

- Do **NOT** call directly as an operator — route via the top-level verb
  (`/CJ_goal_feature`, `/CJ_goal_defect`, or `/CJ_goal_todo_fix`)
- You are inside a subagent — depth-≤2 ceiling: this skill spawns subagents, so
  calling it from within another subagent creates a nested wall (see memory:
  `project_cj_goal_run_nested_subagent_wall`)
- You want plan review or ship — the pipeline stops at QA-green; `/ship` is separate
- The work-item is a task-type design-doc with no committed code — known halt
  pattern (memory: `project_cj_personal_pipeline_task_type_qa_halt`)

## Mental model

A 3-step file-handoff chain: scaffold (design doc → work-item dir) → implement
(spec → code) → QA (test rows → green/red). Each step is a fresh-context Agent
subagent. AUQs are pre-collected at the orchestrator layer because subagents
have no AskUserQuestion tool. Idempotent re-entry — already-green phases skip.

## Common pitfalls

- Operators calling it directly — the SKILL.md explicitly says INTERNAL; route
  through a top-level verb instead
- Calling from inside another subagent — nested-subagent wall halts the chain
- Expecting the pipeline to commit + ship — it stops at QA-green; the commit +
  PR happens at `/ship` (separate skill)
- Mismatch between design-doc input and an already-scaffolded dir — the skill
  detects which is which from the input path; pass the right one

## Related skills

- `/CJ_scaffold-work-item` — Phase 1 (design → work-item tree)
- `/CJ_implement-from-spec` — Phase 2 (spec → code)
- `/CJ_qa-work-item` — Phase 3 (test rows → gates)
- `/CJ_goal_todo_fix` — primary caller; chains this pipeline per drained TODO
- `/CJ_personal-workflow` — runs at phase boundaries to enforce structure
