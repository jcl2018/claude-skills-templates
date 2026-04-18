---
name: "refactor-shared-helper"
type: task
workflow_type: task
id: "T000008"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
parent: "S000006"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
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

- [ ] Identify duplicated logic in T000006's Knowledge Loading block: yml parsing, category enumeration, md file listing
- [ ] Extract into a single named bash function or a separate section in SKILL.md (e.g., `## Knowledge Helpers`) that both Always-On and On-Demand blocks source
- [ ] Keep the supported yml subset stable: `surface`, `triggers`; flat keys only
- [ ] Preserve deterministic output: categories lex-sorted; files within each lex-sorted
- [ ] Preserve malformed-yml behavior: one warning naming the file, skip category, continue
- [ ] Verify T000006's Tier 1 + Tier 2 tests still pass after refactor (no behavior change for always-on)
- [ ] Document helper contract in WORKFLOW.md (at a level that lets a reader understand, not an implementation dump)

## Log

- 2026-04-16: Created. Extracts shared yml parser + category/file enumeration from T000006's impl so T000009 (on-demand matching) can reuse. Pure refactor — behavior-preserving.

## PRs

## Files

- skills/company-workflow/SKILL.md (modified)
- skills/company-workflow/WORKFLOW.md (modified, minor)

## Insights

## Journal
