---
name: "build-fixtures"
type: task
id: "T000005"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "S000005"
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

- [ ] Create `skills/company-workflow/fixtures/valid-knowledge-dir/` root
- [ ] Subdir `coding/` — `surface: always`, triggers: []; contains `style.md` (with canary) and `cpp/errors.md` (nested file with canary)
- [ ] Subdir `runbooks/` — `surface: on-demand`, triggers: [pricing, "pricing engine"]; contains `pricing.md` (with canary)
- [ ] Subdir `notes/` — NO `.knowledge.yml`; contains `draft.md` (used to verify missing-yml default behavior)
- [ ] Subdir `broken/` — malformed `.knowledge.yml` (e.g., invalid syntax or wrong keys); contains `any.md`
- [ ] Subdir `empty-triggers/` — `surface: on-demand`, triggers: []; contains `nevermatched.md`
- [ ] Document each canary string at the top of each md file for tests to match (stable identifiers)
- [ ] Add fixture README explaining the intent of each category (helps reviewers)

## Log

- 2026-04-16: Created. Builds `valid-knowledge-dir/` fixture with mixed categories. Used by T000006, T000007, and eventually T000009/T000010.
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).

## PRs

## Files

- skills/company-workflow/fixtures/valid-knowledge-dir/ (new directory tree)

## Insights

## Journal
