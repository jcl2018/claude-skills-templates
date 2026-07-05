---
type: roadmap
parent: F000083
title: "Materialize + enforce the portability test contract — Roadmap"
date: 2026-07-05
author: Charlie Jiang
status: Approved
---

## Scope

Turn the `portability` topic's testing from "wired but undocumented" into
"legible and enforced." Deliver a hand-authored **dream doc** (the end goal +
the three properties), a **topic subdir** that presents the tests grouped by
layer and explains how each layer achieves the dream, **detailed per-test
assertion tables**, a **deterministic enforcement check** so the docs cannot
rot back to stubs, and a **fast CI-push parity gate** (completeness + fidelity)
that does not slow the per-PR build.

## Non-Goals

- Moving the slow `test-deploy.sh` onto CI-push — the fast `windows-smoke.sh`
  S5/S6 gate completeness + fidelity per-PR instead.
- Enrolling other topics into `topic_contracts:` — follow-up work, one dream
  doc + subdir per topic.
- Any change to a test's runtime behavior.

## Success Criteria

- [ ] A maintainer reading `docs/goals/portability.md` can state the end goal and the three properties without reading code.
- [ ] `docs/tests/topics/portability/` shows, per layer, which tests run and how they achieve the dream.
- [ ] Each per-test doc answers "what does this specific test assert?" with a table.
- [ ] `validate.sh` HARD-fails if an enrolled topic loses its dream doc or a per-layer page.
- [ ] The per-PR CI-push gate now proves completeness + fidelity, and stays fast (seconds).

## Decomposition

Single-deliverable feature — implementation folded into the feature tracker; no
child user-stories.

| User-Story | Title | Status |
|-----------|-------|--------|
| — | (folded into F000083) | Closed |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Docs restructure (dream doc + topic subdir + enriched per-test) | 2026-07-05 | In Progress | Charlie | WHAT/HOW split | — |
| 2 | Enforcement (`--check-topic-docs` + Check 31 + negative test) | 2026-07-05 | In Progress | Charlie | deterministic | 1 |
| 3 | CI-push parity gate (windows-smoke S5/S6) + Check 18 tidy | 2026-07-05 | In Progress | Charlie | fast per-PR | — |
| 4 | Declarations + registries + CLAUDE.md + `/ship` | 2026-07-05 | Not Started | Charlie | PR-stop | 1,2,3 |

### Delivery History

- 2026-07-05: F000083 created.

## Dependency Graph

```
#1 docs restructure --> #2 enforcement --> #4 declarations + ship
#3 CI-push parity gate + Check 18 tidy --> #4 declarations + ship
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Should the dream-doc home be `docs/goals/` or a different name? | Confirmed at the in-session design gate; `docs/goals/` chosen (docs/workflows/ is generated). |
