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

See [F000003_TRACKER.md](F000003_TRACKER.md) Log/Insights. company-workflow (originally scaffolded as `company_spec_system`) established the `company-workflow` skill — a parallel track to personal-workflow with its own templates, artifact manifest, validation logic, and 4-phase lifecycle. Renamed and consolidated 2026-04-24 so each skill maps to exactly one feature; the knowledge integration work from former F000004 (S000004 + S000005, both shipped) was absorbed here.

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
| 1 | Skill is standalone — zero gstack dependencies (2026-04-14) | The skill must run on a company machine where gstack isn't installed. No analytics, no `/review`, no `/ship`, no `/docs check` references inside the skill itself. |
| 2 | One unified `validate` command with file mode (template-derived rules) and directory mode (artifact completeness via `company-artifact-manifests.json`) (2026-04-15) | Original 3 subcommands (`validate` / `check` / `create`) were redundant. Templates are the single source of truth — the validator derives rules at runtime, no separate `contract.json` to drift from. |
| 3 | `$AI_KNOWLEDGE_DIR` env-var seam for the knowledge folder, with warn-every-invocation when unset (2026-04-16) | Rejected fixed paths (couples to home-dir layout), per-repo `.knowledge/` (defeats cross-project knowledge), and multi-source overlay (deferred). Single env-var knob, testable in CI, degrades cleanly. Warn-every-invocation nudges configuration over silent value loss. |
| 4 | Two-tier surfacing — `surface: always` auto-injects per invocation; `surface: on-demand` loads only when literal triggers in the user's latest prompt match (2026-04-16) | "Everything always" overwhelms context; "nothing unless asked" loses default-guidance value. Per-category `.knowledge.yml` keeps the mental model simple (one knob per category, not one per file). Literal triggers (no fuzzy/semantic match) keep matching deterministic and reviewable. |
| 5 | Per-repo `.claude/knowledge-enabled` opt-in marker — regular file only, fails closed on symlinks (parent dir AND marker) (2026-04-20) | Central security control: prevents cross-context contamination across repos. A global env var pointed at Company A's knowledge folder must NOT inject Company A guidance into Company B or OSS repos. Symlink fail-closed prevents hostile-planted markers via `.claude → /tmp/attacker` redirect. |
| 6 | One-feature-per-skill consolidation — former `F000004_knowledge_integration` merged into F000003, `F000003_company_spec_system` renamed to `company_workflow` (2026-04-24) | F000004's S000004 + S000005 shipped to company-workflow; the work was scoped under "knowledge integration" rather than "company-workflow", which split the skill's history across two features. Co-locating surfaces the full skill arc (templates → standalone packaging → knowledge integration) in one tracker. |
| 7 | Knowledge helpers extracted to `skills/company-workflow/bin/knowledge-helpers.sh` — single canonical implementation of `parse_knowledge_yml` / `parse_knowledge_triggers` / `list_categories` / `list_md_files`, sourced by every `## Knowledge ...` block in `SKILL.md` via the same 2-level fallback chain as Path Resolution (PR #47, v0.14.3, 2026-04-24) | Inline duplication across 4 blocks (Helpers, Loading, On-Demand Matching, Diagnostic) was fragile — the Diagnostic block carried a separate `_parse` shim with subtly different behavior, plus its own inline trigger awk parser. One canonical file means a bug fix lands once, not four times. SKILL.md dropped 1109 → 851 lines; byte-identity drift tripwire retired (impossible by construction). |

For story-scope detail and the full chronological Journal (15+ entries), see
`F000003_TRACKER.md`. For the per-doc design rationale, see
`skills/company-workflow/philosophy/`.

## Risks & open questions

Feature shipped. Edge-case defects tracked in `work-items/defects/`
(D000003 onward all trace to this feature's original design).

| Risk / Question | Next check |
|-----------------|-----------|
| Personal-workflow knowledge-loading port (S000006) DEFERRED — reopen condition is a specific personal-repo task where missing knowledge-loading is an observed blocker. | Re-evaluate when an actual personal-repo workflow needs cross-repo knowledge; `/autoplan` dual-voice CEO review converged NO-GO on speculative parity work. |

## Definition of done

Feature shipped. Backfill status only.

- [x] Feature shipped (status: closed in TRACKER)

## Not in scope

- Personal-workflow port of knowledge loading — DEFERRED via S000006 after `/autoplan` dual-voice CEO review (now reparented under [F000001_personal_workflow](../F000001_personal_workflow/F000001_TRACKER.md)).
- Seed knowledge content shipped inside the skill repo — `$AI_KNOWLEDGE_DIR` is user-owned and external by design (Milestone #5 dropped 2026-04-21).
- Fuzzy / semantic / embedding-based on-demand matching — v1 is literal-trigger only.
- Multi-source knowledge resolution (env var + per-repo overlay) — deferred follow-up.

## Pointers

- Parent tracker: [F000003_TRACKER.md](F000003_TRACKER.md)
- Milestones: [F000003_milestones.md](F000003_milestones.md)
- Philosophy notes: [skills/company-workflow/philosophy/](../../../skills/company-workflow/philosophy/)
- Defect that required this file: [D000009](../../defects/D000009_personal_workflow_feature_missing_design_doc/D000009_TRACKER.md)
