---
name: "Slim the cj_goal build gate — take inline doc-sync + test-sync off the per-PR path"
type: feature
id: "F000079"
status: active
created: "2026-07-03"
updated: "2026-07-03"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/busy-antonelli-45aa90"
branch: "claude/busy-antonelli-45aa90"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Create working branch (worktree branch already active)
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks)
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition)
5. Define acceptance criteria
6. Decompose into child user-stories

**Gates:**
- [x] Design produced (design-summary approval gate passed)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress
3. Update Todos section
4. Update Files section

**Gates:**
- [x] All child stories have entered Phase 2+
- [x] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check`
2. Verify smoke tests pass in CI
3. Walk E2E manually
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. `/land-and-deploy` — separate human step after review
6. `/document-release` — post-ship doc audit (nightly CI covers the agent-judged pass)

**Gates:**
- [ ] `/CJ_personal-workflow check` — children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done

## Acceptance Criteria

- [x] Step 5.5's slow `/CJ_document-release` invocation is removed from all four `skills/CJ_goal_*/pipeline.md` build tails and replaced by a fast idempotent deterministic doc-regen (`test-spec.sh` + `workflow-spec.sh --render-docs`); the tail is QA → pre-doc-sync commit → deterministic doc-regen → `/ship`.
- [x] `skills/CJ_qa-work-item/qa.md` gates the agent-judged half of Step 8.6a/8.6b on a new `DEFER_SYNC: true` directive; standalone QA keeps the full inline sweep; `DEFER_AUDIT` behavior unchanged.
- [x] All four QA dispatches pass `DEFER_SYNC: true` alongside `DEFER_AUDIT: true`.
- [x] `spec/test-spec-custom.md`: the `doc-sync` gate row (order 45) reframed to the deterministic regen; a `level: integration` behavior `build-gate-no-inline-slow-sync` + a `behavior_coverage:` link; a `categories:` row `cj-goal-gate-shape` (`workflow`/`CI-push`/`deterministic`) with a `docs/tests/workflow/CI-push/` front-door doc.
- [x] `tests/cj-goal-doc-sync-wiring.test.sh` gains checks 7-9 (no inline `/CJ_document-release`; `--render-docs` present; `DEFER_SYNC` wired) and is runnable via `/CJ_test_run cj-goal-gate-shape`.
- [x] `scripts/audit-nightly.sh` header notes it now also covers the deferred doc/test SYNC drift (framing only).
- [x] CLAUDE.md `## Doc-sync coverage` + `## Nightly doc/test-drift audit` + the `/CJ_document-release` prose updated to the slimmed shape.
- [ ] `./scripts/validate.sh` green (Checks 24/26/27/28); `./scripts/test.sh` green (incl. the extended guard + new category test); `shellcheck` clean.
- [x] The deterministic per-PR gate + standalone `/CJ_qa-work-item` + `/CJ_doc_audit` + `/CJ_test_audit` + `/CJ_document-release` (the skill itself) unchanged in standalone behavior.

## Todos

- [x] S000129 — qa.md `DEFER_SYNC` detection (8.6.0) + gate the 8.6a/8.6b agentic sweep + deferred-RESULT prose.
- [x] S000129 — 4× `pipeline.md` Step 5.5 → deterministic doc-regen (markers reframed) + `DEFER_SYNC: true` in each QA dispatch.
- [x] S000129 — `spec/test-spec-custom.md` gate reframe + behavior + coverage + `cj-goal-gate-shape` category row; front-door doc + index.
- [x] S000129 — extend `tests/cj-goal-doc-sync-wiring.test.sh` (checks 7-9) + `scripts/audit-nightly.sh` header + CLAUDE.md prose.
- [ ] S000129 — green the tree: `validate.sh` (24/26/27/28) → `test.sh` → shellcheck.

## Log

- 2026-07-03: Created. Extends the audit-relocation precedent to the two remaining slow inline sync steps (doc-sync + test-sync): deterministic-agentic split — fast deterministic regen stays inline, the slow agentic prose/overlay sync defers to the existing nightly audit. Built on the two-axis test contract framework (category × layer). Rebased off stale main onto the two-axis feature at build start.

## PRs

## Files

- `skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_task/pipeline.md`, `skills/CJ_goal_todo_fix/pipeline.md` (Step 5.5 deterministic regen + `DEFER_SYNC` dispatch)
- `skills/CJ_qa-work-item/qa.md` (`DEFER_SYNC` detection + 8.6a/8.6b gating + deferred RESULT)
- `spec/test-spec-custom.md` (gate reframe + behavior + behavior_coverage + `cj-goal-gate-shape` category)
- `tests/cj-goal-doc-sync-wiring.test.sh` (checks 7-9)
- `docs/tests/workflow/CI-push/cj-goal-gate-shape.md` + `docs/tests/index.md`
- `scripts/audit-nightly.sh` (header framing)
- `CLAUDE.md` (Doc-sync coverage / Nightly audit / /CJ_document-release prose)

## Insights

- The doc/test sync differs from the audit that F000078's precedent moved: sync WRITES files the PR needs, and some writes are REQUIRED for `validate.sh` (a new test needs a `units:` row; catalogs must be fresh). So it is NOT a blanket removal — the fast deterministic obligations stay inline (enforced by the unchanged per-PR gate); only the SLOW agent-judged prose/overlay work defers.
- `/CJ_document-release` never regenerated the catalogs — `--render-docs` is owned by the implement phase and enforced by Check 26/27. So removing the inline slow doc-sync does not break the deterministic gate; the deterministic regen at Step 5.5 is the belt-and-braces that keeps it green with no model spend.
- The enforcement fits `level: integration`, NOT `level: workflow` — the invariant spans the four orchestrators + qa.md, and Check 28 reserves `level: workflow` for one-orchestrator-per-behavior coverage. This mirrors the sibling `workflow-doc-audit-runs` behavior exactly.
- The guard + the nightly `doc-sync` workflow test are complements: the guard proves the build tail was SLIMMED (no inline slow sync); the nightly test proves the SAFETY NET (audit-nightly) runs. Together they prove the sync moved inline → nightly.

## Journal

- [decision] 2026-07-03 — Deterministic-agentic split (not a blanket removal). Summary: operator chose to keep the fast deterministic regen inline (per-PR gate stays green + structural same-PR sync preserved) and defer only the slow agentic prose/overlay work to the nightly audit — the honest precedent shape.
- [decision] 2026-07-03 — Reuse the EXISTING nightly audit as the safety net; add no new nightly job. Summary: `audit-nightly.yml` already runs `/CJ_doc_audit` + `/CJ_test_audit` (which catch the deferred drift) and files the `audit-drift` issue.
- [decision] 2026-07-03 — New `DEFER_SYNC: true` directive (sibling of `DEFER_AUDIT`), not overloading `DEFER_AUDIT`. Summary: audit is an advisory READ, sync is a productive WRITE — distinct concerns kept legible.
- [decision] 2026-07-03 — Enforce via the two-axis category contract (a `workflow`/`CI-push` category test + a `level: integration` behavior). Summary: the operator's "adapt to the two-axis framework" — the guard is name-selectable via `/CJ_test_run` and reported wired by `/CJ_test_audit`.
- [finding] 2026-07-03 — Worktree branched off stale main (6.0.110), missing the two-axis feature (6.0.111). Summary: fast-forwarded onto origin/main before building so the change adapts to the two-axis contract and does not conflict at merge; the feature re-IDed from a colliding F000078 to F000079.
