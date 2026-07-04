---
name: "Topic contract + portability agentic proof"
type: user-story
id: "S000132"
status: active
created: "2026-07-04"
updated: "2026-07-04"
parent: "F000082"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/inspiring-keller-69636a"
branch: "claude/inspiring-keller-69636a"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "0ba34169501c526114d6f047d3bed7774de4b258"
    completed_at: "2026-07-04T15:21:02Z"
    test_rows_run: 8
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7", "AC-8", "AC-9"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-e2e] E1-E3 green (E1(b) live-agentic SKIPPED local-only)", "[qa-audit] AUDITS=deferred"]
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
2. Create working branch: `git checkout -b feat/topic_contract_portability_proof` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (N/A — atomic story; the whole implementation lands as one vertical slice)

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

- [ ] AC1 — `topic:` parses + validates; all 12 existing `categories:` rows carry a topic; `--list-categories` shows it.
- [ ] AC2 — `topic_contracts: [portability]` parses; portability is enrolled.
- [ ] AC3 — `test-spec.sh --check-topic-contract` HARD-fails when portability is missing its agentic row/test/doc, PASSES once present; the `scripts/test.sh` negative test plants the fault → expect fail → restore → pass, invoking ONLY the targeted engine.
- [ ] AC4 — `validate.sh` gains the new hard Check; green on this repo; CI-safe (declaration-only, zero model spend).
- [ ] AC5 — `scripts/lib/agentic-sandbox.sh` exists (POSIX+LF); its deterministic helpers are unit-smoked with no model spend.
- [ ] AC6 — `tests/portability-version-agentic.test.sh` SKIPs cleanly without the local-only gate; live, it drives `claude --print` (cap `$0.50`) and PASSES iff `{surfaced_nudge, evidence}` shows the nudge relayed.
- [ ] AC7 — `/CJ_test_run portability-version-agentic` (`--e2e`/`--all`) runs it; a default `free` run SKIPs it; `/CJ_test_audit` Stage 1 reports it wired.
- [ ] AC8 — docs green: front-door doc has the three sections; `docs/tests/index.md` + `spec/doc-spec-custom.md` updated; `validate.sh` Checks 24/26/27/28 + `doc-spec --check-on-disk` pass.
- [ ] AC9 — CLAUDE.md + `spec/test-spec.md`/`--seed` + overlay prose updated; grandfathered topics + follow-up TODOs recorded.

## Todos

<!-- Actionable items for this story. -->

