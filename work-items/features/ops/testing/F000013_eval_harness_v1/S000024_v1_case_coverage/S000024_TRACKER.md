---
name: "V1 eval case coverage (personal-workflow + system-health)"
type: user-story
id: "S000024"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000013"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: "S000023"
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/eval_harness_v1_cases` (or use parent's branch if shipping in same PR)
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
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `tests/eval/personal-workflow/check-step18-faithful-comma-split/` — fixture has multi-AC traceability cells (`AC-1, AC-2, AC-3`); schema asserts ac_coverage shape; case PASSES on a clean checkout AND FAILS when the S000022 parser fix is reverted on a test branch
- [ ] `tests/eval/personal-workflow/check-passing-feature/` — fixture is a canonical valid feature work-item; schema asserts overall=PASS, all checks=PASS
- [ ] `tests/eval/personal-workflow/check-missing-frontmatter/` — fixture has malformed frontmatter; schema asserts overall=FAIL with frontmatter check FAIL
- [ ] At least one more `personal-workflow` case covering a distinct check (e.g., template drift, lifecycle gate failure, traceability mismatch beyond Step 18) — total 4–5 personal-workflow cases
- [ ] `tests/eval/system-health/report-clean-system/` — fixture is a healthy state; schema asserts overall=PASS
- [ ] `tests/eval/system-health/report-with-issues/` — fixture has detectable health issues; schema asserts overall=DEGRADED with specific issue surfaced
- [ ] Total V1 case count between 6–10
- [ ] All cases pass `bash scripts/eval.sh` end-to-end
- [ ] S000022 caveat documented in `check-step18-faithful-comma-split/prompt.md` (in-line note that this tests "Claude executes the spec," not the parser logic itself)

## Todos

<!-- Actionable items for this story. -->

- [ ] Author `check-step18-faithful-comma-split` case (the S000022 regression case)
- [ ] Verify case fails on a test branch with the parser fix reverted (regression-detection proof)
- [ ] Author `check-passing-feature` case (canonical valid input)
- [ ] Author `check-missing-frontmatter` case
- [ ] Author 1–2 more personal-workflow cases (lifecycle drift, template mismatch, etc.)
- [ ] Author `report-clean-system` case for system-health
- [ ] Author `report-with-issues` case for system-health
- [ ] Run full suite via `bash scripts/eval.sh` and verify all 6–10 cases pass
- [ ] Add S000022 caveat note to `check-step18-faithful-comma-split/prompt.md`
- [ ] Verify schema reuse: lift any ≥2-case-shared shapes into `tests/eval/schemas/common-frags.json` if drift becomes painful (otherwise defer to V2)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. V1 case coverage — fills in the test cases that exercise personal-workflow + system-health behaviors against the runner that S000023 ships.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `tests/eval/personal-workflow/check-step18-faithful-comma-split/**` (new)
- `tests/eval/personal-workflow/check-passing-feature/**` (new)
- `tests/eval/personal-workflow/check-missing-frontmatter/**` (new)
- `tests/eval/personal-workflow/<additional-cases>/**` (new)
- `tests/eval/system-health/report-clean-system/**` (new)
- `tests/eval/system-health/report-with-issues/**` (new)
- `tests/eval/schemas/common-frags.json` (new, conditional on drift pressure)

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
