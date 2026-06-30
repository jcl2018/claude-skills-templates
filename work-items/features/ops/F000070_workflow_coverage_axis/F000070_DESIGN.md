---
type: design
parent: F000070
title: "Workflow-coverage axis — eval-backed level:workflow tests + forward/reverse gate — Feature Design"
version: 1
status: Draft
date: 2026-06-29
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. -->

## Problem

F000069 made both catalogs GENERATED + freshness-gated — the workflow docs
(`docs/workflow.md` + `docs/workflows/`, Check 27) and the test catalog
(`docs/test-catalog.md` + `docs/tests/`, Check 26). But **documenting a workflow
is not testing it**: a `CJ_goal_*` orchestrator can be fully described in
`spec/workflow-spec.md` and rendered into `docs/workflows/<name>.md` with ZERO
test proving the workflow actually runs. The `behaviors:` axis already carries
`level: workflow` in its closed enum (F000066), but **0 `level: workflow`
behaviors exist today** — the slot sits empty and nothing forces it filled.

This feature closes the gap with a real, gstack-independent test per orchestrator
plus a structural gate that makes "documented-but-untested workflow" impossible:
add a 5th `CJ_goal_*` orchestrator and CI HARD-fails until it has a
`level: workflow` behavior linked to a real eval case. It closes the TODOS.md
"Workflow-coverage" (P2, L) row and defers "Make /CJ_test_audit the per-repo test
ENFORCER" (P2, L) as a tracked follow-up.

## Shape of the solution

