# /autoplan Restore Point
Captured: 2026-04-16T05:02:46Z | Branch: claude-nostalgic-volhard | Commit: 6f1fb99

## Re-run Instructions
1. Copy "Original Plan State" below back to your plan file
2. Invoke /autoplan

## Original Plan State
# Plan: Restructure /docs into /personal-workflow

## Context

The `/docs` skill is entangled with repo-root state (`artifact-manifests.json`,
`templates/*.md`, `rules/work-items.md`). The `/company-workflow` skill is fully
self-contained. This plan restructures `/docs` into `/personal-workflow` to match
company-workflow's self-contained pattern, making the two skills independent and
easy to compare side-by-side.

Design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-nostalgic-volhard-design-20260415-214255.md`
(APPROVED by /office-hours on 2026-04-15)

Key decisions from /office-hours:
- Kill `/docs init` entirely (narrative doc generation, claims sidecar, staleness detection)
- Keep `check` + `tree` subcommands
- Rewrite check.md with Tier 1 (contract.json foundation matching company-workflow) + Tier 2 (personal extensions)
- Templates move to `templates/personal-workflow/`
- `rules/work-items.md` replaced by WORKFLOW.md inside the skill
- 2-level fallback, drop `~/.claude/spec/templates/` middle level

## Step 1: Create skill directory structure

Create `skills/personal-workflow/` with the same subdirectories as company-workflow:

```
skills/personal-workflow/
  SKILL.md
  WORKFLOW.md
  contract.json
  personal-artifact-manifests.json
  check.md
  tree.md
  fixtures/
  examples/
