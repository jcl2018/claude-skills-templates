# Design: gstack-style deployment for the CJ_ workbench (install == clone)

Status: APPROVED
Date: 2026-06-05
Author: chjiang (via /office-hours, inline in /CJ_goal_feature)
Branch: cj-feat-20260605-160453-69246
Mode: builder (technical architecture migration)

## Problem

The CJ_ workbench separates a **source clone** (e.g. `~/Documents/projects/claude-skills-templates`) from **individually-installed skills** (`~/.claude/skills/CJ_*/`, per-file symlinks), bridged by `.source` in `~/.claude/.skills-templates.json`. The 26 shared root `scripts/*.sh` are NOT installed — 12 skills reach them via `.source` back to the clone. That `.source` reach-back is exactly what makes those skills `workbench`-tier (per `/CJ_portability-audit`): they can't run in a repo/machine that lacks the source clone.

gstack solves this differently: it ships **one self-contained dir `~/.claude/skills/gstack/` that IS a git checkout** (origin garrytan/gstack), containing every skill + a shared `bin/` + `agents/` + `package.json`/`VERSION`. Skills call `~/.claude/skills/gstack/bin/...` (absolute into the bundle); `/gstack-upgrade` `git pull`s the checkout in place. **install == clone ⇒ zero install-drift** and genuine self-containment.

## Decision (operator, this session)

Adopt the **full gstack model**: install the CJ_ family as ONE self-contained bundle whose install dir is itself the git checkout, develop the workbench BY editing that installed checkout, and **drop `.source` entirely**. Explicitly NOT per-skill script bundling and NOT a shared `~/.claude/cj-bin/`. The operator accepts that this reshapes self-development (the separate clone + the `cj-feat-*`/`cj-def-*` worktree machinery + `post-land-sync` + the F000045 pre-build sync get rethought/retired), and accepts a large multi-step effort.

## Target architecture

- A single bundle dir (working name `~/.claude/skills/cj-workbench/`) that is a **git checkout** of the workbench repo (the install == the clone == the dev working copy).
- Every CJ_ skill lives inside it; the 26 shared `scripts/*.sh` live inside it (under `scripts/` or a `bin/`), so skills resolve them **bundle-relative** — no `.source`, no separate-clone reach.
- Claude Code skill discovery: gstack surfaces both a nested `gstack/<skill>/` AND flat `~/.claude/skills/<skill>/`. We must determine which mechanism we need (a flat re-export of each skill, or Claude Code discovering nested skill dirs) — **OPEN QUESTION O1**.
- Upgrade/maintenance: a `git pull` in the bundle checkout replaces `skills-deploy install` from a separate clone; `post-land-sync` + the `--phase sync` + `skills-update-check` get reworked to operate on the in-place checkout, and the per-file-symlink install model is retired.
- Portability: with `.source` gone at runtime, the 12 `workbench` skills drop to `local-only` (or `standalone` where they reach nothing beyond their own bundle) — measurable on `/CJ_portability-audit`.

## Hard problems / risks (must be respected by the migration)

1. **Live-install flip without bricking.** The current `~/.claude/skills/CJ_*` install is in active use (this very pipeline). Flipping from per-file-symlinks to a single-checkout bundle must be reversible + staged; a half-applied flip cannot leave the user with no working `/CJ_*` skills.
2. **Self-dev flow rewrite.** The `cj-feat-*`/`cj-def-*` worktree machinery, `.source`, `post-land-sync`, and the `--phase sync` are all built on the separate-clone model. install==clone means developing *in* the checkout — these get retired or re-pointed. (Ironically this retires the machinery this run is using.)
3. **Claude Code discovery from a bundle (O1).** Unverified how Claude Code surfaces `/CJ_*` commands from inside a bundle dir vs flat `~/.claude/skills/<name>/`.
4. **Windows/Git-Bash + the symlink fallback.** `skills-deploy`'s copy-mode (no symlinks on Git Bash) must keep working under the new model.
5. **CI.** `validate.sh`/`test.sh` assume the repo-root `scripts/` layout; bundle layout changes the test surface.

## Migration decomposition (epic → stories)

This is an epic. Proposed stories (each shippable + reviewable on its own):

- **S1 (this run) — Runtime self-containment foundation.** Shared scripts travel with the install; skills resolve them bundle-first with `.source` as legacy fallback. Non-breaking, additive, reversible. Moves the 12 skills `workbench → local-only`. (Detailed below.)
- **S2 — Single-bundle layout + git-checkout install.** `skills-deploy` learns to install the CJ_ family as one self-contained checkout dir (alongside the legacy install, behind a flag); resolve O1 (skill discovery).
- **S3 — Develop-in-place + retire the separate-clone machinery.** Re-point/retire `.source`, `post-land-sync`, `--phase sync`, the `cj-feat-*`/`cj-def-*` worktree flow; the checkout becomes the dev copy.
- **S4 — Drop `.source` + manifest `source`; finalize the portability tier shift; docs (PHILOSOPHY/ARCHITECTURE/WORKFLOWS) + audit expectations.**
- **S5 — Cleanup + parity (Windows copy-mode, CI, `skills-update-check` on the in-place checkout).**

## Story 1 (the buildable slice for this /CJ_goal_feature run)

**Title:** Shared `scripts/*.sh` travel with the install; skills resolve them bundle-first, `.source` as legacy fallback (the runtime de-coupling foundation).

**Scope:**
- Deposit the 26 shared `scripts/*.sh` into a deployed location that travels with the install (candidate: a `_cj-shared/scripts/` skill-dir the deploy writes; exact home is the story's design decision). `skills-deploy install` populates it.
- Rewire the 12 `.source`-reaching skills' resolution preambles to a 3-tier resolution: (1) repo-local `$REPO_ROOT/scripts/` (workbench self-dev), (2) the deployed shared location, (3) `.source` (legacy fallback — removed in S4).
- Re-tier those skills `workbench → local-only` in `skills-catalog.json`; update the `/CJ_portability-audit` expectations + the docs that assert the old tier.
- Tests: a consumer-repo simulation (the D000030/D000032 pattern) proving a skill resolves a shared script with NO source clone present; the audit reflects the new tier.

**Why this first:** it is the common foundation of the full-gstack path, it is genuinely non-breaking (`.source` fallback preserved), it is the single biggest portability win (12 skills de-coupled from the source clone), and it is independently testable + reversible. S2+ (install==clone, develop-in-place) build on it.

**Non-goals for S1:** does NOT yet make the install a checkout, does NOT retire `.source`/worktree/`post-land-sync`, does NOT change Claude Code discovery. Those are S2–S5.

## Open questions

- **O1:** How does Claude Code surface `/CJ_*` from a bundle dir vs flat `~/.claude/skills/<name>/`? (Blocks S2, not S1.)
- **O2:** Shared-scripts deployed home — a `_cj-shared` skill dir, or a `cj-workbench/` proto-bundle? (Resolved during S1 implementation.)
- **O3:** Does retiring the `cj-feat-*` worktree dev flow (S3) need a replacement dev convenience, or is "edit the checkout + branch in place" enough?

## The assignment (next concrete action)

Build **S1** through `/CJ_goal_feature`'s silent build (scaffold → implement → qa → PR), OR — given this is the deployment FOUNDATION and S1 touches 12 skills + `skills-deploy` + the catalog + the audit — review this design + S1's plan before spending the autonomous build budget. The design-summary gate (next) is that go/no-go.
