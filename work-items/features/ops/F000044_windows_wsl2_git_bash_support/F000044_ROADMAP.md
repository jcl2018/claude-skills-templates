---
type: roadmap
parent: F000044
title: "Windows (WSL2 + Git Bash) support for the skills workbench — Roadmap"
date: 2026-06-03
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap: scope/non-goals, decomposition, delivery timeline. -->

## Scope

Make the macOS-only skills workbench run on Windows through its two realistic POSIX layers — WSL2 (primary) and Git Bash — without rewriting any bash into PowerShell. Delivered as four user-stories: CRLF-safe checkout, a portable runtime (date math + widened OS gate), a symlink-free install path, and CI + docs that prove and document the support.

## Non-Goals

- Native cmd/PowerShell support — Claude Code runs skill bash preambles via Git Bash/WSL anyway; a PowerShell port would duplicate the whole codebase. Excluded.
- Non-Windows OS targets beyond incidental Linux/WSL2 coverage — out of scope for this feature.
- `${TMPDIR:-/tmp}` parameterization of hardcoded `/tmp/` lockfiles — `/tmp` works on both WSL2 + Git Bash; deferred to avoid churning drain-one-todo tests for no functional gain.

## Success Criteria

- [ ] `./scripts/test.sh` green on macOS AND on Git Bash (windows-latest CI); new Darwin-gated-path tests green on ubuntu-latest
- [ ] Fresh Windows clone checks out `*.sh` with LF (no shebang breakage)
- [ ] `skills-deploy install` + `doctor` succeed on Git Bash (copy-mode) and WSL2 (symlink-mode)
- [ ] `CJ_suggest` + `CJ_improve-queue` run (not refuse) on WSL2 + Git Bash with correct date math

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000077](S000077_crlf_safety/S000077_TRACKER.md) | CRLF safety (.gitattributes) | Open |
| [S000078](S000078_portable_posix_runtime/S000078_TRACKER.md) | Portable POSIX runtime (date + OS gate) | Open |
| [S000079](S000079_symlink_free_install/S000079_TRACKER.md) | Symlink-free copy-mode install | Open |
| [S000080](S000080_windows_ci_and_docs/S000080_TRACKER.md) | Windows CI job + docs | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000077 (CRLF safety) | — | Not Started | chjiang | Smallest, lowest risk; unblocks Windows checkout | — |
| 2 | Ship S000078 (portable runtime, WSL2) | — | Not Started | chjiang | "Runs on WSL2" | #1 |
| 3 | Ship S000079 (symlink-free install, Git Bash) | — | Not Started | chjiang | The L-effort risk item; land only after test-deploy covers both modes | #1 |
| 4 | Ship S000080 (CI + docs) | — | Not Started | chjiang | Proves + documents the support | #2, #3 |
| 5 | End-to-end: fresh Windows clone → install → both skills run | — | Not Started | chjiang | Feature acceptance | #4 |

### Delivery History

<!-- Append-only record of what shipped when. -->

- (none yet)

## Dependency Graph

<!-- #N blocks #M. -->

```
#1 CRLF safety (S000077)
   ├─> #2 portable runtime / WSL2 (S000078) ──┐
   └─> #3 symlink-free install / Git Bash (S000079) ──┐
                                                       ├─> #4 CI + docs (S000080) ──> #5 E2E Windows acceptance
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Keep symlink-mode default on macOS, or unify on copy-mode everywhere? | S000079 SPEC (design assumes keep symlinks) |
| Add a WSL2 CI job in addition to the Git Bash one? | S000080 |
| `skills-deploy doctor` under copy-mode: hard-fail or warn when symlinks unavailable? | S000079 |
