---
type: design
parent: F000068
title: "The --phase recap formatter — Story Design"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
reviewers: []
---

<!-- Brief stub. Full design context lives in the parent feature design. -->

## Problem

The four cj_goal orchestrators each hand-author their land/PR recap as prose, so
the shape drifts. A shared formatter is needed so the recap shape is uniform
wherever it is emitted. This story builds that formatter as a new `recap` phase
on the existing shared dispatcher `scripts/cj-goal-common.sh`.

## Shape of the solution

Add a `recap` case to `cj-goal-common.sh`'s `--phase` dispatch. It takes
`--when {before|after}`, `--mode {feature|defect|task|todo_fix}` (labelling
only), and the recap content via the existing repeatable `--field KEY=VALUE`
parsing (`delivered`, `e2e`, `next`). It prints a header (keyed off `--when`) and
the three labelled sections **Delivered / How to E2E-test it / Next step** to
stdout, then emits `PHASE=recap` + `PHASE_RESULT=ok` and exits 0. It computes no
content, mutates nothing, writes no telemetry. Missing fields render empty
sections (fail-soft). See the parent design for the full rationale.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Reuse the telemetry phase's `--field` parser | It already handles repeatable fields + safe verbatim printing (no eval). Re-inventing risks an escaping bug. |
| 2 | Fail-soft: exit 0 + empty section on missing field | The recap is advisory; a missing field must never break a run. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `--field` multi-line / special-char content must render verbatim | Assert in `tests/cj-goal-common-recap.test.sh`; reuse the telemetry parser as the reference. |
| A new `tests/*.test.sh` needs a `spec/test-spec-custom.md` units row | Add the row in this story; verify via `test-spec.sh --check-coverage`. |

## Definition of done

- [ ] `--phase recap` renders the header + three labelled sections, `PHASE_RESULT=ok`, exit 0.
- [ ] Missing field ⇒ empty section, still exit 0.
- [ ] New hermetic test green; test-spec units row present; `test.sh` + `validate.sh` + `test-spec.sh` green.

## Not in scope

- Wiring the helper into the four pipelines (that is S000113).
- Any `validate.sh` gate (advisory posture, parent decision).
- The helper computing content on its own.

## Pointers

- Parent feature design: [../F000068_DESIGN.md](../F000068_DESIGN.md)
- Parent tracker: [../F000068_TRACKER.md](../F000068_TRACKER.md)
- Spec: [S000112_SPEC.md](S000112_SPEC.md)
- Test-spec: [S000112_TEST-SPEC.md](S000112_TEST-SPEC.md)
