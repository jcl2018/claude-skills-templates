---
name: "implement-resolution-block"
type: task
id: "T000003"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "S000004"
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
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Draft the exact warning text (3 variants: unset/empty, path-not-found, path-is-file)
- [x] Add `## Knowledge Resolution` section to SKILL.md right after `## Path Resolution`
- [x] Implement bash block: read env, validate `-d`, expose `$_KNOWLEDGE_DIR`, emit warning on failure paths
- [x] Handle three failure modes distinctly: unset/empty, path-not-found, path-is-file (see S000004 PRD AC-2/3)
- [x] Add `## Knowledge Configuration` section to WORKFLOW.md with `AI_KNOWLEDGE_DIR` setup example + layout + `.knowledge.yml` schema
- [x] Verify warning lands on stderr (`>&2`), exit code remains 0 (no `exit 1`)
- [ ] Commit changes (user will do this)
- [ ] Hand off to T000004 for test coverage

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-04-16: Created. Implements resolution bash block in SKILL.md + docs in WORKFLOW.md for S000004 AC-1/2/3/4. No test code here — T000004 owns tests.
- 2026-04-17: Implemented. Added `## Knowledge Resolution` section to SKILL.md (bash block + behavior contract + cross-link) and `## Knowledge Configuration` section to WORKFLOW.md (setup + layout + `.knowledge.yml` schema + current status). Three distinct warning lines per failure mode (unset/empty, not-found, not-a-directory). Ready for T000004 tests.
- 2026-04-17: Committed as 6265249 (feat: T000003 AI_KNOWLEDGE_DIR resolution + WORKFLOW.md configuration docs).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Plan phase, updated during Implement. -->

- skills/company-workflow/SKILL.md (modified)
- skills/company-workflow/WORKFLOW.md (modified)

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
