---
type: design
parent: S000065
title: "Per-skill USAGE.md convention + audit — implementation design"
version: 1
status: Draft
date: 2026-06-01
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. (For an atomic user-story, this is a
     brief link-to-parent stub — the parent F000032_DESIGN.md owns the full
     problem-framing + alternative analysis.) -->

## Problem

The workbench lacks a per-skill "when to invoke / when not / mental model" surface. `SKILL.md` is agent-runtime; `DESIGN.md` is developer-rationale (optional, 1/13 adoption). Operators and the agent itself currently have no first-stop doc explaining whether a given skill is the right hammer for a given nail. This story implements the surface — a new required `USAGE.md` per routable non-deprecated skill, governed by a new template and a new validate.sh audit check. See parent `F000032_DESIGN.md` for the full problem framing and the Approach A/B/C alternative analysis.

## Shape of the solution

Atomic implementation in one PR:

1. New file `templates/doc-SKILL-USAGE.md` — five required H2 sections + DESIGN.md-shaped frontmatter.
2. Eleven new files `skills/{name}/USAGE.md` (one per routable non-deprecated skill).
3. New Check 13 block in `scripts/validate.sh` — line-anchored greps for the five required H2 headings, ERROR on any miss.
4. New `## Documentation surfaces` section in `doc/PHILOSOPHY.md` + per-decision-tree-entry USAGE links.
5. Two-line edit to `CLAUDE.md` Skill directory structure + new step in Creating a new skill.

All staged together for one commit (atomic-ordering required by the pre-commit hook).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single user-story (no sub-tasks) | The work is atomic under the pre-commit hook. Splitting adds bookkeeping cost without splitting actual risk surface. F000030 used the same shape. |
| 2 | Backfill content distilled from SKILL.md description + rules/skill-routing.md | Authoritative source already exists; new USAGE.md restates it in operator-facing voice. No reinvention. |
| 3 | Check 13 derives audit set from jq query each run | Future-proof: adding/deprecating a skill auto-adjusts the audit set; no name list to keep in sync. |
| 4 | Line-anchored grep (`^## When to use$`) | Substring grep would falsely pass on body content quoting the required headings. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Pre-commit hook blocks intermediate state if Check 13 commits before USAGE.md files | Mitigation: stage everything in one commit via /ship. Operator-mid-implement `git commit` is the only failure mode. |
| Content quality of 11 backfills — risk of placeholder text passing the structural audit | Manual smoke at ship time: read two random USAGE.md, confirm they answer "should I invoke this skill?" |

## Definition of done

- [ ] All acceptance criteria from this story's TRACKER.md verified.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` both exit 0.
- [ ] PR opened via /ship.

## Not in scope

- README.md per-skill USAGE.md column — deferred (catalog field change required).
- work-copilot/ USAGE.md analog — workbench-only scope.
- USAGE.md deployment to `~/.claude/` — human-reading only; not needed.
- USAGE.md frontmatter audit — recommended via template, not enforced.

## Pointers

- Parent feature design: [../F000032_DESIGN.md](../F000032_DESIGN.md)
- Parent feature tracker: [../F000032_TRACKER.md](../F000032_TRACKER.md)
- SPEC: [S000065_SPEC.md](S000065_SPEC.md)
- TEST-SPEC: [S000065_TEST-SPEC.md](S000065_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260601-152835-3769-design-20260601-153151.md`
