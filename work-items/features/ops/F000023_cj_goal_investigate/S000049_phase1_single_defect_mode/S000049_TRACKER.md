---
name: "v1.0 single-defect mode — /CJ_goal_investigate skill + pipeline + chain"
type: user-story
id: "S000049"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000023"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/S000049_cj_suggest_impr_draft_filter-20260515-192236"
blocked_by: ""
---

<!-- Prerequisite: parent F000023_DESIGN.md captures the design context.
     This atomic story derives directly from the parent feature's
     /office-hours session — DESIGN.md here is a brief stub linking back. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_investigate_v1` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
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
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `skills/CJ_goal_investigate/SKILL.md` exists with proper frontmatter (name, description, version, allowed-tools).
- [ ] `skills/CJ_goal_investigate/pipeline.md` exists with full step-by-step orchestration logic.
- [ ] `skills-catalog.json` entry added with `status: experimental`.
- [ ] `rules/skill-routing.md` entry added for `/CJ_goal_investigate <D-id|fragment>` routing.
- [ ] `/CJ_goal_investigate D000NNN` resolves D-ID, dispatches `/investigate` with sentinel-wrapped JSON instruction, parses response, writes RCA + test-plan artifacts, chains to `/CJ_qa-work-item` + `/ship` + `/land-and-deploy`.
- [ ] `/CJ_goal_investigate "fragment"` fuzzy-matches defect dir basenames + tracker `name:` field. Ambiguous (2+) halts with ranked candidate list. Zero matches halts with "no defect matches".
- [ ] `/CJ_goal_investigate --dry-run <arg>` previews chain plan + idempotency state + expected write paths WITHOUT writing any file.
- [ ] All 9 end-states in the Halt-on-Red Taxonomy implemented with their journal-entry formats and `next_action=` / `resume_cmd=` / `raw_output_path=` fields.
- [ ] 5-row idempotency resume state table implemented (RCA-populated? × fix-in-tree? × PR-open? × PR-merged? combos).
- [ ] RCA artifact write maps JSON keys → template headings: Symptom, Reproduction Steps, Investigation Trail, Root Cause, Affected Components, Fix Description, Regression Risk.
- [ ] Test-plan artifact write appends one row per regression test from JSON.regression_test.
- [ ] Phase 1 dogfood: dispatch `/investigate` as Agent subagent against scratch bug, confirm sentinel block returned (fallback documented if not).
- [ ] Phase 7 dogfood: run `/CJ_goal_investigate D000NNN` end-to-end against a real existing defect (read tracker journal to confirm not in flight).
- [ ] CHANGELOG entry added.
- [ ] README badge / quick-start updated.

## Todos

<!-- Actionable items for this story. -->

- [ ] Phase 1: Validate the machine handoff — dispatch /investigate with sentinel-wrapped JSON instruction against scratch bug; document live behavior in DESIGN.md.
- [ ] Phase 2: Skill scaffolding — create `skills/CJ_goal_investigate/SKILL.md` + `pipeline.md`; add catalog entry; add routing rule.
- [ ] Phase 3: Resolver + preflight + idempotency table — implement `resolve_defect_dir()`, 5-row resume table, `--dry-run`; test against D000008/D000017/D000019.
- [ ] Phase 4: /investigate dispatch + JSON parser + artifact writes — sentinel-wrapped prompt; JSON parse; RCA + test-plan row writes.
- [ ] Phase 5: Halt-on-red taxonomy — all 9 end-states with journal-entry formats and `next_action=` strings.
- [ ] Phase 6: /CJ_qa-work-item + /ship + /land-and-deploy chain — inline Skill invocations.
- [ ] Phase 7: Dogfood validation — pick one real existing defect; run /CJ_goal_investigate end-to-end; surface issues to v1.0.1.
- [ ] Phase 8: Documentation + ship — update README, CLAUDE.md (skill-routing + v1.1 drain-mode note), CHANGELOG; run /ship → /land-and-deploy.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-15: Created. v1.0 single-defect mode for `/CJ_goal_investigate` — sibling pipeline skill, defect-work-item-aware, machine-readable /investigate handoff, halt-on-red taxonomy, idempotent re-entry.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills/CJ_goal_investigate/SKILL.md (new)
- skills/CJ_goal_investigate/pipeline.md (new)
- skills-catalog.json (modified)
- rules/skill-routing.md (modified)
- README.md (modified)
- CHANGELOG.md (modified)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Sentinel-wrapped JSON handoff is the load-bearing fix. Free-text DEBUG REPORT parsing was the reviewer-flagged critical brittleness.
- `/investigate` Phase 4 writes the fix DIRECTLY to source — there is NO separate `/CJ_implement-from-spec` step in this chain. RCA + test-plan are post-investigate audit artifacts.
- `DONE_WITH_CONCERNS` (`[investigate-unverified]`) must halt pre-ship. Auto-advancing on "concerns" defeats the Iron-Law gate.
- `resolve_defect_dir()` is a single helper that encapsulates the legacy `work-items/defects/<domain>/D000NNN_<slug>/` layout. v1.1's freestanding `D<NNN>_bug-report.md` convention swaps this helper without touching the rest of the chain.

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] 2026-05-15: scope = v1.0 single-defect only; no drain/quiet/lock/sunset.
- [decision] 2026-05-15: machine-readable handoff via dispatch-prompt convention (sentinel-wrapped JSON); not an upstream feature.
- [decision] 2026-05-15: `[investigate-unverified]` halt is Iron-Law-equivalent — does NOT auto-advance to /ship.
- [decision] 2026-05-15: `/CJ_implement-from-spec` NOT in chain; `/investigate` Phase 4 writes the fix directly.
- [decision] 2026-05-15: legacy defect dir convention only (`work-items/defects/<domain>/D000NNN_<slug>/`); freestanding deferred to v1.1.
