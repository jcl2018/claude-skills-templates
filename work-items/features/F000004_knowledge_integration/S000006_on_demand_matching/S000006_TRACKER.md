---
name: "on-demand-matching"
type: user-story
id: "S000006"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "F000004"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "S000004"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) — from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) — from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) — from `templates/doc-TEST-SPEC.md`
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [ ] All child tasks have entered Phase 2+
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/personal-workflow tree` — verify hierarchy and structural completeness
3. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
4. Ensure all child tasks have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] `/personal-workflow tree` — structure verified
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] For each category with `.knowledge.yml { surface: on-demand }`, the skill makes its declared `triggers` list available to Claude along with the category root path
- [ ] Claude matches the user's current prompt against every on-demand category's triggers (case-insensitive whole-word match on prompt tokens; quoted multi-word trigger phrases matched as a unit)
- [ ] When one or more categories match, Claude reads every `*.md` file under each matched category (recursive, same enumeration rules as S000005)
- [ ] When multiple categories match, content from all matched categories is loaded
- [ ] Categories with empty `triggers: []` never match; they are effectively dark until the user adds triggers
- [ ] A `surface: always` category is never considered by this matching logic (it's already loaded by S000005)
- [ ] When `$_KNOWLEDGE_DIR` is empty: no matching, no loading, no additional warning
- [ ] Existing `validate` command produces byte-identical output with and without on-demand categories present (zero regression)

## Todos

<!-- Actionable items for this story. -->

- [ ] Decide who tokenizes the prompt: the skill emits a "matching spec" and Claude does the match; or the skill emits triggers and Claude handles both tokenization and match. (Leaning: Claude does both — it already has the prompt in context and bash can't see it.)
- [ ] Draft the exact instruction text in SKILL.md: "For each on-demand category listed below, check if any declared trigger matches the user's request; if so, Read all listed paths before answering"
- [ ] Decide diagnostic surfacing: should Claude log which triggers matched, to help users tune? (Proposal: yes, one line per matched category.)
- [ ] Disambiguate "prompt tokens" — does that include prior turns in the conversation or only the latest user message? (Proposal: only the latest user message to avoid runaway loading.)
- [ ] Decide behavior when a trigger is a single very-common word like "the" or "code". (Proposal: no skill-side filtering; user's responsibility to pick specific triggers.)
- [ ] Write Tier 1 smoke tests (structure: instruction text present, on-demand categories emitted)
- [ ] Write Tier 2 E2E tests (prompt contains trigger → category loaded; no trigger → not loaded; multi-match → both loaded)
- [ ] Extend fixture `valid-knowledge-dir/` with on-demand categories covering single-word and phrase triggers
- [ ] Update WORKFLOW.md with on-demand example and trigger-authoring guidance

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. Third vertical slice of F000004: on-demand trigger matching + loading. Blocked by S000004 (resolution); parallel to S000005 (always-on).
- 2026-04-17: Decomposed into tasks: T000008 (extract shared helper from T000006's block), T000009 (On-Demand Matching block + extend fixtures + WORKFLOW.md docs, blocked by T000008), T000010 (Tier 1 + Tier 2 + regression tests, blocked by T000009).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter with `parent: F000004`; story-level milestones.md dropped — now only at feature level).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
