---
type: roadmap
parent: F000068
title: "3-part land/PR recap (before + after) for every cj_goal — Roadmap"
date: 2026-06-28
author: chjiang
status: Draft
---

## Scope

Deliver a consistent, human-readable **3-part land/PR recap** — **Delivered /
How to E2E-test it / Next step** — emitted **before and after** the land/deploy
moment for every cj_goal orchestrator. It is produced by a new shared formatting
helper (`scripts/cj-goal-common.sh --phase recap`) so the shape is uniform across
all four verbs, and it is wired into each pipeline's land/PR-stop step. The
posture is **advisory**: the recap never blocks a land and no `validate.sh` check
asserts it fired. The `CLAUDE.md` `## Post-land recap` convention is reframed to
describe the new before+after 3-part shape and name the helper as producer.

## Non-Goals

- A `validate.sh` presence-check that each pipeline references the recap — the advisory posture decision; the wiring is convention, not gated.
- Any edit to upstream `/land-and-deploy` — untouchable (same rule as `/CJ_document-release`).
- The helper computing the recap content itself — it is a pure formatter; the agent authors `delivered`/`e2e`/`next` and passes them in via `--field`.
- State persistence, telemetry writes, or any mutation by the recap phase.

## Success Criteria

- [ ] `cj-goal-common.sh --phase recap --when before|after --field …` renders the BEFORE/AFTER header + the three labelled sections, `PHASE_RESULT=ok`, exit 0 — observable by running the helper.
- [ ] Missing `--field` ⇒ empty section, still exit 0 (fail-soft) — observable by running the helper with fields omitted.
- [ ] All four `cj_goal` pipeline.md files reference the recap at their terminal/land step — observable by grep.
- [ ] `CLAUDE.md` `## Post-land recap` describes the 3-part before+after convention and names the helper — observable by reading the section.
- [ ] `scripts/validate.sh`, `scripts/test.sh`, and `scripts/test-spec.sh --validate`/`--check-coverage` all green — observable from CI / a local run.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000112](S000112_recap_helper/S000112_TRACKER.md) | The `--phase recap` formatter (helper + test + test-spec units row) | Open |
| [S000113](S000113_wire_pipelines/S000113_TRACKER.md) | Wire the recap into the 4 pipelines + reframe the CLAUDE.md convention + docs | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000112 — `--phase recap` formatter + test + test-spec units row | — | Not Started | chjiang | The pure formatter on `cj-goal-common.sh`; reuses the telemetry `--field` parser | — |
| 2 | Ship S000113 — wire 4 pipelines + reframe CLAUDE.md convention + docs | — | Not Started | chjiang | Consumes the helper from #1; prose fallback when absent | #1 |
| 3 | End-to-end pipeline run (scaffold → implement → qa → doc-sync → audit → ship), stop at PR | — | Not Started | chjiang | The whole feature ships in one PR | #1, #2 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-28: F000068 scaffolded from the APPROVED /office-hours design doc.

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 recap formatter (S000112) --> #2 wire pipelines + CLAUDE.md (S000113) --> #3 E2E pipeline run / ship
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Does the `todo_fix` verb wire the recap in `pipeline.md` or `SKILL.md`? | Resolve during S000113 implement — inspect the todo verb's file structure and place the before+after recap around its `/ship → /land-and-deploy` tail. |
| Do any `docs/workflows/*.md` Touches blocks enumerate the cj-goal-common phases (and thus need a `recap` entry)? | Resolve during S000113 implement / doc-sync — grep the Touches blocks; doc-sync surfaces the drift. |
