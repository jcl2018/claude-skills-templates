---
type: design
parent: S000103
title: "--check-on-disk Stage-1 engine + three-stage restructure of both audit skills + fresh-context dispatch + per-stage reports — Story Design"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
reviewers: []
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session — per tracker-user-story.md, this DESIGN is a brief stub; the
     authoritative cross-story design lives in the parent's
     F000061_DESIGN.md. All 7 sections kept (structural completeness is
     enforced by /CJ_personal-workflow check); content is intentionally
     brief. -->

## Problem

See [../F000061_DESIGN.md](../F000061_DESIGN.md) `## Problem`: F000060's
audit skills landed with prose-described Stage-1 bash (re-derived per run —
the dogfood hit the word-split gotcha: two phantom findings + one vacuous
check), evidence-free Stage-2 judgment (resident-context rubber-stamping),
and no Stage 3 at all (nothing cross-walks doc CONTENT against live repo
state). This story builds the entire hardening — engine, both skill
restructures, dispatch, reports, sweep, tests — in one atomic unit.

## Shape of the solution

One PR delivering: the NEW `doc-spec.sh --check-on-disk` subcommand (6
deterministic checks against the merged registry; registry-absent probe
BEFORE the parse gates; orphans counts a non-self-declaring overlay;
`while IFS= read -r` loops; env overrides), the three-stage restructure of
`/CJ_doc_audit` AND `/CJ_test_audit` (Stage 1 = engine calls; Stage 2 =
clause-by-clause evidence-cited requirement verdicts with the
`satisfies`/`missing-requirement (soft)`/`n/a`/`FINDING: stage2/` grammar;
Stage 3 = ground-truth enumeration + drift cross-walk), the REQUIRED
fresh-context subagent dispatch standalone (+ `Agent` tool in both skills +
catalog; in-QA inline), the per-stage report contract
(`STAGE1/2/3_FINDINGS=` + sections + `stageN/` prefixes; pre-stage findings
as STAGE1; skipped-stage grammar), qa.md's AUDIT_FINDINGS per-stage template
(four pipelines: ZERO edits), the docs/catalog sweep + TODOS convergence
row, and the two extended test suites. See
[S000103_SPEC.md](S000103_SPEC.md) `## Architecture` for the data flow.

## Big decisions

Owned by the parent: see [../F000061_DESIGN.md](../F000061_DESIGN.md)
`## Big decisions` (D10.1 engine subcommand; D10.2 REQUIRED fresh-context
dispatch with honest in-QA degradation; D10.3 both audits symmetrically;
D11 validate.sh untouched; the registry-absent probe carve-out; the
orphan-overlay decision; table-block views-render comparison; pre-stage
findings as STAGE1; the extends-never-breaks report contract; extend-suites-
not-new-suites). Story-local tradeoffs are recorded in
[S000103_SPEC.md](S000103_SPEC.md) `## Tradeoffs`.

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Seeded violations in the `--check-on-disk` battery don't isolate (one violation flips multiple check ids) | The extended doc-spec-overlay battery asserts each violation flips EXACTLY its own `FINDING: stage1/<id>` |
| `Agent` tool addition missed in either surface (frontmatter vs catalog `depends.tools`) makes D10.2 impossible | Both surfaces edited in the same commit; QA smoke greps both |
| architecture.md ~L285–296 stale passage survives the sweep and this run's own Stage 2/3 dogfood flags it | Rewritten in the same PR; E2E row verifies |
| SKILL.md edits flip Check 14 USAGE.md drift on both skills | USAGE.mds updated with real content same-PR (normal path) |
| test.sh restore-trap clobbers concurrent edits; CI shellcheck stricter than local | No tree mutations during test.sh runs; verify modified doc-spec.sh under no-rc shellcheck (parent Todos coordinate rows) |

## Definition of done

The parent's Definition of done is carried 1:1 by this story — see
[../F000061_DESIGN.md](../F000061_DESIGN.md) and this story's
`## Acceptance Criteria` in [S000103_TRACKER.md](S000103_TRACKER.md) for the
expanded, testable form (engine output contract + carve-out + both skill
restructures with the full verdict grammars + dispatch + per-stage reports +
qa.md template with zero pipeline edits + docs sweep + extended tests, all
green).

## Not in scope

See [../F000061_DESIGN.md](../F000061_DESIGN.md) `## Not in scope`: no
validate.sh delegation (Approach B — TODOS row), no registry schema or seed
change, no new `test-spec.sh` subcommands, no checkpoint-AUQ wiring changes
(pipelines print the block verbatim), no new test suites, no break of the
F000060 report contract (stage fields are pure additions).

## Pointers

- Parent feature design: [../F000061_DESIGN.md](../F000061_DESIGN.md)
- Parent tracker: [../F000061_TRACKER.md](../F000061_TRACKER.md)
- Roadmap: [../F000061_ROADMAP.md](../F000061_ROADMAP.md)
- Story tracker: [S000103_TRACKER.md](S000103_TRACKER.md)
- Spec: [S000103_SPEC.md](S000103_SPEC.md)
- Test spec: [S000103_TEST-SPEC.md](S000103_TEST-SPEC.md)
- Source design doc (the scaffold input; carries the check table, the verdict grammars, and the error-path grammar verbatim): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-unruffled-kalam-e25974-design-20260612-170600.md`
- Hardened machinery (landed dependency): `work-items/features/ops/F000060_two_tier_audit_contract/`
