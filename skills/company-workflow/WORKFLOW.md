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

### Hierarchy & Placement

When scaffolding a work item, the generating AI must also scaffold its required
children in the same operation. Structural completeness is enforced at scaffolding
time by the AI reading this spec, not by a separate validator or scaffolder script.
This matches the D000007 philosophy: templates + WORKFLOW.md are the source of
truth; the AI reads them and follows them.

**Required children (scaffold these alongside the parent):**

- **feature** -> at least 1 user-story child
- **user-story** -> at least 1 task child
- **task, defect, review** -> no required children

**Placement rules:**

| Type | Location |
|------|----------|
| feature | `work-items/features/{ID}_{slug}/` |
| defect | `work-items/defects/{ID}_{slug}/` |
| review | `work-items/reviews/{ID}_{slug}/` |
| user-story | nested under a feature: `work-items/features/{feature-ID}_{slug}/{ID}_{slug}/` |
| task | nested under a user-story |

**Directory naming rule:** every work-item directory must be `{ID}_{slug}/` where:
- `{ID}` matches the type prefix (F/S/T/D/R) + 6 digits (e.g., `F000003`, `R000001`)
- `{slug}` matches `[a-z0-9_-]+` (lowercase, no spaces or capitals)
- The `{ID}` inside the directory name must match the `id` field in the TRACKER
  frontmatter

**Common mistakes to avoid:**

- Creating `work-items/features/F000003_my-feature/` with no child user-story directory
- Creating a user-story at `work-items/user-stories/` (they always nest under a feature)
- Using bare slugs like `work-items/features/my-feature/` without the ID prefix
- Mismatching the ID in the directory name vs. the ID in the TRACKER frontmatter

**Legacy directories:** if you encounter an existing bare-slug directory (e.g.,
`work-items/features/my-feature/` without an ID prefix), treat it as legacy. Don't
auto-rename. Flag it to the user and let them decide whether to migrate.

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
guidance (e.g. cpp style) and company-specific domain knowledge. When a
category is marked `surface: always` and the current repo has opted in via
`.claude/knowledge-enabled`, the category's markdown files are injected into
Claude's context on every skill invocation — no copy-paste needed.

