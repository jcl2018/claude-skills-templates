---
type: test-spec
parent: S000009_always_on_instructions
feature: F000004_work_copilot
title: "Always-On Copilot Instructions — Test Specification"
version: 2
status: Draft
date: 2026-04-22
updated: 2026-05-05
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Migrated from Test Matrix + Test Tiers shape to Smoke + E2E on 2026-05-05. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2, AC-3, AC-4 | File exists in bundle, ≤ 8 KB, mentions /validate | Delivery pipeline sees it; size budget held; points at validator | `test -f work-copilot/instructions/copilot-instructions.md && [ "$(wc -c < work-copilot/instructions/copilot-instructions.md)" -le 8192 ] && grep -q '/validate' work-copilot/instructions/copilot-instructions.md` |
| S2 | core | AC-1, AC-2 | Conventions intact: ID regex + lifecycle phase names | Convention not drifted; phase vocabulary stable | `grep -qE 'F[0-9]{6}' work-copilot/instructions/copilot-instructions.md && grep -qiE 'Track.*Implement.*Ship' work-copilot/instructions/copilot-instructions.md` |
| S3 | usability | AC-5 | Common tasks table present | At least 5 task rows for ambient navigation | `grep -c '^|' work-copilot/instructions/copilot-instructions.md` ≥ 5 |
| S4 | core | AC-1 | Installed path wired in manifest | Installer will deliver it to `.github/copilot-instructions.md` | `jq -e '.files[] \| select(.dest == ".github/copilot-instructions.md")' work-copilot/install-manifest.json` |
| S5 | observability | AC-6 | Each H2 section ends with a `Source:` reference (manual review) | Every claim in the file is sourced; reduces hallucination risk | Manual review checklist at ship time |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-3 | Cold-start ambient Q&A across 3 AC scenarios | 1. Install bundle in fresh repo. 2. Open Copilot chat. 3. Ask: "how do I add a user story under F000004?", "where does a defect live?", "is my work item compliant?" | Story-1 answer references the right work-item directory + parent + required artifacts. Defect answer references `work-items/defects/D000NNN_{slug}/` + TRACKER + RCA + test-plan. Compliance answer instructs running `/validate <path>` | Pass if all 3 answers pass manual rubric |
| E2 | observability | AC-1 | Behavior regression check: instructions actually influence Copilot | Remove instructions.md from target; re-ask the same 3 questions | Answers are generic / wrong / less specific than E1 | Confirms instructions are actually influencing Copilot output |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Every possible workflow question | Unbounded space | Q/A quality only measured on AC-scenario subset |
| Long Copilot sessions (>10k tokens deep) | Not part of daily use | Instructions might get compressed away |
| Non-Chat surfaces (inline completion) | Out of scope per PRD | Inline suggestions won't benefit from instructions |
