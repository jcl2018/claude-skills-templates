---
name: "Phase 0 spike — parser surface + Step 8.5 scan surface enumeration"
type: user-story
id: "S000029"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/lucid-sanderson-bcccff"
blocked_by: ""
---

<!-- Parent feature: F000015. Source design (parent): ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md
     This is a BLOCKING spike for the rest of F000015. ~30 min combined for both legs. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/brief_mode_for_personal_pipeline` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
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

- [ ] Phase 0.a parser-surface check completed: read `skills/scaffold-work-item/scaffold.md`, enumerate the design-doc fields the parser actually consumes (title, mode, recommended-approach, type, component, others?), confirm the synthesized stub template satisfies all required fields
- [ ] Phase 0.b Step 8.5 scan-surface check completed: read `skills/personal-pipeline/pipeline.md` Step 8.5 implementation, enumerate which design-doc / SPEC sections auto-mode final gate scans for Taste / User-Challenge surfaces, confirm `(none, brief mode bypasses ...)` placeholders cannot match any taste-fork pattern
- [ ] Combined Phase 0 output written as a 10–15 line journal entry on this tracker: parser fields enumerated, Step 8.5 scan surface enumerated, stub satisfies both (yes/no), action taken (extend/harden/escalate)
- [ ] If a parser field is missing: stub template extended (preferred) OR escalation to Approach B documented in TODOS.md
- [ ] If a Step 8.5 scan pattern matches a placeholder: stub hardened (omit those sections, or use a sentinel string scanner refuses to match)

## Todos

<!-- Actionable items for this story. -->

- [ ] Read `skills/scaffold-work-item/scaffold.md` end-to-end; enumerate parser-consumed fields
- [ ] Read `skills/personal-pipeline/pipeline.md` Step 8.5; enumerate scan surface (sections + patterns)
- [ ] Cross-reference the synthesized stub template against both surfaces
- [ ] Write the combined Phase 0 note (10–15 lines) to this tracker's Journal
- [ ] Record extend / harden / escalate action explicitly

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. Scaffolded under F000015 via /scaffold-work-item.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- (No code edits in S000029; only journal note + optional TODOS.md entry on escalation)

## Insights

<!-- Non-obvious findings worth remembering. -->

- BLOCKING for the rest of F000015: cannot edit pipeline.md until both legs of the spike confirm feasibility.
- Either spike outcome is workable: extend stub template (preferred), harden stub (if Step 8.5 matches a placeholder), or escalate to Approach B (deferred). Document escalation reason in TODOS.md if it happens.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-09: Phase 0 is mandatory before any pipeline.md edits — both legs (parser surface + Step 8.5 scan surface) must produce yes/no verdicts. Summary: avoid editing pipeline.md against unverified assumptions about parser-consumed fields and taste-fork scan patterns.
