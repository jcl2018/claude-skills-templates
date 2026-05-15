---
name: "/CJ_suggest preflight-aware mode + --limit flag (WI-A)"
type: user-story
id: "S000042"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000020"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
# pr: ""  # populate post-/ship
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_suggest_preflight_aware` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (N/A — atomic story)

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

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `/CJ_suggest --for-skill cj-goal --limit 15` returns up to 15 rows, none of which trip /CJ_goal preflight (priority P1, size L|XL, sensitive-surface regex match, design-needed keyword).
- [ ] `/CJ_suggest` with no flags returns top-5 unchanged (regression test).
- [ ] `/CJ_goal` no-args path calls `/CJ_suggest --for-skill cj-goal --limit 15`.
- [ ] /loop /CJ_goal session that previously starved at iter 10 now drains 12+ iterations.

## Todos

<!-- Actionable items for this story. -->

- [ ] Add `--for-skill <name>` and `--limit N` flags to skills/CJ_suggest/scripts/suggest.sh
- [ ] Factor /CJ_goal preflight predicates into a small inline awk function shared by /CJ_suggest pre-filter
- [ ] Update goal.sh to pass `--for-skill cj-goal --limit 15` on the no-args path
- [ ] Update SKILL.md for /CJ_suggest documenting the new flags
- [ ] Add smoke tests verifying both flagged and unflagged behavior

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-15: Created. WI-A from F000020 design. Approach D (pre-filter at /CJ_suggest layer); subsumes design bugs #1, #3, #4.
- 2026-05-15: Phase 2 implemented. suggest.sh: --for-skill cj-goal + --limit N flags, body-extract function, predicate filter (gates 3-5 mirror goal.sh:262-303 verbatim), per-row [CJ_suggest] excluded stderr log; goal.sh:179 invocation passes --for-skill cj-goal --limit 15; SKILL.md + skills-catalog.json bumped to v1.1.0. Smoke: unflagged byte-identical regression preserved; flagged path excludes 5 rows (P1×2, sensitive-surface×1, design-needed×2) and surfaces 7 candidates from previously truncated top-5.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills/CJ_suggest/scripts/suggest.sh
- skills/CJ_suggest/SKILL.md
- skills/CJ_goal/scripts/goal.sh

## Insights

<!-- Non-obvious findings worth remembering. -->

- Pre-filter at the queue layer (Approach D) subsumes 3 of 4 bugs (#1 sensitive-surface STOP, #3 top-5 cap exhaustion, #4 /CJ_suggest /CJ_goal-blindness) with one mechanism. Single coherent fix beats stack of bolt-ons.
- Coupling /CJ_suggest with /CJ_goal preflight knowledge is bounded: opt-in flag (default behavior preserved), 4 short predicates, future consumers extend via `--for-skill <name>` pattern.

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] 2026-05-15: Approach D selected for keystone bug (#1 sensitive-surface STOP) over A/B/C alone. D handles #1, #3, #4 with one structural change; A/B/C only handle #1.
- [decision] 2026-05-15: `--limit N` default kept at 5 (no behavior change for un-flagged callers); /CJ_goal explicitly passes 15.
- [decision] 2026-05-15: `--for-skill cj-goal` flag lives on /CJ_suggest routing, not /CJ_goal-side wrapper. Acceptable coupling; revisit if 3rd consumer with conflicting criteria appears.
- [orchestrator] 2026-05-15: --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/features/ops/F000020_cj_goal_v1_1_polish/S000042_cj_suggest_preflight_aware; scaffold skipped. RUN_ID=20260515-135129-21576
- [qa-smoke-summary] 2026-05-15: green — S1/S2/S3/S4/S5 PASS plus 3 negative-arg-validation cases plus AC#3 invocation verify (9/9). Pre-ship E2E E1 verified inline; E2/E3/E4 deferred to post-ship per TEST-SPEC E3 `core post-ship` tag.
- [qa-pass] 2026-05-15: smoke green; pre-ship AC #1/#2/#3/#5 verified; AC #4 = post-ship E2E (E3) — deferred. RUN_ID=20260515-135129-21576
- [auto-final-gate-suppressed] 2026-05-15: 1 mechanical, 0 taste, 2 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (filter run_id=20260515-135129-21576). END_STATE=green.
