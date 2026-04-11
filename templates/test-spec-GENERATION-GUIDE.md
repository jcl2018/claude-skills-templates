# Test Specification Generation Guide

How Claude (or a human) pre-populates TEST-SPEC.md from the template.

## When to generate

After both PRD and ARCHITECTURE are populated. The test spec reads from both
to build comprehensive test coverage. Generation order: PRD first, ARCHITECTURE
second, TEST-SPEC third.

## Sources (in priority order)

1. **PRD** — acceptance criteria (Given/When/Then) are the primary input for test cases
2. **ARCHITECTURE** — components and data flow reveal integration test needs
   and edge cases from the design

## Steps

### 1. Fill frontmatter

- `parent`: from the work item's `id` field
- `title`: from the work item's `name` field + " — Test Specification"
- `prd`: "PRD.md"
- `architecture`: "ARCHITECTURE.md"
- `date`: today
- `author`: current user

### 2. Test Matrix (the core section)

Generate from PRD acceptance criteria:
- Each P0 acceptance criterion -> at least one test case row
- The **AC column** traces each test case back to a PRD acceptance criterion
  (e.g., `AC-1`, `AC-2`). This IS the traceability — no separate RTM needed.
- Add edge cases identified during architecture analysis:
  - Null/empty inputs
  - Boundary conditions (0 items, max items, single item)
  - Error paths (invalid input, network failure, concurrent access)
  - Performance cases (large data sets)
- Assign test types: Unit for isolated logic, Integration for cross-component,
  E2E for user-visible workflows

### 3. Test Tiers

Every feature gets two test tiers. Generate both.

**Tier 1 — Smoke Tests** (automated, no skill execution):
- For each artifact the feature produces: check file exists, frontmatter is valid,
  required sections are present
- For JSON artifacts: check valid JSON, required fields non-empty, schema passes
  existing validators (e.g., `validate-work-spec.sh`)
- Script column: reference an existing test script or write `# TODO: add to {script}`
- These run without Claude. They catch structural regressions.

**Tier 2 — E2E Tests** (manual, real user workflow):
- For each P0 acceptance criterion: write the steps a real user would take
  (e.g., "run `/work-track create --type feature`", "check ~/.ai-work/work-items/")
- Expected Outcome: what the user actually sees, not internal state
- Rubric: concrete pass/fail (e.g., "PRD.md has Problem Statement section with
  non-placeholder content" not "PRD looks correct")
- These require Claude skill execution. They catch behavioral regressions.

**Rule of thumb:** if you can check it with `grep` or `jq`, it's Tier 1.
If it requires Claude to produce the output, it's Tier 2.

### 4. Coverage Gaps

Explicitly list what is NOT tested:
- Scenarios deemed too expensive to test vs. their risk
- Environmental constraints (e.g., "can't test on Linux, only Windows available")
- Deliberate omissions with accepted risk documented

This section is more honest and useful than pretending full coverage.

### 5. Cross-validate against PRD

After generation, verify coverage:
- [ ] Every P0 acceptance criterion has at least one test case in the matrix
- [ ] Every component in ARCHITECTURE.md has at least one test
- [ ] No PRD requirement is silently dropped

Report any uncovered criteria as a Coverage Gap entry.

## Offline requirement

All generation must work without network access. Codebase analysis uses
local git repos. No external API calls required.
