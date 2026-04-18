---
name: "implement-loading-block"
type: task
workflow_type: task
id: "T000006"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
parent: "S000005"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000005"
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

## PRs

## Files

- skills/company-workflow/SKILL.md (modified)
- skills/company-workflow/WORKFLOW.md (modified)

## Insights

## Journal
