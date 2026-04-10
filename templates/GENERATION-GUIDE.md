# Template Generation Guide

Machine-readable instructions for Claude Code. Read by /work-track during scaffolding.

## Cross-Template Conventions

### Frontmatter Format
- YAML between `---` delimiters
- `type`: always lowercase (prd, architecture, test-spec, rca, feature, defect, task, user-story)
- `parent`: ID of the parent work item (tracker ID for triplet docs, feature ID for user stories)
- `feature`: feature-level ID (same as parent for features, parent's parent for user stories)
- `date`: ISO format YYYY-MM-DD
- `status`: Draft | Active | Done
- `author`: system username (from `whoami`)

### Story Numbering
- Sequential within each priority tier (P0 starts at 1, P1 continues from last P0, etc.)
- Stable: never renumber existing stories when adding new ones
- Gap-tolerant: deleted stories leave gaps (story #3 deleted, #4 stays #4)

### Tag Vocabulary
Standard tags for user stories and test cases:
- `core` — fundamental functionality
- `resilience` — error handling, recovery, degradation
- `observability` — logging, metrics, audit trails
- `usability` — UX, developer experience, ergonomics
- `security` — auth, access control, input validation
- `integration` — cross-component, cross-skill interactions

Use the SAME tag in the PRD story table, AC heading, and TEST-SPEC test matrix.

### AC (Acceptance Criteria) Format
Always Given/When/Then:
```
GIVEN {precondition — what state exists before the action}
WHEN  {action — what the user or system does}
THEN  {expected result — observable, testable outcome}
```

Multiple THEN clauses are fine. Each should be independently verifiable.

## Per-Template Instructions

### PRD Generation

**When:** Feature or user-story work item created via /work-track create.

**Fill order:** frontmatter → Problem Statement → Mental Model → User Stories → AC → Metrics

**Problem Statement rules:**
- Name the specific user (role, not category)
- Describe the current workaround (or "nothing" if no workaround exists)
- State why the workaround is painful

**User Story rules:**
- P0 stories must be independently deliverable
- Each story must be answerable with a single yes/no test
- "What it asks" column: plain English, no jargon, no code references

### ARCHITECTURE Generation

**When:** After PRD exists. Architecture references the PRD.

**Fill order:** frontmatter (set `prd: PRD.md`) → Overview → Diagram → Components → Data Flow → Dependencies → Risks → Decisions

**Diagram rules:**
- ASCII art, not images
- Show component boundaries and data flow direction
- Include error/fallback paths if non-obvious

**Components table rules:**
- One row per affected file or directory
- Change Type: New (doesn't exist yet) or Modified (exists, being changed)

**Design Decisions rules:**
- Every non-obvious choice gets a row
- "Rejected Alternative" must be a real option that was considered
- "Why" must reference a concrete tradeoff, not "seemed better"

### TEST-SPEC Generation

**When:** After PRD and ARCHITECTURE exist. Test spec references both.

**Fill order:** frontmatter (set `prd:` and `architecture:`) → Test Matrix → Tier 1 → Tier 2 → Coverage Gaps

**Test Matrix rules:**
- Every P0 AC must have at least one test row
- AC column references the story number (AC-1, AC-2, etc.)
- Type: Unit (isolated), Integration (cross-component), E2E (full workflow)

**Tier 1 (Smoke) rules:**
- Must be runnable without Claude (pure bash/shell)
- Checks: file existence, frontmatter fields, section headers, JSON schema
- Include the exact command to run

**Tier 2 (E2E) rules:**
- Requires Claude execution
- Steps written as "what a real user would do"
- Rubric: specific pass/fail criteria, not "looks correct"

### TRACKER Generation

**When:** Any work item type created via /work-track create.

**Fill order:** frontmatter → Lifecycle (pre-filled per type) → Acceptance Criteria → Log entry

**Type-specific lifecycle adjustments:**
- `feature`: All 4 phases with full sub-gates
- `defect`: Phase 2 sub-gates include "root cause identified", "hypothesis tested", "fix committed"
- `task`: Simplified Phase 4 (no "Linux build" or "regression tests", just "tests pass")
- `user-story`: Same as feature but nested under parent feature

### RCA Generation

**When:** Defect work item created via /work-track create --type defect.

**Fill order:** frontmatter → Symptom → Reproduction Steps → (Investigation Trail filled during /work-implement)

**Symptom rules:**
- Include the exact error message or incorrect behavior observed
- State reproduction frequency
- Do NOT include root cause speculation in the Symptom section
