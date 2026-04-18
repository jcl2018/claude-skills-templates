---
name: "implement-resolution-block"
type: task
workflow_type: task
id: "T000003"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
parent: "S000004"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Scope understood from parent work item (parent tracker read)
- [x] Working branch created (`branch` field populated)
- [x] Files section has >=1 entry

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
