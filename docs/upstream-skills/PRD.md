---
type: prd
feature: upstream-skills
title: "Upstream Skills — Product Requirements"
version: 1
status: Active
date: 2026-04-09
author: chjiang
---

## Problem Statement

Gstack provides upstream skills that evolve independently. Without a structured sync process, skill copies in `skills/` drift from upstream, break on upgrade, or accumulate stale versions. The repo owner needs a repeatable upgrade path that preserves P2 (upstream skills are copies, not forks) while tracking which skills are active vs passive.

## Mental Model

`skills-catalog.json` is the registry. Each upstream skill entry declares its source, dependencies, and classification. Sync is a clean overwrite from gstack's repo via git pull. Verification runs smoke checks (file exists, deps resolve) and behavioral checks (skill invocation produces expected output).

## User Stories

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | Can I sync all upstream skills from gstack? | repo owner | run a sync that overwrites skills/ from the gstack upstream | I get the latest skill versions without merge conflicts |
| 2 | core | Does the catalog track every upstream skill? | repo owner | have skills-catalog.json list each skill with source, deps, and portability | I know what's installed and what it requires |
| 3 | integration | Can I detect when upstream has newer versions? | repo owner | run audit check 1.7 and see if gstack has updates | I know when to upgrade |

### P1 (Important)

None for v1.

### P2 (Nice-to-Have)

None for v1.

## Acceptance Criteria

### Story #1: Upstream sync [core]

```
GIVEN gstack repo has been updated upstream
WHEN  I pull the latest skills into skills/
THEN  every SKILL.md in skills/ matches the upstream version byte-for-byte
  AND skills-catalog.json version field is updated
```

### Story #2: Catalog completeness [core]

```
GIVEN upstream skills exist in skills/{name}/SKILL.md
WHEN  I check skills-catalog.json
THEN  every skill directory has a corresponding catalog entry
  AND every catalog entry with source "gstack" has a matching skill directory
```

### Story #3: Version detection [integration]

```
GIVEN the installed gstack version is recorded in skills-catalog.json
WHEN  audit check 1.7 runs
THEN  it reports whether the installed version matches upstream latest
```

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| Catalog completeness | 100% of upstream skills tracked | Every skills/{name}/ dir has a catalog entry |
| Version freshness | Catalog version matches upstream VERSION | Audit check compares catalog vs gstack VERSION |

## Out of Scope

- Automatic upstream pull (sync is manual by design per P2)
- Forking or patching upstream skills in-place

## Assumptions

- Upstream gstack skills use a consistent SKILL.md format
- The gstack repo is the only upstream source
- Version is tracked at the catalog level, not per-skill
