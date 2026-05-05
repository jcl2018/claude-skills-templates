---
type: test-plan
parent: D000011
title: "work-copilot install requires full claude-skills-templates checkout — Test Plan"
date: 2026-04-28
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     Per RCA's chosen mechanism (release tarball). Update test cases if
     RCA mechanism changes during /office-hours or implementation. -->

## Scope

The fix introduces a `scripts/release-bundle.sh` packaging script and a
`/ship`-integrated step that publishes `work-copilot-bundle-vX.Y.Z.tar.gz`
as a GitHub release asset on every workbench release tag. Files modified:

- `scripts/release-bundle.sh` — new — packs the bundle tarball
- `scripts/test.sh` — new test cases verifying tarball contents + integrity
- `work-copilot/README.md` — rewritten Install section (tarball, not clone)
- `README.md` (root) — adds "For Copilot users" section with tarball path
- `~/.claude/skills/gstack/ship/SKILL.md` (or workbench `/ship` shim) —
  one new line that calls `release-bundle.sh` after tag-push (out-of-scope
  if `/ship` integration is best left manual; in that case, document the
  command in CHANGELOG release notes)

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Tarball pack produces exactly the expected file set | Run `scripts/release-bundle.sh /tmp/out`. `tar tzf /tmp/out/work-copilot-bundle-vX.Y.Z.tar.gz \| sort` | Matches expected manifest exactly: every file under `work-copilot/` + `scripts/copilot-deploy.py` + the bundle-specific README. No `.claude/`, no `skills/personal-workflow/`, no `work-items/`, no `templates/personal-workflow/` | Pending |
| 2 | Tarball contents byte-identical to source | After Test 1, extract tarball to `/tmp/extract`. Run `find /tmp/extract -name '*.md' -print0 \| while IFS= read -r -d '' f; do cmp -s "$f" "$REPO/${f#/tmp/extract/}" \|\| echo MISMATCH "$f"; done` | No MISMATCH lines | Pending |
| 3 | End-to-end install from extracted tarball | Pack tarball, extract to fresh `/tmp/extract`, `cd /tmp/extract && python scripts/copilot-deploy.py install /tmp/target`. Verify `/tmp/target/.github/copilot-instructions.md` exists, `doctor` reports all PASS | install summary `installed=N skipped=0`, doctor exit 0, no MISSING/DRIFT/ORPHAN | Pending |
| 4 | Tarball excludes Claude-side artifacts | After Test 1, `tar tzf /tmp/out/work-copilot-bundle-vX.Y.Z.tar.gz \| grep -E '^(\.claude/\|skills/personal-workflow/\|skills/system-health/\|work-items/\|templates/personal-workflow/\|docs/)'` | exit 1 (no matches) | Pending |
| 5 | Tarball matches VERSION file | `tar tzf <tarball-path> \| head -1` and check it doesn't reference an old version; tarball filename matches `cat VERSION` | Filename matches `work-copilot-bundle-v$(cat VERSION).tar.gz` | Pending |
| 6 | Install path documented correctly | `grep -A 5 "Install" work-copilot/README.md` mentions `curl` or `gh release download` and does NOT recommend `git clone` for end-users | `git clone` only appears in a "for workbench contributors" section, not the primary install path | Pending |
| 7 | Drift safety net intact | After packing, run `scripts/validate.sh` — sync check Error check 10 still PASSes (the pack script must not modify source files) | exit 0, 0 errors | Pending |
| 8 | Workbench-cloner workflow unchanged | Existing contributor flow: `git clone <workbench> && cd <workbench> && python scripts/copilot-deploy.py install <target>` still works | No regression — Test 8 covers F000004 v1 install path; should pass unchanged | Pending |
| 9 | Original bug reproduces (without fix) | On a fresh dir, run the OLD documented flow (`git clone` of full repo, count files). Confirm ~350 files. Then run the NEW flow (tarball extract, count files). Confirm ~50 files | New flow delivers <100 files; old flow delivers >300 | Pending |
| 10 | Bundle-specific README is bundle-scoped | Inspect the bundle README inside the tarball. It should NOT reference workbench-internal paths like `templates/personal-workflow/`, `skills/personal-workflow/`, `work-items/`, etc. | grep -lE '(templates/personal-workflow\|skills/personal-workflow\|work-items/)' on the README returns nothing | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (macOS — primary dev box)
- [ ] L1 regression suite passes (`scripts/test.sh`)
- [ ] Manual reproduction of original bug confirms fix:
  - Fresh tmpdir, `curl`-extract tarball, install — works without ever cloning
  - Compare disk footprint: old flow vs new flow (≥7× reduction)
- [ ] Tarball published on a test release tag (e.g., `v1.1.0-test`); verify download URL works
- [ ] Windows work box: full re-run of D000011 reproduction steps with the new install path; expect ~50 files local instead of ~350
- [ ] CHANGELOG entry mentions the new install path; old `git clone` path is preserved for workbench contributors only

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (primary dev) | feat/v1-cut + fix branch | Pending |
| Linux (CI runner) | feat/v1-cut + fix branch | Pending |
| Windows (work box) | release tarball download path | Pending — gates on tarball being published; confirms the bug is actually fixed for the originally-affected user |
