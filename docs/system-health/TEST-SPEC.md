---
type: test-spec
feature: system-health
title: "System Health — Test Specification"
version: 1
status: Active
date: 2026-04-10
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Full health produces 9-layer output | AC-1 | Repo deployed, all scripts present | Run `/health` | All 9 layers scored, composite score reported | P0 | E2E |
| 2 | core | Config hygiene runs layers 1-6 | AC-2 | Waza data collection script present | Run `/health --layer config` | Layers 1-6 produce findings | P0 | E2E |
| 3 | core | Governance checks run layer 7 | AC-3 | health-checks.sh present | Run `/health --layer governance` | Upstream freshness + contract validation reported | P0 | E2E |
| 4 | core | Doc quality delegates to /align-feature-contract | AC-4 | Doc triplet families exist | Run `/health --layer docs` | Per-family alignment results aggregated | P0 | E2E |
| 5 | core | Deploy state reports drift | AC-5 | Deployable files exist | Run `/health --layer governance` (includes layer 9) | deploy.sh --dry-run output included | P0 | E2E |
| 6 | usability | --scope restricts to one family | AC-6 | docs/infrastructure/ exists with triplet | Run `/health --scope docs/infrastructure/` | Only layer 8 runs, only infrastructure family checked | P0 | E2E |
| 7 | usability | --layer filters by category | AC-7 | All layers functional | Run `/health --layer docs` | Only layer 8 runs | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md exists | Skill is deployed | `[ -f .claude/skills/system-health/SKILL.md ]` |
| S2 | core | health-checks.sh exists and is executable | Deterministic checks available | `[ -x scripts/health-checks.sh ]` |
| S3 | core | Contract exists in skill-contracts.json | Skill has behavioral contract | `jq '.contracts[] | select(.skill == "system-health")' skill-contracts.json` |
| S4 | core | Waza data collection present | Upstream dependency met | `[ -f skills/waza/health/scripts/collect-data.sh ]` |
| S5 | core | Catalog entry present | Skill registered | `jq '.skills[] | select(.name == "system-health")' skills-catalog.json` |
| S6 | core | Replaces field set | Tombstone tracking active | `jq '.skills[] | select(.name == "system-health") | .replaces' skills-catalog.json` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Full health run | Type `/health` in Claude Code session | 9-layer dashboard with composite score, snapshot saved | All layers produce output, score is 0-10 |
| E2 | usability | Scoped run | Type `/health --scope docs/audit/` | Only audit family's layer 8 checks appear | No other families or layers in output |
| E3 | usability | Layer filter | Type `/health --layer governance` | Only layers 7 and 9 appear | No config (1-6) or docs (8) in output |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Layer interaction under partial failure (e.g., Waza script missing) | Requires simulating upstream deletion | Low risk: health-checks.sh has fallback handling |
| Composite score algorithm accuracy | Score weighting is heuristic, not deterministic | Medium risk: manual review of score reasonableness |
| Snapshot file format stability | Format is human-readable markdown, not machine-consumed | Low risk: snapshots are for historical reference only |
