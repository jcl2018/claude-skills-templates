---
type: design
parent: S000125
title: "CI cadence taxonomy split (V2) + Windows nightly move — Story Design"
version: 1
status: Draft
date: 2026-07-03
author: chang
reviewers: []
---

<!-- Atomic story: derives directly from the parent feature's /office-hours
     session. Sections are intentionally brief and defer cross-story context to
     the parent F000075_DESIGN.md; none are omitted (section completeness is
     enforced by /CJ_personal-workflow check). -->

## Problem

The workbench `windows-latest` job runs the slow `test-deploy.sh` suite on every
PR, making merges too slow, and the category test contract has no way to express
"runs on every push" vs "runs nightly." This story carries the single coherent
change that fixes both: bump the portable category taxonomy to V2
`{workflow, CI-push, CI-nightly}` and move the slow Windows deploy suite to a
nightly workflow. See parent [F000075_DESIGN.md](../F000075_DESIGN.md) for the
full problem framing.

## Shape of the solution

One story, eight deliverables (see parent ROADMAP + this story's SPEC
`## Architecture`): (1) portable seed + parser taxonomy V2 bump in both
byte-identical copies; (2) `spec/test-spec-custom.md` `categories:` re-key +
`windows-deploy` `CI-nightly` row; (3) folder/doc renames + the
`spec/doc-spec-custom.md` registry rewrite; (4) `scripts/test-run.sh` enum +
error-string V2; (5) the two real CI workflows (`windows.yml` fast smoke, new
`windows-nightly.yml`); (6) both cj_test skills' SKILL.md + USAGE.md; (7) the two
test files; (8) `CLAUDE.md` via doc-sync. The category name carries the cadence,
so selection is `--category CI-push|CI-nightly` with no new flag.

## Big decisions

<!-- Story-scope decisions; cross-story rationale lives in the parent design. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | `--check-structure` folder checks derive from the distinct declared categories | Avoid forcing an empty `tests/CI-nightly/` on THIS repo + every consumer that upgrades the seed. |
| 2 | The `spec/doc-spec-custom.md` registry rewrite lands in the implementation commit | The `docs/tests/` rows are contract entries; deferring to doc-sync hard-fails Check 15/15a. |
| 3 | Keep `test-deploy` (push) AND `windows-deploy` (nightly) as two rows | Same script, two CI contexts (platform + cadence); the two per-test docs explain the redundant local command. |

See parent [F000075_DESIGN.md](../F000075_DESIGN.md) `## Big decisions` for the
feature-level decisions (change the real workflow, keep a fast PR Windows check,
expand the taxonomy vs a `cadence:` field).

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Editing only one of the two byte-identical taxonomy copies breaks `cmp -s` | Implement — edit `spec/test-spec.md` + the seed heredoc in lockstep. |
| Missing a category-enum site in `scripts/test-spec.sh` leaves stale V1 behavior | Implement — update every enum site (parser + three `--check-structure` loops). |
| Renaming the lowercase `docs/tests/ci.md` (units-axis family render) by mistake | Implement — rename only the `docs/tests/CI/` category dir; leave `ci.md` untouched. |
| `--category CI-nightly` runs `test-deploy.sh` locally, not on real Windows | Accepted — intent-declaration + audit cross-check; `platform:` field deferred. |

## Definition of done

- [ ] `test-spec.sh --validate` / `--list-categories` / `--check-structure` reflect V2; `--seed` byte-identical to `spec/test-spec.md`.
- [ ] `test-run.sh --category CI-push`/`CI-nightly` select correctly via `--dry-run`.
- [ ] `windows.yml` PR-runs only `windows-smoke.sh`; `windows-nightly.yml` runs `test-deploy.sh` on `windows-latest` on schedule + dispatch.
- [ ] Both cj_test skills + `CLAUDE.md` document V2; both test files updated.
- [ ] `validate.sh` green (Checks 15/15a, 24, 26, 28); full `test.sh` green; shellcheck clean.

## Not in scope

- Physical relocation of test scripts into `tests/<category>/` — deferred.
- A `platform:` field on the `categories:` axis — deferred refinement.
- Moving `goal-task-eval` into `CI-nightly` — cadence does not subsume kind.
- A backward-compat `CI` alias; any upstream gstack edits.

## Pointers

- Parent tracker: [../F000075_TRACKER.md](../F000075_TRACKER.md)
- Parent design: [../F000075_DESIGN.md](../F000075_DESIGN.md)
- Parent roadmap: [../F000075_ROADMAP.md](../F000075_ROADMAP.md)
- This story: [S000125_TRACKER.md](S000125_TRACKER.md) · [S000125_SPEC.md](S000125_SPEC.md) · [S000125_TEST-SPEC.md](S000125_TEST-SPEC.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-eloquent-cohen-54b476-design-20260702-235650.md`
