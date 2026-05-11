---
type: design
parent: S000034
title: "/wc-ship — PR description synthesis — Story Design"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
reviewers: []
---

## Problem

Copilot users need a prompt that synthesizes a high-quality PR description from the work-item's accumulated state (tracker journal, `receipts.qa` AC coverage, `receipts.implement.commits_since_scaffold`) and writes a `receipts.ship` block so `/wc-pipeline` can spot "ship printed but PR not opened" drift. The prompt does NOT push or open a PR — users do that manually on GitHub and then flip `receipts.ship.pr_opened: true`.

## Shape of the solution

`work-copilot/prompts/ship.prompt.md` (`mode: agent`, `tools: [codebase, search, searchResults, editFiles]`). Five steps: (1) `/validate`, (2) read tracker + PRD/RCA + PR-DESCRIPTION template, (3) synthesize PR description, (4) print to chat + optionally write to `PR-DESCRIPTION.md`, (5) write `receipts.ship` with `pr_opened: false`.

Working-Tree Rule is warn-and-write for `/wc-ship` (the only receipt-writing prompt that doesn't hard-stop). Reasoning: the synthesized PR description is useful even if the tree isn't pushed; the warning surfaces the risk.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Warn-and-write Working-Tree Rule | The PR description is a clipboard-paste artifact; useful even unpushed. Hard-stop would frustrate iterative workflows. |
| 2 | `pr_opened: false` default | The prompt can't know if a PR was opened (no shell, no API access). User flips manually; /wc-pipeline drift rule catches forgotten flips. |
| 3 | `pr_opened` as canonical truth (not `pr_url`) | URL can be pasted in a non-flipped state; flag is unambiguous. |
| 4 | Optionally write `PR-DESCRIPTION.md` to the work-item dir | Useful artifact for review history; "optionally" because some users prefer clipboard-only. Spec says: always write the file unless the user explicitly says "chat-only." |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Synthesizing a coherent PR description from a tracker journal that has incomplete or conflicting entries. | Test with a fixture work-item that has mixed-quality journal entries; document the "garbage-in, garbage-out" tradeoff in the prompt. |
| User opens PR but forgets to flip `pr_opened: true` — `/wc-pipeline` "ship printed but PR not opened" rule should catch this after 24h. | Verify the 24h timeout in S000035 spec; verify the user-facing message names the fix path clearly. |

## Definition of done

- [ ] Prompt file authored and byte-checked into `work-copilot/prompts/ship.prompt.md`.
- [ ] Manual smoke pass against a fixture with complete `receipts.qa` and `receipts.implement` produces a coherent PR description.
- [ ] `receipts.ship` writes correctly with `pr_opened: false`.

## Not in scope

- Auto-opening PR via GitHub API.
- Auto-pushing branch.
- Multi-PR coordination (mono-repo with multiple PRs from one work-item — V2 candidate).

## Pointers

- Parent tracker: [../F000015_TRACKER.md](../F000015_TRACKER.md)
- Parent design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Story tracker: [S000034_TRACKER.md](S000034_TRACKER.md)
- Spec: [S000034_SPEC.md](S000034_SPEC.md)
- Test spec: [S000034_TEST-SPEC.md](S000034_TEST-SPEC.md)
- Receipts chain: receipts.implement (S000031) + receipts.qa (S000030) → receipts.ship (this story).
- Downstream: /wc-pipeline (S000035) reads `receipts.ship.pr_opened` for the drift rule.
