---
name: "Implement validate.prompt.md + manifest"
type: task
id: "T000008_implement_prompt_and_validator"
status: active
created: "2026-04-22"
updated: "2026-04-22"
parent: "S000007_copilot_prompt_packaging"
repo: "claude-skills-templates"
branch: "feat/work-copilot"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/work-copilot`
   (shared with the feature PR; this task doesn't need its own branch)
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

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
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

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [x] Write `work-copilot/prompts/validate.prompt.md` with YAML frontmatter (`mode`, `description`) and prose instructions
- [x] Copy `skills/company-workflow/company-artifact-manifests.json` to `work-copilot/copilot-artifact-manifests.json` and update description + filename conventions
- [x] Mirror `templates/company-workflow/` -> `work-copilot/templates/` (bundled)
- [x] Write fixtures: one known-good work item dir and one with an artifact removed, for manual E2E diff vs `/company-workflow check`
- [ ] Verify prompt runs on the work machine in VS Code Copilot Chat (E1 test) — **blocked on S000008 installer**

## Log

- 2026-04-22: Created. Implements S000007 acceptance criteria for the Copilot prompt packaging story.
- 2026-04-22: Bundle implemented — 23 files, 96 KB total. `validate.prompt.md` (7 KB), manifest (2 KB), 16 mirrored templates, 4 fixture files. Local source on `feat/work-copilot`.

## PRs

## Files

- work-copilot/prompts/validate.prompt.md
- work-copilot/copilot-artifact-manifests.json
- work-copilot/templates/ (mirrored files)
- work-copilot/fixtures/ (E2E diff fixtures)

## Insights

- Writing the prompt is mostly translation — the company SKILL.md is already
  prose instructions that a language model can execute. Main adaptation:
  replace references to `/company-workflow check` with `/validate`, and
  replace "skill assets path resolution" with "bundle path resolution
  inside `.github/work-copilot/`".
- The 2 KB prompt budget estimated in S000007's ARCHITECTURE risk table was
  too tight. Final prompt is 7 KB because the validator logic (File Mode +
  Directory Mode + output contract + anti-hallucination rules) doesn't
  compress well without losing fidelity. 7 KB is still fine for Copilot's
  context window. Updating the risk assessment accordingly.
- The anti-hallucination rule ("read the file, do NOT recall") is explicit
  at the top of the prompt. Every time the prompt references a bundle path,
  it's named with its relative path so the model can Read it deterministically.

## Journal

### 2026-04-22 — decision
Fixtures live in `work-copilot/fixtures/` not at the repo root, so they
ship inside the bundle and are installable alongside the prompt. Users
can run `/validate work-copilot/fixtures/good-feature/` on their work
machine as a self-test.
