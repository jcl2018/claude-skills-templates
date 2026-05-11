---
type: design
parent: S000031
title: "/wc-implement — implement from spec (per-type dispatch) — Story Design"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
reviewers: []
---

## Problem

Copilot users need an implement-from-spec walkthrough that reads the right input artifacts per work-item type (PRD/ARCHITECTURE for user-story, RCA/test-plan for defect, etc.), proposes a plan, edits code with explicit user confirmation, and writes a `receipts.implement` block that `/wc-qa` and `/wc-pipeline` can read. This is the Copilot analog of `/CJ_implement-from-spec` (Claude side), adapted to Copilot's no-AUQ, no-shell constraints.

## Shape of the solution

`work-copilot/prompts/implement.prompt.md` (`mode: agent`, `tools: [codebase, search, searchResults, findTestFiles, editFiles]`). Six main steps: (1) `/validate`, (2) per-type input dispatch over 5 tracker `type:` values, (3) walkthrough-mode plan + edits, (4) user-paste pattern for `git rev-parse HEAD` and `git log --oneline <scaffold_sha>..HEAD`, (5) Working-Tree Rule paste pattern (hard-stop), (6) read-whole-parse-merge-write the `receipts.implement` block.

Per-type input dispatch:

| Tracker `type:` | Inputs read |
|---|---|
| user-story | PRD.md + ARCHITECTURE.md + TEST-SPEC.md |
| defect | RCA.md + test-plan.md |
| task | TRACKER.md + test-plan.md |
| feature | feature-summary + DESIGN + milestones; if multi-story, prompts user in chat to pick a child user-story and delegates |
| review | review-notes; behavior is walk-through reading + action; receipt is **degenerate** (empty arrays + 1-line open_risks summary) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Walkthrough mode only (no --auto) | Copilot has no AUQ, no shell. Walkthrough chat is the safest UX for V1. Parent /CJ_implement-from-spec has --auto; we deliberately omit it. |
| 2 | Per-type dispatch over 5 types | Mirrors /CJ_implement-from-spec's per-type input contract. The "review" type is degenerate (empty arrays); spec the shape explicitly so /wc-pipeline tolerates it. |
| 3 | Capture `latest_sha_at_implement` via user-paste of `git rev-parse HEAD` | Locked by the user-paste-pattern decision in the parent feature. |
| 4 | Working-Tree Rule hard-stop | Same reasoning as /wc-qa: drift math depends on receipts reflecting what's in git. |
| 5 | Read whole tracker, parse YAML, merge, write whole tracker back | Same YAML-edit pattern as /wc-qa and other receipt-writing prompts; precedent: `validate.prompt.md`. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| User pastes a `git log` output with extra noise (release notes from CHANGELOG-like commits, etc.). Prompt should be tolerant. | Test with a realistic fixture during exercise. |
| Feature-type input dispatch — when "feature" is the type, the prompt delegates to a child story. How is the child story chosen? | Plain-chat prompt: "This is a feature with N child stories. Which child should I implement now?" Lock during exercise. |

## Definition of done

- [ ] Prompt file authored, byte-checked into `work-copilot/prompts/implement.prompt.md`.
- [ ] Per-type dispatch exercised on at least 3 of 5 types (user-story, defect, review minimum); confirm receipt schema parses for each.
- [ ] Walkthrough mode produces edit diffs that the user can review before commit; no surprise edits.

## Not in scope

- `--auto` flag — explicit V1 omission.
- Multi-file refactor automation — V1 is one edit per confirm cycle (Copilot's editFiles can batch, but the prompt should chunk for review).
- Cross-repo edits — V1 scoped to single-repo work items.

## Pointers

- Parent tracker: [../F000015_TRACKER.md](../F000015_TRACKER.md)
- Parent design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Story tracker: [S000031_TRACKER.md](S000031_TRACKER.md)
- Spec: [S000031_SPEC.md](S000031_SPEC.md)
- Test spec: [S000031_TEST-SPEC.md](S000031_TEST-SPEC.md)
- Mental model: `skills/CJ_implement-from-spec/SKILL.md` (Claude-side analog)
- Schema source: S000030 receipts.qa contract — S000031 conforms to it for `receipts.implement`.
