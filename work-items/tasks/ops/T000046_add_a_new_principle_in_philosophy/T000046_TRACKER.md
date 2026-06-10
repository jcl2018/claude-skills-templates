---
name: "Add a new principle in philosophy mentioning this document integrity topic"
type: task
id: "T000046"
status: active
created: "2026-06-09"
updated: "2026-06-09"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/pensive-robinson-08ad9c"
branch: "claude/pensive-robinson-08ad9c"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/add_a_new_principle_in_philosophy`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [ ] Parent scope read (parent tracker reviewed)
- [ ] Working branch created (`branch` field populated)
- [ ] Required docs scaffolded (test-plan)
- [ ] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/add_a_new_principle_in_philosophy/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Implement: Add a new principle in philosophy mentioning this document integrity topic

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-09: Created. Auto-scaffolded by /CJ_goal_task from topic: Add a new principle in philosophy mentioning this document integrity topic

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `docs/philosophy.md` — add the third doc-contract principle `### Trustworthy by construction, not by convention` + its front-table row (the only doc change).
- `work-items/tasks/ops/T000046_add_a_new_principle_in_philosophy/test-plan.md` — filled Scope + 7 concrete regression rows (work-item artifact).

## Insights

### Implementation spec

**What the principle is:** the third principle under the EXISTING
`## Topic: Doc contract` in `docs/philosophy.md` — document INTEGRITY. Distinct
claim vs the two sibling principles ("one file, human + machine" = where the
contract lives; "Two tiers, one portable pass" = what it covers): a doc you
can't trust is worse than no doc, so trust is *enforced by machinery* rather
than promised by convention.

**Machinery the principle names (generically, no work-item IDs):** generated
views regenerated from the registry and drift-failed by CI (never hand-edited);
declared⇔on-disk both directions + registry schema validation; the portable
Common seed kept byte-identical across its copies by a drift test; the hard
no-work-item-ID lint for human docs + the front-table gate; the doc-release
pass self-bootstrapping a missing contract, stub-scaffolding missing declared
docs, and advisorily auditing each registered doc against its declared
requirement (incl. the missing-general-contract-doc check).

**Hard constraints (validate.sh enforces):** front summary table gains a
matching row in the same position order as the body (Check 20); NO work-item
IDs anywhere in `docs/philosophy.md` (Check 19); `## Decision tree` stays the
last `## ` heading; generated views untouched (Check 23 stays green).

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): Add a new principle in philosophy mentioning this document integrity topic


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: Add a new principle in philosophy mentioning this document integrity topic -->

- 2026-06-09 [impl-decision] Named the principle "Trustworthy by construction, not by convention" and placed it as the THIRD `###` under the existing `## Topic: Doc contract` (after "Two tiers, one portable pass", before `## Decision tree`, which stays the last `## ` heading). Front-table row inserted directly after the "Two tiers" Doc-contract row so table order matches body order (Check 20 + the registry requirement that the table lists every principle).
- 2026-06-09 [impl-decision] Framed the principle as complement-not-duplicate of its two siblings: "one file" = where the contract lives, "two tiers" = what it covers, this one = why you can believe it (integrity enforced by machinery — generation over hand-maintenance, byte-identical seed copies, declared-vs-on-disk + schema gates, hard lints, self-healing + advisory audit — not promised by convention). Closing line draws the hard-gate vs advisory-audit division of labor.
- 2026-06-09 [impl-finding] Wrote all machinery references generically (no check numbers in the new body text, no work-item IDs anywhere — Check 19 hard lint; verified zero `[FSTD][0-9]{6}` matches). Generated views (docs/doc-general.md / doc-custom.md) deliberately untouched, so the Check 23 drift check stays green.
- 2026-06-09 [impl] Modified 1 doc file (docs/philosophy.md: one front-table row + one `###` principle section) + filled this work-item's test-plan.md (Scope + 7 concrete regression rows). Tracker Files/Todos/Insights updated.
- 2026-06-09 [impl-auto] Auto-mode run; --auto allowed (1 doc file touched, no sensitive surface).
- 2026-06-09 [impl-pass] T000046: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-09 [qa-smoke] 1 (new principle present): green — exactly one `### Trustworthy by construction, not by convention` at docs/philosophy.md:322, inside `## Topic: Doc contract` (line 262; no new `## Topic:` heading added).
- 2026-06-09 [qa-smoke] 2 (front-table row, position): green — third **Doc contract** row at line 15, directly after the "Two tiers, one portable pass" row (line 14); table order matches body order.
- 2026-06-09 [qa-smoke] 3 (integrity machinery named): green — all five machinery classes present in the new section (generated views; byte-identical seed drift test; declared⇔on-disk + schema validation; hard lints incl. front-table gate; self-healing bootstrap/stub-scaffold + advisory audit).
- 2026-06-09 [qa-smoke] 4 (no sibling duplication): green — agent-inspected vs the two sibling principles; distinct integrity/trust-by-machinery thesis, explicitly framed as complement ("where it lives / what it covers / why you can believe it"); no restatement of "one file" or "two tiers".
- 2026-06-09 [qa-smoke] 5 (decision tree last): green — last `## ` heading is `## Decision tree: which CJ_ skill do I call?` (line 352).
- 2026-06-09 [qa-smoke] 6 (no work-item IDs): green — `grep -nE '[FSTD][0-9]{6}' docs/philosophy.md` zero matches (Check 19 hard lint clean).
- 2026-06-09 [qa-smoke] 7 (validate.sh): green — `./scripts/validate.sh` exit 0, Errors 0 / Warnings 0; Checks 19/20/23 explicitly PASS (front-table, no work-item refs, generated views in sync). Run per orchestrator caution: validate.sh directly, NOT scripts/test.sh (uncommitted tree).
- 2026-06-09 [qa-smoke-summary] green: 7/7 non-manual rows green (0 manual rows pending)
- 2026-06-09 [qa-pass] T000046 (task): green smoke from test-plan rows (7 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. Note: `Core changes committed` gate intentionally pending — orchestrator commits after QA-green per /CJ_goal_task pipeline.
- 2026-06-10T06:09:37Z [task-pr-opened] T000046 v6.0.63 PR #258
  pr_url=https://github.com/jcl2018/claude-skills-templates/pull/258
