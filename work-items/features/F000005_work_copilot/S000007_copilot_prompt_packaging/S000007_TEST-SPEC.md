---
type: test-spec
parent: S000007_copilot_prompt_packaging
feature: F000005_work_copilot
title: "Copilot Prompt Packaging — Test Specification"
version: 1
status: Draft
date: 2026-04-22
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Test Matrix must cover every PRD acceptance criterion
     across happy/edge/error paths. For a single fix or task, use test-plan.md instead. -->

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Valid feature dir returns all PASS | AC-1 | feature dir with TRACKER.md + milestones.md, both valid | Run `/validate work-items/features/F000005_work_copilot/` | `[PASS] TRACKER.md`, `[PASS] milestones.md`, `Summary: 2 PASS, 0 MISSING, 0 DRIFT` | P0 | E2E |
| 2 | core | Missing artifact flagged MISSING | AC-2 | feature dir with TRACKER.md but no milestones.md | Run `/validate <dir>` | Output includes `[MISSING] milestones.md` | P0 | E2E |
| 3 | core | Frontmatter drift flagged DRIFT | AC-3 | tracker missing a required frontmatter field | Run `/validate <tracker.md>` | Output includes `[DRIFT] TRACKER.md: missing required field <field>` | P0 | E2E |
| 4 | core | File mode on single tracker | AC-4 | valid TRACKER.md path | Run `/validate <tracker.md>` | File-mode output: structural rules only, no manifest scan | P0 | E2E |
| 5 | core | Directory mode on work-item dir | AC-4 | valid directory path | Run `/validate <dir>` | Directory-mode output: manifest scan + per-artifact structural rules | P0 | E2E |
| 6 | usability | Cheat sheet on empty invocation | AC-5 | N/A | Run `/validate` | Output is a 3-line usage reminder | P1 | E2E |
| 7 | observability | Summary footer | AC-6 | mixed PASS/MISSING/DRIFT result | Run `/validate <dir>` | Last line is `Summary: N PASS, M MISSING, K DRIFT` | P1 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | `validate.prompt.md` exists in bundle | File is shipped | `test -f work-copilot/prompts/validate.prompt.md` |
| S2 | core | Prompt has YAML frontmatter with `mode:` and `description:` | Copilot can load it | `head -n 1 validate.prompt.md` shows `---` |
| S3 | core | Manifest is valid JSON | Schema not corrupted | `jq . work-copilot/copilot-artifact-manifests.json` |
| S4 | core | Manifest schema matches company-workflow schema | No drift from source | `diff <(jq -S . company-artifact-manifests.json) <(jq -S . copilot-artifact-manifests.json)` ignoring description/version keys |
| S5 | core | Templates directory mirrors `templates/company-workflow/` | Bundle complete | `diff -rq templates/company-workflow/ work-copilot/templates/` returns no missing files |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Fresh install validates a known-good item | 1. Install bundle in a fresh repo. 2. Copy F000005 work-item into it. 3. Open Copilot chat. 4. Type `/validate work-items/features/F000005_work_copilot/` | All PASS; summary footer shows 2 PASS | Pass if every line matches expected contract |
| E2 | core | Detects missing artifact | Remove milestones.md, then run /validate on same dir | `[MISSING] milestones.md` present | Pass if MISSING line is emitted and not hallucinated |
| E3 | core | Parity with Claude Code | Same work item validated via `/company-workflow check` and `/validate` | Identical status lines (ignoring ordering) | Manual diff; pass if zero delta |

<!-- No E2E test skill yet — these run manually on the work machine during S000007 ship verification. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Copilot version compatibility matrix | We only have one work machine to test on | An older Copilot build may not load `.prompt.md` — would be caught at install time |
| Large work-item directories (100+ artifacts) | No realistic scenario; real items have <10 artifacts | Context-window overflow on pathological inputs |
| Non-English filenames | Not in our workflow | Unicode handling untested |
