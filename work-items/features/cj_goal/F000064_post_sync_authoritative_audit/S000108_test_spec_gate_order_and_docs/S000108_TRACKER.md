---
name: "test-spec gate-order swap + docs + the three named tests"
type: user-story
id: "S000108"
status: active
created: "2026-06-13"
updated: "2026-06-13"
parent: "F000064"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/friendly-sinoussi-cef30d"
blocked_by: "S000107"
---

<!-- Atomic story: derives directly from the parent feature's /office-hours session.
     Parent's design is sufficient context; DESIGN.md is a brief stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/post_sync_authoritative_audit` (or use parent's branch if shipping in same PR)
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

- [ ] `spec/test-spec-custom.md` swaps the `qa-audit` / `doc-sync` gate `order:` values so doc-sync precedes qa-audit (today qa-audit is order 45, doc-sync order 50).
- [ ] The `qa-audit` gate's `backing:` / `checks:` prose is updated: after the move, 8.6c/8.6d no longer run inside QA on orchestrator paths, so the backing is "orchestrator-level post-sync `/CJ_doc_audit` + `/CJ_test_audit` + the checkpoint AUQ," not "the QA Step 8.6 audit block."
- [ ] `validate.sh` Check 24 (test-spec coverage cross-check) and Check 15b (per-`CJ_goal_*` ASCII charts) stay green; the full `scripts/test.sh` suite passes.
- [ ] Docs updated: root `CLAUDE.md` pipeline-ordering prose (one file), `docs/workflow.md` per-`CJ_goal_*` ASCII charts (showing doc-sync → audit → checkpoint), the four SKILL.md Overview ASCII chains, and the catalog `description` fields that spell out the QA → checkpoint → doc-sync order.
- [ ] The three named tests are updated for the new ordering: `scripts/test.sh` zzz-test-scaffold integration fixture, `tests/cj-goal-doc-sync-wiring.test.sh` (the ORDERING assertion), and any per-pipeline halt-marker tests.

## Todos

