---
name: "implement-matching-block"
type: task
workflow_type: task
id: "T000009"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
parent: "S000006"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000008"
---

## Lifecycle

### Phase 1: Track
- [ ] Scope understood from parent work item (parent tracker read)
- [ ] Working branch created (`branch` field populated)
- [ ] Files section has >=1 entry

### Phase 2: Implement
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] All test cases in test-plan.md marked Pass
- [ ] Files section updated with all changed files
- [ ] Todos section reflects remaining work (no stale items)

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

## PRs

## Files

- skills/company-workflow/SKILL.md (modified)
- skills/company-workflow/WORKFLOW.md (modified)
- skills/company-workflow/fixtures/valid-knowledge-dir/ (possibly extended)

## Insights

## Journal
