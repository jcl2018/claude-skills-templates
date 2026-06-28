---
name: "The --phase recap formatter on cj-goal-common.sh"
type: user-story
id: "S000112"
status: active
created: "2026-06-28"
updated: "2026-06-28"
parent: "F000068"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "3126f56d68344060a473da8c0a5b130a374d3d58"
    completed_at: "2026-06-28T19:45:39Z"
    test_rows_run: 7
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke-summary] green 5/5", "[qa-e2e-summary] green E1+E2", "[qa-audit] AUDITS=deferred", "[qa-pass] S000112"]
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Atomic story under F000068. DESIGN.md is a brief stub linking to the parent
     F000068_DESIGN.md; the parent's /office-hours session is the design context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/landing_recap_3part` (shipping in same PR as parent)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (N/A — atomic story)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

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

- [ ] `recap` is added to the `--phase` enum on `scripts/cj-goal-common.sh` with a `recap)` dispatch case and a `--when {before|after}` flag.
- [ ] The case prints a standardized labelled 3-part block to stdout: a header keyed off `--when` (BEFORE → "About to land …"; AFTER → "Landed …" / PR-stop → "PR opened …"), then **Delivered**, **How to E2E-test it**, **Next step** sections sourced from `--field delivered=`, `--field e2e=`, `--field next=`.
- [ ] It reuses the existing repeatable `--field KEY=VALUE` parsing the `telemetry` phase already has (print verbatim, no eval); a missing/unknown field renders an empty section rather than erroring.
- [ ] It is fail-soft: emits `PHASE=recap` + `PHASE_RESULT=ok`, exits 0; mutates nothing; writes no telemetry; never halts.
- [ ] The script's header-comment usage block is updated (the `--phase {…}` list gains `recap`; `--when` documented).
- [ ] `tests/cj-goal-common-recap.test.sh` exists, is hermetic (mirrors the existing `tests/cj-goal-common-*.test.sh` style), asserts all three labelled sections render, `--when before|after` header switching, fail-soft on missing fields, and exit 0.
- [ ] `spec/test-spec-custom.md` has a `units:` row for the new test (Check 24 reverse-sweep requires it); `scripts/test.sh` picks up the new test; `scripts/test-spec.sh --validate` + `--check-coverage` green.

## Todos

<!-- Actionable items for this story. -->

