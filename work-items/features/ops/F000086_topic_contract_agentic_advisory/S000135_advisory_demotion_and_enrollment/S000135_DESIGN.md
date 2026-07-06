---
type: design
parent: S000135
title: "Advisory agentic demotion + validator/full-suite enrollment — Story Design"
version: 1
status: Draft
date: 2026-07-06
author: chang
reviewers: []
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session — brief per-section content per the tracker template's stub
     guidance; the full cross-story design lives in the parent
     F000086_DESIGN.md. -->

## Problem

The three-layer topic contract's hard local-hook+agentic requirement blocks
enrollment of topics whose deterministic surfaces already run today; only
`portability` is enrolled. See parent [F000086_DESIGN.md](../F000086_DESIGN.md)
`## Problem` for the full context.

## Shape of the solution

One coherent change set, implemented in the parent design's order: engine loop
change (`_run_topic_contract` advisory demotion) → general prose + `_emit_seed`
mirror → overlay (enrollment + 4 honest `categories:` rows) → front-door docs +
index → dream docs + topic subdirs + doc-spec declarations → Check 30 drill
rewrite → prose sweep. Story-scope detail lives in
[S000135_SPEC.md](S000135_SPEC.md).

## Big decisions

Inherited from the parent (see F000086_DESIGN.md `## Big decisions`): global
advisory demotion (Approach C, D4 informed reversal), layers stay HARD,
honest-rows-only enrollment, deploy-harness stays unenrolled, byte-identical
seed mirror, /CJ_test_audit Stage-1 wiring fix.

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Seed-identity break from an imperfect `_emit_seed` mirror | Smoke S4 (seed byte-identity diff) before ship |
| Check 26 catalog staleness after the `validate-check-30` / `validate-check-31` row rewording | Run `test-spec.sh --render-docs` regen; validate.sh Check 26 |
| Check 24 anchor break from rewording the validate.sh Check 30 banner | Preserve the literal `"=== Check 30:"` anchor; validate.sh Check 24 |

## Definition of done

The parent's Definition of done, verified through this story's TEST-SPEC rows
(smoke S1–S5, E2E E1–E2). See [F000086_DESIGN.md](../F000086_DESIGN.md)
`## Definition of done`.

## Not in scope

Same boundary as the parent (F000086_DESIGN.md `## Not in scope`):
deploy-harness + remaining topics stay unenrolled, no per-topic flavor, no new
agentic tests, no festive-margulis edits, no `/CJ_test_run` SKILL.md `--topic`
prose fix, no new per-PR CI workload.

## Pointers

- Parent feature design: [F000086_DESIGN.md](../F000086_DESIGN.md)
- Parent tracker: [F000086_TRACKER.md](../F000086_TRACKER.md)
- Story tracker: [S000135_TRACKER.md](S000135_TRACKER.md)
- Spec: [S000135_SPEC.md](S000135_SPEC.md)
- Test spec: [S000135_TEST-SPEC.md](S000135_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-practical-kilby-0ee2a8-design-20260706-021054.md`
