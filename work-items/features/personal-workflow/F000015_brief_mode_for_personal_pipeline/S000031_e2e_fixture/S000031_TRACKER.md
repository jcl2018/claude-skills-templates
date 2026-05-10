---
name: "End-to-end brief-mode fixture with special-character coverage"
type: user-story
id: "S000031"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/lucid-sanderson-bcccff"
blocked_by: "S000030"
---

<!-- Parent feature: F000015. Source design (parent): ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md
     Blocked by S000030 (flag plumbing); the fixture cannot run end-to-end until Step 0a is in place. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/brief_mode_for_personal_pipeline` (or use parent's branch)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's; S000031 is atomic) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] A new fixture under `skills/personal-pipeline/fixtures/` exercises a brief-mode end-to-end run on a known-trivial change
- [ ] Fixture brief text MUST include backtick + `## Header` line to verify the fenced verbatim block correctly insulates the stub structure
- [ ] Fixture verifies stub design doc is well-formed: passes `/scaffold-work-item` parser without modification (S000029 verdict honored)
- [ ] Fixture verifies post-synthesis flow: scaffold + implement + qa subagent chain runs to green end-to-end
- [ ] Fixture verifies telemetry write contains the new `mode` field with value `brief`
- [ ] Fixture verifies sunset-checkpoint parser defaults to `manual` for legacy telemetry lines (regression test)
- [ ] `scripts/test.sh` includes the new fixture in its run

## Todos

<!-- Actionable items for this story. -->

- [ ] Wait for S000030 ship; cannot run end-to-end without Step 0a
- [ ] Create fixture directory `skills/personal-pipeline/fixtures/brief-mode/`
- [ ] Author fixture brief text with intentional backtick + `## Header` line
- [ ] Wire fixture into `scripts/test.sh`
- [ ] Add regression assertion: legacy telemetry without `mode` field parses as `manual`

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. Scaffolded under F000015 via /scaffold-work-item.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/personal-pipeline/fixtures/brief-mode/` (new directory)
- `scripts/test.sh` (wire the new fixture into the test run)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The fixture is the critical regression net for special-character handling; if the fenced verbatim block doesn't fully insulate stub structure, the fixture must catch it.
- The fixture also acts as the byte-identity regression net for `--brief` absent: a manual-mode pass through the same fixture (different invocation) should produce identical post-state aside from the work-item's expected scaffold.
- Concurrent-invocation race is documented as accepted risk; the fixture does NOT exercise it.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-09: Fixture brief text MUST include backtick + `## Header` line. Summary: this is a forcing function — without that special-character coverage, the fixture is just a happy-path smoke and we lose the structural-safety regression net.
