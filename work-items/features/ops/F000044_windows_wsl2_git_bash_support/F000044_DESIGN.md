---
type: design
parent: F000044
title: "Windows (WSL2 + Git Bash) support for the skills workbench — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Story-scope detail (SPEC/TEST-SPEC)
     lives on the nested user-stories. Source: office-hours design doc
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260603-233220.md -->

## Problem

The workbench is largely macOS-only by construction: 42 bash scripts (all `#!/usr/bin/env bash`) plus one Python file, and two skills (`CJ_suggest`, `CJ_improve-queue`) that hard-refuse off macOS via `uname -s != "Darwin"`. A 2026-06-03 portability audit catalogued the concrete blockers to running on Windows. For a Claude Code skills repo, "Windows" realistically means a POSIX layer — WSL2 or Git Bash — because Claude Code executes every skill's bash preamble through that layer. Native `cmd`/PowerShell was considered and rejected.

## Shape of the solution

Approach B (POSIX-clean): make the workbench run on both WSL2 and Git Bash without a rewrite. Four concerns, one per user-story:

| Concern | User-story | Artifact |
|---------|-----------|----------|
| CRLF safety on Windows checkout (`.gitattributes`) | S000077 | S000077_crlf_safety/S000077_TRACKER.md |
| Portable date math + widened OS gate (runs on WSL2) | S000078 | S000078_portable_posix_runtime/S000078_TRACKER.md |
| Symlink-free copy-mode install + manifest schema (runs on Git Bash) | S000079 | S000079_symlink_free_install/S000079_TRACKER.md |
| `windows-latest` CI job + Windows docs | S000080 | S000080_windows_ci_and_docs/S000080_TRACKER.md |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Target WSL2 + Git Bash (POSIX layers), not native cmd/PowerShell | Claude Code runs skill bash preambles via Git Bash/WSL regardless; native would mean reimplementing 42 scripts and still wouldn't satisfy the preambles. `work-copilot/` (Python) already serves non-bash consumers. |
| 2 | bash stays the implementation language | Portability via portable date + widened gate + capability-probed install is far cheaper than a PowerShell port and keeps one codebase. |
| 3 | Inline `date_to_epoch` into the two skill scripts (not shared via `lib.sh`) | Deployed skill scripts under `~/.claude/skills/` install by symlinking `*.md`/`*.json` only; `scripts/` is not deployed, so they cannot source `lib.sh` at runtime. |
| 4 | Capability-probe symlink-mode (macOS/WSL2/Linux) vs copy-mode (Git Bash) for install | Preserves the maintainer's instant-edit dev loop on macOS while making Git Bash work; copy-mode needs a NEW manifest schema (`install_kind` + per-file `source_checksum`) because skills currently store no checksum. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| S000079 touches the install path (skills-deploy) — a bad copy-mode change could break macOS installs | test-deploy.sh must cover both modes before S000079 lands |
| macOS install semantics: keep symlink-mode default, or unify on copy-mode everywhere? | Decide in S000079 SPEC (design assumes keep symlinks) |
| CI: Git Bash job only, or also a WSL2 job? | Decide in S000080 (Git Bash is built into windows-latest; WSL2 needs a marketplace action) |
| `skills-deploy doctor` on Git-Bash-without-symlink: hard-fail or warn under copy-mode? | Decide in S000079 |

## Definition of done

- [ ] `./scripts/test.sh` green on macOS AND on Git Bash (windows-latest CI); new Darwin-gated-path tests green on ubuntu-latest
- [ ] Fresh Windows clone checks out `*.sh` with LF (no shebang breakage)
- [ ] `skills-deploy install` + `doctor` succeed on Git Bash (copy-mode) and WSL2 (symlink-mode)
- [ ] `CJ_suggest` + `CJ_improve-queue` run (not refuse) on WSL2 + Git Bash with correct date math

## Not in scope

- Native cmd/PowerShell support — rejected (parallel reimplementation; preambles still need bash)
- Non-Windows OSes beyond incidental Linux/WSL2 coverage
- `${TMPDIR:-/tmp}` parameterization of the hardcoded `/tmp/` lockfiles — deferred; `/tmp` works on both WSL2 + Git Bash and changing the daily lockfile path churns the drain-one-todo tests for no functional gain

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000044_TRACKER.md](F000044_TRACKER.md)
- Roadmap: [F000044_ROADMAP.md](F000044_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260603-233220.md`
