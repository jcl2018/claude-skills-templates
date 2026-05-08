---
type: design
parent: S000020
title: "Phase 3 gate auto-update — engine + post-merge hook — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Atomic story stub. The parent F000011_DESIGN.md is the primary context. -->

## Problem

Phase 3 lifecycle gates stay UNCHECKED after every `/ship` + `/land-and-deploy` cycle. Today's session shipped 4 PRs and all 4 work-item trackers carry stale Phase 3 state. Manual updates are unmemorable. See parent: [F000011_DESIGN.md](../F000011_DESIGN.md).

## Shape of the solution

Engine: `--update` flag on `/personal-workflow check`. Reads external state, writes `[x]` to inferable Phase 3 gates, never marks `E2E walked manually`. Hook: `scripts/post-merge-hook.sh` fires on `git pull` to main, scans incoming commits for touched work-item dirs, runs `--update` on each.

## Big decisions

- Engine is a flag, not a new skill. Keeps surface small.
- Hook fires on `git pull` only. Web UI / cross-machine merges accept the gap.
- `E2E walked manually` is explicit-excluded from auto-marking.

## Risks & open questions

- `gh` offline → engine falls back to partial inference (skip PR-state-dependent gates, just re-run check structurally).
- Coincidence over-marking on `/document-release` gate signal — accepted as low-risk.
- Multi-level child recursion deferred to v2.

## Definition of done

After ship + merge + `git pull main`, all 6 Phase 3 gates EXCEPT `E2E walked manually` auto-update on the touched work-item. Re-running is a NO-OP. See parent F000011_DESIGN.md for full Definition of Done.

## Not in scope

- `E2E walked manually` auto-detection
- Cross-machine merge coverage
- Upstream gstack contributions
- Multi-level child recursion

## Pointers

- Parent F000011_DESIGN.md
- Source /office-hours design doc: [../../../../.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-phase3-gate-autoupdate-design-20260508-165047.md](../../../../.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-phase3-gate-autoupdate-design-20260508-165047.md)
- Existing skills/personal-workflow/check.md (engine target)
- Existing scripts/setup-hooks.sh (hook installer target)
