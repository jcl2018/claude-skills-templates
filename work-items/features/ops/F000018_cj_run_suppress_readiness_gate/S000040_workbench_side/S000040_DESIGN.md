---
type: design
parent: S000040
title: "Workbench-side change: pass --suppress-readiness-gate, fix Branch(f) open_pr — Story Design"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
reviewers: []
---

<!-- A user-story's design doc. Atomic stories may use a brief stub. -->

## Problem

`/CJ_run` Phase 4 (Step 5 of `skills/CJ_run/run.md`) invokes
`/land-and-deploy` via the Skill tool, but does not pass any flag to suppress
the readiness-gate AUQ. As a result, end-to-end pipeline runs surface an extra
"Ready to merge PR #N?" question that is pure ceremony — `/autoplan` and
`/ship` already gated the same things.

Branch(f) `open_pr` mode (run.md ~line 267) is a dead-end: it prints "PR
already open. Run /land-and-deploy to merge." and exits 0. That breaks the
"let it run to the end" promise for the resume-from-PR-open path.

## Shape of the solution

Three workbench-side edits:

1. **Step 5 invocation** — change the Skill-tool invocation prose to pass
   `--suppress-readiness-gate` literally.
2. **Branch(f) open_pr handler** — change the table row from print+exit-0 to
   auto-dispatch `/land-and-deploy --suppress-readiness-gate #<PR_NUM>` with
   an inline-duplicated PR_NUM parsing block (copied from Step 5).
3. **SKILL.md polish** — update the frontmatter description and the Phase 4
   entry to mention the suppression behavior; bump version 0.4.0 → 0.5.0;
   add CHANGELOG entry.

See parent F000018_DESIGN.md for context on the proven `--suppress-final-gate`
pattern this mirrors.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Inline-duplicate PR_NUM parsing block in Branch(f) (vs extracting a /CJ_run helper) | ~15 lines duplicated is cheaper than introducing the abstraction. (User taste decision in /autoplan.) |
| 2 | Pass the flag unconditionally under /CJ_run (no env var, no conditional) | /CJ_run is the only caller; opt-in semantics are owned at the wrapper level. |
| 3 | Reuse current branch (claude/modest-meitner-0c7600) | v3.3.2 was just merged here; branch is clean; user explicitly requested. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Workbench PR lands before gstack PR — flag is silently ignored | Acceptable. gstack's loose arg parsing makes this a safe no-op. Verified at gstack PR review. |
| Branch(f) auto-dispatch changes user expectations (was print-and-exit) | Document in CHANGELOG. The behavior change is small and consistent with the "let it run to the end" intent. |

## Definition of done

See parent F000018_DESIGN.md `## Definition of done`. All six criteria translate directly to this story (it owns the entire workbench-side change).

## Not in scope

- gstack `/land-and-deploy` flag itself.
- Suppression of Step 5 deploy-strategy AUQ or Step 1.5 first-run dry-run AUQ.

## Pointers

- Parent tracker: [../F000018_TRACKER.md](../F000018_TRACKER.md)
- Parent design: [../F000018_DESIGN.md](../F000018_DESIGN.md)
- SPEC: [S000040_SPEC.md](S000040_SPEC.md)
- TEST-SPEC: [S000040_TEST-SPEC.md](S000040_TEST-SPEC.md)
- Pattern reference: `skills/CJ_personal-pipeline/pipeline.md` (`--suppress-final-gate` contract)
