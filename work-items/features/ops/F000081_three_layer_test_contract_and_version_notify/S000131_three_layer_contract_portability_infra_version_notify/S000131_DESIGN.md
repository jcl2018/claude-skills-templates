---
type: design
parent: S000131
title: "Three-layer contract + portability→infra + git ls-remote version-notification + retire /CJ_portability-audit — Story Design"
version: 1
status: Draft
date: 2026-07-04
author: Charlie Jiang
reviewers: []
---

<!-- A story-scoped design stub. This user-story carries the WHOLE F000081 scope,
     so the SHAPE and BIG DECISIONS mirror the parent feature DESIGN; the
     story-scope detail (requirements, architecture, tradeoffs) lives in SPEC.md
     and TEST-SPEC.md. See the parent F000081_DESIGN.md for the full cross-story
     framing. -->

## Problem

This story implements the whole F000081 change (see the parent feature DESIGN for the
full four-gap framing). In short: the two-axis test contract (category × layer) is
half-populated and nothing reports the gap; the two portability harness tests are
miscategorized as `workflow` when they are standing verification `infra`, with no
local-hook third layer; the version-notification (`scripts/skills-update-check`) gates on
a live workbench `.git` checkout so remote/foreign-repo installs get NO staleness nudge;
and the standalone `/CJ_portability-audit` verb is redundant once the contract proves
portability automatically.

## Shape of the solution

Five sequentially-built workstreams shipped as one PR: **WS1** — the three-levels-per-category
contract prose (general `spec/test-spec.md` + byte-identical seed) + an advisory
per-category × {CI-push, CI-nightly, local-hook} matrix in `--check-structure`; **WS3** —
a checkout-independent `skills-update-check` via `git ls-remote --tags` + a new root unit
test; **WS2** — flip the two portability rows to `infra`, hand-move their front-door docs
under `docs/tests/infra/…` (+ the four `spec/doc-spec.md` rows), and backfill the local-hook
cell with a command-only `portability-version-check` row; **WS5** — retire the
`/CJ_portability-audit` verb across all consistency touchpoints, keeping the engine +
Check 18; **WS4** — add a nightly full-suite CI workflow (+ its `ci` unit) and a
targeted-negative-test refactor (defer the `validate.yml` trim). The full requirement
list + architecture + component map is in SPEC.md; the smoke/E2E coverage is in TEST-SPEC.md.

## Big decisions

<!-- Mirrors the parent feature's Big decisions; see F000081_DESIGN.md for full rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | `git ls-remote` (not curl) for the remote read. | git is the repo's vetted hard dependency; ssh + non-GitHub URLs; zero curl precedent. |
| 2 | Safe-additive CI now, defer the `validate.yml` trim. | The nightly workflow + negative-test refactor are in-PR-verifiable; the trim + layer-reclass is an attended follow-up. |
| 3 | Coverage matrix is ADVISORY (`NOTE:`s, exit 0). | `--check-structure` keeps its "findings are the product" posture; empty cells never hard-fail. |
| 4 | One atomic user-story, no task children. | WS1–WS5 are one cohesive sequential change in one PR; splitting fragments a coherent diff. |
| 5 | Retire the verb, keep the engine + Check 18. | The automatic per-PR lint + reclassified infra tests make the manual verb redundant. |

## Risks & open questions

<!-- Mirrors the parent feature's Risks; see F000081_DESIGN.md for the full table. -->

| Risk / Question | Next check |
|-----------------|-----------|
| The `spec/test-spec.md` ↔ `test-spec.sh --seed` byte-identity is the most fragile edit. | Green the `seed-byte-identical` contract test FIRST (WS1), before any other WS. |
| A doc move under `docs/` is a doc-spec + generated-catalog edit; `--seed-docs` never moves authored content. | WS2 hand-moves the docs, edits the four `spec/doc-spec.md` rows, regenerates, and re-runs `--check-on-disk` before greening. |
| Retiring a routable skill is consistency-heavy (many checks). | Mirror the /CJ_repo-init retirement; run whole `validate.sh` green before ship. |
| Portability local-hook filled deterministically vs the canonical "quick agentic". | Advisory matrix (Q1) permits it; the agentic variant is a deferred follow-up. |

## Definition of done

- [ ] All six S000131 Acceptance Criteria (WS1–WS5 + the full-green/regeneration gate) are met — see S000131_TRACKER.md.
- [ ] `test-spec.sh --seed` byte-identical; `--check-structure` prints the matrix + `NOTE:`s, exit 0.
- [ ] Portability rows read `infra`; front-door docs under `docs/tests/infra/…`; `spec/doc-spec.md` + catalog updated; the local-hook command-row exists.
- [ ] `skills-update-check` git-ls-remote rework proven by `tests/skills-update-check.test.sh` (Check 24 green).
- [ ] `nightly.yml` registered as a `ci` unit; negative tests targeted; `/CJ_portability-audit` retired with engine + Check 18 intact.
- [ ] Whole `validate.sh` + full `test.sh` + shellcheck green; VERSION bumped; README + catalogs regenerated; deferred follow-up filed.

## Not in scope

- The `validate.yml` per-PR trim + the matching `layer` reclass — deferred attended follow-up.
- A truly agentic portability local-hook variant — deferred; the cell is backfilled deterministically.
- Any change to the `CJ_portability-audit` catalog `portability` tier or Check 18.
- A version-check cache TTL change or any per-skill preamble edit.

## Pointers

- Parent feature design: [../F000081_DESIGN.md](../F000081_DESIGN.md)
- Parent feature tracker: [../F000081_TRACKER.md](../F000081_TRACKER.md)
- Parent feature roadmap: [../F000081_ROADMAP.md](../F000081_ROADMAP.md)
- This story's spec: [S000131_SPEC.md](S000131_SPEC.md)
- This story's test-spec: [S000131_TEST-SPEC.md](S000131_TEST-SPEC.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-ecstatic-greider-fb1178-design-20260704-003931.md`
