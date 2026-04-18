---
name: "on-demand-matching"
type: user-story
workflow_type: user-story
id: "S000006"
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

- [ ] For each category with `.knowledge.yml { surface: on-demand }`, the skill makes its declared `triggers` list available to Claude along with the category root path
- [ ] Claude matches the user's current prompt against every on-demand category's triggers (case-insensitive whole-word match on prompt tokens; quoted multi-word trigger phrases matched as a unit)
- [ ] When one or more categories match, Claude reads every `*.md` file under each matched category (recursive, same enumeration rules as S000005)
- [ ] When multiple categories match, content from all matched categories is loaded
- [ ] Categories with empty `triggers: []` never match; they are effectively dark until the user adds triggers
- [ ] A `surface: always` category is never considered by this matching logic (it's already loaded by S000005)
- [ ] When `$_KNOWLEDGE_DIR` is empty: no matching, no loading, no additional warning
- [ ] Existing `validate` command produces byte-identical output with and without on-demand categories present (zero regression)

## Todos

<!-- Actionable items for this story. -->

- [ ] Decide who tokenizes the prompt: the skill emits a "matching spec" and Claude does the match; or the skill emits triggers and Claude handles both tokenization and match. (Leaning: Claude does both — it already has the prompt in context and bash can't see it.)
- [ ] Draft the exact instruction text in SKILL.md: "For each on-demand category listed below, check if any declared trigger matches the user's request; if so, Read all listed paths before answering"
- [ ] Decide diagnostic surfacing: should Claude log which triggers matched, to help users tune? (Proposal: yes, one line per matched category.)
- [ ] Disambiguate "prompt tokens" — does that include prior turns in the conversation or only the latest user message? (Proposal: only the latest user message to avoid runaway loading.)
- [ ] Decide behavior when a trigger is a single very-common word like "the" or "code". (Proposal: no skill-side filtering; user's responsibility to pick specific triggers.)
- [ ] Write Tier 1 smoke tests (structure: instruction text present, on-demand categories emitted)
- [ ] Write Tier 2 E2E tests (prompt contains trigger → category loaded; no trigger → not loaded; multi-match → both loaded)
- [ ] Extend fixture `valid-knowledge-dir/` with on-demand categories covering single-word and phrase triggers
- [ ] Update WORKFLOW.md with on-demand example and trigger-authoring guidance

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. Third vertical slice of F000004: on-demand trigger matching + loading. Blocked by S000004 (resolution); parallel to S000005 (always-on).
- 2026-04-17: Decomposed into tasks: T000008 (extract shared helper from T000006's block), T000009 (On-Demand Matching block + extend fixtures + WORKFLOW.md docs, blocked by T000008), T000010 (Tier 1 + Tier 2 + regression tests, blocked by T000009).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
