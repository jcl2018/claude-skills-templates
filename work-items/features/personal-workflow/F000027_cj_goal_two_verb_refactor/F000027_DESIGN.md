---
type: design
parent: F000027
title: "CJ_goal family — two-verb refactor (feature / defect) over leaf skills — Feature Design"
version: 1
status: Draft
date: 2026-05-21
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The CJ_goal family grew to five overlapping orchestrators — `/CJ_goal_run`, `/CJ_goal_auto`, `/CJ_goal_investigate`, `/CJ_goal_todo_fix`, plus the internal `/CJ_personal-pipeline`. The front door is cluttered: the author (or a newcomer three weeks later) can't tell which to invoke for "build a feature" vs "fix a bug."

The orchestration is also deeply nested — `run → personal-pipeline → scaffold/impl/qa` as nested subagents — which already hit a wall (the pipeline subagent cannot spawn its own scaffold subagent; it halts at Phase 2, the "nested-subagent wall"). The goal is to collapse the entry point to two clear verbs — **feature** and **defect** — on a flat, robust architecture, while preserving the orthogonal backlog-drain utility (`/CJ_goal_todo_fix` + `/CJ_personal-pipeline`).

## Shape of the solution

Two independent verb skills, each owning its full orchestration inline, dispatching the proven leaf skills as depth-≤2 subagents. The common, deterministic bits (worktree init, telemetry/audit-receipt write, PR-existence checks) move to a small bash helper (`cj-goal-common.sh`) with explicit mode flags — not an LLM-followed orchestrator.

