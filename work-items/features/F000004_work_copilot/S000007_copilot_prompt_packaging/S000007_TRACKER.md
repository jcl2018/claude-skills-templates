---
name: "Copilot Prompt Packaging"
type: user-story
id: "S000007_copilot_prompt_packaging"
status: active
created: "2026-04-22"
updated: "2026-04-22"
parent: "F000004_work_copilot"
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
   → should show PASS for template, lifecycle, traceability badges
2. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
3. Ensure all child tasks have shipped
4. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
5. Run `/land-and-deploy` — merges PR and verifies deployment

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

- [ ] `work-copilot/prompts/validate.prompt.md` exists and, when invoked in
  GitHub Copilot chat, performs the equivalent of `/company-workflow check`
- [ ] The prompt reads `copilot-artifact-manifests.json` (delivered alongside)
  to decide which artifacts are required per work-item type
- [ ] Output format matches company-workflow: `[PASS]`, `[MISSING]`, `[DRIFT]`
  one line per artifact
- [ ] Prompt works in both file mode (single tracker) and directory mode
  (whole work item)
- [ ] No external tool calls required — pure prompt-based validation using
  Copilot's native file-read capability

## Todos

- [ ] [T000008_implement_prompt_and_validator](T000008_implement_prompt_and_validator/T000008_TRACKER.md) — author the `.prompt.md` file and manifest

## Log

- 2026-04-22: Created. Port the company-workflow validator UX into a Copilot `.prompt.md` file that runs without shell tools.

## PRs

## Files

- work-copilot/prompts/validate.prompt.md
- work-copilot/copilot-artifact-manifests.json

## Insights

- Copilot `.prompt.md` files are markdown with YAML frontmatter that Copilot
  loads on `/promptname`; they can reference `${workspaceFolder}` and
  attachments. The validator logic translates cleanly because it's already
  prose instructions in the Claude skill.

## Journal

### 2026-04-22 — decision
Deliver as a single `.prompt.md` per validator mode rather than one prompt
file per work-item type. Matches the "one unified validate command" decision
in F000003.
