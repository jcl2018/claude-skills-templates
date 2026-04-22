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

- [ ] Verify Python 3.10+ is on the work machine (if not, switch plan to PowerShell) — **blocked on Windows box access**
- [x] Implement `scripts/copilot-deploy.py` with `install`, `doctor`, `remove` subcommands (stdlib only)
- [x] Generate `install-manifest.json` inline during install (written to target, not the source bundle — simpler than a separate build step, kept the spec in the installer per the Journal decision)
- [x] Binary-mode file reads for SHA256 (prevent D000005 CRLF rerun)
- [x] Add template-sync check to `scripts/validate.sh`
- [x] Add Tier 1 smoke tests — T1–T7 and T10 from the test-plan pass on macOS
- [ ] Dry-run on macOS, then run on Windows work box — **blocked on Windows box access** (E1 E2E test)

## Log

- 2026-04-22: Created. Implements S000008 acceptance criteria for delivery + installer.
- 2026-04-22: Installer implemented. 3 subcommands (install/doctor/remove), Python 3 stdlib only, binary-mode SHA256, install-manifest generated inline at install time. Tier 1 smoke tests T1–T7 and T10 all pass on macOS against a temp target directory. validate.sh gained Error check 10 (work-copilot/templates sync with templates/company-workflow).
- 2026-04-22: Dropped the separate `scripts/build-copilot-bundle.sh` idea — the installer walks the source bundle on each install and generates the manifest itself. No build step, no source-side manifest to commit.

## PRs

## Files

- scripts/copilot-deploy.py (new)
- scripts/validate.sh (added work-copilot template sync check)

## Insights

- Python stdlib covers everything we need: `pathlib`, `hashlib`, `argparse`,
  `json`, `shutil`. No pip install. This matters because work machines often
  restrict `pip` behind corporate proxies.
- Keeping the install-manifest out of the source bundle was the right call.
  If it lived in the repo it would churn on every unrelated template change
  (because hashes update), and doctor-on-target would work identically
  either way (it only needs a manifest *next to the installed files*).
- The install logic has three distinguishable states for an existing file:
  SKIP (identical to source), UPDATE (target matches prior manifest, source
  newer — safe to update), DRIFT (target doesn't match prior manifest —
  user edit). Only DRIFT requires `--overwrite`. This is a richer contract
  than the S000008 PRD asked for, but it costs almost nothing and makes
  "skill updated upstream" a one-step non-interactive update.

## Journal

### 2026-04-22 — decision
The installer is the source of truth for the install-manifest format. If we
ever move to PowerShell, we port the spec, not re-derive it. Format: JSON
with one entry per file: `{src, dest, sha256}`.
