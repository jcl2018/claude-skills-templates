---
type: architecture
parent: S000016
feature: F000008
title: "Examples + fixtures + repo-level surfaces — Architecture"
version: 1
status: Draft
date: 2026-05-05
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

This story is a long tail of small, file-level edits across three loosely-related surface clusters: examples (visible to humans), fixtures (consumed by tests), and repo-level docs/scripts/registry (read by humans, CI, and external tooling). No single change is large; the risk is missing one. The story's value is in being a single accountable place for "everything else" so reviewers and the validator can both confirm completeness.

The trickiest sub-task is the `scripts/test-deploy.sh` canary swap because a naive sed produces a working bash script that nonetheless references a non-existent path (`$REPO_ROOT/templates/doc-RCA.md`) — the actual file is at `templates/personal-workflow/doc-RCA.md`. Per the design's iteration-3 reviewer concern, this requires a manual line-414 fix after the bulk sed.

## Architecture

```
                    S000014 (templates + manifest + check.md) lands first
                                            |
                                            v
+--------------------------------------------------------------------+
| Three independent subsurface clusters, processed in any order:    |
|                                                                    |
|   1. Examples (8 files)                                            |
|       - Delete 4 example-doc-{PRD,ARCH,feature-summary,milestones}|
|       - Create 2 example-doc-{SPEC,ROADMAP}                        |
|       - Rewrite 2 example-tracker-{feature,user-story}             |
|                                                                    |
|   2. Fixtures (~6 files)                                           |
|       - Migrate valid-feature-dir/ to new shape                    |
|       - Update test.sh assertion for invalid-missing-artifact-dir  |
|       - Audit other fixtures for stale references                  |
|                                                                    |
|   3. Repo-level surfaces (6 files)                                 |
|       - CONTRIBUTING.md table                                      |
|       - PHILOSOPHY.md prose                                        |
|       - template-registry.json doc_types array                     |
|       - scripts/test.sh per-workflow loop split                    |
|       - scripts/test-deploy.sh canary swap + line 414 fix          |
|       - skills-catalog.json templates list                         |
+--------------------------------------------------------------------+
                                            |
                                            v
                Verify: test.sh, validate.sh, test-deploy.sh all PASS
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `skills/personal-workflow/examples/example-doc-PRD.md` | claude-skills-templates | Delete | Old artifact example |
| `skills/personal-workflow/examples/example-doc-ARCHITECTURE.md` | claude-skills-templates | Delete | Old artifact example |
| `skills/personal-workflow/examples/example-doc-feature-summary.md` | claude-skills-templates | Delete | Old artifact example |
| `skills/personal-workflow/examples/example-doc-milestones.md` | claude-skills-templates | Delete | Old artifact example |
| `skills/personal-workflow/examples/example-doc-SPEC.md` | claude-skills-templates | New | Merged PRD + ARCHITECTURE example content |
| `skills/personal-workflow/examples/example-doc-ROADMAP.md` | claude-skills-templates | New | Merged feature-summary + milestones example content |
| `skills/personal-workflow/examples/example-tracker-feature.md` | claude-skills-templates | Modified | Rewritten to mirror new tracker-feature.md template |
| `skills/personal-workflow/examples/example-tracker-user-story.md` | claude-skills-templates | Modified | Rewritten to mirror new tracker-user-story.md template |
| `skills/personal-workflow/fixtures/valid-feature-dir/F999999_feature-summary.md` | claude-skills-templates | Delete | Replaced by ROADMAP |
| `skills/personal-workflow/fixtures/valid-feature-dir/F999999_milestones.md` | claude-skills-templates | Delete | Replaced by ROADMAP |
| `skills/personal-workflow/fixtures/valid-feature-dir/F999999_ROADMAP.md` | claude-skills-templates | New | Merged content |
| `skills/personal-workflow/fixtures/valid-feature-dir/F999999_DESIGN.md` | claude-skills-templates | Modified | Cross-link update |
| `skills/personal-workflow/fixtures/invalid-missing-artifact-dir/` | claude-skills-templates | Audit-only | Fixture file unchanged; test.sh assertion updated |
| `CONTRIBUTING.md` | claude-skills-templates | Modified | Lines 44-45 |
| `PHILOSOPHY.md` | claude-skills-templates | Modified | Lines 25, 42, 43 |
| `template-registry.json` | claude-skills-templates | Modified | personal-workflow entry: version + doc_types |
| `scripts/test.sh` | claude-skills-templates | Modified | Lines 585-592 per-workflow loop split |
| `scripts/test-deploy.sh` | claude-skills-templates | Modified | sed swap (19 refs) + line 414 path fix |
| `skills-catalog.json` | claude-skills-templates | Modified | personal-workflow entry: version + templates list |

### Data Flow

No runtime data flow — pure file edits.

## API Changes

`template-registry.json`'s `personal-workflow.doc_types` array is the closest thing to a public API in this story. External consumers (other repos using `skills-deploy install` to pull personal-workflow templates) read this array to know which doc templates exist. Old contract: `["prd", "architecture", "test-spec", "milestones", "rca", "test-plan"]`. New contract: `["design", "spec", "roadmap", "test-spec", "rca", "test-plan"]`.

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| `template-registry.json` `personal-workflow.doc_types` | `["prd", "architecture", "test-spec", "milestones", "rca", "test-plan"]` | `["design", "spec", "roadmap", "test-spec", "rca", "test-plan"]` | New artifact set |
| `template-registry.json` `personal-workflow.version` | `"2.0.0"` | `"3.0.0"` | Contract change |
| `skills-catalog.json` personal-workflow `templates` list | (current 4 doc + 4 tracker + ...) | (drops doc-PRD, doc-ARCHITECTURE, doc-feature-summary, doc-milestones; adds doc-SPEC, doc-ROADMAP) | Reflect new template set |
| `scripts/test-deploy.sh` canary template name | `doc-PRD.md` | `doc-RCA.md` | doc-PRD.md is being deleted; doc-RCA.md exists in both workflows and is workflow-agnostic for the canary's purpose |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000014 shipped (new templates + manifest) | Feature | Pending | Hard dependency — examples reference templates by name |
| `doc-RCA.md` exists in `templates/personal-workflow/` | File | Available | Verified via `find` |
| External consumers re-read template-registry.json on next deploy | Behavior | Standard | Old consumer state stays read until they pull |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `scripts/test-deploy.sh` line 414 broken path missed after sed | High | Med (test fails, blocks PR) | Explicit Phase 2 step calls out manual line-414 fix after bulk sed |
| Per-workflow loop split in scripts/test.sh accidentally inverts the per-workflow logic | Med | Med | Test by running test.sh once on each workflow; verify both branches succeed |
| External consumers cache old template-registry.json doc_types | Low | Low (downstream tooling re-reads on next deploy) | Out of scope — consumer-side concern |
| Skipped fixture audit leaves stale assertion that breaks check.md output | Med | Low (cosmetic — extra DRIFT or wrong MISSING set) | Phase 2 explicit step: read each fixture file under `fixtures/` |
| `skills-catalog.json` template list drift causes `skills-deploy doctor` warnings | Med | Low (visible warning only) | Update catalog as part of this story; verify with `skills-deploy doctor --quiet` post-change |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| test-deploy.sh canary template | doc-RCA.md | doc-SKILL-DESIGN.md (only template at repo root) | doc-SKILL-DESIGN.md is a different concept (skill-design docs, not work-item artifacts); doc-RCA.md is workflow-agnostic for the canary's drift-detection purpose |
| Fixture audit approach | Read each fixture file individually | Sed across all fixtures uniformly | Fixtures intentionally exercise edge cases; uniform sed could break their assertions |
| CONTRIBUTING/PHILOSOPHY edit scope | Only the lines that name deleted artifacts (44-45 / 25, 42, 43) | Broader doc rewrite to use new artifact-set narrative throughout | YAGNI — narrative quality is fine; only the artifact-name references need updating |
| Order of subsurface processing | Examples → Fixtures → Repo-level | All three in parallel | Sequencing reduces context-switching cost; each cluster is small enough to do start-to-finish |
