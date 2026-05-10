---
type: roadmap
parent: F000015
title: "--brief mode for /personal-pipeline — Roadmap"
date: 2026-05-09
author: chjiang
status: Draft
---

<!-- Roll-up roadmap for F000015. Three user-stories: S000029 (Phase 0 spike,
     BLOCKING), S000030 (flag plumbing + stub synthesis), S000031 (end-to-end
     fixture). -->

## Scope

Add `--brief "<text>"` and `--type {task|defect}` flags to `/personal-pipeline`
that synthesize a real stub design doc on disk before dispatching the existing
scaffold/implement/qa subagent chain. Single keystroke from
intent-as-paragraph to scaffolded + implemented + qa'd work-item. 100%
backward compatible: existing manual and `--auto` paths byte-identical when
`--brief` is absent. Telemetry gains an additive `mode` field
(`manual`/`auto`/`brief`/`brief+auto`); sunset-checkpoint parser defaults to
`manual` if absent.

## Non-Goals

- `--brief --type feature` — multi-story features deserve full /office-hours; hard-rejected with prescribed error message
- `--brief --type user-story` in v1 — deferred to v1.1 against real usage data
- Brief text > 2000 characters — hard cap; longer briefs error out and are pointed at /office-hours
- In-memory state instead of a real file on disk — explicitly rejected to preserve audit trail
- Approach B (new /office-hours --brief mode) — one-refactor promotion path away, but not in v1
- Approach C (--brief on /scaffold-work-item with manual chaining) — explicitly rejected; loses single-keystroke ergonomics

## Success Criteria

- [ ] `/personal-pipeline --brief "<paragraph>" --type defect` produces a green pipeline run end-to-end on a workbench fixture
- [ ] `/personal-pipeline` (no `--brief`) is byte-identical to current behavior on a manual-mode test run
- [ ] `/personal-pipeline --brief "..." --type feature` errors out with the prescribed message; no work-item directory written; no synthesized stub left on disk
- [ ] `/personal-pipeline --brief "..." --type user-story` errors out with the v1.1 follow-up message
- [ ] Synthesized stub design doc is well-formed enough that `/scaffold-work-item` runs successfully without any pipeline.md-internal post-processing
- [ ] The 6-run sunset checkpoint correctly counts brief-mode invocations in `~/.gstack/analytics/personal-pipeline.jsonl` (new `mode` field; default `manual` if absent)
- [ ] `scripts/validate.sh` and `scripts/test.sh` pass post-change
- [ ] Special-character coverage: fixture brief with backtick + `## Header` line correctly insulates stub structure via fenced verbatim block

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000029](S000029_phase0_spike/S000029_TRACKER.md) | Phase 0 spike — parser surface + Step 8.5 scan surface enumeration | Open |
| [S000030](S000030_brief_flag_synth/S000030_TRACKER.md) | --brief flag plumbing + stub synthesis in /personal-pipeline | Open |
| [S000031](S000031_e2e_fixture/S000031_TRACKER.md) | End-to-end brief-mode fixture with special-character coverage | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000029 (Phase 0 spike) | 2026-05-10 | Not Started | chjiang | ~30 min combined; BLOCKING for pipeline.md edits | — |
| 2 | Ship S000030 (--brief flag plumbing + stub synthesis) | 2026-05-12 | Not Started | chjiang | ~50 lines of pipeline.md + flag parsing in SKILL.md + telemetry mode field + 6 Error Handling rows | #1 |
| 3 | Ship S000031 (end-to-end fixture) | 2026-05-13 | Not Started | chjiang | Fixture brief text MUST include backtick + `## Header` line for special-char coverage | #2 |
| 4 | First real brief-mode run on a small TODO | 2026-05-14 | Not Started | chjiang | Bootstrap validation; populates first telemetry line with `mode: brief` | #3 |
| 5 | Update CLAUDE.md skill-routing for brief-mode triggers | 2026-05-14 | Not Started | chjiang | "small task", "quick defect", "lite work item" → `/personal-pipeline --brief` | #2 |
| 6 | v1.1 decision checkpoint: --type user-story for brief mode | 2026-06-15 | Not Started | chjiang | Decision deferred to v1.1 against ≥6 brief-mode invocations | #4 |

### Delivery History

<!-- PR links, merge dates, version bumps. Append-only after ship. -->

- 2026-05-09: Scaffolded F000015 from `chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md` via /scaffold-work-item.

## Dependency Graph

```
#1 S000029 spike  (BLOCKING for pipeline.md edits)
        |
        v
#2 S000030 flag plumbing + stub synthesis
        |
        v
#3 S000031 end-to-end fixture
        |
        v
#4 first real brief-mode run
        |
        +---> #5 CLAUDE.md skill-routing update (parallel; depends on #2)
        |
        v
#6 v1.1 decision checkpoint (after ≥6 brief-mode invocations)
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Does the synthesized stub satisfy `/scaffold-work-item`'s parser surface as-is, or does the template need extension? | S000029 Phase 0.a spike (BLOCKING) |
| Do the stub's `(none, brief mode bypasses ...)` placeholders match any Step 8.5 taste-fork scan pattern? | S000029 Phase 0.b spike (BLOCKING) |
| Should v1.1 add `--type user-story` for brief mode? | Defer to v1.1 decision checkpoint after ≥6 v1 brief-mode invocations |
