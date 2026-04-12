---
name: "copy-spec-templates-create-skill-scaffold"
type: task
id: "T000002_copy_spec_scaffold"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "S000003_template_registry"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Files section populated

### Phase 2: Implement
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Review
- [x] Doc review completed
- [x] Doc generation finalized
- [x] Test verification passed — T000002 test-plan 9/9 Pass, S000003 Tier 1 smoke S1-S8 all Pass. E2E tests moved to S000005.

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [x] Copy ~/Downloads/spec/templates/*.md → templates/company-workflow/ (13 files, byte-identical)
- [x] Copy ~/Downloads/spec/contract.json → skills/company-workflow/contract.json
- [x] Copy ~/Downloads/spec/reference/guide-*.md → skills/company-workflow/reference/ (7 files)
- [x] Copy ~/Downloads/spec/philosophy/rationale-*.md → skills/company-workflow/philosophy/ (3 files)
- [x] Copy ~/Downloads/spec/reference/invalid-*.md → skills/company-workflow/fixtures/ (3 files)
- [x] Create skills/company-workflow/SKILL.md with frontmatter, fallback chain, routing table, validate subcommand
- [x] Add company-workflow entry to skills-catalog.json (templates: [] per eng review)
- [x] Run ./scripts/validate.sh — PASS (0 errors, 0 warnings)
- [x] Run ./scripts/test.sh — PASS (0 failures)

## Log

- 2026-04-11: Created. One-time manual copy of company spec into repo structure + skill scaffold. Child of S000003.
- 2026-04-11: Implemented. 27 files copied (13 templates + 1 contract + 7 guides + 3 rationale + 3 fixtures). SKILL.md created with 2-level fallback chain. Catalog entry added. validate.sh PASS, test.sh PASS.

## PRs

## Files

- templates/company-workflow/tracker-feature.md
- templates/company-workflow/tracker-defect.md
- templates/company-workflow/tracker-task.md
- templates/company-workflow/tracker-user-story.md
- templates/company-workflow/tracker-review.md
- templates/company-workflow/doc-ARCHITECTURE.md
- templates/company-workflow/doc-PRD.md
- templates/company-workflow/doc-RCA.md
- templates/company-workflow/doc-TEST-SPEC.md
- templates/company-workflow/doc-milestones.md
- templates/company-workflow/doc-review-notes.md
- templates/company-workflow/doc-scrum.md
- templates/company-workflow/doc-test-plan.md
- skills/company-workflow/SKILL.md
- skills/company-workflow/contract.json
- skills/company-workflow/reference/
- skills/company-workflow/philosophy/
- skills/company-workflow/fixtures/
- skills-catalog.json

## Insights

- Source files at ~/Downloads/spec/ are a one-time import. After commit, the repo becomes the source of truth.
- The spec has 13 template files, 7 guide files, 3 rationale files, and 3 invalid fixture files.

## Journal

- 2026-04-11 [finding]: Spec templates differ from existing templates in key ways: workflow_type field, url field, verbose lifecycle checkboxes, review type support, scrum doc type.
