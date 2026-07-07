---
name: "Retire the paid run-eval harness — keep the eval cases as in-session verify specs + the Check 28 gate (Testing roadmap Phase 0)"
type: feature
id: "F000087"
status: active
created: "2026-07-06"
updated: "2026-07-06"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/vigorous-mcclintock-e72fcb"
branch: "claude/vigorous-mcclintock-e72fcb"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Working branch: `claude/vigorous-mcclintock-e72fcb` (orchestrator worktree)
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-vigorous-mcclintock-e72fcb-design-20260706-165302.md`)
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

- [ ] `scripts/eval.sh` is DELETED and the `run-eval` `runners:` row is REMOVED from `spec/test-spec-custom.md`; no dangling reference to `eval.sh` remains in `scripts/`, `tests/`, `.github/workflows/`, or the spec/test-run engines
- [ ] The `suite-eval` unit is re-anchored off `source: scripts/eval.sh` onto a durable `tests/eval/` spec (a live `source` + `anchor` that Check 24's forward grep matches); its `label`/`purpose` are reframed as specs-only, verified in-session
- [ ] `bash scripts/validate.sh` is GREEN, specifically Check 24 (coverage cross-check — `suite-eval` re-anchored, no dangling), Check 28 (workflow coverage — 4/4 orchestrators still wired), Check 30 (`--check-topic-contract` — exit 0, only advisory notes), Checks 26/27 (catalogs fresh)
- [ ] The `goal-task-eval` + `goal-feature-eval` `categories:` rows are removed and `cj-goal-eval` is dropped from the `topic_contracts:` unenrolled-topics prose (no labeled `categories:` rows remain for it)
- [ ] The two front-door docs `docs/tests/workflow/local-hook/goal-task-eval.md` + `docs/tests/workflow/local-hook/goal-feature-eval.md` are deleted, their `spec/doc-spec-custom.md` declaring rows removed, and `docs/tests/index.md` reconciled
- [ ] `/CJ_test_audit` reports NO orphaned eval family (the `eval` family stays declared via `run-test-sh` `covers:` + the re-anchored `suite-eval` unit)
- [ ] Every `tests/eval/<skill>/<case>/prompt.md` is an honest, non-leaking in-session verification spec (no expected-output in any prompt.md; the `behavior_coverage` anchor strings Check 28 greps still match live)
- [ ] The full `bash scripts/test.sh` suite passes; shellcheck green

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Delete `scripts/eval.sh` + sweep every caller (scripts/tests/workflows/spec engines) so nothing dangles (S000136)
- [ ] Edit `spec/test-spec-custom.md`: remove the `run-eval` `runners:` row; reframe `run-test-sh` `covers:` note (keep `eval`; drop the "run-eval owns real eval execution" clause); re-anchor `suite-eval` onto `tests/eval/` specs; remove the `goal-task-eval` + `goal-feature-eval` `categories:` rows; drop `cj-goal-eval` from the unenrolled-topics prose (S000136)
- [ ] Mirror any `spec/test-spec.md` seed change ONLY if a general-file line changed (expected: none — all edits are overlay) (S000136)
- [ ] Edit `spec/doc-spec-custom.md`: remove the two front-door-doc declaration rows; delete the two physical docs; reconcile `docs/tests/index.md` (S000136)
- [ ] De-leak the eval prompts: remove the `dry_run_preview` expected-output leak in `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md`; preserve the `behavior_coverage` anchor strings Check 28/Check-5 grep (S000136)
- [ ] Regenerate the generated catalogs (`test-spec.sh --render-docs`, `workflow-spec.sh --render-docs`) so Checks 26/27 stay green (S000136)
- [ ] Verify: `validate.sh` (esp. Checks 24/26/27/28/30), `--check-structure` (workflow/local-hook subfolder not left empty), `test.sh`, shellcheck (S000136)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Retire the paid `run-eval` harness (`scripts/eval.sh`) — keep the `tests/eval/` cases as durable in-session verification specs + the free Check 28 structural gate (Testing roadmap Phase 0).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/eval.sh` (DELETE)
- `spec/test-spec-custom.md` (runners row removal + suite-eval re-anchor + categories rows removal + covers note + topic prose)
- `spec/test-spec.md` (mirror ONLY if a general-file line changed — expected: no change)
- `spec/doc-spec-custom.md` (remove two front-door-doc declaring rows)
- `docs/tests/workflow/local-hook/goal-task-eval.md`, `docs/tests/workflow/local-hook/goal-feature-eval.md` (DELETE)
- `docs/tests/index.md` (reconcile)
- `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md` (+ any other leaking prompt.md — de-leak, preserve anchors)
- `docs/test-catalog.md`, `docs/tests/*.md`, `docs/workflow.md`, `docs/workflows/*.md` (regenerated catalogs)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Retiring machinery is the feature: "green = trustworthy" without a recurring bill. The free automatic structural gate (Check 28) stays green and travels to every machine; the only agentic cost becomes an in-session ask the operator already pays for.
- The `tests/eval/<skill>/<case>/` dirs are load-bearing beyond the runner: they are the anchors `validate.sh` Check 28 (`--check-workflow-coverage`) greps, so deleting them would un-guard `CJ_goal_*` drift on every push. They must be KEPT as durable, honest, non-leaking verification specs.
- Check 28 is driven by the `behaviors:`/`behavior_coverage:` axis (each `level: workflow` behavior → its `workflow:` orchestrator + its `tests/eval/<skill>/<case>/prompt.md` anchor), which is INDEPENDENT of the `categories:` rows — so removing the two `goal-*-eval` `categories:` rows does NOT break the workflow gate.
- The portability un-enroll prerequisite is MOOT: F000086 already demoted the enrolled-topic `local-hook`+agentic point to ADVISORY, and Phase 0 removes the eval-family harness, not portability's agentic test — so no preceding "un-enroll portability" commit is required (verify empirically with `--check-topic-contract` after removal).
- Approach C (remove the two `categories:` rows) was chosen over A (self-skip command string) and B (tiny shared helper) as the least-surface option: nothing to break, no doc-string-as-command awkwardness, and it aligns with "retiring the harness is the feature."

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Summary: Approach C chosen (operator AUQ) — drop the `goal-task-eval` + `goal-feature-eval` `categories:` rows + their front-door docs; keep ONLY the `behaviors:`/`behavior_coverage:` + `tests/eval/` dirs + Check 28. Accepts the tradeoff that it regresses the roadmap's "feature+task are first-class `categories: workflow` rows" state; the `level: workflow` behaviors + Check 28 are the real workflow gate.
- [decision] 2026-07-06 — Summary: `suite-eval` re-anchors off `source: scripts/eval.sh` (which would go dangling under Check 24's forward anchor-grep once the script is deleted) onto the durable `tests/eval/` specs, reframed as "the eval-case verification specs Claude drives in-session," not "the runner."
- [decision] 2026-07-06 — Summary: The eval family stays DECLARED (not orphaned) — `run-test-sh` keeps `eval` in its `covers:` list (test.sh never invoked eval.sh anyway) and the `suite-eval` unit keeps `family: eval` alive; the note is reframed to "specs-only, verified in-session."
- [finding] 2026-07-06 — Summary: Phase 2 ripple (out of scope) — the roadmap's "promote `defect` + `todo_fix` to first-class `categories: workflow` rows" now conflicts with removing `feature`+`task`'s rows; flag in TODOS, do not expand this build.
