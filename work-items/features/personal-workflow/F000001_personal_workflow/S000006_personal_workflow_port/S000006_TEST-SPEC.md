---
type: test-spec
parent: S000006
feature: F000001_personal_workflow
title: "personal-workflow-port — Test Specification"
version: 2
status: Draft
date: 2026-04-20
updated: 2026-05-05
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Migrated from Test Matrix + Test Tiers shape to Smoke + E2E on 2026-05-05.
     Original AC column used `Story #N` format; converted to `AC-N` for
     validator traceability. Each AC-N maps to PRD P0 story #N. Consolidated
     to ≤5 rows per tier. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | personal-workflow SKILL.md has Knowledge Resolution + Loading sections | Both blocks were copied; ordered Path Resolution → Stale Rules → Knowledge Resolution → Knowledge Loading → Overview | `grep -Fq '## Knowledge Resolution' skills/personal-workflow/SKILL.md && grep -Fq '## Knowledge Loading' skills/personal-workflow/SKILL.md` |
| S2 | core | AC-1 | Resolution block references AI_KNOWLEDGE_DIR (not renamed) | No accidental variable rename during port | `grep -c 'AI_KNOWLEDGE_DIR' skills/personal-workflow/SKILL.md` ≥ 1 |
| S3 | security | AC-2 | Warning text writes to stderr (no stdout pollution) | Resolution warnings don't leak into stdout that downstream tools parse | Static grep for `>&2` inside the Knowledge Resolution fenced block of skills/personal-workflow/SKILL.md |
| S4 | usability | AC-8 | Command refs say `/personal-workflow`, not `/company-workflow` | Skill-name strings adapted, docs not copy-pasted | `! grep -F '/company-workflow' skills/personal-workflow/SKILL.md` (within Knowledge sections); `grep -Fq '## Knowledge Configuration' skills/personal-workflow/WORKFLOW.md` |
| S5 | resilience | AC-6 | Port is additive — manifests + company-workflow unchanged | personal-artifact-manifests.json and company-workflow SKILL.md not modified by this port | `git diff main -- skills/personal-workflow/personal-artifact-manifests.json deprecated/company-workflow/SKILL.md` returns empty |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3, AC-5 | Opt-in repo: always-on knowledge reaches Claude | `export AI_KNOWLEDGE_DIR=/tmp/k` (with a fixture containing a canary string); `touch $repo/.claude/knowledge-enabled`; run `/personal-workflow check` | Claude's context includes the canary (proves always-on loaded) | Pass = canary retrievable; Fail = absent |
| E2 | security | AC-5 | Global env var + non-opted-in repo: no leak | `export AI_KNOWLEDGE_DIR=/work-knowledge`; open a repo with NO `.claude/knowledge-enabled`; run `/personal-workflow check` | Canary NOT accessible; no Always-On / On-Demand sections emitted | Pass = canary unreachable |
| E3 | core | AC-4, AC-7 | On-demand trigger match (positive + negative) + diagnostic line | Fixture: `surface: on-demand, triggers: [pricing engine]` + canary; opt-in marker present. Ask Claude "walk me through the pricing engine" then ask an unrelated question | Canary surfaces only for the matching prompt; diagnostic line `[knowledge] matched: <category> via <trigger>` emitted | Pass = canary present in match case, absent in non-match, diagnostic line visible |
| E4 | resilience | AC-6 | Zero-regression on existing workflow | Fresh clone, no env var, no marker; run `/personal-workflow check` against existing work-items/; diff vs. pre-port baseline | stdout byte-identical; stderr only differs by the AI_KNOWLEDGE_DIR warning line | Pass = diff matches expected delta only |
| E5 | integration | AC-3 | Both skills honor the same marker in the same repo | Opt-in marker present, same env var, same fixtures; run `/company-workflow validate` and `/personal-workflow check` back-to-back | Both emit equivalent Always-On / On-Demand sections (content parity) | Pass = both load the same files |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Drift detection between the two skills' duplicated bash | v1 explicitly accepts drift (P2 Story #9 defers the helper extraction) | First user report surfaces drift; cost of refactor not yet worth paying |
| Performance: total skill bootstrap with knowledge loading on both skills | Orthogonal — S000005 covers always-on byte cap; personal-workflow inherits it | If cap is wrong, fixed once in S000005 |
| Localization / non-UTF-8 knowledge filenames | Out of scope for F000004 as a whole | Matches company-workflow coverage |
| Windows path handling in opt-in marker lookup | Out of scope for F000004 as a whole | Shell assumptions match company-workflow |
| Sanitization of control chars + >200-char paths in warning | Tested via fixtures in T000007 implementation | Edge case; observable via stderr |
| Malformed `.knowledge.yml` resilience | Tested via T000007 fixtures; consolidated into E1/E3 paths | Edge case; observable via stderr |
