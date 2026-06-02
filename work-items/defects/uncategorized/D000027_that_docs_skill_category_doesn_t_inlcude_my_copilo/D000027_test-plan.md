---
type: test-plan
parent: D000027
title: "doc/SKILL-CATALOG.md missing copilot bundle — Test Plan"
date: 2026-06-02
author: /CJ_goal_defect
status: Draft
---

## Scope

Adds a `## Companion surfaces (non-skill)` section with a `### work-copilot` subsection to `doc/SKILL-CATALOG.md` and relaxes the preamble to acknowledge non-skill companion surfaces. Single-file change: `doc/SKILL-CATALOG.md`.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Original bug: catalog has zero copilot mentions | Run `grep -nE 'copilot\|Copilot\|work-copilot' doc/SKILL-CATALOG.md` | Returns ≥ 1 match (post-fix returns 6) | Pass |
| 2 | Check 15 still passes after fix | Run `./scripts/validate.sh` | Exit 0; Check 15 emits PASS for each of the 11 active routable skills | Pass |
| 3 | New section uses the explicit non-skill tag | Run `grep -nE '\(non-skill bundle\)' doc/SKILL-CATALOG.md` | Returns ≥ 1 match | Pass |
| 4 | `### work-copilot` subsection exists | Run `grep -n '^### work-copilot' doc/SKILL-CATALOG.md` | Returns 1 match | Pass |

## Verification Steps

- [x] `./scripts/validate.sh` returns exit 0
- [x] `grep -n copilot doc/SKILL-CATALOG.md` returns ≥ 1 match
- [x] Reading the new section in context (preamble → orchestrators → phase-step → validators → companion surfaces → see-also) does not break the existing visual flow
- [ ] PR review confirms the section text is accurate and useful for an operator landing on the page cold

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS 25.5.0 / zsh / worktree cj-def-20260602-010934-57806 | branch `cj-def-20260602-010934-57806` off `main@c3a85f0` | Pass |
