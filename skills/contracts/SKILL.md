---
name: contracts
description: "Doc triplet contract enforcement: template alignment, cross-doc traceability, and test harness for PRD + ARCHITECTURE + TEST-SPEC sets."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

## Preamble

Log skill usage so `/system-health` can track which skills are actually used:

```bash
mkdir -p ~/.gstack/analytics
echo '{"skill":"contracts","ts":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","repo":"'"$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo unknown)"'"}' >> ~/.gstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

# /contracts — Doc Triplet Contract Enforcement

Enforces doc triplet contracts (PRD + ARCHITECTURE + TEST-SPEC) and provides a test
harness. Two subcommands: check (default) and test.

## Subcommand Routing

- `/contracts` or `/contracts check [path]` — run contract checks (default)
- `/contracts test` — run the test harness

## Template Resolution

Resolve templates in this order (first match wins):
1. `$REPO_ROOT/templates/` — repo root templates (doc-*.md, contract-*.md)
2. `~/.claude/spec/templates/` — user spec system
3. `~/.claude/templates/` — legacy fallback

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
for dir in "$REPO_ROOT/templates" "$HOME/.claude/spec/templates" "$HOME/.claude/templates"; do
  [ -d "$dir" ] && echo "TEMPLATES: $dir" && break
done
```

Verify doc templates exist: doc-PRD.md, doc-ARCHITECTURE.md, doc-TEST-SPEC.md.
Check current names first, then legacy: PRD-TEMPLATE.md, ARCHITECTURE-TEMPLATE.md, TEST-SPEC-TEMPLATE.md.

## Triplet Discovery

Accept a directory path as argument. If none given, scan for triplets:

**Single mode:** Directory contains PRD.md + ARCHITECTURE.md + TEST-SPEC.md -> audit it.
**Batch mode:** Directory does not contain a triplet -> scan subdirectories for triplets.
**Auto-detect:** No argument -> scan docs/*/ and work-items/*/ for triplets.

## Check Subcommand (default)

### Layer 1: Template Alignment (per doc)

For each of the three documents, compare against its template.

**1a. Frontmatter Check:**
- Extract field names from template YAML frontmatter
- Compare against instance frontmatter
- FAIL: required field missing. PASS: field present. INFO: extra field in instance.
- Special: `parent` is optional for family-level docs (suppress FAIL)

**1b. Section Check:**
- Extract ## and ### headers from template and instance
- FAIL: template section missing in instance
- WARN: instance section not in template
- FAIL: section renamed (fuzzy match, e.g. "Smoke Tests" vs "Test Tiers")
- Sections after `<!-- placeholder -->` in template are optional (INFO if missing)

**1c. Table Structure Check:**
- Extract table header rows (column names) from template
- Match tables by section context in instance
- FAIL: template column missing. WARN: extra column in instance.
- TEST-SPEC: verify Test Tiers has Tier 1 and Tier 2 sub-sections with tables

**1d. Generation Guide Compliance (best-effort):**
- If guide-{doc-type}.md exists in spec/reference/, check it. Also check legacy naming.
- WARN-only. Skip silently if no guide exists.

### Layer 2: Cross-Doc Traceability

**2a. PRD to TEST-SPEC Coverage:**
- Extract story numbers from PRD User Stories tables (P0 and P1)
- Extract AC references from TEST-SPEC Test Matrix
- FAIL: P0 story with no test. WARN: P1 story with no test. INFO: orphan test reference.

**2b. PRD to ARCHITECTURE Coverage:**
- Extract components from ARCHITECTURE Components Affected table
- WARN: P0 story with no architectural component

**2c. ARCHITECTURE to TEST-SPEC Coverage:**
- Check each component has at least one test (keyword match)
- WARN: component with no test coverage

**2d. TEST-SPEC Internal Consistency:**
- Tier 1 rows must have Script/Command filled
- Tier 2 rows must have Rubric filled
- All Test Matrix rows must have Priority and Type
- Sequential test numbers (gaps are WARN)

### Layer 3: Code/Contract Verification (WARN-only)

All Layer 3 checks are advisory. Only run when supporting files exist.

- Contract alignment: check skill-contracts.json if present
- Script/test existence: verify referenced scripts exist at path
- WARN only. Never FAIL on Layer 3.

### Output Format

```
=== /contracts check: {target path} ===
Templates: {template directory}

LAYER 1: Template Alignment
  PRD.md:       [PASS/FAIL] {details}
  ARCHITECTURE: [PASS/FAIL] {details}
  TEST-SPEC:    [PASS/FAIL] {details}

LAYER 2: Cross-Doc Traceability
  [PASS/FAIL] {N}/{M} stories covered, {details}

LAYER 3: Code/Contract (advisory)
  [PASS/WARN] {details} — or "Skipped (no contracts found)"

SUMMARY: {N} passed, {M} failed, {K} warnings
```

### Fix Mode (Layer 1 only)

After reporting, offer to fix FAIL findings:
- Y: fix all Layer 1 failures
- n: report only
- select: individual accept/reject per fix

Fix actions: add missing sections/fields/columns from template, rename mismatched
sections, restructure TEST-SPEC tiers. Preserves existing content. Requires user approval.

Layer 2 and Layer 3 are report-only (not auto-fixable).

## Test Subcommand

### Tier 1: Smoke Tests (deterministic, no AI)

Scan for triplets and run structural checks:

**S1: Frontmatter exists** — each doc has YAML between `---` delimiters
**S2: Required fields** — PRD has `type: prd`, ARCH has `type: architecture` + `prd:`, SPEC has `type: test-spec` + `prd:` + `architecture:`
**S3: Required sections** — PRD: Problem Statement, User Stories, Acceptance Criteria. ARCH: Overview, Architecture. SPEC: Test Matrix, Test Tiers.
**S4: Cross-references resolve** — ARCH prd: and SPEC prd:/architecture: point to existing files
**S5: No placeholder text** — no `{placeholder}` patterns in content

Report as table:
```
| Family | S1 | S2 | S3 | S4 | S5 | Status |
```

### Tier 2: E2E Tests (invokes check)

For each complete triplet:
1. Invoke the check subcommand
2. Verify output has Layer 1 + Layer 2 + fixability summary
3. Verify no FAIL on well-formed triplets
4. Record pass/fail per triplet

### Unified Report

```
/contracts test Results
=======================
Tier 1 (Smoke): {N}/{M} passed
Tier 2 (E2E):   {N}/{M} passed

| Family | Smoke | E2E | Overall |
Overall: {PASS/FAIL}
```

## Rules

1. **Templates are source of truth.** Instances conform to templates, not the reverse.
2. **Report first, fix on request.** Never auto-fix without showing the report.
3. **Layer 3 is WARN-only.** Never FAIL on code/contract checks.
4. **Preserve existing content.** Fixes add structure around content, never delete.
5. **Tier 1 is deterministic.** No AI judgment, pure structural checks.
6. **Read-only by default.** This skill does not have Write/Edit in allowed-tools. Fix mode operates through user confirmation.
7. **Graceful degradation.** Missing contracts -> skip Layer 3. Missing templates -> abort with message.
