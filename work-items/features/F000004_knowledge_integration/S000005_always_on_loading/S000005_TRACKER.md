---
name: "always-on-loading"
type: user-story
workflow_type: user-story
id: "S000005"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "S000004"
---

## Lifecycle

### Phase 1: Track
- [x] Story scoped (acceptance criteria defined)
- [x] Working branch created (`branch` field populated)
- [x] Tasks broken down (child task items created if needed)

### Phase 2: Implement
- [ ] Core implementation committed (>=1 commit SHA in Log)
- [ ] Acceptance criteria met
- [ ] All P0 cases in TEST-SPEC.md marked Pass; remaining cases marked Pending/Skip with reason
- [ ] Files section updated with all changed files

### Phase 3: Review
- [ ] Code review requested (reviewer noted)
- [ ] Review feedback captured (suggestions + resolutions in Journal)
- [ ] All review suggestions resolved or marked won't-fix

### Phase 4: Ship
- [ ] Linux branch build passes
- [ ] Regression tests pass
- [ ] Code review completed (reviewer noted in Journal)
- [ ] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

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

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
