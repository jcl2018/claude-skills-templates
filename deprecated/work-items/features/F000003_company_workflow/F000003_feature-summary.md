---
type: feature-summary
parent: F000003_company_workflow
title: "company-workflow — Feature Summary"
date: 2026-04-24
author: chjiang
status: Backfill
---

<!-- Retroactive backfill: F000003 shipped before feature-summary.md was a
     required feature artifact for personal-workflow (added in this PR's
     manifest update). The original roll-up identity for this feature lives
     in F000003_TRACKER.md (Acceptance Criteria, Insights, Journal). This
     file exists for manifest compliance. -->

## Scope

`company-workflow` is the formal-spec, standalone parallel to `personal-workflow`.
No external skillset / harness dependencies — installs anywhere via `skills-deploy install`.
Owns its own templates (5 trackers, 9 doc types under `templates/company-workflow/`),
its own artifact manifest (`company-artifact-manifests.json`), reference guides,
philosophy notes, and validation logic. Templates are the single source of truth:
the validator derives every structural rule (required frontmatter, sections,
phase headers, minimum checkboxes) by parsing the matching template at runtime.
Also ships knowledge integration: `$AI_KNOWLEDGE_DIR` env-var seam, two-tier
surfacing (always-on + on-demand), `knowledge-doctor` diagnostic.

## Success Criteria

- [x] Skill has no external skillset / harness dependencies; portable to any repo
- [x] `templates/company-workflow/` contains all 13 company spec templates
- [x] `company-artifact-manifests.json` declares 5 type entries (feature, defect, task, user-story, review)
- [x] `company-workflow validate <path>` enforces structural rules and artifact completeness
- [x] `skills-deploy install` deploys skill + templates onto any machine
- [x] `$AI_KNOWLEDGE_DIR` resolution with unset/invalid warnings
- [x] Two-tier surfacing: `surface: always` auto-injects; `surface: on-demand` matches user-prompt triggers
- [x] 500-path / 100KB hard caps prevent context blowup
- [x] Graceful degradation when `$AI_KNOWLEDGE_DIR` is absent (warn to stderr, exit 0)
- [x] Zero regression for existing validate / scaffolding flows (scripted assertion in `scripts/test.sh`)

## Constituent User-Stories

- [S000003 — Company-Workflow Implementation](S000003_company_workflow_implementation/S000003_TRACKER.md) — templates + manifest + validate; CLOSED
- [S000004 — Knowledge Integration](S000004_knowledge_integration/S000004_TRACKER.md) — `$AI_KNOWLEDGE_DIR` env-var resolution + always-on + on-demand surfacing; SHIPPED via PRs #38 (v0.11.0) + #40 (v0.12.0) + #41 (v0.13.0)

## Out-of-Scope

- Seed knowledge content shipped inside the skill repo — `$AI_KNOWLEDGE_DIR` is user-owned and external by design.
- Fuzzy / semantic / embedding-based on-demand matching — v1 is literal-trigger only. Quality of surfacing is bounded by the quality of the user's trigger lists.
- Multi-source knowledge resolution (env var + per-repo overlay) — deferred follow-up; ship single-source first.
