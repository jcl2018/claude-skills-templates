# Design: S3 — develop-in-place enablement (`skills-deploy bundle-status` + origin-repoint)

Status: APPROVED
Date: 2026-06-05
Author: chjiang (via /office-hours, inline in /CJ_goal_feature)
Branch: cj-feat-20260605-185939-49060
Mode: builder (technical architecture migration)
Parent: F000049 (gstack-style deployment, install == clone) — S3 of S1–S5

## Problem

F000049's S3 (parent design one-liner): "develop-in-place + retire the
separate-clone machinery." Concretely it means: after S2's `--bundle`, the
managed bundle at `~/.claude/skills/cj-workbench/` IS a git checkout with the flat
`/CJ_*` symlinked into it. "Develop-in-place" means you edit the workbench IN that
checkout (branch, edit, push, PR) and the install reflects it live.

## The risk that shapes the scope (surfaced to the operator, who chose "build now")

The "retire the separate-clone machinery" half is **subtractive and dangerous**:
`.source` is referenced in ~28 files; the `cj-feat-*` worktree flow in ~15; the
machinery (`cj-goal-common.sh`, `cj-worktree-init/cleanup.sh`, `post-land-sync.sh`,
the 3 orchestrators) is what every `cj_goal` run — **including the run building
this** — operates on. Ripping it out wholesale, undesigned, in one PR could break
the dev flow mid-migration. The parent design called this out: "Ironically this
retires the machinery this run is using."

## Scope decision (the load-bearing call)

S3 delivers the **develop-in-place half** (the value) and **defers the rip-out**:

- **DELIVER:** make the bundle a first-class dev checkout you can actually develop
  + ship from. The genuine gap: `--bundle` clones from a LOCAL `.source` for
  speed/offline, so the bundle's `origin` points at the local clone — you cannot
  `git push`/PR to GitHub from it. S3 **repoints `origin` to the GitHub upstream**.
  Plus a `skills-deploy bundle-status` to see the dev checkout's state, plus docs.
- **DEFER (to S4 / later):** the actual retirement of `.source`, the `cj-feat-*`
  worktree flow, and `post-land-sync`'s separate-clone model. Those are
  intertwined with S4's "drop `.source`," and the separate-clone path stays
  WORKING (made optional, not removed). The machinery this run uses is untouched.

This keeps S3 **additive + reversible + non-breaking** — the same safety posture
as S1/S2 — while genuinely delivering "develop-in-place."

## Shape of the solution

1. **`do_bundle_install` origin-repoint:** read the GitHub upstream once
   (`SKILLS_DEPLOY_BUNDLE_UPSTREAM` env override → manifest `upstream_url`); after
   ensuring the bundle checkout, `git -C <bundle> remote set-url origin <upstream>`
   when it differs. Now the bundle tracks GitHub: branch off main, push, PR — all
   from `~/.claude/skills/cj-workbench/`.
2. **`skills-deploy bundle-status`** (new read-only subcommand): reports
   `install_mode`, the bundle path, branch/HEAD/origin/dirty, and the
   develop-in-place hint. On a non-bundle install it reports `dev-clone` (no false
   install==clone claim).
3. **Docs:** a usage note + the install summary point at develop-in-place +
   `bundle-status`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Deliver develop-in-place enablement; DEFER the `.source`/worktree rip-out to S4 | The rip-out is subtractive, undesigned, and retires the running machinery — unsafe in one PR. The value (develop-in-place) is deliverable additively. |
| 2 | Repoint the bundle's `origin` to the GitHub upstream | Cloning from a local `.source` leaves origin = the local clone; you couldn't push/PR. This is THE thing that makes develop-in-place actually usable. |
| 3 | `bundle-status` as a read-only subcommand (not a flag) | Visibility for the in-place dev checkout; mirrors `doctor`. Safe + additive. |
| 4 | Keep the separate-clone path working (make optional, not remove) | Reversible + non-breaking; the default install + the worktree flow are untouched. |

## Risks & open questions

| Risk / Question | Handling |
|-----------------|----------|
| Operator expects the FULL rip-out from "build S3 now" | The design + PR state the scoping explicitly: develop-in-place delivered, rip-out deferred to S4. The PR review is the check. |
| `origin` repoint to a wrong/absent upstream | Only repoints when `bundle_upstream` is non-empty; a missing upstream leaves the local origin + no failure. |
| Windows/Git-Bash | Inherits S2's copy-mode degradation; full parity is S5. |

## Definition of done

- [x] `--bundle` repoints the bundle's `origin` to the GitHub upstream (push/PR from the bundle works)
- [x] `skills-deploy bundle-status` reports the develop-in-place checkout state; reports `dev-clone` on a non-bundle install
- [x] Additive: the default install + the separate-clone machinery are untouched (no rip-out)
- [x] Hermetic tests for the repoint + bundle-status (incl. the non-bundle case)
- [x] `validate.sh` + `scripts/test.sh` green; shellcheck clean

## Not in scope (deferred)

- Retiring `.source` / the `cj-feat-*` worktree flow / `post-land-sync`'s separate-clone model — intertwined with **S4** (drop `.source`); S3 keeps them working
- Flipping `--bundle` to the default install — **S4**
- Windows/Git-Bash copy-mode parity — **S5**

## Pointers

- Parent feature design: `work-items/features/ops/F000049_*/F000049_DESIGN.md`
- S2 (landed): `work-items/features/ops/F000049_*/S000086_*` — the `--bundle` mode this builds on
- O1 reference: `~/.claude/skills/gstack/` (a git-checkout bundle, develop-in-place pattern)
