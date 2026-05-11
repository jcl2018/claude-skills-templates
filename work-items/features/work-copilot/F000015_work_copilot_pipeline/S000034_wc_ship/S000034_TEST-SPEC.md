---
type: test-spec
parent: S000034
feature: F000015
title: "/wc-ship — Test Specification"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
spec: S000034_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `ship.prompt.md` exists with correct `tools:` array | Prompt installed | `test -f work-copilot/prompts/ship.prompt.md && grep -q "tools:" work-copilot/prompts/ship.prompt.md` |
| S2 | core | AC-5 | Prompt documents receipts.ship schema with pr_opened: false default | Schema correct | `grep -q "pr_opened: false" work-copilot/prompts/ship.prompt.md && grep -q "pr_url: null" work-copilot/prompts/ship.prompt.md` |
| S3 | resilience | AC-6 | Warn-and-write language for Working-Tree Rule | Warn not hard-stop | `grep -q "warning" work-copilot/prompts/ship.prompt.md && grep -q "git status --porcelain" work-copilot/prompts/ship.prompt.md && ! grep -q "commit those files first.*ship" work-copilot/prompts/ship.prompt.md` |
| S4 | core | AC-3 | Prompt mentions receipts.qa and receipts.implement as synthesis inputs | Synthesis sources documented | `grep -q "receipts.qa" work-copilot/prompts/ship.prompt.md && grep -q "receipts.implement" work-copilot/prompts/ship.prompt.md` |
| S5 | usability | AC-7 | Post-ship instructions present | User reminded to flip pr_opened | `grep -q "After opening the PR" work-copilot/prompts/ship.prompt.md && grep -q "pr_opened: true" work-copilot/prompts/ship.prompt.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1,2,3,4,5 | Happy-path ship on a defect with full receipts | (1) Use a fixture defect with complete receipts.implement and receipts.qa. (2) Open Copilot Chat. (3) Invoke `/wc-ship <fixture-defect>`. (4) See /validate pass. (5) See PR description printed in chat. (6) See PR-DESCRIPTION.md written. (7) Paste clean `git status --porcelain`. | (a) PR description has all 5 sections (summary, what changed, ACs, risks, tracker link). (b) PR-DESCRIPTION.md file exists in work-item dir. (c) Tracker frontmatter gains receipts.ship with pr_opened: false. | All sections present; PR-DESCRIPTION.md parses; receipts.ship schema correct. |
| E2 | resilience | AC-6 | Working-Tree Rule warn (not hard-stop) | (1) Edit a fixture file without committing. (2) Invoke `/wc-ship` on a fixture with receipts.qa and receipts.implement. (3) Paste dirty `git status --porcelain`. | Prompt prints warning ("Note: PR description was synthesized from an unpushed working tree...") AND proceeds to write receipts.ship. | Warning shown; receipts.ship still written; user has the PR description. |
| E3 | usability | AC-7 | Post-ship instructions printed | After E1 or E2, check chat output. | Chat ends with "After opening the PR on GitHub, edit this tracker's receipts.ship: flip pr_opened: true and fill pr_url with the PR URL." | Exact-or-similar string present in chat. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Multi-commit summarization | V1 lists all commits; summarization is V2. | Large work-items might produce verbose PR descriptions; risk: clipboard truncation. Acceptable; user can edit. |
| /wc-ship on user-story (vs defect/task) | V1 spec says user-stories ship via task children; /wc-ship on a standalone user-story is an edge case. | If a user-story has no task children, /wc-ship will still synthesize but with a less-tailored template. Spec covers this in AC-2. |
| Stale PRD detection | Explicitly out of scope; /wc-pipeline handles this. | /wc-ship synthesizes against whatever PRD is present; staleness is the orchestrator's concern. |
