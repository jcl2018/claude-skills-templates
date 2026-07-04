---
skill-name: "CJ_qa-work-item"
version: 1.0.0
status: experimental
created: "2026-06-01"
last-updated: "2026-07-03T20:06:32Z"
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
runs the Step 8.6 audit block, which has two halves with different deferral
behavior:

- **8.6a/8.6b — overlay WRITES (always inline):** refresh the two custom spec
  overlays (`spec/test-spec-custom.md` units, `spec/doc-spec-custom.md` rows).
  These run on every green path regardless of any defer directive — they must
  land pre-sync so the orchestrator's commit + doc-sync fold them into the PR.
- **8.6c/8.6d — three-stage AUDITS (skippable inline):** Step 8.6.0 checks the
  dispatch prompt for the literal `DEFER_AUDIT: true` directive (the
  orchestrator-to-QA defer signal — a greppable string, NOT an argv flag, since
  QA is dispatched as a subagent prompt). Standalone (no directive): run
  `/CJ_doc_audit` + `/CJ_test_audit` inline and emit the `AUDIT_FINDINGS` block,
  exactly as before — standalone QA is the last doc-mutating point, so the
  inline audit stays. Orchestrator-driven (`DEFER_AUDIT: true`): SKIP 8.6c/8.6d,
  report `AUDITS=deferred`, emit no `AUDIT_FINDINGS` — the orchestrator does NOT
  re-run the audit on the build path; the agent-judged doc/test audit now runs
  ON-DEMAND (locally via `/CJ_doc_audit` + `/CJ_test_audit`, or `bash
  scripts/audit-nightly.sh`), off the build path.

Audit findings ride the green RESULT's `AUDITS=` field + (when not skipped) a
fenced `AUDIT_FINDINGS` block — they never flip QA red. Standalone, the operator
reads the `AUDIT_FINDINGS` block directly; under `DEFER_AUDIT: true` the
orchestrator advances past QA and the on-demand audit surfaces any findings.
Output is structured (gate transitions + journal entries + the extended RESULT);
orchestrators read the result and either advance or halt the pipeline.

## Common pitfalls

- Calling it on an incomplete Phase 2 and being confused by the refuse — fix the
  upstream Implement gates first
- Forgetting that E2E subagents are depth-2 — calling this skill from inside
  another subagent hits the depth-≤2 ceiling and halts
- Treating QA findings as failures — red is the contract; the journal entry is the
  artifact the operator reviews
- Expecting audit findings (Step 8.6) to make QA red — they ride the GREEN
  RESULT by design; a red RESULT would halt at the qa gate and the operator
  would never see the `AUDIT_FINDINGS` block
- Adding a new `tests/*.test.sh` in the work-item without letting 8.6a add its
  `units:` row — the test audit (and validate.sh Check 24) flags it

## Related skills

- `/CJ_implement-from-spec` — upstream phase: produces the code this skill tests
- `/CJ_doc_audit` + `/CJ_test_audit` — the audit verbs Step 8.6c/d execute
  inline; standalone they answer the same questions in any repo
- `/CJ_personal-workflow` — runs at boundaries to confirm Phase 2 completeness
- `/CJ_goal_feature` + `/CJ_goal_defect` + `/CJ_goal_task` + `/CJ_goal_todo_fix`
  — top-level orchestrators that call QA as the final pre-ship leaf subagent with
  `DEFER_AUDIT: true` (the inline audit is skipped; it runs on-demand off the build path)
