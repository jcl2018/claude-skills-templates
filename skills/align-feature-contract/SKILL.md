---
name: align-feature-contract
description: "Doc triplet contract enforcement — template alignment, cross-doc traceability, and optional code verification for PRD + ARCHITECTURE + TEST-SPEC sets."
version: 0.1.0
---

# /align-feature-contract — Doc Triplet Contract Enforcement

When `/align-feature-contract` is invoked, compare a PRD + ARCHITECTURE + TEST-SPEC
triplet against their templates, check cross-doc traceability, and report all findings.
Optionally offer to fix Layer 1 (template alignment) issues with user approval.

## Design Principle

**Templates are source of truth.** Instances conform to templates, not the reverse.
Check all three docs together, not individually — cross-doc consistency matters
as much as per-doc structure.

**Complementary to `/audit`:**
- `/audit` checks **system health** (deploy integrity, skill inventory, governance)
- `/align-feature-contract` checks **doc-to-template** and **doc-to-doc** alignment

## When to Use

- After creating or scaffolding a doc triplet to verify template compliance
- Before shipping to catch doc drift from templates
- After editing docs manually to verify nothing was broken
- When reviewing someone else's docs
- `/align-feature-contract docs/work-pipeline/`
- `/align-feature-contract ~/.ai-work/work-items/features/F-1234/`
- `/align-feature-contract path/to/any/triplet/ --templates path/to/templates/`

## Preconditions

1. Identify the template directory. Resolution order:
   a. `--templates <path>` argument (explicit override)
   b. `~/.claude/spec/templates/` (current spec system)
   c. Skill directory (`~/.claude/skills/align-feature-contract/`) — templates
      live alongside this SKILL.md. This is the default for deployed installs.
   d. `~/.claude/templates/` (legacy location)
   e. `work-items/templates/` in the nearest git repo root
   f. `~/.ai-work/work-items/templates/` (legacy deployed location)
   If none found, abort: "No template directory found. Specify with --templates."
2. Verify the three doc templates exist. Check for current names first, then legacy:
   - Current: `doc-PRD.md`, `doc-ARCHITECTURE.md`, `doc-TEST-SPEC.md`
   - Legacy: `PRD-TEMPLATE.md`, `ARCHITECTURE-TEMPLATE.md`, `TEST-SPEC-TEMPLATE.md`
   Abort if neither set is found.

## Target Detection

Accept a directory path as argument.

**Single triplet mode:** If the directory contains `PRD.md` + `ARCHITECTURE.md` +
`TEST-SPEC.md`, audit that triplet directly. If any of the three is missing, check
if the directory contains subdirectories with triplets (batch mode).

**Batch mode:** If the target directory does NOT contain a triplet, scan its immediate
subdirectories for complete triplets. Audit each one and produce a combined report.
Example: `/align-feature-contract docs/discord/` discovers and audits all 5 feature
triplets under `docs/discord/accounts/`, `docs/discord/portfolio/`, etc.

If no triplets found at all, abort: "No doc triplets found in {path} or its subdirectories."

Additional rules:
1. The `parent` frontmatter field is optional for family-level docs (suppress FAIL).
2. Generation guides loaded if present. Check current names first, then legacy:
   - Current: `guide-prd.md`, `guide-architecture.md`, `guide-test-spec.md` (in `~/.claude/spec/reference/`)
   - Legacy: `prd-GENERATION-GUIDE.md`, `architecture-GENERATION-GUIDE.md`, `test-spec-GENERATION-GUIDE.md`

If no argument provided, check if the current directory contains the triplet.
If not, list directories that do (scan `docs/*/` and `~/.ai-work/work-items/features/*/`)
and ask user to pick.

---

## Layer 1: Template Alignment (per doc)

For each of the three documents, compare against its template.

### 1a. Frontmatter Check

1. Read the template's YAML frontmatter between `---` delimiters
2. Extract all field names from the template
3. Read the instance's frontmatter
4. Report:
   - **FAIL**: required field in template but missing in instance
   - **PASS**: field present in both
   - **INFO**: field in instance but not in template (may be intentional)
5. Special handling: `parent` is optional for family-level docs (suppress FAIL)

### 1b. Section Check

1. Extract all `##` and `###` section headers from the template
2. Extract all `##` and `###` section headers from the instance
3. Compare:
   - **FAIL**: section in template but missing in instance
   - **WARN**: section in instance but not in template (may be custom addition)
   - **FAIL**: section renamed (fuzzy match — e.g., "Smoke Tests" vs "Test Tiers")
4. Special handling: sections after `<!-- placeholder -->` comments in template
   are optional — report as INFO if missing, not FAIL

### 1c. Table Structure Check

1. For each markdown table in the template, extract the header row (column names)
2. Find the matching table in the instance (by section context)
3. Compare column headers:
   - **FAIL**: column in template but missing in instance
   - **WARN**: column in instance but not in template
4. For TEST-SPEC: check `## Test Tiers` has both `### Tier 1` and `### Tier 2`
   sub-sections, each with their own table

### 1d. Generation Guide Compliance (best-effort)

1. If a generation guide exists for this doc type, read it. Check current naming first:
   `guide-{doc-type}.md` (in spec/reference/), then legacy: `{doc-type}-GENERATION-GUIDE.md`
2. Check sections the guide marks as "leave blank" or "seed" are handled appropriately
3. This check is **WARN-only** — guides aren't structured data, parsing is fragile
4. Skip silently if no guide exists for the doc type

---

## Layer 2: Cross-Doc Traceability

### 2a. PRD to TEST-SPEC Coverage

