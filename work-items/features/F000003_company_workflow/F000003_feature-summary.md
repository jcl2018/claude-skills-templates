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
Zero gstack dependencies — installs anywhere via `skills-deploy install`. Owns
its own templates (5 trackers, 9 doc types under `templates/company-workflow/`),
its own artifact manifest (`company-artifact-manifests.json`), reference guides,
philosophy notes, and validation logic. Templates are the single source of truth:
the validator derives every structural rule (required frontmatter, sections,
phase headers, minimum checkboxes) by parsing the matching template at runtime.
Also ships knowledge integration: `$AI_KNOWLEDGE_DIR` env-var seam, two-tier
surfacing (always-on + on-demand), per-repo opt-in marker, `knowledge-doctor`
diagnostic.

## Success Criteria

- [x] Skill has zero gstack dependencies; portable to any repo
- [x] `templates/company-workflow/` contains all 13 company spec templates
- [x] `company-artifact-manifests.json` declares 5 type entries (feature, defect, task, user-story, review)
- [x] `company-workflow validate <path>` enforces structural rules and artifact completeness
- [x] `skills-deploy install` deploys skill + templates onto any machine
- [x] `$AI_KNOWLEDGE_DIR` resolution with unset/invalid warnings (S000004)
- [x] Two-tier surfacing: `surface: always` auto-injects; `surface: on-demand` matches user-prompt triggers (S000005)
- [x] Per-repo opt-in marker (`.claude/knowledge-enabled`) honored, fails closed on symlinks
- [x] 500-path / 100KB hard caps prevent context blowup
- [x] Graceful degradation when `$AI_KNOWLEDGE_DIR` is absent (warn to stderr, exit 0)
- [x] Zero regression for existing validate / scaffolding flows (scripted assertion in `scripts/test.sh`)

## Constituent User-Stories

- [S000003 — Company-Workflow Implementation](S000003_company_workflow_implementation/S000003_TRACKER.md) — templates + manifest + validate; CLOSED
- [S000004 — Env-Var Resolution](S000004_env_var_resolution/S000004_TRACKER.md) — `$AI_KNOWLEDGE_DIR` resolution + warnings; SHIPPED via PR #38 (v0.11.0)
- [S000005 — Knowledge Loading](S000005_knowledge_loading/S000005_TRACKER.md) — always-on + on-demand surfacing; SHIPPED via PRs #40 (v0.12.0) + #41 (v0.13.0)

## Out-of-Scope

- Personal-workflow port of knowledge loading — DEFERRED via S000006 after `/autoplan` dual-voice CEO review (NO-GO, 5/6 dimensions). Now reparented under [F000001_personal_workflow](../F000001_personal_workflow/F000001_TRACKER.md). Reopen condition: a specific personal-repo task where missing knowledge-loading is an observed blocker.
- Seed knowledge content shipped inside the skill repo — `$AI_KNOWLEDGE_DIR` is user-owned and external by design (Milestone #5 dropped 2026-04-21).
- Fuzzy / semantic / embedding-based on-demand matching — v1 is literal-trigger only. Quality of surfacing is bounded by the quality of the user's trigger lists.
- Multi-source knowledge resolution (env var + per-repo overlay) — deferred follow-up; ship single-source first.
