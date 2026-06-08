---
name: "Standalone /CJ_document-release + general/custom doc-contract principle"
type: user-story
id: "S000097"
status: active
created: "2026-06-08"
updated: "2026-06-08"
parent: "F000055"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/sleepy-cerf-e8f24b"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "edda0d80f11988bd3c00d05dee9620a8fbec6b5c"
    completed_at: "2026-06-08T17:14:59Z"
    test_rows_run: 8
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries:
      - "[qa-smoke] S1 (AC-1): green"
      - "[qa-smoke] S2 (AC-2): green"
      - "[qa-smoke] S3 (AC-5): green"
      - "[qa-smoke] S4 (AC-4): green"
      - "[qa-smoke] S5 (AC-1,2,3,4,5): green"
      - "[qa-e2e] E1 (AC-2): green"
      - "[qa-e2e] E2 (AC-3): green"
      - "[qa-e2e] E3 (AC-1): green"
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_document_release_standalone_principle` (or use parent's branch if shipping in same PR)
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

- [ ] **Principle + front-table row:** `docs/philosophy.md` gains a new sibling principle under `## Topic: Deployment` stating the general/custom two-tier doc model + the portable any-repo pass + the wire-into-CI hook, with a matching front-table row; no work-item IDs; `validate.sh` Checks 19 + 20 green.
- [ ] **Catalog guard:** `skills/CJ_document-release/SKILL.md` Step 6.7.2 guards the `skills-catalog.json` read — catalog absent ⇒ one clean skip note (no `jq` stderr), skips the skill-MD audit half AND the `.cj-goal-feature/` scratch write; 6.7.1/6.7.3 incl. the human-doc no-work-item-ID lint still run; no new `set -e` abort.
- [ ] **gstack message:** the gstack-absent failure surfaces `[doc-sync-red]` at the Step 4→5 boundary naming "gstack `/document-release` not installed" as a possible cause (covers resolution-failure AND non-green; no programmatic probe).
- [ ] **Bookkeeping:** `CJ_document-release` portability stays `local-only` (not relabeled `workbench`); the Step 5.7 portability gate passes (no `[portability-red]`); USAGE.md drift (Check 14) resolved + new behavior noted.
- [ ] **CI recipe + smoke test:** `docs/architecture.md` documents the portable CI hook scoped honestly (`doc-spec.sh --validate` portable; declared⇔on-disk loop + `front_table` workbench-local); a new cold-repo smoke row in `tests/cj-document-release-config.test.sh` proves the Step 6.7.2 guard path (no `jq` error, no stray `.cj-goal-feature/` artifact). `scripts/test.sh` + `scripts/validate.sh` green.

## Todos

<!-- Actionable items for this story. -->

