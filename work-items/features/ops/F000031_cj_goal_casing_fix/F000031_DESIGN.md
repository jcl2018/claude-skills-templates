---
type: design
parent: F000031
title: "Casing-only rename of F000027 verbs (cj_goal_feature/defect → CJ_goal_feature/defect) — Feature Design"
version: 1
status: Draft
date: 2026-05-31
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

The `CJ_goal_*` skill family has a casing inconsistency introduced by F000027's two-verb refactor (v5.0.x, just shipped). After F000027 the family looks like: lowercase `cj_goal_feature` + `cj_goal_defect` (the F000027 verbs), uppercase `CJ_goal_investigate` + `CJ_goal_todo_fix` (the older orchestrators). Both halves are end-to-end goal orchestrators with identical semantic role — they share the "goal" family token because they share an end-state goal pattern. The casing mismatch is purely cosmetic but visible across every routing surface (rules/skill-routing.md, CLAUDE.md, doc/PHILOSOPHY.md, doc/ARCHITECTURE.md, TODOS.md, work-items/ trackers, operator muscle memory).

Fresh readers parse the mix as a real defect because the rest of the CJ_* family is uniformly uppercase (9 of 11 skills). The 2 lowercase F000027 verbs are the outliers. The user originally framed this as "remove the goal token, it's not used" — the office-hours conversation surfaced that the goal token IS a load-bearing family signal (orchestrator vs single-phase utility), and the real defect is casing only. This feature lands the casing fix; the goal token stays.

## Shape of the solution

