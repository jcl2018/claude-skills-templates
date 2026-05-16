---
name: "/CJ_goal_investigate — defect-aware bugfix pipeline orchestrator"
type: feature
id: "F000023"
status: active
created: "2026-05-15"
updated: "2026-05-15"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/S000049_cj_suggest_impr_draft_filter-20260515-192236"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_goal_investigate`
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

- [ ] `/CJ_goal_investigate D000NNN` against a scaffolded defect produces a shipped + deployed PR with a populated RCA matching the template, with no operator intervention except `/ship` Gate #2.
- [ ] `/CJ_goal_investigate --dry-run D000NNN` prints the chain plan + idempotency state + expected RCA / test-plan writes WITHOUT modifying any file.
- [ ] Re-running `/CJ_goal_investigate D000NNN` after green is a one-line summary, no /investigate dispatch.
- [ ] Re-running after `/ship` declined resumes at `/ship`.
- [ ] `[investigate-unverified]` halts pre-ship and writes a transcript path the operator can `cat` to investigate.
- [ ] Tracker journal of every dispatched defect contains exactly one `[investigate-*]` line (terminal end-state).
- [ ] CHANGELOG / README / skill-routing rules updated.
- [ ] The `/investigate` subagent's sentinel-wrapped JSON output validates against the orchestrator's parser on a real defect (Phase 7 dogfood).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000049 — Phase1: single-defect mode (v1.0 ship)
- [ ] (v1.1 deferred) drain mode, --quiet, family-drain lock, sunset criterion
- [ ] (v1.1 deferred) freestanding defect dir convention (D<NNN>_bug-report.md)
- [ ] (v2.0 speculative) ad-hoc bugs without scaffolded defect dir, hot-fix path

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-15: Created. Defect-aware bugfix pipeline orchestrator — `/CJ_goal_investigate` sibling to `/CJ_goal_run` + `/CJ_goal_todo_fix`. v1.0 single-defect mode only; drain/quiet/lock/sunset deferred to v1.1.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills/CJ_goal_investigate/SKILL.md (new)
- skills/CJ_goal_investigate/pipeline.md (new)
- skills-catalog.json (modified)
- rules/skill-routing.md (modified)
- README.md (modified)
- CHANGELOG.md (modified)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The Iron-Law gate (`/investigate`'s "no fixes without root cause") becomes free when the orchestrator refuses to advance until RCA exists and contains a non-empty root-cause section.
- Machine-readable handoff (sentinel-wrapped JSON DEBUG REPORT) eliminates the free-text-parse failure mode the dual-voice reviewers flagged as critical. The contract is convention, not an upstream feature.
- `/CJ_implement-from-spec` is NOT in this chain. `/investigate` Phase 4 writes the fix directly to source. RCA + test-plan are audit artifacts populated post-investigate, not inputs to a separate implementation step.
- Splitting v1.0 to single-defect-only is the load-bearing scope fix. Both reviewers (Claude subagent + codex) independently called out v0 as over-scoped.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-15: scope-split — v1.0 single-defect only; drain/quiet/lock/sunset deferred to v1.1. Rationale: no end-state taxonomy data yet; ceremony, not leverage at v1.
- [decision] 2026-05-15: machine-readable handoff — `/investigate` emits sentinel-wrapped JSON (`DEBUG_REPORT_BEGIN_JSON ... DEBUG_REPORT_END_JSON`). Convention, not upstream feature. Phase 1 of impl validates against live `/investigate`.
- [decision] 2026-05-15: `/CJ_implement-from-spec` removed from chain — `/investigate` Phase 4 writes the fix directly; RCA + test-plan are post-investigate audit artifacts.
- [decision] 2026-05-15: Iron-Law-equivalent halt — `[investigate-unverified]` (JSON.status=DONE_WITH_CONCERNS) does NOT auto-advance to /ship. Reviewer-flagged critical fix.
- [decision] 2026-05-15: legacy defect dir convention only in v1 — `work-items/defects/<domain>/D000NNN_<slug>/`. Freestanding `D<NNN>_bug-report.md` deferred to v1.1.
- [orchestrator] 2026-05-15: /CJ_personal-pipeline (--suppress-final-gate) scaffold complete. Feature with 1 user-story child (S000049). Multi-story feature halt per pipeline.md Step 4 sub-step 3; end_state=green. Per-child impl+QA dispatch deferred to wrapper (/CJ_goal_run Branch (b)/(f)).
- [auto-pipeline-clean] 2026-05-15: suppression path — zero Taste, zero User-Challenge-Approved decisions accumulated (scaffold-only run, multi-story halt before Phase 2).
