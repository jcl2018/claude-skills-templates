---
name: "3-part land/PR recap (before + after) for every cj_goal"
type: feature
id: "F000068"
status: active
created: "2026-06-28"
updated: "2026-06-28"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
---

<!-- Design source: ~/.gstack/projects/jcl2018-claude-skills-templates/landing-recap-design-20260628-185347.md (APPROVED 2026-06-28). -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/landing_recap_3part`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `cj-goal-common.sh --phase recap` exists: a pure formatter that renders a 3-part labelled block (Delivered / How to E2E-test it / Next step) on stdout, keyed off `--when {before|after}`, reusing the existing repeatable `--field KEY=VALUE` parsing, emitting `PHASE=recap` + `PHASE_RESULT=ok` and exit 0.
- [ ] The helper is fail-soft/advisory: missing/unknown fields render an empty section (never error); it mutates nothing and writes no telemetry; it NEVER halts.
- [ ] All four cj_goal pipelines reference the recap at their land/PR-stop step — the two landing verbs (`defect`, `todo_fix`) emit a before+after pair around the land; the two PR-stop verbs (`feature`, `task`) emit one at-PR recap reshaped to the 3-part form — each with a documented prose fallback when the helper is absent.
- [ ] `CLAUDE.md` `## Post-land recap` is reframed to the 3-part before+after land/PR convention, names the helper as producer, makes the agent's content-authoring responsibility explicit, and keeps the "advisory, never blocks, no validate.sh check asserts it fired" framing.
- [ ] `tests/cj-goal-common-recap.test.sh` exists and is green; `spec/test-spec-custom.md` has a `units:` row for it; `scripts/test.sh`, `scripts/validate.sh`, and `scripts/test-spec.sh --validate`/`--check-coverage` all green.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000112 — build the `cj-goal-common.sh --phase recap` formatter + `tests/cj-goal-common-recap.test.sh` + `spec/test-spec-custom.md` units row.
- [ ] S000113 — wire the recap into the four `cj_goal` pipeline.md files + reframe the `CLAUDE.md` `## Post-land recap` convention + the `cj-goal-common.sh` Scripts-reference row + any docs/workflows Touches blocks.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-28: Created. 3-part human-readable land/PR recap (Delivered / How-to-E2E-test / Next step) emitted before+after the land moment for all four cj_goal orchestrators, built as a new `cj-goal-common.sh --phase recap` formatter (Approach C), advisory (no validate.sh gate).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-goal-common.sh`
- `skills/CJ_goal_feature/pipeline.md`
- `skills/CJ_goal_task/pipeline.md`
- `skills/CJ_goal_defect/pipeline.md`
- `skills/CJ_goal_todo_fix/pipeline.md` (or `SKILL.md` per the todo verb's structure)
- `CLAUDE.md`
- `tests/cj-goal-common-recap.test.sh`
- `spec/test-spec-custom.md`
- `scripts/test.sh`
- `docs/workflow.md` + `docs/workflows/*.md` (if Touches blocks enumerate cj-goal-common phases)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The repo already carries a `## Post-land recap` convention in CLAUDE.md, but it is after-land-only, two-part (What/How), framed as "verify" not "E2E test", and hand-authored per orchestrator — so the shape drifts. The shared formatter fixes the shape drift; the agent still authors the change-specific content.
- The helper is a **pure formatter**: it does not compute content, does not mutate, does not write telemetry. `--mode` is for labelling/telemetry parity only; the block shape is verb-neutral.
- The `--field` value escaping must reuse the existing `telemetry` phase's repeatable `--field KEY=VALUE` parsing (print verbatim, no eval) — do not re-invent it.
- A NEW `tests/*.test.sh` requires a matching `spec/test-spec-custom.md` units row or Check 24's reverse-sweep fails (recurring blind spot). No new validate.sh check here, so the zzz-test-scaffold integration fixture is unaffected.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Approach C (shared formatting helper) + advisory posture chosen in /office-hours. Summary: build a `cj-goal-common.sh --phase recap` formatter and wire it into the four pipelines, with NO validate.sh presence-check and NO edit to upstream `/land-and-deploy` (untouchable, same rule as `/CJ_document-release`).
