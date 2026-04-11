# /docs check — Staleness Detection + Coherence

Detect stale doc sections via the claims sidecar, and run mechanical coherence checks.

## Step 1: Locate Claims Sidecar

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
CLAIMS="$REPO_ROOT/.docs/claims.json"
[ -f "$CLAIMS" ] && echo "FOUND: $CLAIMS" || echo "MISSING"
```

**If MISSING:** Tell the user:
"No .docs/claims.json found. Run `/docs init` first to generate documentation and the claims sidecar."
Stop.

## Step 2: Validate Claims Schema

Read `.docs/claims.json` and validate its structure.

Required top-level fields:
- `version` (number)
- `generated_at` (string, ISO 8601)
- `generated_commit` (string, hex SHA, 7-40 chars)
- `docs` (object, at least one key)

Each doc entry must have `sections` (object). Each section must have:
- `evidence` (array of strings, each a relative file path)
- `commit` (string, hex SHA)

**If validation fails:** Tell the user:
"Error: .docs/claims.json is not valid JSON or has an invalid schema.
Cause: merge conflict, manual edit, or corruption.
Fix: run `/docs init` to regenerate the claims sidecar."
Stop.

## Step 3: Staleness Detection

For each doc in claims.json, for each section:

1. Verify the stored commit exists:
```bash
git cat-file -t STORED_SHA 2>/dev/null && echo "REACHABLE" || echo "UNREACHABLE"
```

2. If UNREACHABLE: flag section as:
```
  UNVERIFIABLE: "Section title" — stored commit not in history (rebase or force-push?)
  Fix: run /docs init to rebuild the baseline.
```
Skip to next section.

3. If REACHABLE: check each evidence file for changes:
```bash
git diff STORED_SHA..HEAD -- "evidence/file/path" 2>/dev/null
```

4. If any evidence file has changes: flag section as STALE.
5. If an evidence file no longer exists: flag as STALE + warn "evidence file deleted."
6. If no changes to any evidence file: section is FRESH.

## Step 4: Mechanical Coherence Checks

Scan all markdown files in the repo root for:

**4a. Broken internal links:**
Find all markdown links `[text](path)` where path is a relative file path.
Check if the target file exists. Flag missing targets.

**4b. Conflicting version numbers:**
If multiple docs reference a version number (e.g., in frontmatter `version:` fields),
check they agree. Flag conflicts.

**4c. References to deleted files/functions:**
If docs reference specific file paths (e.g., `skills/docs/SKILL.md`) or function
names, check they still exist via Glob/Grep. Flag references to missing targets.

## Step 5: Output Report

Format the report as a structured staleness check:

```
=== /docs check ===
Claims: .docs/claims.json (generated TIMESTAMP, commit SHA)

STALENESS CHECK:
  PHILOSOPHY.md:
    [FRESH]  Why this repo exists — no evidence changes
    [STALE]  Design principles — CLAUDE.md changed (3 lines added)
    [STALE]  Key patterns — skills/workflow/SKILL.md modified
    [FRESH]  How to extend — no evidence changes

  OVERVIEW.md:
    [FRESH]  What this project is — no evidence changes
    [UNVERIFIABLE] Architecture — stored commit abc1234 not in history

COHERENCE CHECK:
  [PASS] Internal links — 12 checked, 0 broken
  [WARN] Version conflict — SKILL.md says 0.1.0, catalog says 0.2.0
  [WARN] Dead reference — PHILOSOPHY.md references scripts/migrate.sh (deleted)

SUMMARY: 2 stale sections, 1 unverifiable, 2 coherence warnings
```

## Error Messages

- **Not a git repo:** "Error: /docs requires a git repository."
- **No claims.json:** "No .docs/claims.json found. Run /docs init first."
- **Malformed claims.json:** "Error: .docs/claims.json is not valid JSON or has an invalid schema. Cause: merge conflict, manual edit, or corruption. Fix: run /docs init to regenerate."
- **Unreachable commit:** "{section}: stored commit {sha} not in history. Likely cause: rebase or force-push. Fix: run /docs init to rebuild baseline."
