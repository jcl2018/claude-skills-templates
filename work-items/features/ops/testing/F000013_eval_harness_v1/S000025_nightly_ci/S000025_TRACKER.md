---
name: "Nightly CI workflow + first run validation + TODOS update"
type: user-story
id: "S000025"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000013"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: "S000024"
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/eval_harness_nightly_ci` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [ ] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [x] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [x] `/ship` — PR created (with pre-landing review)
- [x] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `.github/workflows/eval-nightly.yml` exists with cron `0 9 * * *` UTC, runs `bash scripts/eval.sh`, requires `ANTHROPIC_API_KEY` repo secret
- [ ] Workflow includes `workflow_dispatch` trigger so manual runs are possible
- [ ] First manual run via `gh workflow run eval-nightly.yml` completes successfully (or surfaces real issues to fix)
- [ ] Observed cost from first real run is recorded in tracker journal (PASS criterion if ≤ $1.50; revise V1 success criteria if > $2.25)
- [ ] Observed wall-clock from first real run is recorded in tracker journal (PASS criterion if ≤ 12 min; revise V1 success criteria if > 18 min)
- [ ] `TODOS.md` updated: "Behavioral eval harness (P1, M)" entry marked DONE-V1 with link to F000013 + V2 trajectory bullets
- [ ] Failure-notification path verified: a deliberately-failing case (temporarily corrupt one schema) triggers the workflow's failure surface (GitHub PR check, email, etc.) on the next manual run
- [ ] Workflow has reasonable timeout (15 min) to prevent runaway cost on stuck runs

## Todos

<!-- Actionable items for this story. -->

- [ ] Author `.github/workflows/eval-nightly.yml`: cron schedule + workflow_dispatch + ANTHROPIC_API_KEY secret + `bun install -g claude` (or whatever the actual install path is) + `bash scripts/eval.sh` + summary output
- [ ] Set repo secret `ANTHROPIC_API_KEY` if not already set
- [ ] Manually trigger first run: `gh workflow run eval-nightly.yml`
- [ ] Observe first run: record cost, wall-clock, any unexpected failures
- [ ] Verify failure-notification: corrupt one schema, trigger run, confirm failure surfaces; revert
- [ ] If observed cost > $2.25: open follow-up to cut cases or tighten prompts before V1 ship
- [ ] If observed wall-clock > 18 min: open follow-up to add more `xargs` parallelism or skip optional cases
- [ ] Update `TODOS.md`: mark eval harness DONE-V1 with link to F000013 and V2 trajectory note (scaffold/implement/qa skill cases, per-PR cadence, LLM-judge, schema consolidation, parser-logic unit tests)
- [ ] Update F000013 ROADMAP delivery history with workflow PR link

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. Nightly CI integration — wires the runner from S000023 + cases from S000024 into a recurring GitHub Actions workflow on main.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #72: v1.12.0 feat: F000013 V1 eval harness — S000023 runner + first case](https://github.com/jcl2018/claude-skills-templates/pull/72) — MERGED

## Files

<!-- Affected file paths. -->

- `.github/workflows/eval-nightly.yml` (new)
- `TODOS.md` (modified)
- `work-items/features/ops/testing/F000013_eval_harness_v1/F000013_ROADMAP.md` (modified — delivery history)

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
- 2026-05-09 [gates-update] Phase 3: /ship — PR #72,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #72,PRs section: linked PR #72 (MERGED).
