---
type: design
parent: F000034
title: "doc/SKILL-CATALOG.md + tracked-doc/ manifest — Feature Design"
version: 1
status: Draft
date: 2026-06-01
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

After F000030 (PR #180) added `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md`, F000032 (PR #186) added per-skill `USAGE.md` (operator/agent best-practice), and F000033 (PR #188) added Check 14 (USAGE.md content freshness vs SKILL.md), there is still no consolidated workbench-level surface where a reader can scan ALL skills at a glance: name, status, when-to-invoke, and a visual workflow chart. The decision tree in PHILOSOPHY.md is a one-line-per-skill routing index — useful for "which skill?" but not "how does this skill flow?"

Additionally, F000030 named two `doc/*.md` files explicitly (PHILOSOPHY.md, ARCHITECTURE.md) but established no convention for what happens when a third file is added to `doc/`. The next doc/ addition (this PR's SKILL-CATALOG.md) is the first natural test of that extensibility gap.

This feature closes both gaps in one atomic PR: a hand-written catalog doc + a tracked-doc/ manifest that registers every doc/*.md with an audit class.

## Shape of the solution

One atomic PR. Six files touched:

1. `templates/doc-SKILL-CATALOG-section.md` (NEW) — per-skill section template with inline instructions per field (status, source, invoke-when, workflow-or-tag).
2. `doc/SKILL-CATALOG.md` (NEW) — header + one section per routable non-deprecated skill (4 orchestrators with ASCII charts, 7 single-step skills with tags), grouped by role.
3. `CLAUDE.md` (MODIFIED) — new `### Tracked doc/ files manifest` subsection inside `## /document-release workbench audit conventions`; `### Reporting` extended; `### Skill directory structure` extended; `## Creating a new skill` extended with new Step 7.
4. `scripts/validate.sh` (MODIFIED) — new Check 15 block (~50 lines) after Check 14. Two halves: (a) manifest parse + orphan/missing-from-disk checks, (b) SKILL-CATALOG.md per-skill section completeness check.
5. `VERSION` (MODIFIED) — PATCH bump (5.0.19 or next free slot).
6. `CHANGELOG.md` (MODIFIED) — F000034 entry in user-forward voice.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Catalog + manifest + Check 15 (atomic implementation) | S000067 | `S000067_skill_catalog_doc_impl/S000067_TRACKER.md` |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Hand-written catalog, NOT auto-generated (Approach A over C) | ASCII charts aren't derivable from SKILL.md prose without brittle parsing. F000032 rejected the auto-gen path for the same reason. Operator writes each section; Check 15 enforces structure + completeness. |
| 2 | New `doc/SKILL-CATALOG.md` file, NOT extension of USAGE.md (Approach A over B) | USAGE.md is per-skill how-to; SKILL-CATALOG.md is cross-skill index. Different reader, different lifecycle. Coupling them couples their drift signals. |
| 3 | Tracked-doc/ manifest inline in CLAUDE.md, NOT a separate JSON file | CLAUDE.md inline is simpler for v1 (one file to read; awk-parseable). Separate JSON would be cleaner for tool consumption but adds a file + parser surface. Defer hoisting until a future tool needs structured parsing. |
| 4 | `audit_class` enum is closed (`skill-routing-drift` / `skill-catalog-completeness` / `static-reference` / `auto-generated`) | Closed enum prevents per-doc free-text drift. v1 only uses the first two values; `static-reference` + `auto-generated` are reserved for future doc/ additions whose drift criteria aren't yet worked out. |
| 5 | ERROR severity, hand-written content, audited at commit + on /document-release | Per F000030 + F000032 + F000033 precedent. WARN replays F000030's 1/13 DESIGN.md adoption decay. ERROR + cheap override is the load-bearing workbench pattern. |
| 6 | ASCII chart mandatory for orchestrators; explicit tag mandatory for single-step skills (no silent omission) | Check 15's predicate is `(chart present) OR (tag present)`. A section without either is silent omission. 4 orchestrators get charts; 7 single-step skills get one of `(single-step utility)` / `(validator)` / `(phase-step in /CJ_goal_feature chain)`. |
| 7 | Audit predicate matches F000032 + F000033 exactly (`status != "deprecated"` AND `(files | length) > 0`) | Three checks (13, 14, 15), one predicate, one truth. Diverging the predicate would let them fall out of sync. Re-use, don't fork. |
| 8 | Single user-story decomposition | Manifest + catalog + Check 15 + CLAUDE.md edits ship atomically under the pre-commit hook (Check 15 ERRORs on orphan/missing-section/missing-chart-and-tag intermediate states). Same shape as F000032 + F000033. |
| 9 | No upstream `/document-release` modification | Per memory `project_workbench_auto_deploy_unsafe`, upstream skills are not ours to edit. Integration via CLAUDE.md project context (the existing F000030 pattern). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| 11 hand-written sections (~25-40 lines each) is real backfill effort | Mitigation: the source material exists — each orchestrator's SKILL.md `## Overview` section already has the chart shape. The template (`templates/doc-SKILL-CATALOG-section.md`) plus the existing prose makes this an exercise in distillation, not invention. |
| Atomic-commit ordering through pre-commit hook | Same constraint as F000032 + F000033: stage everything once. Check 15's defensive `if [ -f "$CATALOG_FILE" ]` guards against intermediate-state false-fire during test runs. |
| Future doc/ additions skip the manifest convention | Mitigation: Check 15a's orphan detection ERRORs on any unregistered doc/*.md file. Adding a doc/ file without a manifest entry is structurally impossible without overriding via `--no-verify` (visible signal). |
| Whether SKILL-CATALOG.md should replace PHILOSOPHY.md `## Decision tree` | Resolution: No. Different readers — decision tree answers "which skill?"; catalog answers "what does this skill do?" Both stay. PHILOSOPHY.md gets a one-line reference to SKILL-CATALOG.md in the Decision tree intro (deferred follow-up if useful). |
| Whether ARCHITECTURE.md's per-skill mentions are also audited by Check 15 | Resolution: No. Check 15 audits SKILL-CATALOG.md completeness specifically. ARCHITECTURE.md's audit is F000030's skill-routing-drift check (retired-skill mentions outside the right section). The two audits are orthogonal. |
| Backwards-compat for deprecated shims | The predicate `status != "deprecated"` excludes them, same as F000032 + F000033. The 4 deprecated alias shims + CJ_goal_investigate are not in the audit set. |
| Manifest grows beyond what awk-range parsing handles cleanly | Defer hoisting to a JSON file until 5+ entries. v1 has 3; v2 expected to stay small. |
| Phase-step skills (CJ_scaffold/implement/qa) get full ASCII charts or just tags | Resolution: tag-only. They're called transitively by orchestrators and their "chart" is one box. The `(phase-step in /CJ_goal_feature chain)` tag is more useful than a one-box chart. |

## Definition of done

- [ ] `doc/SKILL-CATALOG.md` exists with 11 hand-written sections (4 charts + 7 tags) covering all routable non-deprecated skills.
- [ ] `templates/doc-SKILL-CATALOG-section.md` exists with inline instructions per field.
- [ ] `CLAUDE.md` has the new `### Tracked doc/ files manifest` subsection inside `## /document-release workbench audit conventions`, with the three v1 entries.
- [ ] `CLAUDE.md ### Skill directory structure` references the SKILL-CATALOG.md requirement.
- [ ] `CLAUDE.md ## Creating a new skill` has a new Step 7 instructing the author to add a catalog section.
- [ ] `scripts/validate.sh` Check 15 fires ERROR on: orphan doc/*.md, manifest entry pointing to missing file, missing section in SKILL-CATALOG.md, section missing both chart AND tag.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD.
- [ ] CHANGELOG entry in user-forward voice; VERSION bumped PATCH.
- [ ] PR opened against main.

## Not in scope

- README.md per-skill workflow-chart column — deferred; README regenerates from catalog.
- work-copilot/ analog catalog/manifest — workbench-only scope.
- Upstream `/document-release` modification — not ours to modify.
- Auto-generated `audit_class` entries in v1 — enum reserves the value, no entries yet.
- Per-skill snooze of Check 15 — single global ERROR is sufficient.
- ARCHITECTURE.md per-skill audit — F000030's skill-routing-drift is the existing audit; Check 15 is orthogonal.

## Pointers

- Parent tracker: [F000034_TRACKER.md](F000034_TRACKER.md)
- Roadmap: [F000034_ROADMAP.md](F000034_ROADMAP.md)
- Child story: [S000067_skill_catalog_doc_impl/S000067_TRACKER.md](S000067_skill_catalog_doc_impl/S000067_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260601-225856-skills-doc-design-20260601-230103.md`
- F000030 (PR #180, v5.0.11) — established `doc/` folder + workbench audit conventions; this feature extends it with the tracked-doc/ manifest primitive.
- F000032 (PR #186, v5.0.17) — established USAGE.md + Check 13 (presence + structure); this feature reuses the same audit predicate.
- F000033 (PR #188, v5.0.18) — added Check 14 (USAGE.md freshness); this feature reuses the same audit predicate and convention shape.
