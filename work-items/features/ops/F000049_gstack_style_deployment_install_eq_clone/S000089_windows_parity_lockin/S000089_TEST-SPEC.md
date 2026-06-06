---
type: test-spec
parent: S000089
feature: F000049
title: "Lock in Windows copy-mode parity for the in-place install==clone model (F000049 closer) — Test Specification"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
spec: SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | A hermetic `FORCE_COPY` default `skills-deploy install` yields a manifest with `install_mode == "in-place"` AND `bundle_path == source` | the S4 install==clone-in-place receipt holds under copy-mode | `scripts/windows-smoke.sh` (S5 block: assertion 1) |
| S2 | core | AC-2 | A copy-installed orchestrator SKILL.md contains the `_UC=` (`_cj-shared`) update-check form and NO `jq -r '.source'` read | the S4 de-coupling holds under copy-mode | `scripts/windows-smoke.sh` (S5 block: assertion 2) |
| S3 | resilience | AC-3 | `windows-smoke.sh` exits 0 on a symlink-capable host (it uses `FORCE_COPY`, so it is host-independent) — exercised by `scripts/test.sh:506` on ubuntu CI | the lock-in guards both lanes, not just windows-latest | `bash scripts/windows-smoke.sh` (and `scripts/test.sh` S000080 regression) |
| S4 | usability | AC-4 | `CLAUDE.md` "Running on Windows" contains the in-place copy-mode parity note AND the dir-symlink drop rationale | the model + the dropped refinement are documented | `grep -c 'install_mode: in-place\|dir-level symlink' CLAUDE.md` |
| S5 | observability | AC-5 | `_cj-shared/scripts/skills-update-check` is copy-deposited AND the manifest `source` equals the in-place checkout | the update-check nudge works on the in-place Windows install | `scripts/windows-smoke.sh` (S5 block: assertion 1 covers source==bundle_path; deposit check) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1,AC-2 | A maintainer on Windows (Git Bash) installs the workbench in copy-mode | `skills-deploy install` on a real Git-Bash host (auto-selects copy-mode); inspect the manifest + a deployed orchestrator | manifest stamps `install_mode: in-place` + `bundle_path == source`; the deployed orchestrator resolves update-check from `_cj-shared` with no `.source` read; the family runs | PASS if the in-place receipt + the de-coupled resolution both hold on a real copy-mode host; FAIL if either reverts to `.source` or omits the in-place stamp |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Dir-level skill symlinks (reinstall-free pull) | DROPPED by design (POSIX-only asymmetry, non-criterion, drift-detection cost) — there is nothing to test | A new skill FILE still needs a reinstall (`skills-deploy install` / `post-land-sync`) to appear on any platform; symmetric, accepted |
| A real windows-latest run pre-merge | The assertion is host-independent (`FORCE_COPY`) and runs locally + on ubuntu; the live windows-latest run happens in CI on the PR | If a Windows-only path regresses despite FORCE_COPY parity, windows.yml catches it on the PR before land |
| The audit verdict via the deployed engine path | The audit is verified in-repo (FINDINGS=0); the deployed `~/.claude` engine path differs by install kind | The in-repo audit is authoritative; the deployed-path audit is out of S5 scope |
