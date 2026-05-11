---
type: test-spec
parent: S000032
feature: F000015
title: "/wc-scaffold — Test Specification"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
spec: S000032_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `scaffold.prompt.md` exists with correct `tools:` array | Prompt installed | `test -f work-copilot/prompts/scaffold.prompt.md && grep -q "tools:" work-copilot/prompts/scaffold.prompt.md` |
| S2 | core | AC-7 | Prompt body documents `receipts.scaffold` schema with `pending_commit: true` | Schema correct | `grep -q "pending_commit" work-copilot/prompts/scaffold.prompt.md && grep -q "validate_result" work-copilot/prompts/scaffold.prompt.md` |
| S3 | core | AC-2 | Design-doc-required invariant language present | Invariant documented | `grep -q "design doc is missing required frontmatter" work-copilot/prompts/scaffold.prompt.md` |
| S4 | core | AC-4 | All 5 work-item types referenced | Per-type dispatch present | `grep -E "(feature\|user-story\|task\|defect\|review)" work-copilot/prompts/scaffold.prompt.md \| wc -l` (expect ≥ 5) |
| S5 | core | AC-8 | Design-doc update language present | Lineage update | `grep -q "scaffolded_to" work-copilot/prompts/scaffold.prompt.md && grep -q "SCAFFOLDED" work-copilot/prompts/scaffold.prompt.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3,4,5,6,7,8 | Happy-path scaffold of a feature from a design-doc | (1) Hand-author a fixture design-doc with required frontmatter. (2) Invoke `/wc-scaffold <fixture-design>`. (3) Watch ID picker pick next F-prefix. (4) Watch directory tree written. (5) Watch /validate pass. (6) Check tracker frontmatter for receipts.investigate + receipts.scaffold. (7) Check design-doc updated. | (a) New dir at `work-items/features/<comp>/F000NNN_<slug>/` with TRACKER+DESIGN+ROADMAP. (b) Tracker has both receipts blocks. (c) Design-doc `status: SCAFFOLDED`, `scaffolded_to: <path>`. | All assertions pass; receipts parse as valid YAML; /validate reports PASS. |
| E2 | core | AC-1 | Idempotency NO-OP | (1) Run the same `/wc-scaffold` again on the just-scaffolded design-doc. | Prompt prints "Already scaffolded at <path>; nothing to do." | No file writes; clear NO-OP message. |
| E3 | core | AC-2 | Design-doc-required invariant fires | (1) Use a legacy design-doc (no frontmatter or partial frontmatter). (2) Invoke `/wc-scaffold`. | Prompt aborts with the missing-frontmatter error; no scaffolding. | No dir created; clear error message. |
| E4 | core | AC-5 | /validate gate catches a broken template | (1) Manually corrupt one of the templates Copilot reads. (2) Invoke `/wc-scaffold` on a valid design-doc. | After tree write, /validate reports DRIFT; prompt prints violations; design-doc is NOT marked SCAFFOLDED. | Design-doc status unchanged; clear validate error; new dir may exist but is flagged. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Multi-story decomposition E2E | V1 spec covers it (Spec Open Question), but full E2E test is deferred to a follow-up. | A multi-story feature scaffold might miss child IDs; risk: file follow-up after first real-world run. |
| PR-claim collision detection | V1 doesn't have it (gh pr list requires shell). | Two parallel worktrees could collide; mitigation: /wc-pipeline run post-scaffold can spot it. |
| Review-type scaffold | V1 spec covers it (AC-4); E2E test pending. | Review-type is a degenerate path; smoke check S4 verifies the language is present. |
