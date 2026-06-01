---
type: roadmap
parent: F000032
title: "Per-skill USAGE.md convention + audit — Roadmap"
date: 2026-06-01
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

Introduce a per-skill `USAGE.md` best-practice doc next to each routable non-deprecated skill's `SKILL.md`, governed by a new template (`templates/doc-SKILL-USAGE.md`) and enforced by a new `scripts/validate.sh` Check 13. Backfill `USAGE.md` for the 11 currently-routable skills. Add a `## Documentation surfaces` section to `doc/PHILOSOPHY.md` and link each decision-tree entry to its USAGE.md. Update `CLAUDE.md` to document the convention for future skill authors. The agent's runtime path is unchanged — USAGE.md is human-reading, in-repo only, not deployed to `~/.claude/`.

## Non-Goals

- README.md per-skill USAGE.md column — deferred; needs catalog field + generator change. Open a TODOS follow-up if discovery via PHILOSOPHY decision tree is insufficient.
- work-copilot/ USAGE.md analog — workbench-only scope (Constraint #1).
- Deployment to `~/.claude/skills/{name}/USAGE.md` — agent has SKILL.md; USAGE.md is operator-reading.
- USAGE.md for the 5 deprecated shims (CJ_goal_run, CJ_goal_auto, CJ_goal_investigate, cj_goal_feature, cj_goal_defect) — excluded by `status != "deprecated"` predicate.
- DESIGN.md lifted to required — stays optional; different reader (developer rationale) vs USAGE.md (operator + agent best-practice).
- USAGE.md frontmatter audit — recommended via template, not enforced by Check 13 (over-constrains a low-value surface).
- Upstream gstack skill changes — none required.

## Success Criteria

- [ ] Every routable non-deprecated skill (11 total: 3 active + 8 experimental) has `skills/{name}/USAGE.md` with all five required H2 sections filled with substantive content.
- [ ] `scripts/validate.sh` Check 13 fires ERROR on a missing USAGE.md or a missing required H2 for any routable non-deprecated skill in `skills-catalog.json`; `./scripts/validate.sh` exits 0 on this PR's HEAD.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD.
- [ ] `doc/PHILOSOPHY.md` has new `## Documentation surfaces` section placed between `## Key patterns and conventions` and `## Decision tree`; each active-skill decision-tree entry links to its USAGE.md.
- [ ] `CLAUDE.md` "Skill directory structure" lists USAGE.md as required; "Creating a new skill" instructs new authors to create USAGE.md from the new template.
- [ ] A reader following `doc/PHILOSOPHY.md ## Decision tree → USAGE.md → SKILL.md` can answer "should I invoke this skill?" without reading SKILL.md cold (manual smoke test on two random skills post-ship).
- [ ] Workbench-only blast radius: no upstream skill files modified; no `~/.claude/` deploy surface added; `skills-catalog.json` unchanged.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000065](S000065_per_skill_usage_md_impl/S000065_TRACKER.md) | Per-skill USAGE.md convention + audit — implementation | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000065 (template + 11 backfills + validate.sh Check 13 + CLAUDE.md + PHILOSOPHY.md edits) | 2026-06-01 | Not Started | chjiang | One atomic PR via /ship | — |
| 2 | End-to-end pipeline run + smoke check | 2026-06-01 | Not Started | chjiang | Verify decision-tree → USAGE.md chain answers "should I invoke this skill?" on two random skills | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-01: Created — F000032 scaffolded from /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 Ship S000065 (template + 11 USAGE.md + validate.sh Check 13 + docs) --> #2 E2E + smoke check
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does discovery via PHILOSOPHY decision tree → USAGE.md feel sufficient, or does README.md need a column too? | Post-ship: read decision tree, click two random USAGE.md, decide. If insufficient → TODOS follow-up. |
| Should work-copilot/ get an analogous USAGE.md surface? | Deferred — re-evaluate if work-copilot/ grows past current bundle scope. |
