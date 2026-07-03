---
name: "Category-based test contract — /CJ_test_audit + /CJ_test_run V1 foundation"
type: feature
id: "F000074"
status: active
created: "2026-07-02"
updated: "2026-07-02"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/charming-germain-70dd6e"
branch: "claude/charming-germain-70dd6e"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/category_test_contract_v1`
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

- [ ] The test contract carries a NEW, backward-compatible category axis (`workflow` + `CI`): a new overlay section + new `test-spec.sh` subcommands that leave the existing `--validate` / `--check-coverage` / `--render-docs --check` / `--check-workflow-coverage` tolerant and green.
- [ ] `/CJ_test_audit` verifies the five structural checks (a–e) as findings-not-crashes, seeds missing `docs/tests/<category>/<name>.md` stubs + the index table idempotently, and NEVER moves test scripts.
- [ ] `/CJ_test_run` accepts `--category <workflow|CI>` and a single-test-name argument (reusing the `docs/tests/` name), selecting the right tests; the default run touches no paid model.
- [ ] Both `SKILL.md` + `USAGE.md` for `/CJ_test_audit` and `/CJ_test_run` are rewritten around the category model; CLAUDE.md's scripts-reference + contract prose describe the new category surface.
- [ ] `test-spec.sh --seed` emits the portable category contract; new tests cover the category behavior; `validate.sh` + `test.sh` + the doc/test audit stay green (the change is ADDITIVE — no removal of the existing units/behaviors/runners axes or the `docs/tests/<family>.md` render).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000124 — implement the category-axis foundation (see child TRACKER)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-02: Created. Category-based test contract V1 foundation — add a backward-compatible category axis (workflow + CI) to the test contract and re-point /CJ_test_audit + /CJ_test_run at it, additively, without the deferred physical test-move / grammar-removal / validate re-expression.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec.md` (general seed — add portable category contract)
- `spec/test-spec-custom.md` (overlay — add repo category rows)
- `scripts/test-spec.sh` (engine — add category subcommands)
- `scripts/test-run.sh` (engine — add `--category` + single-test-name selection)
- `skills/CJ_test_audit/SKILL.md` + `USAGE.md`
- `skills/CJ_test_run/SKILL.md` + `USAGE.md`
- `CLAUDE.md` (scripts-reference + contract prose)
- `tests/` (new coverage for category behavior)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- One clean noun — the test category — threads the whole system: the folder a test lives in, the contract section that declares it, the doc that describes it, the index row, and the `/CJ_test_run` argument. Audit and run share ONE vocabulary.
- Foundation-first staging keeps the repo green: because `validate.sh` Checks 24/26/28 still validate the existing units/behaviors/runners grammar this PR, the category axis MUST be purely additive — the removal + physical reorganization is a deferred follow-up run.
- Audit posture is REPORT + SEED DOC STUBS ONLY: `/CJ_test_audit` reports structural gaps and may seed doc scaffolding idempotently, but NEVER moves or rewrites test scripts (standalone-safe for foreign repos).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-02: Core model = REPLACE (the end-state supersedes family/units/behaviors), but THIS PR ships only the additive foundation — the category axis coexists; removal + physical reorganization are deferred.
- [decision] 2026-07-02: Workbench layout = physically reorganize NOW is the end-state, but the physical test-script move into `tests/workflow/` + `tests/CI/` is DEFERRED out of this PR to keep it green and reviewable.
- [decision] 2026-07-02: Audit posture = REPORT + SEED DOC STUBS ONLY — the audit reports the five checks and seeds doc stubs idempotently, never touching test-script layout (standalone-safe).
