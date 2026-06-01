---
type: design
parent: F000032
title: "Per-skill USAGE.md convention + audit — Feature Design"
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

The workbench has two doc surfaces today: `doc/PHILOSOPHY.md` (workbench-level overview, design principles, decision tree, retired skills) and `doc/ARCHITECTURE.md` (mechanism reference), both shipped 8 days ago in F000030 (PR #180, v5.0.11). What is missing is a per-skill best-practice / "how to think about this skill" surface.

Today the per-skill doc surface is `skills/{name}/DESIGN.md`, declared **optional** by CLAUDE.md and supported by `templates/doc-SKILL-DESIGN.md` (Purpose / Behavior / Design Decisions / Dependencies / Security Boundaries / Test Criteria). Only `skills/CJ_system-health/DESIGN.md` exists; the other 10 routable skills have none. DESIGN.md is design-rationale shaped — useful for developers extending the skill — but it does not answer "when do I invoke this?" "when do I NOT?" "what is the mental model?" That gap is exactly what this feature closes.

## Shape of the solution

Add a new required file `skills/{name}/USAGE.md` per routable non-deprecated skill, plus a new template `templates/doc-SKILL-USAGE.md` and a new validate.sh Check 13 that enforces presence + section completeness. `doc/PHILOSOPHY.md` gains a new top-level `## Documentation surfaces` section and each decision-tree entry gains a USAGE link. CLAUDE.md documents the convention.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Template + 11 backfills + validate.sh Check 13 + CLAUDE.md + PHILOSOPHY.md edits | S000065 | `S000065_per_skill_usage_md_impl/S000065_TRACKER.md` |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | New USAGE.md file class (Approach B) instead of lifting DESIGN.md from optional to required (Approach A) or adding a required `## Philosophy` section inside SKILL.md (Approach C) | B directly matches the user's "best-practice per skill" framing. A would force 12 backfills of a design-rationale doc shape the user didn't ask for. C grows every SKILL.md with operator-facing prose, paying a per-turn token cost on every agent invocation. |
| 2 | Audit predicate `status != "deprecated"` with non-empty `files`, NOT F000030's `status == "active"` | F000030's predicate gates decision-tree placement (ship-stable only). USAGE.md audits routability — operators route to `experimental` skills today (CJ_goal_feature/defect/scaffold-work-item), so they need USAGE.md too. Audit set = 11 skills (3 active + 8 experimental). The 5 deprecated shims + tooling-only `templates` entry are excluded automatically. |
| 3 | USAGE.md stays in-repo; NOT deployed by skills-deploy install | USAGE.md is human-reading. Agent gets SKILL.md (the agent-facing file) at runtime; USAGE.md doesn't need delivery to `~/.claude/`. Less to deploy = less drift. |
| 4 | DESIGN.md stays optional, distinct from USAGE.md | Two different readers: USAGE.md = operator + agent ("when / why"); DESIGN.md = developer ("how was this built"). Only 1/13 skills had DESIGN.md after 8 days — proves "optional" decays. USAGE.md is required + audited from day 1. |
| 5 | Audit is ERROR, not WARN | F000030 establishes missing PHILOSOPHY.md decision-tree entries are ERROR. USAGE.md matches that severity. WARN would replay F000030's 1/13 adoption story. |
| 6 | Audit grep is line-anchored (`^## When to use$`), not substring | A substring grep would falsely pass on USAGE.md that quotes the required heading inside a code fence. |
| 7 | Frontmatter recommended but NOT audited | Template ships with frontmatter for visual consistency with DESIGN.md. Check 13 validates only the five H2 headings. Over-constraining frontmatter is a separate, lower-value concern. |
| 8 | No README.md changes for v1 | `scripts/generate-readme.sh` regenerates README.md from skills-catalog.json. Adding a USAGE.md column needs a catalog field + script change. Deferred to a TODOS follow-up if README.md feels insufficient after v1. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Atomic-commit ordering: validate.sh pre-commit hook will BLOCK an intermediate commit that adds Check 13 without the 11 USAGE.md files. | Mitigation: stage all 13+ files in ONE commit. /ship's commit-once-at-end pattern handles this naturally. Only failure mode is operator running `git commit` between mid-implement stages. |
| Audit set drift: future skills must add USAGE.md or the audit will fire. | Mitigation: CLAUDE.md "Creating a new skill" step lists USAGE.md as required. The audit IS the enforcement. |
| work-copilot/ analog deferred — does Copilot bundle need its own USAGE.md surface? | Out of scope for v1 (workbench-only per Constraint #1). Decide if work-copilot/ ever grows past its current scope; tracked as a follow-up. |
| README.md per-skill USAGE.md link missing — discovery via PHILOSOPHY.md decision tree may not be enough. | Spend 15 min after ship reading the decision tree (per design's "The Assignment"). If insufficient, open a TODOS row. |

## Definition of done

- [ ] `templates/doc-SKILL-USAGE.md` exists with five required H2 sections + DESIGN.md-shaped frontmatter.
- [ ] All 11 routable non-deprecated skills have a `skills/{name}/USAGE.md` with all five required H2 sections filled with content.
- [ ] `scripts/validate.sh` Check 13 fires ERROR on missing USAGE.md or missing required H2 for any routable non-deprecated skill.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0.
- [ ] `doc/PHILOSOPHY.md` has new `## Documentation surfaces` section + per-decision-tree-entry USAGE links.
- [ ] `CLAUDE.md` Skill directory structure + Creating a new skill steps updated.
- [ ] `skills-catalog.json` UNCHANGED (USAGE.md not in `files` arrays, template not in `templates` entries).
- [ ] CHANGELOG.md entry in user-forward voice.

## Not in scope

- README.md per-skill USAGE.md links — deferred (catalog field + script change required); TODOS follow-up if needed.
- work-copilot/ USAGE.md analog — workbench-only scope per Constraint #1.
- Deployment of USAGE.md to `~/.claude/skills/{name}/USAGE.md` — not needed (human-reading, in-repo only).
- USAGE.md for the 5 deprecated shims (CJ_goal_run, CJ_goal_auto, CJ_goal_investigate, cj_goal_feature, cj_goal_defect) — excluded by audit predicate; SKILL.md banner-then-route is sufficient.
- USAGE.md frontmatter validation — recommended (template ships with it) but not audited.
- Changes to upstream gstack skills — none required.

## Pointers

- Parent tracker: [F000032_TRACKER.md](F000032_TRACKER.md)
- Roadmap: [F000032_ROADMAP.md](F000032_ROADMAP.md)
- Child story: [S000065_per_skill_usage_md_impl/S000065_TRACKER.md](S000065_per_skill_usage_md_impl/S000065_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260601-152835-3769-design-20260601-153151.md`
- F000030 (PR #180, v5.0.11) — established doc/ folder + workbench audit conventions; this feature extends the pattern at the per-skill layer.
- F000031 (PR #181, v5.0.12) — uppercase canonical CJ_goal_* names; audit predicate uses catalog `name` fields directly.
