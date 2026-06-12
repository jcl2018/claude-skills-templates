---
type: design
parent: S000102
title: "Audit skills + two-tier spec files + QA checkpoint + test-pipeline demolition — Story Design"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
reviewers: []
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session — per tracker-user-story.md, this DESIGN is a brief stub; the
     authoritative cross-story design lives in the parent's
     F000060_DESIGN.md. All 7 sections kept (structural completeness is
     enforced by /CJ_personal-workflow check); content is intentionally
     brief. -->

## Problem

See [../F000060_DESIGN.md](../F000060_DESIGN.md) `## Problem`: no
operator-facing verb answers "do this repo's docs/tests follow their
contracts?" in an arbitrary repo, and no cj_goal moment surfaces those
answers before ship budget is spent; the doc contract's custom half is fused
into the seed-blocking single file, and the test contract exists only as the
undeliverable workbench-specific 66-row test-pipeline registry. This story
builds the entire fix — including the test-pipeline demolition — in one
atomic unit.

## Shape of the solution

One PR delivering: the doc-spec general/custom file split (general ==
`--seed` byte-identical, `front_table` promoted into the seed schema),
`doc-spec.sh` overlay merge, the NEW `spec/test-spec.md` seed +
`spec/test-spec-custom.md` overlay (verbatim row migration), the NEW
`scripts/test-spec.sh` full-parity parser/coverage engine, the
`/CJ_doc_audit` + `/CJ_test_audit` skills, QA Steps 8.6a–d + the extended
RESULT/AUDIT_FINDINGS contract, the always-prompt checkpoint AUQ in all four
pipelines + the gate-spec `qa-audit` row, the F000059 demolition with its
enumerated reference sweep (a first-class deliverable, not cleanup), the
document-release seeding-path updates, the zero-AUQ wording sweep, and three
new registered test suites. See [S000102_SPEC.md](S000102_SPEC.md)
`## Architecture` for the data flow.

## Big decisions

Owned by the parent: see [../F000060_DESIGN.md](../F000060_DESIGN.md)
`## Big decisions` (D5.1 spec/-only home; D5.2 demolition over coexistence;
D5.3 overlay-file migration with internal merge; D5.4 always-prompt
checkpoint; D6 full parser parity; front_table seed promotion; verbatim row
shape; audit-findings-ride-green-RESULT; REGISTRY=absent + units-gated
floor). Story-local tradeoffs are recorded in
[S000102_SPEC.md](S000102_SPEC.md) `## Tradeoffs`.

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Seed lockstep (general file + heredoc + template copy) breaks in a half-state | tests/doc-spec-overlay.test.sh byte-identity assertion + pre-commit validate.sh; single-commit atomicity per parent risk table |
| Step 8.6d self-application flags the orchestrators stale on this feature's own run | Zero-AUQ wording sweep lands same-PR; verified at this story's own QA (success criterion 6) |
| Demolition sweep misses a `test-pipeline` reference | Sweep is enumerated in SPEC Requirements; criterion-3 grep is the backstop |
| Nested-subagent wall breaks 8.6c/8.6d dispatch | Audit skill logic executes INLINE by the QA agent reading the skill files; dual posture documented in both skills |
| test.sh restore-trap clobbers concurrent edits; CI shellcheck stricter than local | No tree mutations during test.sh runs; verify new shell under no-rc shellcheck (parent Todos coordinate rows) |

## Definition of done

The parent's Definition of done is carried 1:1 by this story — see
[../F000060_DESIGN.md](../F000060_DESIGN.md) and this story's
`## Acceptance Criteria` in [S000102_TRACKER.md](S000102_TRACKER.md) for the
expanded, testable form (two-tier files + merge + parser parity + both
skills + QA wiring + checkpoint in all four pipelines + demolition complete
+ document-release alignment + wording sweep + registered tests, all green).

## Not in scope

See [../F000060_DESIGN.md](../F000060_DESIGN.md) `## Not in scope`: no
generated readable view for the test-spec registry (deferred TODOS row), no
concern-taxonomy work (struck as obsolete, re-evaluated later), no
portability-gate false-halt fix (separate row), no upstream gstack
modification, no multi-story decomposition, no determinism reduction (the
Check-24 engine is ported in full).

## Pointers

- Parent feature design: [../F000060_DESIGN.md](../F000060_DESIGN.md)
- Parent tracker: [../F000060_TRACKER.md](../F000060_TRACKER.md)
- Roadmap: [../F000060_ROADMAP.md](../F000060_ROADMAP.md)
- Story tracker: [S000102_TRACKER.md](S000102_TRACKER.md)
- Spec: [S000102_SPEC.md](S000102_SPEC.md)
- Test spec: [S000102_TEST-SPEC.md](S000102_TEST-SPEC.md)
- Source design doc (the scaffold input; carries the seed-equality resolution + the enumerated reference sweep): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-unruffled-kalam-e25974-design-20260612-140815.md`
- Donor machinery being retired: `work-items/features/ops/F000059_test_pipeline_generated_view/`