- [x] Swap the `order:` values of the `qa-audit` and `doc-sync` gate rows in `spec/test-spec-custom.md` (doc-sync 45, qa-audit 50).
- [x] Update the `qa-audit` gate `backing:`/`checks:` prose to name the orchestrator-level post-sync audit + checkpoint.
- [x] Update root `CLAUDE.md` pipeline-ordering prose (audit-feeds-checkpoint, doc-sync-coverage, portability-gate, and gate-sequence/layers prose).
- [x] Update the four per-`CJ_goal_*` ASCII charts + summary table + Touches blocks in `docs/workflow.md` to show doc-sync → post-sync audit → checkpoint (Check 15b green).
- [x] Verify the four SKILL.md Overview ASCII chains read consistently with the new order — S000107 already updated them; no stale "checkpoint → doc-sync" wording remains.
- [x] `scripts/test.sh` — no functional order assertion depends on the swap (the S000096 gate-guard checks `--list-gates` membership, not order; the T000040 Touches check verifies bullet presence, not order); only the cj-goal-doc-sync-wiring runner-block comment/messages were updated (3-way → 4-way). The zzz-test-scaffold fixture is non-CJ_goal_* and not order-dependent.
- [x] Update `tests/cj-goal-doc-sync-wiring.test.sh` — now covers all FOUR orchestrators (added CJ_goal_task; H2/H3-tolerant Step-5.5 grep) and asserts the NEW post-sync order (qa-audit row BEFORE doc-sync in the halt-taxonomy run-order listing + the "AFTER doc-sync" post-sync semantics in the halted_at_qa_audit row).
- [x] No separate per-pipeline halt-marker tests exist beyond the wiring test + the S000096 gate guard; both updated/verified.
- [x] `test-spec.sh --validate` + `cj-goal-doc-sync-wiring.test.sh` + `validate.sh` (Check 24 + Check 15b) all green. (Full `scripts/test.sh` deferred to the orchestrator's QA pass.)

## Log

- 2026-06-13: Created. Swap the qa-audit/doc-sync gate order in the test-spec registry + update the qa-audit backing prose + the docs (CLAUDE.md, workflow.md charts, SKILL.md chains, catalog) + the three named tests.

## PRs

## Files

- `spec/test-spec-custom.md` — MODIFIED: qa-audit/doc-sync gate `order:` swap (doc-sync 45, qa-audit 50) + qa-audit backing/checks prose rewritten to name the orchestrator-level post-sync audit + checkpoint
- `spec/test-spec.md` — UNCHANGED: the general tier carries no qa-audit/doc-sync ordering prose; stays byte-identical to `test-spec.sh --seed` (verified)
- `CLAUDE.md` — MODIFIED: audit-feeds-checkpoint prose, doc-sync-coverage section, portability-gate section, gate-sequence/layers prose all updated to doc-sync → post-sync audit → checkpoint
- `docs/workflow.md` — MODIFIED: the four per-`CJ_goal_*` ASCII charts + "In words" + Touches blocks + the summary table + the /CJ_doc_audit & /CJ_test_audit utility-audit entries (Check 15b green)
- `scripts/test.sh` — MODIFIED (descriptive only): cj-goal-doc-sync-wiring runner-block comment + messages 3-way → 4-way / F000064 post-sync order; no functional order assertion existed
- `tests/cj-goal-doc-sync-wiring.test.sh` — MODIFIED: now covers all 4 orchestrators + asserts the NEW post-sync order (qa-audit before doc-sync in the table + the post-sync "AFTER doc-sync" semantics); SC2295-clean
- NOT TOUCHED (owned by S000107 / the orchestrator's sensitive-surface handling): the four `skills/CJ_goal_*/{pipeline,SKILL}.md` (S000107 already updated their Overview chains + halt-taxonomy rows to the new order) and `skills-catalog.json`

## Insights

- `tests/cj-goal-doc-sync-wiring.test.sh` asserts the doc-sync step + halt-row ORDERING and WILL FAIL on the reorder until updated — it is the canary that proves the reorder landed.
- The test-spec registry is the single source of truth for the gate sequence (enforced by `validate.sh` Check 24); the `order:` swap must keep the registry valid and the coverage cross-check green.
- Check 15b enforces the per-`CJ_goal_*` ASCII charts in `docs/workflow.md`; the charts must show the reordered doc-sync → audit → checkpoint sequence or Check 15b / the coverage cross-check flags drift.

## Journal

- [decision] 2026-06-13: Swap the `qa-audit` (order 45) and `doc-sync` (order 50) `order:` values so doc-sync precedes qa-audit, and update the qa-audit backing prose to name the orchestrator-level post-sync audit. Summary: keep the test-spec registry the single source of truth for the gate sequence.
- [blocker] 2026-06-13: Blocked by S000107 — the docs/charts/tests describe the reordered pipeline behavior, so the pipelines must be reordered first. Summary: land S000107 before finalizing the docs + named tests.
- 2026-06-13 [qa-smoke-summary] green: 5/5 non-manual smoke rows green (S1 test-spec.sh --validate OK; S2 doc-sync order 45 < qa-audit order 50; S3 validate.sh exit=0 incl Check 15b 4 charted orchestrators + Check 24 coverage rows=66 findings=0; S4 cj-goal-doc-sync-wiring.test.sh PASS; S5 full scripts/test.sh exit=0 RESULT: PASS).
- 2026-06-13 [qa-e2e-summary] green (static-verifiable E2E): E1 (gate docs after swap — qa-audit backing names orchestrator-level post-sync audit + checkpoint AUQ; CLAUDE.md/workflow.md/SKILL.md all doc-sync→audit→checkpoint, none claims old order) verified; E2 (ORDERING test red-before/green-after) verified — the wiring test asserts the new post-sync order and is green on the reordered pipelines.
- 2026-06-13 [qa-pass] S000108 (user-story): green smoke + green E2E. Phase 2 gates already transitioned (idempotent re-confirm).
- 2026-06-13 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator)
- [impl] 2026-06-13: Implemented the registry swap + derived-doc/test updates. Swapped the gate `order:` in `spec/test-spec-custom.md` (doc-sync 45, qa-audit 50) and rewrote the qa-audit backing/checks to "orchestrator-level post-sync /CJ_doc_audit + /CJ_test_audit + the checkpoint AUQ." Updated CLAUDE.md (4 ordering passages) + docs/workflow.md (4 ASCII charts + In-words + Touches + summary table + the two utility-audit entries). Rewrote `tests/cj-goal-doc-sync-wiring.test.sh` to cover all 4 orchestrators (added CJ_goal_task, H2/H3-tolerant Step-5.5 grep) and assert the new post-sync order (qa-audit-before-doc-sync table run-order + the "AFTER doc-sync" semantics); made it SC2295-clean. `scripts/test.sh`: only the wiring runner-block prose needed updating (no functional order assertion existed; S000096 gate guard checks membership not order; T000040 checks Touches-bullet presence). Verified: `test-spec.sh --validate` OK, `cj-goal-doc-sync-wiring.test.sh` PASS, `validate.sh` Check 24 (coverage clean rows=66 findings=0 + marker drift in sync) + Check 15b (4 charted orchestrator sections) green. The four SKILL.md Overview chains were already consistent (S000107) — no stale "checkpoint → doc-sync" wording found. Summary: registry is the truthful single source; all derived surfaces reflect doc-sync → post-sync audit → checkpoint.
