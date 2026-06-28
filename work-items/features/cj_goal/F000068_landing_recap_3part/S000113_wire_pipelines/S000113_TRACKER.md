---
name: "Wire the recap into the 4 pipelines + reframe the CLAUDE.md convention"
type: user-story
id: "S000113"
status: active
created: "2026-06-28"
updated: "2026-06-28"
parent: "F000068"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "3126f56d68344060a473da8c0a5b130a374d3d58"
    completed_at: "2026-06-28T19:45:39Z"
    test_rows_run: 7
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke-summary] green 5/5", "[qa-e2e-summary] green E1+E2", "[qa-audit] AUDITS=deferred", "[qa-pass] S000113"]
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Atomic story under F000068. DESIGN.md is a brief stub linking to the parent
     F000068_DESIGN.md; the parent's /office-hours session is the design context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/landing_recap_3part` (shipping in same PR as parent)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (N/A — atomic story)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `skills/CJ_goal_feature/pipeline.md` — the terminal Step 6.5 "PIPELINE COMPLETE" block is reshaped to the 3-part recap (calls the helper; documented prose fallback when the helper is absent).
- [ ] `skills/CJ_goal_task/pipeline.md` — the terminal STOP-at-PR block (Step 7) is reshaped to the 3-part recap likewise.
- [ ] `skills/CJ_goal_defect/pipeline.md` — a before-recap is added ahead of the `/land-and-deploy` land step (Step 10) AND the existing after/post-land recap is reshaped to 3-part.
- [ ] `skills/CJ_goal_todo_fix/pipeline.md` (or `SKILL.md` per its structure) — a before+after recap is added around the `/ship → /land-and-deploy` tail, per drained TODO.
- [ ] `CLAUDE.md` `## Post-land recap` is reframed to describe the 3-part **before+after** land/PR recap, names the helper as producer, makes the agent's content-authoring responsibility explicit, and keeps the "advisory, never blocks, no validate.sh check asserts it fired" framing. The `cj-goal-common.sh` Scripts-reference row is updated to mention the new `recap` phase.
- [ ] If any `docs/workflow.md` / `docs/workflows/*.md` Touches block enumerates the cj-goal-common phases, `recap` is added (doc-sync surfaces this).
- [ ] `scripts/validate.sh` green (no NEW check; existing checks unaffected). Grep each of the 4 pipeline.md files: the recap pointer/call is present at the terminal/land step (manual confirmation; not gated).

## Todos

<!-- Actionable items for this story. -->

- [x] Reshape the feature + task PR-stop terminal blocks to the 3-part recap (single at-PR recap each).
- [x] Add before-recap + reshape after-recap in the defect pipeline around Step 10.
- [x] Add before+after recap around the todo_fix `/ship → /land-and-deploy` tail (per drained TODO).
- [x] Reframe the `CLAUDE.md` `## Post-land recap` convention + update the `cj-goal-common.sh` Scripts-reference row.
- [x] Add `recap` to any docs Touches blocks that enumerate cj-goal-common phases.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-28: Created. Wire the `--phase recap` helper into the four cj_goal pipelines (before+after for the two landing verbs, one at-PR recap for the two PR-stop verbs) + reframe the CLAUDE.md convention + docs.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_goal_feature/pipeline.md` (modified) — reshaped Step 6.5 terminal block to a single at-PR 3-part recap (`--when after`) + prose fallback.
- `skills/CJ_goal_task/pipeline.md` (modified) — reshaped the Step 7/8.5 terminal block likewise.
- `skills/CJ_goal_defect/pipeline.md` (modified) — added a BEFORE recap in Step 10 ahead of `/land-and-deploy` + reshaped the Step 12 summary to an AFTER 3-part recap.
- `skills/CJ_goal_todo_fix/pipeline.md` (modified) — added the BEFORE recap in Step 5.6 (right after `/ship`, before `/land-and-deploy`, per drained TODO).
- `skills/CJ_goal_todo_fix/SKILL.md` (modified) — added the AFTER recap in the Agent-layer terminal (after `/land-and-deploy` + DONE-mark, per drained TODO). The todo verb's land tail lives in SKILL.md Routing, not pipeline.md.
- `CLAUDE.md` (modified) — reframed `## Post-land recap` to the 3-part before+after convention naming `cj-goal-common.sh --phase recap` as producer; added a "Land/PR recap formatter" paragraph documenting the 7th cj-goal-common phase (the Scripts-reference equivalent in CLAUDE.md's established style).
- `docs/architecture.md` (modified) — added a `recap` bullet to the "Phases it owns" list.
- `docs/workflows/CJ_goal_feature.md` / `CJ_goal_task.md` (modified) — added the at-PR recap to the chart + the Steps·phases + Scripts·tools·shell Touches bullets (Check 15b-enforced).
- `docs/workflows/CJ_goal_defect.md` / `CJ_goal_todo_fix.md` (modified) — added the before+after recap to the chart + the Touches bullets.

## Insights

<!-- Non-obvious findings worth remembering. -->

