---
type: architecture
parent: S000008_template_delivery_and_install
feature: F000005_work_copilot
title: "Template Delivery and Install — Architecture"
version: 1
status: Draft
date: 2026-04-22
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

A cross-platform installer drops the `work-copilot/` bundle into a target
repo's `.github/` directory. The installer is a single Python script
(`scripts/copilot-deploy.py`) with subcommands `install`, `doctor`, and
`remove`. A companion manifest (`work-copilot/install-manifest.json`)
records per-file SHA256 checksums so the installer can detect drift and
skip unchanged files. `scripts/validate.sh` gets a new rule that fails when
`work-copilot/templates/` diverges from `templates/company-workflow/`.

## Architecture

```
claude-skills-templates/
  work-copilot/                          source bundle
    install-manifest.json                (generated at build, lists files + sha256)
    prompts/validate.prompt.md
    copilot-artifact-manifests.json
    templates/ (mirror)
    reference/
  scripts/
    copilot-deploy.py                    install/doctor/remove
    validate.sh                          +template-sync check

target-repo/
  .github/
    work-copilot/                        installed bundle (no prompts/ here)
    prompts/
      validate.prompt.md                 (Copilot looks here)
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `scripts/copilot-deploy.py` | claude-skills-templates | New | Python installer with install/doctor/remove |
| `work-copilot/install-manifest.json` | claude-skills-templates | New | Build-time generated file+checksum map |
| `scripts/validate.sh` | claude-skills-templates | Modified | Add template-sync check |
| `scripts/build-copilot-bundle.sh` | claude-skills-templates | New (P1) | Regenerates install-manifest.json and mirrors templates |

### Data Flow

1. User runs `python scripts/copilot-deploy.py install <target-repo>`
2. Script reads `work-copilot/install-manifest.json` to get file list
3. For each file, compute SHA256 of source + destination (if exists)
4. If destination missing: copy and record
5. If destination matches source checksum: skip (no-op)
6. If destination matches recorded-install checksum but differs from source: update
7. If destination differs from both: refuse unless `--overwrite`
8. Print summary `{installed, skipped, updated, drifted}`

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `copilot-deploy install <target> [--overwrite]` | CLI | Install bundle into `<target>/.github/` |
| `copilot-deploy doctor <target>` | CLI | Report install health |
| `copilot-deploy remove <target>` | CLI | Remove installed bundle (leaves user edits alone by default) |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| `scripts/validate.sh` | Checks catalog + filesystem | Also diffs `work-copilot/templates/` against `templates/company-workflow/` | Prevent bundle drift |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| Python 3.10+ | Tool | Available on Windows work box (verify in Phase 1) | Stdlib only — no pip installs |
| `hashlib` (stdlib) | Code | Available | For SHA256 |
| `pathlib` (stdlib) | Code | Available | Cross-platform paths |
| `argparse` (stdlib) | Code | Available | CLI parsing |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| CRLF conversion corrupts checksums (D000005 rerun) | Med | High | Open files as binary (`rb`) when hashing; document `.gitattributes` guidance |
| User has Python < 3.10 on work box | Low | High | Check in Phase 1; fallback is a PowerShell port |
| `.github/prompts/` conflicts with pre-existing user prompts | Low | Med | Doctor flags name collisions; install refuses to overwrite non-bundle files |
| Windows path-length limit (260 chars) | Low | Med | Short install paths; no deep nesting beyond `.github/work-copilot/templates/` |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Language | Python 3 stdlib | PowerShell | Python runs on Windows + macOS without separate scripts; stdlib avoids pip |
| Install target | `<target>/.github/` | `~/.github/` | Copilot workspace prompts live per-repo, not per-user |
| Drift policy | Refuse without `--overwrite` | Silent update | Protects user edits; matches `skills-deploy` behavior |
| Bundle mirror | Build-time copy from `templates/company-workflow/` | Symlink at install | Symlinks break on Windows + in archives; explicit copy is boring and portable |
| Manifest location | Inside bundle (`work-copilot/install-manifest.json`) | External file | Keeps bundle self-describing; installer can run from a zip |
