---
type: design
parent: F000044
title: "Windows CI job + docs — Feature Design"
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

Without Windows CI, the new Windows support rots silently. CI today is
`.github/workflows/validate.yml` + `.github/workflows/eval-nightly.yml`, both on
`ubuntu-latest` — no Windows coverage. There is also no "Running on Windows"
documentation. This story proves the support (a `windows-latest` job running the
relevant test subset) and documents it (README + CLAUDE.md). See parent
F000044_DESIGN.md for the full problem statement.

## Shape of the solution

Add a Windows CI job + write the Windows docs. A new `windows-latest` job (in
`validate.yml` or a new `.github/workflows/windows.yml`) with `shell: bash` (Git
Bash is built into `windows-latest`) runs a Windows-relevant test subset
(portable-date from S000078 + copy-mode-install from S000079), not the full
macOS/Linux suite. Docs: a README "Running on Windows" section + a CLAUDE.md
note. See parent F000044_DESIGN.md `## Shape of the solution`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Dedicated `windows.yml` job over a matrix axis in `validate.yml` | The Windows test subset differs from the full suite, so a dedicated job is cleaner. See parent F000044_DESIGN.md. |
| 2 | Target Git Bash on `windows-latest`; defer a WSL2 CI job | Git Bash is built into `windows-latest`; WSL2 needs a marketplace action. See parent F000044_DESIGN.md. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Add a WSL2 CI job in addition to Git Bash? | Resolve during S000080 implement. See parent for the full risk table. |

## Definition of done

- [ ] A green `windows-latest` job runs the portable-date + copy-mode-install subset under Git Bash; CI fails on Windows regression; README has a "Running on Windows" section; CLAUDE.md notes Windows support. See parent F000044_DESIGN.md `## Definition of done`.

## Not in scope

- A WSL2 CI job — deferred (needs a marketplace action); the Git Bash job is the Windows signal. See parent F000044_DESIGN.md `## Not in scope` for the full boundary.
- Running the full suite on Windows — only the subset runs on `windows-latest`.

## Pointers

- Parent feature design: [../F000044_DESIGN.md](../F000044_DESIGN.md)
- Parent tracker: [../F000044_TRACKER.md](../F000044_TRACKER.md)
- Story tracker: [S000080_TRACKER.md](S000080_TRACKER.md)
- SPEC: [S000080_SPEC.md](S000080_SPEC.md)
- TEST-SPEC: [S000080_TEST-SPEC.md](S000080_TEST-SPEC.md)
