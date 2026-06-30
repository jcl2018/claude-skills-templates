---
name: "Eval-backed level:workflow coverage + forward/reverse gate + Stage-2 substance"
type: user-story
id: "S000119"
status: active
created: "2026-06-29"
updated: "2026-06-29"
parent: "F000070"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/dreamy-wilbur-17be66"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "2b4ea59af371336a20b7e9479cce2f2a5a2d9079"
    completed_at: "2026-06-30T04:48:33Z"
    test_rows_run: 8
    ac_ids_covered: [AC-2, AC-3, AC-4, AC-5, AC-6, AC-7]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-smoke-summary] green 5/5", "[qa-e2e-deferred] E4 post-ship", "[qa-e2e] E1/E2/E3 green", "[qa-e2e-summary] green", "[qa-audit] AUDITS=deferred"]
    ready_for_ship: true
    next_legal: [ship]
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/workflow_coverage_axis` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; one cohesive implementation chain in the test-spec/workflow-spec/validate surfaces + eval cases)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] 4 `level: workflow` behaviors declared in `spec/test-spec-custom.md`, each carrying a `workflow:` field equal to a declared orchestrator, plus 4 `behavior_coverage:` rows (`unit: suite-eval`, `source:` the case `prompt.md`, live `anchor`).
- [ ] 3 real eval cases added: `tests/eval/CJ_goal_task/halt-too-complex/`, `tests/eval/CJ_goal_feature/dry-run-plan/`, `tests/eval/CJ_goal_defect/dry-run-plan/` (each `prompt.md` + `expected.schema.json`, `--json-schema`-validated by `eval.sh`); `todo_fix` reuses an existing preflight-halt case.
- [ ] `_parse_behaviors_file` extended from 5 to 6 TSV columns (`id,statement,level,area,purpose,workflow`); `nz()`/flush `printf` + the ~line-580 5-var read updated with the `[ "$_bworkflow" = "-" ] && _bworkflow=""` unwrap; other `$1`-only consumers verified positional-safe.
- [ ] `test-spec.sh --validate`: `workflow:` optional, allowed ONLY on `level: workflow` rows, value MUST be a declared orchestrator (enum-checked); rendered-field ID lint preserved.
- [ ] `workflow-spec.sh --list-orchestrators` exists (orchestrator-kind names only, reusing `_list_sections()` + `_section_kind()`).
- [ ] `test-spec.sh --check-workflow-coverage` exists: forward (every orchestrator has ≥1 matching `level: workflow` behavior), reverse (every `level: workflow` behavior's `workflow:` resolves to a declared orchestrator), registry-gated skip (workflow-spec absent / not canonical OR test-spec absent → `inactive` + exit 0); cross-script path resolved repo-local→`_cj-shared`.
- [ ] New `validate.sh` check (next free after 27) runs the gate, HARD, registry-gated-skip; wired into the `zzz-test-scaffold` fixture.
- [ ] `/CJ_test_audit` Stage 1 prints `--check-workflow-coverage` verbatim (`stage1/` prefixed); Stage 2 adds the per-behavior substance clause; `skills/CJ_test_audit/SKILL.md` + its catalog `doc_requirement` updated.
- [ ] Tests: forward-miss → finding, reverse-orphan → finding, registry-absent → inactive, all-declared → clean, 6th-column round-trip + `-` unwrap, `workflow:` enum-check rejects unknown orchestrator, negative 5th-orchestrator fixture → FAILS, consumer-absent → SKIP.
- [ ] `scripts/test.sh` green; `validate.sh` 0 errors; `test-spec.sh --validate` + `--check-coverage` clean.

## Todos

<!-- Actionable items for this story. -->

- [x] Step 1: add 3 real eval cases (`CJ_goal_task` behavioral halt; `CJ_goal_feature`/`CJ_goal_defect` `--dry-run`).
- [x] Step 2: declare 4 `level: workflow` behaviors with the new `workflow:` field.
- [x] Step 3: add 4 `behavior_coverage:` rows (`unit: suite-eval`, `source:` prompt, live `anchor`).
- [x] Step 4: extend the behaviors parser to the 6th `workflow` column + `--validate` enum-check.
- [x] Step 5: add `workflow-spec.sh --list-orchestrators`.
- [x] Step 6: add `test-spec.sh --check-workflow-coverage` (forward + reverse + registry-gated skip).
- [x] Step 7: wire the gate into `validate.sh` (Check 28) + the `zzz-test-scaffold` fixture (Step 3g).
- [x] Step 8: surface in `/CJ_test_audit` (Stage 1 verbatim + Stage 2 substance) + update SKILL.md/USAGE.md + catalog `doc_requirement` + `description`.
- [x] Step 9: tests for the new machinery (`tests/workflow-coverage.test.sh`: positive, negative 5th-orchestrator forward miss, reverse orphan, enum-check, consumer-absent) + the `test-spec.test.sh` drill-fixture follow-on.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-29: Created. Eval-backed level:workflow coverage + forward/reverse gate + Stage-2 substance (single-story chain of F000070).
- 2026-06-29: Implemented (Steps 1-9) via /CJ_implement-from-spec. validate.sh PASS (0 errors), scripts/test.sh PASS (0 failures), test-spec.sh --validate + --check-coverage + --check-workflow-coverage all green; tests/workflow-coverage.test.sh (12 assertions) + tests/test-spec.test.sh green.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `spec/test-spec-custom.md` (modified — 4 `level: workflow` behaviors + 4 `behavior_coverage:` rows + the `validate-check-28` + `test-workflow-coverage` units rows)
- `scripts/test-spec.sh` (modified — 6th `workflow` column parser, `--validate` enum-check, `_resolve_workflow_spec`/`_list_orchestrators` cross-script helpers, `--check-workflow-coverage`)
- `scripts/workflow-spec.sh` (modified — `--list-orchestrators` subcommand + `_list_orchestrators` helper)
- `scripts/validate.sh` (modified — new Check 28)
- `scripts/test.sh` (modified — Step 3g Check-28 zzz-fixture assertion + `tests/workflow-coverage.test.sh` runner)
- `skills/CJ_test_audit/SKILL.md` (modified — Stage 1 `--check-workflow-coverage` call + Stage 2 `level: workflow` substance clause + frontmatter description)
- `skills/CJ_test_audit/USAGE.md` (modified — Stage 1 enumeration adds the workflow-coverage gate)
- `skills-catalog.json` (modified — CJ_test_audit `doc_requirement` + `description`)
- `README.md` (regenerated from the catalog)
- `docs/test-catalog.md` + `docs/tests/validate.md` + `docs/tests/test.md` (regenerated — new units rows)
- `tests/eval/CJ_goal_task/halt-too-complex/`, `tests/eval/CJ_goal_feature/dry-run-plan/`, `tests/eval/CJ_goal_defect/dry-run-plan/` (new — `prompt.md` + `expected.schema.json` + `fixture/README.md` each)
- `tests/workflow-coverage.test.sh` (new — the gate + parser + `--list-orchestrators` machinery test)
- `tests/test-spec.test.sh` (modified — the coverage-drill fixture copies the referenced eval prompt files)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The 6th-column parser change is the riskiest mechanical edit: the flush `printf` AND the only destructuring consumer (the ~line-580 5-var `read`) must both move to 6 vars with the `-` placeholder unwrap; other consumers read `$1` only (duplicate-id ~498, coverage `awk '$1==want'` ~703, `--list-behaviors`/anchor ~737/1555) and are positional-safe.
- The new `validate.sh` check needs a parallel `zzz-test-scaffold` integration fixture edit — the recurring implement blind spot (F000032/F000034/F000035 all forgot it).
- Use `workflow-spec.sh --list-orchestrators` (registry-sourced, orchestrator-kind only) for the gate's orchestrator set — NOT `--list-workflows` (includes roster) or the `skills-catalog.json` jq set (consumer-absent → breaks registry-gating).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Atomic story — no task children. Summary: one cohesive implementation chain across the test-spec/workflow-spec/validate surfaces + 3 eval cases; the steps are sequential but not parallelizable sub-units warranting separate task dirs.
- 2026-06-29 [impl-decision] Made the `--validate` `workflow:` enum-check GRACEFUL on an unresolvable orchestrator set (skip, not halt) instead of halting. Rationale: halting `--validate` when workflow-spec.sh / spec/workflow-spec.md is absent makes test-spec validation depend on the workflow registry being present — it broke `test-spec.test.sh`'s temp-dir coverage drills (which copy only `test-spec-custom.md`) and would break consumer repos with no workflow registry. The dedicated `--check-workflow-coverage` gate + validate.sh Check 28 own the orchestrator-set enforcement where the registry IS resolvable, so a genuine orphan link is still caught; the level-placement rule (workflow: only on level:workflow rows) stays unconditional.
- 2026-06-29 [impl-decision] Resolved the new validate.sh check number to Check 28 (next free after Check 27); mirrored Check 27's registry-gated-skip shape (engine-absent SKIP + inactive/REGISTRY=absent SKIP + HARD on a real finding).
- 2026-06-29 [impl-finding] The reverse arm of the gate is largely SUBSUMED by the `--validate` enum-check (the gate runs `_run_registry_gates` first, which halts on an undeclared workflow: value before the reverse arm runs). The gate's own reverse arm is the belt-and-suspenders for the path validate leaves open — a level:workflow behavior with an EMPTY workflow: field (validate allows it; the gate flags it). Both lines of defense are covered by tests/workflow-coverage.test.sh cases 5a/5b.
- 2026-06-29 [impl-finding] The new validate.sh Check 28 banner + the new tests/workflow-coverage.test.sh both required parallel test-spec registry rows (Check 24's reverse sweep: `validate-check-28` for the banner, `test-workflow-coverage` for the test file), AND the `zzz-test-scaffold` integration fixture edit (Step 3g) — the recurring F000032/34/35 implement blind spot, pre-flighted and handled.
- 2026-06-29 [impl] Steps 1-9: 3 new eval cases (task halt-too-complex; feature/defect dry-run-plan), 4 level:workflow behaviors + 4 behavior_coverage rows, the 6th-column behaviors parser + enum-check, workflow-spec.sh --list-orchestrators, test-spec.sh --check-workflow-coverage, validate.sh Check 28 + the zzz Step-3g fixture, /CJ_test_audit Stage 1+2 surfacing + SKILL.md/USAGE.md/catalog updates, tests/workflow-coverage.test.sh (+ the test-spec.test.sh drill-fixture follow-on). README + test catalog regenerated.
- 2026-06-29 [impl-pass] S000119: implementation complete. Phase 2 implementer-owned gates transitioned. validate.sh 0 errors; scripts/test.sh 0 failures.
- 2026-06-29 [qa-smoke] S1 (AC-2): green — `test-spec.sh --validate` → `OK schema_version=1` (exit 0); enum-check accepts the 4 declared orchestrators and rejects an unknown `workflow:` value when the workflow registry is resolvable (verified via temp-fixture `[test-spec-no-config]` finding).
- 2026-06-29 [qa-smoke] S2 (AC-4): green — `test-spec.sh --check-workflow-coverage` → `workflow coverage: orchestrators=4 level:workflow behaviors=4 findings=0` (exit 0). Forward+reverse gate green from birth, no orphan behavior.
- 2026-06-29 [qa-smoke] S3 (AC-3): green — `test-spec.sh --list-behaviors` (exit 0) emits the 4 new `workflow-cj-goal-*` behaviors; 6th `workflow` column round-trips with the `-` placeholder unwrap; positional `$1` consumers unaffected.
- 2026-06-29 [qa-smoke] S4 (AC-7): green — `workflow-spec.sh --list-orchestrators` (exit 0) emits exactly the 4 `CJ_goal_*` orchestrator names, no roster entries.
- 2026-06-29 [qa-smoke] S5 (AC-4): green — `validate.sh` 0 errors / 0 warnings (Check 28 PASS: orchestrators=4 level:workflow behaviors=4 findings=0) && `test.sh` 0 failures (RESULT: PASS; `tests/workflow-coverage.test.sh` green; Step-3g zzz-test-scaffold Check-28 fixture PASS on the in-sync live tree).
- 2026-06-29 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-29 [qa-e2e-deferred] E4 (AC-1): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship. The 3 new eval cases require ANTHROPIC_API_KEY (nightly eval-nightly.yml / local eval.sh).
- 2026-06-29 [qa-e2e-run-start] RUN_ID=20260629-214531-49491 commit=2b4ea59
- 2026-06-29 [qa-e2e] E1 (AC-4): green — forward-miss negative fixture FAILS the gate. A well-formed 5th orchestrator with no matching `level: workflow` behavior yields a forward FINDING + non-zero exit (verified via tests/workflow-coverage.test.sh's hermetic `_emit_orchestrator_section` case: "forward miss: a 5th orchestrator ... FAILS the gate"; also reverse-orphan 5a/5b). Gate is not a silent pass. [parent-inline]
- 2026-06-29 [qa-e2e] E2 (AC-6): green — consumer-absent registries SKIP cleanly. test-spec absent → `REGISTRY=absent` exit 0; workflow-spec absent → `workflow coverage inactive — no orchestrators resolvable ...` exit 0. No error, no false finding. [parent-inline]
- 2026-06-29 [qa-e2e] E3 (AC-5): green — /CJ_test_audit surfaces the gate. Stage 1: `--check-workflow-coverage` emitted verbatim `stage1/workflow-coverage: ... findings=0` (exit 0; SKILL.md lines 244-268). Stage 2: per-`level:workflow`-behavior substance protocol present (SKILL.md lines 355-366); the 4 behaviors link to real eval-case prompts that genuinely DRIVE the workflow (task complexity-gate halt; feature/defect `--dry-run`), each `expected.schema.json` asserts the load-bearing field with `const` + `pattern` — not hollow stubs. [parent-inline]
- 2026-06-29 [qa-e2e-summary] green (0s subagent — inline per nested-subagent wall; 3 rows parent-inline; 1 deferred): E1/E2/E3 all green; E4 deferred post-ship (eval execution needs ANTHROPIC_API_KEY).
- 2026-06-29 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none(already-declared-by-impl),doc-spec-custom:none (Step 8.6a/8.6b ran inline — overlays already complete + coverage/doc-spec checks clean; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-29 [qa-pass] S000119 (user-story): green smoke + green E2E (E1/E2/E3; E4 deferred post-ship). Phase 2 gates transitioned.
