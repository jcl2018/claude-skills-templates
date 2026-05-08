---
type: design
parent: F000011
title: "Phase 3 lifecycle-gate auto-update via post-merge hook — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Distilled from /office-hours design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-phase3-gate-autoupdate-design-20260508-165047.md
     Premise check confirmed all 6 premises in-session before alternatives review. -->

## Problem

After every `/ship` + `/land-and-deploy` cycle, the work-item's Phase 3 lifecycle gates stay UNCHECKED. The workflow ran successfully — PR merged, CI green, deploy verified — but the tracker doesn't reflect any of it. Every PR shipped today (S000017, S000019, S000018, D000016) carries stale Phase 3 state. The "two manual steps" original framing was actually three; updating Phase 3 gates after ship is the third, and it's unmemorable in practice.

## Shape of the solution

Two pieces working together:

1. **Inference engine** — `/personal-workflow check --update <work-item-dir>` reads external state (`gh pr view`, `gh pr checks`, `git log`, child tracker recursion) and writes `[x]` to inferable Phase 3 gates. Idempotent and additive: never downgrades `[x]` → `[ ]`. The `E2E walked manually` gate is explicit-excluded — never auto-marked since it has no external signal.
2. **Trigger mechanism** — `scripts/post-merge-hook.sh` fires when `git pull` / `git merge` lands new commits on `main`. The hook detects work-item dirs touched by the incoming commits and invokes `/personal-workflow check --update` on each. Hook failures are best-effort (warn, don't block).

The combination satisfies P5 (auto-trigger): the user already runs `git pull` after every ship, and the hook piggybacks on that natural step.

## Big decisions

- **Engine + Hook combined, not separate.** Engine alone (option A from design) fails P5; hook alone is structurally impossible without the engine. Together they satisfy P5 without cross-machine complexity.
- **Local merge only.** Hook only fires when the user pulls main locally. Web UI / cross-machine merges miss the trigger. Accepted gap; user can run `--update` manually after a remote merge if needed. Cross-machine sync is a v2 problem.
- **`E2E walked manually` never auto-marked.** Contract: engine reflects verifiable reality. Human acknowledgment is not verifiable. v1 leaves the gate UNCHECKED unless the user edits manually.
- **Idempotent + additive only.** Engine writes `[x]` on positive signal; never downgrades. Re-running on already-converged state is a NO-OP. This avoids the "what if user manually unchecked" footgun.
- **Defer upstream gstack contributions** (option 4 from original TODO). Per P6, slow upstream loop. v1 ships local-side; if drift remains after v1, revisit option 4.

## Risks & open questions

- **`gh` offline / unauthenticated** — engine should fall back to partial inference (PR existence from git remote, structural check via /personal-workflow check itself). Document: don't fail on gh errors.
- **Multi-level features (feature → user-story → task)** — children inference recurses one level only in v1. Multi-level recursion is straightforward to add later if needed.
- **`/document-release` gate signal** — v1 heuristic: look for a `docs:` commit on main that touched paths the work-item modified. Could over-mark on coincidence; accepted as low-risk.
- **Hook scope: post-merge only, not post-checkout / post-rewrite** — post-merge handles `git pull` after ship; other hooks would re-fire on branch switches (unwanted).

## Definition of done

The 6 Phase 3 gates auto-update after a ship + merge + `git pull main`, except `E2E walked manually` (never auto-marked). A `[gates-update]` journal entry summarizes what changed. The `## PRs` section gets the merged PR link with status. Re-running is a NO-OP. Existing `/personal-workflow check` (no `--update` flag) behavior is unchanged.

## Not in scope

- `E2E walked manually` auto-detection (defer to v2, would need test-log file or `--mark-e2e` flag)
- Web UI / cross-machine merge coverage (accepted gap; user runs `--update` manually if needed)
- Upstream gstack /ship+/land-and-deploy modifications (option 4 from original TODO; deferred per P6)
- Auto-firing on `git fetch` (only `git pull` / `git merge` triggers; `git fetch` doesn't move main)
- Multi-level child recursion (v1: one level; revisit if multi-level features ship)

## Pointers

- Source /office-hours design doc: [chjiang-feat-phase3-gate-autoupdate-design-20260508-165047.md](../../../../.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-phase3-gate-autoupdate-design-20260508-165047.md)
- TODOS.md entry: "Phase 3 lifecycle-gate auto-update gap" (P2/M, captured 2026-05-08)
- Child user-story: [S000020_implement_engine_and_hook](S000020_implement_engine_and_hook/)
- Phase 2 gate ownership pairing precedent: S000018_implement_from_spec + S000019_qa_work_item (Phase 2 gates split). Phase 3 work follows the same auto-update pattern.
