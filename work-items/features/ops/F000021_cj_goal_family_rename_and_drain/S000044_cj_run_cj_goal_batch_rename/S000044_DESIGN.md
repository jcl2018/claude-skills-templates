---
type: design
parent: S000044
title: "Batched rename CJ_run → CJ_goal_run + CJ_goal → CJ_goal_todo_fix — User Story Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- Brief stub. See parent F000021_DESIGN.md for full context. -->

## Problem

`/CJ_run` and `/CJ_goal` are functionally adjacent (feature ship + TODO drain)
but named inconsistently. The pivot reshapes them as a family
(`/CJ_goal_run` + `/CJ_goal_todo_fix`) — but the rename itself is the
prerequisite, pure-mechanical step that unblocks the semantic changes in
S000045–S000047.

## Shape of the solution

Single chore PR: `git mv skills/CJ_run skills/CJ_goal_run` + `git mv skills/CJ_goal skills/CJ_goal_todo_fix`. Update all references (catalog, routing, CLAUDE.md, telemetry paths). Write thin alias SKILL.md files at the old paths that print a deprecation banner then delegate to the new skill. Major version bump (rename-only break, v3.6.5 → v4.0.0).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Pure rename mechanics + alias delegation | S000044 (this story) | [S000044_TRACKER.md](S000044_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Batch both renames in ONE chore PR | Both are pure `git mv` + reference updates; reviewable in one diff; avoids awkward intermediate state where one rename ships and the other doesn't. Autoplan-gate confirmed. |
| 2 | Major version bump (v3.6.5 → v4.0.0) | Rename is breaking by name (slash-command surface changes), even if semantics are preserved by aliases. Semantic versioning compliance. |
| 3 | Soft cutover: aliases through v4.x with deprecation banner; removed v5.0.0 | Protects operator muscle memory. Hard cutover at v4.0 would break every operator's first post-upgrade invocation. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Stale `/CJ_run` reference somewhere in repo (work-item history, comment, README) | Grep audit pre-ship: `grep -rE '/CJ_run\b' --exclude-dir={.git,.gstack,deprecated}`. Work-item history retains old names by design (NOT in scope). |
| Telemetry path drift mid-v4.x (operator on v4.1, fallback read on old path) | Fallback-read both paths; merge before sunset trip-wire. Verified in S000044 smoke `S2`. |
| Alias delegation fails silently in some installer flows | `skills-deploy install` + `validate.sh` smoke tests must pass post-rename. S000044 smoke `S3`. |

## Definition of done

- [ ] Both `git mv` operations complete with no orphan references.
- [ ] All 12 `rules/skill-routing.md` entries updated.
- [ ] Both alias `SKILL.md` files print one-line deprecation banner and delegate to new skill.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` pass.
- [ ] Squash-merged PR via `gh pr merge <PR#> --squash --delete-branch` (no `--auto`).

## Not in scope

- Phase 5 drain logic in /CJ_goal_run — S000045.
- Native drain semantics in /CJ_goal_todo_fix — S000046.
- `--quiet` flag — S000047.
- Work-item history rewrite — historical accuracy preserved; only forward-looking references update.
- /CJ_run telemetry merge tool — fallback-read covers v4.x.

## Pointers

- Parent feature tracker: [../F000021_TRACKER.md](../F000021_TRACKER.md)
- Parent feature design: [../F000021_DESIGN.md](../F000021_DESIGN.md)
- Parent roadmap: [../F000021_ROADMAP.md](../F000021_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-165033.md`
