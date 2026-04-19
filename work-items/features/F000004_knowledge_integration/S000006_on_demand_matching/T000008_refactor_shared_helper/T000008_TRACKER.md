---
name: "refactor-shared-helper"
type: task
id: "T000008"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "S000006"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [ ] Identify duplicated logic in T000006's Knowledge Loading block: yml parsing, category enumeration, md file listing
- [ ] Extract into a single named bash function or a separate section in SKILL.md (e.g., `## Knowledge Helpers`) that both Always-On and On-Demand blocks source
- [ ] Keep the supported yml subset stable: `surface`, `triggers`; flat keys only
- [ ] Preserve deterministic output: categories lex-sorted; files within each lex-sorted
- [ ] Preserve malformed-yml behavior: one warning naming the file, skip category, continue
- [ ] Verify T000006's Tier 1 + Tier 2 tests still pass after refactor (no behavior change for always-on)
- [ ] Document helper contract in WORKFLOW.md (at a level that lets a reader understand, not an implementation dump)

## Log

- 2026-04-16: Created. Extracts shared yml parser + category/file enumeration from T000006's impl so T000009 (on-demand matching) can reuse. Pure refactor — behavior-preserving.
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).

## PRs

## Files

- skills/company-workflow/SKILL.md (modified)
- skills/company-workflow/WORKFLOW.md (modified, minor)

## Insights

## Journal
