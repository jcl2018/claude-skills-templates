---
type: roadmap
parent: F000012
title: "Pipeline parity: per-type implement/qa + Step 18 comma-split fix — Roadmap"
date: 2026-05-08
author: chjiang
status: Draft
---

<!-- Feature roll-up roadmap. F000010 polish; bundles TODOS.md #5 and #6 as one feature
     with two user-stories. -->

## Scope

Close the two known F000010 polish gaps surfaced during the F000011 dogfood:
1. Generalize `/implement-from-spec` and `/qa-work-item` to accept all 4 work-item types (defect, task, feature, user-story) instead of hard-failing on non-user-story input.
2. Tighten `skills/personal-workflow/check.md` Step 18 traceability parser prose to explicitly split AC cells on comma before set-membership check.

The two stories ship together so the small fix (S000022) verifies the bigger refactor (S000021) by flowing through the new defect path end-to-end.

## Non-Goals

- New work-item types beyond the 4 already in `personal-artifact-manifests.json` — this feature extends pipeline coverage to the existing 4, not adds new types.
- Smarter feature-level dispatch (auto-pick a child user-story) — v1 uses AskUserQuestion explicitly.
- Defect QA smoke/E2E split — defect `test-plan.md` rows treated as smoke-equivalent in v1; revisit only if gap surfaces post-merge.
- Tasks-through-pipeline real-world dogfooding — code path ships, verification waits for first real task work-item.
- Step 18 implementation rewrite into a separate parser script — `check.md` is prose interpreted by the LLM; the prose IS the spec.

## Success Criteria

- [ ] `/implement-from-spec <defect-dir>` succeeds; reads `RCA.md` + `test-plan.md`; produces a working implementation.
- [ ] `/qa-work-item <defect-dir>` succeeds; reads `test-plan.md`; produces smoke verification + journal entry.
- [ ] Existing `/implement-from-spec <user-story-dir>` and `/qa-work-item <user-story-dir>` flows behave identically to v1.10.0.
- [ ] `/personal-workflow check work-items/features/personal-workflow/F000010_pipeline_skills/` produces no false `[UNTESTED]` findings on multi-AC P0 stories (S000018 P0 #2/#3/#5/#6, S000019 P0 #2/#4).
- [ ] Test suite covers: implement-on-defect, qa-on-defect, Step 18 multi-AC TEST-SPEC fixture.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000021](S000021_per_type_implement_qa/S000021_TRACKER.md) | Per-type implement/qa pipeline branching | Open |
| [S000022](S000022_traceability_comma_split/S000022_TRACKER.md) | Step 18 traceability comma-split fix | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000021 (per-type pipeline branching) | 2026-05-09 | Not Started | chjiang | Bigger refactor; ships first so S000022 has the new defect path to ride through | — |
| 2 | Ship S000022 (Step 18 comma-split fix) | 2026-05-09 | Not Started | chjiang | Integration test for #1; the multi-AC fixture also covers Step 18.5 cap advisory unchanged | #1 |
| 3 | End-to-end pipeline run on F000012 | 2026-05-09 | Not Started | chjiang | Verify both children pass `/personal-workflow check`; smoke + E2E green | #1, #2 |

### Delivery History

<!-- Backward-looking PR/merge history; populated post-ship. -->

## Dependency Graph

```
#1 ship S000021 (per-type pipeline)
    │
    ▼
#2 ship S000022 (Step 18 fix) ── (rides through new defect path as integration test)
    │
    ▼
#3 end-to-end F000012 verification
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Defect implement reads RCA + test-plan, but RCA is "what went wrong" not "what to build." Treat test-plan as de-facto SPEC? | Resolved in DESIGN big decision #3: yes, test-plan is the spec; RCA is context |
| Defect QA without E2E split may miss user-visible regressions | Accepted gap for v1; revisit if it surfaces post-merge |
