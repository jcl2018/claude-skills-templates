---
type: design
parent: S000083
title: "Layer 1 static dependency lint — Story Design"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
reviewers: []
---

<!-- Atomic story: this DESIGN.md is a brief stub. The full cross-story design
     context lives in the parent feature's design — see
     ../F000047_DESIGN.md and the source /office-hours doc. Story-scope detail
     (requirements, architecture, tests) lives in SPEC.md + TEST-SPEC.md. -->

## Problem

Some workbench skills declare `portability: standalone` in `skills-catalog.json`
yet reach for repo-local artifacts a target repo will not have (`scripts/test.sh`,
`scripts/cj-goal-common.sh`, root config, `CLAUDE.md` conventions, the manifest
`.source` reach-back). Nothing verifies the declared field against actual
dependencies. This story builds Layer 1: a static dependency-lint engine that
catches the mismatch, advisory-first. See `../F000047_DESIGN.md` for the full
problem framing and the producer-vs-consumer distinction from `/CJ_repo-init`.

## Shape of the solution

A root engine `scripts/cj-portability-audit.sh` collects each catalog skill's
files, classifies each EXECUTED repo-local dependency against the skill's declared
`portability` tier (strict ladder: `standalone` ⊂ `local-only` ⊂ `workbench`),
honors the new optional `portability_requires` accepted-deps catalog field, and
emits a three-value per-skill verdict. The same engine is the body of the
`/CJ_portability-audit` skill (rich report) AND a new `validate.sh` advisory check
(exit 0 in v1). A single Layer-2 case (`scripts/eval.sh --portability` running
`CJ_suggest` against a stripped scratch repo) proves the dynamic harness exists.
See SPEC.md for the architecture diagram, components affected, and the
classification contract.

## Big decisions

Inherited from the parent feature design (`../F000047_DESIGN.md` "Big decisions"):
Approach B (new skill, engine-in-script); advisory-first (exit 0 in v1);
`portability_requires` ships in v1 (correctness prerequisite, not polish); the
strict tier ladder where the self-resolution preamble is a FINDING for
`standalone` but OK-with-note for `workbench`/`local-only` (D4); correct-behavior
spec written to `doc/WORKFLOWS.md` (D4); engine is a ROOT script resolved via
`.source`. Story-local decision: this is an ATOMIC story (no task children) — one
cohesive change across engine + skill + validate.sh + test.sh + catalog + eval.sh
+ docs.

## Risks & open questions

- The `zzz-test-scaffold` integration edit to `scripts/test.sh` is the step the implement-subagent systematically forgets (F000032/F000034/F000035) — pre-flighted in SPEC + TRACKER. Next check: implement step.
- Layer-2 `.source` fall-through: a `git init`'d scratch tmpdir falls through to the real workbench `.source`, proving nothing unless resolution is redirected at a scratch `~/.claude`. Next check: the one `CJ_suggest` Layer-2 case must demonstrate the redirect. See parent DESIGN "Risks" for the full list.

## Definition of done

See this story's TRACKER `## Acceptance Criteria` and SPEC `## Acceptance Criteria`
(authoritative). In brief: engine + validate.sh advisory check + test.sh fixture +
catalog entry & `portability_requires` pre-seed + SKILL.md/USAGE.md + docs
(WORKFLOWS/ARCHITECTURE/PHILOSOPHY) + one green `CJ_suggest` Layer-2 case; `≥1` real
finding surfaces before adjudication; `validate.sh` + `test.sh` green after pre-seed.

## Not in scope

- Layer 2 broad coverage across all runnable leaf skills + orchestrator partial runs (parent feature's Story 2).
- Nightly-CI wiring of the portability eval (Story 2).
- Advisory→hard-gate hardening / `PORTABILITY_STRICT=1` default flip (Story 2).
- Auto-fixing mismatches; parsing the `.source`-fallback guard (conservative flag-and-adjudicate in v1).

## Pointers

- Parent feature design: [../F000047_DESIGN.md](../F000047_DESIGN.md)
- Parent tracker: [../F000047_TRACKER.md](../F000047_TRACKER.md)
- This story's spec: [S000083_SPEC.md](S000083_SPEC.md)
- This story's test spec: [S000083_TEST-SPEC.md](S000083_TEST-SPEC.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-140945-869-design-20260604-142240.md`
