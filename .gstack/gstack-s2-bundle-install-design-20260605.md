# Design: S2 — single-bundle layout + git-checkout install (`skills-deploy install --bundle`)

Status: APPROVED
Date: 2026-06-05
Author: chjiang (via /office-hours, inline in /CJ_goal_feature)
Branch: cj-feat-20260605-181820-91748
Mode: builder (technical architecture migration)
Parent: F000049 (gstack-style deployment, install == clone) — S2 of S1–S5

## Problem

F000049 converts the CJ_ workbench to gstack's **install == clone** model. S1
(S000085, landed v6.0.42) made the shared `scripts/*.sh` travel with the install.
S2 is the **single-bundle layout + git-checkout install**: make the CJ_ family
installable as ONE self-contained git checkout under `~/.claude/skills/`, the way
gstack installs. The parent design flagged this as blocked on **O1** — "how does
Claude Code surface `/CJ_*` from a bundle dir vs flat `~/.claude/skills/<name>/`?"

## O1 — RESOLVED (empirical, from the gstack reference implementation)

gstack is itself an install==clone bundle, so O1 is answered by inspection:

- `~/.claude/skills/gstack/` IS a **git checkout** (`.git` present) containing every
  gstack skill nested (`gstack/office-hours/SKILL.md`, name: `office-hours`).
- Claude Code discovers skills from **flat** `~/.claude/skills/<name>/SKILL.md`. So
  gstack **flat-exports** each user-facing skill: `~/.claude/skills/office-hours/`
  is a dir whose `SKILL.md` is a **symlink** → `../gstack/office-hours/SKILL.md`
  (points INTO the bundle checkout).
- **The CJ_ family is already ~90% this shape.** It already installs as flat
  symlink dirs (`~/.claude/skills/CJ_goal_feature/SKILL.md` → symlink). The ONLY
  difference from gstack: CJ_ symlinks point at the **external dev clone**
  (`~/Documents/projects/claude-skills-templates/skills/...`), whereas gstack's
  point into a **managed bundle checkout** under `~/.claude/skills/`.

**Conclusion:** O1 needs no new discovery mechanism. The flat-symlink-into-a-checkout
pattern already works for CJ_. S2 = make the symlink TARGET a managed bundle
checkout (`~/.claude/skills/cj-workbench/`) instead of the external clone.

## Shape of the solution (additive + flagged — the live install stays untouched)

A new **`skills-deploy install --bundle [path]`** mode:

1. **Ensure the managed bundle checkout.** Default path `~/.claude/skills/cj-workbench`.
   If absent, `git clone` it (from the manifest `upstream_url`, or a local fast-path
   from `.source`); if present, optional `git -C <bundle> pull --ff-only`. This dir
   IS the git checkout (install == clone).
2. **Install FROM the bundle, not the external clone.** Run the existing install
   logic with the source root swapped from `$REPO_ROOT` to `$BUNDLE` — the flat CJ_
   skill dirs + the shared `_cj-shared` scripts + templates + rules all symlink/copy
   from the bundle. This is the existing per-file-symlink install with one swapped
   variable; the discovery mechanism is unchanged.
3. **Record it in the manifest:** `install_kind: bundle`, `bundle_path`,
   `bundle_commit`. `doctor` reports the bundle's health + drift.
4. **Copy-mode parity:** on Git Bash (no symlinks), the bundle mode degrades to
   copy-mode exactly like the legacy install's `_can_symlink` fallback.

**Behind a flag.** The default `skills-deploy install` (legacy per-file-symlink into
the external clone) is **unchanged**. Nothing flips until the operator runs
`--bundle`. So the build is additive, the live install is safe, and the PR is the
review gate.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | A NEW `--bundle` mode behind a flag, legacy `install` untouched | Additive + reversible; the active `~/.claude/skills/CJ_*` install cannot be bricked by a half-applied flip (parent design hard-problem #1) |
| 2 | Bundle = a managed git **clone** at `~/.claude/skills/cj-workbench/` (fresh from origin/.source), NOT moving the dev clone | S2 adds the layout + install mode; "make the bundle the dev checkout" + retiring the external clone is S3 (develop-in-place). Keeps S2 non-disruptive. |
| 3 | Reuse the existing install logic with the source root swapped to `$BUNDLE` | O1 showed discovery is unchanged; the only delta is the symlink TARGET. Minimal, low-risk addition vs a parallel installer. |
| 4 | Default `install` stays the default; `--bundle` is opt-in | The flip to bundle-as-default + retiring legacy is S4. |

## Risks & open questions

| Risk / Question | Handling |
|-----------------|----------|
| The eventual live-install flip (bundle becomes default) | OUT of S2 — deferred to S4; S2 keeps `--bundle` opt-in |
| Develop-in-place (editing the bundle as the dev checkout) | OUT of S2 — that is S3; S2's bundle is a managed clone, the dev clone is untouched |
| Windows/Git-Bash copy-mode of the bundle | S2 degrades to copy-mode like the legacy install; full parity audit is S5 |
| Clone source: origin (network) vs `.source` (local) | S2 prefers a local `.source` clone for speed/offline, falls back to `upstream_url`; both recorded |
| `git clone` in CI/tests (no network) | Tests clone from the LOCAL repo (file:// or path), never the network |

## Definition of done

- [ ] `skills-deploy install --bundle [path]` ensures a managed git checkout at the bundle path and flat-exports the CJ_ family + `_cj-shared` scripts + templates from it
- [ ] The default `skills-deploy install` is byte-for-byte unchanged (legacy install untouched; verified by existing tests staying green)
- [ ] The manifest records `install_kind: bundle` + `bundle_path` + `bundle_commit`; `doctor` surfaces them
- [ ] A hermetic test installs the bundle mode from a LOCAL clone (no network) and asserts the flat CJ_ skills resolve into the bundle checkout
- [ ] `validate.sh` + `scripts/test.sh` green; shellcheck clean; Windows copy-mode degrades gracefully

## Not in scope (S3–S5)

- Making the bundle the **dev checkout** (develop-in-place) + retiring the external clone / `.source` / `post-land-sync` / the `cj-feat-*` worktree flow — **S3**
- Flipping `--bundle` to the **default** install + dropping legacy — **S4**
- Full **Windows/Git-Bash** copy-mode parity audit + CI + update-check on the in-place checkout — **S5**

## Pointers

- Parent feature design: `work-items/features/ops/F000049_*/F000049_DESIGN.md`
- Parent /office-hours design: `.gstack/gstack-style-deployment-design-20260605.md`
- S1 (landed): `work-items/features/ops/F000049_*/S000085_*` (the `_cj-shared` deposit this builds on)
- O1 reference implementation: `~/.claude/skills/gstack/` (a git-checkout bundle) + its flat symlink re-exports (`~/.claude/skills/office-hours/SKILL.md` → bundle)
