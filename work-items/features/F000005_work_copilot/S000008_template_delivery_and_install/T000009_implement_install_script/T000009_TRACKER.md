---
name: "Implement copilot-deploy.py installer"
type: task
id: "T000009_implement_install_script"
status: active
created: "2026-04-22"
updated: "2026-04-22"
parent: "S000008_template_delivery_and_install"
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

- [ ] Verify Python 3.10+ is on the work machine (if not, switch plan to PowerShell)
- [ ] Implement `scripts/copilot-deploy.py` with `install`, `doctor`, `remove` subcommands (stdlib only)
- [ ] Generate `work-copilot/install-manifest.json` at build time (new `scripts/build-copilot-bundle.sh` or inline in deploy)
- [ ] Binary-mode file reads for SHA256 (prevent D000005 CRLF rerun)
- [ ] Add template-sync check to `scripts/validate.sh`
- [ ] Add Tier 1 smoke tests (S1–S5 from TEST-SPEC)
- [ ] Dry-run on macOS, then run on Windows work box

## Log

- 2026-04-22: Created. Implements S000008 acceptance criteria for delivery + installer.

## PRs

## Files

- scripts/copilot-deploy.py
- scripts/build-copilot-bundle.sh (or equivalent manifest generator)
- scripts/validate.sh (modified)
- work-copilot/install-manifest.json (generated)

## Insights

- Python stdlib covers everything we need: `pathlib`, `hashlib`, `argparse`,
  `json`, `shutil`. No pip install. This matters because work machines often
  restrict `pip` behind corporate proxies.

## Journal

### 2026-04-22 — decision
The installer is the source of truth for the install-manifest format. If we
ever move to PowerShell, we port the spec, not re-derive it. Format: JSON
with one entry per file: `{src, dest, sha256}`.
