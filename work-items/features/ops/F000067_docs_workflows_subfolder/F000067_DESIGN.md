---
type: design
parent: F000067
title: "docs/workflows/ subfolder — per-workflow files + workflow.md as a pure index — Feature Design"
version: 1
status: Draft
date: 2026-06-27
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. -->

## Problem

`docs/workflow.md` has grown to 863 lines / 56KB. The four `CJ_goal_*`
orchestrator sections (`## Orchestrators`, lines 62–406) are ~344 lines / 40% of
the file and the densest (ASCII charts + 4-bullet Touches). The Utilities &
phase-step skills section (~178 lines) and the Utility audits section (~182
lines) add more. The single file is scaling past a comfortable size and mixes a
human-readable overview with deep per-workflow reference detail.

The doc contract (`spec/doc-spec.md` registry + `validate.sh` Checks 15a/15b/19)
currently knows only one workflow doc: `docs/workflow.md`. It has no notion of a
per-workflow subfolder. This feature splits the deep detail into a
`docs/workflows/` subfolder, leaves `workflow.md` as a pure index, and teaches
the doc contract about the two-level structure — as a portable, mandated part of
the contract that every adopting repo inherits.

## Shape of the solution

Reorganize, do not expand: existing content moves verbatim into a
`docs/workflows/` subfolder (one `.md` per workflow); `docs/workflow.md` becomes a
pure top-level index/overview; and the **engine** (`scripts/doc-spec.sh`) +
`validate.sh` + the portable doc-spec seed learn the two-level structure as a
**registry-gated hard mandate**.

What moves where (full split):

| New file under `docs/workflows/` | Moved-from section(s) in `workflow.md` |
|---|---|
| `CJ_goal_feature.md` | `### CJ_goal_feature` (67–154) |
| `CJ_goal_task.md` | `### CJ_goal_task` (155–241) |
| `CJ_goal_defect.md` | `### CJ_goal_defect` (242–320) |
| `CJ_goal_todo_fix.md` | `### CJ_goal_todo_fix` (321–406) |
| `utilities-and-phase-steps.md` | `## How the machinery works` (407–485) + `## Utilities & phase-step skills` (486–664) |
| `utility-audits.md` | `## Utility audits` (665–847) |

`docs/workflow.md` keeps the intro/preamble (1–61), a new compact index (one line
per workflow, linking each `docs/workflows/*.md`), and the `## See also` tail —
~80–120 lines.

The whole change is one cohesive reorganize-plus-teach-the-contract unit, carried
by a single user-story child.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Full split + contract/engine/validator/test/prose changes | S000111 | [S000111_docs_workflows_subfolder/S000111_TRACKER.md](S000111_docs_workflows_subfolder/S000111_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | **Approach C** — bake the requirement into the portable seed, with a hard mandate | Chosen over the recommended overlay-only A: the two-level structure becomes part of the general/portable contract so every adopting repo inherits it, not a workbench-only overlay. |
| 2 | **Full split** (workflow.md → pure index) | Chosen over orchestrators-only: all six dense sections move out; `workflow.md` becomes a pure index/overview (~80–120 lines). |
| 3 | **Mandate** (`docs/workflows/` required + non-empty) | Chosen over "describe + permit": an adopting repo MUST have a non-empty `docs/workflows/`; the engine emits `stage1/workflows-subfolder` when it is missing. |
| 4 | The mandate is **registry-gated** (skips on `REGISTRY=absent`) | A repo that has not adopted the contract is unaffected — the mandate never fires on an unrelated repo. |
| 5 | New light **Check 15c** added alongside the Check 15b retarget | Moving per-orchestrator enforcement to the subfolder requires a no-vanish guarantee that the overview index still names every workflow. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| **Portability impact (headline):** every adopted-contract repo lacking a non-empty `docs/workflows/` now gets a `stage1/workflows-subfolder` FINDING from `/CJ_doc_audit`. | Accepted — the user's explicit uniform-mandate choice. Workbench goes green by creating the 6 files; registry-absent repos unaffected. Verify with the registry-absent temp-dir drill. |
| **3-way byte-identity is fragile** — seed must stay identical across `spec/doc-spec.md`, `templates/doc-spec-common.md`, the `doc-spec.sh --seed` heredoc. | The `tests/cj-document-release-config.test.sh` no-drift test; edit all three in lockstep. |
| **Check 15b retarget must not lose the no-vanish guarantee.** | New Check 15c verifies the overview index links each `CJ_goal_*` orchestrator's subfolder file. |
| **Human-doc lint (Check 19) now applies to the subfolder files** — moved orchestrator content must carry no work-item IDs. | Source sections already comply; verify after the move. |
| **doc-sync prose churn** — `CLAUDE.md`/architecture/philosophy describe the old single-file model in several places. | Step 5.5 doc-sync handles registered docs; the contract-describing prose needs a careful manual full-migration secondary-ref sweep. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `docs/workflow.md` reduced to a pure index (~80–120 lines); six `docs/workflows/*.md` files created with verbatim-moved content (no prose lost; index links all six).
- [ ] Portable seed taught the two-level mandate, 3-way byte-identical; no-drift test green.
- [ ] `doc-spec.sh --check-on-disk` adds `workflows-subfolder` + recursed orphan scan; registry-absent ⇒ exit 0.
- [ ] `spec/doc-spec-custom.md` declares the 6 overlay rows.
- [ ] `validate.sh` Check 15a recurses, Check 15b retargets, new Check 15c added.
- [ ] `spec/test-spec-custom.md` units rows + tests (`doc-spec-overlay`, `cj-document-release-config` no-drift, `test.sh` zzz-test-scaffold fixture) updated.
- [ ] `validate.sh` + `test.sh` green; `/CJ_doc_audit` + `/CJ_test_audit` clean post-sync.
- [ ] Contract-describing prose synced (CLAUDE.md, architecture, philosophy, doc-WORKFLOWS-section template).

## Not in scope

<!-- Explicit non-goals. -->

- Writing new prose depth — "current depth is ok"; this is a verbatim reorganize, not an expansion.
- Restructuring any non-workflow doc (`philosophy.md`, `architecture.md`, `reference.md`) into subfolders — only `docs/workflow.md` is split.
- Changing the doc-spec table grammar or the 3-column registry format — only new rows + a reworded Requirement string + the new engine check are added.
- Retiring or merging any existing `validate.sh` check beyond the targeted 15a/15b changes + the new 15c.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000067_TRACKER.md](F000067_TRACKER.md)
- Roadmap: [F000067_ROADMAP.md](F000067_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/docs-workflows-subfolder-design-20260627-204444.md`
