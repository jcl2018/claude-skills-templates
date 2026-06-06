---
type: design
parent: S000086
title: "Single-bundle layout + git-checkout install (skills-deploy install --bundle) — Story Design"
version: 1
status: Draft
date: 2026-06-05
author: chjiang
reviewers: []
---

<!-- Atomic story: this design is a brief stub. The full S2 design (the O1
     resolution + the bundle-install mechanism + the staging) lives in the
     /office-hours design doc and the parent feature design — see Pointers. -->

## Problem

F000049's S2: make the CJ_ family installable as ONE self-contained git checkout
under `~/.claude/skills/` (gstack's install == clone), so the install dir IS the
checkout. The parent design flagged this as blocked on **O1** — how Claude Code
surfaces `/CJ_*` from a bundle dir vs flat `~/.claude/skills/<name>/`.

## Shape of the solution

A new **`skills-deploy install --bundle [path]`** mode (additive, opt-in): ensure a
managed git checkout of the workbench at the bundle path, then delegate to THAT
checkout's own `skills-deploy install`. The child's `REPO_ROOT` resolves to the
bundle, so the existing per-file-symlink install symlinks the flat `/CJ_*` dirs
INTO the bundle = install == clone. The default install is untouched.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Single-bundle layout + git-checkout install (resolve O1) | S000086 | S000086_SPEC.md / S000086_TEST-SPEC.md |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Additive `--bundle` flag, legacy `install` untouched | The live `~/.claude/skills/CJ_*` install cannot be bricked by a half-applied flip (parent hard-problem #1); opt-in + reversible |
| 2 | Delegate to the bundle's OWN `skills-deploy install` | O1 showed discovery is unchanged — the bundle's install (REPO_ROOT=bundle) symlinks INTO the bundle with zero new logic; minimal + low-risk |
| 3 | Bundle = a managed clone, NOT moving the dev clone | S2 adds layout + mode; make-bundle-the-dev-checkout + retire external clone is S3 |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| The eventual flip (bundle as default install) | OUT of S2 — S4 |
| Develop-in-place (editing the bundle) | OUT of S2 — S3 |
| Windows/Git-Bash copy-mode of the bundle | Degrades to copy-mode like the legacy install; full parity audit is S5 |
| Clone source offline | `SKILLS_DEPLOY_BUNDLE_SOURCE` → manifest `.source` (local) → `upstream_url`; tests clone from a local path |

## Definition of done

- [x] `skills-deploy install --bundle` ensures a managed git checkout + symlinks the flat `/CJ_*` skills INTO it
- [x] The default `skills-deploy install` is unchanged (additive)
- [x] The manifest records `install_mode: bundle` + `bundle_path` + `bundle_commit` + `source` = bundle
- [x] A hermetic test proves install==clone offline (clone from a local source)
- [x] `validate.sh` + `scripts/test.sh` green; shellcheck clean

## Not in scope

- Make the bundle the dev checkout (develop-in-place) + retire the external clone / `.source` / worktree flow — S3
- Flip `--bundle` to the default + drop legacy — S4
- Windows/Git-Bash copy-mode parity audit + CI + update-check on the in-place checkout — S5

## Pointers

- /office-hours S2 design (full): `.gstack/gstack-s2-bundle-install-design-20260605.md`
- Parent feature design: [../F000049_DESIGN.md](../F000049_DESIGN.md)
- S1 (landed): [../S000085_shared_scripts_self_containment/S000085_TRACKER.md](../S000085_shared_scripts_self_containment/S000085_TRACKER.md) — the `_cj-shared` deposit the bundle install reuses
- O1 reference implementation: `~/.claude/skills/gstack/` (a git-checkout bundle) + its flat symlink re-exports
