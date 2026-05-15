---
name: "/CJ_qa-work-item refuses vacuous-PASS on placeholder-only test plans (Theme C)"
type: task
id: "T000023"
status: active
created: "2026-05-14"
updated: "2026-05-14"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "fix/qa-refuse-vacuous-T000023"
blocked_by: ""
---

<!-- Theme C from the /CJ_goal autoplan dual-voice review (round 2). Not in TODOS.md
     yet — distilled directly from the autoplan finding. Skip-design per
     feedback_skip_design_for_small_todos; the fix is surgical. -->

## Lifecycle

### Phase 1: Track

**Gates:**
- [x] Parent scope read (no parent; /CJ_goal autoplan Theme C source)
- [x] Working branch created (`fix/qa-refuse-vacuous-T000023`)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [x] Modify `skills/CJ_qa-work-item/qa.md` Step 4 "Edge cases" sub-section (lines ~207-211): change the "Test rows empty (only placeholder rows): log INFO: ... treating as vacuous PASS" behavior to HALT with an explicit refuse message
- [x] Add the new HALT class to qa.md's halt taxonomy if one exists, or document inline (documented inline at lines 207-228; refuse-RESULT contract is `SMOKE=red; E2E=red; PHASE2_GATES=partial`)
- [ ] Mark Theme C addressed in the prior /CJ_goal design doc's `Patches Applied Post-Autoplan` (or note in CHANGELOG entry) so future readers know it's no longer a /CJ_goal blocker — deferred to /ship's CHANGELOG entry

## Log

- 2026-05-14: Created. Distilled from /CJ_goal autoplan round 2 Theme C: "placeholder test-plan defeats QA gate." qa.md line 209-211 currently logs `INFO: ... treating as vacuous PASS` when all test-plan rows are placeholders (smoke + E2E both empty after filtering), which writes `[qa-pass]` and trips the green path even though no real tests ran. Fix: HALT instead — populate the test-plan before re-running.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_qa-work-item/qa.md` (modified) — Step 4 Edge cases sub-section (lines ~207-211)

## Insights

**Source: /CJ_goal autoplan round 2 — Theme C (Eng codex C1 + Eng subagent C1, both CRITICAL convergent).**

**Failure mode (verbatim from autoplan):**

> "Phase 3 'Test-plan verified' gate has no plausible owner. tracker-task.md Phase 3 requires `Test-plan verified (all scenarios passing)` BEFORE `/ship`. /CJ_qa-work-item for type=task treats all test-plan rows as smoke-equivalent (no E2E subagent). The auto-generated test-plan row (design line 85: 'manual verification per TODO body') is intentionally bogus — it will always pass the smoke check trivially, defeating the gate."

**Concrete mechanism (from qa.md inspection):**

`skills/CJ_qa-work-item/qa.md` Step 4 "Edge cases (all types)" sub-section at lines 207-217 documents:

```
- Test rows empty (only placeholder rows): log INFO: `{test_rows_source} has no
  populated test rows; treating as vacuous PASS.` Skip to Step 9 (gate
  transition / [qa-pass]).
```

For type=defect/task: the placeholder filter at line 190-192 ("A row is a placeholder if its `#` column is literally `1` AND its `Steps` column is `{steps}`") matches the template default (`tracker-task.md` test-plan template starts with `| 1 | {original bug scenario} | {steps} | {fixed behavior} | Pass/Fail/Pending |`). Any scaffolded work-item that leaves the template's placeholder row UNCHANGED triggers the vacuous-PASS path, writes `[qa-pass]`, and the pipeline reaches `end_state=green` with zero real tests run.

This is the gap /CJ_goal's autoplan flagged: under `/loop /CJ_goal`, an auto-scaffolded task with an unpopulated test-plan would silently pass QA. Same risk for any human-scaffolded work-item that forgets to populate test cases.

**Implementation detail:**

Change the "vacuous PASS" edge case to a HALT. Specifically, replace lines 209-211 with a HALT instruction that:
1. Refuses to write `[qa-pass]`
2. Writes a `[qa-refused]` journal entry explaining why
3. Returns `RESULT: SMOKE=red; E2E=red; PHASE2_GATES=partial` (or equivalent halt-RESULT)
4. Surfaces a clear "populate the test-plan, then re-run" message

Keep the existing edge cases for "smoke empty, E2E populated" (user-story path) and "smoke populated, E2E empty" (defect/task happy path) untouched — those are valid populated states.

**Substrate validation hook:** This T000023 ships through `/CJ_personal-pipeline --work-item-dir` like T000022 did. The first run validates that v3.4.1 + v3.4.2 substrate continues to work for back-to-back task-type work-items.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal autoplan round 2 Theme C — distilled into a T-task per skip-design-for-small-todos -->

- 2026-05-14: [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/tasks/skills/T000023_qa_refuse_vacuous_placeholder_passes; scaffold skipped.
- 2026-05-14: [implement] Edited skills/CJ_qa-work-item/qa.md Step 4 Edge cases sub-section (lines 207-228): replaced "vacuous PASS" bullet with HALT + refuse-RESULT contract; also reconciled linked stale journal template at Step 9 (line 684-687) to point at the new HALT path. FILES_CHANGED=1.
- 2026-05-14: [qa-smoke-summary] green — T000023_test-plan.md 6/6 rows passing (grep-based smoke; type=task → no E2E dispatch per qa.md line 179). Verification: `./scripts/validate.sh` PASS (0 errors, 0 warnings).
- 2026-05-14: [qa-pass] T000023 (task): green smoke from test-plan rows (6 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-05-14: [auto-pipeline-clean] run_id=20260514-212941-19050 — auto pipeline reached green with zero Taste / User-Challenge-Approved decisions (suppression contract active via --suppress-final-gate).
