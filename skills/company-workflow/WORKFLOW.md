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
guidance (e.g. cpp style) and company-specific domain knowledge. Two
surfacing modes:

- **`surface: always`** — the category's `*.md` files are Read into Claude's
  context on every skill invocation. Use for guidance you want applied
  unconditionally (house coding style, team conventions).
- **`surface: on-demand`** — the category loads only when the user's latest
  message mentions one of the category's declared triggers. Use for
  situational material (domain runbooks, language references, internal
  acronyms) where loading unconditionally would waste context.

Both modes activate whenever `$AI_KNOWLEDGE_DIR` resolves to a valid directory.
Cross-context isolation is the user's responsibility — scope `$AI_KNOWLEDGE_DIR`
per shell or per repo if you want to keep one client's knowledge out of another.

### Quick Start (4-line copy-paste)

```bash
export AI_KNOWLEDGE_DIR="$HOME/knowledge"
mkdir -p "$AI_KNOWLEDGE_DIR/coding"
printf 'surface: always\n' > "$AI_KNOWLEDGE_DIR/coding/.knowledge.yml"
printf '# Canary\nCANARY_SETUP_TEST\n' > "$AI_KNOWLEDGE_DIR/coding/notes.md"
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
| `malformed .knowledge.yml at ...` | yml has an unknown key, single-quoted value, or similar | Fix the yml (see Schema below); only `surface` + `triggers` keys are recognized |
| Always-On section is emitted but Claude isn't quoting canaries | Claude didn't Read the files | Check the doctor output — are paths actually listed? If so, ask Claude directly |
| `loading aborted: N paths / N bytes exceeds cap` | Too much always-on content | Reduce files, or mark some categories `surface: on-demand` with triggers so they only load when relevant |

### Escape Hatches

- **One-shot disable:** `AI_KNOWLEDGE_DISABLE=1 /company-workflow ...` — bypasses
  all loading for that invocation. Use when debugging a bad knowledge file
  without unsetting the env var.
- **Session disable:** `unset AI_KNOWLEDGE_DIR` (or `export AI_KNOWLEDGE_DIR=`)
  in the shell where you want loading off.
- **Per-category disable:** delete or rename the category's `.knowledge.yml`.
  Missing yml is a silent skip.
- **Per-category opt-in later:** author yml as `surface: on-demand` with
  narrow triggers — the category only loads when the user's prompt mentions
  one of those triggers.

### Layout

```
$AI_KNOWLEDGE_DIR/
  <category>/              # arbitrary name (coding, domain, runbooks, …)
    .knowledge.yml         # declares surface mode
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
# Always-on: content loads on every skill invocation
surface: always

# --- or ---

# On-demand: content loads only when the user's latest message mentions a trigger
surface: on-demand
triggers: [pricing, "pricing engine", PE]
```

Both inline flow form (`triggers: [a, "b c", 'd']`) and block form work:

```yaml
surface: on-demand
triggers:
  - pricing
  - "pricing engine"
  - PE
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

| `.knowledge.yml` | Behavior |
|---|---|
| `surface: always` | Content loaded on every invocation |
| `surface: on-demand` + non-empty `triggers` | Loaded when user's latest message matches a trigger |
| `surface: on-demand` + empty/missing `triggers` | Inert — never loads until you add triggers |
| Missing | Silent skip |
| Malformed | Category skipped, one-line stderr warning |

### Trigger authoring guidance

Triggers are literal keywords or phrases. The match is:
- **Single-word triggers** (no spaces): case-insensitive whole-word match
  against prompt tokens. `pricing` matches `Pricing` and `PRICING` but NOT
  `pricingengine` (substring inside a word).
- **Multi-word phrase triggers** (contain spaces, must be quoted in yml):
  case-insensitive phrase match at token boundaries. `"pricing engine"`
  matches "how does the pricing engine work" but NOT "what is pricing" alone.

Good trigger hygiene:
- **Specific > generic.** `"pricing engine"` beats `pricing` — fewer false
  positives for unrelated prompts that happen to mention pricing.
- **Include your domain's internal acronyms** — `PE`, `OKR`, `SLA` — if
  colleagues type them, the category should load.
- **Avoid common English words** — `the`, `and`, `code` — these match
  everything and defeat the on-demand filter.
- **Watch false positives in diagnostic logs.** Every match emits a
  `[knowledge] matched: <cat> via <trigger>` line on stderr. If you see
  unexpected matches, narrow the trigger.

On-demand loading is narrowed to the **user's latest message only** —
not prior turns, not system prompt, not Claude's own replies. Keeps
context from ballooning over long conversations.

### Security

