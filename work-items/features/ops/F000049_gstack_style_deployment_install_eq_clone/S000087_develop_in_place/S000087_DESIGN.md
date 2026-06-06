---
type: design
parent: S000087
title: "Develop-in-place enablement (bundle-status + origin-repoint) — Story Design"
version: 1
status: Draft
date: 2026-06-05
author: chjiang
reviewers: []
---

<!-- Atomic story: brief stub. The full S3 design (the scope decision + the
     mechanism) lives in the /office-hours doc + the parent design — see Pointers. -->

## Problem

F000049's S3 = "develop-in-place + retire the separate-clone machinery." The
rip-out half is subtractive + dangerous (28 `.source` refs, 15 worktree refs, the
machinery this very run uses). This story delivers the **develop-in-place** half
safely and defers the rip-out.

## Shape of the solution

After S2's `--bundle`, the bundle IS a git checkout with the flat `/CJ_*`
symlinked into it — editing in the bundle reflects live. The one gap: the bundle's
`origin` (cloned from a local `.source`) points at the local clone, so you can't
push/PR to GitHub. S3: **repoint `origin` to the GitHub upstream** + add
**`skills-deploy bundle-status`** + docs. Additive; the separate-clone machinery
is untouched.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Develop-in-place enablement (origin-repoint + bundle-status) | S000087 | S000087_SPEC.md / S000087_TEST-SPEC.md |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Deliver develop-in-place; DEFER the `.source`/worktree rip-out to S4 | The rip-out is subtractive + undesigned + retires the running machinery; the value is deliverable additively |
| 2 | Repoint the bundle's `origin` to the GitHub upstream | The genuine enabler — cloning from a local `.source` leaves origin un-pushable |
| 3 | `bundle-status` as a read-only subcommand | Visibility for the in-place dev checkout; mirrors `doctor` |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Operator expects the full rip-out from "build now" | Design + PR state the scoping explicitly; PR review is the check |
| Missing/absent upstream | Repoint only when `bundle_upstream` is non-empty; no failure otherwise |
| Windows copy-mode | Inherits S2's degradation; full parity is S5 |

## Definition of done

- [x] `--bundle` repoints the bundle's `origin` to the GitHub upstream
- [x] `bundle-status` reports the develop-in-place state; `dev-clone` on a non-bundle install
- [x] Additive — separate-clone machinery untouched (no rip-out)
- [x] Hermetic tests (repoint + bundle-status + non-bundle case)
- [x] `validate.sh` + `scripts/test.sh` green; shellcheck clean

## Not in scope

- Retiring `.source` / the worktree flow / `post-land-sync`'s separate-clone model — S4
- Flipping `--bundle` to the default install — S4
- Windows/Git-Bash copy-mode parity — S5

## Pointers

- /office-hours S3 design (full + the scope decision): `.gstack/gstack-s3-develop-in-place-design-20260605.md`
- Parent feature design: [../F000049_DESIGN.md](../F000049_DESIGN.md)
- S2 (landed): [../S000086_single_bundle_install/S000086_TRACKER.md](../S000086_single_bundle_install/S000086_TRACKER.md) — the `--bundle` mode this builds on
