---
type: test-spec
parent: S000009_always_on_instructions
feature: F000004_work_copilot
title: "Always-On Copilot Instructions — Test Specification"
version: 1
status: Draft
date: 2026-04-22
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Scope: ENTIRE user story. -->

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Ambient awareness for scaffolding question | AC-1 | instructions installed, Copilot chat open | Ask "how do I add a user story under F000004?" | Response references `work-items/features/F000004_*/S0000NN_*/` with correct parent and required artifacts | P0 | E2E |
| 2 | core | Ambient awareness for defect placement | AC-2 | instructions installed | Ask "where does a defect live?" | Response: `work-items/defects/D000NNN_{slug}/` + TRACKER + RCA + test-plan | P0 | E2E |
| 3 | core | Points to /validate | AC-3 | instructions installed | Ask "is my work item compliant?" | Response instructs running `/validate <path>` | P0 | E2E |
| 4 | core | Size budget | AC-4 | file authored | `wc -c copilot-instructions.md` | <= 8192 | P0 | Unit |
| 5 | usability | Common tasks table present | AC-5 | file authored | `grep -c '^|' copilot-instructions.md` | >= 5 rows | P1 | Unit |
| 6 | observability | Every claim has a source link | AC-6 | file authored | Manual review: each H2 section has a footer link | Pass if every section ends with a `Source:` reference | P1 | Manual |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | File exists in bundle | Delivery pipeline sees it | `test -f work-copilot/instructions/copilot-instructions.md` |
| S2 | core | Size ≤ 8 KB | Budget | `[ $(wc -c < work-copilot/instructions/copilot-instructions.md) -le 8192 ]` |
| S3 | core | Mentions `/validate` | Points to validator | `grep -q '/validate' work-copilot/instructions/copilot-instructions.md` |
| S4 | core | Has ID regex invariant | Convention not drifted | `grep -qE 'F[0-9]{6}' work-copilot/instructions/copilot-instructions.md` |
| S5 | core | Has phase names | Lifecycle stable | `grep -qiE 'Track.*Implement.*Ship' work-copilot/instructions/copilot-instructions.md` |
| S6 | core | Installed path wired in manifest | Installer will deliver it | `jq -e '.files[] | select(.dest == ".github/copilot-instructions.md")' work-copilot/install-manifest.json` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps | Expected Outcome | Rubric |
|---|-----|----------|-------|-----------------|--------|
| E1 | core | Cold-start ambient Q&A | 1. Install bundle in fresh repo. 2. Open Copilot chat. 3. Ask the 3 AC scenarios | Each answer aligns with conventions | Pass if all 3 answers pass manual rubric |
| E2 | observability | Behavior regression if file removed | Remove instructions.md, re-ask same questions | Answers are generic / wrong / less specific | Confirms instructions are actually influencing Copilot |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Every possible workflow question | Unbounded space | Q/A quality only measured on AC-scenario subset |
| Long Copilot sessions (>10k tokens deep) | Not part of daily use | Instructions might get compressed away |
| Non-Chat surfaces (inline completion) | Out of scope per PRD | Inline suggestions won't benefit from instructions |
