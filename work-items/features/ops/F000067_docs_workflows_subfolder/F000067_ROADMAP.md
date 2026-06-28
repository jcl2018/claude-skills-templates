---
type: roadmap
parent: F000067
title: "docs/workflows/ subfolder — per-workflow files + workflow.md as a pure index — Roadmap"
date: 2026-06-27
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. Scope/non-goals, decomposition, delivery timeline. -->

## Scope

Split the deep per-workflow detail out of `docs/workflow.md` into a
`docs/workflows/` subfolder (one `.md` per workflow), leave `workflow.md` as a
pure top-level index/overview, and teach the doc contract about the two-level
structure as a **portable, mandated** part that every adopting repo inherits.
Content moves verbatim — reorganize, do not expand.

## Non-Goals

- New prose depth — "current depth is ok"; this is a verbatim reorganize.
- Splitting any non-workflow doc into subfolders — only `docs/workflow.md`.
- Changing the 3-column doc-spec registry grammar — only new rows + a reworded Requirement + the new engine check.
- Retiring/merging existing `validate.sh` checks beyond the targeted 15a/15b changes + the new 15c.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `docs/workflow.md` is a ~80–120-line pure index linking each `docs/workflows/*.md`.
- [ ] Six `docs/workflows/*.md` exist with verbatim-moved content; no prose lost.
- [ ] Portable seed teaches the two-level mandate, 3-way byte-identical; no-drift test green.
- [ ] `doc-spec.sh --check-on-disk` `workflows-subfolder` PASS + recursed-orphans PASS; registry-absent temp-dir drill exits 0.
- [ ] `validate.sh` (15a/15b/15c/16/17/19 + 24) + `test.sh` full suite green.
- [ ] `/CJ_doc_audit` + `/CJ_test_audit` clean post-sync.

## Decomposition

<!-- The user-stories that decompose this feature. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000111](S000111_docs_workflows_subfolder/S000111_TRACKER.md) | docs/workflows/ subfolder — full split + contract/engine/validator/test/prose changes | Open |

## Delivery Timeline

<!-- Forward-looking milestones. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000111 (full split + contract/engine/validator/test/prose) | — | Not Started | chjiang | The single child story carries the whole change | — |
| 2 | End-to-end pipeline run (scaffold → implement → qa → doc-sync → audit → PR) | — | Not Started | chjiang | Stops at the PR (CJ_goal_feature PR-stop) | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-27: Scaffolded F000067 + child S000111 from the APPROVED /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000111 (full split + contract/engine/validator/test/prose) --> #2 End-to-end pipeline run (stop at PR)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does the registry-absent temp-dir drill still exit 0 after the mandate is added (mandate truly registry-gated)? | Verified by the S000111 TEST-SPEC registry-absent smoke row during QA. |
| Do the six moved sections appear verbatim in their new files with no content loss? | Verified by the S000111 TEST-SPEC content-preservation E2E row during QA. |
