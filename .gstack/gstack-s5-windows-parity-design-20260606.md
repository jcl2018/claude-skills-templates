---
title: "F000049 S5 — lock in Windows copy-mode parity for the in-place install==clone model (epic closer)"
mode: startup
status: DRAFT
date: 2026-06-06
author: chjiang
parent: F000049
predecessors: [S000085 (S1), S000086 (S2), S000087 (S3), S000088 (S4)]
recommended-approach: "A — verification-only: lock in the parity that already holds; DROP the dir-symlink polish; close F000049"
---

## Why this doc exists

S5 is the final story of F000049. The epic's last open success criterion is
"Windows/Git-Bash copy-mode parity holds." S4 (S000088) declared the default
install **install==clone-in-place** and dropped every runtime `.source`
reach-back. The S5 design pass first asked the obvious question: does that S4
model actually work under Windows copy-mode, or does it need new parity code?

## The de-risking finding (parity already holds)

A hermetic copy-mode (`SKILLS_DEPLOY_FORCE_COPY=1`) **default** install was run and
inspected:

- the manifest stamps `install_mode: "in-place"` + `bundle_path == source` — the
  S4 install==clone-in-place receipt holds under copy-mode;
- `skills-update-check` is copy-deposited to `_cj-shared/scripts/` — the
  de-coupled update-check resolution target exists on Windows;
- the orchestrators copy-install as regular files carrying the de-coupled `_UC=`
  (`_cj-shared`) update-check — no `.source` read.

**Conclusion:** S4's changes were platform-neutral by construction (the in-place
receipt is a manifest jq write; the `_cj-shared` deposit is already `cp`; the
resolution is `_cj-shared`-based). The Windows copy-mode parity the epic asks for
**already holds with zero new code.** S5 is therefore not a parity-code story —
it is a *lock-in* story.

## Scope (Approach A — chosen)

1. **Lock in the parity.** `scripts/windows-smoke.sh` already asserts copy-mode
   install + `install_kind=copy` + healthy doctor (S000079), but NOT the S4
   `install_mode: in-place` stamp or the de-coupled `_cj-shared` resolution. Add
   one S5 assertion block: a copy-mode default install stamps `install_mode:
   in-place` (`bundle_path == source`) AND a copy-installed orchestrator resolves
   update-check from `_cj-shared` with no `.source` read. `windows-smoke.sh` runs
   on **both** lanes — windows-latest (`.github/workflows/windows.yml`) and ubuntu
   (`scripts/test.sh:506` via the `FORCE_COPY` override) — so the lock-in guards
   a future regression on real Windows AND in the default CI.
2. **Docs.** `CLAUDE.md` "Running on Windows" notes the in-place install==clone
   model holds under copy-mode (with the de-risking finding), and records that the
   dir-symlink refinement was deliberately dropped (below).
3. **Close F000049.** Mark the epic done in the parent TRACKER/ROADMAP.

## Decision: DROP the dir-symlink reinstall-free refinement

The S4-deferred idea — install `~/.claude/skills/<name>` as a dir-level symlink
INTO the checkout so a `git pull` makes NEW skill files live with no reinstall —
is **dropped**, not deferred again:

- it is **POSIX-only** (Windows copy-mode can't symlink), so it would *create* a
  POSIX-reinstall-free / Windows-still-reinstalls **asymmetry** — the opposite of
  the "parity" S5 is meant to secure;
- it is **not** an F000049 success criterion (install==clone ✓, no `.source` ✓,
  develop-in-place ✓, consumer-install ✓, Windows parity ✓-already);
- it would rework the doctor's per-file `source_checksums` drift detection (a
  dir-symlink has no per-file checksums) — real cost for a convenience;
- `post-land-sync` / `--phase sync` already reinstall on pull, so a new file is
  picked up on the next sync — the convenience gap is small.

If a reinstall-free pull is ever wanted, it is a standalone follow-up, scoped on
its own merits, not a tail of this epic.

## Risks & open questions
- R1 — the assertion must pass on a symlink-capable host too (it uses
  `FORCE_COPY`), so it stays green on macOS/Linux + the ubuntu CI, not just
  windows-latest. (Same portability posture as the existing S000079 block.)
- O1 — none; the de-risking already answered the only open question (does S4 work
  under copy-mode → yes).

## Definition of done
- [ ] `windows-smoke.sh` asserts the in-place stamp + `_cj-shared` resolution under copy-mode
- [ ] Runs green on both lanes (local FORCE_COPY + windows-latest)
- [ ] CLAUDE.md notes Windows parity + the dropped dir-symlink decision
- [ ] F000049 marked DONE; `validate.sh` + `scripts/test.sh` + shellcheck green; audit FINDINGS=0

## Pointers
- S4 design (the in-place model this verifies): `.gstack/gstack-s4-retire-legacy-design-20260605.md`
- Parent feature: [../F000049_DESIGN.md] / ROADMAP
- F000044 Windows support (the copy-mode mechanism): `work-items/features/ops/F000044_windows_wsl2_git_bash_support/`
