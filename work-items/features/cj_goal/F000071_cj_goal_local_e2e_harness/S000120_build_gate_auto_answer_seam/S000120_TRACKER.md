---
name: "Build-gate auto-answer seam (dormant, CI-green)"
type: user-story
id: "S000120"
status: active
created: "2026-06-30"
updated: "2026-06-30"
parent: "F000071"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-happy-e2e"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "c8315d03ecf8165b31cf5447f6952ab789ff9a8a"
    completed_at: "2026-07-01T00:38:29Z"
    test_rows_run: 8
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["qa-smoke S1-S5 green", "qa-e2e E1-E3 green", "qa-audit deferred"]
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Prerequisite: the parent feature F000071's /office-hours session is the
     design context for this atomic story; DESIGN.md links to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/build_gate_auto_answer_seam` (or use parent's branch if shipping in same PR)
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

- [ ] `scripts/cj-e2e-gate.sh --gate <design-gate|qa-audit> [--digest <...>]` prints exactly one of `AUTO=continue|halt|inactive` from guard + allowlist + green-digest logic (pure, deterministic, no Claude).
- [ ] With BOTH `CJ_GOAL_E2E_AUTO=1` AND `.cj-e2e-sandbox` present: an allowlisted gate with a green digest (`doc:ok,test:ok`) → `continue`; with findings → `halt`; a non-allowlisted gate id → `inactive`.
- [ ] With only the flag, or only the marker (guard incomplete): any gate → `inactive` (the AUQ fires unchanged — a normal run is behavior-unchanged).
- [ ] The four cj_goal pipelines (`CJ_goal_feature`, `CJ_goal_task`, `CJ_goal_defect`, `CJ_goal_todo_fix`) carry uniform seam prose at their qa-audit AUQ step (and `CJ_goal_feature` additionally at its design-gate step) that runs the helper first and branches: `continue` → skip AUQ + print `[E2E-AUTO]` banner + proceed; `halt` → `[qa-audit-declined]`; `inactive` → fire the AUQ unchanged.
- [ ] `.cj-e2e-sandbox` is `.gitignore`d AND a `validate.sh` marker-absence check HARD-fails if `.cj-e2e-sandbox` is in the tracked tree.
- [ ] `tests/cj-e2e-gate.test.sh` asserts the full verdict matrix (flag-only→inactive, marker-only→inactive, both+green→continue, both+findings→halt, non-allowlisted-gate→inactive), wired as a `family: test` units row + a `scripts/test.sh` runner block, plus the new validate check gets a parallel `zzz-test-scaffold` fixture row.
- [ ] CI-green: `validate.sh` 0 errors; `test.sh` green; a normal run is behavior-unchanged.

## Todos

<!-- Actionable items for this story. -->

- [x] Write `scripts/cj-e2e-gate.sh` (verdict helper: guard + allowlist + green-digest logic).
- [x] Add the uniform seam prose to the qa-audit AUQ step in all four pipelines + the design-gate step in `CJ_goal_feature` (generalizing `--quiet`).
- [x] Add `.cj-e2e-sandbox` to `.gitignore`.
- [x] Add the `validate.sh` marker-absence check (Check 29) (+ its `zzz-test-scaffold` fixture row in `scripts/test.sh`).
- [x] Write `tests/cj-e2e-gate.test.sh` (deterministic verdict matrix); wire a `family: test` units row + a `scripts/test.sh` runner block.
- [x] Add the test-hierarchy doc note (the `docs/tests/test-hierarchy.md` row for this seam).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-30: Created. Part A of F000071 — the dormant, CI-green build-gate auto-answer seam + its non-activation proof.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/cj-e2e-gate.sh` (new)
- `scripts/validate.sh` (modified — marker-absence check)
- `scripts/test.sh` (modified — test runner block + zzz-test-scaffold fixture row)
- `tests/cj-e2e-gate.test.sh` (new)
- `skills/CJ_goal_feature/pipeline.md` (modified — design-gate + qa-audit seam prose)
- `skills/CJ_goal_task/pipeline.md` (modified — qa-audit seam prose)
- `skills/CJ_goal_defect/pipeline.md` (modified — qa-audit seam prose)
- `skills/CJ_goal_todo_fix/pipeline.md` (modified — qa-audit seam prose)
- `.gitignore` (modified — `.cj-e2e-sandbox`)
- `docs/tests/test-hierarchy.md` (modified — test-hierarchy note; hand-authored, edited in place)
- `spec/test-spec-custom.md` (modified — `family: test` units row for `tests/cj-e2e-gate.test.sh` + `validate-check-29` row)
- `docs/test-catalog.md` (modified — regenerated by `test-spec.sh --render-docs` after the two new units rows; Check 26)
- `docs/tests/test.md` (modified — regenerated test-family catalog page)
- `docs/tests/validate.md` (modified — regenerated validate-family catalog page)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The gates are agent-emitted `AskUserQuestion` calls (prose in pipeline.md), NOT shell — a shell helper cannot suppress them. So the seam is split: a pure deterministic verdict helper (`AUTO=continue|halt|inactive`) + agent-prose in each pipeline AUQ step that runs the helper first and branches on its verdict.
- The qa-audit auto-continue REUSES `todo_fix --quiet`'s existing predicate (continue ONLY on `doc:ok,test:ok`, HALT on findings, NEVER auto-waive), widened to fire on `QUIET=1 OR (CJ_GOAL_E2E_AUTO=1 AND marker)` — ONE path, two triggers.
- The new `validate.sh` check needs a parallel `zzz-test-scaffold` fixture row in `scripts/test.sh` — the recurring implement blind spot (every new validate check has historically forgotten this parallel edit).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Scope = Part A ONLY. Summary: this story is the dormant, CI-green seam + its non-activation proof; the harness (Part B) and the workflow docs (Part C) are tracked follow-on on the parent feature F000071, deliberately NOT pulled into this story's SPEC/TEST-SPEC.
- [decision] Helper home is a standalone `scripts/cj-e2e-gate.sh`, not a `cj-goal-common.sh` phase. Summary: simplest to unit-test as a pure deterministic verdict function (Open Question 3 in the design, resolved).
- 2026-06-30 [impl-decision] Resolved SPEC Open Question 2: the `[E2E-AUTO]` banner is printed by the pipeline prose on a `continue` verdict (not by the helper), keeping `scripts/cj-e2e-gate.sh` a pure stdout-only verdict function. Digest format the helper parses is the existing `doc:ok,test:ok` form (substring-matched: continue requires BOTH `doc:ok` AND `test:ok`).
- 2026-06-30 [impl-decision] The new validate check is Check 29 (next free number after Check 28). Engine is `git ls-files` (committed/staged tree), so a gitignored-but-present marker in a sandbox passes cleanly; only a TRACKED marker hard-fails.
- 2026-06-30 [impl-finding] The two new units rows (`validate-check-29` + `test-cj-e2e-gate`) triggered Check 24's reverse coverage cross-check (new live surfaces with no registry row) AND Check 26 (stale generated catalog). Resolved by adding both rows (work-item-ID-free in rendered label/purpose fields per the test-spec validator) and running `test-spec.sh --render-docs` (which respects the `_HANDAUTHORED_TESTDOCS` carve-out, so `docs/tests/test-hierarchy.md` was NOT regenerated).
- 2026-06-30 [impl-finding] Seam prose is uniform across the 4 qa-audit sites: 4 byte-identical helper-invocation lines (`--gate qa-audit --digest "$AUDITS"`), one per pipeline (`CJ_goal_feature` Step 3.4, `CJ_goal_task` Step 4.5, `CJ_goal_defect` Step 8.5, `CJ_goal_todo_fix` SKILL.md checkpoint); plus 1 design-gate invocation in `CJ_goal_feature` Step 2.7 only. The auto-continue path generalizes `--quiet` into `QUIET=1 OR (helper says continue)`.
- 2026-06-30 [impl] Wrote 2 files (`scripts/cj-e2e-gate.sh`, `tests/cj-e2e-gate.test.sh`); modified 9 (4 pipeline surfaces, `scripts/validate.sh`, `scripts/test.sh`, `.gitignore`, `spec/test-spec-custom.md`, `docs/tests/test-hierarchy.md`) + 3 regenerated catalog files. shellcheck clean across `scripts/*.sh scripts/skills-deploy scripts/skills-update-check`; `validate.sh` 0 errors / 0 warnings.
- 2026-06-30 [impl-pass] S000120: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-30 [qa-smoke] S1 (AC-1, AC-7): green — `bash tests/cj-e2e-gate.test.sh` ALL PASS (12 cases incl. helper prints exactly one verdict line); exit 0.
- 2026-06-30 [qa-smoke] S2 (AC-2): green — flag-only→inactive AND marker-only→inactive asserted by the matrix (dormant under an incomplete guard); part of the ALL-PASS run, exit 0.
- 2026-06-30 [qa-smoke] S3 (AC-3): green — both guards + non-allowlisted gate id (ship/merge/land)→inactive asserted (build-gates-only allowlist, never matches ship/merge/deploy); exit 0.
- 2026-06-30 [qa-smoke] S4 (AC-4): green — both guards + qa-audit: green digest→continue; doc/test/empty findings digest→halt (green-only continue, never auto-waive); exit 0.
- 2026-06-30 [qa-smoke] S5 (AC-6): green — `bash scripts/validate.sh` 0 errors / 0 warnings; Check 29 PASS (`.cj-e2e-sandbox` not tracked — marker cannot ship); exit 0.
- 2026-06-30 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending).
- 2026-06-30 [qa-e2e-run-start] RUN_ID=20260630-173658-10404 commit=c8315d0
- 2026-06-30 [qa-e2e] E1 (AC-5): green — guard-absent (no CJ_GOAL_E2E_AUTO, no .cj-e2e-sandbox) → helper returns AUTO=inactive for BOTH qa-audit and design-gate; the AUQ fires unchanged (normal run behavior-unchanged). Verified inline via `scripts/cj-e2e-gate.sh` (nested-subagent wall — no sub-subagent). [parent-inline]
- 2026-06-30 [qa-e2e] E2 (AC-4, AC-5): green — full guard (CJ_GOAL_E2E_AUTO=1 + .cj-e2e-sandbox in an isolated sandbox): qa-audit green digest → continue; doc-findings AND test-findings → halt (never auto-waive); design-gate → continue. Pipeline prose in all 4 pipelines branches continue→skip AUQ + `[E2E-AUTO]` banner, halt→`[qa-audit-declined]` (grep-confirmed). [parent-inline]
- 2026-06-30 [qa-e2e] E3 (AC-3): green — full guard + non-allowlisted gate ids (ship, merge, land, land-and-deploy, deploy, document-release) ALL → AUTO=inactive; the seam never auto-answers a ship/merge/deploy gate (allowlist is {design-gate, qa-audit} only). [parent-inline]
- 2026-06-30 [qa-e2e-summary] green (0s subagent; 3 rows parent-inline; 0 deferred): E1/E2/E3 all green — deterministic seam verified inline (guard-absent→inactive, full-guard green→continue/findings→halt, ship/merge/deploy→inactive). Pipeline-prose branch wiring grep-confirmed across all 4 pipelines.
- 2026-06-30 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none(2 units rows already added by implement — coverage findings=0),doc-spec-custom:none (Step 8.6a/8.6b ran inline; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-30 [qa-pass] S000120 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
