---
type: design
parent: F000015
title: "--brief mode for /personal-pipeline — Feature Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Cross-story design for F000015. Story-scope detail (SPEC/TEST-SPEC) lives
     on S000029 (Phase 0 spike), S000030 (flag plumbing + synthesis), and
     S000031 (end-to-end fixture). Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md -->

## Problem

`/personal-pipeline` (and `/scaffold-work-item` underneath) hard-require a
design-doc path under `~/.gstack/projects/{slug}/` as input. For small
work-items (defects, simple tasks, one-line fixes that still warrant a tracked
work-item directory), running a full `/office-hours` session to produce that
design doc is overkill. The user's existing memory captures the principle:
"Skip design for small TODOs, implement directly, don't run /office-hours for
well-scoped P2/P3 tasks." But that memory only covers work that bypasses the
work-item layer entirely. There's a gap: small-but-trackable work currently
has no fast path into `/personal-pipeline`.

A single keystroke from intent-as-paragraph to scaffolded + implemented + qa'd
work-item — `/personal-pipeline --brief "<text>" --type defect` — closes that
gap. The orchestrator silently synthesizes a stub design doc behind the
scenes; the rest of the scaffold/implement/qa flow is byte-identical to manual
mode.

## Shape of the solution

Add `--brief "<text>"` and `--type {task|defect}` flags to `/personal-pipeline`
(v1; `--type user-story` deferred to v1.1). The orchestrator generates a stub
design doc inline before dispatching the scaffold subagent. Reuses 100% of the
existing scaffold/implement/qa flow.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Phase 0 spike: parser-surface check + Step 8.5 scan-surface check | S000029 | [S000029_TRACKER.md](S000029_phase0_spike/S000029_TRACKER.md) |
| `--brief` flag plumbing + stub synthesis in /personal-pipeline (Step 0a + telemetry `mode` field + Error Handling rows) | S000030 | [S000030_TRACKER.md](S000030_brief_flag_synth/S000030_TRACKER.md) |
| End-to-end brief-mode fixture (special-character coverage; verifies fenced verbatim insulation) | S000031 | [S000031_TRACKER.md](S000031_e2e_fixture/S000031_TRACKER.md) |

The pipeline flow once `--brief` is set:

1. **Step 0a (new): Brief Mode branch** — fires before existing Step 1.
   - Validate flag combination (`--brief` requires `--type`; `--type` ∈ {task, defect}; mutually exclusive with positional design-doc path; brief text non-empty and ≤2000 chars).
   - Synthesize stub design doc using template; brief text wrapped in a fenced verbatim block.
   - Write to `~/.gstack/projects/{slug}/{user}-{branch}-design-{datetime}-brief.md`. Collision-suffix `-2`, `-3`, … on rapid re-invocation.
   - Set in-memory design-doc-path to the synthesized stub; continue into existing Step 1.
