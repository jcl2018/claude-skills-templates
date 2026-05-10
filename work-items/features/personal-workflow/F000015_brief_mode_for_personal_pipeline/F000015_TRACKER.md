---
name: "--brief mode for /personal-pipeline"
type: feature
id: "F000015"
status: active
created: "2026-05-09"
updated: "2026-05-09"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/lucid-sanderson-bcccff"
blocked_by: ""
---

<!-- Source design: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md
     (APPROVED; Builder mode; Approach A — inline brief synthesis in /personal-pipeline) -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/brief_mode_for_personal_pipeline`
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

1. Run `/personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `/personal-pipeline --brief "<paragraph>" --type defect` produces a green pipeline run end-to-end on a workbench fixture
- [ ] `/personal-pipeline` (no `--brief`) is byte-identical to current behavior on a manual-mode test run
- [ ] `/personal-pipeline --brief "..." --type feature` errors out with the prescribed message; no work-item directory written; no synthesized stub left on disk
- [ ] `/personal-pipeline --brief "..." --type user-story` errors out with the v1.1 follow-up message
- [ ] Synthesized stub design doc is well-formed enough that `/scaffold-work-item` runs successfully without any pipeline.md-internal post-processing
- [ ] The 6-run sunset checkpoint correctly counts brief-mode invocations (new `mode` field; default `manual` if absent)
- [ ] `scripts/validate.sh` and `scripts/test.sh` pass post-change

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000029 (Phase 0 spike: parser surface + Step 8.5 scan surface enumeration)
- [ ] Ship S000030 (--brief flag plumbing + stub synthesis in /personal-pipeline)
- [ ] Ship S000031 (end-to-end brief-mode smoke fixture with special-character coverage)
- [ ] Update CLAUDE.md skill-routing section with brief-mode trigger phrases
- [ ] Update telemetry-parser sunset checkpoint to read the new `mode` field, defaulting to `manual` if absent

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. Scaffolded F000015 from `chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md` via /scaffold-work-item.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/personal-pipeline/SKILL.md` (Usage section + Error Handling table; version bump)
- `skills/personal-pipeline/pipeline.md` (Step 0a: Brief Mode branch + telemetry `mode` field)
- `skills/personal-pipeline/fixtures/` (new brief-mode end-to-end fixture)
- `CLAUDE.md` (skill-routing trigger phrases for brief mode)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Friction discovered: every small defect/task that warrants a tracked work-item still requires a full /office-hours session. Memory entry "Skip design for small TODOs" only covers work that bypasses the work-item layer entirely; brief mode closes the gap for small-but-trackable work.
- Builder reflex: when offered a workaround (hand-write a minimal design doc), the user escalated to "wanting to resolve it as a feature" — fix the tool, don't paper over recurring friction.
- Approach A wins on smallest diff (~50 lines), 100% backward compat, preserved audit trail (real file on disk), and one-refactor promotion path to Approach B if more lite modes appear later.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-09: Premise 4 narrowed (spec-review iteration 1) — `--brief` is locked to `--type {task, defect}` in v1; `--type user-story` deferred to v1.1 against real usage data, not pre-judged. Summary: avoid pre-judging user-story-as-brief; let v1 task/defect adoption inform whether v1.1 should support it.
- [decision] 2026-05-09: Special-character handling — embed brief text inside a fenced verbatim block (` ```text ` ... ` ``` `) to insulate stub structure from backticks, `## `-prefixed lines, and other Markdown. Summary: structural safety over template prettiness.
- [decision] 2026-05-09: Phase 0 spike is BLOCKING for any pipeline.md edits — must enumerate `/scaffold-work-item` parser surface AND `/personal-pipeline` Step 8.5 scan surface, confirm stub satisfies both, before any code changes. Summary: "harden the stub if you have to" applies to both surfaces.
- [decision] 2026-05-09: Filename grammar `^[a-z0-9_]+-[a-z0-9-]+-design-[0-9]{8}-[0-9]{6}-brief(-[2-9]|-[1-9][0-9]+)?\.md$` — collision suffix starts at `-2`; `-1` is reserved as a no-op alias and is never written. Summary: explicit grammar prevents drift in collision handling.
- [orchestrator] 2026-05-10T06:14:39Z /personal-pipeline --auto run_id=20260509-225921-12132: halt at Step 4.3 — multi-story feature with 3 user-story children (S000029/S000030/S000031); Phase 1 (scaffold) complete; Phase 2 (implement) and Phase 3 (qa) deferred to manual per-child invocation per pipeline.md v1 scope. Summary: end_state=green; orchestrator did its job up to scaffold.
- [auto-pipeline-clean] 2026-05-10T06:14:39Z run_id=20260509-225921-12132: 1 mechanical decision logged, 0 taste, 0 user-challenge-approved → Step 8.5 short-circuit (empty state). No close calls to confirm.
