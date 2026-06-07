---
type: test-spec
parent: S000091
feature: F000051
title: "Shared portability-audit phase + 3-orchestrator gate + PR surfacing — Test Specification"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Smoke = automated regression (CI). E2E = manual user-scenario verification. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Phase on clean catalog returns ok + structured fields | Exit 0 and stdout has `PHASE=portability-audit`, `MODE=feature`, `FINDINGS=0`, `SKILLS_AUDITED=` (n>0), `PHASE_RESULT=ok`, a clean `VERDICT_LINE` | `bash scripts/cj-goal-common.sh --phase portability-audit --mode feature` then grep the fields |
| S2 | resilience | AC-2 | Phase on a dishonest-declaration fixture returns findings | Non-zero exit and `PHASE_RESULT=findings`, `FINDINGS>0` (skills-with-findings) | `bash tests/cj-goal-common-portability.test.sh` (findings-fixture case) |
| S3 | resilience | AC-2 | Phase with engine absent + phase with `--dry-run` both fail soft | Engine-absent → exit 0 + `PHASE_RESULT=skipped`; `--dry-run` → exit 0 + `PHASE_RESULT=ok`, empty `FINDINGS=`, engine NOT run | `bash tests/cj-goal-common-portability.test.sh` (engine-absent + dry-run cases) |
| S4 | integration | AC-6 | Repo validate + full test suite pass | `validate.sh` (incl. Check 15b for the 3 updated `CJ_goal_*` Touches blocks/charts) and `test.sh` (incl. the new phase test) are green | `./scripts/validate.sh && ./scripts/test.sh` |
| S5 | core | AC-3 | Each orchestrator file wires the gate + halt before /ship | Grep confirms a `--phase portability-audit` call + a `[portability-red]` halt token + `halted_at_portability` exist in feature `pipeline.md`, defect `pipeline.md`, todo `SKILL.md`, anchored before the `/ship` invocation | `grep -n 'portability-audit\|portability-red\|halted_at_portability' skills/CJ_goal_feature/pipeline.md skills/CJ_goal_defect/pipeline.md skills/CJ_goal_todo_fix/SKILL.md` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers: post-ship (E2E rows only). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. Each row is one user-visible scenario.
     Post-ship rows (the live-pipeline ratchet proof) are only verifiable after
     the orchestrator edits ship on merged refs / open a real PR. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Clean gate on the live catalog | Run `bash scripts/cj-goal-common.sh --phase portability-audit --mode feature` in the repo | Prints the structured block with `PHASE_RESULT=ok`, `FINDINGS=0`, and a "all N skills honestly declared (0 findings)" `VERDICT_LINE`; exits 0 | All listed fields present + exit 0 |
| E2 | usability | AC-7 | Dry-run preview mentions the gate | Invoke each orchestrator with `--dry-run` | The chain-plan preview contains a line describing the portability-audit gate (halt-on-red, before /ship); the engine is not run | Preview line present in all 3; no engine invocation |
| E3 | core post-ship | AC-3 | Live-pipeline halt on a dishonest declaration (the Assignment) | Run one real `/CJ_goal_feature` whose change touches a skill's declared portability with a deliberately dishonest declaration | The run HALTs at the gate with `[portability-red]` / `halted_at_portability` BEFORE `/ship`; a journal entry carries `next_action` / `resume_cmd`; NO PR is created | Halt occurs pre-ship with the journal contract fields; no PR |
| E4 | observability post-ship | AC-4 | Live-pipeline green verdict in the PR body | Run a clean real `/CJ_goal_feature` through to PR | The PR body shows a `### Portability` verdict line alongside the registered-doc verdicts | `### Portability` line present in the PR body |
| E5 | resilience post-ship | AC-5 | Resume after a red restarts at the gate | After an E3 `[portability-red]` halt, fix the declaration and re-invoke the same verb | The run restarts at the gate (not at `/ship`), re-runs the pure-read phase, and proceeds on green | Resume re-enters at the gate and completes |

<!-- E3/E4/E5 are tagged post-ship: they exercise a full live orchestrator run that
     drives ship/PR creation, only meaningful after this change merges. /CJ_qa-work-item
     Step 4 filters post-ship rows out of the E2E subagent dispatch and records a
     [qa-e2e-deferred] journal entry. The Assignment (E3) is verified after merge. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Full live `/CJ_goal_defect` and `/CJ_goal_todo_fix` end-to-end gate runs | E3/E4 prove the gate on `/CJ_goal_feature`; the other two share the identical shared phase + gate-handler shape, and S5 (grep) confirms all 3 are wired | A defect/todo-specific wiring typo not caught by S5's grep could slip; mitigated by the shared-phase design (one implementation) |
| The engine's own audit correctness (tier ladder, carve-outs) | Owned by `/CJ_portability-audit` + its existing tests; this story consumes the engine unchanged | An engine regression would surface as a wrong verdict, but is out of this story's scope |
| `gh pr edit` failure injection for the surfacing step | The surfacing is best-effort / never-halts by contract; E4 confirms the happy path | A silent surfacing failure leaves the PR without the line but does not break the run (by design) |