- The two landing verbs (defect, todo_fix) get a true before+after pair around the land; the two PR-stop verbs (feature, task) get one at-PR recap — the orchestrator never lands, so the human's later `/land-and-deploy` is the existing "direct /land-and-deploy" recap path the convention already covers.
- Upstream `/land-and-deploy` is NOT edited (untouchable, same rule as `/CJ_document-release`); the before/after recap calls live in this repo's pipeline.md files around the land step, not inside the upstream skill.

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] Recap placement per verb. Summary: before+after pair around the land for the two landing verbs (defect Step 10, todo_fix `/ship → /land-and-deploy` tail per drained TODO); one at-PR recap reshaping the existing terminal block for the two PR-stop verbs (feature Step 6.5, task Step 7). Each call has a documented prose fallback for an absent helper.
- 2026-06-28 [impl-finding] Resolved the SPEC Open Question on todo_fix wiring location: the todo verb's `/ship → /land-and-deploy` tail is agent-driven and described in **SKILL.md's Routing "Agent-layer terminal"**, while the pre-`/land-and-deploy` seam (Step 5.6) lives in pipeline.md. So the BEFORE recap went into `pipeline.md` Step 5.6 (right after `/ship`, before `/land-and-deploy`) and the AFTER recap into `SKILL.md`'s Agent-layer terminal (after `/land-and-deploy` + DONE-mark). Both run per drained TODO.
- 2026-06-28 [impl-decision] CLAUDE.md has no dedicated `| cj-goal-common.sh | … |` Scripts-reference TABLE row — the phases are documented as prose paragraphs (the portability-gate paragraph is the established pattern). So the "Scripts-reference row" AC was satisfied by adding a parallel "Land/PR recap formatter (F000068/S000112)" paragraph right after the portability-gate one (the 7th phase), plus a `recap` bullet in `docs/architecture.md`'s "Phases it owns" list — the two canonical phase enumerations.
- 2026-06-28 [impl-decision] todo_fix recap calls pass `--mode feature` (not a new `todo_fix` mode) — matching this pipeline's existing `--phase sync`/`portability-audit` calls per CLAUDE.md; the block shape is verb-neutral and `--mode` is labelling-only. No change to the shared `--mode` enum.
- 2026-06-28 [impl-finding] The Check 15b 4-bullet Touches blocks in `docs/workflows/CJ_goal_*.md` DO enumerate the cj-goal-common phases (chart + Steps·phases + Scripts·tools·shell), so the "conditional" docs edit was REQUIRED, not optional. Added `recap` to all four verb workflow docs + architecture.md; validate.sh Check 15b stays green.
- 2026-06-28 [impl-finding] Hit the known test.sh restore-trap gotcha (MEMORY): running test.sh left a stray `zzz-test-scaffold` row in README.md that tripped Check 25 (README-freshness) → 2 phantom test.sh failures. Restored README.md from HEAD (it was never in this story's change set); a single clean test.sh run is green (Failures: 0, RESULT: PASS).
- 2026-06-28 [impl] Modified 4 pipeline surfaces (feature/task pipeline.md, defect pipeline.md, todo_fix pipeline.md + SKILL.md), CLAUDE.md (`## Post-land recap` reframe + 7th-phase paragraph), and 5 docs (architecture.md + 4 verb workflow docs). Upstream `/land-and-deploy` NOT touched (verified via `git diff --name-only`). validate.sh green (0/0); full test.sh green (Failures: 0); grep confirms the recap pointer at each pipeline's terminal/land step with the right before/after count.
- 2026-06-28 [impl-auto] Auto-mode run (subagent context, no AUQ — approved autonomous build). The sensitive surface (skills/, CLAUDE.md) would normally AUQ-gate; proceeded per the orchestrator directive. Upstream-untouchable rule honored (`/land-and-deploy` unedited).
- 2026-06-28 [impl-pass] S000113: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-28 [qa-smoke] S1 (AC-1): green — `grep -l 'phase recap'` matches both feature + task pipelines (PR-stop recap pointer present).
- 2026-06-28 [qa-smoke] S2 (AC-2): green — `grep -c 'phase recap'` defect=2 (before+after), todo_fix pipeline.md=1 (before) + SKILL.md=1 (after) → before+after pair around the land for both landing verbs.
- 2026-06-28 [qa-smoke] S3 (AC-3): green — CLAUDE.md `## Post-land recap` names `cj-goal-common.sh --phase recap` as producer and keeps the advisory / "NEVER halts" / "no validate.sh gate" framing.
- 2026-06-28 [qa-smoke] S4 (AC-5): green — `git diff --name-only` touches only this repo's pipeline.md / CLAUDE.md / docs / scripts / tests / spec; no `/land-and-deploy` file in the diff (upstream untouched).
- 2026-06-28 [qa-smoke] S5 (AC-6): green — validate.sh PASS (Errors: 0, Warnings: 0); no new check introduced; Check 15b + Check 24 green.
- 2026-06-28 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending).
- 2026-06-28 [qa-e2e-run-start] RUN_ID=20260628-124539-68969 commit=3126f56
- 2026-06-28 [qa-e2e] E1 (AC-1, AC-2, AC-4): green — read each of the 4 pipelines at its terminal/land step: feature + task each show one at-PR recap (`--when after`); defect shows before+after around Step 10/12; todo_fix shows before (pipeline.md Step 5.6) + after (SKILL.md Agent-layer terminal); each call site documents a prose fallback for an absent helper.
- 2026-06-28 [qa-e2e] E2 (AC-3, AC-6): green — reframed CLAUDE.md convention reads as a coherent 3-part before+after recap that names the helper, makes the agent's content-authoring explicit, and keeps the advisory framing; `validate.sh` exits 0 (doc-sync surfaces clean).
- 2026-06-28 [qa-e2e-summary] green (inline subagent; 0 rows parent-inline; 0 deferred): both E2E criteria green — all four pipelines present the recap at the right point with the right count + prose fallback; CLAUDE.md convention coherent + validate green.
- 2026-06-28 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom(present:test-cj-goal-common-recap),doc-spec-custom:none (Step 8.6a/8.6b ran inline; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-28 [qa-pass] S000113 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
