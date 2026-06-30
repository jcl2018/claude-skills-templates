---
type: roadmap
parent: F000070
title: "Workflow-coverage axis — eval-backed level:workflow tests + forward/reverse gate — Roadmap"
date: 2026-06-29
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals, decomposition, and
     delivery timeline. -->

## Scope

Give every `CJ_goal_*` workflow a real, gstack-independent `level: workflow`
test (a Claude-driven eval case) plus a forward/reverse gate that makes
"documented-but-untested workflow" structurally impossible. The gate runs in
plain CI (registry-only, no API); the eval runs where `ANTHROPIC_API_KEY` lives
(nightly / local). Closes the empty `level: workflow` slot in the F000066
behaviors axis.

## Non-Goals

- The generated `docs/tests/workflow-coverage.md` view — deferred follow-up (units-family renderer + Check 26 reverse-sweep exemption + per-row doc-spec declaration).
- "Make /CJ_test_audit the per-repo test ENFORCER" — separate large story; this axis is its precondition.
- The full happy-path-to-PR eval E2E per orchestrator (reaching `/ship`) — gated on the gstack-in-CI blocker; upgrades the SAME behavior without re-stating it.
- Editing the four `CJ_goal_*` `pipeline.md`/`SKILL.md` files — NOT touched.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] All 4 `CJ_goal_*` orchestrators have a `level: workflow` behavior (with a `workflow:` field) + a `behavior_coverage:` row pointing at a real eval case (`unit: suite-eval`, `source:` the case prompt, live `anchor`).
- [ ] `feature`/`task`/`defect` each gain ≥1 real eval case (`task` a behavioral `halted_at_too_complex` halt; `feature`/`defect` a `--dry-run` `dry_run_preview`).
- [ ] `test-spec.sh --check-workflow-coverage` exists (forward + reverse), HARD, registry-gated-skip, green from birth; a new `validate.sh` check runs it in plain CI; `/CJ_test_audit` Stage 1 prints it + Stage 2 judges substance.
- [ ] Adding a hypothetical 5th `CJ_goal_*` orchestrator with no workflow behavior → the new check FAILS (negative fixture).
- [ ] Absent `spec/workflow-spec.md` / `spec/test-spec.md` → SKIP cleanly (consumer posture).
- [ ] `scripts/test.sh` green; `validate.sh` 0 errors; `test-spec.sh --validate` + `--check-coverage` clean.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000119](S000119_workflow_coverage_axis/S000119_TRACKER.md) | Eval-backed level:workflow coverage + forward/reverse gate + Stage-2 substance | Open |

## Delivery Timeline

<!-- Forward-looking milestones. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000119 (the single implementation chain: eval cases + 6th-column parser + 2 subcommands + gate + validate wiring + audit surfacing + tests) | — | Not Started | chjiang | Builds ON F000069 (MET) | — |
| 2 | End-to-end pipeline run (`validate.sh` 0 errors, `test.sh` green, negative + consumer fixtures pass) | — | Not Started | chjiang | Eval cases run separately under `eval.sh` (need `ANTHROPIC_API_KEY`) | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-29: Scaffolded from /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000119 (impl chain) --> #2 End-to-end pipeline run (validate/test/fixtures green)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| New `validate.sh` check number (next free after 27) | Resolve at implement time. |
| feature/defect richer-than-dry-run case (e.g. feature isolation gate, defect malformed-arg) | `--dry-run` is the clean gstack-independent default for story 1; a richer pre-gstack halt is a deferred upgrade. |
