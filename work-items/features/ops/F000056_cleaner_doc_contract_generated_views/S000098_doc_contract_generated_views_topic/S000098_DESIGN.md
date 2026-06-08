---
type: design
parent: S000098
title: "Generated general/custom doc views + philosophy Doc-contract topic — Story Design"
version: 1
status: Draft
date: 2026-06-08
author: chjiang
reviewers: []
---

<!-- Atomic story: derives directly from the parent feature's /office-hours session.
     See parent F000056_DESIGN.md for full context. Sections are brief but complete. -->

## Problem

`doc-spec.md` carries a hand-maintained table that duplicates its own machine
registry, the readable general/custom split the operator wants does not exist, and the
contract's *why* is scattered. This story implements the 8 deltas that fix all three
without breaking the contract. See parent [F000056_DESIGN.md](../F000056_DESIGN.md).

## Shape of the solution

Eight deltas, in order: (1) `doc-spec.sh --render general|custom` (separate awk pass,
quote-strip, pipe-escape); (2) `scripts/generate-doc-views.sh` (`--output-dir`); (3)
the two generated `docs/` views; (4) two Custom registry entries; (5) slim the Custom
prose to a pointer (keep the "Repo notes" rationale; Common section untouched); (6)
`philosophy.md` `## Topic: Doc contract` (move the 2 principles, update front-table
labels); (7) `validate.sh` Check 23 in-sync + `test.sh` stdout-only mirror; (8)
`generate-readme.sh:23` blurb + README regen.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Separate awk pass for `--render` (not `_parse_registry`) | 3-col TSV mis-binds a 4th field; `purpose:`/`requirement:` are quoted multi-word free-form |
| 2 | Check 23 generator-based + `test.sh` mirror stdout/temp-only | No regenerate-and-diff idiom to mirror; the EXIT trap does not restore `docs/` |
| 3 | Registry entries + generated files in ONE commit | Else Check 15a fails declared-but-missing/orphan mid-build |
| 4 | Common seed section untouched | Byte-identical to the seed (test #13); shared by consumer repos |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Render columns: 3-column vs adding "Present?" | SPEC pins 3-column (determinism); "Present?" deferred |
| Mid-build orphan if registry + files split across commits | TEST-SPEC E2E verifies they land together (Check 15a green) |

## Definition of done

- [ ] All 8 deltas implemented; `validate.sh` + `test.sh` green; Check 19/20/23 green; seed test #13 green; portability green.
- [ ] Render row sets exact (general=4, custom=9); views in sync; PR opens and STOPS.

## Not in scope

- Extending the Common/portable seed for auto-generated views in consumer repos — deferred follow-up.
- Auto-regen of views on `/ship` — v1 manual, gated by Check 23.
- A "Present?" render column — deferred.

## Pointers

- Parent feature design: [../F000056_DESIGN.md](../F000056_DESIGN.md)
- Spec: [S000098_SPEC.md](S000098_SPEC.md)
- Test spec: [S000098_TEST-SPEC.md](S000098_TEST-SPEC.md)
- Tracker: [S000098_TRACKER.md](S000098_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-sleepy-cerf-e8f24b-design-20260608-doc-contract.md`
