<!-- AUTO-GENERATED from scripts/generate-doc-views.sh — do not edit -->
# Doc contract — general docs

The general-tier docs (`section: common`) every adopting repo carries, generated from the `spec/doc-spec.md` registry. Do not hand-edit; regenerate with `scripts/generate-doc-views.sh`.

| Doc | Purpose | Requirement |
|-----|---------|-------------|
| docs/philosophy.md | Major design logic, one '## Principle N' section each. | Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs; opens with a summary table at the top listing every principle. |
| docs/workflow.md | The major workflows from a human's perspective; names the major entry points. | Lists every major workflow/entry point a human would invoke; ASCII flowcharts preferred; no work-item IDs; opens with a summary table at the top listing every major workflow/entry point. |
| docs/architecture.md | Meaningful infra under the hood, deeper than workflow.md. | Explains the load-bearing machinery deeper than workflow.md; ASCII diagrams preferred; no work-item IDs. |
| README.md | Repo landing page: folder structure + how to get started. | Has a folder-structure section and a getting-started section naming the major workflows; no work-item IDs. |
| docs/test-pipeline.md | Generated check-level view of the verification surface (rendered from the spec/test-pipeline.md registry). | Generated from the spec/test-pipeline.md registry by scripts/generate-doc-views.sh; kept in sync by validate.sh Check 23; do not hand-edit. |
| spec/doc-spec.md | The doc contract itself (this file). | Present; Common section verbatim from the seed; registry parses with schema_version 1; registry declares every general-contract doc. |
| CLAUDE.md | Agent operating instructions (auto-loaded by Claude Code). | Present; work-item references allowed (operational doc). |
| CHANGELOG.md | Release history (keep-a-changelog). | Present; updated by /ship + /document-release. |
| TODOS.md | Operational backlog wired into /CJ_suggest, /CJ_goal_todo_fix, /ship. | Present; work-item references allowed (operational doc). |
| docs/doc-general.md | Generated readable view of the section:common (general) registry docs. | Generated from the spec/doc-spec.md registry by scripts/generate-doc-views.sh; kept in sync by validate.sh Check 23; do not hand-edit. |
| docs/doc-custom.md | Generated readable view of the section:custom registry docs. | Generated from the spec/doc-spec.md registry by scripts/generate-doc-views.sh; kept in sync by validate.sh Check 23; do not hand-edit. |