- [x] (a) Add the philosophy principle + front-table row.
- [x] (b) Add the Step 6.7.2 `skills-catalog.json` guard (skip skill-MD audit half + `.cj-goal-feature/` scratch write when catalog absent; preserve `$(…)`-capture / `|| true`).
- [x] (c) Add the Step 4→5 `[doc-sync-red]` gstack-absent message.
- [x] (d) Document the portable CI hook in `docs/architecture.md` (scoped honestly).
- [x] (e) Bump USAGE.md (Check 14) + re-confirm portability stays `local-only`.
- [x] (f) Add the cold-repo smoke row to `tests/cj-document-release-config.test.sh`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-08: Created. Single atomic story carrying all five deltas of the standalone-/CJ_document-release feature (F000055).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `docs/philosophy.md` (modified — new sibling principle under `## Topic: Deployment` + front-table row)
- `skills/CJ_document-release/SKILL.md` (modified — Step 6.7.2 catalog guard + Step 6.7.4 scratch-skip + Step 4→5 gstack-absent message + Error-Handling row)
- `skills/CJ_document-release/USAGE.md` (modified — new cold-run / standalone behavior documented + Check-14 last-updated bump)
- `docs/architecture.md` (modified — portable CI-hook recipe scoped honestly + cold-run guard note)
- `tests/cj-document-release-config.test.sh` (modified — new cold-repo guard smoke row #14)
- `skills-catalog.json` (verified — `CJ_document-release` portability unchanged: stays `local-only`; no edit)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The `skills-catalog.json`-absent path does NOT halt today (verified): `jq` exits 2 with a stderr `Could not open file` line, `SKILL_NAMES=$(…)` captures empty, the `for` loop runs zero times, and Step 6.7 (advisory) falls through. The fix only makes the skip explicit + clean and avoids the stray untracked `.cj-goal-feature/` artifact (not gitignored in a consumer repo).
- The guard gates ONLY the 6.7.2 skill-MD enumeration half. 6.7.1 + 6.7.3 stay live — including the human-doc no-work-item-ID lint (`doc-spec.sh --list-human-docs`-driven), which is the portable half.
- Portability TRENDS more portable (the guard removes one repo-local dependency) but stays `local-only` because the skill still hard-deps gstack + `_cj-shared` + `doc-spec.sh`.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Single atomic story (no task children). Summary: the five deltas are one cohesive change to the doc/skill enforcement surface; per WORKFLOW.md, tasks are optional and not warranted here.
- [finding] gstack-absent is a DIFFERENT mode from Step 5's "upstream returned non-green" — it surfaces as a `Skill(document-release)` resolution failure at Step 4. So the clarified message must live at the Step 4→5 boundary, not in a Step-5-only edit, to cover both cases.
- 2026-06-08 [impl-decision] Step 6.7.4 scratch write: wrapped the verdict block emit so it always goes to stdout (via a `/tmp` temp file `cat`) and only copies to `.cj-goal-feature/registered-doc-verdicts.md` when `CATALOG_PRESENT=true`. Rejected the alternative of gating only the `mkdir`/`tee` because the original used `tee` (which writes the file AND stdout in one call) — splitting stdout from the file write was the cleanest way to keep stdout unconditional while skipping the artifact in non-workbench mode.
- 2026-06-08 [impl-decision] Portability left as `local-only` with no `portability_requires` added. Per SPEC tradeoff: the guard REMOVES one repo-local dep (the unconditional `skills-catalog.json` read), so the skill trends more portable, not less; the audit still passes clean (`CJ_document-release | local-only | portable`, FINDINGS=0) because the remaining gstack + `_cj-shared` + `doc-spec.sh` deps already justify `local-only`. No catalog edit.
- 2026-06-08 [impl-finding] The Step 6.7.2 guard is agent-instruction prose in SKILL.md, not a standalone script, so the smoke row (test #14) reproduces the guard's exact bash (`if [ ! -f "$_CATALOG" ]` + the `CATALOG_PRESENT=false` scratch-skip) under `set -e` and asserts the three properties (exit 0, no `Could not open file` stderr, no stray `.cj-goal-feature/`), plus a grep that the SKILL.md still carries the guard literal — so removing the guard from the prose the agent executes fails the test.
- 2026-06-08 [impl-finding] `grep -c PATTERN file` prints `0` to stdout AND exits 1 on no-match, so an `|| echo 0` fallback double-appended ("0\n0") and broke the `[ -eq ]` integer test. Switched to `if grep -q ...; then _JQ_NOISE=1; else _JQ_NOISE=0; fi` (exit-code-driven, single value). Noted for the harness zsh/bash word-split + grep-exit gotchas.
- 2026-06-08 [impl] Implemented all 5 deltas: philosophy.md principle + front-table row; SKILL.md Step 6.7.2 catalog guard + Step 6.7.4 scratch-skip + Step 4→5 gstack-absent message + Error-Handling row; USAGE.md cold-run behavior + last-updated bump; architecture.md portable-CI-hook recipe + cold-run guard note; tests cold-repo smoke row #14. skills-catalog.json verified unchanged (local-only). New test row green (16/16 OK); portability audit FINDINGS=0.
- 2026-06-08 [impl-pass] S000097: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-08 [qa-smoke] S1 (AC-1): green — scripts/validate.sh RESULT: PASS (0 errors, 0 warnings); Check 19 PASS (no work-item refs in 4 human-docs), Check 20 PASS (philosophy.md opens with summary table); the new principle + front-table row are present.
- 2026-06-08 [qa-smoke] S2 (AC-2): green — bash tests/cj-document-release-config.test.sh exit 0, 16/16 OK incl. the new cold-repo guard row (no jq noise, no stray .cj-goal-feature/) + the SKILL.md Step 6.7.2 guard-literal row.
- 2026-06-08 [qa-smoke] S3 (AC-5): green — scripts/doc-spec.sh --validate run from a synthetic cold repo (seeded doc-spec.md, NO skills-catalog.json) prints "OK schema_version=1", exit 0. Portable mechanical guarantee holds cold.
- 2026-06-08 [qa-smoke] S4 (AC-4): green — CJ_document-release catalog portability == local-only (not relabeled workbench); PORTABILITY_STRICT=1 cj-portability-audit.sh exit 0, FINDINGS=0 (CJ_document-release | local-only | portable); cj-goal-common.sh --phase portability-audit emits PHASE_RESULT=ok, 0 [portability-red] markers.
- 2026-06-08 [qa-smoke] S5 (AC-1,2,3,4,5): green — scripts/test.sh RESULT: PASS, Failures: 0 (full suite incl. the new smoke row + USAGE Check-14 resolution); tree restored clean at HEAD.
- 2026-06-08 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-08 [qa-e2e-run-start] RUN_ID=20260608-101311-2639 commit=edda0d8
- 2026-06-08 [qa-e2e] E1 (AC-2): green — reproduced the SKILL.md Step 6.7.2 guard bash cold in a synthetic non-workbench repo (seeded doc-spec.md, no skills-catalog.json): exactly one clean skip note, CATALOG_PRESENT=false, exit 0 under set -e, EMPTY stderr (no "jq: Could not open file"); 6.7.4 scratch-skip left NO stray .cj-goal-feature/ artifact; 6.7.3 human-doc no-work-item-ref lint still ran cold (4 docs scanned, 0 stale). [parent-inline]
- 2026-06-08 [qa-e2e] E2 (AC-3): green — SKILL.md Step 4→5 boundary block (lines 405-418) distinguishes resolution-failure (gstack /document-release not installed) from non-green return and routes BOTH to the Step 5 [doc-sync-red] halt; the Step 5 message (line 430) names "gstack /document-release not installed" as a possible cause; no programmatic skill-presence probe added; Error-Handling row (line 686) carries the same cause + recovery. Runtime gstack-absence not force-able in-env; verified on the executed prose surface. [parent-inline]
- 2026-06-08 [qa-e2e] E3 (AC-1): green — docs/philosophy.md `### Two tiers, one portable pass` (line 152) reads as a sibling to `### The doc contract is one file` under `## Topic: Deployment` (explicit sibling framing line 177, not a duplicate); states the general/custom two-tier model + portable any-repo pass + wire-into-CI hook (doc-spec.sh --validate); matching front-table row (line 14); no work-item IDs (Check 19 PASS). [parent-inline]
- 2026-06-08 [qa-e2e-summary] green (0s subagent; 3 rows parent-inline; 0 deferred): all 3 E2E rows green — cold-run guard (E1), gstack-absent [doc-sync-red] message (E2), new philosophy principle in context (E3). Run inline per depth-≤2 constraint (mechanical doc-and-skill checks; no Agent subagent dispatched).
- 2026-06-08 [qa-pass] S000097 (user-story): green smoke + green E2E. Phase 2 gates transitioned. receipts.qa written (commit edda0d8, ac_ids_uncovered=[], ready_for_ship=true).
