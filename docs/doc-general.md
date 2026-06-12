<!-- AUTO-GENERATED from scripts/generate-doc-views.sh — do not edit -->
# Doc contract — general docs

The general-tier docs (`section: common`) every adopting repo carries, generated from the `spec/doc-spec.md` registry. Do not hand-edit; regenerate with `scripts/generate-doc-views.sh`.

| Doc | Purpose | Requirement |
|-----|---------|-------------|
| docs/philosophy.md | Major design logic, one '## Principle N' section each. | Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs; opens with a summary table at the top listing every principle. |
| docs/workflow.md | The major workflows from a human's perspective; names the major entry points. | Lists every major workflow/entry point a human would invoke; ASCII flowcharts preferred; no work-item IDs; opens with a summary table at the top listing every major workflow/entry point. |
| docs/architecture.md | Meaningful infra under the hood, deeper than workflow.md. | Explains the load-bearing machinery deeper than workflow.md; ASCII diagrams preferred; no work-item IDs. |
| README.md | Repo landing page: folder structure + how to get started. | Has a folder-structure section and a getting-started section naming the major workflows; no work-item IDs. |
| spec/doc-spec.md | The doc contract itself (this file — the general tier, delivered verbatim by doc-spec.sh --seed). | Present; byte-identical to the portable seed (doc-spec.sh --seed); registry parses with schema_version 1; repo-specific docs live in the optional doc-spec-custom.md overlay, never in this file. |
| spec/test-spec.md | The general test contract — portable rules for the repo's verification surface (parsed by test-spec.sh). | Present; the general test contract — rules current against the live verification surface; registry parses with schema_version 1; repo-specific units live in the optional test-spec-custom.md overlay. |
| CLAUDE.md | Agent operating instructions (auto-loaded by Claude Code). | Present; work-item references allowed (operational doc). |
| CHANGELOG.md | Release history (keep-a-changelog). | Present; updated by /ship + /document-release. |
| TODOS.md | The operational backlog. | Present; work-item references allowed (operational doc). |
| docs/doc-general.md | Generated readable view of the section: common (general) registry docs. | Generated from the doc-spec registry via doc-spec.sh --render general; kept matching the merged registry; do not hand-edit. |
| docs/doc-custom.md | Generated readable view of the section: custom registry docs. | Generated from the doc-spec registry via doc-spec.sh --render custom; kept matching the merged registry; do not hand-edit. |
