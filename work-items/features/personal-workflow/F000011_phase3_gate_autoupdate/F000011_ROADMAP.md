---
type: roadmap
parent: F000011
title: "Phase 3 lifecycle-gate auto-update via post-merge hook — Roadmap"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

## Scope

Build the inference engine (`/personal-workflow check --update`) + git post-merge hook trigger. v1 ships both pieces in one PR; they're co-dependent and ship together.

## Non-Goals

- `E2E walked manually` auto-detection (no external signal; v2)
- Web UI / cross-machine merge auto-trigger (hook is local-only; accepted gap)
- Upstream gstack /ship + /land-and-deploy modifications (option 4 from original TODO; deferred per P6)
- Multi-level child recursion (v1: one level only)
- `--mark-e2e` flag or other manual-acknowledgment helpers (v2 if needed)

## Success Criteria

- After ship + merge + `git pull main`, the touched work-item's Phase 3 gates that ARE inferable get marked `[x]` automatically.
- `E2E walked manually` stays `[ ]` (never auto-marked).
- A `[gates-update]` journal entry summarizes what changed.
- The `## PRs` section gets the merged PR link with status.
- Re-running `/personal-workflow check --update` is a no-op if state already converged.
- Existing `/personal-workflow check` (no `--update` flag) behavior is unchanged.
- Hook failures don't block git merges; print a warning and let user re-run manually.

## Decomposition

| ID | Slug | Scope | Phase |
|---|---|---|---|
| S000020 | implement_engine_and_hook | Engine (--update flag in check.md) + post-merge hook script + setup-hooks.sh wiring + tests | Implement |

Single user-story child since engine + hook ship together (engine is incomplete without trigger; hook is useless without engine).

## Delivery Timeline

| Step | Deliverable | Estimated effort |
|---|---|---|
| Ship S000020 | Engine + hook + tests + docs | M (4-5 hours of CC work) |
| End-to-end verification | Ship a small change, `git pull`, verify Phase 3 gates auto-update | S (15 min) |
| F000011 ship | PR with feature-level summary, all sub-work merged | S (handled by /ship) |

## Dependency Graph

```
F000011 (feature)
  │
  └── S000020 (engine + hook)
        │
        ├── modifies: skills/personal-workflow/check.md (--update flag, Steps 13.5-13.7)
        ├── creates:  scripts/post-merge-hook.sh
        ├── modifies: scripts/setup-hooks.sh (install post-merge hook)
        └── tests:    extend test-deploy.sh or similar to cover hook + engine
```

No external dependencies. `gh` CLI is already required by the workbench. Git ≥ 2.x is universal.

## Open Questions

- **Children recursion depth in v1?** Decision: 1 level (direct children only). Revisit if multi-level features ship and the limitation bites.
- **`/document-release` gate signal heuristic — over-mark risk?** Decision: v1 ships the heuristic; accept low-risk over-marking. v2 could add explicit signal (e.g., `[doc-release]` marker in the docs: commit message).
- **Hook ordering with existing pre-commit hook (D000007 era)?** Decision: post-merge runs after merge completes; pre-commit runs before commit. No collision; both can coexist in `setup-hooks.sh`.
