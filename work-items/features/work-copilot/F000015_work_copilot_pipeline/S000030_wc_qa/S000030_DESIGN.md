---
type: design
parent: S000030
title: "/wc-qa — QA walkthrough + receipt-schema lock — Story Design"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
reviewers: []
---

## Problem

The pipeline has six phase commands; five of them write receipts and one (`/wc-pipeline`) reads them. If `/wc-implement` writes a receipt shape that `/wc-qa` and `/wc-pipeline` later disagree with, the orchestrator becomes theater — printing diagnostics against a contract no command actually honors. Building `/wc-qa` first, against the real pain (drift math + uncovered ACs + Working-Tree Rule), locks the receipt schema before any downstream prompt is written. Codex's exact build-order pick.

## Shape of the solution

Single new file: `work-copilot/prompts/qa.prompt.md` with `mode: agent` and `tools: [codebase, search, searchResults, findTestFiles, editFiles]`. The prompt walks the user through 9 steps (see SPEC.md Requirements P0). At the end of the run, it writes `receipts.qa` to the tracker's YAML frontmatter via the "read whole tracker, parse YAML, merge new block, write whole tracker" pattern (precedent: existing `work-copilot/prompts/validate.prompt.md`).

Fixture extension: the existing `work-copilot/fixtures/valid-feature-dir/` gets enough material that `/wc-qa` exercises the uncovered-AC and changed-files-without-tests diagnostics on day 1.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Build /wc-qa first to lock the receipt schema | Codex's bottom-up build order: receipts are the cross-prompt contract; lock the contract before writing the prompts that produce it. Alternative (top-down, B): /scaffold and /implement guess at receipts. |
| 2 | Working-Tree Rule UX: hard-stop for /wc-qa | The drift-math premise is "receipts reflect what's in git." If the user wrote receipts while uncommitted, the next `/wc-pipeline` call lies. Hard-stop "commit first, then re-invoke" keeps drift math honest. |
| 3 | First-run fallback to `receipts.scaffold` SHA | When no prior `[qa-*]` journal entry exists, the diff-audit step needs a baseline SHA. Using `receipts.scaffold.completed_at`'s associated SHA (recorded in receipts.scaffold) is deterministic and lets /wc-pipeline cross-check the timeline later. Rejected alternative: `HEAD~N` — N is fuzzy. |
| 4 | "Read whole tracker, parse, merge, write whole tracker" YAML edit pattern | Surgical YAML edits from a Copilot prompt are unreliable. Precedent: `validate.prompt.md` already follows this. State it explicitly in /wc-qa so Copilot doesn't attempt a partial edit. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| User pastes garbage from `git log --name-only`; prompt should be tolerant. | Test with a malformed paste during fixture exercise; spec a recovery path ("If output looks empty or malformed, please re-run and paste again"). |
| Tracker frontmatter parse fails on malformed YAML left by a previous edit. | The prompt should detect parse failure and abort with a clear message; no silent corruption. Spec covers this in P0 row #6. |

## Definition of done

- [ ] Prompt file authored, byte-checked into `work-copilot/prompts/qa.prompt.md`.
- [ ] Fixture extended; `/wc-qa` on the fixture produces a valid `receipts.qa` block.
- [ ] Smoke check in /CJ_personal-workflow check passes on the new file (presence + frontmatter shape).

## Not in scope

- Implement /wc-implement (S000031) — separate story; this one only locks the contract.
- Automating `git log` execution — the user-paste pattern is the explicit V1 decision.
- Schema versioning — V1 ships exactly one schema version; if V2 adds fields, that's a separate story.

## Pointers

- Parent tracker: [../F000015_TRACKER.md](../F000015_TRACKER.md)
- Parent design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Story tracker: [S000030_TRACKER.md](S000030_TRACKER.md)
- Spec: [S000030_SPEC.md](S000030_SPEC.md)
- Test spec: [S000030_TEST-SPEC.md](S000030_TEST-SPEC.md)
- Precedent prompt: `work-copilot/prompts/validate.prompt.md`
