---
name: "always-on-loading"
type: user-story
id: "S000005"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "F000004"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "S000004"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) — from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) — from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) — from `templates/doc-TEST-SPEC.md`
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [ ] All child tasks have entered Phase 2+
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/personal-workflow tree` — verify hierarchy and structural completeness
3. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
4. Ensure all child tasks have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] `/personal-workflow tree` — structure verified
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] Given `$_KNOWLEDGE_DIR` is a valid directory (from S000004), skill enumerates top-level subdirectories as categories
- [ ] For each category with `.knowledge.yml { surface: always }`: all nested `*.md` files under that category are loaded into the skill's context
- [ ] Load order is deterministic: categories sorted by name, files within each category sorted by relative path
- [ ] A category with no `.knowledge.yml`, or with `surface: on-demand`, contributes zero content in this story (on-demand ships in S000006)
- [ ] A category with malformed `.knowledge.yml` triggers a one-line warning naming the file and skip; skill continues
- [ ] When `$_KNOWLEDGE_DIR` is empty (S000004 emitted the unset warning): nothing is loaded, no additional warning
- [ ] Existing `validate` command produces byte-identical output with and without any always-on categories present (zero regression)

## Todos

<!-- Actionable items for this story. -->

- [ ] Decide exact injection mechanism: how does loaded content reach Claude's context? Options: skill preamble inlines via `cat`, skill preamble lists paths for Claude to read with the Read tool, or skill emits a reserved `## Knowledge Context` section
- [ ] Decide `.knowledge.yml` parser: native bash + `grep` (tiny and no deps), or invoke `yq` if available (clean but adds a dependency)
- [ ] Define malformed-file warning text
- [ ] Add a soft size cap for total always-on bytes and decide behavior when exceeded (warn? truncate? hard fail?)
- [ ] Write Tier 1 smoke tests (structural: sections, fixture layouts)
- [ ] Write Tier 2 E2E tests (valid always-on category → content loaded; on-demand category → nothing loaded; mixed categories → only always-on loaded)
- [ ] Create fixtures under `skills/company-workflow/fixtures/`: one valid always-on category, one on-demand category, one malformed yml
- [ ] Update WORKFLOW.md with `.knowledge.yml` schema and example

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. Second vertical slice of F000004: always-on category loading. Blocked by S000004 (resolution). On-demand matching ships in S000006.
- 2026-04-17: Decomposed into tasks: T000005 (build fixtures), T000006 (Knowledge Loading block in SKILL.md + WORKFLOW.md schema docs, blocked by T000005), T000007 (Tier 1 + Tier 2 + regression tests, blocked by T000006).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter with `parent: F000004`; story-level milestones.md dropped — now only at feature level).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
