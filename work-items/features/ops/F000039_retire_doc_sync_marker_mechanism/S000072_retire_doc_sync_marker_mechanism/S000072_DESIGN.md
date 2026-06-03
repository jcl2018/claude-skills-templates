---
type: design
parent: S000072
title: "Retire the doc-sync marker + preamble-AUQ retirement surface — Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- Atomic user-story design. Brief by intent — the cross-story design lives in
     the parent feature F000039_DESIGN.md; this stub adds story-local framing and
     defers the rest. Section completeness is enforced by /CJ_personal-workflow
     check; each section carries at least a sentence. -->

## Problem

The F000028/F000029 doc-sync marker-AUQ mechanism became redundant once F000036
made doc-sync run inline at Step 5.5; its `DOC_SYNC_PENDING` AUQ now fires for
drift already folded into the same PR (operator-flagged obsolete in v6.0.8). This
story executes the full retirement. See parent [F000039_DESIGN.md](../F000039_DESIGN.md)
for the complete problem framing, including the critical "doc-sync names TWO
mechanisms" distinction.

## Shape of the solution

One cohesive de-referencing change: delete the detection script + its 2 tests,
strip the preamble AUQ block from the 2 orchestrators that carry it, strike the
stale "F000029 fallback" language (~9 locations), surgically edit `setup-hooks.sh`
(remove post-merge Section 3 + post-rewrite hook; keep pre-commit + Sections 1+2),
delete F000028/F000029 doc content, fix 2 stale config-parser comments, and
regenerate README. The file-by-file surface is in SPEC.md `### Components Affected`.
The F000036 Step 5.5 survivor is left untouched (see SPEC PRESERVE rows).

## Big decisions

Inherits the parent feature's decisions (Approach A full-delete; KEEP the F000037
config parser; single atomic story). See [F000039_DESIGN.md](../F000039_DESIGN.md)
`## Big decisions`. Story-local: the two completeness greps are the acceptance
gate for "retirement is complete," not just a passing test suite.

## Risks & open questions

Primary risk is deleting survivor coverage by conflating the two "doc-sync"
mechanisms; mitigated by the explicit DIES-vs-PRESERVE split in SPEC.md and the
TEST-SPEC assertion that `tests/cj-goal-doc-sync-wiring.test.sh` still passes. See
parent [F000039_DESIGN.md](../F000039_DESIGN.md) `## Risks & open questions` for
the full table.

## Definition of done

`validate.sh` + `test.sh` exit 0, both completeness greps return zero live
references, the survivor wiring test still passes, both preambles are clean, the
hook edit preserves Sections 1+2, README is regenerated, and the accepted-gap note
exists in CLAUDE.md. Full measurable list in SPEC.md `## Acceptance Criteria` and
TEST-SPEC.md.

## Not in scope

Touching the F000036 Step 5.5 survivor; building a replacement reminder for the
rare non-/ship path; deleting F000028/F000029 history; editing CHANGELOG.md
directly; removing runtime `~/.gstack/` state files. See parent
[F000039_DESIGN.md](../F000039_DESIGN.md) `## Not in scope`.

## Pointers

- Parent feature design: [../F000039_DESIGN.md](../F000039_DESIGN.md)
- This story's spec: [S000072_SPEC.md](S000072_SPEC.md)
- This story's test spec: [S000072_TEST-SPEC.md](S000072_TEST-SPEC.md)
- Story tracker: [S000072_TRACKER.md](S000072_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-140631-39060-design-20260603-141622.md`
