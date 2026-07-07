---
type: design
parent: S000136
feature: F000087
title: "Retire the eval runner, keep the specs + Check 28 gate — Story Design"
version: 1
status: Draft
date: 2026-07-06
author: chang
reviewers: []
---

<!-- The user-story design doc. For an atomic story that derives directly from
     the parent feature's /office-hours session, this is a brief stub linking to
     the parent — CONTENT brevity is fine, but all seven sections are kept
     (section completeness is enforced by /CJ_personal-workflow check). -->

## Problem

The paid `run-eval` harness (`scripts/eval.sh`, `tier: paid`) spends metered
model money per eval case. This story deletes it and reframes the `tests/eval/`
cases as durable in-session verification specs, WITHOUT breaking the free
structural gates (Check 24 coverage cross-check, Check 28 workflow coverage). See
the parent [F000087_DESIGN.md](../F000087_DESIGN.md) for the full problem shape.

## Shape of the solution

One coherent PR, in order: delete `scripts/eval.sh` + sweep callers → edit
`spec/test-spec-custom.md` (remove the `run-eval` `runners:` row, re-anchor
`suite-eval` onto the `tests/eval/` specs, reframe the `run-test-sh` `covers:`
note, remove the two `goal-*-eval` `categories:` rows, drop `cj-goal-eval` from
the unenrolled-topics prose) → edit `spec/doc-spec-custom.md` + delete the two
front-door docs + reconcile `docs/tests/index.md` → de-leak the eval prompts
(preserve the anchors) → regenerate catalogs. Requirements + architecture detail
live in [S000136_SPEC.md](S000136_SPEC.md); test rows in
[S000136_TEST-SPEC.md](S000136_TEST-SPEC.md).

## Big decisions

- Approach C (remove the two `categories:` rows + front-door docs; keep the
  `behaviors:`/`behavior_coverage:` axis + `tests/eval/` dirs + Check 28) — least
  surface, nothing to break. Full rationale + rejected A/B in the parent DESIGN's
  Big decisions table.
- `suite-eval` re-anchors off `source: scripts/eval.sh` onto a live `tests/eval/`
  `source` + `anchor` (chosen at implementation time) so Check 24's forward
  anchor-grep stays green after the delete.
- The eval family stays DECLARED (not orphaned): `run-test-sh` keeps `eval` in
  `covers:`; the `suite-eval` unit keeps `family: eval`.

## Risks & open questions

- `--check-structure` (b): confirm removing the two rows doesn't leave a required
  `tests/workflow/local-hook/` subfolder empty (doc-sync + e2e-local remain).
- De-leaking prompts must PRESERVE the `behavior_coverage` anchor strings Check 28
  greps. See the parent DESIGN's Risks table for the full list.

## Definition of done

See [S000136_SPEC.md](S000136_SPEC.md) `## Acceptance Criteria` and the parent
[F000087_DESIGN.md](../F000087_DESIGN.md) `## Definition of done`. In short:
`scripts/eval.sh` + the `run-eval` row GONE with no dangling reference;
`validate.sh` GREEN (Checks 24/26/27/28/30); `/CJ_test_audit` reports no orphaned
eval family; the `tests/eval/` prompts are honest + non-leaking; `test.sh` passes.

## Not in scope

- A new `/CJ_verify` skill or any wrapper; Phase 2 of the roadmap; editing
  CHANGELOG; portability un-enroll. See the parent DESIGN's Not-in-scope section.

## Pointers

- Parent design: [../F000087_DESIGN.md](../F000087_DESIGN.md)
- Parent tracker: [../F000087_TRACKER.md](../F000087_TRACKER.md)
- This story: [S000136_TRACKER.md](S000136_TRACKER.md) · [S000136_SPEC.md](S000136_SPEC.md) · [S000136_TEST-SPEC.md](S000136_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-vigorous-mcclintock-e72fcb-design-20260706-165302.md` (APPROVED)
