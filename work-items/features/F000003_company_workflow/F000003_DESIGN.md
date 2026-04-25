---
type: design
parent: F000003_company_workflow
title: "company-workflow — Feature Design"
version: 1
status: Backfill
date: 2026-04-22
author: chjiang
reviewers: []
---

<!-- Retroactive backfill: F000003 shipped before DESIGN.md was a required
     feature artifact (added in D000009, 2026-04-22). The original design
     decisions for this feature live in F000003_TRACKER.md (Journal +
     Insights) and in the nested user-story ARCHITECTURE.md files. This
     file exists for manifest compliance and as a thin index for future
     readers. -->

## Problem

The `company-workflow` skill — a parallel track to personal-workflow with its own templates, artifact manifest, validation logic, and 4-phase lifecycle. Includes knowledge integration: `$AI_KNOWLEDGE_DIR` env-var seam with two-tier surfacing (always-on + on-demand) so Claude can pull house style / domain knowledge into work-item workflows. See [F000003_TRACKER.md](F000003_TRACKER.md) Log/Insights for the chronological build history.

## Shape of the solution

A second work item skill targeting the company/formal workflow. Cross-story detail lives in the nested user-stories.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| (see nested stories) | S-ids in this dir | (per-story TRACKER/PRD/ARCHITECTURE) |

## Big decisions

The full chronological Journal lives in `F000003_TRACKER.md`. The decisions below
are the architectural through-line — the ones a future maintainer needs to
understand the shape of the skill without reading the whole Journal.

| # | Decision | Why |
|---|----------|-----|
| 1 | Skill is portable: standalone, self-contained, and deployable to any machine (2026-04-14) | (a) **Standalone** — no external skillset / harness dependencies; runs on bash + coreutils. (b) **Self-contained** — all skill assets live under `skills/company-workflow/` (SKILL.md, WORKFLOW.md, `bin/knowledge-helpers.sh`, manifests, reference/, philosophy/, examples/, fixtures/); all templates under `templates/company-workflow/`. No runtime resolution outside these two trees. (c) **Deployable** — `skills-deploy install` copies the bundle to `~/.claude/skills/` + `~/.claude/templates/`. Runtime asset resolution uses a 2-level fallback (repo root → `~/.claude/`) so the skill works identically pre- and post-deploy. **Testable contract:** copy the bundle to a fresh repo on another machine, run validate, must work. |
| 2 | One unified `validate` command with file mode (template-derived rules) and directory mode (artifact completeness via `company-artifact-manifests.json`) (2026-04-15) | Original 3 subcommands (`validate` / `check` / `create`) were redundant. Templates are the single source of truth — the validator derives rules at runtime, no separate `contract.json` to drift from. |
| 3 | `$AI_KNOWLEDGE_DIR` env-var seam for the knowledge folder, with warn-every-invocation when unset (2026-04-16) | Rejected fixed paths (couples to home-dir layout), per-repo `.knowledge/` (defeats cross-project knowledge), and multi-source overlay (deferred). Single env-var knob, testable in CI, degrades cleanly. Warn-every-invocation nudges configuration over silent value loss. |
| 4 | Two-tier surfacing — `surface: always` auto-injects per invocation; `surface: on-demand` loads only when literal triggers in the user's latest prompt match (2026-04-16) | "Everything always" overwhelms context; "nothing unless asked" loses default-guidance value. Per-category `.knowledge.yml` keeps the mental model simple (one knob per category, not one per file). Literal triggers (no fuzzy/semantic match) keep matching deterministic and reviewable. **The only enforced contract is the two `surface` modes (`always` / `on-demand`)**; everything else is user-shaped — category names, nesting, and `*.md` filenames are all user-defined and discovered at runtime via `list_categories()`. The two-tier model is the only context-scoping knob; cross-context isolation is the user's responsibility (control which categories carry which triggers, or unset `$AI_KNOWLEDGE_DIR` per shell). |
| 5 | Knowledge helpers extracted to `skills/company-workflow/bin/knowledge-helpers.sh` — single canonical implementation of `parse_knowledge_yml` / `parse_knowledge_triggers` / `list_categories` / `list_md_files`, sourced by every `## Knowledge ...` block in `SKILL.md` via the same 2-level fallback chain as Path Resolution (PR #47, v0.14.3, 2026-04-24) | Inline duplication across 4 blocks (Helpers, Loading, On-Demand Matching, Diagnostic) was fragile — the Diagnostic block carried a separate `_parse` shim with subtly different behavior, plus its own inline trigger awk parser. One canonical file means a bug fix lands once, not four times. SKILL.md dropped 1109 → 851 lines; byte-identity drift tripwire retired (impossible by construction). |

For story-scope detail and the full chronological Journal (15+ entries), see
`F000003_TRACKER.md`. For the per-doc design rationale, see
`skills/company-workflow/philosophy/`.

## Risks & open questions

Feature shipped. Edge-case defects tracked in `work-items/defects/`
(D000003 onward all trace to this feature's original design).

## Definition of done

Feature shipped. Backfill status only.

- [x] Feature shipped (status: closed in TRACKER)

## Not in scope

- Seed knowledge content shipped inside the skill repo — `$AI_KNOWLEDGE_DIR` is user-owned and external by design.
- Fuzzy / semantic / embedding-based on-demand matching — v1 is literal-trigger only.
- Multi-source knowledge resolution (env var + per-repo overlay) — deferred follow-up.

## Pointers

- Parent tracker: [F000003_TRACKER.md](F000003_TRACKER.md)
- Milestones: [F000003_milestones.md](F000003_milestones.md)
- Philosophy notes: [skills/company-workflow/philosophy/](../../../skills/company-workflow/philosophy/)
- Defect that required this file: [D000009](../../defects/D000009_personal_workflow_feature_missing_design_doc/D000009_TRACKER.md)
