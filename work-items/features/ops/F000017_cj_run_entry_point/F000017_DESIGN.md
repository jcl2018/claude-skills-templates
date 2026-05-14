---
type: design
parent: F000017
title: "/CJ_run Entry Point Consolidation — Feature Design"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
reviewers: []
---

## Problem

Three public skills exist for "run the pipeline": `/CJ_personal-pipeline`,
`/CJ_ship-feature`, and `/CJ_personal-workflow` (validator). Users don't know
which to call, the names are misleading, and none of them handle "resume from
wherever the work currently sits." Both pipeline skills require an APPROVED
design doc as their only input, which makes them useless when work is
already scaffolded (mid-flight handoff, partial pipeline already run).

The /CJ_ship-feature skill has the right architecture (full autoplan →
pipeline → ship → deploy) — the problem is naming + input rigidity.

## Shape of the solution

Rename /CJ_ship-feature → /CJ_run. Add two new input modes: work-item-dir
(resume from current phase) and no-arg (scan current branch's work-items/
and auto-resume). Remove /CJ_personal-pipeline from routing — it stays as
internal implementation. /CJ_personal-workflow (validator) is untouched.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Rename mechanics + Branch(g) no-arg branch scan | S000038 | [S000038_rename_and_branch_g/S000038_TRACKER.md](S000038_rename_and_branch_g/S000038_TRACKER.md) |
| Branch(f) work-item-dir input mode + phase detection + dispatch table | S000039 | [S000039_branch_f_work_item_dir/S000039_TRACKER.md](S000039_branch_f_work_item_dir/S000039_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Rename `/CJ_ship-feature` → `/CJ_run` | Current name is misleading (sounds feature-specific); `/CJ_run` is short, neutral, accurately describes "run the pipeline." |
| 2 | Remove `/CJ_personal-pipeline` from routing (keep as internal) | Eliminates the two-public-entry-points confusion; pipeline becomes implementation detail of /CJ_run. Direct callers can still invoke it but routing won't suggest it. |
| 3 | Add work-item-dir input mode (Branch f) | Enables "resume from wherever the work currently sits" — the primary user complaint. Phase detection from TRACKER gates picks the right sub-pipeline. |
| 4 | Add no-arg branch-scan mode (Branch g) | One-key resume on the current branch. Limits to user-story TRACKERs in v0.2 (gate strings are user-story-specific). |
| 5 | Two-child decomposition (S000038 + S000039) | Maps the design's per-mode dependency split: rename + Branch(g) ship independent; Branch(f) impl_qa_ship needs F000016/S000036. |
| 6 | No backward-compat shim for `/CJ_ship-feature` | Shims recreate the exact naming confusion this feature fixes. Direct callers update. |
| 7 | Fresh telemetry log (`CJ_run.jsonl`); sunset counter resets to 0 | Clean break. `CJ_ship-feature.jsonl` kept for historical reference but not read. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| F000016 (S000036 + S000037) hasn't merged yet — S000039's impl_qa_ship dispatch depends on it | Block S000039 implementation start until F000016 merges; S000038 can proceed in parallel |
| Branch(g) scan only matches user-story TRACKERs (gate strings differ for defect/task) | v0.2 scope; document the limitation in S000038's TRACKER |
| Multi-story behavior in Branch(b) inherits from S000037 (already scaffolded as part of F000016) | Verify S000037 ships before F000017 ships; otherwise multi-story design-doc inputs won't iterate children |
| `--all` flag for branch-scan (iterate all in-progress items) | Deferred to v0.3 per design's Future Work section |

## Definition of done

- [ ] `skills/CJ_ship-feature/` renamed to `skills/CJ_run/` via `git mv`
- [ ] `skills/CJ_run/SKILL.md` frontmatter updated (`name: CJ_run`, version: 0.2.0, description rewritten)
- [ ] `skills/CJ_run/run.md` (was ship-feature.md) has new Branch(f) and Branch(g) logic at Step 1
- [ ] `skills-catalog.json` entry renamed; CJ_personal-pipeline description prefixed "internal — use /CJ_run instead."
- [ ] `rules/skill-routing.md` routes `/CJ_run` for ship/deploy/pipeline; no `/CJ_personal-pipeline` entry
- [ ] `validate.sh` passes
- [ ] All success criteria in /CJ_run design's Success Criteria section verified

## Not in scope

- Renaming `/CJ_personal-workflow` (the validator) — it's accurately named, kept as-is
- Folding /office-hours into /CJ_run (raw-idea input) — premise rejection per office-hours session
- `--all` flag for branch-scan iteration — deferred to v0.3
- Branch(g) scanning defect/task TRACKERs — v0.2 scope is user-story only
- Backward-compat shim or deprecation alias for `/CJ_ship-feature` — clean break

## Pointers

- Parent tracker: [F000017_TRACKER.md](F000017_TRACKER.md)
- Roadmap: [F000017_ROADMAP.md](F000017_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-awesome-pasteur-36565c-design-20260513-154622.md`
- Blocking feature: [F000016_TRACKER.md](../F000016_ship_feature_multi_story_auto_iterate/F000016_TRACKER.md)
