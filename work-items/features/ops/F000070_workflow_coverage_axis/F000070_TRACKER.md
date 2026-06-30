---
name: "Workflow-coverage axis — eval-backed level:workflow tests + forward/reverse gate"
type: feature
id: "F000070"
status: active
created: "2026-06-29"
updated: "2026-06-29"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/dreamy-wilbur-17be66"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/workflow_coverage_axis`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] All 4 `CJ_goal_*` orchestrators have a `level: workflow` behavior (carrying a `workflow:` field) plus a `behavior_coverage:` row pointing at a real eval case (`unit: suite-eval`, `source:` the case prompt, live `anchor`).
- [ ] `feature`/`task`/`defect` each gain ≥1 real eval case under `tests/eval/<skill>/<case>/` (`task` a behavioral `halted_at_too_complex` halt; `feature`/`defect` a `--dry-run` `dry_run_preview`), matching the `CJ_goal_todo_fix` case shape (`prompt.md` + `expected.schema.json`, `--json-schema`-validated by `eval.sh`).
- [ ] `test-spec.sh --check-workflow-coverage` exists (forward + reverse), HARD, registry-gated-skip, green from birth.
- [ ] A new `validate.sh` check runs the gate in plain CI (no API), wired into the `zzz-test-scaffold` integration fixture.
- [ ] `/CJ_test_audit` Stage 1 prints the gate output verbatim (`stage1/` prefixed) + Stage 2 judges substance per `level: workflow` behavior.
- [ ] Checks 3–6 pass per new behavior; the `behaviors:` parser carries the 6th `workflow` column and `--validate` enum-checks it against the declared orchestrators.
- [ ] `workflow-spec.sh --list-orchestrators` exists (orchestrator-kind names only, registry-sourced).
- [ ] Negative fixture: a hypothetical 5th `CJ_goal_*` orchestrator with no workflow behavior → the new check FAILS.
- [ ] Consumer posture: absent `spec/workflow-spec.md` / `spec/test-spec.md` → SKIP cleanly (no error, no false finding).
- [ ] `scripts/test.sh` green; `validate.sh` 0 errors; `test-spec.sh --validate` + `--check-coverage` clean.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Implement S000119 (the single-story chain: eval cases + 6th-column parser + 2 new subcommands + gate + validate wiring + audit surfacing + tests).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-29: Created. Workflow-coverage axis — every CJ_goal_* workflow gets a real Claude-driven level:workflow eval test + a forward/reverse gate + audit-substance judgment (scaffolded from /office-hours design doc).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec-custom.md` (4 `level: workflow` behaviors + 4 `behavior_coverage:` rows)
- `scripts/test-spec.sh` (6th `workflow` column parser + `--check-workflow-coverage`)
- `scripts/workflow-spec.sh` (`--list-orchestrators`)
- `scripts/validate.sh` (new check, next free after 27)
- `scripts/test.sh` (`zzz-test-scaffold` integration fixture)
- `skills/CJ_test_audit/SKILL.md` + its catalog `doc_requirement`
- `tests/eval/CJ_goal_task/halt-too-complex/`, `tests/eval/CJ_goal_feature/dry-run-plan/`, `tests/eval/CJ_goal_defect/dry-run-plan/`
- `tests/test-spec.test.sh` (or new `tests/workflow-coverage.test.sh`)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The honest `level: workflow` test is a REAL Claude-driven eval case (the proven `CJ_goal_todo_fix` pattern: `claude --print`, `--plugin-dir <workbench>/skills`, `--json-schema` enforcement), targeting gstack-independent halt/dry-run paths so it actually runs without gstack-in-CI. This dissolved the rejected shell-fixture / fresh-install / `--dry-run`-stub approach two adversarial reviews kept snagging on.
- Honest split: the forward/reverse GATE runs in plain CI (registry-only, no API) so "documented-but-untested impossible" is enforced everywhere; the eval (works-when-run) runs where `ANTHROPIC_API_KEY` lives (nightly / local). Strictly more honest than a green shell stub.
- `family: eval` is already test-bearing and `suite-eval` (anchor `scripts/eval.sh`) already exists — `behavior_coverage` reuses it, so NO new `units:` rows are needed.
- Declaring a `level: workflow` behavior auto-activates Checks 3–6; the implementation must wire the `anchor` (live `-F` grep in `source`) + coverage row, not only the new gate.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Reframed from a shell-fixture approach to eval-backed after the operator refused the shell fixture twice; the `level: workflow` test is a real Claude-driven eval run, not a green stub. Summary: ambition with a working brake — the full happy-path-to-PR E2E (needs gstack `/ship`/`/office-hours`) is a deferred upgrade of the SAME behavior, not re-stated.
- [decision] Forward-link via an explicit optional `workflow:` field (6th TSV column), not a derived heuristic. Summary: closes OQ1; requires the `_parse_behaviors_file` flush + the ~line-580 read change (prior reviewer findings 3/6).
- [decision] Orchestrator source is the workflow registry via a new `workflow-spec.sh --list-orchestrators`, NOT `--list-workflows` (includes roster) or the `skills-catalog.json` jq set (catalog is consumer-absent → breaks registry-gating). Summary: closes OQ2; prior reviewer finding 4.
- [decision] The generated `docs/tests/workflow-coverage.md` view is DEFERRED to a follow-up (highest blast radius — units-family renderer + Check 26 reverse-sweep exemption + per-row doc-spec declaration); the cheap Stage-2 substance judgment is kept.
