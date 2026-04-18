---
name: "env-var-resolution"
type: user-story
workflow_type: user-story
id: "S000004"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
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

- [ ] `company-workflow` skill reads `AI_KNOWLEDGE_DIR` on every invocation and exposes the resolved path as a skill-internal variable for downstream code
- [ ] When `AI_KNOWLEDGE_DIR` is unset OR empty: skill emits exactly one warning line on stderr naming the variable and pointing to docs, exit code remains 0
- [ ] When `AI_KNOWLEDGE_DIR` is set but the path does not exist or is not a directory: skill emits a warning mentioning the configured path, exit code remains 0
- [ ] When `AI_KNOWLEDGE_DIR` is set and points to a valid directory: no warning emitted
- [ ] No knowledge files are read or loaded by this story (resolution only — loading lands in S00000X always-on and on-demand stories)
- [ ] Existing `validate` command produces byte-identical output with and without `AI_KNOWLEDGE_DIR` set (zero regression)

## Todos

<!-- Actionable items for this story. -->

- [ ] Draft the exact warning text (one line, ≤100 chars, names the variable, points to docs)
- [ ] Add resolution block to SKILL.md Path Resolution section
- [ ] Decide where the warning is emitted (skill preamble? every command? only when knowledge is expected to be consulted?)
- [ ] Write Tier 1 smoke test (SKILL.md contains the resolution block; warning text present)
- [ ] Write Tier 2 E2E test (env var unset / set-valid / set-invalid scenarios)
- [ ] Update WORKFLOW.md or SKILL.md docs with the `AI_KNOWLEDGE_DIR` setup instructions
- [ ] Confirm no regression against existing fixtures (`fixtures/valid-feature-dir/`, etc.)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. First vertical slice of F000004: env var resolution + missing-folder warning. No knowledge loading in this story.
- 2026-04-17: Decomposed into tasks: T000003 (resolution + warning impl in SKILL.md + WORKFLOW.md) and T000004 (Tier 1 + Tier 2 + regression tests). T000004 blocked by T000003.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills/company-workflow/SKILL.md (modified — added `## Knowledge Resolution` section in T000003)
- skills/company-workflow/WORKFLOW.md (modified — added `## Knowledge Configuration` section in T000003)

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