Single atomic refactor PR. Two-step `git mv` on case-insensitive macOS APFS to rename the two F000027 skill dirs (lowercase → uppercase). Create lowercase deprecation shims under `deprecated/{name}/` (first actual use of CLAUDE.md's documented "Deprecated skills convention"). Update `skills-catalog.json` with 6 edits (2 renames + 2 new deprecated entries + 2 dep-chain fixes on existing CJ_goal_run/auto entries). Flip every active-routing reference across docs + tests + scripts. Single user-story child carries the full implementation — all 10 steps are tightly coupled and must land in one PR to keep validate.sh + test.sh green.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Two-step git mv, shim creation, catalog edits, cross-reference flips, test-regex update | S000064 | [S000064_casing_rename_impl/S000064_TRACKER.md](S000064_casing_rename_impl/S000064_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (full rename + shims now) over Approach B (defer to v6.0.0 bundle) and Approach C (codify casing as intentional) | Self-contained PR; immediate visible cleanup; reuses tested F000027 shim pattern; doesn't create a new sunset wave (rides v6.0.0 already retiring CJ_goal_run/auto). B has worse hit rates per CLAUDE.md hygiene conventions (stale bundled-future TODO rows). C's convention claim ("verbs are lowercase") doesn't survive contact with the existing taxonomy — CJ_goal_investigate + CJ_goal_todo_fix are also orchestrators. |
| 2 | Direction of fix: lowercase → UPPERCASE (not uppercase → lowercase) | Taxonomy weight: 9 of 11 CJ_* skills already uppercase. Flipping the 2 outliers is the smaller-blast-radius change. |
| 3 | Lowercase deprecation shims placed at `deprecated/{name}/` (not `skills/{name}/`) | (a) APFS case-collision: the shim path `skills/cj_goal_feature/` is the same inode as the new canonical `skills/CJ_goal_feature/` — they can't coexist. (b) `deprecated/` placement follows CLAUDE.md's documented "Deprecated skills convention" — this PR is the FIRST actual use of the convention. F000027's existing CJ_goal_run/auto shims stay at `skills/` (historical) and get removed entirely at v6.0.0 sunset, so a mid-life migration would be pure churn. |
| 4 | Single user-story (S000064) — no further decomposition | The 10 implementation steps are tightly coupled. Splitting into multiple stories would force multi-PR coordination where each intermediate PR leaves test.sh red (S000060 regression test asserts the F000027 shim references the lowercase name; flipping it in PR1 without renaming the dir in PR2 → red). Atomic story is the only shape that keeps the pre-commit hook passing throughout. |
| 5 | Shim shape mirrors F000027 actual content (frontmatter + Deprecation Banner section + Routing section, ~40 lines), not a minimal stub | F000027's CJ_goal_run shim is the tested precedent. Mirroring its shape exactly validates the pattern is reusable (not bespoke to F000027) and reduces cognitive load for future readers comparing the four shims. |
| 6 | Memory file references at `~/.claude/projects/.../memory/` excluded from PR diff | Memory files are operator-local state per `feedback_workbench_scope` memory. Including them in PR diff would (a) leak personal state, (b) not apply on other operators' machines, (c) violate workbench-only scope. Operator-local follow-up after merge handles them. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Two-step `git mv` on case-insensitive APFS may exhibit stale-index edge case (not previously used in this repo's history — F000021 family rename did direct R-renames between distinct names, not the case-collision pattern) | Implementer verifies each step's exit code; if needed, runs `git update-index --refresh` between the temp-name and target-name moves. |
| `5.0.12` version literal baked into shim frontmatter + 2 new catalog entries BEFORE `/ship` runs the VERSION bump — if another worktree's PR lands at v5.0.12 first, our embedded literals drift. | Implementer runs `./scripts/check-version-queue.sh` immediately before `/ship` per design Step 8; if slot != 5.0.12, hand-edit the three literals (~5 sec) before commit. |
| TODOS.md rows referencing lowercase names (likely 0-2 rows) | Implementer greps TODOS.md during Step 6; flip active rows, leave strikethrough/DONE rows verbatim. |
| Open PRs that name lowercase skills in commit messages / PR bodies | Acceptable cost — shims keep lowercase invocations working; no rewrite. |
| `/loop /cj_goal_feature` invocations in user shell history or scheduled cron jobs | Shims preserve these; users update cron entries manually. No automated migration. |
| Should F000027's CJ_goal_run + CJ_goal_auto shims also migrate from `skills/` to `deprecated/`? | DEFERRED to a TODOS row tagged `[v6.0.0 sunset]` per design Open Question #6. Reason: all four shims get removed at v6.0.0, so mid-life migration is pure churn. |
| Worktree directory naming convention `cj-feat-*` (lowercase) — flip to `cj-FEAT-*`? | KEEP lowercase. Worktree branch names are runtime artifacts, not skill identity; existing operator muscle memory + open worktrees use lowercase. Out of scope. |
| Resume state directories `.cj-goal-feature/` + `.cj-goal-defect/` — flip? | KEEP lowercase. Runtime state, not skill identity. Flipping would break in-flight resume state for any open pipeline. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] `skills/CJ_goal_feature/` + `skills/CJ_goal_defect/` exist; old lowercase dirs gone from `skills/`.
- [ ] `deprecated/cj_goal_feature/SKILL.md` + `deprecated/cj_goal_defect/SKILL.md` exist with F000027-shim-shape content.
- [ ] `skills-catalog.json` has 6 edits applied; `./scripts/validate.sh` passes.
- [ ] F000027 shim cross-references (`skills/CJ_goal_run/SKILL.md` + `skills/CJ_goal_auto/SKILL.md`) flipped to uppercase canonical.
- [ ] Docs + scripts + tests all show uppercase active-routing references. CHANGELOG.md v5.0.12 entry written in user-forward voice.
- [ ] Version-slot preflight ran; baked-in literals reconciled if collision detected.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` both pass.
- [ ] No git history rewritten.
- [ ] Invoking `/cj_goal_feature` prints the deprecation banner and routes to `/CJ_goal_feature`; `/CJ_goal_feature` works without banner. Same for defect pair.
- [ ] PR opens at v5.0.12 and stops for human review.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Migrating F000027's CJ_goal_run + CJ_goal_auto shims from `skills/` to `deprecated/` — deferred to v6.0.0 sunset PR (TODOS row tagged `[v6.0.0 sunset]`); mid-life migration is pure churn when v6.0.0 removes all four shims.
- Renaming the worktree branch prefix `cj-feat-*` to uppercase — runtime artifact, not skill identity; operator muscle memory + open worktrees depend on lowercase.
- Renaming resume state directories (`.cj-goal-feature/`, `.cj-goal-defect/`) — runtime state, flipping breaks in-flight resume state for any open pipeline.
- Rewriting git history to flip lowercase references in F000027 commit messages — git history is immutable record of what was; new commits use new names.
- Editing memory files at `~/.claude/projects/.../memory/` — operator-local state per `feedback_workbench_scope` memory; handled as operator-local follow-up after merge, not in PR diff.
- Renaming the telemetry path `~/.gstack/analytics/CJ_goal_feature.jsonl` — already uppercase (per pipeline.md Step 6); no action needed.
- Downstream-consumer churn (portfolio repo, exploration repo) — workbench-only scope per `feedback_workbench_scope`.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000031_TRACKER.md](F000031_TRACKER.md)
- Roadmap: [F000031_ROADMAP.md](F000031_ROADMAP.md)
- Child user-story: [S000064_casing_rename_impl/S000064_TRACKER.md](S000064_casing_rename_impl/S000064_TRACKER.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260531-153400-70306-design-20260531-154158.md`
- Related feature (F000027 two-verb refactor — the source of the casing inconsistency this PR fixes): `work-items/features/personal-workflow/F000027_cj_goal_two_verb_refactor/`
- F000027 shim pattern precedent: `skills/CJ_goal_run/SKILL.md`, `skills/CJ_goal_auto/SKILL.md`