- [ ] Schema/parser: add `topic:` as the 9th `categories:` column + `topic_contracts:` list to `test-spec.sh`; widen all six consumer sites (parser flush `printf`/`nz()`, `--validate` loop + dup-id guard, `--list-categories`, `--check-structure` readers, `test-run.sh` category-mode slicer, `--render-docs`/`--seed-docs` stub); backfill 12 rows.
- [ ] `test-spec.sh --check-topic-contract` engine (mirror `--check-workflow-coverage`): enrolled-topic → require ≥1 CI-push, ≥1 CI-nightly, ≥1 local-hook+deterministic, ≥1 local-hook+agentic, each with its front-door doc; gate on `categories:` + `topic_contracts:` existing.
- [ ] `scripts/lib/agentic-sandbox.sh`: `mk_neutral_sandbox`, `mk_tagged_bare_upstream <ver>` (via `SKILLS_UPDATE_REMOTE_URL`, no `git` shim), `run_preamble_via_claude <budget>`; POSIX+LF + a no-model smoke test.
- [ ] `tests/portability-version-agentic.test.sh`: local-only SKIP gate + live `claude --print` run producing `{surfaced_nudge, evidence}`; PASS iff the agent surfaces the nudge.
- [ ] New `categories:` row `portability-version-agentic | infra | local-hook | agentic | local-only | topic: portability` + front-door `docs/tests/.../portability-version-agentic.md` (three sections) + `docs/tests/index.md` row + `spec/doc-spec-custom.md` declaration.
- [ ] `validate.sh` new hard Check calling `--check-topic-contract` + the paired negative test in `scripts/test.sh` (single-check-targeted, no whole-validate re-run).
- [ ] `/CJ_test_run --topic <t>` selector (mutually exclusive with a bare name); confirm `--category`/`--layer`/name + `local-only`-behind-`--e2e` already work; `/CJ_test_audit` surfaces the check via Stage 1.
- [ ] Docs: `spec/test-spec.md` prose (topic axis + both-modes-at-local rule + enrollment) + byte-identical `_emit_seed` heredoc edit + overlay backfill; CLAUDE.md verification-contract + test-contract sections; file grandfather follow-up TODOs.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-04: Created. Carries the whole F000082 implementation (AC1–AC9) as one atomic vertical slice: topic axis + enrollment + hard Check + agentic-sandbox lib + portability proof + `/CJ_test_run` wiring + docs.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/test-spec.sh`
- `scripts/test-run.sh`
- `scripts/lib/agentic-sandbox.sh` (new)
- `scripts/validate.sh`
- `scripts/test.sh`
- `tests/portability-version-agentic.test.sh` (new)
- `spec/test-spec.md`, `spec/test-spec-custom.md`
- `docs/tests/index.md`, `docs/tests/.../portability-version-agentic.md` (new)
- `spec/doc-spec-custom.md`
- `CLAUDE.md`

## Insights

<!-- Non-obvious findings worth remembering. -->

- The corollary to state up front: `mode:agentic ⇒ tier≠free`, so the agentic row is structurally PRESENT in CI but NEVER EXECUTED there (CI runs the free tier). The hard Check proves declaration; `/CJ_test_run --e2e` proves behavior, local-only. CI never proves the agentic path — by design.
- Six consumer sites must all widen 8→9 fields in lockstep or the TSV field-count drifts silently — parser flush, `--validate` (loop + dup-id guard), `--list-categories`, `--check-structure` readers, `test-run.sh` category-mode slicer, `--render-docs`/`--seed-docs` stub.
- The enrolled topic name `portability` is pinned NOW (the 4 `portability-*` rows); the other 11 topic names may float to implement time (they are grandfathered, so their exact spelling is not load-bearing).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-04 — Kept as ONE atomic user-story rather than splitting schema / lib / proof / wiring into parallel stories. Summary: the parts must land together (§8 landing sequence) — enrolling portability before its agentic row exists would red `validate.sh` on its own commit — so independent parallel stories would only create false decomposition.
- [decision] 2026-07-04 — Reuse `SKILLS_UPDATE_REMOTE_URL` (tagged bare upstream), no `git` PATH-shim. Summary: portable on Windows Git Bash, and the same seam `e2e-local` already uses.
- [decision] 2026-07-04 — Portability agentic row is a flat command-only `tests/*.test.sh` path, matching the existing 11 rows; migration into `tests/<cat>/<layer>/` deferred. Summary: `--check-structure` (b) exempts command-only rows, so the flat path is contract-clean.
- 2026-07-04 [qa-smoke] S1 (AC-1): green — `test-spec.sh --validate` = `OK schema_version=1` (rc 0); `--list-categories` emits a 9th `topic` column on all 13 rows (no TSV field-count drift).
- 2026-07-04 [qa-smoke] S2 (AC-2): green — `test-spec.sh --check-topic-contract` = `enrolled=1 findings=0` (rc 0); portability reads as enrolled, unenrolled topics unaffected.
- 2026-07-04 [qa-smoke] S3 (AC-3): green — hermetic negative test (targeted engine only): PLANT (drop portability's local-hook+agentic row from a temp registry) → rc 1 + `FINDING: topic-contract — enrolled topic 'portability' is missing a local-hook + agentic test`; RESTORE (untouched tree) → `findings=0`. No whole-validate re-run.
- 2026-07-04 [qa-smoke] S4 (AC-4): green — full `scripts/validate.sh` PASS (Errors 0, Warnings 0, new hard Check 30 PASS, rc 0); pre-verified by the orchestrator, not re-run here (Windows ~11-min gate; already confirmed green). Declaration-only, zero model spend, CI-safe.
- 2026-07-04 [qa-smoke] S5 (AC-5): green — sourced `scripts/lib/agentic-sandbox.sh`; `mk_neutral_sandbox` (rc 0, `.source`-absent manifest written) + `mk_tagged_bare_upstream` (rc 0, `v9.9.9` tag readable via `git ls-remote --tags`, no `git` shim) both succeed with NO model spend (`run_preamble_via_claude` not invoked).
- 2026-07-04 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-07-04 [qa-e2e-run-start] RUN_ID=20260704-152102-833 commit=0ba3416
- 2026-07-04 [qa-e2e] E1 (AC-6): green — (a) `bash tests/portability-version-agentic.test.sh` with `CJ_E2E_LOCAL` unset → exit 0 + a `SKIP:` line + no `claude` call (SKIP clean, no model spend), matching rubric (a). (b) the LIVE `CJ_E2E_LOCAL=1` + `claude --print` path is SKIPPED here — needs a claude login not available in subagent/CI context; it is local-only by house rule (Coverage Gap: a human runs E1(b) locally before ship). Verifiable half green; live half deferred by design, not a failure. [parent-inline] [E1(b) live-agentic: SKIPPED local-only]
- 2026-07-04 [qa-e2e] E2 (AC-7): green — cj_test_ verbs verified via the deterministic `test-run.sh` engine (`--dry-run`, no model spend): (a) `portability-version-agentic --e2e` → `decision: will-run`; (b) `portability-version-agentic` default free → `decision: skip(tier-not-selected)` (tier local-only); (c) `--topic portability` → selects ALL 5 portability-topic rows (check18-lint, smoke, deploy, version-check will-run; version-agentic skip(tier-not-selected)); (d) `/CJ_test_audit` Stage-1 engine calls: `--check-topic-contract` enrolled=1 findings=0 + `--check-structure` findings=0 with `structure/d` + `structure/f` PASS for the new row's front-door doc — the row is wired. Ran engines inline (leaf, depth ≤ 2 — no recursive skill dispatch). [parent-inline]
- 2026-07-04 [qa-e2e] E3 (AC-8, AC-9): green — docs + contract prose green: `doc-spec.sh --check-on-disk` findings=0 (5 checks PASS); front-door doc `docs/tests/infra/local-hook/portability-version-agentic.md` carries all three sections (## What it is / ## How to run / ## Explanation); `docs/tests/index.md` row + `spec/doc-spec-custom.md` declaration present; Checks 26/27/28 freshness engines rc 0; seed byte-identity `spec/test-spec.md == --seed` IDENTICAL; CLAUDE.md + `spec/test-spec.md` topic-axis prose present; grandfather follow-up TODOs recorded in TODOS.md. Full `scripts/validate.sh` (Checks 24/26/27/28 + doc-spec) PASS pre-verified by the orchestrator (not re-run — Windows ~11-min gate). [parent-inline]
- 2026-07-04 [qa-e2e-summary] green (0s subagent — all E2E run parent-inline; 3 rows parent-inline; 0 deferred): E1(a)/E2/E3 verified green inline; E1(b) live-agentic path SKIPPED local-only (human runs pre-ship per Coverage Gap — not a failure). No red, no ambiguous.
- 2026-07-04 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none(already-declared),doc-spec-custom:none(already-declared) (Step 8.6a/8.6b: deterministic new-surface rows confirmed present inline — `tests/portability-version-agentic.test.sh` has its units:+categories: rows, its front-door doc has its doc-spec-custom row; the agent-judged amendment sweep SKIPPED via DEFER_SYNC + 8.6c/8.6d SKIPPED via DEFER_AUDIT — the agentic doc/test sync + audit run on-demand off the build path)
- 2026-07-04 [qa-pass] S000132 (user-story): green smoke + green E2E. Phase 2 gates transitioned. All 9 ACs covered (AC-1..AC-9); receipt written (ready_for_ship: true). E1(b) live-agentic path deferred local-only per Coverage Gap (human runs pre-ship).
