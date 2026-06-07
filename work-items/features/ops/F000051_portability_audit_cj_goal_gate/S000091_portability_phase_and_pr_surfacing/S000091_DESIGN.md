---
type: design
parent: S000091
title: "Shared portability-audit phase + 3-orchestrator gate + PR surfacing — Design"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
reviewers: []
---

<!-- Atomic user-story design. Story-scope detail lives in SPEC.md + TEST-SPEC.md;
     this DESIGN is a brief stub linking to the parent feature for cross-story context. -->

## Problem

cj_goal runs already execute `/CJ_portability-audit` (via `validate.sh` Check 18 in
the pre-commit hook) on every commit, but a finding never blocks the run (advisory
exit 0) and the verdict is buried in `validate.sh` output. This story closes that
gap: it adds the gate + the PR-surfaced verdict. See parent
[F000051_DESIGN.md](../F000051_DESIGN.md) for the full problem framing and the
clean-baseline-as-free-ratchet rationale.

## Shape of the solution

One shared phase `cj-goal-common.sh --phase portability-audit` (shaped like
`pr-check`/`sync`): resolve engine → run under `PORTABILITY_STRICT=1` → parse
`FINDINGS=`/`SKILLS_AUDITED=` → emit `PHASE_RESULT=ok|findings|skipped` +
`VERDICT_LINE=`. All 3 orchestrators call it after Step 5.5 doc-sync, before
`/ship`: clean → verdict scratch + continue; absent → note + continue; findings →
HALT `[portability-red]`. The existing Step 4.6/9.5/5.6 surfacing seam is extended
to splice the verdict into the PR body. Detailed requirements + architecture are in
[S000091_SPEC.md](S000091_SPEC.md).

## Big decisions

<!-- Story-level choices. Feature-wide decisions live in the parent DESIGN. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Mirror `pr-check`/`sync` phase shape + the `sync` exit-capture idiom verbatim | Consistency with the host file; a bare `$(...)` would swallow the engine's non-zero exit or abort under the orchestrator shell. |
| 2 | Anchor the gate by CONTENT (after the doc-sync handler, before `/ship`), not a new step number | The orchestrators' step numbers are non-monotonic; a number would be jarring + cross-wire-prone. See parent DESIGN decision #5. |

## Risks & open questions

<!-- Story-level risks. See parent DESIGN for feature-wide risks. -->

| Risk / Question | Next check |
|-----------------|-----------|
| `scripts/test.sh` may enumerate cj-goal-common phases and need a parallel entry (implement-subagent blind spot). | Implement phase — grep test.sh and extend. |
| Check 15b (HARD gate) requires updating all 3 `docs/workflow.md` charts + Touches blocks. | Implement phase — `./scripts/validate.sh` must pass. |

## Definition of done

<!-- Story-level DoD. -->

- [ ] Phase emits the structured stdout block + the three exit/PHASE_RESULT outcomes (ok/findings/skipped); `--dry-run` runs nothing.
- [ ] All 3 orchestrators gate on red with `[portability-red]` + journal contract fields, and surface the green verdict in the PR.
- [ ] `tests/cj-goal-common-portability.test.sh` asserts all three outcomes; `./scripts/validate.sh` + `./scripts/test.sh` green (incl. Check 15b).

## Not in scope

<!-- Story-level non-goals. See parent DESIGN for the full list. -->

- Engine edits, flipping Check 18 to strict-by-default, modifying `drain-one-todo.sh`, refreshing `CJ_portability-audit/SKILL.md` prose — all deferred per parent F000051_DESIGN.md "Not in scope".

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent feature design: [../F000051_DESIGN.md](../F000051_DESIGN.md)
- Parent tracker: [../F000051_TRACKER.md](../F000051_TRACKER.md)
- This story's spec: [S000091_SPEC.md](S000091_SPEC.md)
- This story's test-spec: [S000091_TEST-SPEC.md](S000091_TEST-SPEC.md)
- Engine: `scripts/cj-portability-audit.sh`; host: `scripts/cj-goal-common.sh`
