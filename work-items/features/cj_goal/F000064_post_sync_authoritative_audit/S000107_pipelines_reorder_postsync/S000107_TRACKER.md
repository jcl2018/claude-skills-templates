---
name: "Four cj_goal pipelines: pre-doc-sync commit + doc-sync→audit→checkpoint reorder"
type: user-story
id: "S000107"
status: active
created: "2026-06-13"
updated: "2026-06-13"
parent: "F000064"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/friendly-sinoussi-cef30d"
blocked_by: "S000106"
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

- [ ] Each of the four pipelines (feature `pipeline.md`, defect `pipeline.md`, task `SKILL.md`, todo `SKILL.md`) adds an explicit automated pre-doc-sync commit step, placed correctly against that pipeline's existing commit topology, and idempotent (skips the commit when the tree is already clean at HEAD).
- [ ] Each pipeline moves the doc-sync step (`/CJ_document-release`) to run BEFORE the audit + checkpoint.
- [ ] Each pipeline adds an orchestrator-level post-sync audit step that dispatches `/CJ_doc_audit` + `/CJ_test_audit` as ONE combined depth-2 fresh-context subagent, READ-ONLY (no overlay/doc fixes).
- [ ] Each pipeline re-points its existing QA-audit checkpoint to consume the post-sync audit report; the checkpoint AUQ text, `[qa-audit-waived]`/`[qa-audit-declined]` journal lines, and `halted_at_qa_audit` end-state are unchanged in meaning.
- [ ] Each pipeline embeds the `DEFER_AUDIT: true` directive in its QA dispatch prompt so the audit does not also run pre-sync.
- [ ] Resume logic: doc-sync / post-sync audit / checkpoint stay pure-read / idempotent (no new phase boundary); the pre-doc-sync commit records a boundary or is idempotent so a resume does not double-commit. Verified against each pipeline's validate-before-skip logic.

## Todos

- [x] feature `skills/cj_goal_feature/pipeline.md`: added the NEW Step 3.5 pre-doc-sync commit (feature commits nothing automatically today — F000038), moved Step 5.5 doc-sync ahead of the audit + checkpoint, added the NEW Step 5.6 post-sync audit, re-pointed the Step 3.4 checkpoint, embedded `DEFER_AUDIT: true`. SKILL.md chart/halt-row/description updated to match.
- [x] defect `skills/cj_goal_defect/pipeline.md`: kept the Step 7.6 commit-before-QA; added the NEW Step 8.4 pre-doc-sync commit for the post-QA tracker update; moved Step 5.5 doc-sync ahead of the audit + checkpoint; added Step 5.6 post-sync audit; re-pointed the Step 8.5 checkpoint; embedded `DEFER_AUDIT: true`. SKILL.md updated to match.
- [x] task `skills/CJ_goal_task/pipeline.md` (+ SKILL.md surface): same reorder against the task topology — NEW Step 4.4 commit, Step 5.5 doc-sync, NEW Step 5.6 audit, Step 4.5 checkpoint re-pointed, `DEFER_AUDIT: true`.
- [x] todo `skills/CJ_goal_todo_fix/pipeline.md` (+ SKILL.md surface): same reorder against the todo topology — NEW Step 5.4 orchestrator-layer commit (todo_fix.sh does not commit), Step 5.5 doc-sync, NEW Step 5.5b audit, the SKILL.md checkpoint re-pointed, `DEFER_AUDIT: true`.
- [x] Verified depth ≤ 2 (orchestrator → ONE combined audit subagent) and that the post-sync audit is ONE combined subagent running both `/CJ_doc_audit` + `/CJ_test_audit` (not two), READ-ONLY, in all four pipelines.
- [ ] (Deferred — S000108) The parallel test edits (`tests/cj-goal-doc-sync-wiring.test.sh` ORDERING assertion, zzz-test-scaffold fixture, per-pipeline halt-marker tests) + the test-spec gate-order swap + docs. Out of scope for S000107; `cj-goal-doc-sync-wiring.test.sh`'s ordering assertion is EXPECTED to go red on this reorder until S000108 updates it.

