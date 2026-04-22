---
name: "Author copilot-instructions.md"
type: task
id: "T000010_author_instructions_file"
status: active
created: "2026-04-22"
updated: "2026-04-22"
parent: "S000009_always_on_instructions"
repo: "claude-skills-templates"
branch: "feat/work-copilot"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/work-copilot`
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

1. Work from design doc + parent's acceptance criteria + your Todos
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR
4. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [ ] Draft `work-copilot/instructions/copilot-instructions.md` structured as: Intro, How work is tracked, How to add a work item, How to check compliance, Sources
- [ ] Keep body under 8 KB; each section under 1 KB
- [ ] Include ID regex (`[FSTD][0-9]{6}`) and phase names (Track, Implement, Ship) verbatim so Tier 1 grep tests pass
- [ ] Link to manifest + templates paths inside the bundle (relative to `.github/`)
- [ ] Add entry to `work-copilot/install-manifest.json` mapping source -> `.github/copilot-instructions.md`
- [ ] Run size check: `wc -c`

## Log

- 2026-04-22: Created. Implements S000009 acceptance criteria for the always-on instructions file.

## PRs

## Files

- work-copilot/instructions/copilot-instructions.md
- work-copilot/install-manifest.json (add entry)

## Insights

- Temptation: copy the whole WORKFLOW.md into `copilot-instructions.md`. Bad
  idea — kills the budget and creates a second source of truth. Keep this
  file a compact index with pointers.

## Journal

### 2026-04-22 — decision
Every H2 section ends with a `Source:` footer that links to the authority
(WORKFLOW.md section, manifest path, or template filename). Avoids the drift
D000007 tried to prevent in the contract.json era.
