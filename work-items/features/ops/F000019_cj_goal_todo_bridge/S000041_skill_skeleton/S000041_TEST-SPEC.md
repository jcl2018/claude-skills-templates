---
type: test-spec
parent: S000041
feature: F000019
title: "Skill skeleton + scripts/goal.sh + catalog + routing + eval — Test Specification"
version: 1
status: Draft
date: 2026-05-14
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke = structural existence + frontmatter +
     deploy + catalog + validator. E2E = preflight halt fixtures + an
     end-to-end dry-run on a real TODO. Green-path E2E is deferred per
     /CJ_personal-pipeline precedent (eval budget). -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | SKILL.md exists with valid frontmatter | Skill is discoverable by Claude Code | `test -f skills/CJ_goal/SKILL.md && head -10 skills/CJ_goal/SKILL.md \| grep -q '^name: CJ_goal'` |
| S2 | core | AC-1 | scripts/goal.sh exists, executable, has shebang | Dispatch target reachable | `test -x skills/CJ_goal/scripts/goal.sh && head -1 skills/CJ_goal/scripts/goal.sh \| grep -q '^#!/usr/bin/env bash'` |
| S3 | core | AC-1 | Catalog entry exists | Distribution + validation work | `jq -e '.[] \| select(.name == "CJ_goal" and .status == "experimental")' skills-catalog.json` |
| S4 | core | AC-1 | Routing rule mentions /CJ_goal | Skill is routable | `grep -q '/CJ_goal' rules/skill-routing.md` |
| S5 | integration | AC-1 | scripts/validate.sh passes | Workbench invariants hold | `./scripts/validate.sh` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | resilience | AC-5 | Preflight halt — P1 TODO | Create fixture TODO with `(P1, S)` suffix; invoke `/CJ_goal "fixture-p1"` | exit code != 0; "too big — run /office-hours" in stdout; no work-items/ pollution | binary pass/fail |
| E2 | resilience | AC-5 | Preflight halt — size L | Create fixture with `(P3, L)`; invoke /CJ_goal | exit != 0; same halt class halted_at_preflight | binary |
| E3 | resilience | AC-5 | Preflight halt — sensitive surface AUQ default | Create fixture body mentioning `skills-catalog.json`; invoke /CJ_goal | AUQ surfaces; default option "halt"; halted_at_sensitive_surface_user_declined; exit != 0 | binary |
| E4 | resilience | AC-5 | Preflight halt — design-needed keyword | Body contains "needs design"; invoke /CJ_goal | exit != 0; halted_at_preflight ("needs design") | binary |
| E5 | resilience | AC-5 | Preflight halt — body too vague | Body < 50 chars; invoke /CJ_goal | exit != 0; halted_at_preflight ("too vague") | binary |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Green-path end-to-end (TODO → merged PR) | Blows per-case $0.50 eval budget; /CJ_personal-pipeline precedent | Will be validated manually via the design's "First real run" recommendation (P4,S TODO from TODOS.md) and telemetry inspection |
| /loop continue-set in eval | /loop is a separate skill; integration test would require multiple TODOs + multiple iterations | Manual /loop /CJ_goal run on a 3-TODO backlog covers this once v1 ships |
| Idempotency on partial-scaffold (T-tracker exists but pipeline never ran) | Edge case; small surface | Re-run /CJ_goal on the same T-ID — should jump in at step 4 dispatch |
| Hash-collision on TODOS.md DONE-mark | Requires concurrent edit fixture | Manually triggered by editing TODOS.md mid-run; documented halt class exists |
