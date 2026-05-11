---
type: design
parent: S000035
title: "/wc-pipeline — status compiler / drift math — Story Design"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
reviewers: []
---

## Problem

The pipeline ships only as much value as the diagnostic over its receipts. Without `/wc-pipeline`, users see receipts in tracker frontmatter but have no synthesized view of "what's stale, what's missing, what's next." `/wc-pipeline` is the status compiler — read-only over receipts and `.git/HEAD`, printing drift math: Missing / Stale / Coverage holes / Diff audit / Ship-not-opened / Next legal.

## Shape of the solution

`work-copilot/prompts/pipeline.prompt.md` (`mode: agent`, `tools: [codebase, search, searchResults]` — **no editFiles**, read-only). Four steps: (1) read receipts (tracker frontmatter OR design-doc frontmatter based on input), (2) read `.git/HEAD` via `codebase` tool, (3) compute drift math (5 rules), (4) print a fixed-format status block.

Two input modes:

- **Work-item path** (full multi-phase drift math).
- **Design-doc path** (frontmatter status: DRAFT/APPROVED/SCAFFOLDED + next-legal suggestion).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Binary stale check (no commit count) | `git log` requires shell; `.git/HEAD` read via `codebase` gives string-compare only. Print the binary signal + the exact `git log` command user could run for a count — user-paste pattern as documentation, not runtime. |
| 2 | `pr_opened` keying for ship drift | URL can be pasted without flag flip; flag is unambiguous. |
| 3 | 24h timeout on ship-not-opened drift | Gives user reasonable time to manually open PR; shorter = noisy, longer = missed. |
| 4 | Tolerate degenerate review-type receipts | Empty `files_touched`, `commits_since_scaffold`, `ac_ids_targeted` are valid for review type. Don't flag as drifted. |
| 5 | Read-only — no editFiles tool | Status compiler MUST be a printer, not a macro. Prevents accidental state mutations from a diagnostic call. Encoded in the prompt's `tools:` array. |
| 6 | Two-mode input (work-item path OR design-doc path) | A design-doc that hasn't been scaffolded yet still has receipts.investigate; /wc-pipeline should report its state too. Switches based on input path's frontmatter type. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Receipts schema evolves but /wc-pipeline expects V1 — how does it degrade? | V1: ignore unknown fields, error out on missing required fields with "receipt schema V<N> not supported; upgrade /wc-pipeline." V2 candidate: versioned schema header. |
| 24h ship-not-opened threshold is arbitrary. Should it be configurable? | V1: hardcoded 24h. V2 candidate: env var or per-repo config. |
| Tracker frontmatter has multiple receipts (qa re-run) — pick the most recent? | V1 spec says receipts are overwrite-per-phase (not append), so the question is moot for V1; revisit if append-mode is added in V2. |

## Definition of done

- [ ] Prompt file authored, byte-checked into `work-copilot/prompts/pipeline.prompt.md`.
- [ ] Drifted fixture work-item at `work-copilot/fixtures/drifted-feature-dir/` built; all 5 drift signals fire on it.
- [ ] Manual exercise: invoke `/wc-pipeline` on the drifted fixture; verify each drift signal in the printed status block.

## Not in scope

- Auto-fixing drifts (status compiler is read-only; fixes are upstream prompts' job).
- Cross-work-item drift (e.g., one feature with 6 children — V1 prints one work-item at a time; V2 candidate for multi-work-item reports).
- Trend tracking (drift over time) — V2 candidate.

## Pointers

- Parent tracker: [../F000015_TRACKER.md](../F000015_TRACKER.md)
- Parent design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Story tracker: [S000035_TRACKER.md](S000035_TRACKER.md)
- Spec: [S000035_SPEC.md](S000035_SPEC.md)
- Test spec: [S000035_TEST-SPEC.md](S000035_TEST-SPEC.md)
- Mental model: read-only status compiler reading receipts written by S000030–S000034.
- Receipt sources: S000030 (qa), S000031 (implement), S000032 (scaffold), S000033 (investigate), S000034 (ship).
