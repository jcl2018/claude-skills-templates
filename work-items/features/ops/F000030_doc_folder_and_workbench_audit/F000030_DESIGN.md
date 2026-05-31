---
type: design
parent: F000030
title: "doc/ folder with rewritten PHILOSOPHY + new ARCHITECTURE; /document-release named-doc audit — Feature Design"
version: 1
status: Approved
date: 2026-05-31
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

`philosophy.md` at repo root (350 lines, 19922 bytes) is the workbench's "why this exists + how the pieces fit together" entry-point doc, intended for the operator and future contributors. It has drifted significantly across the last 5 weeks of shipping:

- References three retired skills (`/workflow`, `/contracts`, `/docs`) as primary evidence for design principles.
- Names `/CJ_goal_auto` and `/CJ_goal_run` as the primary entry points across the decision tree, per-skill pipelines, and "Quick rule of thumb" table — both DEPRECATED by F000027 / S000060 (PR #173, v5.0.6) and scheduled for sunset v6.0.0.
- Zero mention of the actual current front doors `/cj_goal_feature` (build a feature: topic → PR) and `/cj_goal_defect` (fix a bug: description → shipped fix), which have shipped 10 and 4 telemetry entries respectively this week alone.
- Zero mention of three mechanism layers landed in the last 14 days: `cj-goal-common.sh` shared helper (S000057), F000028 post-merge/post-rewrite doc-sync hooks, F000029 marker-pickup AUQ.

`/document-release` already finds `philosophy.md` via its `find . -maxdepth 2 -name "*.md"` glob, but treats it as a generic "any other .md" file — no specific skill-routing-drift checks. So `/document-release` reviews philosophy.md but doesn't catch the drift class that just accumulated. The drift specifically accumulated *because* that audit heuristic is generic.

F000028 + F000029 wired the doc-sync MECHANISM (hooks drop markers, preambles surface AUQs). This feature closes the loop on the CONTENT side: gives the workbench's signature explanation a named-doc audit so routing changes → hook fires → AUQ surfaces → `/document-release` runs → drift caught → operator fixes.

## Shape of the solution

A single child user-story carries the full implementation: create `doc/` at repo root, `git mv philosophy.md → doc/PHILOSOPHY.md` (preserves history; one shot on case-insensitive APFS because destination path differs), rewrite to current state, add new `doc/ARCHITECTURE.md` with five required sections, edit root `README.md` (+ `## Deeper reading`), and add a new section to root `CLAUDE.md` (`## /document-release workbench audit conventions` with literal jq commands).

No upstream skill modification. `/document-release` reads CLAUDE.md as project context during its Step 2 audit pass; the workbench audit conventions ride that existing behavior. Same pattern as the existing CI/CD merge convention section that teaches `/ship` + `/land-and-deploy` to skip `--auto` in this repo.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Move + rewrite philosophy.md, add ARCHITECTURE.md, README + CLAUDE.md edits | S000063 | [S000063_doc_folder_and_workbench_audit_impl/S000063_TRACKER.md](S000063_doc_folder_and_workbench_audit_impl/S000063_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach B (create `doc/` folder, `git mv` + rewrite, add ARCHITECTURE.md, wire via CLAUDE.md convention) | Captures operator reframe ("consolidate into doc/") at the right granularity; closes F000028+F000029 loop on the content side; blast radius small enough QA verifies with smoke tests + Diataxis coverage check. Rejected Approach A (rewrite in place + add to /document-release Step 2 named docs — too narrow; no `doc/` home for future explanation content). Rejected Approach C (Approach B + extract CLAUDE.md mechanism prose to ARCHITECTURE — real refactor, would need to verify nothing downstream greps CLAUDE.md for exact section headings; rejected at scope AUQ). |
| 2 | NO new manifest layer (no declarative skills-manifest.yaml driving generated docs) | Skill routing already lives in `rules/skill-routing.md`; prose narrative in `doc/PHILOSOPHY.md` is enough. YAGNI at ~7 active skills. |
| 3 | Drop-vs-tombstone rule for retired skill names | Single `## Retired skills` subsection at end of PHILOSOPHY holds one paragraph per name (`/workflow`, `/contracts`, `/docs`, `/CJ_goal_auto`, `/CJ_goal_run`). All OTHER mentions throughout PHILOSOPHY/ARCHITECTURE are dropped. Audit annotation suppression rule (mentions inside that subsection OR within 200 chars of `DEPRECATED`/`sunset`/`tombstone` are skipped) is the symmetric escape hatch. |
| 4 | `doc/README.md` index file is dropped from v1 | With only two files in `doc/`, an index is YAGNI. Discovery via root `README.md ## Deeper reading` + GitHub's directory rendering. Revisit if `doc/` grows past 4 files. |
| 5 | CLAUDE.md mechanism duplication accepted for v1 | F000009 / F000028 / F000029 / TODOS-hygiene sections in CLAUDE.md (agent-relevant) overlap ~30% with doc/ARCHITECTURE.md content (operator-facing). Soft duplication is the cost of declining Approach C. Revisit if CLAUDE.md grows past ~500 lines. |
| 6 | `/document-release` Step 1 base-branch abort is a separate F000029 contract gap (out of scope) | The skill refuses to run on main. CLAUDE.md convention this feature adds is still read on any feature branch in this workbench, so the wiring lands on the path Step 1 actually allows. File the abort gap as a TODOS follow-up. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| `/document-release` may not actually read + execute the CLAUDE.md convention section (untested until first run on a workbench feature branch) | Post-merge smoke test #1: on a throwaway branch, add an unannotated `/workflow` reference to `doc/PHILOSOPHY.md` outside `## Retired skills`. Run `/document-release`. Confirm PR body's Documentation section contains a `### Skill-routing drift` subheading naming `/workflow`. If not fired, tighten the convention wording. |
| New-skills check (active skills missing from Decision tree) may have false-positives if `## Decision tree` heading text differs from expected anchor | Post-merge smoke test #2: add a `skills/CJ_smoketest/SKILL.md` stub + catalog entry (`status: active`); don't mention it in `doc/PHILOSOPHY.md ## Decision tree`. Run `/document-release`. Confirm PR body names "active skill not in decision tree: CJ_smoketest". |
| CLAUDE.md grows past ~500 lines and the duplication-acceptance decision (decision #5) starts hurting | Re-evaluate at v6.0.0 sunset (Approach C extraction back on the table). |
| Case-insensitive APFS could surprise the `git mv philosophy.md doc/PHILOSOPHY.md` step | Confirmed in design phase: destination path differs (`./philosophy.md` vs `./doc/PHILOSOPHY.md`), one-shot rename works. If for some reason it doesn't, the fallback is two-step (`git mv philosophy.md philosophy.md.tmp; git mv philosophy.md.tmp doc/PHILOSOPHY.md`). |
| Annotation suppression rule (200-char proximity to `DEPRECATED`/`sunset`/`tombstone`) could be too loose or too strict in practice | Empirical: smoke test #1 exercises the strict case (un-annotated mention should fire). If it false-positives in normal prose, dial the window down (e.g., to same-paragraph-only). |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md` exist; root `philosophy.md` is gone; `git log --follow doc/PHILOSOPHY.md` shows rename preserved.
- [ ] `doc/PHILOSOPHY.md` names `/cj_goal_feature` + `/cj_goal_defect` as primary front doors; every mention of retired/deprecated skills is inside `## Retired skills` OR dropped.
- [ ] `doc/PHILOSOPHY.md` has a `## Decision tree` heading with the routing diagram covering active CJ_ skills (cj_goal_feature, cj_goal_defect, CJ_goal_investigate, CJ_goal_todo_fix, CJ_suggest, CJ_system-health, CJ_improve-queue) and a "Called transitively" table for internal phase-step skills.
- [ ] `doc/ARCHITECTURE.md` has the five required headings exactly: `## The shared cj-goal-common.sh helper (S000057)`, `## F000028 doc-sync hooks (post-merge + post-rewrite)`, `## F000029 marker-pickup AUQ (cj_goal preambles)`, `## Decision tree mirror`, `## Deprecation tombstones`. Each section answers the content questions listed in Approach B item 4.
- [ ] Root `README.md` has `## Deeper reading` linking to `doc/PHILOSOPHY.md` and `doc/ARCHITECTURE.md`.
- [ ] Root `CLAUDE.md` has `## /document-release workbench audit conventions` with both literal jq commands + annotation suppression rules.
- [ ] `./scripts/validate.sh` exits green; `./scripts/test.sh` exits green.
- [ ] CHANGELOG.md entry added for F000030.
- [ ] Smoke test (manual, leaf reader): "which CJ_ skill do I call to start a feature?" → `/cj_goal_feature`; "what closes the doc-sync loop?" → F000028 hooks + F000029 marker-pickup AUQ.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Root-convention files do not move. README.md, CLAUDE.md, CONTRIBUTING.md, CHANGELOG.md, TODOS.md, skills-catalog.json all have hard reasons to stay at root (GitHub display, Claude Code autodiscovery, runtime consumers like /ship Step 14, validate.sh / skills-deploy / test.sh reading ./skills-catalog.json).
- `/document-release` SKILL.md is NOT modified. The skill lives only at `~/.claude/skills/document-release/SKILL.md` (gstack-deployed); workbench-specific audit conventions go into CLAUDE.md.
- `/document-release` Step 1 base-branch abort fix is a separate F000029 contract gap. File as TODOS follow-up; do not gate this feature on fixing it.
- New manifest layer (declarative `skills-manifest.yaml`) — out of scope; prose docs that cross-link to skills-catalog.json + rules/skill-routing.md are enough.
- CLAUDE.md mechanism prose extraction (Approach C). Rejected at scope AUQ; revisit if CLAUDE.md grows past ~500 lines.
- Changes to F000028 hooks or F000029 marker-pickup AUQ. Strictly downstream content consumer.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000030_TRACKER.md](F000030_TRACKER.md)
- Roadmap: [F000030_ROADMAP.md](F000030_ROADMAP.md)
- Child story: [S000063_doc_folder_and_workbench_audit_impl/S000063_TRACKER.md](S000063_doc_folder_and_workbench_audit_impl/S000063_TRACKER.md)
- Upstream design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260531-123255-4461-design-20260531-124744.md`
- Predecessor mechanism (hook): [../F000028_doc_sync_post_merge_hook/F000028_TRACKER.md](../F000028_doc_sync_post_merge_hook/F000028_TRACKER.md)
- Predecessor mechanism (AUQ): [../F000029_marker_pickup_auq/F000029_TRACKER.md](../F000029_marker_pickup_auq/F000029_TRACKER.md)
- Architectural precedent (project-instructions-teach-upstream-skill): CLAUDE.md `## CI/CD merge convention` section