```

Files to create:
- `skills/personal-workflow/SKILL.md` — thin router with check + tree dispatch
- `skills/personal-workflow/contract.json` — 3-phase lifecycle structural rules
- `skills/personal-workflow/personal-artifact-manifests.json` — from repo-root `artifact-manifests.json`

### SKILL.md

```yaml
---
name: personal-workflow
description: "Personal work item validation with structural completeness checks. Validates tracker files and work item directories against personal templates, contract.json, and personal-artifact-manifests.json."
version: 1.0.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
---
```

Thin router: `/personal-workflow check` → read check.md, `/personal-workflow tree` → read tree.md.
Path resolution: 2-level fallback (repo then ~/.claude).

### contract.json

```json
{
  "version": 1,
  "frontmatter": {
    "required": ["name", "type", "status", "created", "updated"],
    "recommended": ["repo", "branch"]
  },
  "sections": {
    "required": ["Lifecycle", "Todos", "Log", "PRs", "Files", "Journal"],
    "optional": ["Acceptance Criteria", "Reproduction Steps", "Insights"],
    "expected_order": ["Lifecycle", "Acceptance Criteria", "Reproduction Steps", "Todos", "Log", "PRs", "Files", "Insights", "Journal"],
    "order_skip_absent": true,
    "type_specific_optional": {
      "feature": ["Acceptance Criteria"],
      "user-story": ["Acceptance Criteria"],
      "defect": ["Reproduction Steps"],
      "task": []
    }
  },
  "lifecycle": {
    "min_checkboxes": 3,
    "phases": ["Track", "Implement", "Ship"]
  }
}
```

### personal-artifact-manifests.json

Move content from repo-root `artifact-manifests.json`. Same schema. Remove `review` type.
Keep `hierarchy` and `placement` fields (used by Tier 2 checks).

## Step 2: Move templates

Move 10 templates from `templates/*.md` to `templates/personal-workflow/`:
- 4 trackers: tracker-feature.md, tracker-user-story.md, tracker-task.md, tracker-defect.md
- 6 docs: doc-PRD.md, doc-ARCHITECTURE.md, doc-TEST-SPEC.md, doc-milestones.md, doc-RCA.md, doc-test-plan.md

Keep at repo root: `templates/doc-SKILL-DESIGN.md` (skill-authoring, not work items).

## Step 3: Rewrite check.md (Tier 1 + Tier 2)

Rewrite `skills/personal-workflow/check.md` with clear tier separation:

**Tier 1: Foundation (Steps 1-13)** — matches company-workflow validate approach:
- File Mode (Steps 1-7): validate single file against contract.json
- Directory Mode (Steps 7-13): validate directory against personal-artifact-manifests.json

**Tier 2: Extensions (Steps 14-23)** — personal-workflow only:
- Recursive walk + model building (Steps 14-15)
- Cross-checks: template compliance, lifecycle consistency, traceability, structural completeness (Steps 16-19)
- Outputs: badge taxonomy, tree report, graph artifact, human-readable report (Steps 20-23)

Invocation model:
- File path → Tier 1 File Mode only
- Directory path → Tier 1 Directory Mode + Tier 2
- No path → both tiers on full work-items/ directory
- No work-items/ dir → skip Tier 2 with INFO message

Key reuse: existing check.md Steps 6-19 logic is preserved in Tier 2 (Steps 14-23).

## Step 4: Adapt tree.md

Update path resolution from repo-root to 2-level skill fallback.
Read manifest from `$_SKILL_DIR/personal-artifact-manifests.json` instead of
`$REPO_ROOT/artifact-manifests.json`.

## Step 5: Write WORKFLOW.md

Adapt from `rules/work-items.md`. Contains scaffolding conventions:
- 3-step doc-driven workflow
- Type-to-artifact mapping (4 types)
- ID generation (F/S/T/D prefixes)
- Directory layout
- Placeholder replacement
- 3-phase lifecycle
- Installation instructions
- Template resolution: 2-level fallback

## Step 6: Create fixtures

Create from scratch (no existing fixtures to migrate):
- `fixtures/valid-tracker.md` — valid 3-phase tracker
- `fixtures/invalid-missing-section.md` — missing Journal section
- `fixtures/invalid-wrong-order.md` — sections out of order
- `fixtures/invalid-bad-frontmatter.md` — malformed YAML
- `fixtures/invalid-missing-lifecycle.md` — no Lifecycle section
- `fixtures/valid-feature-dir/` — complete feature with all artifacts
- `fixtures/invalid-missing-artifact-dir/` — feature missing milestones.md

## Step 7: Delete old files

- `skills/docs/` (entire directory)
- `artifact-manifests.json` (repo root)
- `rules/work-items.md`
- `templates/tracker-feature.md`, `tracker-user-story.md`, `tracker-task.md`, `tracker-defect.md`
- `templates/doc-PRD.md`, `doc-ARCHITECTURE.md`, `doc-TEST-SPEC.md`, `doc-milestones.md`, `doc-RCA.md`, `doc-test-plan.md`

## Step 8: Update catalog and config

### skills-catalog.json
- Remove "docs" entry
- Add "personal-workflow" entry with templates: `["personal-workflow/tracker-*.md", "personal-workflow/doc-*.md"]`
- Update "templates" entry: retains only `doc-SKILL-DESIGN.md`

### CLAUDE.md — 5 changes:
1. Skill routing: replace /docs with /personal-workflow
2. Remove "Work item templates" paragraph (now in WORKFLOW.md)
3. Template naming: show `templates/personal-workflow/` and `templates/company-workflow/`
4. Template deployment fallback: 2-level (drop `~/.claude/spec/templates/`)
5. Remove `artifact-manifests.json` reference

### template-registry.json
- Add "personal-workflow" set pointing to `templates/personal-workflow/`
- Remove stale "workbench" set

## Step 9: Create examples/ directory

Empty for v1. Populate later when examples are written.

## Migration

Breaking change: scaffolding rules move from global (`~/.claude/rules/work-items.md`)
to skill-invocation-scoped (WORKFLOW.md). Users must invoke `/personal-workflow` to
access scaffolding conventions.

For `skills-deploy` users:
- `skills-deploy remove` first (cleans old /docs deployment)
- `skills-deploy install` (deploys new personal-workflow)
- Manual cleanup: `rm ~/.claude/templates/tracker-*.md ~/.claude/templates/doc-*.md`

## Critical files

- `skills/docs/SKILL.md` → deleted, replaced by `skills/personal-workflow/SKILL.md`
- `skills/docs/check.md` → rewritten as `skills/personal-workflow/check.md`
- `skills/docs/tree.md` → adapted as `skills/personal-workflow/tree.md`
- `artifact-manifests.json` → moved to `skills/personal-workflow/personal-artifact-manifests.json`
- `rules/work-items.md` → replaced by `skills/personal-workflow/WORKFLOW.md`
- `skills-catalog.json` → updated entries
- `CLAUDE.md` → 5 routing/config changes
- `template-registry.json` → updated sets

## Verification

1. `ls skills/personal-workflow/` and `ls skills/company-workflow/` show same directory structure
2. Run `./scripts/validate.sh` — should pass with new structure
3. Run `./scripts/test.sh` — should pass
4. Verify no file in personal-workflow references `artifact-manifests.json` at repo root
5. Verify no file in personal-workflow references `templates/*.md` at repo root (only `templates/personal-workflow/`)
6. `grep -r "artifact-manifests.json" skills/personal-workflow/` should return 0 results
7. `grep -r "templates/" skills/personal-workflow/ | grep -v "personal-workflow"` should return 0 results
