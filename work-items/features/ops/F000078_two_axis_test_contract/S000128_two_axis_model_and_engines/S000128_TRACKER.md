---
name: "Two-axis model + engines + populated workflow category"
type: user-story
id: "S000128"
status: active
created: "2026-07-03"
updated: "2026-07-03"
parent: "F000078"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/kind-goldberg-4747aa"
branch: "claude/kind-goldberg-4747aa"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/two_axis_test_contract` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (N/A — atomic story; the whole two-axis change is one cohesive, sequential build with no parallel sub-units)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

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

- [ ] `test-spec.sh --validate` passes with the category enum `{workflow, regression, infra}`, the layer enum `{CI-push, CI-nightly, pipeline-gate, local-hook}` (units-layer subset `{local-hook, CI-push, CI-nightly}`), and the `mode: agentic ⇒ tier ∈ {paid, local-only}` cross-check.
- [ ] The general `spec/test-spec.md` is byte-identical to `test-spec.sh --seed` (3-way lockstep: parse comment, human table, `--seed` heredoc), verified by the seed-identity test.
- [ ] All 83 `units:` `layer: ci` rows re-map to `CI-push` (trigger ∈ {pr-ci, push-main, pre-commit}) or `CI-nightly` (trigger = nightly); no `units:` row references a layer absent from `layers[]`.
- [ ] `test-spec.sh --list-categories` emits the extended TSV `name category layer mode command tier doc purpose`; `--check-structure` validates the 2-deep `tests/<category>/<layer>/` structure, exempts command-only rows from check (b), and reports the 29 flat tests as advisory backfill findings (exit 0).
- [ ] `test-spec.sh --seed-docs` seeds a missing per-test doc at the 2-deep `docs/tests/<category>/<layer>/<name>.md` path carrying the three front-door sections.
- [ ] `test-run.sh --category workflow`, `--layer CI-nightly`, and `--category`+`--layer` composition select correctly; single-NAME selection preserved; a default run stays free-tier (no model spend).
- [ ] The 4 workflow tests (portability-smoke, portability-deploy, goal-feature-eval, doc-sync) exist as `tests/workflow/<layer>/` file rows or command rows, each with a front-door doc; `docs/tests/index.md` lists them; no orphaned old-path `docs/tests/CI-push/…` etc. remain.
- [ ] Check 28 stays green — the reused `workflow-cj-goal-feature-runs` `level:workflow` behavior still resolves to the `CJ_goal_feature` orchestrator.
- [ ] `validate.sh` green (Checks 24/26/27/28), `test.sh` green (seed-identity + render-freshness suites), shellcheck clean; every script edit is LF + portable (`jq()` CR-strip wrapper for any new jq call, portable `date`).

## Todos

<!-- Actionable items for this story. -->

- [ ] Build step 1 — General tier: rewrite `spec/test-spec.md` (`layers[]` → the four, general `categories` definition of the 3 kinds, the `mode` attribute) + `docs/philosophy.md` "Four verification layers" (~L222–264) + Principle #4 ref (~L184–198) + `docs/architecture.md` test-spec contract (~L363–531).
- [ ] Build step 2 — Engine `test-spec.sh`: category enum at every hardcoded site (re-grep, ~932 case/~933 error/~2205/~2210-2221 seed prose); `layers[]` in the three lockstep seed locations (~127-133 parse comment, ~2122-2125 human table, ~2323-2343 `--seed`); layer-id enum ~744-746; units `layer` enum ~979-981; `layer`+`mode` fields on `categories:` rows + `--validate` cross-check; `--list-categories` extended TSV; `--check-structure` 2-deep + committed check-(b) command-only exemption; `--seed-docs` 2-deep path.
- [ ] Build step 2 — Engine `test-run.sh`: `--category` enum (re-grep ~224 case/~225 error); add `--layer` selection + `--category`+`--layer` composition; keep single-NAME; name→command from extended `--list-categories`.
- [ ] Build step 3 — Overlay `spec/test-spec-custom.md`: re-map all 83 `units:` `layer: ci` → CI-push/CI-nightly by trigger; rewrite the 7 category rows per the table; add the new workflow rows + `workflow-doc-audit-runs` behavior + its coverage link; update the layer-grouping prose.
- [ ] Build step 4 — Physical: create `tests/workflow/{CI-push,CI-nightly,local-hook}/` + the doc-sync test file; write front-door docs (`## What it is`/`## How to run`/`## Explanation`); regenerate `docs/tests/` via `--render-docs` + `--seed-docs`; refresh `docs/tests/index.md`; reconcile `spec/doc-spec-custom.md` (delete moved-category docs, add new paths); remove the stale empty `tests/{CI-push,CI-nightly,workflow}/.gitkeep`.
- [ ] Build step 5 — Skills: `skills/CJ_test_audit/SKILL.md` + `skills/CJ_test_run/SKILL.md` (two-axis structure, 3 categories, 4 layers, `--layer`) + USAGE freshness bump.
- [ ] Build step 6 — Green in order: `validate.sh` (24/26/27/28) → `test.sh` (seed-identity + render-freshness) → shellcheck; run `scripts/windows-smoke.sh` for portability.
- [ ] Settle the doc-sync backing (new `tests/eval/CJ_doc_audit/` agentic case via `suite-eval` vs existing `cj-audit-skills` unit) during implement.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Carries the entire two-axis test-contract reframe (model + engines + overlay re-map + populated workflow category + doc/skill updates) as one atomic user-story.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `spec/test-spec.md`, `spec/test-spec-custom.md`, `spec/doc-spec-custom.md`
- `scripts/test-spec.sh`, `scripts/test-run.sh`
- `docs/philosophy.md`, `docs/architecture.md`, `docs/tests/index.md`, `docs/tests/<category>/<layer>/*.md`
- `skills/CJ_test_audit/SKILL.md`, `skills/CJ_test_audit/USAGE.md`, `skills/CJ_test_run/SKILL.md`, `skills/CJ_test_run/USAGE.md`
- `tests/workflow/{CI-push,CI-nightly,local-hook}/` (+ removal of stale `tests/{CI-push,CI-nightly,workflow}/.gitkeep`)
- `tests/test-spec.test.sh`, `tests/test-run.test.sh` (assertions for the new enums/fields — deterministic drills)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The enum change is atomic because `test-spec.sh --validate` (called by HARD `validate.sh` Check 24) enum-checks BOTH `categories:` AND `units:`/`layers:` rows — a partial flip reds CI mid-PR.
- Three lockstep seed locations must move together or the byte-identical-seed test fails: parse comment (~:127-133), human table (~:2122-2125), `--seed` heredoc (~:2323-2343), mirroring the doc-spec 3-way lockstep at `tests/doc-spec-overlay.test.sh:99-110`.
- `layer` is a RENDERED field in `docs/tests/<family>.md`, so the 83-row re-map forces regenerating every family doc via `--render-docs` — Check 26 (freshness) is the gate that catches a stale render.
- Re-categorizing a row MOVES its generated doc path; the old `docs/tests/CI-push/…` becomes a Check 15/15a orphan unless deleted + the new path declared in `spec/doc-spec-custom.md` and regenerated.
- Do NOT trust the design's line numbers — re-grep for every hardcoded enum site before editing.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-03 — Kept as ONE atomic user-story (no task children). Summary: the build order is strictly sequential (general tier → engines → overlay → physical → skills → green) with no parallel sub-units, and the enum flip must land in one change; decomposing into tasks would fragment an inherently atomic diff.
- [decision] 2026-07-03 — `mode` is required on every `categories:` row with the `agentic ⇒ tier ≠ free` cross-check (resolves review fix #6/#7). Summary: agentic tests spend model tokens, so `free` is impossible for them; explicit+required removes the mode/tier overlap.
- [decision] 2026-07-03 — `--check-structure` check (b) is committed (not deferred) with a command-only exemption (resolves review fix #8). Summary: command-only rows (validate/suite/test-deploy) must never force an empty `tests/infra/…` folder.
