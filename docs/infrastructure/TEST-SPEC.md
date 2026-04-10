---
type: test-spec
feature: infrastructure
title: "Infrastructure — Test Specification"
version: 1
status: Active
date: 2026-04-09
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Deploy copies all skill dirs | AC-1 | Repo has skills/ and .claude/skills/ | Run `bash scripts/deploy.sh` | All skill SKILL.md files exist under ~/.claude/skills/ | P0 | E2E |
| 2 | core | Deploy merges settings correctly | AC-1 | settings/baseline.json and override exist | Run deploy.sh | ~/.claude/settings.json contains merged result | P0 | E2E |
| 3 | resilience | Post-commit hook triggers deploy | AC-3 | Hook installed in .claude/hooks/ | Commit a change to a deployable file | ~/.claude/ reflects the change | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | deploy.sh exists and is executable | Script is present and runnable | `test -x scripts/deploy.sh` |
| S2 | core | Post-commit hook exists | P11 enforcement is wired | `test -f .claude/hooks/post-commit-deploy.sh` |
| S3 | core | All path-scoped rules have valid globs | Rules activate on correct paths | `grep -l 'globs:' .claude/rules/*.md` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Full deploy cycle | Run deploy.sh, then diff repo vs ~/.claude/ | Zero differences for deployed files | Pass: exit 0 and no diff output |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Deploy on a fresh machine with no ~/.claude/ | Requires clean environment setup | First deploy may need manual mkdir |
| Concurrent deploy (two terminals) | Unlikely in single-user setup | Possible file race; low impact |
