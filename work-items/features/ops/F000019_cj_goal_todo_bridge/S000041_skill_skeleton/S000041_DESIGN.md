---
type: design
parent: S000041
title: "Skill skeleton + scripts/goal.sh + catalog + routing + eval — Design"
version: 1
status: Draft
date: 2026-05-14
author: chjiang
reviewers: []
---

<!-- This story's DESIGN is a brief stub linking to the parent feature's
     design. The full multi-iteration /office-hours design lives at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260514-162927.md.
     Parent feature design at ../F000019_DESIGN.md captures the cross-story
     shape. This story is atomic — all build work lives here. -->

## Problem

The parent feature F000019 needs a single implementable user-story that builds
the complete /CJ_goal v1 skill from scratch. Source design specifies a thin
SKILL.md wrapper that dispatches to scripts/goal.sh containing the load-bearing
logic, plus catalog/routing/eval surfaces.

## Mental Model

Single atomic story = single PR. Implementation is mostly orchestration over
already-shipped pieces (/CJ_suggest ranking, tracker-task.md template,
doc-test-plan.md template, /CJ_scaffold-work-item Step 5 ID picker,
/CJ_personal-pipeline's task-type dispatch, /ship Gate #2, /land-and-deploy
v3.4.0 `--suppress-readiness-gate`). The genuinely new code is:

1. Pre-flight gates (suffix parse, priority/size cap, body-extract, sensitive-surface scan, design-needed keyword, idempotency)
2. TODOS.md parser (handles `## Active work` and domain-grouped shapes)
3. T-task scaffold writes (TRACKER + test-plan)
4. Direct-dispatch chain (/CJ_personal-pipeline → /ship → /land-and-deploy)
5. Per-session skip-list mechanic
6. Hash-verify TODOS.md DONE-mark write
7. Telemetry write

## Pointers

- Parent feature design: [../F000019_DESIGN.md](../F000019_DESIGN.md)
- Parent feature tracker: [../F000019_TRACKER.md](../F000019_TRACKER.md)
- SPEC: [S000041_SPEC.md](S000041_SPEC.md)
- TEST-SPEC: [S000041_TEST-SPEC.md](S000041_TEST-SPEC.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260514-162927.md`
