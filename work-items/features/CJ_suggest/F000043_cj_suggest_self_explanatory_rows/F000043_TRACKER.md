---
name: "Make /CJ_suggest rows self-explanatory (what-it-does + effort)"
type: feature
id: "F000043"
status: active
created: "2026-06-03"
updated: "2026-06-03"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-225728-46346"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_suggest_self_explanatory_rows`
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

- [ ] `bash skills/CJ_suggest/scripts/suggest.sh` (no flags) prints a card list: each item shows ID (when present), title, `Pri · Effort`-label, a `What:` line from the body's first line, and a `Status:` line.
- [ ] `bash skills/CJ_suggest/scripts/suggest.sh --for-skill cj-goal --limit 15` prints the identical byte-stable markdown table as today (consumer path unchanged), verified by `/CJ_goal_todo_fix` still parsing candidates.
- [ ] Empty-body rows render `What: (no description)`; orphan / default-P4-M signals still visible in the card `Status:` line.
- [ ] Edge cases preserved: missing TODOS.md → exit 1; no actionable items → `No actionable items.` + exit 0.
- [ ] USAGE.md + SKILL.md "Surface convention" note updated to describe the card layout and the consumer-table fork.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000076 (card render fork in suggest.sh + docs + test)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Make /CJ_suggest's ranked rows self-explanatory — carry a "what it does" line + readable effort label inline, while keeping the byte-stable consumer table.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills/CJ_suggest/scripts/suggest.sh
- skills/CJ_suggest/SKILL.md
- skills/CJ_suggest/USAGE.md

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The data is already present: every TODO heading has body prose, and `Size` already encodes effort. This is pure formatting leverage — zero new inputs, no model call at print time.
- The downstream-parser risk drove the design: `/CJ_goal_todo_fix` (todo_fix.sh:334-337) parses the table with `awk -F'|'` reading column 2 = title. Forking the render on `[ -n "$FOR_SKILL" ]` keeps the machine path byte-stable.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-03: Chose Approach A (card list for interactive, keep table for consumers) over Approach B (add columns to the single table — wraps badly) and Approach C (card list everywhere — breaking change to a second skill + its test fixture). Summary: deliver the full interactive UX win at the lowest blast radius by leaving the consumer code path literally untouched.