**Cross-context isolation is the user's responsibility.** Knowledge loads
whenever `$AI_KNOWLEDGE_DIR` resolves to a valid directory — there is no
per-repo opt-in gate. If you work across multiple clients or contexts and
do not want one client's knowledge bleeding into another's repo, scope the
env var per shell instead of exporting it globally:

```bash
# In the shell where you want Company A loaded:
export AI_KNOWLEDGE_DIR="$HOME/knowledge-company-a"

# In a different shell for OSS work:
unset AI_KNOWLEDGE_DIR
```

For one-off bypass without unsetting, use `AI_KNOWLEDGE_DISABLE=1`. For
fine-grained control inside a single knowledge folder, mark situational
categories `surface: on-demand` with narrow triggers — they only load when
the user's prompt explicitly mentions a trigger.

**Knowledge files are a prompt-injection surface.** Knowledge file content
is Read into Claude's context on every invocation — same trust boundary as
any other Read call. Review knowledge files before pointing
`$AI_KNOWLEDGE_DIR` at them. Don't commit secrets, PII, or unreviewed
third-party content into the knowledge folder. A malicious `.md` (synced
from a compromised source, auto-generated, committed by a rushed colleague)
becomes a full prompt-injection surface on every `/company-workflow`
invocation while the env var points at that folder.

File paths containing control characters (newline, CR) are rejected during
enumeration — they'd otherwise forge line structure in the `## Always-On
Knowledge` or `## On-Demand Knowledge Candidates` block Claude sees. Hidden
files and directories (anything starting with `.`) under a category are
skipped, so a stray `.draft/notes.md` won't leak into Claude's context.

On-demand content has the same trust boundary as always-on: it reaches
Claude's context via the Read tool once a trigger matches. Review triggers
against the prompts you actually expect, not just the ones you hope for —
a trigger like `code` would match nearly every prompt and pull the category
into context on every invocation.

### Bytes + path caps

v1 enforces:
- **500 path cap:** no more than 500 absolute paths emitted under
  `## Always-On Knowledge`.
- **100KB byte cap:** cumulative content of emitted `*.md` files.

Either cap tripped → hard-fail warning, nothing loads (better a loud failure
than silent context blowup). If you hit the cap, consider splitting your
most sprawling category into multiple categories and moving some to
`surface: on-demand` — on-demand categories only load when the user's
prompt matches a trigger, so they don't count against always-on caps.

### Diagnostic: knowledge-doctor

Run `/company-workflow knowledge-doctor` to see the exact state of every
precondition and every category. Sample output:

```
AI_KNOWLEDGE_DIR: /Users/chjiang/knowledge (exists)
repo_root: /Users/chjiang/Documents/projects/claude-skills-templates
disable env var: not set
categories:
  coding      surface=always     files=3    bytes=8.2KB    loads=yes
  runbooks    surface=on-demand  files=5    bytes=12.1KB   loads=on-match (triggers: pricing, "pricing engine")
  staging     surface=on-demand  files=2    bytes=1.4KB    loads=no (empty triggers)
  notes       surface=(missing yml)         loads=no
  broken      surface=(malformed yml)       loads=no (warning)
cap status: 3/500 paths, 8.2KB/100KB bytes
result: loading enabled; 3 paths will be emitted to Claude
```

`loads=on-match` means the category will load IF the user's latest prompt
mentions one of the listed triggers. `loads=no (empty triggers)` means the
category is inert — add triggers to activate it.

### Current Status

F000003 (originally tracked as F000004_knowledge_integration; merged into
F000003_company_workflow on 2026-04-24) ships the full knowledge-integration
feature in three slices:

- **Resolution** (path detection + unset/invalid warnings): shipped in S000004
  (PR #38, v0.11.0).
- **Always-on loading + knowledge-doctor**: shipped in S000005 c1+c2
  (PR #40, v0.12.0). The per-repo opt-in marker that originally shipped here
  was removed in v1.0.0 — cross-context isolation is now the user's
  responsibility (scope `$AI_KNOWLEDGE_DIR` per shell).
- **On-demand trigger matching**: shipped in S000005 c3 (v0.13.0). User's
  latest message is tokenized, triggers are matched case-insensitively
  against the prompt (whole-word for single tokens; phrase at token
  boundaries for quoted multi-word triggers), and matched categories'
  files Read into context before answering.

Matching is intentionally simple: literal triggers, no fuzzy/semantic
match, no embedding similarity. Quality of surfacing is bounded by the
quality of the user's trigger lists. See [F000003 feature tracker](../../work-items/features/F000003_company_workflow/F000003_TRACKER.md)
for history.
