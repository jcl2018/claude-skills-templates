---
name: "General docs are required — reclassify the contract/agent/backlog docs + views as section: common"
type: feature
id: "F000058"
status: active
created: "2026-06-09"
updated: "2026-06-09"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/pensive-robinson-08ad9c"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/general_docs_required`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] The 6 named docs (`spec/doc-spec.md`, `CLAUDE.md`, `CHANGELOG.md`, `TODOS.md`, `docs/doc-general.md`, `docs/doc-custom.md`) are `section: common` in the workbench registry; `docs/doc-general.md` lists all 10 general docs; `docs/doc-custom.md` lists exactly `CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md`.
- [ ] The portable seed (all three copies, byte-identical where required) declares the 10 general docs and states "General docs are required."
- [ ] `/CJ_document-release` SKILL.md states the tier logic (general = required + stub-scaffolded; custom = per-repo) and carries the advisory missing-general-doc audit rule.
- [ ] `docs/philosophy.md` "Two tiers, one portable pass" states required-ness.
- [ ] The workbench Common section is byte-identical to the seed Common section (incidental diagram-line drift fixed).
- [ ] `validate.sh` + `test.sh` fully green with no new checks and no fixture edits.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000100: complete contract restatement — registry flip + seed growth to 10 entries + views regen + skill tier-logic statement + philosophy amendment + secondary-reference sweep + growth-safe seed test assertions
- [ ] Coordinate: confirm no new validate.sh check and no `scripts/test.sh` fixture churn anywhere in the build
- [ ] Coordinate: USAGE.md freshness for `skills/CJ_document-release/` (Check 14) lands in the same PR

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-09: Created. General docs become required — reclassify 6 docs as `section: common`, restate the Common-prose contract as a 10-doc general table with an explicit required rule, and have /CJ_document-release state the tier logic.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- spec/doc-spec.md
- templates/doc-spec-common.md
- scripts/doc-spec.sh
- docs/doc-general.md
- docs/doc-custom.md
- skills/CJ_document-release/SKILL.md
- skills/CJ_document-release/USAGE.md
- docs/philosophy.md
- CLAUDE.md
- tests/cj-document-release-config.test.sh

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The set boundary (exactly 6 docs to flip) was decided before the design session started — the premise gate was a confirmation, not a discovery.
- The deliverable is a *statement* in the skill, not a new gate: "required" = must exist, enforced by existing machinery (Check 15/17 + stub-scaffold + the seed), plus an advisory audit finding that never halts.
- Complete restatement (Approach B) over the minimal flip (Approach A): a seed that states "general docs are required" while keeping the "four human docs" framing would argue with itself.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-09 — Summary: Premises 1-4 agreed at the premise gate ("Agree, all four"): the required rule lands in the portable Common seed; the general set is the 10 named docs; "required" = must-exist via existing machinery (no new hard gate); seed requirement strings stay portable while the workbench registry keeps specialized ones.
- [decision] 2026-06-09 — Summary: Approach C (machine-enforced `--list-general-docs` + hard validate.sh check) deliberately deferred; eligible as a later TODOS row only if the operator asks.
