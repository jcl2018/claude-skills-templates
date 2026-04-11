# /docs init — Generate Narrative Documentation

Generate PHILOSOPHY.md (default) or OVERVIEW.md from codebase analysis.
Produces a claims sidecar (`.docs/claims.json`) mapping each section to evidence files.

## Step 1: Determine Doc Type

Parse the user's input:
- `/docs init` or `/docs init philosophy` -> generate PHILOSOPHY.md
- `/docs init overview` -> generate OVERVIEW.md

## Step 2: Check for Existing Doc

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
DOC_TYPE="${1:-philosophy}"
if [ "$DOC_TYPE" = "philosophy" ]; then
  TARGET="$REPO_ROOT/PHILOSOPHY.md"
elif [ "$DOC_TYPE" = "overview" ]; then
  TARGET="$REPO_ROOT/OVERVIEW.md"
fi
[ -f "$TARGET" ] && echo "EXISTS" || echo "NEW"
```

**If EXISTS (re-run):**
- Do NOT regenerate the doc content (avoids LLM nondeterminism overwriting human edits)
- Read the existing doc, analyze its sections against the current codebase
- Generate/update `.docs/claims.json` only, mapping each section to current evidence
- Tell the user: "Found existing {doc}. Updated .docs/claims.json with current evidence mappings. Run /docs check to see staleness."
- Skip to Step 6 (claims.json generation)

**If NEW (first run):**
- Continue to Step 3

## Step 3: Gather Evidence

Read these sources in order:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
echo "=== Repo structure ==="
find "$REPO_ROOT" -maxdepth 2 -name '*.md' -not -path '*node_modules*' -not -path '*.git*' | head -30

echo "=== Git history ==="
git log --oneline -20

echo "=== CLAUDE.md ==="
[ -f "$REPO_ROOT/CLAUDE.md" ] && echo "FOUND" || echo "MISSING"

echo "=== README.md ==="
[ -f "$REPO_ROOT/README.md" ] && echo "FOUND" || echo "MISSING"
```

Read CLAUDE.md and README.md if they exist.

Read key source files that define the project's character:
- For this repo: `skills-catalog.json`, skill SKILL.md files, key scripts
- For other repos: package.json/Cargo.toml/go.mod, main entry points, config files

Check for design docs from prior /office-hours sessions:

```bash
eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || true
SLUG=${SLUG:-$(basename "$REPO_ROOT")}
ls -t ~/.gstack/projects/$SLUG/*-design-*.md 2>/dev/null | head -3
```

If design docs exist, read the most recent one for additional context on design decisions.

## Step 4: Generate the Doc

### PHILOSOPHY.md Schema

Generate a markdown file with these sections. Each section must be grounded in evidence
from the codebase, not generic advice. Quote specific files, patterns, and decisions.

```markdown
# Philosophy

## Why this repo exists
[What problem it solves. What motivated building it. Who it's for.]

## Design principles and tradeoffs
[The 3-5 principles that shaped key decisions. For each: the principle, an example 
of where it applies in the code, and what was traded away.]

## What this intentionally does NOT optimize for
[Explicit non-goals. What the project is NOT trying to be. Why.]

## Key patterns and conventions
[The patterns that repeat across the codebase. Naming conventions, directory structure,
data flow patterns. For each: what the pattern is, where it appears, and the rationale.]

## How to extend without breaking its character
[Guidelines for adding new code that fits the existing style. What to preserve. 
What anti-patterns to avoid.]

## Dependencies and assumptions
[What the project depends on (runtime, tools, conventions). What assumptions about 
the environment are baked in.]

## Failure modes and maintenance risks
[What breaks first. What requires manual intervention. What will go stale.]
```

### OVERVIEW.md Schema

```markdown
# Overview

## What this project is
[One paragraph. What it does, who uses it, why it matters.]

## Architecture at a glance
[ASCII diagram or description of the major components and how they relate.]

## Key components and how they relate
[For each major component: what it does, what it depends on, what depends on it.]

## Getting started (for contributors)
[Not install steps (that's README). This is: how to understand the codebase well 
enough to make changes. Where to start reading. What to ignore.]

## Current state and known limitations
[What works well. What's fragile. What's missing. Honest assessment.]
```

## Step 5: Confirm Before Writing

Present the generated outline to the user via AskUserQuestion:

> Generated {PHILOSOPHY.md / OVERVIEW.md} with {N} sections based on {M} evidence files.
>
> Sections: {list section titles}
>
> Write this to {target path}?

Options:
- A) Write it
- B) Show me the full content first
- C) Cancel

If B: show the full generated content, then re-ask A/C.
If C: stop.
If A: write the file and continue to Step 6.

## Step 6: Generate Claims Sidecar

Create `.docs/claims.json` mapping each section to its evidence files.

```bash
mkdir -p "$REPO_ROOT/.docs"
```

For each section in the generated doc, identify 2-5 files that serve as evidence
for that section's claims. Use the files you actually read during evidence gathering.

Write `.docs/claims.json`:

```json
{
  "version": 1,
  "generated_at": "ISO-8601-TIMESTAMP",
  "generated_commit": "SHORT-SHA",
  "docs": {
    "PHILOSOPHY.md": {
      "sections": {
        "Why this repo exists": {
          "evidence": ["CLAUDE.md", "README.md"],
          "commit": "SHORT-SHA"
        }
      }
    }
  }
}
```

Rules for evidence mapping:
- Use file paths relative to repo root
- Use specific files, not directories (avoid `templates/` — use `templates/doc-PRD.md`)
- Each section should have 2-5 evidence files
- The `commit` field is `git rev-parse --short HEAD` at generation time
- `generated_commit` at the top level matches the per-section commits on first generation

## Step 7: Post-Init Explanation

After writing both files, tell the user:

> Created:
> - `{PHILOSOPHY.md / OVERVIEW.md}` — narrative documentation
> - `.docs/claims.json` — evidence mappings for staleness detection
>
> The `.docs/` directory should be committed to git. It enables `/docs check` to
> detect when code changes make doc sections stale.
>
> Next: make some code changes, then run `/docs check` to see staleness detection in action.

## Error Messages

- **Not a git repo:** "Error: /docs requires a git repository."
- **Write failure:** "Error: Could not write to {path}. Check permissions."
- **No CLAUDE.md or README.md:** Continue without them. Note: "No CLAUDE.md found. Generated doc may lack project-specific context."