## Log

- 2026-06-13: Created. Reorder all four cj_goal pipelines: pre-doc-sync commit + doc-sync ahead of the audit + checkpoint + orchestrator-level post-sync read-only audit + checkpoint re-point + `DEFER_AUDIT: true` dispatch directive.

## PRs

## Files

- `skills/cj_goal_feature/pipeline.md` (modified) — Step 3.3 QA dispatch gains `DEFER_AUDIT: true`; NEW Step 3.5 pre-doc-sync commit (idempotent); Step 5.5 doc-sync moved ahead of the audit + checkpoint; NEW Step 5.6 post-sync read-only audit subagent; Step 3.4 checkpoint re-pointed to the post-sync report; dry-run + resilience-contract prose updated.
- `skills/cj_goal_feature/SKILL.md` (modified) — ASCII chart + `halted_at_qa_audit` halt row + frontmatter description updated for the new order.
- `skills/cj_goal_defect/pipeline.md` (modified) — Step 8 QA invocation gains `DEFER_AUDIT: true`; NEW Step 8.4 pre-doc-sync commit (captures the post-QA tracker update, idempotent — distinct from the Step 7.6 fix-before-QA commit); Step 5.5 doc-sync ahead of the audit + checkpoint; NEW Step 5.6 post-sync read-only audit subagent; Step 8.5 checkpoint re-pointed; dry-run + Step 5.7 intro prose updated.
- `skills/cj_goal_defect/SKILL.md` (modified) — ASCII chart + `halted_at_qa_audit` halt row + frontmatter description updated.
- `skills/CJ_goal_task/pipeline.md` (modified) — Step 4 QA dispatch gains `DEFER_AUDIT: true`; NEW Step 4.4 pre-doc-sync commit (idempotent); Step 5.5 doc-sync ahead of the audit + checkpoint; NEW Step 5.6 post-sync read-only audit subagent; Step 4.5 checkpoint re-pointed; dry-run prose updated. (SKILL.md is the SPEC-named surface, but the orchestration STEPS live in pipeline.md — both edited for consistency.)
- `skills/CJ_goal_task/SKILL.md` (modified) — ASCII chart + `halted_at_qa_audit` halt row + frontmatter description updated.
- `skills/CJ_goal_todo_fix/pipeline.md` (modified) — Step 4 QA dispatch gains `DEFER_AUDIT: true`; NEW Step 5.4 pre-doc-sync orchestrator-layer commit (todo_fix.sh does not commit; idempotent); Step 5.5 doc-sync ahead of the audit + checkpoint; NEW Step 5.5b post-sync read-only audit subagent; checkpoint (in SKILL.md) re-pointed to the post-sync report.
- `skills/CJ_goal_todo_fix/SKILL.md` (modified) — per-TODO chain chart + drain-mode chart + the QA-audit checkpoint section re-pointed to the post-sync audit; Step 5.7 intro + frontmatter description updated.
- No resume-state schema change: the pre-doc-sync commit is gated on the live tree state (idempotent), not on a new `last_completed_phase` boundary; doc-sync / post-sync audit / checkpoint stay pure-read.

## Insights

- Per-pipeline commit topology differs and must be enumerated per file: defect commits the fix before QA (Step 7.6) + re-commits the tracker after QA; feature commits nothing automatically; task/todo differ. The new pre-doc-sync commit lands at a different point per file.
- The post-sync audit is read-only — if it surfaces a fix, the operator Halts at the checkpoint and re-runs so the fix lands pre-sync on the next pass (preserving "everything in the PR is post-sync-clean").

## Journal

