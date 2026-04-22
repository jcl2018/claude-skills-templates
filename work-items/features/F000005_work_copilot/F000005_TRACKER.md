---
name: "work-copilot"
type: feature
id: "F000005_work_copilot"
status: active
created: "2026-04-22"
updated: "2026-04-22"
repo: "claude-skills-templates"
branch: "feat/work-copilot"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/work-copilot`
3. Scaffold work item directory and TRACKER.md
4. Scaffold `milestones.md` (delivery timeline) — from `templates/doc-milestones.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (PRD, ARCHITECTURE, TEST-SPEC) lives in child stories

**Gates:**
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] Milestones scaffolded
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories/tasks drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all children pass validation
2. Ensure all child stories have shipped
3. Run `/ship` — creates feature PR, includes pre-landing code review
4. Run `/land-and-deploy` — merges and verifies

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `work-copilot/` directory contains a portable bundle that mirrors the
  intent of `skills/company-workflow/`: templates, artifact manifest,
  validation instructions, reference guides
- [ ] The bundle installs into a target repo's `.github/` directory as a
  `copilot-instructions.md` file plus `.prompt.md` prompt files
- [ ] A GitHub Copilot user in the target repo can invoke the equivalent of
  `/company-workflow check` via a Copilot prompt/chat mode and get
  [PASS]/[MISSING]/[DRIFT] output on work items
- [ ] Installation works on a Windows work machine with Copilot (matches the
  "work machine" delivery constraint)
- [ ] Zero dependency on Claude Code, gstack, or any Anthropic-specific
  tooling — the bundle is Copilot-native
- [ ] `skills-deploy install work-copilot <target-repo>` (or equivalent)
  copies the bundle into `<target-repo>/.github/` idempotently

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] [S000007_copilot_prompt_packaging](S000007_copilot_prompt_packaging/S000007_TRACKER.md) — port the validator as a Copilot prompt file
- [ ] [S000008_template_delivery_and_install](S000008_template_delivery_and_install/S000008_TRACKER.md) — deliver templates + install into target repo's `.github/`
- [ ] [S000009_always_on_instructions](S000009_always_on_instructions/S000009_TRACKER.md) — author `copilot-instructions.md` for always-on workflow context

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-22: Created. Port company-workflow semantics (templates + validator + install) to GitHub Copilot so it can run on the user's work machine without Claude Code.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- work-items/features/F000005_work_copilot/F000005_DESIGN.md  # feature-level plan
- work-copilot/                           # new bundle root
- work-copilot/prompts/                   # .prompt.md files
- work-copilot/instructions/              # copilot-instructions.md source
- work-copilot/templates/                 # mirrored from templates/company-workflow/
- work-copilot/copilot-artifact-manifests.json
- scripts/copilot-deploy.py               # Python 3 stdlib installer (install/doctor/remove)
- scripts/validate.sh                     # add template-sync check

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Copilot's `.prompt.md` files are the closest analog to Claude Code slash
  commands; `.github/copilot-instructions.md` is the closest analog to an
  always-on SKILL.md.
- Copilot has no shell execution at prompt time: the validator logic must be
  expressible as instructions to the model, not a bash script. The company
  skill's SKILL.md is already mostly prose + checklists, so port cost is low.
- Work machine is Windows with Copilot; installer must avoid bash-only
  assumptions. A cross-platform path (Python or PowerShell) may be required.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-04-22 — decision
Target GitHub Copilot via `.github/copilot-instructions.md` (always-on) plus
`.github/prompts/*.prompt.md` (slash-command equivalents). Rejected
`.chatmode.md`-only because chat modes require the user to switch modes
manually; always-on + prompts keeps parity with the Claude Code UX.

### 2026-04-22 — decision
Feature-level plan captured in [F000005_DESIGN.md](F000005_DESIGN.md)
(in lieu of a full `/office-hours` run — the scope was already well-defined
by the three child PRDs, so a consolidated design doc is the lighter-weight
artifact). DESIGN.md enumerates the 7 big decisions, risks, sequencing, and
definition of done.
