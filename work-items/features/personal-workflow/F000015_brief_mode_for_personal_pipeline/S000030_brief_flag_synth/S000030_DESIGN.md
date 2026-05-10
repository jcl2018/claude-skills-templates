---
type: design
parent: S000030
title: "--brief flag plumbing + stub synthesis in /personal-pipeline — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Atomic-story design. See parent F000015_DESIGN.md for cross-story context.
     Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md -->

## Problem

`/personal-pipeline` doesn't yet accept `--brief` or synthesize stub design docs. To close the friction documented in F000015's DESIGN, the orchestrator needs a new Step 0a (flag parsing + validation + synthesis + filename collision) that runs BEFORE existing Step 1 (pre-scaffold idempotency check). The change MUST be byte-identical to current behavior when `--brief` is absent.

## Shape of the solution

Two file edits scoped tightly:

**`skills/personal-pipeline/SKILL.md`:**
- Update Usage section to document `--brief "<text>" --type {task|defect}`.
- Append six rows to the Error Handling table (verbatim from parent DESIGN).
- Bump `version` field in frontmatter.

**`skills/personal-pipeline/pipeline.md`:**
- Add Step 0a (Brief Mode) BEFORE existing Step 1.
- Add `mode` field to telemetry write at end of pipeline.
- Update sunset-checkpoint parser to default to `manual` if `mode` absent (one-line change).

Step 0a logic:

1. Parse args. If `--brief` is set: validate combination (mutual exclusivity with positional path; `--type` required, ∈ {task, defect}; brief text non-empty and ≤2000 chars after whitespace trim).
2. If validation fails: emit prescribed error message verbatim, exit clean.
3. Otherwise: synthesize stub design doc (template in parent DESIGN); brief text wrapped in fenced verbatim block.
4. Compute filename `{user}-{branch-with-slashes-as-dash}-design-{YYYYMMDD-HHMMSS}-brief.md`. If exists, append `-2`, `-3`, … (un-suffixed = implicit `-1`; never written suffixed `-1`).
5. Write stub to `~/.gstack/projects/{slug}/{filename}`.
6. Set in-memory design-doc-path to the synthesized stub. Continue into existing Step 1.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Step 0a fires BEFORE Step 1, not as part of Step 1 | Existing Step 1 logic is unchanged. Synthesized stubs by construction land in the clean-slate branch (no footer, no tracker refs). Easier to reason about and easier to revert if Step 0a regresses. |
| 2 | Six error rows are verbatim copies of parent DESIGN's prescribed messages | Behavioral examples in DESIGN must match shipped code; verbatim copy avoids drift. |
| 3 | Telemetry `mode` field is additive, not replacement | Existing parsers default to `manual` if absent → 100% backward compatible. Sunset checkpoint reads the new field; one-line parser change is the only consumer impact. |
| 4 | Filename grammar is enforced explicitly (regex documented in parent DESIGN) | Prevents collision-suffix drift; `-1` is reserved as a no-op alias. |
| 5 | Brief text wrapped in fenced verbatim block | Insulates stub structure from backticks, `## `-prefixed lines, and other Markdown — verified by S000031 fixture. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| S000029 verdict not yet known: parser may need stub template extension | BLOCKING; S000030 cannot start until S000029 ships verdict |
| S000029 verdict not yet known: Step 8.5 scan may match a placeholder | BLOCKING; if matches, S000030 must use sentinel placeholders or omit sections |
| Filename collision (rapid re-invocation) is exercised correctly | S000031 fixture; not in S000030 acceptance |

## Definition of done

- [ ] SKILL.md Usage section + 6 Error Handling rows + version bump
- [ ] pipeline.md Step 0a + telemetry `mode` field + sunset-parser default
- [ ] Manual smoke: `/personal-pipeline --brief "..." --type defect` synthesizes a stub at expected path with valid contents
- [ ] Manual smoke: `/personal-pipeline` (no `--brief`) shows zero behavioral change against a known manual run
- [ ] Manual smoke: 4 error paths produce prescribed messages and write nothing on disk
- [ ] `scripts/validate.sh` passes

## Not in scope

- End-to-end fixture (S000031 owns; this story produces a manually-smokeable change)
- CLAUDE.md skill-routing trigger phrases (parent F000015 todo; not blocking S000030)
- Approach B promotion (deferred regardless of v1 outcome)

## Pointers

- Parent tracker: [S000030_TRACKER.md](S000030_TRACKER.md)
- Parent feature design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md`
- Blocked by: [S000029_TRACKER.md](../S000029_phase0_spike/S000029_TRACKER.md)
- Files modified: `skills/personal-pipeline/SKILL.md`, `skills/personal-pipeline/pipeline.md`
