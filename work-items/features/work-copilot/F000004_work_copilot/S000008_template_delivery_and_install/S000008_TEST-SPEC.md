---
type: test-spec
parent: S000008_template_delivery_and_install
feature: F000004_work_copilot
title: "Template Delivery and Install — Test Specification"
version: 2
status: Draft
date: 2026-04-22
updated: 2026-05-05
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Migrated from Test Matrix + Test Tiers shape to Smoke + E2E on 2026-05-05.
     Original 10 Test Matrix rows + 5 smoke + 2 E2E consolidated. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | Installer script is executable + manifest is valid JSON | Installer can run; manifest not corrupt | `python scripts/copilot-deploy.py --help` exits 0; `python -c "import json; json.load(open('work-copilot/install-manifest.json'))"` |
| S2 | core | AC-3, AC-5 | Manifest covers every bundle file with matching SHA256 | No orphan files; no stale checksums | Walk `work-copilot/`, compare against manifest keys; recompute SHA256, diff against manifest values |
| S3 | integration | AC-6 | Template mirror is in sync at HEAD | No drift between upstream `deprecated/company-workflow/templates/` and bundle copy | `diff -rq deprecated/company-workflow/templates/ work-copilot/templates/` returns no diffs |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-8 | Fresh install on Windows + Copilot discovery | 1. Clone bundle on Windows box. 2. `python scripts/copilot-deploy.py install C:\work\target-repo`. 3. Open target in VS Code. 4. Type `/validate` in Copilot chat | `.github/work-copilot/` and `.github/prompts/validate.prompt.md` exist; install summary shows `installed=N skipped=0 updated=0 drifted=0`; prompt appears in Copilot's slash menu and runs | Pass if all three of: files installed, summary correct, prompt discoverable |
| E2 | core | AC-3, AC-8 | Idempotent re-install + round-trip update | After E1: re-run install with no changes; then edit a template upstream, rebuild manifest, re-run install on the same target | Re-install: `installed=0, skipped=N, updated=0`. Round-trip: `updated=1` for the edited file; destination matched prior-install checksum so no `--overwrite` needed | Pass if both summaries match |
| E3 | core | AC-4, AC-5 | Drift detection + overwrite + doctor diagnostics | After E1: edit an installed file in target; run `install` (no flag), then `install --overwrite`, then doctor. Then delete an installed file and run doctor; remove a file from upstream bundle (orphan) and run doctor | Without --overwrite: `[DRIFT] <file>`; exit 1. With --overwrite: file replaced; warning printed; exit 0. Doctor on deleted: `[MISSING] <file>`; exit 1. Doctor on orphan: `[ORPHAN] <file>`; exit 1 | Pass if all 4 sub-cases produce the expected exit code + flag |
| E4 | integration | AC-6 | validate.sh fails on template drift | Edit `deprecated/company-workflow/templates/tracker-feature.md` upstream; do not rebuild bundle; run `./scripts/validate.sh` | Fails with drift message naming the file | Pass = non-zero exit with the drift message |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Symlinked target repos | Not in use | Install behavior on symlinks untested |
| Filesystems without atime/sha support | Only Windows NTFS + macOS APFS in use | Exotic FS not covered |
| Network-mounted repos | Unlikely for the user's workflow | Slow install on NFS |
