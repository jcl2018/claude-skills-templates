---
type: design
parent: S000032
title: "/wc-scaffold — design-doc → work-item directory tree — Story Design"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
reviewers: []
---

## Problem

The Copilot side has no analog to `/CJ_scaffold-work-item`. Users at the company hand-craft work-item directory trees, miss required artifacts, or skip the design-doc step entirely. `/wc-scaffold` ports the Claude-side pattern (read design doc → ID picker → template fill-in → boundary validate) to Copilot's constraints (no shell, no AUQ).

The keystone constraint is the **design-doc-required invariant**: every tracker must root back to a `receipts.investigate` block. Without this, `/wc-pipeline`'s drift math chain has no starting node.

## Shape of the solution

`work-copilot/prompts/scaffold.prompt.md` (`mode: agent`, `tools: [codebase, search, searchResults, editFiles]`). Eight steps: (1) read design-doc frontmatter (idempotency check), (2) read manifest + templates, (3) pick next ID per type, (4) write directory tree, (5) call `/validate`, (6) copy `receipts.investigate` into new tracker, (7) write `receipts.scaffold`, (8) update design-doc `status:` and `scaffolded_to:`.

Idempotency: if design-doc frontmatter says `status: SCAFFOLDED` and `scaffolded_to:` points to an existing directory, NO-OP.

Hand-authored fallback: if a user wants to scaffold without /wc-investigate, they hand-author a stub `.github/work-copilot/designs/<slug>.md` with `status: APPROVED`, `work_item_type: <type>`, and a minimal `receipts.investigate` block (`outputs: { proposed_type: <type>, scope_summary: "hand-authored" }`).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Idempotency via design-doc YAML frontmatter (not footer line) | Frontmatter is structured; a footer is brittle to manual edits. The Claude-side `/CJ_scaffold-work-item` uses a footer for historical reasons; this prompt does it cleaner. |
| 2 | Design-doc-required invariant | Without this, /wc-pipeline can't root drift math. Hand-authored stubs allowed but the receipt block is mandatory. |
| 3 | `pending_commit: true` in receipts.scaffold | Step 7 writes the receipt before the user can commit the new directory (which is the very thing they're scaffolding). The flag flips to false on first `/wc-implement` run when the user confirms via paste that the scaffold commit landed. |
| 4 | ID picker via grep over existing `work-items/` | Matches the Claude-side pattern. PR-claim check (queue-collision detection) is harder without `gh` in shell; V1 punts to local-only and relies on /CJ_personal-workflow check at boundaries. V2 could add a user-paste pattern for `gh pr list`. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Two parallel worktrees both scaffold to the same ID (PR-claim collision) — V1 has no `gh pr list` access. | Document as a known limitation in the prompt; suggest re-running `/wc-pipeline` post-scaffold to spot collisions. V2 candidate: user-paste pattern for `gh pr list`. |
| The user invokes `/wc-scaffold` on a design-doc that lacks the required frontmatter (legacy /office-hours output, e.g.). | Spec says: error out with "design doc is missing required frontmatter (status, work_item_type, receipts.investigate); hand-author or re-run /wc-investigate." |

## Definition of done

- [ ] Prompt file authored and byte-checked into `work-copilot/prompts/scaffold.prompt.md`.
- [ ] Idempotency NO-OP path verified against a previously-scaffolded design-doc.
- [ ] Design-doc-required invariant verified: invoke with a no-frontmatter file → clear error.
- [ ] Full happy-path scaffold against a fixture design-doc produces a valid work-item tree + receipt.

## Not in scope

- PR-claim queue-collision detection (V2).
- Cross-repo scaffold (single-repo V1 only).
- Auto-scaffolding multiple work items in one call.

## Pointers

- Parent tracker: [../F000015_TRACKER.md](../F000015_TRACKER.md)
- Parent design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Story tracker: [S000032_TRACKER.md](S000032_TRACKER.md)
- Spec: [S000032_SPEC.md](S000032_SPEC.md)
- Test spec: [S000032_TEST-SPEC.md](S000032_TEST-SPEC.md)
- Mental model: `skills/CJ_scaffold-work-item/SKILL.md` + `scaffold.md` (Claude-side analog)
