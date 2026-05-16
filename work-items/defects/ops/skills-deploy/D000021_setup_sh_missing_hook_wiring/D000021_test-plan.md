---
type: test-plan
parent: D000021
title: "setup.sh bootstrap never installs the post-merge auto-sync hook — Test Plan"
date: 2026-05-15
author: chjiang
status: Draft
---

<!-- Scope: ONE defect fix. Cases are regression cases for the specific bug:
     setup.sh not wiring setup-hooks.sh. The automated regression is a
     source-level static grep inside test.sh's existing D000013 block —
     no git init, no fixture, no setup.sh execution (its clone path hits
     the network; the D000013 block deliberately avoids firing hooks in CI). -->

## Scope

Two one-line changes:

- `scripts/setup.sh` — one guarded line inserted immediately before the final
  `exec` (setup.sh:33): `"$CLONE_DIR/scripts/setup-hooks.sh" || echo "WARN:
  hook install failed (run scripts/setup-hooks.sh manually)" >&2`. `exec` stays
  last and unchanged.
- `scripts/test.sh` — one `if grep` assertion added inside the existing D000013
  regression block (test.sh:724–749), matching the adjacent guard idiom;
  asserts `setup.sh` references `setup-hooks.sh`.

No change to `skills-deploy install` behavior, the post-merge hook body, or any
release/deploy workflow. No new fixture.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `test.sh` asserts setup.sh wires setup-hooks.sh (positive) | Run `./scripts/test.sh`; observe the new assertion inside the D000013 block | New assertion prints `ok "setup.sh bootstrap invokes setup-hooks.sh ..."`; full suite stays green | Pending |
| 2 | Negative test — revert wiring → test fails | Temporarily delete the `setup-hooks.sh` line from `scripts/setup.sh`; run `./scripts/test.sh`; then restore the line | With the line removed, the new assertion emits `fail_test "setup.sh does not invoke setup-hooks.sh ..."` and the suite goes red; after restore the suite is green again | Pending |
| 3 | Manual acceptance — fresh clone installs the hook (network OK, one-time) | `git clone <repo> /tmp/cst-test && /tmp/cst-test/scripts/setup.sh`; then `ls -l /tmp/cst-test/.git/hooks/post-merge` | `.git/hooks/post-merge` is present and executable; manual `setup-hooks.sh` no longer required for the documented path | Pending |
| 4 | `set -euo pipefail` regression guard — hook-install failure does not abort deploy | Simulate `setup-hooks.sh` failing (e.g. force its `HOOK_DIR` resolution to `exit 1`); run `setup.sh` | `setup.sh` prints the `WARN: hook install failed` line on stderr but **still reaches** the final `exec skills-deploy install`; deploy completes (no `set -e` abort) | Pending |
| 5 | `validate.sh` + `test.sh` overall green | Run `./scripts/validate.sh` then `./scripts/test.sh` | Both exit 0; `validate.yml` CI green; the new D000021 work-item passes `/CJ_personal-workflow check` | Pending |
| 6 | Scope held — no out-of-scope diff | `git diff` the PR | Only `scripts/setup.sh` (+1 line), `scripts/test.sh` (+the assertion), the D000021 work-item docs, and CHANGELOG/VERSION (via `/ship`) change. No `test-deploy.sh` fixture, no `skills-deploy` change, no doctor change, no release/deploy pipeline | Pending |

## Verification Steps

- [ ] Local build succeeds (the workbench has no compile step; `scripts/validate.sh` is the structural build gate)
- [ ] L1 regression suite passes (`scripts/test.sh` green, including the new D000013-block assertion — case 1)
- [ ] Negative test confirmed: reverting the `setup.sh` wiring line makes `test.sh` red at the new assertion, then restore (case 2)
- [ ] Manual reproduction of original bug confirms fix: throwaway clone + `setup.sh` → `.git/hooks/post-merge` present and executable (case 3)
- [ ] `set -e` guard verified: a forced `setup-hooks.sh` failure still lets `setup.sh` reach the deploy `exec` (case 4)
- [ ] `/CJ_personal-workflow check` clean on the D000021 work-item directory
- [ ] CHANGELOG entry + PR body disclose the commit-blocking pre-commit install delta (mandatory SHIP-WITH-DISCLOSURE — verified at `/ship`, not in this test plan's automated scope)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (workbench, branch claude/stoic-swartz-eb489a) | current `main` + this fix | Pending |
| `validate.yml` CI (GitHub Actions, Linux) | PR head | Pending |
