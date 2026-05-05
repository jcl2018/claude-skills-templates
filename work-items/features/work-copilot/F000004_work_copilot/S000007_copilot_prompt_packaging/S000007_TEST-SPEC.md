---
type: test-spec
parent: S000007_copilot_prompt_packaging
feature: F000004_work_copilot
title: "Copilot Prompt Packaging — Test Specification"
version: 2
status: Draft
date: 2026-04-22
updated: 2026-05-05
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Migrated from Test Matrix + Test Tiers shape to Smoke + E2E on 2026-05-05.
     Original 7 Test Matrix rows + 5 smoke + 3 E2E consolidated; AC values
     carry across rows that share a fixture. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `validate.prompt.md` exists in bundle with valid frontmatter | File is shipped; Copilot can load it (mode + description present) | `test -f work-copilot/prompts/validate.prompt.md && head -1 work-copilot/prompts/validate.prompt.md \| grep -Fq -- ---` |
| S2 | core | AC-1 | Manifest is valid JSON and matches company-workflow schema | Schema not corrupted; no drift from upstream source | `jq . work-copilot/copilot-artifact-manifests.json && diff <(jq -S . deprecated/company-workflow/company-artifact-manifests.json) <(jq -S . work-copilot/copilot-artifact-manifests.json)` (ignoring description/version keys) |
| S3 | core | AC-1 | Templates directory mirrors `deprecated/company-workflow/templates/` | Bundle complete; no missing files | `diff -rq deprecated/company-workflow/templates/ work-copilot/templates/` returns no missing files |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-4, AC-5, AC-6 | Fresh install validates a known-good item — happy path covers cheat sheet, file mode, summary | 1. Install bundle in a fresh repo. 2. Copy F000004 work-item into it. 3. Open Copilot chat. 4. Run `/validate` (cheat sheet), then `/validate work-items/features/work-copilot/F000004_work_copilot/` (dir mode), then `/validate <a TRACKER.md>` (file mode) | Cheat sheet: 3-line usage. Dir mode: all PASS, summary `2 PASS, 0 MISSING, 0 DRIFT`. File mode: structural rules only, exit 0 | Pass if every line matches expected contract |
| E2 | core | AC-2, AC-3 | Detects missing artifact + frontmatter drift | Remove milestones.md from a known-good dir, then run /validate; separately, edit a tracker to drop a required frontmatter field, run /validate on that file | `[MISSING] milestones.md` present in first run; `[DRIFT] TRACKER.md: missing required field <field>` in second run; both exit non-zero | Pass = MISSING + DRIFT lines emitted (not hallucinated) |
| E3 | core | AC-1 | Parity with Claude Code | Same work item validated via `/personal-workflow check` (Claude Code) and `/validate` (Copilot) | Identical status lines (ignoring ordering) | Manual diff; pass if zero delta |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Copilot version compatibility matrix | We only have one work machine to test on | An older Copilot build may not load `.prompt.md` — caught at install time |
| Large work-item directories (100+ artifacts) | No realistic scenario; real items have <10 artifacts | Context-window overflow on pathological inputs |
| Non-English filenames | Not in our workflow | Unicode handling untested |
