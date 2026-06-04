---
type: test-plan
parent: T000037
title: "doc/WORKFLOWS.md — workflow-centric doc reorg — Test Plan"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- Scope: ONE task — the Job 1 doc reorg (rename doc/SKILL-CATALOG.md →
     doc/WORKFLOWS.md, push component roster to doc/ARCHITECTURE.md, re-scope
     validate.sh Check 15b to the CJ_goal_* prefix, ripple ~12 source files).
     The three GREEN gates (T1, T2, T3) below are mandated by the design's
     Success Criteria and are the QA contract for /CJ_qa-work-item. -->

## Scope

This task renames and re-scopes the top-level skill-doc surface:

- `doc/SKILL-CATALOG.md` → `doc/WORKFLOWS.md` (rewritten to carry ONLY the 3 cj_goal
  orchestrator workflows — `### CJ_goal_feature`, `### CJ_goal_defect`,
  `### CJ_goal_todo_fix` — each with its ASCII chart + a new `**Touches:**` block).
- `doc/ARCHITECTURE.md` gains a `## Component skills (non-workflow roster)` section
  (9 skills) + keeps the work-copilot companion entry; its internal SKILL-CATALOG
  link + audit_class enum (`skill-catalog-completeness` → `workflow-completeness`)
  are updated.
- `scripts/validate.sh` Check 15: `CATALOG_FILE` → `doc/WORKFLOWS.md`; Check 15b
  completeness predicate re-scoped `select(.name | startswith("CJ_goal_"))`.
- `scripts/test.sh` zzz-test-scaffold fixture: catalog-doc interaction + backup/restore
  plumbing REMOVED; fixture becomes a positive "non-orchestrator skill needs no
  workflow-doc section" regression test.
- Lockstep token renames (`skill-catalog`/`SKILL-CATALOG` → `workflows`/`WORKFLOWS`)
  across: `CLAUDE.md` (5 refs), `cj-document-release.json` (categories key),
  `tests/cj-document-release.test.sh` + `tests/cj-document-release-config.test.sh`
  (incl. the hardcoded `F36_COMPAT` string), `templates/doc-SKILL-CATALOG-section.md`
  → `templates/doc-WORKFLOWS-section.md`, `doc/PHILOSOPHY.md` (2 refs),
  `skills/CJ_document-release/SKILL.md` (1 ref).
- `TODOS.md`: a new Job-2 follow-up row added; line ~294's `skill-catalog`
  (a skills-catalog.json reference) deliberately LEFT unchanged.