A single implementation chain (this is a single-story feature — the pipeline
builds one chain). Three real eval cases are added (`feature`/`task`/`defect`,
copying the proven `CJ_goal_todo_fix` halt-case shape: JSON-only output,
`--json-schema` enforced), 4 `level: workflow` behaviors + 4 `behavior_coverage:`
rows are declared in `spec/test-spec-custom.md`, the behaviors parser gains a 6th
`workflow` column, two additive subcommands are added
(`workflow-spec.sh --list-orchestrators`, `test-spec.sh
--check-workflow-coverage`), a new HARD registry-gated `validate.sh` check runs
the gate in plain CI (no API), and `/CJ_test_audit` surfaces it (Stage 1 verbatim
+ Stage 2 substance judgment).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Eval cases + behaviors + parser + 2 subcommands + gate + validate wiring + audit surfacing + tests (the whole chain) | S000119 | [S000119_workflow_coverage_axis/S000119_TRACKER.md](S000119_workflow_coverage_axis/S000119_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | The `level: workflow` test is a REAL Claude-driven eval case (the `CJ_goal_todo_fix` pattern), NOT a shell `--dry-run` stub or fresh-install fixture | Two adversarial reviews proved shell/dry-run fixtures hollow; the operator refused the shell fixture twice. An eval case actually loads the skill + runs the preamble/isolation/gate and emits a schema-validated result. |
| 2 | Eval cases target gstack-independent paths (`task` → `halted_at_too_complex`; `feature`/`defect` → `--dry-run` `dry_run_preview`; `todo_fix` → an existing preflight halt) | They must actually RUN without gstack — none reach `/office-hours` or `/ship`, sidestepping the gstack-in-CI blocker while staying real. The full happy-path-to-PR E2E is a deferred upgrade of the SAME behavior. |
| 3 | The forward/reverse GATE runs in plain CI (registry-only, no API); the eval runs where `ANTHROPIC_API_KEY` lives | Honest split: "documented-but-untested impossible" is enforced everywhere regardless of the API key; the eval (works-when-run) runs nightly/local. Strictly more honest than a green shell stub. |
| 4 | Forward-link via an explicit optional `workflow:` field (6th TSV column), not a derived heuristic | Closes OQ1. Requires the `_parse_behaviors_file` flush + the ~line-580 read change with the `-` placeholder unwrap (prior reviewer findings 3/6). |
| 5 | Orchestrator source is the workflow registry via a new `workflow-spec.sh --list-orchestrators` | Closes OQ2. `--list-workflows` includes roster entries (no kind filter); the `skills-catalog.json` jq set is consumer-absent and breaks registry-gating (prior reviewer finding 4). |
| 6 | `behavior_coverage` reuses the existing `suite-eval` `units:` row (anchor `scripts/eval.sh`) — NO new units rows | `family: eval` is already test-bearing (Check 4 accepts `{test, test-deploy, eval, windows-smoke}`); the coverage `source:` is the case `prompt.md` + a literal `anchor` grepped live `-F`. |
| 7 | The generated `docs/tests/workflow-coverage.md` view is DEFERRED to a follow-up | Highest blast radius (units-family renderer + Check 26 reverse-sweep exemption + per-row doc-spec declaration). The cheap Stage-2 substance judgment is kept. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| The 6th-column parser change must touch the behaviors-TSV flush AND the only destructuring consumer (~line 580) with the `-` unwrap; other consumers read `$1` only | Implement-time: extend `_parse_behaviors_file` + `nz()`/flush `printf` + the 5-var `read`; verify positional-safety of duplicate-id (~498), coverage `awk` (~703), `--list-behaviors`/anchor (~737/1555). |
| The new `validate.sh` check needs a parallel `zzz-test-scaffold` integration fixture edit — the recurring implement blind spot | Pre-flight in the implement prompt: every new `validate.sh` check needs the parallel `scripts/test.sh` fixture edit (F000032/F000034/F000035 all hit it). |
| Declaring a `level: workflow` behavior auto-activates Checks 3–6 | Wire the `anchor` (live `-F` grep in `source`) + ≥1 coverage row per behavior, not only the new gate. |
| Eval cases run only when `ANTHROPIC_API_KEY` is set (nightly / local), not in plain CI | RUN-TIME dependency, not a build blocker — the GATE runs in plain CI and is green from birth; the eval runs where the key lives. |
| A third adversarial review of THIS eval-backed doc is advisable before build but not yet run | Optional pre-build review; the durable findings of the two prior reviews are already carried into this reframe. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] All 4 `CJ_goal_*` orchestrators have a `level: workflow` behavior (with a `workflow:` field) + a `behavior_coverage:` row pointing at a real eval case.
- [ ] `feature`/`task`/`defect` each gain ≥1 real eval case matching the `CJ_goal_todo_fix` shape (`prompt.md` + `expected.schema.json`, `--json-schema`-validated).
- [ ] `test-spec.sh --check-workflow-coverage` exists (forward + reverse), HARD, registry-gated-skip, green from birth; a new `validate.sh` check runs it in plain CI; `/CJ_test_audit` Stage 1 prints it + Stage 2 judges substance.
- [ ] Checks 3–6 pass per new behavior; the `behaviors:` parser carries the 6th `workflow` column and `--validate` enum-checks it.
- [ ] Negative fixture: a hypothetical 5th `CJ_goal_*` orchestrator with no workflow behavior → the new check FAILS.
- [ ] Consumer posture: absent `spec/workflow-spec.md` / `spec/test-spec.md` → SKIP cleanly.
- [ ] `scripts/test.sh` green; `validate.sh` 0 errors; `test-spec.sh --validate` + `--check-coverage` clean.

## Not in scope

<!-- Explicit non-goals. -->

- The generated `docs/tests/workflow-coverage.md` view — deferred follow-up (render-from-behaviors + reverse-sweep exemption + doc-spec-row requirements).
- "Make /CJ_test_audit the per-repo test ENFORCER" — its own office-hours; this axis is its precondition.
- The full happy-path-to-PR eval E2E per orchestrator (reaching `/ship`) — gated on the "Scheduled CI drain blocked on gstack-in-CI" blocker; upgrades the SAME behavior without re-stating it.
- Modifying the four `CJ_goal_*` `pipeline.md`/`SKILL.md` files — they are NOT touched.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000070_TRACKER.md](F000070_TRACKER.md)
- Roadmap: [F000070_ROADMAP.md](F000070_ROADMAP.md)
- Child story: [S000119_workflow_coverage_axis/S000119_TRACKER.md](S000119_workflow_coverage_axis/S000119_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-dreamy-wilbur-17be66-design-20260629-194540.md`
- Builds ON: F000069 (generated catalogs + Check 26/27), F000066 (behaviors/behavior_coverage axis + `level` enum), F000013 (the `eval.sh` harness + `tests/eval/` + `eval-nightly.yml`).
