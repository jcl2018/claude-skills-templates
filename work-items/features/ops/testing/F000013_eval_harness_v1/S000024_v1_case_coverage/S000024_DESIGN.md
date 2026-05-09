---
type: design
parent: S000024
title: "V1 eval case coverage — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Atomic-story DESIGN.md: keep all 7 sections, brief content per section is fine.
     For full feature-level context, see the parent F000013_DESIGN.md. -->

## Problem

S000023 ships the runner skeleton with one passing case. That proves the pipeline works but doesn't actually exercise the in-scope skills' behaviors. V1 success criteria require 6–10 cases across `personal-workflow` and `system-health` — including a regression case for S000022 (the Step 18 traceability parser bug) that the harness should catch when the parser fix is reverted.

## Shape of the solution

Author 4–5 `personal-workflow` cases covering the most-common-failure surfaces (S000022 regression, frontmatter drift, lifecycle drift, valid-case baseline, and one more) plus 2 `system-health` cases (healthy state baseline + degraded state). Each case is `tests/eval/<skill>/<case>/{prompt.md, fixture/, expected.schema.json}`. Schema assertions on shape only — no prose golden-diff. The S000022 case includes an in-prompt caveat documenting that it tests "Claude executes the spec faithfully" (not the parser logic in isolation).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | S000022 regression case is V1-mandatory despite being a "weaker signal" case | The original TODO that motivated the harness named S000022 as the canonical regression worth catching. Even with the caveat (testing spec execution, not parser logic), the case has clear test value: catches Claude misreading the spec, catches accidental SKILL.md prose corruption. |
| 2 | Per-case schemas hand-written; defer consolidation | V1 caps at 10 cases — even with overlap, hand-maintaining schemas is cheaper than designing a `$ref` system at this scale. If drift pressure surfaces during authoring (3+ cases share a fragment), lift to `tests/eval/schemas/common-frags.json`. |
| 3 | Mix of PASS-case and FAIL-case fixtures | The harness should validate both happy path (skill correctly reports PASS) and failure detection (skill correctly identifies a malformed input). Without FAIL-case fixtures, the eval just checks the skill doesn't crash. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| LLM variance may make some assertions flaky (e.g., model paraphrases an error message differently across runs) | Iterate prompt.md to mandate specific JSON keys; if irreducible, narrow the schema to only the most-stable keys |
| `--max-budget-usd 0.15` may be too tight for cases with large fixtures (multi-file work-item trees) | Observe per-case cost during authoring; raise per-case to 0.20 if needed (success criterion has slack: 10 × 0.20 = $2 still close to design's $1.50 budget) |
| S000022 regression-detection proof requires reverting the parser fix on a test branch — that's destructive on the workbench | Use a throwaway branch (`test/s000022-revert`) just for the verification; don't merge |

## Definition of done

- [ ] 6–10 cases across personal-workflow + system-health, all PASSING via `bash scripts/eval.sh`
- [ ] S000022 case verified to FAIL on a test branch with the parser fix reverted
- [ ] S000022 caveat note in-line in the case's prompt.md
- [ ] Schema reuse handled: either acceptable drift across cases OR shared frags lifted to `schemas/common-frags.json`

## Not in scope

- **Spike 0 + skeleton + first case** — S000023
- **Nightly CI workflow** — S000025
- **scaffold/implement/qa skill cases** — V2
- **company-workflow cases** — permanently excluded (deprecated)

## Pointers

- Parent feature: [../F000013_TRACKER.md](../F000013_TRACKER.md)
- Parent feature design: [../F000013_DESIGN.md](../F000013_DESIGN.md)
- Sibling story (skeleton): [../S000023_spike_and_skeleton/S000023_TRACKER.md](../S000023_spike_and_skeleton/S000023_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`
- Originating regression: S000022 (closed by F000012)
