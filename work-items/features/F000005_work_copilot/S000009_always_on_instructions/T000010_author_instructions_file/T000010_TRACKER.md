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
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [x] Draft `work-copilot/instructions/copilot-instructions.md` structured as: Intro, How work is tracked, How to add a work item, How work progresses, How to check compliance, Sources of truth
- [x] Keep body under 8 KB — final size 5061 bytes (5 KB). "Each section under 1 KB" bound slightly exceeded by the two operational sections (1132 and 1073 bytes); tradeoff accepted since those are the highest-signal sections and the total is well under budget.
- [x] Include ID regex (`[FSTDR][0-9]{6}`) and phase names (Track, Implement, Ship) verbatim so Tier 1 grep tests pass — regex widened from the todo's `[FSTD]` to `[FSTDR]` to cover review items
- [x] Link to manifest + templates paths inside the bundle (relative to `.github/`)
- [x] ~~Add entry to `work-copilot/install-manifest.json`~~ — **obsolete per T000009 implementation**: there is no source-side install-manifest. The T000009 installer walks `work-copilot/` at install time and maps `instructions/copilot-instructions.md` → `.github/copilot-instructions.md` via its `map_dest` logic. Verified: a fresh install picks up the new file and doctor passes.
- [x] Run size check: `wc -c` → 5061 bytes

## Log

- 2026-04-22: Created. Implements S000009 acceptance criteria for the always-on instructions file.
- 2026-04-22: Drafted `work-copilot/instructions/copilot-instructions.md` (5061 bytes, 6 H2 sections, each with a `Source:` footer). Every claim points back to the template, manifest, validate.prompt.md, or fixtures — nothing is stated without a source. Installer picks it up automatically via `map_dest` (no manifest edit needed).

## PRs

## Files

- work-copilot/instructions/copilot-instructions.md (new, 5061 bytes)

## Insights

- Temptation: copy the whole WORKFLOW.md into `copilot-instructions.md`. Bad
  idea — kills the budget and creates a second source of truth. Keep this
  file a compact index with pointers.
- The "source footer per section" discipline is cheap to enforce and pays
  for itself on Copilot's end: when the model has a claim and its source in
  the same paragraph, it's much more likely to cite the source (e.g.
  "per `.github/work-copilot/templates/tracker-task.md`") instead of
  paraphrasing the rule and drifting.
- The todo that said to edit `work-copilot/install-manifest.json` was
  written before T000009 landed. T000009 chose an install-time manifest
  rather than a source-side one, so there's nothing to edit — the installer
  already maps `work-copilot/instructions/*` → `.github/*`. Task trackers
  written before their blocker resolves benefit from a "last check" pass
  like this.

## Journal

### 2026-04-22 — decision
Every H2 section ends with a `Source:` footer that links to the authority
(WORKFLOW.md section, manifest path, or template filename). Avoids the drift
D000007 tried to prevent in the contract.json era.