- `/cj_goal_feature "<topic>"`: worktree → `/office-hours` (inline, the one interactive phase, emits an APPROVED design doc) → silent scaffold/impl/qa leaf subagents → `/ship` creates a PR → **STOP** at the PR (the PR is the human review). No autoplan, no auto-merge/deploy.
- `/cj_goal_defect "<bug>"`: worktree → scaffold a no-doc bug report in `.inbox/` → `/investigate` (Agent subagent, Iron-Law: no fix without root cause) → promote to `work-items/defects/.../D000NNN_<slug>/` → `/CJ_qa-work-item` → `/ship` (human Gate #2) → `/land-and-deploy`. Mirrors current `/CJ_goal_investigate` (~80% reuse).

The two tails genuinely differ (feature PR-stops; defect human-ships-then-deploys) — they are NOT one shared doc. Sequencing is defect-first (Approach C) with an early `feature` smoke harness immediately after the `--caller` change, so the feature path is validated before PR #2 rather than left wholly unvalidated.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Helper prep: `cj-worktree-init.sh` `--caller` extension + `cj-goal-common.sh` + early feature smoke harness | S000057 | [S000057_helper_prep/S000057_TRACKER.md](S000057_helper_prep/S000057_TRACKER.md) |
| `/cj_goal_defect` skill (reshape of investigate v1.1 + no-doc bug-report scaffolding) | S000058 | [S000058_defect_skill/S000058_TRACKER.md](S000058_defect_skill/S000058_TRACKER.md) |
| `/cj_goal_feature` skill (office-hours-inline → silent build → PR-stop) + strengthened resume | S000059 | [S000059_feature_skill/S000059_TRACKER.md](S000059_feature_skill/S000059_TRACKER.md) |
| Deprecate `/CJ_goal_run` + `/CJ_goal_auto` (alias shims + sunset) + routing + catalog | S000060 | [S000060_deprecate_and_route/S000060_TRACKER.md](S000060_deprecate_and_route/S000060_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Build flat over the leaf skills; deprecate the front-door middle (D2 CONFIRMED). | Wrapping the existing engines (D1, rejected) inherits the nesting wall + welded-in gates. A flat orchestrator → leaf subagent (depth ≤ 2) is structurally immune to the nested-subagent wall. |
| 2 | `feature` terminates at a PR for human review; auto-merge+deploy dropped (D3, REVISED at GATE #1). | `cj-handoff-gate.sh`'s denylist blocks `skills-catalog.json`, `tests/`, `validate.sh`, `test.sh`, and skill dirs on purpose. Those are exactly the surfaces every skill-feature here touches, so the auto-mergeable subset is "features that change nothing important." Auto-deploy of skill-work is unsafe-by-construction; PR-stop is correct, not a v1 shortcut. |
| 3 | No autoplan in `feature` (Open Question 2, RESOLVED at GATE #1). | Rev 1's "autoplan only on the auto-deploy branch" was incoherent (the branch is known only after `/ship`, but autoplan runs before the build). With auto-deploy gone, every run PR-stops and gets a human PR review — which IS the architecture gate. AUQ-free. |
| 4 | Approach A: two independent verb skills + a deterministic `cj-goal-common.sh` helper (Open Question 3, RESOLVED). | The differing tails turn a shared LLM-followed `tail.md` (Approach B) into a mode-flag orchestrator — the coupling this refactor exists to remove. Common bits are deterministic bash (testable, no drift). |
| 5 | Keep `/CJ_goal_todo_fix` + `/CJ_personal-pipeline`; deprecate `/CJ_goal_run` + `/CJ_goal_auto` with hard alias shims + a sunset date (D5 CONFIRMED + GATE #1 added alias/sunset). | The drain utility is orthogonal and works; protect it. The two front-door orchestrators are what's being collapsed. Hard aliases (one-line banner → route to `/cj_goal_feature`) mirror the existing `CJ_run → CJ_goal_run` pattern; sunset at the next major (e.g. v6.0.0). |
| 6 | Resume strengthened to `last_completed_phase` + per-phase HEAD SHA + PR number, validated against current HEAD (GATE #1). | The A/S/P/M flag model was too lossy and could skip into a later phase on stale state. Validate-before-skipping: recorded SHA must be an ancestor of (or equal to) current HEAD, and any open PR must still resolve to OPEN; otherwise restart the affected phase. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Auto-merge for `feature` (Open Question 1) — re-opened for the author's override. Rev 2 drops it; the only safe path is a feature-specific gate profile whose denylist would still block the dangerous files (most of them), so it buys little. | Author decides at approval. Strong recommendation: leave dropped; PR-stop is correct. Re-open only with a concrete class of feature touching only low-risk surfaces. |
| office-hours doc-path recovery uses the recorded path from the resume state file, not a machine-readable pointer. A blind newest-glob would be fragile across parallel runs. | Deferred follow-up: a machine-readable pointer emitted by office-hours replaces the recorded-path recovery (S000059 uses recorded-path for v1). |
| A defect-first build never exercises the feature tail or the markers-writer, leaving the riskier skill unvalidated until PR #2. | S000057 ships an early `feature` smoke harness right after the `--caller` change (Approach C). |
| `cj-worktree-init.sh` rejects unknown callers (CONFIRMED, lines 55-57): `--caller feature|defect` → `state:failed`/`exit 1`. | S000057 adds `feature`→`cj-feat`, `defect`→`cj-def` to the validator `case` + prefix map. (Latent: shipped `/CJ_goal_auto --caller auto` already hits this — moot once auto is deprecated.) |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `/cj_goal_feature "<topic>"` from clean `main`: worktree → office-hours → APPROVED doc → silent scaffold/impl/qa → `/ship` opens a PR → STOP, zero AUQ between the office-hours approval and the PR.
- [ ] Re-invoking `feature` after a halt resumes at `last_completed_phase`, validating SHA/PR against current HEAD; never re-runs office-hours on an unchanged APPROVED doc, never skips a phase on stale state.
- [ ] `/cj_goal_defect "<bug>"` with no pre-existing defect dir: scaffolds a bug report, root-causes via `/investigate` (Iron-Law), passes the human `/ship` gate, deploys.
- [ ] Nesting depth ≤ 2; no subagent-spawns-subagent path.
- [ ] Deprecated `run`/`auto` print a banner and route to `feature`; `/CJ_goal_todo_fix` + `/CJ_personal-pipeline` + `/schedule` + `/loop` still work.
- [ ] `validate.sh` + `test.sh` green; `cj-worktree-init.sh` accepts the new callers; the early feature smoke harness passes.

## Not in scope

<!-- Explicit non-goals. -->

- **Auto-merge+deploy for `feature`** — unsafe-by-construction in this repo (the handoff-gate denylist blocks exactly the skill surfaces every feature touches). Parked, not deferred-with-intent.
- **`/CJ_goal_auto`'s no-office-hours fast path** — dropped; `feature` always runs office-hours inline as its one interactive phase.
- **Wrap-over-engines / single-skill-two-modes / a shared `tail.md`** — all rejected as recreating the nesting/coupling this refactor removes.
- **Full leaf rebuild** — the proven leaf skills (`/CJ_scaffold-work-item`, `/CJ_implement-from-spec`, `/CJ_qa-work-item`, `/investigate`, `/ship`, `/land-and-deploy`) are reused, not rewritten.
- **Migrating `/CJ_goal_todo_fix` off `/CJ_personal-pipeline`** — deferred follow-up; only then could personal-pipeline be deprecated too.
- **A machine-readable design-doc pointer emitted by office-hours** — deferred follow-up; v1 uses the recorded-path recovery.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000027_TRACKER.md](F000027_TRACKER.md)
- Roadmap: [F000027_ROADMAP.md](F000027_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-hardcore-hermann-c2b955-design-20260520-203603.md`
- Prior family-rename pass: `chjiang-F000021_cj_goal_family_rename_and_drain-design-20260519-185437.md`
