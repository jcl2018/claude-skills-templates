---
name: "Reorder cj_goal doc/test audit to run after doc-sync (post-sync authoritative audit)"
type: feature
id: "F000064"
status: active
created: "2026-06-13"
updated: "2026-06-13"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/friendly-sinoussi-cef30d"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/post_sync_authoritative_audit`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] In every cj_goal orchestrator (feature/defect/task/todo), the doc/test audit that feeds the post-QA checkpoint runs AFTER `/CJ_document-release` doc-sync, so the operator's Continue/Halt decision reflects post-sync doc state.
- [ ] The three-stage audit (incl. Stage-3 drift) runs against the post-sync docs.
- [ ] The audit runs ONCE per orchestrator run (one combined depth-2 fresh-context subagent running `/CJ_doc_audit` + `/CJ_test_audit`) and is READ-ONLY (reports findings, writes no fixes).
- [ ] Each pipeline has an explicit automated pre-doc-sync commit so doc-sync never hits the F000038 manual-pre-commit halt during an autonomous build; the commit step is idempotent (skips when the tree is already clean at HEAD).
- [ ] Standalone `/CJ_qa-work-item` still runs its inline Step 8.6 audit unchanged.
- [ ] `spec/test-spec.md` / `spec/test-spec-custom.md` declare the new gate order (doc-sync precedes qa-audit) AND the updated `qa-audit` backing field; `validate.sh` Check 24 + Check 15b are green; the full `scripts/test.sh` suite passes.
- [ ] The named tests are updated for the new ordering: `scripts/test.sh` zzz-test-scaffold integration fixture, `tests/cj-goal-doc-sync-wiring.test.sh`, and any per-pipeline halt-marker tests.
- [ ] No change to ship safety: `validate.sh` Check 19 (and 15/16/17/24) still gate at `/ship`; audit findings remain advisory (never flip QA red).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000106 — qa.md Step 8.6 split: keep 8.6a/8.6b (overlay writes) inline; make 8.6c/8.6d (doc/test audits) deferrable via the `DEFER_AUDIT: true` dispatch directive; report `AUDITS=deferred` on orchestrator paths; standalone keeps inline audit.
- [ ] S000107 — the four cj_goal pipelines: add the automated pre-doc-sync commit step (idempotent, per each pipeline's commit topology), move doc-sync ahead of the audit + checkpoint, add the orchestrator-level post-sync read-only audit step (ONE combined subagent), re-point the QA-audit checkpoint to the post-sync report, embed `DEFER_AUDIT: true` in the QA dispatch prompt.
- [ ] S000108 — swap the `qa-audit` / `doc-sync` gate `order:` values in `spec/test-spec-custom.md`, update the `qa-audit` gate backing/checks prose, update docs (root CLAUDE.md ordering prose, `docs/workflow.md` per-`CJ_goal_*` ASCII charts, the four SKILL.md Overview chains, catalog descriptions), and update the three named tests (zzz-test-scaffold fixture, `cj-goal-doc-sync-wiring.test.sh`, per-pipeline halt-marker tests).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-13: Created. Reorder the cj_goal doc/test audit to run after `/CJ_document-release` doc-sync (mechanism C-i: audit once, post-sync, read-only) so the post-QA checkpoint reflects post-sync doc state across all four cj_goal orchestrators; add an automated pre-doc-sync commit.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_qa-work-item/qa.md` — Step 8.6 split (overlay-writes inline; audits deferrable)
- `skills/cj_goal_feature/pipeline.md` — pre-doc-sync commit + doc-sync→audit→checkpoint reorder
- `skills/cj_goal_defect/pipeline.md` — same reorder against the defect commit topology
- `skills/CJ_goal_task/SKILL.md` — same reorder against the task commit topology
- `skills/CJ_goal_todo_fix/SKILL.md` — same reorder against the todo commit topology
- `spec/test-spec-custom.md` — qa-audit/doc-sync gate `order:` swap + qa-audit backing prose
- `spec/test-spec.md` — gate-sequence narrative (if the general tier references ordering)
- `CLAUDE.md` — pipeline-ordering prose (one file)
- `docs/workflow.md` — per-`CJ_goal_*` ASCII charts (Check 15b)
- `skills-catalog.json` — catalog `description` fields that spell out QA→checkpoint→doc-sync order
- `scripts/test.sh` — zzz-test-scaffold integration fixture
- `tests/cj-goal-doc-sync-wiring.test.sh` — doc-sync ORDERING assertion

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The doc/test audit is fundamentally a "verify the contract against the FINAL state" operation; the final doc state in a cj_goal run is post-doc-sync, so the authoritative audit belongs there. The current ordering verifies a state that is about to change.
- This is a decision-quality wrinkle, NOT a safety hole — the hard `validate.sh` gates (15/16/17/19/24) still run post-sync at `/ship`, so nothing broken can ship. The fix improves the signal the operator decides on.
- Clean principle that falls out: update the contract before sync, verify it after sync. The spec-overlay WRITES (8.6a/8.6b) belong pre-sync with the code; the doc/test AUDITS (8.6c/8.6d) belong after the last doc-mutating step, and run read-only.
- C-i (audit once, post-sync) chosen over C-ii (audit twice): per Premise 3, doc-sync only updates release-style docs and does not regenerate workflow.md/philosophy.md, so a second post-sync audit mostly re-reports unchanged drift — wasted cost. Run it once, at the authoritative point.
- Per-pipeline commit topology differs and must be enumerated per file: defect commits the fix before QA (Step 7.6) + re-commits the tracker after QA; feature commits nothing automatically; task/todo differ again. The new pre-doc-sync commit lands at a different point in each file.
- Implement-subagent blind spot (known): every change to the audit/gate flow needs parallel edits to `scripts/test.sh`'s zzz-test-scaffold integration test, `tests/cj-goal-doc-sync-wiring.test.sh` (the ORDERING assertion that fails on the reorder until updated), and the per-pipeline halt-marker tests. Listed as explicit implementation steps.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-13: Chose Approach C (structural reorder: move doc-sync ahead of the audit+checkpoint) over A (annotate-only — papers over the ordering) and B (re-audit twice — double 3-stage cost). Summary: the operator's Continue/Halt decision must be honest about the docs that will actually ship.
- [decision] 2026-06-13: Within C, chose mechanism C-i (audit once, post-sync) over C-ii (audit twice, additive). Summary: doc-sync only touches release-style docs, so a second audit mostly re-reports unchanged drift; run the one audit at the authoritative post-sync point.
- [decision] 2026-06-13: The defer signal is a literal `DEFER_AUDIT: true` directive embedded in the QA Agent-tool dispatch prompt (greppable string in the pipeline.md prompt templates), NOT an argv `--flag` — because `/CJ_qa-work-item` is dispatched as a subagent prompt, not a CLI with argv. Summary: OQ1 resolved.
- [decision] 2026-06-13: doc-sync, the post-sync audit, and the checkpoint stay pure-read / idempotent and record NO new phase boundary; the NEW pre-doc-sync commit IS a state change — record its boundary or make it idempotent (skip when the tree is already clean at HEAD) so a resume after it does not double-commit. Summary: OQ2 resolved.
- [decision] 2026-06-13: The post-sync audit is read-only — it reports findings and writes no overlay/doc fixes. If it surfaces a needed fix, the operator Halts at the checkpoint and re-runs so the fix lands pre-sync on the next pass (preserving the "everything in the PR is post-sync-clean" invariant). Summary: addresses reviewer finding 1c.