1. Extract all story numbers from PRD (from `## User Stories` tables, both P0 and P1)
2. Extract all AC references from TEST-SPEC `## Test Matrix` AC column
3. Report:
   - **FAIL**: P0 story with no test coverage
   - **WARN**: P1 story with no test coverage
   - **INFO**: test referencing a story not in PRD (may be stale)

### 2b. PRD to ARCHITECTURE Coverage

1. Extract components from ARCHITECTURE `### Components Affected` table
2. For each P0 story, check it touches at least one component (by keyword match
   in the Description column or by explicit story reference)
3. Report:
   - **WARN**: P0 story with no architectural component (suspicious but not always wrong)

### 2c. ARCHITECTURE to TEST-SPEC Coverage

1. Extract component names from ARCHITECTURE `### Components Affected` table
2. Check each component has at least one test in TEST-SPEC (by keyword match
   in Test Case or Expected Result columns)
3. Report:
   - **WARN**: component with no test coverage

### 2d. TEST-SPEC Internal Consistency

1. If `## Test Tiers` exists with Tier 1 and Tier 2 sub-tables:
   - Tier 1 rows must have `Script/Command` column filled (not empty or placeholder)
   - Tier 2 rows must have `Rubric` column filled
2. Every test in `## Test Matrix` must have Priority and Type columns filled
3. Test numbers should be sequential within the doc (gaps are WARN, not FAIL)

---

## Layer 3: Code/Contract Verification (WARN-only, optional)

All Layer 3 checks are advisory and only run when the supporting files exist.
They surface drift for human review but do not block or auto-fix.

### 3a. Contract Alignment

Only runs if `skill-contracts.json` exists in the repo root.

1. For each skill referenced in the PRD, check it has a contract
2. For each contracted skill, check `must_produce` keywords appear in PRD
   success criteria (substring match, not semantic)
3. Check `must_not_do` items don't appear in PRD scope section
4. Report as **WARN**: skills without contracts, keyword mismatches

### 3b. Script/Test Existence

1. For each TEST-SPEC Tier 1 test that names a script in the `Script/Command`
   column, check the script exists at the referenced path
2. For each validator referenced in the docs, check it exists
3. Report as **WARN**: phantom script references

---

## Output Format

```
=== /align-feature-contract: {target path} ===
Templates: {template directory}

LAYER 1: Template Alignment
  PRD.md:
    [PASS] frontmatter: {N}/{M} fields present
    [FAIL] section: missing "## API Changes" (template prescribes, instance omits)
    [WARN] guide: Success Metrics filled (guide says leave blank)
  ARCHITECTURE.md:
    ...
  TEST-SPEC.md:
    ...

LAYER 2: Cross-Doc Traceability
  [PASS] {N}/{M} PRD stories have TEST-SPEC coverage
  [FAIL] Story #{n} has no ARCHITECTURE component
  [PASS] {N}/{M} ARCHITECTURE components have test coverage
  ...

LAYER 3: Code/Contract Checks (advisory)
  [PASS] {N}/{M} referenced scripts exist
  ...

SUMMARY: {N} checks passed, {M} failed, {K} warnings
```

If Layer 3 was skipped: `LAYER 3: Skipped (no contracts found)`.

Status values: `[PASS]`, `[FAIL]`, `[WARN]`, `[INFO]`

- FAIL = deviation from template contract (Layer 1-2) or missing required element
- WARN = advisory issue worth reviewing (Layer 3, or soft Layer 1-2 findings)
- PASS = check passed
- INFO = informational note (extra content, optional sections)

---

## Fix Mode

After reporting, offer to fix each FAIL finding:

```
{N} fixable issues found. Fix them? [Y/n/select]
```

- **Y**: fix all Layer 1 failures
- **n**: report only, no changes
- **select**: show each fix for individual accept/reject

### Fixability Matrix

| Layer | Auto-fixable? | How |
|-------|--------------|-----|
| Layer 1 (template alignment) | Yes, with approval | Add missing sections/fields/columns from template |
| Layer 2 (cross-doc traceability) | No — report only | Requires human judgment on what to add/remove |
| Layer 3 (code/contract) | No — WARN only | Advisory |

### Fix Actions (Layer 1 only)

- **Missing section**: insert the section header with template placeholder content
  (including HTML comments from template)
- **Missing frontmatter field**: add the field with a `{PLACEHOLDER}` value
- **Wrong section name**: rename to match template (e.g., "Smoke Tests" -> "Test Tiers")
- **Missing table columns**: add column with empty cells to existing rows
- **TEST-SPEC tier structure**: restructure to match template's Tier 1 / Tier 2 layout,
  preserving existing test content and redistributing rows by type:
  - Tests with `Script/Command` or marked `automated` -> Tier 1
  - Tests with `Manual` or behavioral tests -> Tier 2
  - Tests marked both -> duplicate reference in both tiers

### Fix Confirmation

Before writing any fix:
1. Show the specific change (old -> new) for each affected section
2. Wait for user approval
3. Write changes only after confirmation

---

## Important Rules

1. **Report first, fix on request.** Never auto-fix without showing the report.
2. **Templates are source of truth.** If instance and template disagree, the
   template is correct (unless the instance has a deliberate override with a comment).
3. **Layer 3 is WARN-only.** Never FAIL on code/contract checks.
4. **Family docs may omit `parent`.** Suppress the FAIL for missing `parent` field
   in family-level docs.
5. **Preserve existing content.** When fixing, add missing structure around existing
   content — never delete or rewrite user content.
6. **Windows/Git-Bash compatible.** All bash commands must work under Git Bash.
7. **No network access required.** All checks use local files only.
8. **Graceful degradation.** If contracts are missing, skip Layer 3 rather than aborting.
