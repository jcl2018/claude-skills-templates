---
name: "/wc-scaffold — design-doc → work-item directory tree"
type: user-story
id: "S000032"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: "S000031"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/wc_scaffold` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] /office-hours design referenced
- [x] Working branch created
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go
4. Run `/CJ_personal-workflow check` on modified docs
5. Update tracker; add journal entries
6. Update Files section

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work
- [ ] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check`
2. Verify smoke tests in CI
3. Walk E2E manually
4. Ensure all child tasks shipped
5. Run `/ship`
6. Run `/land-and-deploy`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `work-copilot/prompts/scaffold.prompt.md` exists with `tools: [codebase, search, searchResults, editFiles]`.
- [ ] Idempotency check from design-doc YAML frontmatter (read `status:`, `scaffolded_to:`, `receipts.investigate`); NO-OP if already scaffolded.
- [ ] Reads manifest + templates from `.github/work-copilot/`.
- [ ] Picks next ID per type via grep over existing IDs under `work-items/`.
- [ ] Writes directory tree with all required artifacts populated from the design doc.
- [ ] Calls `/validate <new-dir>` at end — fails loud if scaffolding broke a template.
- [ ] Copies `receipts.investigate` from design-doc frontmatter into new tracker's frontmatter (preserves lineage).
- [ ] Writes `receipts.scaffold` block to new tracker's frontmatter with `pending_commit: true`.
- [ ] Updates design-doc's frontmatter `status: SCAFFOLDED` and adds `scaffolded_to: <work-item-dir>`.
- [ ] Design-doc-required invariant enforced: refuse to scaffold without a design-doc input.
- [ ] Manual smoke pass: invoke `/wc-scaffold` on a hand-authored design-doc fixture; verify directory tree + receipt + design-doc updates.

## Todos

- [ ] Author `work-copilot/prompts/scaffold.prompt.md` with frontmatter + 8 main steps.
- [ ] Design-doc frontmatter parse logic (read whole, parse YAML, idempotency check).
- [ ] ID-picking logic (grep existing IDs).
- [ ] Per-type template fill-in logic (5 types).
- [ ] Idempotency NO-OP path (already SCAFFOLDED).
- [ ] Design-doc-required invariant (refuse hand-prompt scaffold).
- [ ] `receipts.scaffold` writes with `pending_commit: true`.
- [ ] Design-doc update: `status: SCAFFOLDED` + `scaffolded_to:`.
- [ ] Smoke + fixture exercise.

## Log

- 2026-05-11: Created. Build #3 of Approach C. Blocked by S000031 (consumes /wc-implement's receipts and design-doc lineage).

## PRs

## Files

- `work-copilot/prompts/scaffold.prompt.md` (new)

## Insights

- The design-doc-required invariant is the keystone of `/wc-pipeline`'s drift math chain: every tracker must root back to a `receipts.investigate` block. Hand-authored stubs are allowed for users who want to skip /wc-investigate, but they MUST hand-author the receipt block. The invariant protects the orchestrator from drift roots it can't reason about.

## Journal

- [decision] 2026-05-11: Idempotency check uses design-doc YAML frontmatter (not a footer line, as on the Claude-side `/CJ_scaffold-work-item`). Reason: design-doc frontmatter is the only structured surface available on the Copilot side; a footer line is brittle to manual edits.
