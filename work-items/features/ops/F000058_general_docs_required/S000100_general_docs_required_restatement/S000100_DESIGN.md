---
type: design
parent: S000100
title: "General docs required — complete contract restatement — Story Design"
version: 1
status: Draft
date: 2026-06-09
author: chjiang
reviewers: []
---

<!-- Atomic story: derives directly from the parent feature's /office-hours session.
     See parent F000058_DESIGN.md for full context. Sections are brief but complete. -->

## Problem

The general tier of the doc-spec contract is dishonestly small: 6 docs every
adopting repo needs (`spec/doc-spec.md`, `CLAUDE.md`, `CHANGELOG.md`,
`TODOS.md`, `docs/doc-general.md`, `docs/doc-custom.md`) are labeled
`section: custom`, the seed still says "four human docs," and nothing states
"general docs are required." See parent [F000058_DESIGN.md](../F000058_DESIGN.md).

## Shape of the solution

Seven ordered steps from the approved plan: (1) workbench registry flip (6
entries) + Common-prose restatement (10-doc table + required rule) + Custom
prose shrink; (2) seed pair growth to 10 portable entries, byte-identical
prose across all three copies (fixing the diagram-line drift); (3) regenerate
the two views; (4) `/CJ_document-release` tier-logic statement + Step 6.7
advisory missing-general-doc rule + USAGE.md refresh; (5) philosophy
"Two tiers, one portable pass" amendment; (5.5) secondary-reference sweep;
(6) growth-safe seed assertions in `tests/cj-document-release-config.test.sh`
+ full verification.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Required rule lands in the portable Common seed, not just the workbench registry | Registry-only flip would be a workbench-only claim (Premise 1) |
| 2 | "Required" = must exist via existing machinery + an advisory audit line; no new hard gate | Premise 3; Approach C's hard check rejected (fixture churn + posture) |
| 3 | Enumerate the general set via `--seed` → temp file → `DOC_SPEC_PATH` → `--render general` | Reuses the parser; filters by `section: common` (`--list-declared` would over-enumerate) |
| 4 | Basename path-equivalence for the contract file (`spec/doc-spec.md` satisfies seed's `doc-spec.md`) | Mirrors spec/-then-root resolution; prevents workbench false-positives |
| 5 | Render-first stubs for the two views with a PORTABLE header | Born satisfying "kept matching the registry"; workbench-path headers don't exist in consumer repos |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| 3-way byte-identical coupling drifts one copy | Drift test 13 + E2E byte-compare (TEST-SPEC E2) before /ship |
| Common-prose rewrite adds a second ```` ```yaml ```` fence or drops the H1 phrase "what docs this repo carries" | Existing single-fence + test-8 assertions in test.sh |
| Check 14 USAGE.md drift on the SKILL.md edit | USAGE.md refresh in the same commit (TEST-SPEC S4 path) |

## Definition of done

- [ ] All 7 acceptance criteria in [S000100_TRACKER.md](S000100_TRACKER.md) check off — registry flip, seed growth + byte-identity, views regen, skill statement + advisory rule, philosophy amendment, sweep, growth-safe tests — with `validate.sh` + `test.sh` fully green and no new checks or fixture edits.

## Not in scope

- Approach C machine enforcement (`--list-general-docs` + hard check) — deferred; see parent Not-in-scope.
- Reclassifying `CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md`; `audit_class` changes; history edits in the sweep.

## Pointers

- Parent tracker: [S000100_TRACKER.md](S000100_TRACKER.md)
- Spec: [S000100_SPEC.md](S000100_SPEC.md)
- Test spec: [S000100_TEST-SPEC.md](S000100_TEST-SPEC.md)
- Feature design: [../F000058_DESIGN.md](../F000058_DESIGN.md)
- Feature roadmap: [../F000058_ROADMAP.md](../F000058_ROADMAP.md)
- Source design doc (APPROVED): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-pensive-robinson-08ad9c-design-20260609-191404.md`
