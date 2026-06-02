---
type: design
parent: S000067
title: "doc/SKILL-CATALOG.md + tracked-doc/ manifest — implementation design"
version: 1
status: Draft
date: 2026-06-01
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. (For an atomic user-story, this is a
     brief link-to-parent stub — the parent F000034_DESIGN.md owns the full
     problem-framing + alternative analysis.) -->

## Problem

F000030 ships `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md` and a workbench audit conventions section in CLAUDE.md, but provides no convention for what happens when a third `doc/*.md` file is added. F000032 + F000033 establish per-skill `USAGE.md` + Check 13 (presence) + Check 14 (freshness) but there is still no consolidated workbench-level surface where a reader can scan ALL skills at a glance with workflow charts. This story builds both: a hand-written `doc/SKILL-CATALOG.md` + a tracked-doc/ manifest registering every doc/*.md with an audit class + Check 15 enforcing both. See parent `F000034_DESIGN.md` for the full Approach A/B/C/D analysis.

## Shape of the solution

Atomic implementation in one PR (one commit, staged together for the pre-commit hook):

1. `templates/doc-SKILL-CATALOG-section.md` (NEW) — per-skill section template with inline instructions per field.
2. `doc/SKILL-CATALOG.md` (NEW) — header + 11 hand-written sections (4 ASCII charts for orchestrators + 7 tags for single-step skills), grouped by role.
3. `CLAUDE.md` (MODIFIED) — new `### Tracked doc/ files manifest` subsection inside `## /document-release workbench audit conventions` (between `### New-skills check` and `### Reporting`); `### Reporting` extended; `### Skill directory structure` extended; `## Creating a new skill` Step 7 inserted (renumber existing 7 → 8).
4. `scripts/validate.sh` (MODIFIED) — new Check 15 block (~50 lines) after Check 14. Two halves: (a) manifest parse + orphan/missing-from-disk checks, (b) SKILL-CATALOG.md per-skill section completeness check (chart-OR-tag predicate).
5. `VERSION` + `CHANGELOG.md` — PATCH bump + user-forward entry naming F000034.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single user-story (no sub-tasks) | Atomic under the pre-commit hook. Same shape as F000032 (S000065) and F000033 (S000066). Splitting adds bookkeeping without splitting risk. |
| 2 | Manifest inline in CLAUDE.md, awk-range parsed | Simpler than a separate JSON file for v1 (3 entries); CLAUDE.md is already the project-context surface `/document-release` reads. Defer hoisting until 5+ entries or a tool needs structured parsing. |
| 3 | Chart-OR-tag predicate for catalog sections (Check 15b) | A section heading alone is silent omission. `(HAS_CHART >= 2) OR (HAS_TAG >= 1)` forces the operator to declare intent. 4 orchestrators get charts; 7 single-step skills get tags. |
| 4 | Closed `audit_class` enum (4 values; v1 uses 2) | Prevents per-doc free-text drift. `static-reference` + `auto-generated` are reserved for future doc/ additions; listing them in v1 avoids a backfill PR. |
| 5 | Defensive `if [ -f "$CATALOG_FILE" ]` guard for Check 15b | Test-mode robustness; intermediate-state safety. Orphan + missing-from-disk halves (15a) always run regardless. |
| 6 | Hand-written, NOT auto-generated (Approach A) | ASCII charts aren't derivable from prose; F000032 already rejected auto-gen on the same grounds. Operator writes; Check 15 audits structure. |
| 7 | Audit predicate matches F000032 + F000033 exactly | Three checks (13/14/15), same predicate, same 11 skills. Re-use, don't fork. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| 11 hand-written sections (~25-40 lines each) is real backfill | Mitigation: source material exists in each orchestrator's SKILL.md `## Overview`. The template makes it an exercise in distillation, not invention. |
| Atomic-commit ordering with pre-commit hook + Check 15 | Same shape as F000032 + F000033 — stage everything once. Intermediate states would trip orphan-detection or missing-section. |
| awk-range parsing breaks if YAML manifest gets fancy | v1 manifest is simple (path/audit_class/owner per entry). Hoisting to a JSON file is the follow-up when manifest outgrows inline parsing. |
| Check 15 HAS_CHART threshold (`>= 2` fenced lines) | Fenced blocks always have open + close; HAS_CHART threshold of 2 captures the canonical shape. Bare `^```` strings elsewhere in the section (e.g. nested fences) would inflate the count but not break the test (still ≥ 2 = chart present). |
| Future doc/ files skip the manifest convention | Mitigation: Check 15a orphan-detection ERRORs on any unregistered doc/*.md. Adding doc/ files without a manifest entry is structurally impossible without `--no-verify`. |

## Definition of done

- [ ] All acceptance criteria from this story's TRACKER.md verified.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` both exit 0.
- [ ] PR opened against main via /ship.

## Not in scope

- README.md per-skill workflow-chart column — deferred (catalog field + generator change required).
- work-copilot/ analog catalog/manifest — workbench-only scope.
- USAGE.md deployment to `~/.claude/` — irrelevant for a validate-time check.
- ARCHITECTURE.md per-skill audit beyond F000030's existing skill-routing-drift check.
- Auto-generated catalog (Approach C) — rejected.
- Distinguishing real vs cosmetic chart edits — out of scope.

## Pointers

- Parent feature design: [../F000034_DESIGN.md](../F000034_DESIGN.md)
- Parent feature tracker: [../F000034_TRACKER.md](../F000034_TRACKER.md)
- SPEC: [S000067_SPEC.md](S000067_SPEC.md)
- TEST-SPEC: [S000067_TEST-SPEC.md](S000067_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260601-225856-skills-doc-design-20260601-230103.md`
- F000030 (PR #180, v5.0.11) — `doc/` folder + audit conventions; this story extends with tracked-doc/ manifest primitive.
- F000032 (PR #186, v5.0.17) — USAGE.md + Check 13; same audit predicate reused.
- F000033 (PR #188, v5.0.18) — Check 14 (USAGE.md freshness); same audit predicate + ERROR-with-override convention reused.
