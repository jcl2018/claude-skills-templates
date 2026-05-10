---
type: design
parent: S000031
title: "End-to-end brief-mode fixture — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Atomic-story design. See parent F000015_DESIGN.md for cross-story context.
     Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md -->

## Problem

Without a fixture, brief-mode regressions land silently — especially structural breakage from special characters in brief text (backticks, `## `-prefixed lines). S000030 ships a manually-smokeable change; S000031 ships the durable regression net.

## Shape of the solution

A new fixture directory under `skills/personal-pipeline/fixtures/brief-mode/`. The fixture exercises:

1. A trivial known-good defect-typed brief invocation that runs scaffold + implement + qa green end-to-end.
2. Brief text with intentional backtick + `## Header` line to verify fenced verbatim insulation.
3. Telemetry assertion: written line has `mode: "brief"`.
4. Regression assertion: a legacy telemetry line without `mode` is parsed as `manual` (verifies S000030's parser default).

`scripts/test.sh` wires the fixture into the standard test run.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single combined fixture covers all four checks | Lower overhead than four separate fixtures; the brief invocation, structural-safety check, telemetry check, and parser-default check are all one logical end-to-end. |
| 2 | Brief text deliberately contains backtick + `## Header` line | Forcing function for special-character coverage; without it, the fixture is just happy-path smoke. |
| 3 | Fixture runs against a synthetic / fake target work-item, not a real shipping change | Fixture must be deterministic and self-cleaning; we mock or stub the implement subagent's target so reruns are idempotent. |
| 4 | Concurrent-invocation race is NOT exercised | Accepted risk per parent F000015; fixture would need locking primitives to test deterministically. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Fixture's mock target work-item may drift from real shipping work-items in shape | Audit on each /personal-pipeline change; if fixture target shape diverges, refresh the mock |
| Telemetry assertion may produce false positives if `mode` field is added at the wrong layer | Inspect actual telemetry write in S000030; ensure assertion targets the right JSON field path |
| Test runtime may grow significantly (full pipeline = 3 subagents) | Accept; brief-mode fixture is opt-in via `scripts/test.sh` invocation; CI can choose to skip if needed |

## Definition of done

- [ ] Fixture directory exists with the brief text containing backtick + `## Header` line
- [ ] `scripts/test.sh` includes the fixture in its standard run
- [ ] Fixture asserts: stub file is well-formed; scaffold/implement/qa green; telemetry has `mode: "brief"`; legacy telemetry parses as `manual`
- [ ] Fixture is rerunnable / idempotent (cleans up after itself)

## Not in scope

- Concurrent-invocation race testing (accepted risk per parent F000015)
- Performance profiling / runtime benchmarks
- Brief-mode `--auto` combination as a separate fixture (combined check inside the same fixture is sufficient for v1)

## Pointers

- Parent tracker: [S000031_TRACKER.md](S000031_TRACKER.md)
- Parent feature design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md`
- Blocked by: [S000030_TRACKER.md](../S000030_brief_flag_synth/S000030_TRACKER.md)
- Files modified: `skills/personal-pipeline/fixtures/brief-mode/` (new), `scripts/test.sh`
