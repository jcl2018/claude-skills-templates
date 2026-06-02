---
name: "v6.0.0 sunset — full nuke of deprecated shims + deprecation infrastructure"
type: feature
id: "F000035"
status: active
created: "2026-06-02"
updated: "2026-06-02"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260602-010655-sunset"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/v600_sunset`
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

- [ ] `jq 'length' skills-catalog.json` returns 5 fewer entries than pre-PR (the 5 deprecated entries removed)
- [ ] `jq -r '.[] | .status' skills-catalog.json | sort -u` returns ONLY `"active"` and `"experimental"`
- [ ] `ls deprecated/ 2>&1` returns "No such file or directory"
- [ ] `ls skills/CJ_goal_run skills/CJ_goal_auto 2>&1` returns "No such file or directory" for both
- [ ] `grep -c 'deprecat' scripts/skills-deploy` returns 0
- [ ] `grep -c 'Retired skills' doc/PHILOSOPHY.md` returns 0; `grep -c 'Deprecation tombstones' doc/ARCHITECTURE.md` returns 0; `grep -c 'Deprecated front doors' rules/skill-routing.md` returns 0
- [ ] `./scripts/validate.sh` passes (0 errors)
- [ ] `./scripts/test.sh` passes (deleted test files don't break the runner)
- [ ] `VERSION` reads `6.0.0`; `CHANGELOG.md` has the `## [6.0.0]` entry
- [ ] README.md (post-regen) has no `### Deprecated` table

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000068 — execute the v6.0.0 sunset (atomic-commit all 16 steps from DESIGN Recommended Approach)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-02: Created. F000035 v6.0.0 sunset wave — full nuke of 5 deprecated alias shims plus the deprecation infrastructure (status enum value, `deprecated/` dir, `--include-deprecated` flag, F000030 retired-skill drift convention, tombstone sections across PHILOSOPHY.md + ARCHITECTURE.md + skill-routing.md). Solo-project framing collapses the backward-compat justification to zero; Approach B (full nuke) chosen over A (sunset shims only).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- VERSION
- CHANGELOG.md
- README.md
- CLAUDE.md
- skills-catalog.json
- rules/skill-routing.md
- doc/PHILOSOPHY.md
- doc/ARCHITECTURE.md
- scripts/validate.sh
- scripts/skills-deploy
- scripts/generate-readme.sh
- skills/CJ_goal_run/ (deleted)
- skills/CJ_goal_auto/ (deleted)
- deprecated/ (deleted entire tree)
- tests/cj-goal-investigate-shim.test.sh (deleted)
- tests/cj-goal-investigate-did-allocator.test.sh (deleted)
- tests/eval/CJ_goal_run/ (deleted)
- tests/cj-worktree-init.test.sh (updated if needed)
- tests/cj-goal-doc-sync-auq-recommendation.test.sh (updated if needed)
- TODOS.md
- ~/.claude/projects/.../memory/project_investigate_retire_candidate.md (deleted) + MEMORY.md index entry

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- This is the workbench's first deletion-only feature — every prior F-ID added a convention; F000035 removes them. Every diff line is subtractive.
- The "solo project" framing is what collapses the deprecation infrastructure's justification to zero. The whole layered cake (status enum + `deprecated/` dir + `--include-deprecated` flag + audit conventions) exists for ONE reason: backward-compat with parallel operators. With one operator, that reason vanishes.
- The deprecated shims documented their own death: the canonical replacement path (`/CJ_goal_feature`) is the very pipeline routing this cleanup PR. Bonus dogfood.
- Validate.sh Check 13/14/15 predicates intentionally stay `status != "deprecated"` even after the enum value is dropped — filters nothing today but is robust to a future re-introduction of the enum. One fewer downstream change at minimal cost.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-02: Approach B (full nuke) chosen over A (sunset shims only) via /office-hours AUQ. Summary: Solo project means the deprecation infrastructure has no operator to protect; retire it alongside the shims it was built for. Future deprecations re-introduce a pattern designed around their actual retirement.
- [decision] 2026-06-02: VERSION bump 5.0.19 → 6.0.0 (MAJOR). Summary: This is the documented sunset wave; the major bump signals the breaking change to muscle-memory invocations of removed skill names.
- [decision] 2026-06-02: Atomic single-commit decomposition (S000068). Summary: All 16 Recommended-Approach steps must land together — Check 9b enum closed-list edit must be staged with the 5-entry catalog removal so the staged enum matches the staged catalog. Splitting risks a transient validate.sh red state.
- [gates-update] 2026-06-02: Phase 2 Implement complete. Summary: /CJ_implement-from-spec executed all 16 design steps in the cj-feat-20260602-010655-sunset worktree — deleted 5 shim dirs + entire deprecated/ tree (Step 1+2); pruned 5 catalog entries (17 → 12) leaving status only {active, experimental} (Step 3); closed the validate.sh status enum + stripped --include-deprecated from skills-deploy + dropped the deprecated-section generator (Steps 4-6); surgically removed deprecation surfaces from CLAUDE.md, doc/PHILOSOPHY.md (## Retired skills + drift-rule prose), doc/ARCHITECTURE.md (## Deprecation tombstones + 4 inline mentions), rules/skill-routing.md (Steps 7-10); deleted/updated tests (Step 11); marked TODOS rows DONE (Step 12); deleted the project_investigate_retire_candidate.md memory + index line (Step 13); bumped VERSION 5.0.19 → 6.0.0 + prepended CHANGELOG entry (Step 14); regenerated README.md sans Deprecated table (Step 15). Awaiting QA + /ship.
- [qa] 2026-06-02: QA verification by /CJ_qa-work-item (leaf subagent under /CJ_goal_feature). RESULT=red. Summary: validate.sh PASSES (0 errors, 0 warnings) and all 13 structural verification checks PASS (catalog count 12, status enum {active,experimental}, deprecated/ + skills/CJ_goal_run + skills/CJ_goal_auto gone, all 5 tombstone/convention headings absent, VERSION=6.0.0, CHANGELOG ## [6.0.0] present, README has no ### Deprecated section, generate-readme.sh emits no Deprecated section, skills-deploy --help has no --include-deprecated flag, skills-deploy bash -n clean). However test.sh FAILS with 7 failures — scripts/test.sh itself still contains stale test rows referencing the deleted skills, violating Success Criterion #15 (`./scripts/test.sh` passes). Specific stale rows: (a) lines 1099-1108 grep skills/CJ_goal_run/SKILL.md for shim banner [FAIL], (b) lines 1116-1124 grep deprecated/CJ_goal_investigate/SKILL.md [FAIL], (c) lines 1192-1199 invoke deleted tests/cj-goal-investigate-did-allocator.test.sh [rc=127 FAIL], (d) lines 1225-1233 invoke deleted tests/cj-goal-investigate-shim.test.sh [rc=127 FAIL], (e) lines 1500-1545 (F000026 cj-handoff-gate Tests 9/10/11) reference deleted skills/CJ_goal_run/run.md + skills/CJ_goal_auto/auto.md [FAIL x3]. Also flagged 3 residual mentions in active prose: README.md line 15 + skills-catalog.json line 138 (CJ_personal-pipeline description still says "INTERNAL -- invoked by /CJ_goal_run") + CLAUDE.md lines 438-444 (entire "### Edge case 2: multi-PR bundles via /CJ_goal_run" subsection retained). doc/SKILL-CATALOG.md line 109 has "historically by /CJ_goal_run" which is arguably historical context but worth flagging. Phase 2 QA-owned gates NOT transitioned — Phase 3 gate "Smoke tests pass in CI" cannot be ticked while test.sh is red. Recommended remediation before /ship: (1) remove stale rows from scripts/test.sh (sections at lines 1099-1124, 1192-1233, 1500-1545); (2) edit skills-catalog.json + regenerate README.md to drop /CJ_goal_run from the CJ_personal-pipeline description; (3) remove or rewrite CLAUDE.md "### Edge case 2" subsection; (4) optionally hedge doc/SKILL-CATALOG.md line 109 wording. Re-run validate.sh + test.sh after; expect both green.

- 2026-06-02T08:44:17Z [qa-reverify] QA RED caught 7 test.sh failures + 4 residual mentions; orchestrator applied 7 fixes: (1) trimmed 2 stale shim assertions from F000025 Regression test in scripts/test.sh (CJ_goal_run + CJ_goal_investigate shim greps); (2) replaced did-allocator test runner block with a tombstone comment; (3) replaced investigate-shim test runner block with a tombstone comment; (4) deleted F000026 Tests 8-11 (the auto.md/run.md sentinel/classifier assertions; Tests 1-7 of cj-handoff-gate.sh helper kept — still in use by /CJ_goal_feature + /CJ_goal_defect; Tests 12-13 kept numerically); (5) skills-catalog.json CJ_personal-pipeline description updated to reference /CJ_goal_todo_fix + /CJ_goal_feature (was '/CJ_goal_run'); (6) deleted CLAUDE.md `### Edge case 2: multi-PR bundles via /CJ_goal_run` subsection; (7) doc/SKILL-CATALOG.md CJ_personal-pipeline status line dropped 'historically by /CJ_goal_run' suffix; bonus (8) skills-catalog.json CJ_goal_defect description dropped historical '~80% reshape of /CJ_goal_investigate v1.1' lineage; README.md regenerated. ./scripts/validate.sh → PASS (0 errors); ./scripts/test.sh → PASS (0 failures, Test 13 SKIP-with-presence-check). All residual-prose grep findings now in TODOS.md DONE/archived rows only (historical record preserved per CLAUDE.md TODOS.md hygiene). Phase 2 QA gates green; ready for /ship.