- [x] Add `recap` to the `--phase` enum + a `recap)` dispatch case + a `--when` flag on `scripts/cj-goal-common.sh`.
- [x] Reuse the telemetry-phase `--field` parsing; render the 3-part block; fail-soft on missing fields.
- [x] Update the script header-comment usage block.
- [x] Write `tests/cj-goal-common-recap.test.sh`.
- [x] Add the `units:` row to `spec/test-spec-custom.md` and confirm `scripts/test.sh` / `test-spec.sh --check-coverage` see it.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-28: Created. The `cj-goal-common.sh --phase recap` pure-formatter phase + its hermetic test + the test-spec units row.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/cj-goal-common.sh` (modified) — added `recap` to the `--phase` enum, the `--when` flag (default + arg-parse), the header-comment usage block, and the `recap)` dispatch case (pure formatter).
- `tests/cj-goal-common-recap.test.sh` (new) — hermetic test: S1 3-part block, S2 `--when` header switch, S3 fail-soft on missing field, S4 verbatim/no-eval `--field`.
- `spec/test-spec-custom.md` (modified) — added the `test-cj-goal-common-recap` `units:` row (Check 24 reverse-sweep).
- `scripts/test.sh` (modified) — the suite DOES hand-wire per-test banners, so added an explicit `bash tests/cj-goal-common-recap.test.sh` block after the portability test.

## Insights

<!-- Non-obvious findings worth remembering. -->

- The `telemetry` phase already implements the repeatable `--field KEY=VALUE` parsing — reuse it verbatim, do not re-invent. It prints values without eval, which is the safe escaping path for multi-line / special-char content.
- The block shape is verb-neutral; `--mode` is only for labelling/telemetry parity.

## Journal

- 2026-06-28 [impl-decision] `--when` with an unknown/empty value defaults to the AFTER header ("=== Landed / PR opened ==="). Resolves the SPEC Open Question on header strings: a recap with no `--when` is most usefully a "here is what happened" block, and the PR-stop verbs read the AFTER header as their at-PR recap.
- 2026-06-28 [impl-decision] Did NOT extend the shared `--mode` enum to add `todo_fix` — the todo verb already passes `--mode feature` for `--phase sync`/`portability-audit` (per CLAUDE.md), so recap follows the same convention; the block shape is verb-neutral and `--mode` is labelling-only here. Avoids touching the validation shared by all phases.
- 2026-06-28 [impl-finding] Reused the telemetry phase's exact split-on-first-`=` idiom (`_k="${kv%%=*}"` / `_v="${kv#*=}"`) and printed via `printf '%s'`, so `$(...)`, backticks, `$VAR`, and embedded newlines all render verbatim (verified by S4). No new escaping surface.
- 2026-06-28 [impl] Modified `scripts/cj-goal-common.sh` (recap phase + `--when` flag + enum + usage block), wrote `tests/cj-goal-common-recap.test.sh` (4 cases, 19 assertions, PASS), added the `test-cj-goal-common-recap` units row to `spec/test-spec-custom.md`, and hand-wired the test banner in `scripts/test.sh`. validate.sh green (0/0); test-spec.sh --validate OK + --check-coverage rows=70 findings=0; shellcheck clean; existing cj-goal-common tests still pass.
- 2026-06-28 [impl-auto] Auto-mode run (subagent context, no AUQ — approved autonomous build). The sensitive surface (scripts/, tests/, scripts/test.sh) would normally AUQ-gate; proceeded per the orchestrator directive.
- 2026-06-28 [impl-pass] S000112: implementation complete. Phase 2 implementer-owned gates transitioned.

<!-- Structured entries from the work-track journal command. -->

- [decision] The recap phase is a pure formatter. Summary: it computes no content, mutates nothing, writes no telemetry — it only renders the 3-part block from fields the agent passes in. Fail-soft (exit 0, empty section on missing field) so it can never halt a run.
- 2026-06-28 [qa-smoke] S1 (AC-1): green — `--phase recap --when before` with all three fields renders Delivered / How to E2E-test it / Next step (tests/cj-goal-common-recap.test.sh PASS).
- 2026-06-28 [qa-smoke] S2 (AC-2): green — `--when before` vs `--when after` produce different headers; both keep all three body sections.
- 2026-06-28 [qa-smoke] S3 (AC-4): green — omitting a `--field` renders an empty section and still exits 0 with PHASE_RESULT=ok (fail-soft).
- 2026-06-28 [qa-smoke] S4 (AC-3): green — special-char / command-substitution / backtick / $VAR / multi-line `--field` values render verbatim (no eval, no truncation).
- 2026-06-28 [qa-smoke] S5 (AC-5): green — test-spec.sh --validate (OK schema_version=1) + --check-coverage (OK coverage rows=70 findings=0); the new test resolves to exactly one units row.
- 2026-06-28 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending).
- 2026-06-28 [qa-e2e-run-start] RUN_ID=20260628-124539-68969 commit=3126f56
- 2026-06-28 [qa-e2e] E1 (AC-1, AC-2): green — live `cj-goal-common.sh --phase recap` renders two readable 3-part blocks; BEFORE header `=== About to land ===` vs AFTER `=== Landed / PR opened ===`, all three sections populated, PHASE_RESULT=ok, exit 0.
- 2026-06-28 [qa-e2e] E2 (AC-5): green — full `scripts/test.sh` ran `tests/cj-goal-common-recap.test.sh` (line 1336-1337 OK) and the whole suite passed (Failures: 0, RESULT: PASS, exit 0); validate.sh green (Errors: 0).
- 2026-06-28 [qa-e2e-summary] green (inline subagent; 0 rows parent-inline; 0 deferred): both E2E criteria green — recap renders for both points; full suite green with the new test.
- 2026-06-28 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom(present:test-cj-goal-common-recap),doc-spec-custom:none (Step 8.6a/8.6b ran inline; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-28 [qa-pass] S000112 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