Modified files: see T000037_TRACKER.md `## Files` (12 source files + CHANGELOG via /ship).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | **validate.sh GREEN + Check 15b enumerates EXACTLY the 3 orchestrators** | Run `./scripts/validate.sh`. Inspect Check 15 output: it reads `doc/WORKFLOWS.md` (not the removed SKILL-CATALOG.md) and Check 15b's completeness predicate `select(.name \| startswith("CJ_goal_"))` resolves to exactly `{CJ_goal_feature, CJ_goal_defect, CJ_goal_todo_fix}`, requiring a `### <name>` section with a chart for each. | validate.sh exits 0 (GREEN). Check 15a: no orphan doc/ file (manifest updated; doc/WORKFLOWS.md registered; doc/SKILL-CATALOG.md gone). Check 15b: passes with the 3-orchestrator set; no other `CJ_goal_*`-prefixed catalog entry sneaks in. Check 16 (cj-document-release.json schema): GREEN. | Pending |
| 2 | **test.sh GREEN after the zzz-test-scaffold fixture update** | Run `./scripts/test.sh` end-to-end. The zzz-test-scaffold fixture (a synthetic NON-orchestrator skill) no longer appends a `### zzz-test-scaffold` section to any doc and no longer backs up/restores doc/SKILL-CATALOG.md (Step 1c stub-append + line ~177 cp + EXIT-trap clause + line ~304 restore all removed). | test.sh exits 0 (GREEN). The fixture now asserts a non-orchestrator scaffolded skill (catalog entry only, NO workflow-doc section) passes validate. No cascade: Check 15b is still exercised by the 3 real orchestrators present in doc/WORKFLOWS.md on every validate run. | Pending |
| 3 | **grep-sweep: zero dangling SKILL-CATALOG / skill-catalog refs in source** | Run `git grep -in 'SKILL-CATALOG\|skill-catalog'`. | Zero hits in source, EXCLUDING: `.gstack/`, `work-items/` (this work-item's own history), `CHANGELOG.md` historical entries, AND the `TODOS.md:294` false-positive (which refers to `skills-catalog.json`, the JSON skill registry — must be LEFT unchanged). Any other hit = a missed rename site (incl. the lowercase `skill-catalog` in `cj-document-release-config.test.sh`'s `F36_COMPAT`). | Pending |
| 4 | **doc/WORKFLOWS.md structural shape** | Open `doc/WORKFLOWS.md`. | Exists; titled `# Workflows`; contains EXACTLY the 3 sections `### CJ_goal_feature`, `### CJ_goal_defect`, `### CJ_goal_todo_fix`, each with its ASCII chart + a `**Touches:**` block (Skills dispatched / Scripts+tools / Docs updated). The `## Phase-step skills`, `## Validators / utilities`, `## Companion surfaces (non-skill)` sections are gone; the old self-reference line (~268) is rewritten. `doc/SKILL-CATALOG.md` no longer exists. | Pending |
| 5 | **doc/ARCHITECTURE.md component roster present** | Open `doc/ARCHITECTURE.md`. | Has a `## Component skills (non-workflow roster)` section listing all 9 component skills (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, CJ_document-release, CJ_personal-workflow, CJ_system-health, CJ_suggest, CJ_improve-queue, CJ_repo-init) each with name + one-line role + Source link; the work-copilot entry's internal link no longer points at the removed catalog; the audit_class enum reads `workflow-completeness` (not `skill-catalog-completeness`). | Pending |
| 6 | **PHILOSOPHY decision-tree no-vanish safety net intact** | Run the F000030 New-skills check logic: `jq -r '.[] \| select(.status=="active") \| select((.files\|length)>0) \| .name' skills-catalog.json`, then grep each name in `doc/PHILOSOPHY.md` `## Decision tree`. | Every active routable skill still appears in PHILOSOPHY.md's decision tree (this check is UNCHANGED by the reorg — it remains the guarantee that no routable skill becomes undocumented). | Pending |
| 7 | **cj-document-release.json category rename** | `jq '.categories \| keys' cj-document-release.json`. | The `skill-catalog` key is gone; a `workflows` key maps to `["doc/WORKFLOWS.md"]`. `whitelist_patterns` (incl. `doc/**/*.md`) unchanged. Check 16 still validates the schema GREEN. | Pending |

## Verification Steps

<!-- How was the reorg verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` exits 0 (covers T1, T4, T5, T7 — Checks 15a/15b/16)
- [ ] `./scripts/test.sh` exits 0 (covers T2 — full suite incl. the updated zzz-test-scaffold integration fixture)
- [ ] `git grep -in 'SKILL-CATALOG\|skill-catalog'` returns only the allowlisted exclusions (T3)
- [ ] `git grep -in 'skill-catalog'` (lowercase, case-insensitive) double-check catches the `F36_COMPAT` token in cj-document-release-config.test.sh
- [ ] PHILOSOPHY.md New-skills check passes for every active routable skill (T6)
- [ ] `git mv` history preserved for the two renames (doc/SKILL-CATALOG.md → doc/WORKFLOWS.md; templates/doc-SKILL-CATALOG-section.md → templates/doc-WORKFLOWS-section.md)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (workbench, zsh) | cj-feat-20260604-004813-68066 | Pending |
