---
type: design
parent: F000068
title: "3-part land/PR recap (before + after) for every cj_goal — Feature Design"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
reviewers: []
---

<!-- Distilled from ~/.gstack/projects/jcl2018-claude-skills-templates/landing-recap-design-20260628-185347.md (APPROVED). -->

## Problem

When a cj_goal run lands (or stops at a PR), the operator can be left guessing
what just shipped, how to confirm it works, and what to do next. CLAUDE.md
already has a `## Post-land recap` convention, but it is (a) **after-land only**,
(b) **two parts** (What this merge did / How to verify it) — missing an explicit
"next step", (c) framed as "verify" rather than "E2E test", and (d) hand-authored
prose per orchestrator, so the shape drifts between runs and verbs.

The goal is a consistent, human-readable **3-part recap** — **Delivered / How to
E2E-test it / Next step** — emitted **before and after** the land/deploy moment
for every cj_goal orchestrator, produced by a shared formatting helper so the
shape is uniform, kept **advisory** (never blocks a land).

## Shape of the solution

Build a **formatting helper** — a new `recap` phase on the existing shared
dispatcher `scripts/cj-goal-common.sh` — that standardizes the 3-part block, and
wire it into all four cj_goal pipelines at their land/PR-stop steps, then update
the CLAUDE.md convention. **No validate.sh gate** (advisory posture). The helper
formats; the agent still authors the change-specific content (it alone knows what
was delivered and the E2E commands); nothing halts if a pipeline skips it.

The helper invocation:

```
cj-goal-common.sh --phase recap --mode {feature|defect|task|todo_fix} \
  --when {before|after} \
  --field delivered="<1-3 lines: what shipped + version + PR# + squash SHA>" \
  --field e2e="<concrete end-to-end commands/checks for THIS change>" \
  --field next="<the concrete next action>"
```

It prints a standardized, labelled 3-part human-readable block to **stdout**: a
header keyed off `--when` (BEFORE: "About to land …"; AFTER: "Landed …" / for
PR-stop verbs "PR opened …"), then the three labelled sections **Delivered**,
**How to E2E-test it**, **Next step**. It is a **pure formatter** (computes no
content — the agent passes it in via `--field`; mutates nothing; writes no
telemetry) and **fail-soft/advisory** (emits `PHASE=recap` + `PHASE_RESULT=ok`,
exits 0; unknown/missing fields render an empty section rather than erroring; if
the helper is absent/unreachable the orchestrator falls back to emitting the
3-part block as prose; it NEVER halts a run). `--mode` is for labelling/telemetry
parity only; the block shape is verb-neutral.

The two landing verbs (`defect`, `todo_fix`) get a true before+after pair around
the land; the two PR-stop verbs (`feature`, `task`) get one at-PR recap (the
orchestrator never lands; the human's later `/land-and-deploy` is the existing
"direct /land-and-deploy" recap path the convention already covers).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| The `--phase recap` formatter (helper + test + test-spec units row) | S000112 | [S000112_recap_helper/S000112_TRACKER.md](S000112_recap_helper/S000112_TRACKER.md) |
| Wire the 4 pipelines + reframe the CLAUDE.md convention + docs | S000113 | [S000113_wire_pipelines/S000113_TRACKER.md](S000113_wire_pipelines/S000113_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach C: a shared `cj-goal-common.sh --phase recap` formatter, not per-orchestrator prose | A shared helper keeps the *shape* uniform across all four verbs and both before/after points; per-orchestrator prose is exactly what drifts today. |
| 2 | Advisory posture — NO `validate.sh` presence-check that each pipeline references the recap | The recap is a courtesy, not a correctness gate; a missing recap should never fail a build. The wiring is convention, not gated. |
| 3 | Helper is a pure formatter; the agent authors `delivered`/`e2e`/`next` content | Only the agent knows what shipped + the change-specific E2E commands. The helper cannot guarantee content quality; the convention prose must make the authoring responsibility explicit. |
| 4 | Reuse the existing `telemetry` phase's repeatable `--field KEY=VALUE` parsing; do NOT edit upstream `/land-and-deploy` | The `--field` parser already exists and handles escaping (print verbatim, no eval) — reuse it. `/land-and-deploy` is an untouchable upstream gstack skill (same rule as `/CJ_document-release`). |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Advisory ⇒ a pipeline could silently drop the pointer | Accepted (the chosen posture). The shared helper keeps the shape uniform wherever it IS called. Confirmed at QA by grepping each of the 4 pipeline.md files for the recap call. |
| Helper is a formatter only — cannot guarantee content is good | The convention prose in CLAUDE.md must make the agent's authoring responsibility (delivered/e2e/next) explicit. Verified at doc-sync. |
| A NEW `tests/*.test.sh` needs a matching `spec/test-spec-custom.md` units row or Check 24 reverse-sweep fails | S000112 adds the units row alongside the test. Verified by `scripts/test-spec.sh --check-coverage` at QA. |
| `--field` value escaping (multi-line / special chars) must render verbatim (no eval) | Reuse the telemetry `--field` parsing as the reference; assert in the new test. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `cj-goal-common.sh --phase recap --when before|after --field …` renders the BEFORE/AFTER header + the three labelled sections (Delivered / How to E2E-test it / Next step), `PHASE_RESULT=ok`, exit 0.
- [ ] Missing `--field` ⇒ empty section, still exit 0 (fail-soft). Absent helper ⇒ orchestrator prose fallback (documented in the pipelines + CLAUDE.md).
- [ ] All four `cj_goal` pipeline.md files reference the recap at their terminal/land step (before+after for the two landing verbs; one at-PR recap for the two PR-stop verbs).
- [ ] `CLAUDE.md` `## Post-land recap` reframed to the 3-part before+after land/PR convention naming the helper, with the agent-authoring responsibility and the advisory framing explicit.
- [ ] `scripts/validate.sh`, `scripts/test.sh` (incl. the new `cj-goal-common-recap` test), and `scripts/test-spec.sh --validate` + `--check-coverage` all green.

## Not in scope

<!-- Explicit non-goals. -->

- A `validate.sh` presence-check that each pipeline references the recap — the advisory posture decision; the wiring is convention, not gated.
- Any edit to upstream `/land-and-deploy` — untouchable, same rule as `/CJ_document-release`.
- The helper computing content (delivered/e2e/next) on its own — it is a pure formatter; the agent passes content in via `--field`.
- State, telemetry writes, or mutation of any kind by the recap phase.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000068_TRACKER.md](F000068_TRACKER.md)
- Roadmap: [F000068_ROADMAP.md](F000068_ROADMAP.md)
- Design source: `~/.gstack/projects/jcl2018-claude-skills-templates/landing-recap-design-20260628-185347.md`
- Existing convention being reframed: `CLAUDE.md` `## Post-land recap`
- Shared dispatcher being extended: `scripts/cj-goal-common.sh`
