# PRD Generation Guide

How to pre-populate a new PRD from the template.

## When to generate

When a new feature work item is created via `the work-track create command --type feature`.
The PRD is the first artifact generated (architecture and test-spec depend on it).

## Sources (in priority order)

1. **User-provided problem statement** — from the create command's natural language input
2. **Existing use case docs** — if migrating from UC-* format, read the UC doc and
   extract: Overview → Problem Statement, Actors → User Stories, Main Flow → Acceptance
   Criteria, Preconditions → Assumptions
3. **Meeting notes** — if the user references a meeting or discussion, extract
   requirements from meeting notes or scrum docs
4. **Ticket URL** — if a TFS/Jira URL is provided AND the network allows it, extract
   the ticket title and description. Do not depend on network access.

## Steps

### 1. Fill frontmatter

- `parent`: from the work item's `id` field
- `title`: from the work item's `name` field + " — Product Requirements"
- `date`: today
- `author`: current user

### 2. Problem Statement

Synthesize from the user's input. Be specific about:
- Who has the problem (role, not category)
- What the current workaround is
- Why the workaround is painful

If migrating from a UC doc, pull from the Overview section.

### 3. User Stories

Extract from the user's description and any referenced docs.
- Assign priority (P0/P1/P2) based on user's emphasis and dependencies
- Each story should be independently testable

If migrating from a UC doc, convert Main Flow steps into user stories.

### 4. Tag each story

Assign one domain keyword per story so reviewers can quickly classify it.

Standard vocabulary (use these first, invent only when none fits):
- **core** — primary feature capability, the main "what it does"
- **resilience** — error handling, recovery, degraded operation, crash safety
- **observability** — reporting, metrics, trending, snapshots
- **usability** — UX improvements, workflow shortcuts, noise reduction
- **security** — access control, secrets, trust boundaries
- **integration** — cross-system interactions, external dependencies

Use the same tag in the matching AC heading: `### Story #N: Title [tag]`.

### 5. Acceptance Criteria

Generate Given/When/Then blocks for each P0 user story.
- Cover the happy path AND at least one error/edge case per story
- Leave P1/P2 criteria as placeholders for human input

### 6. Assumptions

Capture what the PRD takes for granted:
- Environment assumptions (OS, tools available, network access)
- User assumptions (skill level, workflow patterns)
- System assumptions (existing infrastructure, data availability)

If an assumption turns out to be wrong, the PRD needs to be revisited.

### 7. Sections to leave blank for human input

- **Success Metrics** — requires domain knowledge about what "good" looks like
- **P1/P2 acceptance criteria** — lower priority, human decides detail level

### 8. Validation

After generation, verify:
- [ ] Every P0 story has at least one acceptance criterion
- [ ] Problem statement names a specific user role
- [ ] Out of Scope section has at least one item (prevents blank sections)
- [ ] Assumptions section has at least one item
- [ ] No placeholder text like `{role}` remains in filled sections

## Offline requirement

All generation must work without network access. If a ticket URL is provided,
attempt to fetch it but do not fail if the network is unavailable. Note
"Ticket details not fetched (network unavailable)" and proceed.
