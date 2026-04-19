---
name: "implement-loading-block"
type: task
id: "T000006"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "S000005"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000005"
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

- [ ] Add `## Knowledge Loading` section to SKILL.md after `## Knowledge Resolution`
- [ ] Bash block: enumerate top-level subdirs of `$_KNOWLEDGE_DIR`, parse each `.knowledge.yml` (bash `grep`-based parser for the supported subset)
- [ ] For each category with `surface: always`: recursively list `*.md` files, lex-sort by relative path
- [ ] Emit deterministic `## Always-On Knowledge` block listing absolute paths (one per line)
- [ ] Add Claude-facing instruction block: "Before answering, Read every path listed under Always-On Knowledge"
- [ ] Handle malformed yml: one warning line naming the file + reason; skip the category; continue
- [ ] Treat missing `.knowledge.yml` as on-demand+empty-triggers (silent, no warning)
- [ ] Soft-warn when total always-on bytes exceed 50 KB
- [ ] Update WORKFLOW.md: add `.knowledge.yml` schema (`surface`, `triggers`) with worked example; note malformed-file behavior
- [ ] Document the supported bash-parser subset in WORKFLOW.md (flat keys only, list via `[a, b]` or `- a\n- b`)

## Log

- 2026-04-16: Created. Implements SKILL.md Knowledge Loading section + WORKFLOW.md schema docs for S000005. Fixtures from T000005 drive development. Tests live in T000007.
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).

## PRs

## Files

- skills/company-workflow/SKILL.md (modified)
- skills/company-workflow/WORKFLOW.md (modified)

## Insights

## Journal
