---
skill-name: "CJ_qa-work-item"
version: 1.0.0
status: experimental
created: "2026-06-01"
last-updated: "2026-06-06T03:46:08Z"
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
transitions Phase 2 QA-owned gates, halts on red. On every GREEN path it then
runs the Step 8.6 audit block: refresh the two custom spec overlays
(`spec/test-spec-custom.md` units, `spec/doc-spec-custom.md` rows) FIRST, then
run `/CJ_doc_audit` + `/CJ_test_audit` inline. Audit findings ride the green
RESULT's `AUDITS=` field + a fenced `AUDIT_FINDINGS` block — they never flip QA
red; the calling cj_goal orchestrator's post-QA checkpoint AUQ owns the
Continue/Halt decision. Output is structured (gate transitions + journal
entries + the extended RESULT); orchestrators read the result and either
advance, prompt the checkpoint, or halt the pipeline.

## Common pitfalls

- Calling it on an incomplete Phase 2 and being confused by the refuse — fix the
  upstream Implement gates first
- Forgetting that E2E subagents are depth-2 — calling this skill from inside
  another subagent hits the depth-≤2 ceiling and halts
- Treating QA findings as failures — red is the contract; the journal entry is the
  artifact the operator reviews
- Expecting audit findings (Step 8.6) to make QA red — they ride the GREEN
  RESULT by design; a red RESULT would halt at the qa gate and the operator
  would never see the findings checkpoint
- Adding a new `tests/*.test.sh` in the work-item without letting 8.6a add its
  `units:` row — the test audit (and validate.sh Check 24) flags it

## Related skills

- `/CJ_implement-from-spec` — upstream phase: produces the code this skill tests
- `/CJ_doc_audit` + `/CJ_test_audit` — the audit verbs Step 8.6c/d execute
  inline; standalone they answer the same questions in any repo
- `/CJ_personal-workflow` — runs at boundaries to confirm Phase 2 completeness
- `/CJ_goal_feature` + `/CJ_goal_defect` + `/CJ_goal_task` + `/CJ_goal_todo_fix`
  — top-level orchestrators that call QA as the final pre-ship leaf subagent and
  surface the post-QA audit checkpoint
