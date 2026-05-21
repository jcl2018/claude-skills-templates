---
name: "/cj_goal_defect skill — reshape of investigate v1.1 + no-doc bug-report scaffolding"
type: user-story
id: "S000058"
status: active
created: "2026-05-21"
updated: "2026-05-21"
parent: "F000027"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/hardcore-hermann-c2b955"
blocked_by: ""
# pr: ""
---

<!-- Prerequisite: derives directly from the parent feature's /office-hours
     session; the parent F000027_DESIGN.md is sufficient design context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_two_verb_refactor` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (N/A — atomic story)

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

- [ ] `/cj_goal_defect "<bug>"` with no pre-existing defect dir scaffolds a bug report into `.inbox/<slug>/DRAFT.md` (no existing defect dir assumed).
- [ ] `/investigate` runs as an Agent subagent with sentinel-wrapped JSON output; the Iron-Law holds — no fix promotes without a populated root cause.
- [ ] On root cause, RCA + test-plan are written and the `.inbox` draft is promoted to `work-items/defects/.../D000NNN_<slug>/`.
- [ ] The tail keeps the human `/ship` Gate #2 then runs `/land-and-deploy --suppress-readiness-gate`; halt taxonomy + telemetry inherit `/CJ_goal_investigate` unchanged.
- [ ] Nesting depth ≤ 2 (orchestrator → leaf subagent); no subagent-spawns-subagent path.

## Todos

<!-- Actionable items for this story. -->

- [ ] Author `skills/cj_goal_defect/SKILL.md` reshaping investigate v1.1's flat `pipeline.md` (~80% reuse).
- [ ] Implement no-doc bug-report scaffolding (`.inbox/<slug>/DRAFT.md` → promote after Iron-Law).
- [ ] Wire `/investigate` as an Agent subagent with sentinel-wrapped JSON; reuse the v1.1 halt taxonomy.
- [ ] Wire the tail: `/CJ_qa-work-item` → `/ship` (Gate #2) → `/land-and-deploy --suppress-readiness-gate` + tracker journal + telemetry.
- [ ] Add a catalog entry (`experimental`) + routing line.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-21: Created. The `defect` verb — a reshape of `/CJ_goal_investigate` v1.1's flat pipeline with no-doc bug-report scaffolding; ~80% reuse, defect-first per Approach C.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/cj_goal_defect/SKILL.md`
- `skills/cj_goal_defect/pipeline.md` (if the reshape keeps a separate flow doc)
- `skills-catalog.json`
- `scripts/cj-goal-common.sh` (consumed; owned by S000057)

## Insights

<!-- Non-obvious findings worth remembering. -->

- `defect` mirrors current `/CJ_goal_investigate` (human `/ship` gate → deploy), so the Iron-Law gate comes for free via `/investigate` and ~80% of the existing flat `pipeline.md` is reusable.
- The two tails genuinely differ from `feature` (defect human-ships-then-deploys; feature PR-stops), which is why there is no shared tail doc — the common bits are the deterministic `cj-goal-common.sh` only.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-21: `defect` keeps the human `/ship` Gate #2 then deploys (Open Question 4 RESOLVED). Summary: symmetry with current investigate; the human diff review is the autonomy ceiling for bug fixes too.
- [decision] 2026-05-21: Build `defect` first (Approach C sequencing). Summary: ~80% reuse of investigate v1.1 makes it the lower-risk first ship; pair with S000057's early feature smoke harness so the feature path isn't left unvalidated.
