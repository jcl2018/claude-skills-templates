---
type: prd
feature: system-health
title: "System Health — Product Requirements"
version: 1
status: Active
date: 2026-04-10
author: chjiang
---

## Problem Statement

home-setup's quality/audit layer was fragmented across 5 skills with overlapping checks, different output formats, and confusing trigger boundaries: `/project:audit` (command), `/advisor` (custom skill), `/work-audit` (custom skill), `/align-feature-contract` (engine), and `/test-align-contract` (test harness). Meanwhile, Waza's upstream `/health` skill covered config hygiene (CLAUDE.md quality, rules, hooks) that none of the custom skills addressed. The repo owner needs one unified health command with a single mental model.

## Mental Model

9-layer dashboard: layers 1-6 come from Waza's config hygiene checks (inlined per P2 wrapper pattern), layers 7 and 9 are custom governance and deploy state (deterministic, run by `scripts/health-checks.sh`), and layer 8 is doc quality (delegates to `/align-feature-contract`). The `--scope` flag restricts to a path, `--layer` filters by category. Replaces `/project:audit`, `/advisor`, and `/work-audit`.

## User Stories

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | Can I run a unified health check with one command? | repo owner | run `/health` and see all 9 layers scored | I have one place for system quality |
| 2 | core | Does /health cover config hygiene? | repo owner | have layers 1-6 check CLAUDE.md, rules, skills, hooks, sub-agents, and verifiers | config drift is caught automatically |
| 3 | core | Does /health cover governance? | repo owner | have layer 7 check contracts, upstream freshness, and audit spec | governance violations surface immediately |
| 4 | core | Does /health cover doc quality? | repo owner | have layer 8 delegate to /align-feature-contract per family | doc triplet issues are caught without running a separate skill |
| 5 | core | Does /health cover deploy state? | repo owner | have layer 9 check repo-vs-home drift | uncommitted or undeployed changes are flagged |
| 6 | usability | Can I scope to a specific directory? | repo owner | run `/health --scope docs/work-pipeline/` | I only see checks relevant to one family |
| 7 | usability | Can I filter by layer category? | repo owner | run `/health --layer governance` | I only see layers 7 and 9 |

### P1 (Important)

None for v1.

### P2 (Nice-to-Have)

None for v1.

## Acceptance Criteria

### Story #1: Unified command [core]

```
GIVEN the repo has skills, docs, and deployment infrastructure
WHEN  I run /health
THEN  all 9 layers produce scored results
  AND a composite health score is reported
```

### Story #2: Config hygiene [core]

```
GIVEN Waza's config data collection script exists at skills/waza/health/scripts/collect-data.sh
WHEN  /health runs layers 1-6
THEN  each layer reports findings based on Waza's rubric
```

### Story #3: Governance [core]

```
GIVEN scripts/health-checks.sh produces structured output for layers 7 and 9
WHEN  /health runs layer 7
THEN  upstream freshness, contract validation, and audit spec checks are reported
```

### Story #4: Doc quality [core]

```
GIVEN doc triplet families exist under docs/
WHEN  /health runs layer 8
THEN  /align-feature-contract is invoked per family and results are aggregated
```

### Story #5: Deploy state [core]

```
GIVEN deployable files exist in the repo
WHEN  /health runs layer 9
THEN  deploy.sh --dry-run reports drift or confirms zero drift
```

### Story #6: Scope restriction [usability]

```
GIVEN a valid directory path under docs/ or work-items/
WHEN  I run /health --scope docs/work-pipeline/
THEN  only layer 8 checks run, scoped to that directory
```

### Story #7: Layer filter [usability]

```
GIVEN the --layer flag accepts config, governance, docs, or all
WHEN  I run /health --layer governance
THEN  only layers 7 and 9 run
```

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| Layer coverage | All 9 layers produce output | /health run with no flags |
| Scope accuracy | --scope restricts to correct family | Run with --scope and verify only that family's checks appear |
| Predecessor elimination | /advisor, /work-audit, /project:audit no longer invoked | Skill routing in CLAUDE.md points to /health |

## Out of Scope

- Cross-repo consistency checks (deferred to future layer 10)
- Auto-remediation (reports issues, does not fix them)
- Trend tracking across runs (health-history.jsonl captures data, visualization is future work)

## Assumptions

- Waza's config data collection script is available at `skills/waza/health/scripts/collect-data.sh`
- /align-feature-contract is deployed and functional for layer 8 delegation
- scripts/health-checks.sh exists and produces structured output for layers 7 and 9
- The skill is deployed to `.claude/skills/system-health/SKILL.md`
