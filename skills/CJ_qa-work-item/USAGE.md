---
skill-name: "CJ_qa-work-item"
version: 1.0.0
status: experimental
created: "2026-06-01"
last-updated: "2026-06-01"
---

# Skill Usage: CJ_qa-work-item

## When to use

- "QA this work-item", "run tests on the work-item", "verify the work-item"
- A scaffolded + implemented work-item is in Phase 2 and needs its test-plan rows run
- An orchestrator (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`)
  is delegating the QA phase as a leaf subagent
- Re-running is idempotent — already-green rows are skipped

## When NOT to use

- Phase 2 is incomplete (Implement gates unchecked) — this skill refuses; finish
  implementation first
- The work-item is a task-type design-doc with no committed code yet — known halt
  pattern; commit at `/ship` first (see memory:
  `project_cj_personal_pipeline_task_type_qa_halt`)
- You want to write tests, not run them — that's `/CJ_implement-from-spec`
- You want to merge after QA — that's `/ship` + `/land-and-deploy`

## Mental model

Runs each TEST-SPEC row as a smoke test (and, for user-stories, dispatches a
fresh-context E2E subagent per test row). Writes findings to the tracker journal,
transitions Phase 2 QA-owned gates, halts on red. Output is structured (gate
transitions + journal entries); orchestrators read the result and either advance
or halt the pipeline.

## Common pitfalls

- Calling it on an incomplete Phase 2 and being confused by the refuse — fix the
  upstream Implement gates first
- Forgetting that E2E subagents are depth-2 — calling this skill from inside
  another subagent hits the depth-≤2 ceiling and halts
- Treating QA findings as failures — red is the contract; the journal entry is the
  artifact the operator reviews

## Related skills

- `/CJ_implement-from-spec` — upstream phase: produces the code this skill tests
- `/CJ_personal-workflow` — runs at boundaries to confirm Phase 2 completeness
- `/CJ_goal_feature` + `/CJ_goal_defect` + `/CJ_goal_todo_fix` — top-level
  orchestrators that call QA as the final pre-ship leaf subagent
