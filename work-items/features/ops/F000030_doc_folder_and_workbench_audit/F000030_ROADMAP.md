---
type: roadmap
parent: F000030
title: "doc/ folder with rewritten PHILOSOPHY + new ARCHITECTURE; /document-release named-doc audit — Roadmap"
date: 2026-05-31
author: chjiang
status: Approved
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Create `doc/` at repo root; move existing `philosophy.md` → `doc/PHILOSOPHY.md` via `git mv` (preserves history); rewrite to current state (drop retired-skill name references except in a single `## Retired skills` subsection; replace `/CJ_goal_auto` + `/CJ_goal_run` references with `/cj_goal_feature` + `/cj_goal_defect`; add `## Decision tree` heading + routing diagram). Add NEW `doc/ARCHITECTURE.md` with five mechanism-reference sections (cj-goal-common.sh helper, F000028 doc-sync hooks, F000029 marker-pickup AUQ, Decision tree mirror, Deprecation tombstones). Update root `README.md` (add `## Deeper reading`) + root `CLAUDE.md` (add `## /document-release workbench audit conventions` with literal jq commands + annotation suppression rules). Add CHANGELOG entry for F000030. No upstream skill modification.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- Root-convention files do not move (README, CLAUDE.md, CONTRIBUTING, CHANGELOG, TODOS, skills-catalog.json).
- No edits to `~/.claude/skills/document-release/SKILL.md` — upstream gstack skill.
- No fix for `/document-release` Step 1 base-branch abort (separate F000029 contract gap; TODOS follow-up).
- No new manifest layer (no skills-manifest.yaml driving generated docs).
- No CLAUDE.md mechanism extraction (Approach C rejected at scope AUQ).
- No changes to F000028 hooks or F000029 marker-pickup AUQ implementation.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md` exist; root `philosophy.md` is gone (rename history preserved via `git mv`).
- [ ] `doc/PHILOSOPHY.md` names `/cj_goal_feature` + `/cj_goal_defect` as primary front doors; every retired/deprecated skill mention is inside `## Retired skills` OR dropped.
- [ ] `doc/PHILOSOPHY.md` has `## Decision tree` heading + routing diagram for active CJ_ skills.
- [ ] `doc/ARCHITECTURE.md` has the five required headings and each section answers its content questions.
- [ ] Root `README.md` has `## Deeper reading` linking to both new docs.
- [ ] Root `CLAUDE.md` has `## /document-release workbench audit conventions` with literal jq commands.
- [ ] `./scripts/validate.sh` passes (0 errors, 0 warnings); `./scripts/test.sh` passes.
- [ ] CHANGELOG entry added for F000030.
- [ ] Smoke test (post-ship, manual): on a feature branch, plant an unannotated `/workflow` reference in `doc/PHILOSOPHY.md`; run `/document-release`; PR body Documentation section contains `### Skill-routing drift` naming `/workflow`.
- [ ] Smoke test (post-ship, manual): add an unmentioned active skill stub; run `/document-release`; PR body names "active skill not in decision tree: <stub>".

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000063](S000063_doc_folder_and_workbench_audit_impl/S000063_TRACKER.md) | Move + rewrite philosophy.md → doc/PHILOSOPHY.md, add doc/ARCHITECTURE.md, README + CLAUDE.md edits, CHANGELOG | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000063 (move + rewrite + new ARCHITECTURE + README/CLAUDE.md edits + CHANGELOG) | 2026-05-31 | Not Started | chjiang | Single user-story carries the full implementation | — |
| 2 | End-to-end pipeline run (`/ship` opens PR; `/CJ_personal-workflow check` PASS; manual smoke confirms legibility) | 2026-05-31 | Not Started | chjiang | First real-world named-doc audit triggers after merge | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-05-31: F000030 scaffolded from `chjiang-cj-feat-20260531-123255-4461-design-20260531-124744.md` (APPROVED).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 Ship S000063  -->  #2 End-to-end pipeline run
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does the annotation suppression rule (200-char proximity to `DEPRECATED`/`sunset`/`tombstone`) hold up empirically? | Post-merge smoke test #1 (planted `/workflow` reference). If false-positives in normal prose, tighten window to same-paragraph-only. |
| Should `/CJ_goal_todo_fix` and `/CJ_suggest` get equivalent doc-coverage in `doc/PHILOSOPHY.md ## Decision tree`? | Yes — they are active skills per `skills-catalog.json`; the new-skills check requires them to be named in the Decision tree. |
| When does CLAUDE.md mechanism duplication start hurting enough to revisit Approach C? | At ~500 lines or first downstream consumer (manifest sync hook) breaking because of a section move. |
