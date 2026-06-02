---
type: roadmap
parent: F000034
title: "doc/SKILL-CATALOG.md + tracked-doc/ manifest — Roadmap"
date: 2026-06-01
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

Build the workbench's first **catalog**-shaped doc — `doc/SKILL-CATALOG.md` — with one hand-written section per routable non-deprecated skill (4 orchestrators with ASCII workflow charts, 7 single-step skills with explicit tags). Establish the tracked-doc/ manifest convention: every `doc/*.md` registers in a YAML block in `CLAUDE.md ## /document-release workbench audit conventions` with an `audit_class` (`skill-routing-drift` / `skill-catalog-completeness` / `static-reference` / `auto-generated`). Add `scripts/validate.sh` Check 15 enforcing orphan-detection + manifest-consistency + per-skill section completeness. Workbench-internal — no upstream skill changes, no deployment surface, no catalog edits.

## Non-Goals

- README.md per-skill workflow-chart column — deferred (regeneration via `generate-readme.sh` would need a parsing pass).
- work-copilot/ analog catalog/manifest — workbench-only scope.
- Upstream gstack `/document-release` modification — not ours to edit. Integration via CLAUDE.md project context (the existing F000030 pattern).
- Auto-generated catalog (Approach C) — rejected; ASCII charts aren't derivable from prose.
- Per-skill snooze of Check 15 — single global ERROR is sufficient.
- Backfilling `auto-generated` audit_class entries — value reserved in the enum; no v1 entries.
- ARCHITECTURE.md per-skill audit beyond F000030's existing skill-routing-drift check — orthogonal scope.
- Replacing PHILOSOPHY.md `## Decision tree` — both surfaces stay (different readers: routing vs workflow understanding).

## Success Criteria

- [ ] `doc/SKILL-CATALOG.md` exists with sections for all 11 routable non-deprecated skills (predicate matches F000032 + F000033).
- [ ] 4 orchestrators (CJ_goal_feature, CJ_goal_defect, CJ_goal_todo_fix, CJ_personal-pipeline) have fenced ASCII workflow charts distilled from their SKILL.md `## Overview`.
- [ ] 7 single-step skills (CJ_scaffold/implement/qa-work-item + CJ_personal-workflow + CJ_system-health + CJ_suggest + CJ_improve-queue) have explicit tags.
- [ ] `templates/doc-SKILL-CATALOG-section.md` exists.
- [ ] `CLAUDE.md ## /document-release workbench audit conventions` has new `### Tracked doc/ files manifest` subsection with 3 v1 entries (PHILOSOPHY.md, ARCHITECTURE.md, SKILL-CATALOG.md).
- [ ] `CLAUDE.md ### Reporting` notes the Check 15 `### Doc/ manifest drift` PR-body subheading.
- [ ] `CLAUDE.md ### Skill directory structure` references SKILL-CATALOG.md requirement.
- [ ] `CLAUDE.md ## Creating a new skill` has new Step 7 (Step 7 → 8 renumber).
- [ ] `scripts/validate.sh` Check 15 ERRORs on: orphan doc/*.md, manifest entry pointing to missing file, missing `### <name>` section in SKILL-CATALOG.md, section missing both fenced chart AND tag.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD.
- [ ] CHANGELOG entry in user-forward voice; VERSION PATCH-bumped via `./scripts/check-version-queue.sh` (5.0.19 or next free slot).
- [ ] PR opened against main; PR body notes the F000030/F000032/F000033 lineage.
- [ ] Manual smoke (post-ship): touch SKILL-CATALOG.md to delete one `### <name>` heading + re-run validate.sh → Check 15 fires `missing section`; restore. Rename a manifest path to a typo → Check 15 fires `missing from disk`; restore.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000067](S000067_skill_catalog_doc_impl/S000067_TRACKER.md) | doc/SKILL-CATALOG.md + tracked-doc/ manifest — implementation (template + 11 hand-written sections + CLAUDE.md manifest + validate.sh Check 15) | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000067 (template + catalog + manifest + Check 15) | 2026-06-01 | Not Started | chjiang | One atomic PR via /ship against main | — |
| 2 | After merge: post-ship doc audit via `/document-release` | 2026-06-01 | Not Started | chjiang | Verify `### Doc/ manifest drift: none` line surfaces in PR body | #1 |
| 3 | Assignment: write next new skill in workbench + notice catalog-section friction | 2026-06+ | Not Started | chjiang | If "step 7" feels like overhead, the template needs to be denser | #2 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-01: Created — F000034 scaffolded from /office-hours design doc (`chjiang-cj-feat-20260601-225856-skills-doc-design-20260601-230103.md`).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
(no upstream stacking — independent F-ID after F000032 + F000033 merged)
                                  |
                                  v
#1 Ship S000067 (template + catalog + manifest + Check 15)
                                  |
                                  v
#2 Post-ship /document-release audit (verify Doc/ manifest drift: none)
                                  |
                                  v
#3 Assignment: next-skill friction observation
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should the manifest also enforce update-on-/document-release dates per doc? | No. F000033's drift check is per-skill via `git log -1`; expanding to per-doc would require per-file drift criteria which are brittle. The `audit_class` enum already separates `static-reference` (no drift) from `skill-catalog-completeness` (structural drift only). Content freshness across the doc as a whole is genuinely hard to define. Defer indefinitely. |
| Should SKILL-CATALOG.md replace PHILOSOPHY.md `## Decision tree`? | No. They serve different readers — decision tree answers "which skill?"; catalog answers "what does this skill do?" Both stay. PHILOSOPHY.md may get a one-line reference to SKILL-CATALOG.md in the Decision tree intro as a deferred follow-up. |
| Should the manifest live in a separate file (e.g. `doc-catalog.json`) instead of inline in CLAUDE.md? | Considered; deferred. CLAUDE.md inline is simpler for v1 (one file to read; awk-parseable). If a future tool needs structured parsing, hoist then. |
| Backwards-compat: do deprecated shims need catalog sections? | No. The predicate `status != "deprecated"` excludes them. The 4 deprecated alias shims + CJ_goal_investigate are not in the audit set. |
