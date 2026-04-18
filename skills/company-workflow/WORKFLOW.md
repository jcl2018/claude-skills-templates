---
name: company-workflow-guide
description: "Doc-driven development workflow, scaffolding conventions, and installation guide for the company-workflow skill."
type: workflow
version: 1.0.0
---

## Doc-Driven Development Workflow

This skill enables a 3-step doc-driven development approach. Documents are
first-class artifacts, not afterthoughts. The `validate` command enforces
structural compliance at every step.

### Step 1: Generate Initial Docs

The engineer gives the AI the big picture. The AI generates work item documents
using two inputs per template type:

- **Template** (`templates/company-workflow/*.md`) -- the structural skeleton
- **Example** (`examples/*.md`) -- a filled-in instance showing tone, depth, and conventions

For each work item type, the AI reads the template for structure and the
corresponding example for content style:

- Feature: tracker + feature-summary + milestones (3 artifacts)
- User-story: tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones (5 artifacts)
- Task: tracker + test-plan (2 artifacts)
- Defect: tracker + RCA + test-plan (3 artifacts)
- Review: tracker + review-notes (2 artifacts)

The feature artifact set is intentionally narrower than user-story's. A feature is the
roll-up identity (scope, success criteria, constituent stories, non-goals — captured in
`feature-summary.md`) plus a delivery roadmap (`milestones.md`). Story-scope detail
(PRD/ARCHITECTURE/TEST-SPEC) lives at the user-story level, not duplicated at feature
level. See D000003 in the workbench's `work-items/defects/` for the rationale.

The full type-to-artifact mapping is in `company-artifact-manifests.json`.

After generation, run `company-workflow validate` to ensure the docs meet the
structural rules. The validator derives those rules from the templates at
runtime (required fields, section order, lifecycle phases, minimum checkbox
count). Templates are the single source of truth.

### Step 2: Align the Big Picture

The engineer works on the docs to align the big picture with reality:

- Refine acceptance criteria in trackers
- Flesh out PRD user stories and acceptance criteria
- Make architecture decisions and record tradeoffs
- Map test cases to requirements in TEST-SPEC
- Adjust milestones and dependency graphs

Run `company-workflow validate` iteratively during this step. File mode catches
structural violations; directory mode catches missing artifacts and frontmatter drift.

### Step 3: Implement and Iterate

Implementation follows the aligned docs. For each task:

1. Read the parent user story's PRD and ARCHITECTURE for context
2. Implement according to the architecture decisions
3. Run `company-workflow validate` on modified docs after updates
4. Update tracker: move through lifecycle phases, add journal entries
5. Verify against TEST-SPEC criteria

The validate command acts as a continuous compliance gate:
- After editing any doc: file mode catches structural drift
- After completing work: directory mode catches missing artifacts
- Before shipping: full validation confirms spec compliance

## Scaffolding Conventions

### Type-to-Artifact Mapping

Each work item type requires specific artifacts. See `company-artifact-manifests.json`
for the canonical mapping. Summary:

| Type | Artifacts | Count |
|------|-----------|-------|
| feature | TRACKER, feature-summary, milestones | 3 |
| user-story | TRACKER, PRD, ARCHITECTURE, TEST-SPEC, milestones | 5 |
| task | TRACKER, test-plan | 2 |
| defect | TRACKER, RCA, test-plan | 3 |
| review | TRACKER, review-notes | 2 |

Note: `userstory` (no hyphen) is accepted as an alias for `user-story`.

Freestanding templates (`doc-scrum.md`, `doc-review-notes.md`) are not tied to any
type's required artifacts. They can be created ad-hoc in any work item directory
or at the repo root, with no ID prefix required.

### test-plan vs TEST-SPEC

Both templates exist because they target different scopes:

- **`test-plan.md`** (defect, task) — **concrete**. One fix or one task. Cases must be
  reproducible and tied to the specific change. For defects, list regression cases
  for the bug. For tasks, list the test cases that prove the change works.
- **`TEST-SPEC.md`** (user-story) — **broader**. Covers the entire story scope. Test
  Matrix maps every PRD acceptance criterion to at least one case across happy, edge,
  and error paths. Includes Tier 1 (smoke) and Tier 2 (E2E) split.

Pick by parent type, not by personal preference. A task that needs a TEST-SPEC-style
matrix usually means the parent user-story's TEST-SPEC is the right home for that
matrix; the task's test-plan stays focused on what *this task's commits* changed.

### ID Generation

IDs use the format `{TYPE_PREFIX}{NNNNNN}`:

| Type | Prefix | Example |
|------|--------|---------|
| feature | F | F000001 |
| user-story | S | S000001 |
| task | T | T000001 |
| defect | D | D000001 |
| review | R | R000001 |

Increment from the highest existing ID of that type in `work-items/`.

### Directory Layout

```
work-items/
  features/{slug}/
    {ID}_TRACKER.md
    {ID}_{artifact}.md
    {child-slug}/              # nested: feature > user-story > task, max depth 3
      {ID}_TRACKER.md
      {ID}_{artifact}.md
  defects/{slug}/
    {ID}_TRACKER.md
    {ID}_{artifact}.md
```

All artifact filenames are prefixed with the item ID at scaffold time.

### Placeholder Replacement

When generating docs from templates, replace these placeholders:

| Placeholder | Value |
|-------------|-------|
| `{ITEM_NAME}` | Human-readable name of the work item |
| `{ITEM_ID}` | Generated ID (e.g., F000001) |
| `{PARENT_ID}` | Parent work item ID (for nested items) |
| `{FEATURE_ID}` | Top-level feature ID |
| `{YYYY-MM-DD}` | Current date |
| `{BRANCH_NAME}` | Current git branch |
| `{author}` | Current user (from `whoami` or git config) |

