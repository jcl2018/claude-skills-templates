---
type: design
parent: F000044
title: "Symlink-free copy-mode install — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- Atomic story. This DESIGN.md is a brief stub; the full problem shape,
     big decisions, and rejected alternatives live in the parent feature's
     design. See parent F000044_DESIGN.md for context. -->

## Problem

`scripts/skills-deploy` installs skills by symlinking `*.md`/`*.json` into
`~/.claude/` (`ln -snf`); `doctor` asserts `[ -L ]`, and `remove`/`relink`
assume symlinks too. On Git Bash, `ln -s` copies-by-default (or needs Developer
Mode/admin), so install degrades and `doctor` reports false failures. See parent
F000044_DESIGN.md for the full Windows/WSL2/Git-Bash problem statement.

## Shape of the solution

Probe symlink capability at install time (`_can_symlink()`), pick an install
mode (symlink on macOS/WSL2/Linux, copy on Git Bash), record the mode plus a
per-file `source_checksum` in the runtime manifest, and branch
`doctor`/`remove`/`relink` on the recorded mode. See parent F000044_DESIGN.md
`## Shape of the solution`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Symlink on capable platforms, copy on Git Bash (mode chosen by a runtime probe) | Keeps the maintainer's instant-edit dev loop on macOS/WSL2 while making Git Bash work. See parent F000044_DESIGN.md. |
| 2 | New manifest fields `install_kind` + per-file `source_checksum` (copy-mode) | Skills store NO checksum today (only templates/rules do), so copy-mode doctor has nothing to verify against without a schema bump. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Real Git-Bash `ln -s`-copies behavior cannot be exercised on macOS CI | windows-latest CI (S000080) is the live check; locally only the capability probe is unit-tested. See parent for the full risk table. |
| doctor under copy-mode: hard-fail or warn when a copy drifts from source? | Resolve during S000079 implement. |

## Definition of done

- [ ] install + doctor succeed in both symlink-mode and copy-mode; manifest carries `install_kind` + per-file `source_checksum` for copies; remove/relink branch on mode; test-deploy.sh covers both modes + a doctor case each. See parent F000044_DESIGN.md `## Definition of done`.

## Not in scope

- Concurrent install races — accepted, not handled. See parent F000044_DESIGN.md `## Not in scope` for the full boundary.
- Unifying macOS on copy-mode too — open question in the parent design; default is to keep symlinks.

## Pointers

- Parent feature design: [../F000044_DESIGN.md](../F000044_DESIGN.md)
- Parent tracker: [../F000044_TRACKER.md](../F000044_TRACKER.md)
- Story tracker: [S000079_TRACKER.md](S000079_TRACKER.md)
- SPEC: [S000079_SPEC.md](S000079_SPEC.md)
- TEST-SPEC: [S000079_TEST-SPEC.md](S000079_TEST-SPEC.md)
