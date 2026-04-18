---
name: "implement-matching-block"
type: task
id: "T000009"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "S000006"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000008"
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

- [ ] Add `## On-Demand Matching` section to SKILL.md after `## Knowledge Loading`
- [ ] Use shared helper (T000008) to enumerate categories with `surface: on-demand` and non-empty triggers
- [ ] Emit `## On-Demand Knowledge Candidates` block: per-category entries with category root + triggers list + markdown file paths
- [ ] Add Claude-facing instruction block specifying: tokenization rule (whitespace + punctuation; case-fold), single-word trigger = whole-word match on prompt tokens, multi-word trigger = case-insensitive phrase at token boundaries, match on any trigger, load all matched categories
- [ ] Specify the match log format: `[knowledge] matched: <cat> via <trigger>; <cat2> via <trigger>` — one line, stderr
- [ ] Extend fixture `valid-knowledge-dir/`: add any on-demand variants the current fixture doesn't cover (phrase-only category, empty-triggers already covered)
- [ ] Update WORKFLOW.md: on-demand worked example, trigger-authoring guidance, security callout (knowledge file content is trusted by Claude via Read)
- [ ] Document the "latest user message only, not prior turns" scope decision

## Log

- 2026-04-16: Created. Implements SKILL.md On-Demand Matching section + instruction block, using shared helper from T000008. Extends fixtures + WORKFLOW.md. Tests in T000010.
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).

## PRs

## Files

- skills/company-workflow/SKILL.md (modified)
- skills/company-workflow/WORKFLOW.md (modified)
- skills/company-workflow/fixtures/valid-knowledge-dir/ (possibly extended)

## Insights

## Journal
