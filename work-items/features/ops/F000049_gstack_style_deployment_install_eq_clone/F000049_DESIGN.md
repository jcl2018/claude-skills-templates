---
type: design
parent: F000049
title: "gstack-style deployment for the CJ_ workbench (install == clone) — Feature Design"
version: 1
status: Draft
date: 2026-06-05
author: chjiang
reviewers: []
---

## Problem

The CJ_ workbench separates a source clone from individually-installed skills (`~/.claude/skills/CJ_*/`, per-file symlinks), bridged by `.source` in the manifest. The shared root `scripts/*.sh` are not installed — the 4 orchestrator-family skills reach them via `.source` back to the clone to EXECUTE them, which is what makes those skills `workbench`-tier: they can't run without the source clone present. (Implementation note: 12 skills reach `.source`, but only these 4 execute shared scripts; the rest reach `.source` only for the passive update-check nudge — see S000085.) gstack solves this by shipping ONE self-contained dir that IS a git checkout (install == clone), giving zero install-drift and genuine self-containment. This feature adopts that model for the CJ_ family.

## Shape of the solution

A single bundle dir (working name `~/.claude/skills/cj-workbench/`) that is a git checkout of the workbench repo; every CJ_ skill + the 26 shared scripts live inside it; skills resolve scripts bundle-relative (no `.source`); the workbench is developed by editing that checkout in place; `git pull` replaces `skills-deploy install` from a separate clone. Decomposes into 5 user-stories (S1 is the non-breaking foundation; S2–S5 carry the install==clone flip + the dev-flow rewrite + cleanup).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Shared scripts travel with the install; drop runtime `.source` reach (non-breaking) | S000085 (S1) | S000085_shared_scripts_self_containment/S000085_TRACKER.md |
| Single-bundle layout + git-checkout install (resolve skill-discovery O1) | S2 (roadmap) | F000049_ROADMAP.md |
| Develop-in-place + retire the separate-clone machinery | S3 (roadmap) | F000049_ROADMAP.md |
| Drop `.source` + manifest source; finalize tier shift; docs | S4 (roadmap) | F000049_ROADMAP.md |
| Cleanup + parity (Windows copy-mode, CI, update-check) | S5 (roadmap) | F000049_ROADMAP.md |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Full gstack model (install == clone, develop-in-place), NOT the hybrid (consumer bundle + keep dev clone) | Operator choice — most faithful + zero install-drift; accepts the dev-flow rewrite |
| 2 | NOT per-skill script bundling, NOT a shared `~/.claude/cj-bin/` | Operator constraint — only the single-self-contained-bundle approach |
| 3 | Ship as an epic (S1–S5), S1 first + non-breaking (`.source` fallback retained until S4) | The live install is in use; a foundation flip must be staged + reversible |
| 4 | Stop at design + scaffold this run (no autonomous silent build of S1) | S1 touches `skills-deploy` + 12 skills + catalog + audit — too load-bearing for one silent build |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| O1: how Claude Code surfaces `/CJ_*` from a bundle dir vs flat `~/.claude/skills/<name>/` | S2 design (blocks the install==clone flip, not S1) |
| Live-install flip without bricking the active `~/.claude/skills/CJ_*` | S2/S3 must be staged + reversible |
| Self-dev rewrite retires the very `cj-feat-*` worktree machinery this run uses | S3 — design the replacement dev convenience (O3) |
| Windows/Git-Bash copy-mode parity under the new layout | S5 |
| O2: shared-scripts deployed home (`_cj-shared` skill dir vs `cj-workbench/` proto-bundle) | S1 implementation |

## Definition of done

- [ ] CJ_ family installs as one self-contained git-checkout bundle (install == clone)
- [ ] No runtime `.source` reach-back; `--no-adjudication` audit shows the family `local-only`/`standalone`, not `workbench`
- [ ] Workbench developed in-place; separate-clone + worktree + `post-land-sync` + `--phase sync` retired/re-pointed
- [ ] Consumer install+run with no separate source clone present
- [ ] `validate.sh` + `scripts/test.sh` green; Windows copy-mode parity

## Not in scope

- Per-skill script bundling / a shared `~/.claude/cj-bin/` — explicitly excluded by operator constraint
- gstack's own deployment (this is the CJ_ family only)
- Migrating the `work-copilot/` Copilot bundle (separate distribution surface)

## Pointers

- Parent tracker: [F000049_TRACKER.md](F000049_TRACKER.md)
- Roadmap: [F000049_ROADMAP.md](F000049_ROADMAP.md)
- /office-hours design: `.gstack/gstack-style-deployment-design-20260605.md`
- Precedent technique: D000032 (bundled `CJ_repo-init` engine — the bundle-own-script carve-out this generalizes)
