---
type: test-plan
parent: T000009_implement_install_script
title: "Implement copilot-deploy.py installer — Test Plan"
date: 2026-04-22
author: chjiang
status: Draft
---

<!-- Scope: ONE task. -->

## Scope

This task produces `scripts/copilot-deploy.py` and the accompanying
`work-copilot/install-manifest.json` generator. Scope: install / doctor /
remove behavior and drift semantics.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Fresh install on clean target | `mkdir /tmp/target && python scripts/copilot-deploy.py install /tmp/target` | `/tmp/target/.github/work-copilot/` populated; `.github/prompts/validate.prompt.md` exists; exit 0 | Pending |
| 2 | Re-install skips unchanged files | Re-run step 1 | `installed=0 skipped=N` in summary; exit 0 | Pending |
| 3 | Drift refuses without overwrite | Edit one installed file; re-run install | `[DRIFT] <file>`; exit non-zero | Pending |
| 4 | `--overwrite` replaces drifted file | Re-run install with `--overwrite` | File replaced; warning printed; exit 0 | Pending |
| 5 | Doctor on clean install | `python scripts/copilot-deploy.py doctor /tmp/target` | Zero issues; exit 0 | Pending |
| 6 | Doctor on missing file | Delete one installed file; re-run doctor | `[MISSING] <file>`; exit 1 | Pending |
| 7 | Doctor on orphan file | Add a stray file under `.github/work-copilot/`; re-run doctor | `[ORPHAN] <file>`; exit 1 | Pending |
| 8 | Windows binary-safe hashing | Run install on Windows 11 with Python 3.10+; verify source and dest have same SHA256 | Hashes match even with CRLF-converted working copies | Pending |
| 9 | `validate.sh` template sync | Edit `templates/company-workflow/tracker-feature.md`; do not update `work-copilot/templates/`; run `./scripts/validate.sh` | Fails with drift message | Pending |
| 10 | `remove` leaves user files alone | `python scripts/copilot-deploy.py remove /tmp/target` | Bundle files gone; user's other `.github/` contents untouched | Pending |

## Verification Steps

- [ ] Local build succeeds on macOS and Windows
- [ ] Tier 1 smoke tests (S1–S5 from parent TEST-SPEC) pass
- [ ] Python script passes `python -m py_compile scripts/copilot-deploy.py` (no syntax errors)
- [ ] `scripts/validate.sh` passes with bundle in sync
- [ ] End-to-end: install on Windows box, run `/validate` in Copilot Chat (parent E2E E1)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | feat/work-copilot HEAD | Pending |
| Windows 11 + Python 3.10 | feat/work-copilot HEAD | Pending |