2. **Existing Step 1+** runs unchanged. Synthesized stub by construction has no SCAFFOLDED footer and no tracker references → always lands in clean-slate branch (4th of the 4 idempotency branches).
3. **Telemetry write at end of pipeline** gains an additive `mode` field. Values: `manual`, `auto`, `brief`, `brief+auto`. Sunset-checkpoint parser must default to `manual` if absent (one-line additive change).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (inline brief synthesis in /personal-pipeline) over B (new /office-hours --brief mode) and C (--brief on /scaffold-work-item with manual chaining) | Smallest diff (~50 lines); 100% backward compat; preserves audit trail (real file on disk indistinguishable from manual /office-hours docs from /scaffold-work-item's perspective); single-keystroke ergonomics preserved; one-refactor promotion path to B if more lite modes (`--template`, `--revision`) appear later. |
| 2 | `--brief` is locked to `--type {task, defect}` in v1; `--type user-story` deferred to v1.1 | Spec-review iteration 1 narrowing. user-story-as-brief should be evaluated against real usage data, not pre-judged. Multi-story features deserve full /office-hours by construction. |
| 3 | Brief text wrapped in a fenced verbatim block (` ```text ` ... ` ``` `) inside the synthesized stub | Insulates stub structure from backticks, `## `-prefixed lines, and other Markdown structures inside the brief. Structural safety > template prettiness. |
| 4 | Phase 0 spike is BLOCKING for any pipeline.md edits | Two load-bearing unverified premises: (a) the synthesized stub satisfies `/scaffold-work-item`'s parser surface; (b) the stub's `(none, brief mode bypasses ...)` placeholders cannot match Step 8.5's taste-fork scan patterns. Either outcome workable but the design changes shape (extend stub vs harden stub vs escalate to Approach B). |
| 5 | Synthesize a real file on disk under `~/.gstack/projects/{slug}/`, not in-memory state | Preserves audit trail; editable post-hoc; indistinguishable from manual `/office-hours` docs from `/scaffold-work-item`'s perspective; idempotency-on-re-invocation works the same way as manual mode (existing Step 1 logic unchanged). |
| 6 | Mutual exclusivity: `--brief` and a positional design-doc path are mutually exclusive | Avoid an ambiguous "did the user want the stub or the file?" branch. Error out with a clear message and write nothing. |
| 7 | Length cap: `--brief` text ≤2000 characters after whitespace trim | A paragraph longer than 2000 chars is by definition not "brief" and should go through `/office-hours`. Prevents abuse of the fast path. |
| 8 | Filename collision-suffix starts at `-2`; the un-suffixed filename is the implicit `-1` slot | `-1` reserved as a no-op alias and is never written. Explicit grammar prevents drift in collision handling. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `/scaffold-work-item`'s parser may require a field absent from the synthesized stub template | S000029 Phase 0.a spike; if missing, extend template (preferred) or escalate to Approach B (deferred, document in TODOS.md) |
| `/personal-pipeline` Step 8.5 scan surface may match a `(none, brief mode bypasses ...)` placeholder as a taste-fork | S000029 Phase 0.b spike; if it matches, harden stub (omit those sections, or use a sentinel string scanner refuses to match) |
| Existing telemetry consumer (sunset checkpoint at line ~204 of pipeline.md) needs to handle the new `mode` field gracefully | S000030 includes the one-line parser change; verified by S000031 fixture |
| Special-character handling: backticks/`## `-prefixed lines in brief text could break stub structure | S000031 fixture brief text MUST include backtick + `## Header` line to verify the fenced verbatim block correctly insulates |
| Filename collision (rapid re-invocation within the same second) | Collision-suffix rule (`-2`, `-3`, …); covered by S000031 fixture |
| `--brief --type user-story` in v1.1: should we accept against real usage data? | Defer to v1.1 against ≥6 v1 invocations of brief mode; if users hand-modify briefs to scope user-stories, accept and add. If users use /office-hours for user-stories anyway, drop. |

## Definition of done

- [ ] S000029 Phase 0 spike committed: parser fields enumerated, Step 8.5 scan surface enumerated, stub satisfies both (yes/no), action taken (extend/harden/escalate). 10–15 line combined note in S000029 TRACKER journal.
- [ ] `skills/personal-pipeline/SKILL.md` Usage section documents `--brief "<text>" --type {task|defect}`; six new rows appended to Error Handling table; version bumped.
- [ ] `skills/personal-pipeline/pipeline.md` has Step 0a (Brief Mode) before existing Step 1; telemetry write gains `mode` field; sunset-checkpoint parser defaults to `manual` if absent.
- [ ] `skills/personal-pipeline/fixtures/` has a brief-mode end-to-end smoke fixture (special-character coverage verified).
- [ ] `/personal-pipeline --brief "Fix SIGPIPE race in scripts/test.sh D5 blocks" --type defect` produces a green pipeline run end-to-end.
- [ ] `/personal-pipeline` (no `--brief`) is byte-identical to current behavior on a manual-mode test run.
- [ ] `/personal-pipeline --brief "..." --type feature` errors out with the prescribed message; no work-item directory written; no synthesized stub left on disk.
- [ ] `/personal-pipeline --brief "..." --type user-story` errors out with the v1.1 follow-up message.
- [ ] `scripts/validate.sh` and `scripts/test.sh` pass post-change.
- [ ] CLAUDE.md skill-routing section updated with brief-mode trigger phrases (e.g. "small task", "quick defect", "lite work item" → `/personal-pipeline --brief`).

## Not in scope

- **`--brief --type feature`** — multi-story features deserve full /office-hours by construction. Hard-rejected with a prescribed error message.
- **`--brief --type user-story` in v1** — deferred to v1.1 against real usage data; v1 errors with the prescribed message pointing to /office-hours.
- **Brief text > 2000 chars** — hard cap; longer briefs error out and are pointed at /office-hours.
- **In-memory state instead of a real file on disk** — explicitly rejected; we synthesize a real file under `~/.gstack/projects/{slug}/` to preserve audit trail.
- **Approach B (new /office-hours --brief mode)** — promotion path is one refactor away if more lite modes (`--template`, `--revision`) appear later, but not in v1.
- **Approach C (--brief on /scaffold-work-item)** — explicitly rejected; loses single-keystroke ergonomics and breaks /scaffold-work-item's "design doc is source of truth" invariant.

## Pointers

- Parent tracker: [F000015_TRACKER.md](F000015_TRACKER.md)
- Roadmap: [F000015_ROADMAP.md](F000015_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md`
- Builds on: F000014 (the `/personal-pipeline` orchestrator this feature extends)
- Related principle: user MEMORY.md "Skip design for small TODOs" — brief mode closes the gap that memory entry leaves open at the work-item-creation layer
