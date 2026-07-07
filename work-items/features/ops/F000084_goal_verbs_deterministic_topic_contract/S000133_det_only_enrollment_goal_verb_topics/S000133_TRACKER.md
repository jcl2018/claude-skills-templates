---
name: "Deterministic-only enrollment seam + per-verb goal topics (chain drills + docs + enrollment)"
type: user-story
id: "S000133"
status: active
created: "2026-07-06"
updated: "2026-07-06"
parent: "F000084"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/festive-margulis-b0841b"
branch: "claude/festive-margulis-b0841b"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
receipts:
  qa:
    phase: 3
    commit: "c2cadc2e734cf0eedf6f2cfde4bb00d80127fee4"   # S000093: the SHA this receipt vouches for (HEAD; implementation staged uncommitted in the worktree)
    completed_at: "2026-07-06T21:27:17Z"
    test_rows_run: 12                        # 7 smoke (S1-S7) + 5 E2E (E1-E5), all executed this run
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7", "AC-8", "AC-9", "AC-10", "AC-11"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []        # every changed script/spec surface is anchored by a units: row (Check 24 green) or is a generated/doc surface
    journal_entries: ["[qa-smoke] S1-S7 green", "[qa-e2e] E1-E5 green (run INLINE — leaf subagent, no nested dispatch)", "[qa-audit] AUDITS=deferred (DEFER_AUDIT + DEFER_SYNC)"]
    ready_for_ship: true                     # GREEN per the fail-closed verdict: smoke green + E2E green + no uncovered ACs
    next_legal: ["ship"]
    note: "E2E rows E1-E5 run INLINE in the QA runner's own context (S000093 receipts.qa mechanism); this box has no claude CLI, so no paid/agentic/local-only row was executed — none is required (goal-* topics are enrolled deterministic-only). AUDITS deferred per DEFER_AUDIT:true + DEFER_SYNC:true (agent-judged doc/test audit + agentic overlay sweep run on-demand off the build path)."
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (This atomic story derives directly from
     the parent feature's /office-hours session — the parent's design is the
     context; this DESIGN.md is a brief stub linking to it.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/det_only_enrollment_goal_verb_topics` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (N/A — atomic story: one coherent PR; the design's step order is the internal sequence, not parallel sub-units)

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

- [ ] AC-1 — `topic_contracts_deterministic:` parses (same `[a-z0-9-]+` slug grammar as `topic_contracts:`); `test-spec.sh --validate` rejects an invalid slug AND a topic duplicated across the two enrollment lists (cross-list guard).
- [ ] AC-2 — the det-only arm of `--check-topic-contract` HARD-requires three points per det-enrolled topic (≥1 `CI-push` + ≥1 `CI-nightly` + ≥1 `local-hook`+`deterministic`, each with its front-door doc) and tolerates-but-never-requires agentic rows; the `topic_contracts:` four-point both-modes arm is byte-for-byte unchanged for `portability`.
- [ ] AC-3 — `_run_topic_contract` AND `_run_topic_docs` treat "either enrollment list non-empty" as active and iterate the UNION (each topic under its own list's rule); the `topic contract: enrolled=N findings=M` summary format is kept with `enrolled=` counting the union; the `^(REGISTRY=absent|topic contract inactive)` grep contracts still match for consumer repos with neither list.
- [ ] AC-4 — the `spec/test-spec.md` topic-axis prose gains the deterministic-only flavor, mirrored byte-identically into `_emit_seed` (seed-identity test green).
- [ ] AC-5 — the 3-arm `scripts/test.sh` negative drill passes: arm 1 (remove a det-enrolled topic's CI-nightly row → expect the finding), arm 2 (remove a re-topic'd agentic eval row → det-enrolled topics stay green), arm 3 (hide a det-enrolled topic's dream doc via `TESTDOC_OUT` → expect the topic-docs finding) — engine-only invocations against temp registry/docs copies.
- [ ] AC-6 — `tests/cj-goal-defect-smoke.test.sh` passes: worktree entry (`cj-worktree-init.sh --caller defect` → `cj-def-*`), shared-plumbing dispatch (`cj-goal-common.sh --phase worktree|ship|telemetry --mode defect`), workbench-owned leaf-dispatch targets on disk (CJ_qa-work-item, CJ_document-release; /investigate + /ship not asserted — gstack).
- [ ] AC-7 — the 3 chain drills pass in temp clones per the design's chain-step contracts (feature: worktree → sync `--no-sync` skipped → pr-check → e2e-gate inactive/continue under double guard → recap after → cleanup dry-run; task: worktree → `cj-task-scaffold.sh` T-ID mint + `type: task` shape → recap → cleanup dry-run; defect: worktree → `cj-id-claim.sh --prefix D --floor <N> --dry-run` → pr-check → recap before+after pair → `POST_LAND_SYNC_MANIFEST=<temp fixture> post-land-sync.sh --dry-run` → cleanup dry-run); `TEST_FAST=1 bash scripts/test.sh` SKIPs all 3, a full `test.sh` runs them.
- [ ] AC-8 — 11 `categories:` rows land (9 NEW: `goal-feature-smoke`/`goal-feature-chain`/`goal-feature-gate-seam`, `goal-task-scaffold`/`goal-task-chain`/`goal-task-e2e-det`, `goal-defect-smoke`/`goal-defect-chain`/`goal-defect-land-sync` — all `category: workflow` + `mode: deterministic` + `tier: free`; 2 re-topic'd: `goal-feature-eval`/`goal-task-eval` keep `workflow`/`agentic`/`paid`, only `topic:` + doc prose change) + a `units:` row per NEW script; `cj-goal-eval` no longer appears in the registry; `--check-structure` green.
- [ ] AC-9 — Check-31 surfaces land: `docs/goals/goal-{feature,task,defect}.md` dream docs (end goal + the properties the three required points realize + the named deterministic-only posture) + `docs/tests/topics/goal-{feature,task,defect}/` subdirs (`index.md` referencing the dream doc + `CI-push.md` + `CI-nightly.md` + `local-hook.md`) + 9 front-door docs with the three literal sections; all declared in `spec/doc-spec-custom.md`; no work-item IDs in any human-doc.
- [ ] AC-10 — prose truthfulness sweeps land: `scripts/test.sh` TEST_FAST guard comment + `spec/test-spec-custom.md` "skips the heavy test-deploy suite" prose + the `test-deploy` row `purpose:` name the chain drills; the `topic_contracts:` header comment reflects the two lists + the retired `cj-goal-eval` label; Check 30/31 `units:` purposes + the `validate.sh` Check 30 banner state the two-list model.
- [ ] AC-11 — enrollment lands LAST (`topic_contracts_deterministic: [goal-feature, goal-task, goal-defect]`); `--check-topic-contract` + `--check-topic-docs` green for all four enrolled topics; catalogs regenerated; `validate.sh` fully green; CLAUDE.md line + TODOS hygiene rows (PARTIAL mark, todo_fix follow-up, agentic-removal row enumerating the Check 28/24 + portability blockers) written.

## Todos

<!-- Actionable items for this story. -->

- [x] Engine seam: parse `topic_contracts_deterministic:` + cross-list duplicate guard in `--validate`.
- [x] Det-only arm in `--check-topic-contract` (three required points; agentic tolerated).
- [x] Union iteration + inactive-gate rework in `_run_topic_contract` + `_run_topic_docs` (~lines 1329-1332 / 1382-1384 / 1414-1417 / 1456-1458), preserving summary-line + grep contracts.
- [x] `spec/test-spec.md` prose + `_emit_seed` dual-write (byte-identical).
- [x] 3-arm negative drill in `scripts/test.sh` (engine-only, temp copies).
- [x] `tests/cj-goal-defect-smoke.test.sh` (CI-push mirror of the feature smoke, defect shape).
- [x] `tests/goal-feature-chain.test.sh` + `tests/goal-task-chain.test.sh` + `tests/goal-defect-chain.test.sh` (CI-nightly, temp clones) + `scripts/test.sh` registration under `TEST_FAST=1`.
- [x] 11 `categories:` rows + `units:` rows for the 4 new scripts; retire the `cj-goal-eval` label.
- [x] 9 front-door docs + verify whether the 2 re-topic'd eval docs need prose edits.
- [x] 3 dream docs + 3 topic subdirs (index + 3 layer pages each); declare in `spec/doc-spec-custom.md`.
- [x] TEST_FAST prose sweep + `topic_contracts:` header rewrite + Check 30/31 self-describing surfaces.
- [x] Enroll the three topics LAST; regenerate catalogs (`test-spec.sh --render-docs`, `workflow-spec.sh --render-docs`); README regen if counts change.
- [x] CLAUDE.md one-liner; TODOS.md hygiene (PARTIAL + follow-up + removal-blockers rows).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Single atomic story carrying all four parts of F000084: the deterministic-only enrollment seam, the 4 new deterministic tests, the 11 categories rows, and the Check-31 doc surfaces + enrollment.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/test-spec.sh` — parser + det-only arm + union iteration + `_emit_seed`
- `spec/test-spec.md` — topic-axis prose (dual-write)
- `spec/test-spec-custom.md` — categories/units rows + enrollment + header/purpose prose
- `scripts/validate.sh` — Check 30 banner text
- `scripts/test.sh` — 3-arm drill + chain-drill registration + guard comment
- `tests/cj-goal-defect-smoke.test.sh`, `tests/goal-feature-chain.test.sh`, `tests/goal-task-chain.test.sh`, `tests/goal-defect-chain.test.sh` — NEW
- `docs/goals/goal-{feature,task,defect}.md`, `docs/tests/topics/goal-{feature,task,defect}/**`, `docs/tests/workflow/**` — NEW doc surfaces
- `spec/doc-spec-custom.md`, `CLAUDE.md`, `TODOS.md` — declarations + hygiene
- `docs/test-catalog.md`, `docs/tests/index.md`, `docs/tests/test.md`, `docs/tests/validate.md` — regenerated catalogs (`test-spec.sh --render-docs`)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The union-iteration rework is what makes the new list REAL: without it, both engine runners bail "topic contract inactive" when `topic_contracts:` alone is consulted, and Checks 30/31 stay green vacuously for the three new topics.
- `cj-id-claim.sh` usage-errors without `--floor`; the defect chain drill must pass `--prefix D --floor <N> --dry-run`. `POST_LAND_SYNC_MANIFEST` is the documented hermetic seam for the land-tail preview.
- The chain drills reach only helper SCRIPTS — the agent-executed `pipeline.md` prose is structurally out of reach for deterministic tests (accepted; named in the dream docs).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Single atomic story (no task children). Summary: the work is one coherent PR with a strict internal ordering (engine seam → tests → rows/docs → enrollment LAST); decomposing into parallel tasks would fight the ordering constraint.
- [decision] 2026-07-06 — Enrollment is the LAST edit inside the PR. Summary: enrolling before the coverage points + doc surfaces exist reds Checks 30/31 on the landing commit.
- 2026-07-06 [qa-e2e-run-start] RUN_ID=20260706-212717-qa commit=c2cadc2
- 2026-07-06 [qa-smoke] S1 (AC-1): green — test-spec.sh --validate → OK schema_version=1; topic_contracts_deterministic: parses; invalid-slug + cross-list-duplicate fixtures each fail with a named [test-spec-no-config] error.
- 2026-07-06 [qa-smoke] S2 (AC-2, AC-10): green — --check-topic-contract → enrolled=4 findings=0 (det arm: goal-feature/goal-task/goal-defect three points each; both-modes arm: portability unchanged, four points — verified it still bites when its agentic point is removed).
- 2026-07-06 [qa-smoke] S3 (AC-3, AC-5): green — union activation + 3-arm negative drill run foreground engine-only: arm1 (remove goal-defect CI-nightly row) → finding + non-zero; arm2 (remove re-topic'd goal-feature-eval agentic row) → stays green findings=0; arm3 (hide goal-task dream doc via TESTDOC_OUT) → topic-docs finding + non-zero. absent-registry → REGISTRY=absent; no-axis → "topic contract inactive".
- 2026-07-06 [qa-smoke] S4 (AC-4): green — seed identity: spec/test-spec.md byte-identical to test-spec.sh --seed (SEED_IDENTICAL) after the topic-axis prose edit.
- 2026-07-06 [qa-smoke] S5 (AC-6): green — all 4 new scripts PASS standalone: cj-goal-defect-smoke (5 cases), goal-feature-chain (6 steps), goal-task-chain (4 steps), goal-defect-chain (6 steps incl. land-tail).
- 2026-07-06 [qa-smoke] S6 (AC-7): green — --check-structure (a-f all PASS, 39 scripts, matrix full) + full validate.sh RESULT: PASS 0 errors; no cj-goal-eval in the registry.
- 2026-07-06 [qa-smoke] S7 (AC-8): green — --check-topic-docs → enrolled=4 findings=0 + doc-spec.sh --check-on-disk → 5 checks PASS 0 findings; dream docs + topic subdirs declared, no work-item IDs in any human-doc.
- 2026-07-06 [qa-smoke-summary] green: 7/7 non-manual rows green (0 manual rows pending)
- 2026-07-06 [qa-e2e] E1 (AC-10): green [inline] — full validate.sh from worktree root after enrollment → all checks green incl. 24/26/27/28/30/31, RESULT: PASS 0 errors (1 pre-existing docs/goals orphan-dir WARNING, non-blocking).
- 2026-07-06 [qa-e2e] E2 (AC-6): green [inline] — cadence split asserted directly: TEST_FAST=1 SKIPs all 3 chain drills (scripts/test.sh:1930); the full-run else-branch registers + runs goal-feature/task/defect-chain (:1932/:1940/:1948), each PASS standalone.
- 2026-07-06 [qa-e2e] E3 (AC-2, AC-5): green [inline] — scratch registry copy with the goal-feature-eval row deleted → --check-topic-contract stays enrolled=4 findings=0 (agentic-removal robustness; only doc/index prose reference the deleted row, not Check 30).
- 2026-07-06 [qa-e2e] E4 (AC-8, AC-9): green [inline] — maintainer legibility walk: docs/goals/goal-defect.md states the end goal + deterministic-only posture; topics/goal-defect/index.md references the dream doc; CI-nightly.md names the drill + how-to-run; the documented command (bash tests/goal-defect-chain.test.sh) passes.
- 2026-07-06 [qa-e2e] E5 (AC-7, AC-10): green [inline] — registry truthfulness: grep "cj-goal-eval" spec/ → nothing (retired); the topic_contracts header + Check 30/31 unit purposes + TEST_FAST prose all state the two-list model and name the chain drills.
- 2026-07-06 [qa-e2e-summary] green (inline; 0s subagent — E2E run in the QA runner's own context per S000093, no nested dispatch; 5 rows; 0 deferred): all 5 E2E criteria green; tracker journal updated.
- 2026-07-06 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom+11rows+4units,doc-spec-custom+29docs (Step 8.6a/8.6b: deterministic new-surface rows verified present inline; the agent-judged amendment sweep SKIPPED via DEFER_SYNC + 8.6c/8.6d SKIPPED via DEFER_AUDIT — the agentic doc/test sync + audit run on-demand off the build path)
- 2026-07-06 [qa-pass] S000133 (user-story): green smoke (7/7) + green E2E (5/5, run INLINE). Phase 2 QA-owned gates transitioned. All 11 ACs covered (AC-1..AC-11); receipt written (ready_for_ship: true, commit c2cadc2). No paid/agentic/local-only row executed — this box has no claude CLI and none is required (goal-* topics enrolled deterministic-only).
