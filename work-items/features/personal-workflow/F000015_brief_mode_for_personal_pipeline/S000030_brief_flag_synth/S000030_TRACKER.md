---
name: "--brief flag plumbing + stub synthesis in /personal-pipeline"
type: user-story
id: "S000030"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/lucid-sanderson-bcccff"
blocked_by: "S000029"
---

<!-- Parent feature: F000015. Source design (parent): ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md
     Blocked by S000029 (Phase 0 spike) — cannot edit pipeline.md until both legs verify the stub template + Step 8.5 scan inertness. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/brief_mode_for_personal_pipeline` (or use parent's branch)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's; S000030 is atomic) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `skills/personal-pipeline/SKILL.md` Usage section documents `--brief "<text>" --type {task|defect}` flags; six new rows appended to Error Handling table; version field bumped
- [ ] `skills/personal-pipeline/pipeline.md` has Step 0a (Brief Mode) firing BEFORE existing Step 1 (pre-scaffold idempotency check)
- [ ] Step 0a validates flag combination (mutual exclusivity with positional path; --type required and ∈ {task, defect}; brief text non-empty and ≤2000 chars after whitespace trim)
- [ ] Step 0a synthesizes a stub design doc with brief text wrapped in a fenced verbatim block; writes to `~/.gstack/projects/{slug}/{user}-{branch}-design-{datetime}-brief.md`
- [ ] Step 0a applies collision-suffix rule (`-2`, `-3`, … starting at `-2`; un-suffixed filename is the implicit `-1` slot)
- [ ] After synthesis, Step 0a sets in-memory design-doc-path and continues into existing Step 1 unchanged
- [ ] Pipeline telemetry write at end of pipeline gains an additive `mode` field with values `manual`, `auto`, `brief`, `brief+auto`
- [ ] Sunset-checkpoint parser (line ~204 of pipeline.md) reads `mode` field, defaulting to `manual` if absent (one-line additive change)
- [ ] All four error rows present: missing --type; missing/empty brief text; brief text > 2000 chars; mutual exclusivity with positional path; --type feature; --type user-story (v1.1 deferred)
- [ ] `--brief` is byte-identical to current behavior when absent (manual + --auto paths unchanged)

## Todos

<!-- Actionable items for this story. -->

- [ ] Wait for S000029 verdict (extend / harden / escalate). Do NOT edit pipeline.md before S000029 ships.
- [ ] If S000029 verdict = "extend": apply the parser-field extension to the stub template before pipeline.md changes
- [ ] Add Step 0a to pipeline.md (flag parsing + validation + synthesis + filename collision)
- [ ] Add `mode` field to telemetry write at end of pipeline
- [ ] Update sunset-checkpoint parser to default to `manual` if `mode` absent
- [ ] Append six rows to SKILL.md Error Handling table (per parent DESIGN spec)
- [ ] Bump SKILL.md version field
- [ ] Update SKILL.md Usage section with brief-mode invocation examples

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. Scaffolded under F000015 via /scaffold-work-item.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/personal-pipeline/SKILL.md`
- `skills/personal-pipeline/pipeline.md`

## Insights

<!-- Non-obvious findings worth remembering. -->

- Synthesized stubs by construction have no SCAFFOLDED footer and no tracker references → Step 1 always lands in clean-slate branch (4th of the 4 idempotency branches). Step 1 logic itself does NOT change.
- `--auto` final gate (Step 8.5) fires for empty-state tasks the same way (short-circuits silently when no Taste / User-Challenge decisions). No new code path needed for brief mode at Step 8.5 — but the stub's placeholders MUST not match Step 8.5 patterns (covered by S000029 spike).
- Sensitive-surface AUQ pre-collection scans synthesized SPEC; the synthesized stub has no Tradeoffs / taste-fork rows by construction → pre-collection is a no-op for brief-mode tasks (assuming Step 8.5 surface scanning targets only Tradeoffs/sensitive-surface paths in SPEC; S000029 verifies).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-09: This story is BLOCKED on S000029 — pipeline.md edits cannot land until parser surface and Step 8.5 scan surface are verified. Summary: respect the BLOCKING marker; do not start implementation prematurely.
- [decision] 2026-05-09: Six error-handling rows are mandatory (per parent DESIGN section "Error Handling table additions"); each has a prescribed exact-match message. Summary: copy the messages verbatim from F000015_DESIGN.md to keep behavioral examples in sync with shipped code.
