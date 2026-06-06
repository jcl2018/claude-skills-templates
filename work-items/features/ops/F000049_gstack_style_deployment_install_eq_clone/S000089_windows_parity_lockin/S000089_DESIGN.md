---
type: design
parent: S000089
title: "Lock in Windows copy-mode parity for the in-place install==clone model (F000049 closer) — Story Design"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
reviewers: []
---

<!-- Atomic story: brief stub. The full S5 design (the de-risking finding + the
     dropped dir-symlink decision) lives in the /office-hours doc — see Pointers. -->

## Problem

F000049's last open success criterion is "Windows/Git-Bash copy-mode parity
holds." S4 (S000088) declared the default install install==clone-in-place and
dropped runtime `.source`. S5 verifies that under copy-mode and closes the epic.

## Shape of the solution

The de-risking finding: a hermetic `FORCE_COPY` default install ALREADY stamps
`install_mode: in-place` (`bundle_path == source`), copy-deposits
`skills-update-check` to `_cj-shared`, and copy-installs the orchestrators with the
de-coupled `_UC=` update-check — S4 was platform-neutral by construction. So S5 is
a **lock-in** story: one `windows-smoke.sh` assertion (it runs on both lanes —
windows-latest via `windows.yml` and ubuntu via `test.sh:506`) + a CLAUDE.md note +
the epic close. NO new parity code.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Lock in + document the Windows copy-mode parity for the in-place model; close F000049 | S000089 | S000089_SPEC.md / S000089_TEST-SPEC.md |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Verification-only S5 (lock-in assertion + docs + close); no new parity code | The de-risking proved S4's model already holds under copy-mode |
| 2 | Assertion in `windows-smoke.sh` | It runs on BOTH lanes (windows.yml + test.sh:506) — one assertion guards real Windows AND ubuntu CI |
| 3 | DROP the dir-symlink reinstall-free refinement | POSIX-only asymmetry (the opposite of parity), non-criterion, drift-detection rework cost |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| The assertion must stay green on symlink-capable hosts | Use `FORCE_COPY` (same posture as the existing S000079 block) |
| Reinstall-free pull ever wanted? | Standalone follow-up on its own merits, NOT a tail of F000049 |

## Definition of done

- [ ] `windows-smoke.sh` asserts the in-place stamp + `_cj-shared` resolution under copy-mode (both lanes)
- [ ] CLAUDE.md notes parity + the dropped dir-symlink decision
- [ ] F000049 marked DONE; `validate.sh` + `scripts/test.sh` green; shellcheck clean; audit FINDINGS=0

## Not in scope

- Dir-level skill symlinks (reinstall-free pull) — dropped (see Big decision #3)
- New copy-mode behavior — none needed (the de-risking showed parity already holds)

## Pointers

- /office-hours S5 design (full + de-risking + dropped-refinement rationale): `.gstack/gstack-s5-windows-parity-design-20260606.md`
- S4 (the in-place model this verifies): [../S000088_retire_separate_clone_legacy/S000088_TRACKER.md](../S000088_retire_separate_clone_legacy/S000088_TRACKER.md)
- F000044 Windows support (the copy-mode mechanism): `work-items/features/ops/F000044_windows_wsl2_git_bash_support/`