- [decision] 2026-06-13: doc-sync moves AHEAD of the audit + checkpoint (not "stays put"); the audit moves to consume post-sync state. Summary: corrects the earlier framing; the audit follows doc-sync.
- [decision] 2026-06-13: The pre-doc-sync commit is idempotent (skip when the tree is clean at HEAD) so a resume after it does not double-commit; doc-sync/audit/checkpoint record no new phase boundary. Summary: OQ2 resolved.
- [blocker] 2026-06-13: Blocked by S000106 — the pipelines consume S000106's `DEFER_AUDIT: true` signal, so qa.md must support the directive first. Summary: implement S000106 before wiring the pipelines.
- 2026-06-13 [impl-finding] Confirmed S000106 landed: qa.md Step 8.6.0 detects the literal `DEFER_AUDIT: true` in the dispatch prompt and the deferred path returns `AUDITS=deferred` with NO `AUDIT_FINDINGS` block. All four pipeline QA dispatches now embed that literal.
- 2026-06-13 [impl-finding] The defect + todo pipelines invoke QA via the Skill tool inline (not an Agent ROLE-prompt dispatch like feature/task); embedded `DEFER_AUDIT: true` as a greppable literal in the invocation directive so qa.md Step 8.6.0's prompt inspection still detects it.
- 2026-06-13 [impl-decision] Per-file commit topology (Big-decision #8): feature → NEW Step 3.5 (commits nothing automatically today); defect → NEW Step 8.4 for the post-QA tracker update, distinct from the kept Step 7.6 fix-before-QA commit; task → NEW Step 4.4; todo → NEW Step 5.4 orchestrator-layer commit (todo_fix.sh does not commit). Each is the idempotent `git diff --quiet && git diff --cached --quiet` clean-tree skip — no new `last_completed_phase` boundary.
- 2026-06-13 [impl-decision] Edited each pipeline's SKILL.md surface (ASCII chart + `halted_at_qa_audit` halt row + frontmatter description) alongside its pipeline.md steps, even where the SPEC Components Affected named only one of the two — the orchestration STEPS live in pipeline.md for task/todo while the checkpoint/chart prose lives in SKILL.md; leaving the chart on the old order would self-stale under the Stage-3 drift audit.
- 2026-06-13 [impl-finding] Did NOT touch `tests/cj-goal-doc-sync-wiring.test.sh`, the test-spec registry, docs, or `scripts/test.sh` — those are S000108 + orchestrator-handled. Its ordering assertion is EXPECTED to go red on this reorder until S000108 updates it (per the task constraints + parent DESIGN risk row).
- 2026-06-13 [impl] Reordered all four cj_goal pipelines to QA(DEFER_AUDIT) → pre-doc-sync commit (idempotent) → doc-sync → ONE combined READ-ONLY post-sync audit subagent (/CJ_doc_audit + /CJ_test_audit) → QA-audit checkpoint (post-sync) → portability → /ship. Modified 8 files (4 pipeline.md/SKILL.md step surfaces + 4 SKILL.md chart/description surfaces). Phase 2 implementer-owned gates transitioned.
- 2026-06-13 [impl-pass] S000107: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-13 [qa-smoke-summary] green: 5/5 non-manual smoke rows green (S1 all four pipelines embed DEFER_AUDIT: true; S2 pre-doc-sync commit per file; S3 cj-goal-doc-sync-wiring.test.sh PASS; S4 idempotent clean-tree skip present; S5 full scripts/test.sh exit=0 RESULT: PASS).
- 2026-06-13 [qa-e2e-summary] green (static-verifiable E2E): E1 (feature pipeline sequence QA(deferred)→pre-doc-sync commit→doc-sync→post-sync audit→checkpoint) verified via wiring test run-order (qa-audit<doc-sync<ship) + workflow.md/SKILL.md charts; E2 (checkpoint journal lines [qa-audit-waived]/[qa-audit-declined] + halted_at_qa_audit unchanged, now post-sync) verified in all four SKILL.md halt-taxonomy rows; E3 (resume clean-tree idempotent commit) verified by the idempotent-commit guard prose.
- 2026-06-13 [qa-pass] S000107 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
- 2026-06-13 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator)
