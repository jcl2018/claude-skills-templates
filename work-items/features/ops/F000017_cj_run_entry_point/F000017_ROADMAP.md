---
type: roadmap
parent: F000017
title: "/CJ_run Entry Point Consolidation — Roadmap"
date: 2026-05-13
author: chjiang
status: Draft
---

## Scope

Consolidate the public-facing entry points for running the CJ work-item pipeline.
Rename `/CJ_ship-feature` → `/CJ_run`, add two new input modes (work-item-dir
phase-detection + no-arg branch-scan), and remove `/CJ_personal-pipeline` from
routing. The result: one public command (`/CJ_run`) that accepts a design doc,
a work-item directory, or no arg, and dispatches to the right sub-pipeline.

## Non-Goals

- Renaming `/CJ_personal-workflow` — accurately named (it's a validator, not an entry point)
- Raw-idea input (folding /office-hours into /CJ_run) — out of scope per design premise rejection
- Backward-compat shim for `/CJ_ship-feature` — clean break (no alias)
- Defect/task TRACKER support in Branch(g) — v0.2 limits to user-story gate strings
- `--all` flag for iterating all in-progress work-items — deferred to v0.3

## Success Criteria

- [ ] `cat rules/skill-routing.md | grep CJ_run` → routing points to /CJ_run
- [ ] `cat rules/skill-routing.md | grep CJ_ship-feature` → no matches (rename complete)
- [ ] `cat rules/skill-routing.md | grep CJ_personal-pipeline` → no matches (removed from routing)
- [ ] `/CJ_run <approved-design-doc>` → runs existing full-pipeline behavior unchanged
- [ ] `/CJ_run <draft-design-doc>` → error "Design doc is not APPROVED"
- [ ] `/CJ_run <work-item-dir>` → detects phase and dispatches (impl_qa_ship / qa_ship / ship / open_pr / already_shipped)
- [ ] `/CJ_run` (no args) with 1 in-progress user-story → auto-resume
- [ ] `/CJ_run` (no args) with no work-items/ → graceful "no work-items found" message
- [ ] `validate.sh` passes (no new catalog `status` values introduced)
- [ ] Telemetry log is `CJ_run.jsonl` with fresh counter (sunset reset to 0)

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000038](S000038_rename_and_branch_g/S000038_TRACKER.md) | Rename /CJ_ship-feature → /CJ_run + Branch(g) no-arg branch scan | Open |
| [S000039](S000039_branch_f_work_item_dir/S000039_TRACKER.md) | Branch(f) work-item-dir input mode + phase-detection dispatch | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship F000016 (S000036 + S000037 prerequisite) | — | In Progress | chjiang | Already scaffolded; impl pending | — |
| 2 | Ship S000038 (rename + Branch(g)) | — | Not Started | chjiang | Can ship independent of F000016 | — |
| 3 | Ship S000039 (Branch(f) work-item-dir) | — | Not Started | chjiang | Branch(f) impl_qa_ship dispatch needs S000036's --work-item-dir flag | #1 |
| 4 | End-to-end pipeline run on /CJ_run | — | Not Started | chjiang | Verify all 3 input modes work on real work-items | #2, #3 |

### Delivery History

<!-- Append-only. Backward-looking record of merged PRs and version bumps. -->

- 2026-05-13: F000017 scaffolded from design doc chjiang-claude-awesome-pasteur-36565c-design-20260513-154622.md

## Dependency Graph

```
F000016 (multi-story auto-iterate) ─┐
                                    ├─> S000039 (Branch f impl_qa_ship)
                                    │
S000038 (rename + Branch g) ────────┴─> F000017 end-to-end verification
```

S000038 has no F000016 dependency; can ship in parallel with F000016 implementation.
S000039 must wait for F000016 to merge (specifically S000036's --work-item-dir flag).

## Open Questions

| Question | Next check |
|----------|-----------|
| Order of ship: should S000038 land before or after F000016? | Decide at S000038 ship-time; either ordering works |
| Does the rename need a v2.3.0 bump or a patch bump? | Decide at /ship-time based on whether F000016 already bumped major |
