---
name: "Always-On Copilot Instructions"
type: user-story
id: "S000009_always_on_instructions"
status: active
created: "2026-04-22"
updated: "2026-04-22"
parent: "F000005_work_copilot"
repo: "claude-skills-templates"
branch: "feat/work-copilot"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/work-copilot`
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
2. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
3. Ensure all child tasks have shipped
4. Run `/ship` — creates PR
5. Run `/land-and-deploy` — merges and verifies

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `work-copilot/instructions/copilot-instructions.md` exists and, when
  installed to `<target>/.github/copilot-instructions.md`, gives Copilot
  always-on awareness of the work-item conventions (hierarchy, IDs,
  lifecycle, artifact manifest)
- [ ] The instructions file summarizes — but does not duplicate — the
  validate prompt; users still run `/validate` for actual checks
- [ ] The file is ≤ 8 KB so it fits within Copilot's always-on budget
  without crowding out repo-specific context
- [ ] Every claim in the instructions is sourced: it links back to the
  templates, manifest, or WORKFLOW.md for authority
- [ ] When a user opens Copilot chat in a repo with the bundle installed,
  asking "how do I add a work item?" yields an answer aligned with the
  personal/company workflow conventions

## Todos

- [ ] [T000010_author_instructions_file](T000010_author_instructions_file/T000010_TRACKER.md) — write the instructions file

## Log

- 2026-04-22: Created. Author the always-on copilot-instructions.md so Copilot answers work-item questions using our conventions.

## PRs

## Files

- work-copilot/instructions/copilot-instructions.md

## Insights

- `copilot-instructions.md` is always in context, which is both its strength
  (awareness) and its cost (every token competes with the user's code). Keep
  it a compact index, not an encyclopedia.

## Journal

### 2026-04-22 — decision
The instructions file points to the prompt + manifest rather than repeating
their content. Single source of truth; avoids drift the way F000003 avoided
contract.json drift.
