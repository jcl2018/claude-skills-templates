---
type: test-spec
parent: S000008_template_delivery_and_install
feature: F000004_work_copilot
title: "Template Delivery and Install — Test Specification"
version: 1
status: Draft
date: 2026-04-22
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Scope: ENTIRE user story. -->

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Fresh install populates `.github/` | AC-1 | clean target repo | `copilot-deploy install <repo>` | `.github/work-copilot/` and `.github/prompts/validate.prompt.md` exist; exit 0 | P0 | Integration |
| 2 | core | Windows install without bash | AC-2 | Windows box with Python 3.10 | Run same command from PowerShell | Completes with no bash/jq calls; files have correct byte content | P0 | E2E |
| 3 | core | Idempotent re-install | AC-3 | install already ran | Run install again | `installed=0, skipped=N, updated=0`; exit 0 | P0 | Integration |
| 4 | core | Drift detection | AC-4 | user edited an installed file | Run install without `--overwrite` | `[DRIFT] <file>`; exit 1 | P0 | Integration |
| 5 | core | Drift overwrite | AC-4 | user edited an installed file | Run install `--overwrite` | File replaced; warning printed; exit 0 | P0 | Integration |
| 6 | core | Doctor on clean install | AC-5 | clean install | `copilot-deploy doctor <repo>` | Zero issues; exit 0 | P0 | Integration |
| 7 | core | Doctor on missing file | AC-5 | user deleted a bundle file | `copilot-deploy doctor <repo>` | `[MISSING] <file>`; exit 1 | P0 | Integration |
| 8 | core | Doctor on orphan file | AC-5 | bundle removed a file since last install | `copilot-deploy doctor <repo>` | `[ORPHAN] <file>`; exit 1 | P0 | Integration |
| 9 | integration | validate.sh fails on template drift | AC-6 | `templates/company-workflow/tracker-feature.md` edited, bundle unchanged | `./scripts/validate.sh` | Fails with drift message | P1 | Integration |
| 10 | observability | Summary output | AC-8 | any install | inspect stdout | Last line matches `installed=N skipped=M updated=K drifted=0` | P1 | Integration |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | Installer script is executable | Installable | `python scripts/copilot-deploy.py --help` exits 0 |
| S2 | core | `install-manifest.json` is valid JSON | Manifest not corrupt | `python -c "import json; json.load(open('work-copilot/install-manifest.json'))"` |
| S3 | core | Manifest covers every bundle file | No orphan files | Walk `work-copilot/`, compare against manifest keys |
| S4 | core | Every manifest checksum matches on-disk content | No stale checksums | Recompute SHA256, diff against manifest values |
| S5 | integration | Template mirror is in sync | No drift at HEAD | `diff -rq templates/company-workflow/ work-copilot/templates/` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps | Expected Outcome | Rubric |
|---|-----|----------|-------|-----------------|--------|
| E1 | core | Install on real work machine | 1. Clone bundle repo on Windows box. 2. Run `python scripts/copilot-deploy.py install C:\work\target-repo`. 3. Open target repo in VS Code. 4. Type `/validate` in Copilot chat. | Prompt is discoverable and runs | Pass if the prompt appears in Copilot's slash menu and executes |
| E2 | core | Round-trip update | Edit a template; rebuild bundle manifest; re-run install; verify target picks up the edit | Destination file updated without `--overwrite` if destination matched prior-install checksum | Pass if "updated" count is 1 |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Symlinked target repos | Not in use | Install behavior on symlinks untested |
| Filesystems without atime/sha support | Only Windows NTFS + macOS APFS in use | Exotic FS not covered |
| Network-mounted repos | Unlikely for the user's workflow | Slow install on NFS |
