---
name: "/CJ_run Entry Point Consolidation"
type: feature
id: "F000017"
status: active
created: "2026-05-13"
updated: "2026-05-13"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/awesome-pasteur-36565c"
blocked_by: "F000016"
---

<!-- Prerequisite: /office-hours design at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-awesome-pasteur-36565c-design-20260513-154622.md
     (Status: APPROVED). Distilled into DESIGN.md and ROADMAP.md. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_run_entry_point`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks)
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline)
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

- [ ] `/CJ_ship-feature` renamed to `/CJ_run`; old name removed from routing
- [ ] `/CJ_run <design-doc>` runs the existing full-pipeline behavior unchanged
- [ ] `/CJ_run <work-item-dir>` detects phase from TRACKER state and dispatches correctly
- [ ] `/CJ_run` (no args) scans current branch's work-items/ and auto-resumes
- [ ] `/CJ_personal-pipeline` removed from `rules/skill-routing.md` (internal-only)
- [ ] `validate.sh` passes after all changes
- [ ] Telemetry log migrates to `CJ_run.jsonl`; sunset counter resets

## Todos

- [ ] Ship S000038 (rename + Branch(g) — can ship independently of F000016)
- [ ] Ship S000039 (Branch(f) work-item-dir — depends on F000016/S000036)
- [ ] Update CLAUDE.md routing references (if any) post-rename

## Log

- 2026-05-13: Created. Consolidates /CJ_ship-feature + /CJ_personal-pipeline into /CJ_run with multiple input modes (design-doc, work-item-dir, no-arg branch scan).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_ship-feature/` → `skills/CJ_run/` (rename)
- `skills/CJ_run/SKILL.md` (frontmatter update)
- `skills/CJ_run/run.md` (new branches f, g)
- `skills/CJ_personal-pipeline/SKILL.md` (description: internal-only)
- `skills-catalog.json`
- `rules/skill-routing.md`

## Insights

- The "auto" feature the user values is in /CJ_ship-feature; renaming it makes the value visible from the routing alone.
- F000016 (already scaffolded) provides the underlying `--work-item-dir` flag and multi-story loop that Branch(f) and Branch(b) need; F000017 is the entry-point shell that exposes them.
- The design intentionally keeps `/CJ_personal-pipeline` invocable directly (just unrouted) — escape hatch for direct sub-pipeline calls without breaking existing scripts.

## Journal

- 2026-05-13 [decision] Two-child decomposition: S000038 (rename + Branch g) ships independent of F000016; S000039 (Branch f impl_qa_ship) waits on F000016/S000036. Rationale: design's per-mode dependency map names this exact split.
- 2026-05-13 [decision] Slug `cj_run_entry_point` chosen over `cj_run_consolidation` and bare `cj_run`. Rationale: describes the role (entry point), not the action (consolidation).
- 2026-05-13 [decision] No backward-compat shim for `/CJ_ship-feature`. Direct callers must update. Rationale: shims would recreate the naming confusion this feature fixes.
