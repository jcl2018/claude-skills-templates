---
type: design
parent: S000064
title: "Casing rename + shim creation + catalog + cross-reference flips — Story Design"
version: 1
status: Draft
date: 2026-05-31
author: chjiang
reviewers: []
---

<!-- A user-story design doc. Atomic story whose design lives mostly in the
     parent feature's DESIGN.md. This stub captures story-specific shape +
     decisions and points readers up to the parent for full context. -->

## Problem

This story is the single atomic implementation unit for F000031's casing-only rename. All 10 steps from the parent design's "Recommended Approach" section land in one PR because they're tightly coupled — the F000027 S000060 regression test in `scripts/test.sh` lines 1044-1049 asserts the F000027 shim references the lowercase canonical, so renaming the dir without updating the regex (or vice versa) leaves the pre-commit hook red. Atomic ship is the only shape that keeps validate.sh + test.sh green throughout.

See parent [F000031_DESIGN.md](../F000031_DESIGN.md) for the full problem framing, premises, approaches considered, and the rationale behind picking Approach A over B/C.

## Shape of the solution

Single PR; 10 sequential implementation steps; one set of git changes. The steps cluster into 5 logical groups:

| Concern | Steps | Surface |
|---------|-------|---------|
| Two-step git mv (case-insensitive APFS workaround) | Step 1 | `skills/cj_goal_feature/` + `skills/cj_goal_defect/` dirs |
| Self-reference flips in renamed skills | Steps 2, 3 | `skills/CJ_goal_feature/SKILL.md` + pipeline.md; same for defect |
| Lowercase deprecation shim creation | Step 4 | `deprecated/cj_goal_feature/SKILL.md` + `deprecated/cj_goal_defect/SKILL.md` (NEW) |
| Catalog + F000027 dep-chain fix | Step 5 | `skills-catalog.json` (6 edits) |
| Cross-reference flip + version preflight + validation | Steps 6, 6.5, 8, 9 | rules/skill-routing.md, CLAUDE.md, doc/, scripts/, tests/, README.md (auto-gen) |
| Out of scope / N/A | Step 7 (memory files = operator-local), Step 10 (telemetry already uppercase) | — |

## Big decisions

<!-- Story-specific decisions (parent feature DESIGN.md covers feature-level decisions). -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Single atomic story (no further task decomposition) | The S000060 regression test couples the F000027 shim flip + the catalog rename + the test-regex update. Any decomposition leaves intermediate state red. |
| 2 | Two-step `git mv` via `_TMP` intermediate (not a single `git mv lower UPPER`) | macOS APFS is case-insensitive: `git mv lower UPPER` is a no-op (git sees both as the same path). The temp-name intermediate forces git to record an R-rename. |
| 3 | Auto-regenerate README.md via `scripts/generate-readme.sh` (don't hand-edit) | README.md is generated from skills-catalog.json. After the 6 catalog edits, the only correct README state is what the generator produces — hand-editing risks drift on the next regen. |
| 4 | Memory files at `~/.claude/projects/.../memory/` excluded from this PR's diff | Operator-local state per `feedback_workbench_scope` memory rule. Including in PR diff would leak personal state + not apply on other operators' machines. Operator-local follow-up after merge. |
| 5 | Version literal `5.0.12` baked into shim frontmatter + 2 new catalog entries (with check-version-queue.sh preflight escape hatch) | The shim frontmatter `version` field is part of the file's content, not a runtime substitution. Baking the literal is the only way to ship a complete file; the preflight hand-edit (~5 sec) handles the rare parallel-worktree race. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `git mv lower TMP && git mv TMP UPPER` may exhibit stale-index edge case on APFS | Verify each step's exit code; run `git update-index --refresh` between steps only if stale-index error surfaces. |
| Version-slot collision (parallel worktree lands at 5.0.12 first) | Implementer runs `./scripts/check-version-queue.sh` immediately before `/ship`; if slot != 5.0.12, hand-edit 3 baked-in literals before commit. |
| Grep anchor `grep -rn 'cj_goal_feature\|cj_goal_defect' ...` may produce false positives (historical references that should stay lowercase) | Per-row decision rule (active-routing → uppercase; runtime-artifact names → lowercase) handled by implementer at Step 6. |
| `tests/cj-goal-feature-smoke.test.sh` filename itself contains lowercase — should it rename? | KEEP lowercase (runtime artifact name, not skill identity). Decision recorded at parent DESIGN Big Decision row + Open Q #4. |

## Definition of done

- [ ] All 18 acceptance criteria in [S000064_TRACKER.md](S000064_TRACKER.md) `## Acceptance Criteria` section satisfied.
- [ ] `./scripts/validate.sh && ./scripts/test.sh` both exit 0.
- [ ] `/CJ_personal-workflow check` on this directory exits PASS.
- [ ] Smoke tests in [S000064_TEST-SPEC.md](S000064_TEST-SPEC.md) `## Smoke Tests` all pass.
- [ ] E2E tests in [S000064_TEST-SPEC.md](S000064_TEST-SPEC.md) `## E2E Tests` walked manually pre-`/ship`.

## Not in scope

- All non-scope items inherit from parent feature [F000031_DESIGN.md](../F000031_DESIGN.md) `## Not in scope` section. No story-specific additional non-goals.

## Pointers

- Parent feature DESIGN: [../F000031_DESIGN.md](../F000031_DESIGN.md)
- Parent feature TRACKER: [../F000031_TRACKER.md](../F000031_TRACKER.md)
- Parent feature ROADMAP: [../F000031_ROADMAP.md](../F000031_ROADMAP.md)
- Story SPEC: [S000064_SPEC.md](S000064_SPEC.md)
- Story TEST-SPEC: [S000064_TEST-SPEC.md](S000064_TEST-SPEC.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260531-153400-70306-design-20260531-154158.md`
