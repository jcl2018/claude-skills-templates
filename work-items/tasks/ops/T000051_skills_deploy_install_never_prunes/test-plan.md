---
type: test-plan
parent: T000051
title: "`skills-deploy install` never prunes shared scripts deleted from source — orphaned `_cj-shared/scripts/*` accumulate (P3, S) — Test Plan"
date: 2026-06-15
author: Charlie
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

<!-- What does the fix change? Which files/components were modified? -->

Teaches `scripts/skills-deploy` to reconcile the deployed shared-script home
(`~/.claude/_cj-shared/scripts/`) against the source set on every `install`, and
to report its health on `doctor`. Files changed:

- `scripts/skills-deploy` — `do_install` gains a manifest-keyed prune block (inside
  the existing `-d "$SHARED_SCRIPTS_SRC"` guard, after the deploy loop) that removes
  any `.shared_scripts` entry with no source counterpart from BOTH the deployed file
  and the manifest, a `shared_pruned` counter, and a `Pruned:` field on the summary
  line. `do_doctor` gains a `--- Shared scripts ---` section (ORPHAN / FAIL / WARN / OK).
- `scripts/test-deploy.sh` — the regression case below.

The prune is keyed off the MANIFEST `.shared_scripts` keys (scripts a prior install
deployed + tracked), never a raw scandir of the target — so a hand-placed file the
install never recorded is never touched (ownership safety).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `T000051: install prunes orphaned shared scripts (ownership-safe)` in `scripts/test-deploy.sh` | Run an isolated `skills-deploy install` (`SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET` pointed at a temp dir so the real `~/.claude/_cj-shared/` is untouched) so a real source script deploys + is manifest-tracked. Inject a manifest-TRACKED orphan (`zzz-orphan.sh` deployed file + `.shared_scripts` entry, no source) and a hand-placed UNTRACKED file (`zzz-handplaced.sh`, not in the manifest). Re-run `install`. | `zzz-orphan.sh` is removed from BOTH the target dir and the manifest; `zzz-handplaced.sh` SURVIVES (ownership safety — untracked file untouched); a real tracked script (`cj-goal-common.sh`) stays present + manifest-tracked. | Pass |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [x] `bash scripts/test-deploy.sh` passes (new case + all existing cases)
- [x] `bash scripts/validate.sh` green
- [x] `shellcheck scripts/skills-deploy scripts/test-deploy.sh` clean
- [x] Manual reproduction: doctor reports `ORPHAN` before prune; install #2 emits `SHARED: pruned ...` + `Pruned: 1`; install #3 is a clean no-op (idempotent); doctor afterward shows no ORPHAN + `Health: OK`

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | claude/dazzling-jemison-feb6e8 | Pass |
