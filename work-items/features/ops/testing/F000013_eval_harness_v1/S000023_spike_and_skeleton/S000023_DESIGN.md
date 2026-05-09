---
type: design
parent: S000023
title: "Spike 0 + runner skeleton + first passing case — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Atomic-story DESIGN.md: keep all 7 sections, brief content per section is fine.
     For full feature-level context, see the parent F000013_DESIGN.md. -->

## Problem

Three CLI behaviors are unverified and load-bearing for the runner shape: `--plugin-dir` skill discovery in `--bare --print` mode (S0.1), `--json-schema` syntax (S0.2 — inline-only or `@file` shorthand?), `--json-schema` enforcement on mismatch (S0.3 — exit-fail or warn-only?). Until resolved, the runner sketch in `F000013_DESIGN.md` is fallback-shaped pessimistically. Resolving the spike picks the simpler runner shape if available.

## Shape of the solution

A 30–60 minute Spike 0 against a known-valid fixture, capturing findings in `tests/eval/README.md`. Then build the skeleton (`scripts/eval.sh` + `tests/eval/lib/{run-case,seed-fixture}.sh` + `README.md`) shaped per spike outcome. Finish by writing one passing case (`check-flags-missing-lifecycle` — chosen because it requires Claude reasoning about a malformed tracker, not just spec-execution) to prove the pipeline works end-to-end.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Spike 0 first, runner second | Runner shape depends on spike outcome; building backwards risks committing to fallback complexity unnecessarily. |
| 2 | `check-flags-missing-lifecycle` is the first case (not S000022 regression) | First case proves the pipeline; needs to genuinely require Claude reasoning so the eval signal is meaningful. S000022 lands in S000024 alongside other personal-workflow cases. |
| 3 | `seed-fixture.sh` separated from `run-case.sh` | Testable in isolation; reused by future case-authoring helpers. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `--plugin-dir` may need a plugin-manifest wrapper around skills (workbench `skills/` is flat skill dir, not a plugin dir) | Spike S0.1 — try direct first; on fail, try plugin-manifest wrapper; on fail, fall back to fake-`$HOME` + `--add-dir` |
| `xargs -P 4` concurrency may break if two cases share state (e.g., npm cache for `ajv-cli`) | Pre-warm `ajv-cli` once before xargs; fake-`$HOME` already isolates per-case skill state |
| First passing case may surface unexpected fidelity issues (Claude misreads SKILL.md prose, etc.) | Iterate on prompt.md until JSON output is reliable; if irreducible, document as a V2 concern |

## Definition of done

- [ ] Spike S0.1, S0.2, S0.3 findings recorded in `tests/eval/README.md`
- [ ] `scripts/eval.sh` + `tests/eval/lib/run-case.sh` + `tests/eval/lib/seed-fixture.sh` exist and pass shellcheck
- [ ] First case `check-flags-missing-lifecycle` returns PASS via `bash scripts/eval.sh personal-workflow check-flags-missing-lifecycle`
- [ ] `xargs -P 4` concurrency verified (two-case parallel run produces stable PASS)

## Not in scope

- **S000022 regression case** — lands in S000024
- **Other personal-workflow cases** — S000024
- **system-health cases** — S000024
- **Nightly CI workflow** — S000025

## Pointers

- Parent feature: [../F000013_TRACKER.md](../F000013_TRACKER.md)
- Parent feature design: [../F000013_DESIGN.md](../F000013_DESIGN.md)
- Source design doc (`/office-hours`): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`