v1 ships always-on loading only. On-demand trigger matching (categories that
load when the user's message mentions a trigger word) is deferred to a
follow-up story, gated on observed user need. You can author `surface: on-demand`
yml today — the parser accepts it as valid and silently skips it in v1, so
your yml will activate cleanly when the follow-up ships.

### Quick Start (5-line copy-paste)

```bash
export AI_KNOWLEDGE_DIR="$HOME/knowledge"
mkdir -p "$AI_KNOWLEDGE_DIR/coding"
printf 'surface: always\n' > "$AI_KNOWLEDGE_DIR/coding/.knowledge.yml"
printf '# Canary\nCANARY_SETUP_TEST\n' > "$AI_KNOWLEDGE_DIR/coding/notes.md"
mkdir -p .claude && touch .claude/knowledge-enabled
```

Then run `/company-workflow knowledge-doctor` in this repo. You should see
`result: loading enabled; 1 paths will be emitted to Claude`. Ask Claude
what canary strings it has seen; it should quote `CANARY_SETUP_TEST`.

Add `AI_KNOWLEDGE_DIR=...` to `~/.zshrc` / `~/.bashrc` so it persists across
shell sessions.

### Troubleshooting

Run `/company-workflow knowledge-doctor` first. It prints the state of every
precondition. Common traps:

| Symptom | Cause | Fix |
|---|---|---|
| `Warning: AI_KNOWLEDGE_DIR not set` on every skill run | Env var not exported | `export AI_KNOWLEDGE_DIR="$HOME/knowledge"` |
| `Warning: AI_KNOWLEDGE_DIR=... not found` | Path doesn't exist | `mkdir -p "$AI_KNOWLEDGE_DIR"` |
| `has always-on categories but .claude/knowledge-enabled is absent` | Repo not opted in | `touch .claude/knowledge-enabled` in the repo root |
| `malformed .knowledge.yml at ...` | yml has an unknown key, single-quoted value, or similar | Fix the yml (see Schema below); only `surface` + `triggers` keys are recognized |
| Always-On section is emitted but Claude isn't quoting canaries | Claude didn't Read the files | Check the doctor output — are paths actually listed? If so, ask Claude directly |
| `loading aborted: N paths / N bytes exceeds cap` | Too much always-on content | Reduce files, or mark some categories `surface: on-demand` (reserved for c3 follow-up) |

### Escape Hatches

- **One-shot disable:** `AI_KNOWLEDGE_DISABLE=1 /company-workflow ...` — bypasses
  all loading for that invocation regardless of marker state. Use when
  debugging a bad knowledge file without `rm`-ing the committed marker.
- **Per-repo disable:** delete `.claude/knowledge-enabled` (re-add when ready).
- **Per-category disable:** delete or rename the category's `.knowledge.yml`.
  Missing yml is a silent skip.
- **Per-category opt-in later:** author yml as `surface: on-demand` (currently
  inert in v1, ready for c3 follow-up).

### Layout

```
$AI_KNOWLEDGE_DIR/
  <category>/              # arbitrary name (coding, domain, runbooks, …)
    .knowledge.yml         # declares surface mode
    *.md                   # knowledge files; nesting allowed
    <subdir>/
      *.md
<repo root>/
  .claude/
    knowledge-enabled      # empty file; presence = repo opts into knowledge loading
```

The top-level organization is user-shaped: the skill discovers categories by
listing immediate subdirectories of `$AI_KNOWLEDGE_DIR` at runtime. No
taxonomy is hardcoded. `coding/` and `domain/` are illustrative examples —
use whatever category names fit your work (`runbooks/`, `style/`, `security/`,
etc.).

### `.knowledge.yml` Schema

```yaml
surface: always        # v1 active: files load on every skill invocation
# or:
surface: on-demand     # v1 inert (forward-compat — activates with c3 follow-up)
triggers: [keyword1, "multi-word phrase"]   # used in c3 follow-up; v1 ignores
```

**Supported value forms for `surface`:**
- Bare: `surface: always`
- Double-quoted: `surface: "always"`
- With inline comment: `surface: always # house style`
- CRLF line endings and UTF-8 BOM are tolerated.

**NOT supported (treated as malformed):**
- Single-quoted: `surface: 'always'` (v1 limitation; use bare or double-quoted).
- Unknown root keys (anything other than `surface` / `triggers`).
- Multi-line scalars, YAML anchors, etc.

**Category behavior summary:**

| `.knowledge.yml` | v1 behavior | c3 follow-up |
|---|---|---|
| `surface: always` | Content loaded every invocation | (unchanged) |
| `surface: on-demand` | Silent skip (forward-compat) | Loaded when triggers match user prompt |
| Missing | Silent skip | (unchanged) |
| Malformed | Category skipped, one-line stderr warning | (unchanged) |

### Security

The per-repo opt-in marker (`.claude/knowledge-enabled`) is the central
security control. Without it, no knowledge loads — even when `$AI_KNOWLEDGE_DIR`
is valid and categories exist. This prevents cross-context contamination:
a global env var pointed at Company A's knowledge folder will NOT inject
Company A guidance into Company B or OSS repos.

The marker must be a regular file (not a symlink, not a directory). Symlinks
fail closed (blocks hostile-planted markers via symlink). The marker's parent
`.claude/` directory must also not be a symlink — a `repo/.claude -> /tmp/attacker`
redirect would otherwise allow an out-of-repo file to pass the regular-file
check. Both parent-symlink and marker-symlink are explicitly rejected.

Knowledge file content is Read into Claude's context on every invocation —
same trust boundary as any other Read call, which means knowledge files are a
potential prompt-injection channel if unreviewed. Review knowledge files
before opting a repo in. Don't commit secrets, PII, or unreviewed third-party
content into the knowledge folder. A malicious `.md` (synced from a
compromised source, auto-generated, committed by a rushed colleague) becomes
a full prompt-injection surface on every `/company-workflow` invocation in
the opted-in repo.

File paths containing control characters (newline, CR) are rejected during
enumeration — they'd otherwise forge line structure in the `## Always-On
Knowledge` block Claude sees. Hidden files and directories (anything starting
with `.`) under a category are skipped, so a stray `.draft/notes.md` won't
leak into Claude's context.

### Bytes + path caps

v1 enforces:
- **500 path cap:** no more than 500 absolute paths emitted under
  `## Always-On Knowledge`.
- **100KB byte cap:** cumulative content of emitted `*.md` files.

Either cap tripped → hard-fail warning, nothing loads (better a loud failure
than silent context blowup). If you hit the cap, consider splitting your
most sprawling category into multiple categories and moving some to
`surface: on-demand` (reserved for c3 follow-up).

### Diagnostic: knowledge-doctor

Run `/company-workflow knowledge-doctor` to see the exact state of every
precondition and every category. Sample output:

```
AI_KNOWLEDGE_DIR: /Users/chjiang/knowledge (exists)
repo_root: /Users/chjiang/Documents/projects/claude-skills-templates
marker: .claude/knowledge-enabled (present)
disable env var: not set
categories:
  coding      surface=always     files=3    bytes=8.2KB    loads=yes
  runbooks    surface=on-demand  files=5    bytes=12.1KB   loads=no (v1 deferred)
  notes       surface=(missing yml)         loads=no
  broken      surface=(malformed yml)       loads=no (warning)
cap status: 3/500 paths, 8.2KB/100KB bytes
result: loading enabled; 3 paths will be emitted to Claude
```

### Current Status

- **Resolution** (path detection + unset/invalid warnings): shipped in S000004
  (PR #38).
- **Always-on loading + per-repo opt-in gate + knowledge-doctor**: shipped in
  S000005 (T000006 c1+c2).
- **On-demand trigger matching + trigger DSL**: deferred to a follow-up story
  after /autoplan CEO dual-voice review (2026-04-21). Unblock condition: a
  specific user incident where always-on alone was insufficient and on-demand
  trigger matching would have saved context/time. See
  [F000004 feature tracker](../../work-items/features/F000004_knowledge_integration/F000004_TRACKER.md)
  for status.
