---
name: "Deterministic-agentic split of inline doc-sync + test-sync"
type: user-story
id: "S000129"
parent: "F000079"
status: active
created: "2026-07-03"
updated: "2026-07-03"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/busy-antonelli-45aa90"
branch: "claude/busy-antonelli-45aa90"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
1. Scaffold story dir + TRACKER
2. DESIGN (approach), SPEC (file inventory + AC), TEST-SPEC (smoke + E2E)

**Gates:**
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria scoped

### Phase 2: Implement
1. qa.md `DEFER_SYNC`; 4× pipeline Step 5.5 + dispatch; contract; guard; audit-nightly; CLAUDE.md
2. Regenerate catalogs

**Gates:**
- [x] Code + contract + tests + docs written
- [x] Deterministic engine checks green (validate/coverage/structure/render/workflow-coverage)

### Phase 3: QA / Ship
1. `validate.sh` + `test.sh` + shellcheck green
2. `/ship` — PR (pre-landing review)

**Gates:**
- [ ] `validate.sh` green (24/26/27/28)
- [ ] `test.sh` green + shellcheck clean
- [ ] `/ship` — PR created

## Acceptance Criteria

See `S000129_SPEC.md` (P0 rows). In brief: the four pipelines run a deterministic
Step 5.5 doc-regen (no inline `/CJ_document-release`), all four QA dispatches +
qa.md honor `DEFER_SYNC`, the two-axis contract carries the guard behavior +
category test, and the per-PR gate stays green.

## Todos

- [x] qa.md 8.6.0 `DEFER_SYNC` + 8.6a/8.6b gating + deferred RESULT
- [x] 4× pipeline Step 5.5 deterministic regen + `DEFER_SYNC` dispatch
- [x] test-spec-custom gate reframe + behavior + coverage + `cj-goal-gate-shape` category
- [x] guard checks 7-9; front-door doc + index + doc-spec declaration; audit-nightly header; CLAUDE.md prose
- [ ] green the tree (validate / test.sh / shellcheck)

## Log

- 2026-07-03: Implemented the deterministic-agentic split. Deterministic engine checks green; full validate.sh/test.sh greening in progress.

## PRs

## Files

- 4× `skills/CJ_goal_*/pipeline.md`, `skills/CJ_qa-work-item/qa.md`
- `spec/test-spec-custom.md`, `spec/doc-spec-custom.md`
- `tests/cj-goal-doc-sync-wiring.test.sh`
- `docs/tests/workflow/CI-push/cj-goal-gate-shape.md`, `docs/tests/index.md`
- `scripts/audit-nightly.sh`, `CLAUDE.md`

## Insights

- Keeping the `Step 5.5: Doc-sync` heading + the two halt markers (reframed) made the change surgical: the gate shape + the existing guard's checks 1-6 stay stable, and the enforcement is ADDITIVE (checks 7-9), not an inversion.

## Journal

- [decision] 2026-07-03 — Reframe the two doc-sync halt markers rather than remove `[doc-sync-non-doc-write]`. Summary: `[doc-sync-red]` = a `--render-docs` engine failure; `[doc-sync-non-doc-write]` = a defensive "the regen dirtied a non-docs/ file" guard — both stay meaningful, minimizing churn across the 4 SKILL.md + gate row + guard.
