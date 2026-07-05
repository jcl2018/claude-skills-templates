---
type: design
parent: S000132
title: "Topic contract + portability agentic proof — Design"
version: 1
status: Draft
date: 2026-07-04
author: chang
reviewers: []
---

<!-- Atomic user-story design. Derives from the parent feature's /office-hours
     session; the parent F000082_DESIGN.md carries the full cross-story context.
     This doc gives just enough story-scope shape to implement. -->

## Problem

The parent feature (F000082) needs ONE cohesive implementation that adds a
first-class `topic:` axis, per-topic enrollment, a hard declaration-only Check, a
reusable repo-neutral agentic-sandbox lib, and portability's agentic proof — all
landing atomically so `validate.sh` never reds its own commit. This story is that
implementation. See parent `F000082_DESIGN.md` for the full problem context (the
green-but-inert blind spot the agentic layer closes).

## Shape of the solution

Build in dependency order, enroll LAST (§8 of the parent design):

1. **Schema** — `topic:` as the 9th `categories:` column + `topic_contracts:` overlay list,
   widened across the six consumer sites in `test-spec.sh` + `test-run.sh`; 12 rows backfilled.
2. **Lib** — `scripts/lib/agentic-sandbox.sh` (3 POSIX+LF helpers) reusing `SKILLS_UPDATE_REMOTE_URL`.
3. **Proof** — `tests/portability-version-agentic.test.sh` + its `categories:` row + front-door doc + index + doc-spec declaration.
4. **Enroll + Check (LAST)** — `topic_contracts: [portability]` + `test-spec.sh --check-topic-contract`
   + the `validate.sh` hard Check + the targeted `scripts/test.sh` negative test.
5. **Wiring** — `/CJ_test_run --topic` selector; confirm `/CJ_test_audit` surfaces the check.
6. **Docs** — general-seed prose (+ byte-identical `_emit_seed`) + overlay + CLAUDE.md; grandfather TODOs.

## Big decisions

<!-- Story-scope choices. The feature-level decisions live in the parent
     F000082_DESIGN.md "Big decisions" table; these are the ones this story owns. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | One atomic story, not parallel sub-stories | The parts must land together; enrolling before the agentic row exists reds `validate.sh` — parallel stories would be false decomposition. |
| 2 | `--check-topic-contract` mirrors `--check-workflow-coverage`'s shape | Reuse a proven forward+reverse, registry-gated, findings-verbatim Check pattern rather than inventing a new one. |
| 3 | Ship only the 3 lib helpers the first consumer uses (YAGNI) | `mk_neutral_sandbox` / `mk_tagged_bare_upstream` / `run_preamble_via_claude` are all portability calls; no speculative 4th helper. |

## Risks & open questions

<!-- Story-scope risks. Broader feature risks live in the parent. -->

| Risk / Question | Next check |
|-----------------|-----------|
| The six `categories:` consumer sites drift out of lockstep (TSV field-count mismatch) | AC1: `--validate` + `--list-categories` + `--check-structure` all green after the 8→9 widening. |
| Dual-write: `spec/test-spec.md` prose edit vs the `_emit_seed` heredoc | Guarded by the seed-identity test; only prose changes (machine `yaml` block untouched — topic/categories are overlay-only). |
| Windows Git Bash portability of the new lib + test (no `git` shim, POSIX+LF, jq CR-strip) | `windows-smoke` job; decision #4 in parent (no `git` shim) is the guard. |

## Definition of done

<!-- Objective, measurable. Same AC set as the parent, verified at story level. -->

- [ ] AC1–AC9 (see `## Acceptance Criteria` in `S000132_TRACKER.md`) all met and `/CJ_personal-workflow check` passes on this dir.
- [ ] `validate.sh` + `scripts/test.sh` green on this repo with the new hard Check and negative test.
- [ ] Portability agentic test SKIPs clean in CI and PASSES locally with a login.

## Not in scope

<!-- Story-scope non-goals. Feature-level non-goals live in the parent ROADMAP/DESIGN. -->

- Fixing the real release-tag inertness — separate defect (see parent Not-in-scope).
- Migrating the 11 grandfathered topics or refactoring `e2e-local`/`eval.sh` onto the new lib — fast-follows.
- A live/networked `git ls-remote` smoke — deferred.

## Pointers

<!-- Cross-links. Relative paths from this story directory. -->

- Parent feature tracker: [../F000082_TRACKER.md](../F000082_TRACKER.md)
- Parent feature design: [../F000082_DESIGN.md](../F000082_DESIGN.md)
- Story spec: [S000132_SPEC.md](S000132_SPEC.md)
- Story test-spec: [S000132_TEST-SPEC.md](S000132_TEST-SPEC.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-inspiring-keller-69636a-design-20260704-132238.md`
