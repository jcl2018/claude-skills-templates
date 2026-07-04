---
type: roadmap
parent: F000079
title: "Slim the cj_goal build gate — take inline doc-sync + test-sync off the per-PR path — Roadmap"
date: 2026-07-03
author: Charlie Jiang
status: Draft
---

## Scope

Extend the audit-relocation precedent (F000076) to the two remaining SLOW inline
sync steps on the cj_goal build path: **doc-sync** (Step 5.5 `/CJ_document-release`
LLM prose rewrite) and **test-sync** (QA 8.6a/8.6b agent-judged overlay-amendment
sweep). A **deterministic-agentic split**: the FAST deterministic obligations that
keep the per-PR gate green stay inline (Step 5.5 becomes a `--render-docs` regen;
QA still adds the required `units:` row for a new test), while the SLOW agent-judged
prose/overlay work DEFERS to the EXISTING nightly audit via a new `DEFER_SYNC: true`
QA directive. Enforced through the two-axis test contract (a `workflow`/`CI-push`
category test + a `level: integration` behavior). Single atomic user-story.

## Non-Goals

- The deterministic per-PR gate (`validate.sh` / `validate.yml` / pre-commit) — untouched.
- Standalone `/CJ_qa-work-item` — full inline sweep KEPT; only the `DEFER_SYNC` path changes.
- `/CJ_document-release` / `/CJ_doc_audit` / `/CJ_test_audit` skills — unchanged.
- A new nightly job, or an automated nightly doc-sync PR — the safety net is report-only (the existing `audit-drift` issue).

## Success Criteria

- [x] Step 5.5 = deterministic doc-regen across all four pipelines (markers reframed).
- [x] `DEFER_SYNC: true` in qa.md (8.6.0 detection + 8.6a/8.6b gating) + all four QA dispatches.
- [x] Gate reframe + `build-gate-no-inline-slow-sync` behavior + coverage + `cj-goal-gate-shape` category (`workflow`/`CI-push`) + front-door doc + index + doc-spec declaration.
- [x] Guard test checks 7-9 + audit-nightly header + CLAUDE.md prose.
- [ ] `validate.sh` green (24/26/27/28), `test.sh` green, shellcheck clean.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000129](S000129_deterministic_agentic_split/S000129_TRACKER.md) | Deterministic-agentic split of inline doc-sync + test-sync | In Progress |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | qa.md `DEFER_SYNC` detection + 8.6a/8.6b gating + deferred RESULT | — | Done | Charlie Jiang | The core handshake | — |
| 2 | 4× pipeline Step 5.5 → deterministic regen + `DEFER_SYNC` dispatch | — | Done | Charlie Jiang | Feature = reference; 3 replicated | 1 |
| 3 | Contract: gate reframe + behavior + coverage + category + front-door + doc-spec | — | Done | Charlie Jiang | Two-axis category placement | 2 |
| 4 | Guard checks 7-9 + audit-nightly header + CLAUDE.md prose | — | Done | Charlie Jiang | Enforcement + docs | 3 |
| 5 | Green the tree: validate → test.sh → shellcheck | — | In Progress | Charlie Jiang | The atomic greening | 4 |
| 6 | Ship S000129 (PR opened) | — | Not Started | Charlie Jiang | PR-stop | 5 |

### Delivery History

- 2026-07-03: Built F000079 + child S000129 from the APPROVED design (design-summary gate). Rebased off stale main onto the two-axis feature (6.0.111) at build start; re-IDed from a colliding F000078 to F000079.

## Dependency Graph

```
#1 qa.md DEFER_SYNC --> #2 pipelines (Step 5.5 + dispatch)
      --> #3 contract (gate + behavior + coverage + category)
            --> #4 guard + audit-nightly + CLAUDE.md
                  --> #5 green the tree --> #6 ship S000129 (PR)
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Whether to also add a dedicated regression-category guard vs. reusing the workflow guard. | Settled: one `workflow`/`CI-push` guard, complementing the nightly `doc-sync` workflow test — no separate regression row this increment. |
