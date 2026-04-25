---
name: "Template Delivery and Install"
type: user-story
id: "S000008_template_delivery_and_install"
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
2. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
3. Ensure all child tasks have shipped
4. Run `/ship` — creates PR
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

- [ ] An installer (script or scripts subcommand) copies the `work-copilot/`
  bundle into any target repo's `.github/` directory
- [ ] Installation is idempotent: running twice doesn't duplicate or corrupt
  files; drifted user edits are detected and require `--overwrite`
- [ ] Installer runs on Windows (PowerShell or Python) without requiring bash,
  jq, or other Unix-only tools
- [ ] A doctor-style subcommand reports install health: missing files,
  checksum mismatches, orphaned files
- [ ] `work-copilot/templates/` stays in sync with `templates/company-workflow/`
  via a verification check in `scripts/validate.sh`

## Todos

- [ ] [T000009_implement_install_script](T000009_implement_install_script/T000009_TRACKER.md) — author the cross-platform installer

## Log

- 2026-04-22: Created. Deliver the work-copilot bundle into a target repo's `.github/` so the engineer can use Copilot on their Windows work machine.

## PRs

## Files

- work-copilot/                           (source bundle)
- scripts/copilot-deploy.sh               (or extend skills-deploy.sh)
- scripts/copilot-deploy.ps1              (Windows variant, if needed)
- scripts/validate.sh                     (add sync check)

## Insights

- Windows work machine is a hard constraint. `skills-deploy.sh` uses bash and
  jq today (D000005 was about CRLF handling), so we can't reuse it unmodified
  on a Windows box unless the user has Git Bash. A Python installer sidesteps
  that.

## Journal

### 2026-04-22 — decision
Installer target is `<repo>/.github/`, not `~/.github/`. Copilot reads
workspace-scoped prompts from `.github/prompts/`, so install must be
per-repo. This is a departure from `skills-deploy`'s global `~/.claude/`
install — flag clearly in ARCHITECTURE.
