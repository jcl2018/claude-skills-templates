---
name: "Step 18 traceability comma-split fix"
type: user-story
id: "S000022"
status: active
created: "2026-05-08"
updated: "2026-05-08"
parent: "F000012"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/pipeline-parity"
blocked_by: "S000021"
---

<!-- Source design: parent feature F000012_DESIGN.md.
     This story rides through S000021's new defect path as the integration test
     for the per-type pipeline generalization. Sequenced after S000021. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/pipeline-parity` (shared with sibling S000021; same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from parent feature's design context
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (atomic story — no tasks)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
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
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `skills/personal-workflow/check.md` Step 18 prose explicitly instructs: "split each AC cell on comma, trim whitespace, each token contributes one value to `ac_set`."
- [ ] Worked example added to Step 18 showing `| S2 | core | AC-1, AC-2, AC-3 | ...` → `{AC-1, AC-2, AC-3}` set membership.
- [ ] Existing placeholder filter (`^AC-\{[a-zA-Z_]+\}$`) preserved; comma-split happens BEFORE placeholder filter so a cell like `AC-{n}, AC-1` correctly contributes `AC-1` and drops the placeholder.
- [ ] Running `/personal-workflow check` on F000010 work-items produces no false `[UNTESTED]` findings on multi-AC P0 stories (S000018 P0 #2/#3/#5/#6, S000019 P0 #2/#4).
- [ ] Edge case prose updated: "A row's AC cell is `-` or blank" still contributes nothing (unchanged behavior, but re-confirm with worked example).

## Todos

- [ ] Edit `skills/personal-workflow/check.md` Step 18 (lines 339-371): add explicit comma-split instruction.
- [ ] Add worked example block under Step 18 illustrating the comma-split + placeholder-filter ordering.
- [ ] Verify by running `/personal-workflow check` on F000010 dir post-edit; confirm zero false `[UNTESTED]` findings.
- [ ] Add test fixture: a minimal SPEC + TEST-SPEC pair with multi-AC cells; assert traceability passes.
- [ ] Update CHANGELOG.md entry (handled by `/ship`).

## Log

- 2026-05-08: Created. Closes TODOS.md #5; rides through S000021's new defect path as integration test.

## PRs

## Files

<!-- Affected file paths. -->

- `skills/personal-workflow/check.md` (Step 18 prose tightening + worked example)

## Insights

- This is a prose-spec fix, not a code fix. `check.md` is interpreted by the LLM running `/personal-workflow check`. The fix is "tighten prose so any LLM does the right thing."
- The bug existed silently because no one had hit it yet — F000010's SPEC + TEST-SPEC files have multi-AC cells but the false `[UNTESTED]` findings were caught by humans during review and dismissed as "spurious."
- This story is the smaller of the two in F000012 but provides the integration test for S000021. If S000022 ships through the per-type pipeline cleanly, the new defect path works.

## Journal

- 2026-05-08 [decision] Implementation = prose tightening + worked example in `check.md`. No script/code change. (F000012_DESIGN big decision #6.)
- 2026-05-08 [decision] Sequenced after S000021 to dogfood the new defect path. Could ship as a defect (D000017) standalone but bundling under F000012 keeps PR scope coherent. (F000012_DESIGN big decision #2.)