### Lifecycle

The company spec uses a 4-phase lifecycle:

1. **Track** -- scope the work, scaffold docs, define acceptance criteria
2. **Implement** -- write code, update trackers, commit changes
3. **Review** -- verify quality, run validation, check compliance
4. **Ship** -- create PR, merge, deploy

Each tracker template has lifecycle gates (checkboxes) for each phase.

## Using validate

The `company-workflow validate` command has two modes:

### File Mode

```
company-workflow validate <file>
```

Checks a single tracker file against rules derived from the matching template
at runtime (`templates/company-workflow/tracker-{type}.md`):
- Required frontmatter fields (every key present in the template)
- Required sections (`## ` headings present in the template, in the same order)
- 4-phase lifecycle structure (Track, Implement, Review, Ship — derived from the template's `### Phase N:` headers)
- Minimum checkbox count (counted from the template's Lifecycle section)

Exit 0 if valid, exit 1 with violations on stderr.

### Directory Mode

```
company-workflow validate <dir>
```

Checks a work item directory for artifact completeness:
- Finds `*_TRACKER.md`, reads type from frontmatter
- Looks up required artifacts in `company-artifact-manifests.json`
- For each required artifact: checks file exists, frontmatter keys match template
- Detects unresolved `{PLACEHOLDER}` patterns in frontmatter values
- Reports `[PASS]`, `[MISSING]`, or `[DRIFT]` per artifact

### When to Run

- **Step 1** (after generating docs): verify structural compliance
- **Step 2** (during alignment): catch drift as you edit
- **Step 3** (before shipping): full validation gate

## Installation

Install the complete skill package on any machine:

```bash
# From the workbench repo (recommended):
scripts/skills-deploy install

# Or copy manually:
cp -r skills/company-workflow/ ~/.claude/skills/company-workflow/
cp -r templates/company-workflow/ ~/.claude/templates/company-workflow/
```

### What Gets Deployed

```
~/.claude/skills/company-workflow/
    SKILL.md                          # validate command (template-derived rules)
    WORKFLOW.md                       # this file (scaffolding + workflow)
    company-artifact-manifests.json   # type-to-artifact mapping
    examples/                         # 13 filled-in examples (AI reads these)
    reference/                        # 7 human reference guides
    philosophy/                       # 3 lifecycle rationale docs
    fixtures/                         # test fixtures

~/.claude/templates/company-workflow/
    tracker-*.md                      # 5 tracker templates
    doc-*.md                          # 9 doc templates
```

Use `--overwrite` to force-replace files with local modifications.

### Path Resolution

2-level fallback chain. Works in the workbench repo and on deployed machines:

```
Level 1: $REPO_ROOT/skills/company-workflow/     (workbench)
Level 2: ~/.claude/skills/company-workflow/       (deployed)
```

Templates resolve the same way: `$REPO_ROOT/templates/company-workflow/` then
`~/.claude/templates/company-workflow/`.

## Knowledge Configuration

The skill supports an OPTIONAL external knowledge directory for coding
guidance (e.g. cpp style) and company-specific domain knowledge. When
configured, downstream features (SKILL.md §Knowledge Resolution; the
always-on and on-demand loading layers in F000004) consume its contents.
When unset, the skill still functions — only knowledge features are disabled.

### Setup

Export `AI_KNOWLEDGE_DIR` in your shell profile pointing to a directory of
your choice:

```bash
# ~/.zshrc, ~/.bashrc, or equivalent
export AI_KNOWLEDGE_DIR="$HOME/knowledge"
```

Create the directory and a starter category:

```bash
mkdir -p "$AI_KNOWLEDGE_DIR/coding"
```

The skill emits a one-line warning on **stderr** every invocation when the
variable is unset, empty, points to a non-existent path, or points to a
non-directory. Exit code is unchanged (0 on success). Suppression is
deliberately out of scope for v1 — the warning is the nudge to finish setup.

### Layout

```
$AI_KNOWLEDGE_DIR/
  <category>/              # arbitrary name (coding, domain, runbooks, …)
    .knowledge.yml         # optional — declares surface + triggers
    *.md                   # knowledge files; nesting allowed
    <subdir>/
      *.md
```

The top-level organization is user-shaped: the skill discovers categories by
listing immediate subdirectories of `$AI_KNOWLEDGE_DIR` at runtime. No
taxonomy is hardcoded. `coding/` and `domain/` are illustrative examples —
use whatever category names fit your work (`runbooks/`, `style/`, `security/`,
etc.).

### `.knowledge.yml` Schema

```yaml
# Minimum fields
surface: always         # or: on-demand
triggers: [keyword1, "multi-word phrase"]   # required when surface: on-demand
                                            # ignored when surface: always
```

- **`surface: always`** — the category's markdown files are injected into
  Claude's context on every skill invocation. Use for guidance you want
  applied by default (house style, team conventions).
- **`surface: on-demand`** — the category loads only when a declared trigger
  matches the user's latest message. Match rule: case-insensitive whole-word
  tokens for single-word triggers; case-insensitive phrase match at token
  boundaries for quoted multi-word triggers. Multiple matches → all load.
- A category with **no `.knowledge.yml`** is treated as on-demand with empty
  triggers — it stays dark until you author the file.
- A category with **malformed yml** is skipped with a one-line warning; other
  categories are unaffected.

### Current Status

Knowledge *resolution* (path detection + warning) is live. Knowledge *loading*
(always-on injection, on-demand matching) is under development in feature
[F000004](../../work-items/features/F000004_knowledge_integration/). Until
the loading stories land, `AI_KNOWLEDGE_DIR` is recognized but no content is
loaded into Claude's context.
