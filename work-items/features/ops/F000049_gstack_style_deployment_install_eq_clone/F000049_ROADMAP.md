---
type: roadmap
parent: F000049
title: "gstack-style deployment for the CJ_ workbench (install == clone) — Roadmap"
date: 2026-06-05
author: chjiang
status: Draft
---

## Scope

Convert the CJ_ workbench from its current split model — a source clone plus
individually-installed, per-file-symlinked skills bridged by `.source` in the
manifest — to the full **gstack deployment model: install == clone**. The CJ_
family installs as ONE self-contained dir that is itself the git checkout; every
skill and the 26 shared `scripts/*.sh` live inside it and resolve bundle-relative
(no `.source` reach-back); the workbench is developed by editing that checkout in
place; a `git pull` replaces `skills-deploy install` from a separate clone. The
work decomposes into five shippable user-stories (S1–S5): S1 is the non-breaking
runtime de-coupling foundation; S2–S5 carry the install==clone flip and the
self-development-flow rewrite.

## Non-Goals

- Per-skill script bundling — explicitly excluded by operator constraint ("No others")
- A shared `~/.claude/cj-bin/` for the shared scripts — explicitly excluded by operator constraint
- Migrating gstack's own deployment — this epic is the CJ_ family only
- Migrating the `work-copilot/` Copilot bundle — separate distribution surface, out of scope
- A hybrid model (a consumer bundle while keeping the separate dev clone) — the operator chose the full-gstack target over the hybrid

## Success Criteria

- [ ] The CJ_ family installs as ONE self-contained bundle whose install dir is itself the git checkout (install == clone)
- [ ] No skill performs a runtime `.source` reach-back; `/CJ_portability-audit --no-adjudication` shows the family `local-only`/`standalone`, not `workbench`
- [ ] The workbench is developed in place; the separate-clone + `cj-feat-*`/`cj-def-*` worktree machinery + `post-land-sync` + `--phase sync` are retired or re-pointed
- [ ] A consumer can install + run the family with no separate source clone present
- [ ] `validate.sh` + `scripts/test.sh` green under the new layout; Windows/Git-Bash copy-mode parity holds

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000085](S000085_shared_scripts_self_containment/S000085_TRACKER.md) | Shared scripts travel with the install (runtime de-coupling foundation) | Closed (landed v6.0.42 / PR #232) |
| [S000086](S000086_single_bundle_install/S000086_TRACKER.md) | Single-bundle layout + git-checkout install (`--bundle`; resolves O1) | Closed (landed v6.0.43 / PR #233) |
| [S000087](S000087_develop_in_place/S000087_TRACKER.md) | Develop-in-place enablement (`--bundle` origin-repoint + `bundle-status`) | Closed (landed v6.0.44 / PR #234) |
| [S000088](S000088_retire_separate_clone_legacy/S000088_TRACKER.md) | Retire the separate-clone legacy (declare install==clone-in-place + drop runtime `.source` + reframe sync) | In Progress (built; this PR) |
| S5 (TBD) | Cleanup + parity (Windows copy-mode, CI, `skills-update-check` on the in-place checkout) | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | S1 (S000085) shared-scripts self-containment | — | Not Started | chjiang | Non-breaking foundation; `.source` fallback retained | — |
| 2 | S2 single-bundle layout + git-checkout install | — | Not Started | chjiang | Resolves O1 (Claude Code skill discovery from a bundle) | #1 |
| 3 | S3 develop-in-place + retire separate-clone machinery | — | Not Started | chjiang | Retires the worktree / `.source` / `post-land-sync` dev flow | #2 |
| 4 | S4 (S000088) declare install==clone-in-place + drop runtime `.source` + reframe sync; docs | — | In Progress | chjiang | D1-B in-place (no relocation); `--bundle`=consumer bootstrap; sync REFRAMED not deleted (remote-merge needs a pull); worktrees kept | #3 |
| 5 | S5 cleanup + parity (Windows copy-mode, CI, update-check) | — | Not Started | chjiang | windows-latest CI parity; update-check on the in-place checkout | #4 |

### Delivery History

- 2026-06-05: F000049 scaffolded — epic to convert the CJ_ workbench to the gstack model (install == clone). S1 (S000085) scaffolded as the non-breaking foundation; S2–S5 are roadmap entries pending their own scaffolds. (No code shipped this run — design + scaffold only, per operator choice.)

## Dependency Graph

```
#1 S1 shared-scripts self-containment (non-breaking foundation)
   --> #2 S2 single-bundle layout + git-checkout install (resolve O1)
       --> #3 S3 develop-in-place + retire the separate-clone machinery
           --> #4 S4 drop .source + manifest source; finalize tier shift; docs
               --> #5 S5 cleanup + parity (Windows copy-mode, CI, update-check)
```

## Open Questions

| Question | Next check |
|----------|-----------|
| O1: how Claude Code surfaces `/CJ_*` from a bundle dir vs flat `~/.claude/skills/<name>/` | S2 design (blocks the install==clone flip, not S1) |
| O2: shared-scripts deployed home — a `_cj-shared` skill dir vs a `cj-workbench/` proto-bundle | S1 implementation |
| O3: does retiring the `cj-feat-*` worktree dev flow need a replacement dev convenience, or is "edit the checkout + branch in place" enough | S3 design |
