# Architecture Generation Guide

How Claude (or a human) pre-populates ARCHITECTURE.md from the template.

## When to generate

After the PRD is populated. The architecture reads from the PRD to extract requirements
and translate them into technical design. Generation order: PRD first, ARCHITECTURE second.

## Sources (in priority order)

1. **PRD** — the primary input. Read `PRD.md` in the same work item directory.
   Extract: user stories -> components, acceptance criteria -> API surface
2. **Codebase analysis** — grep/glob the affected repos to identify existing
   components, patterns, and interfaces that the design must fit into
3. **Git history** — check prior art: similar features, related PRs, existing
   patterns in the same modules
4. **Work item journal** — if investigation findings exist, incorporate them
   into the Architecture section

## Steps

### 1. Fill frontmatter

- `parent`: from the work item's `id` field
- `title`: from the work item's `name` field + " — Architecture"
- `prd`: "PRD.md" (relative path in the same directory)
- `date`: today
- `author`: current user

### 2. Overview

One paragraph summarizing the technical approach. Reference the PRD's problem
statement and chosen solution direction.

### 3. Architecture

- Identify affected components by scanning the PRD's scope and the codebase
- Draw an ASCII diagram showing component interactions for the primary data flow
- List components affected with repo paths and change types

### 4. API Changes

- Extract from PRD's user stories: what new capabilities are needed?
- Map capabilities to function signatures in existing code patterns
- Note any breaking changes to existing APIs

### 5. Dependencies

This is the single place for all dependency tracking (PRD no longer has a
Dependencies section). Include:
- Libraries and frameworks required
- Other features or modules this depends on
- Build or infrastructure requirements
- PRD assumptions that translate into technical dependencies

### 6. Design Decisions

Document choices made during architecture design:
- What approach was chosen and why
- What alternatives were considered and why they were rejected
- This is the most valuable section for future readers — it prevents
  re-litigating decisions that were already thought through

### 7. Sections to leave blank for human input

- **Risk Assessment** — likelihood/impact scoring requires domain judgment
- **Design Decisions** — seed with any choices made during generation,
  but expect the human to add more during implementation

## Offline requirement

All generation must work without network access. Codebase analysis uses
local git repos. No external API calls required.
