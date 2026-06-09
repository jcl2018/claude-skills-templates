<!-- AUTO-GENERATED from scripts/generate-doc-views.sh — do not edit -->
# Doc contract — custom docs

This repo's custom-tier docs (`section: custom`) beyond the general set, generated from the `spec/doc-spec.md` registry. Do not hand-edit; regenerate with `scripts/generate-doc-views.sh`.

| Doc | Purpose | Requirement |
|-----|---------|-------------|
| spec/doc-spec.md | The doc contract itself (this file). | Present; Common section verbatim from the seed; registry parses with schema_version 1. |
| spec/gate-spec.md | The cj_goal verification contract — what stops a broken change from landing, and at which layer (parsed by scripts/gate-spec.sh). | Present; one fenced yaml registry of layers[] + gates[] parsing with schema_version 1; every declared literal marker present in its mode's pipeline. |
| CLAUDE.md | Agent operating instructions (auto-loaded by Claude Code). | Present; work-item references allowed (operational doc). |
| CHANGELOG.md | Release history (keep-a-changelog). | Present; updated by /ship + /document-release. |
| CONTRIBUTING.md | Contributor authoring guide. | Present; surfaced by GitHub from the repo root. |
| TODOS.md | Operational backlog wired into /CJ_suggest, /CJ_goal_todo_fix, /ship. | Present; work-item references allowed (operational doc). |
| spec/permission-policy.md | The cj_goal allow/ask/deny permission contract (parsed by scripts/permission-policy.sh). | Present; one fenced yaml policy registry parsing with schema_version 1; risky verbs enumerated as deny/ask. |
| docs/doc-general.md | Generated readable view of the section:common (general) registry docs. | Generated from the spec/doc-spec.md registry by scripts/generate-doc-views.sh; kept in sync by validate.sh Check 23; do not hand-edit. |
| docs/doc-custom.md | Generated readable view of the section:custom registry docs. | Generated from the spec/doc-spec.md registry by scripts/generate-doc-views.sh; kept in sync by validate.sh Check 23; do not hand-edit. |
