---
name: test-align-contract
description: "Unified test harness for /align-feature-contract: Tier 1 smoke tests + Tier 2 end-to-end execution."
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Skill
  - AskUserQuestion
---

# /test-align-contract — Test Harness for Doc Triplet Enforcement

Orchestrates two tiers of tests for /align-feature-contract and produces a unified report.

## Tier 1: Smoke Tests (deterministic, no AI)

Run structural checks on all doc triplets discovered under docs/:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
echo "Scanning for triplets..."
for dir in "$REPO_ROOT"/docs/*/; do
  name=$(basename "$dir")
  prd="$dir/PRD.md"
  arch="$dir/ARCHITECTURE.md"
  spec="$dir/TEST-SPEC.md"
  [ -f "$prd" ] && [ -f "$arch" ] && [ -f "$spec" ] && echo "TRIPLET: $name" || echo "INCOMPLETE: $name ($([ -f "$prd" ] && echo 'PRD' || echo 'no-PRD') $([ -f "$arch" ] && echo 'ARCH' || echo 'no-ARCH') $([ -f "$spec" ] && echo 'SPEC' || echo 'no-SPEC'))"
done
```

For each complete triplet, run smoke checks:

**S1: Frontmatter exists** — Each doc has YAML frontmatter between `---` delimiters
**S2: Required fields** — PRD has `type: prd`, ARCH has `type: architecture` and `prd:`, SPEC has `type: test-spec` and `prd:` and `architecture:`
**S3: Required sections** — PRD has "Problem Statement", "User Stories", "Acceptance Criteria"; ARCH has "Overview", "Architecture"; SPEC has "Test Matrix", "Test Tiers"
**S4: Cross-references resolve** — ARCH's `prd:` field points to an existing file; SPEC's `prd:` and `architecture:` fields point to existing files
**S5: No placeholder text** — No `{placeholder}` patterns remaining in content

Report:
```
| Family | S1 | S2 | S3 | S4 | S5 | Status |
|--------|----|----|----|----|-----|--------|
| {name} | P/F | P/F | P/F | P/F | P/F | PASS/FAIL |
```

## Tier 2: E2E Tests (requires AI execution)

For each complete triplet, invoke /align-feature-contract and verify it produces expected output:

1. Invoke the skill on the triplet directory
2. Verify it produces:
   - Per-doc template alignment report (Layer 1)
   - Cross-doc traceability summary (Layer 2)
   - Fixability summary
3. Verify no FAIL-severity findings on well-formed triplets
4. Record pass/fail per triplet

## Unified Report

Combine Tier 1 and Tier 2 results:

```
/test-align-contract Results
═══════════════════════════

Tier 1 (Smoke): {N passed} / {M total} families
Tier 2 (E2E):   {N passed} / {M total} families

| Family | Smoke | E2E | Overall |
|--------|-------|-----|---------|
| {name} | PASS/FAIL | PASS/FAIL/SKIP | PASS/FAIL |

Overall: {PASS/FAIL}
```

## Rules

- **Tier 1 is deterministic.** No AI judgment, pure structural checks.
- **Tier 2 depends on /align-feature-contract.** If the skill is broken, Tier 2 fails.
- **Report everything.** Even passing results go in the report.
