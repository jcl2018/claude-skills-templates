---
type: design
parent: F000044
title: "CRLF safety (.gitattributes) — Feature Design"
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

A fresh clone on Git-for-Windows (default `core.autocrlf=true`) rewrites all 42
tracked `*.sh` files to CRLF on checkout, so `#!/usr/bin/env bash\r` becomes a
bad interpreter and bash hits parse errors on every line. The repo has no
`.gitattributes` today, so Windows devs cannot run any script. See parent
F000044_DESIGN.md `## Problem`.

## Shape of the solution

Add a single `.gitattributes` at the repo root that forces LF on text files
repo-wide (`* text=auto eol=lf`), with explicit coverage for the two
extensionless entrypoint scripts and binary markers so images are never
EOL-munged. One config file controls checkout line endings repo-wide. See
parent F000044_DESIGN.md `## Shape of the solution`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `* text=auto eol=lf` (force LF for all text) over a per-extension allowlist | The repo is bash-heavy with no CRLF-required files; force-LF is the simplest correct policy. |
| 2 | Build on `scripts/lib.sh`'s existing `jq()` CRLF shim rather than duplicate it | The shim normalizes runtime jq OUTPUT — a different layer. This story fixes checked-out SOURCE endings; the two compose. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Any file that legitimately needs CRLF endings? (none known) | Resolve during S000077 implement before `.gitattributes` lands. |

## Definition of done

- [ ] `.gitattributes` forces LF on `*.sh`/`*.py` + the two extensionless scripts; binaries marked binary; one-time `git add --renormalize .` documented. See parent F000044_DESIGN.md `## Definition of done`.

## Not in scope

- Portable date math + widened OS gate (S000078), symlink-free install (S000079), and `windows-latest` CI (S000080). See parent F000044_DESIGN.md `## Not in scope` for the full boundary.

## Pointers

- Parent feature design: [../F000044_DESIGN.md](../F000044_DESIGN.md)
- Parent tracker: [../F000044_TRACKER.md](../F000044_TRACKER.md)
- Story tracker: [S000077_TRACKER.md](S000077_TRACKER.md)
- SPEC: [S000077_SPEC.md](S000077_SPEC.md)
- TEST-SPEC: [S000077_TEST-SPEC.md](S000077_TEST-SPEC.md)
