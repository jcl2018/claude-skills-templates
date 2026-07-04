---
name: "Two-axis test contract — category × verification-layer"
type: feature
id: "F000078"
status: active
created: "2026-07-03"
updated: "2026-07-03"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/kind-goldberg-4747aa"
branch: "claude/kind-goldberg-4747aa"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/two_axis_test_contract`
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

- [ ] `test-spec.sh --validate` passes with the 3-category `{workflow, regression, infra}` enum + the 4-layer `{CI-push, CI-nightly, pipeline-gate, local-hook}` enum + the `mode: agentic ⇒ tier ≠ free` cross-check.
- [ ] `test-spec.sh --list-categories` emits the extended TSV (`name category layer mode command tier doc purpose`); `--check-structure` validates the 2-deep `tests/<category>/<layer>/` structure with command-only infra rows exempt from check (b), and reports the 29 un-migrated flat tests as advisory backfill findings (not errors).
- [ ] The general `spec/test-spec.md` stays byte-identical to `test-spec.sh --seed` (the 3-way-lockstep test passes); no `units:` row references a layer absent from `layers[]`.
- [ ] All 83 `units:` `layer: ci` rows are re-mapped to `CI-push`/`CI-nightly` by trigger; the general `layers[]` block flips to the four in all three lockstep seed locations.
- [ ] `test-run.sh --category workflow` / `--layer CI-nightly` select correctly; a default run stays free-tier (never spends model tokens).
- [ ] The 4 workflow tests exist under `tests/workflow/<layer>/` (or as `command` rows) with front-door docs (`## What it is` / `## How to run` / `## Explanation`); `docs/tests/index.md` lists them; no orphaned old-path docs remain.
- [ ] `validate.sh` green (Checks 24/26/27/28), `test.sh` green (incl. seed-identity + render-freshness suites), shellcheck clean.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000128 — General tier: rewrite `spec/test-spec.md` (layers[] + categories definition + mode attribute) + `docs/philosophy.md` "Four verification layers" + `docs/architecture.md` test-spec contract section.
- [ ] S000128 — Engine: `test-spec.sh` (3-category + 4-layer enums in lockstep, `layer`/`mode` fields + agentic⇒¬free cross-check, `--check-structure` 2-deep + committed check-(b) command-only exemption, `--seed-docs` 2-deep, extended `--list-categories` TSV) + `test-run.sh` (`--category` enum + `--layer` selection + composition).
- [ ] S000128 — Overlay: `spec/test-spec-custom.md` — re-map all 83 `units:` `layer: ci` rows by trigger, rewrite the 7 category rows, add the new workflow rows + `workflow-doc-audit-runs` behavior + coverage link, update layer-grouping prose.
- [ ] S000128 — Physical: create `tests/workflow/{CI-push,CI-nightly,local-hook}/` + the doc-sync test file; write front-door docs; regenerate `docs/tests/` + index + reconcile `spec/doc-spec-custom.md`; remove the stale empty `tests/{CI-push,CI-nightly,workflow}/.gitkeep` scaffolds.
- [ ] S000128 — Skills: `/CJ_test_audit` + `/CJ_test_run` SKILL.md updates + USAGE freshness.
- [ ] S000128 — Green the tree in build order: `validate.sh` (24/26/27/28) → `test.sh` (seed-identity + render-freshness) → shellcheck.
- [ ] File the follow-on TODOS row: migrate the 29 flat regression tests into `tests/regression/<layer>/` + the feature→workflow / defect→regression enforcement gate + wiring the category↔behavior cross-check.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Two-axis test contract — split the single muddled `categories:` axis into orthogonal category × layer axes plus a deterministic|agentic mode; full layer re-map now; ship a populated workflow category.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec.md` (general seed — layers[] + categories + mode)
- `spec/test-spec-custom.md` (overlay — 83-row layer re-map + category rows + new behavior)
- `scripts/test-spec.sh` (enums + `layer`/`mode` fields + `--check-structure` 2-deep + `--seed-docs` + `--list-categories`)
- `scripts/test-run.sh` (`--category` enum + `--layer`)
- `docs/philosophy.md` (Topic: CI/CD "Four verification layers")
- `docs/architecture.md` (test-spec.md contract section)
- `skills/CJ_test_audit/SKILL.md`, `skills/CJ_test_run/SKILL.md`
- `tests/workflow/{CI-push,CI-nightly,local-hook}/` + generated `docs/tests/<category>/<layer>/*.md` + `docs/tests/index.md`

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The test taxonomy is modeled off the WORK-ITEM taxonomy, not off tooling: `category` = the kind of work that produced the test (`workflow` from features, `regression` from defects, `infra` for the standing verification surface). That reframe is why the split clicks.
- `ratchet` was never a location — it is a monotonic-guard *property*. Demoting it from a layer to a `ratchet: true` flag (which already exists) leaves the layer set exactly four.
- The F000074/F000075 single-axis muddle already produced a half-built artifact: `tests/{workflow,CI-push,CI-nightly}/` folders carrying only `.gitkeep`, 0 tests migrated. This feature ships the workflow category POPULATED to avoid repeating that empty-scaffold mistake (rejected Approach B for exactly that reason).
- The enum change is ATOMIC and touches many surfaces at once: `test-spec.sh --validate` (called by HARD `validate.sh` Check 24) enum-checks both `categories:` and `units:`/`layers:` rows, so the layers[] flip + the 83-row re-map + the seed 3-way lockstep + every rendered family doc must land in ONE change or CI reddens mid-PR.
- `category=workflow` is NOT the same as behavior `level: workflow` — Check 28 enforces orchestrator↔`level:workflow`, not category↔behavior. Only `goal-feature-eval` is `level: workflow`; portability + doc-sync are `category=workflow` backing non-workflow-level behaviors. Category↔behavior is convention-only this increment.
- Do NOT trust line numbers when updating enums — re-grep `grep -n "CI-push\|CI-nightly" scripts/test-spec.sh scripts/test-run.sh` and update every hit.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-03 — Two clean axes (category × layer) + a `deterministic|agentic` mode replace the single conflated `categories:` axis. Summary: Premise 1 confirmed with operator — the old `{workflow, CI-push, CI-nightly}` conflated a semantic kind with a run cadence.
- [decision] 2026-07-03 — Categories are the closed set `{workflow, regression, infra}`. Summary: Premise 2 — operator added `infra` as the third bucket for the validator/suite/deploy self-checks rather than overloading `regression`.
- [decision] 2026-07-03 — Layers are exactly `{CI-push, CI-nightly, pipeline-gate, local-hook}`; `ratchet` demotes from a layer to a `ratchet: true` flag. Summary: Premise 3.
- [decision] 2026-07-03 — Main logic goes in the GENERAL portable tier (philosophy + test-spec general), inherited by consumers; the change bumps the seed. Summary: Premise 4.
- [decision] 2026-07-03 — Full layer re-map NOW: all 83 `units:` `layer: ci` rows re-map by trigger in this PR, not deferred. Summary: Premise 6 — operator chose "Full re-map now" over staging, to avoid carrying two layer vocabularies even briefly.
- [decision] 2026-07-03 — Chose Approach A (model + engines + populated workflow tests) over B (model+engines only, ships workflow category empty — rejected) and C (also migrate all 29 flat tests now — XL/High risk, rejected in favor of a staged additive landing).
- [decision] 2026-07-03 — Deferred backfill tracked separately: migrate 29 flat tests into `tests/regression/<layer>/` + the feature→workflow / defect→regression enforcement gate + wiring the category↔behavior cross-check.
