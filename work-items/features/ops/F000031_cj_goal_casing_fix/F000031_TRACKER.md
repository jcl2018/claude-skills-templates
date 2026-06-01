---
name: "Casing-only rename of F000027 verbs (cj_goal_feature/defect → CJ_goal_feature/defect)"
type: feature
id: "F000031"
status: active
created: "2026-05-31"
updated: "2026-05-31"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260531-153400-70306"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_goal_casing_fix`
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

- [ ] `skills/CJ_goal_feature/` and `skills/CJ_goal_defect/` exist as canonical dirs with SKILL.md + pipeline.md; the old lowercase dirs (`skills/cj_goal_feature/`, `skills/cj_goal_defect/`) no longer exist under `skills/`.
- [ ] `deprecated/cj_goal_feature/SKILL.md` and `deprecated/cj_goal_defect/SKILL.md` exist with F000027-shim-shape content (frontmatter + Deprecation Banner section + Routing section, ~40 lines each).
- [ ] `skills-catalog.json` has 6 edits applied: 2 active entries renamed (uppercase, `files` paths updated), 2 deprecated entries added (lowercase, `files` under `deprecated/`), 2 existing F000027 shim entries' `depends.skills` field updated to point at the uppercase canonical instead of the lowercase shim. `./scripts/validate.sh` passes.
- [ ] F000027 shim cross-references updated: `skills/CJ_goal_run/SKILL.md` and `skills/CJ_goal_auto/SKILL.md` reference `/CJ_goal_feature` (uppercase) in their `description`, Deprecation Banner text, and Routing Skill-tool invocation — they route directly to the new canonical, not to the lowercase shim.
- [ ] `rules/skill-routing.md`, `CLAUDE.md`, `CHANGELOG.md`, `doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `README.md` (auto-gen) all show the new uppercase names in routing examples and decision tree mentions. CHANGELOG.md v5.0.12 entry describes the casing-fix in `## For users` voice.
- [ ] `scripts/cj-goal-common.sh` greps clean for active-routing references to the lowercase skill names; telemetry path strings (`CJ_goal_feature.jsonl`) are already uppercase and stay; the line-3 header comment is flipped to uppercase.
- [ ] `scripts/test.sh` lines 1044-1049 (F000027 S000060 regression test) updated from `grep -qE '/cj_goal_feature'` to `'/CJ_goal_feature'` with surrounding ok/fail messages adjusted. `./scripts/test.sh` passes locally.
- [ ] `tests/cj-goal-feature-smoke.test.sh` + `tests/cj-worktree-init.test.sh` reviewed and updated per Step 6 rule (active-routing → uppercase; runtime-artifact names — `cj-feat-` worktree prefix, smoke test's own filename — stay lowercase).
- [ ] Invoking `/cj_goal_feature` (lowercase) via the Skill tool prints the deprecation banner and routes to `/CJ_goal_feature`; invoking `/CJ_goal_feature` directly works without banner. Same for the defect pair.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` both pass (required by pre-commit hook).
- [ ] No git history rewritten; memory files NOT touched in PR diff (operator-local follow-up).
- [ ] Version-slot preflight ran (`./scripts/check-version-queue.sh`); if collision detected, the three baked-in `5.0.12` literals (deprecated/cj_goal_feature/SKILL.md, deprecated/cj_goal_defect/SKILL.md, + 2 new catalog entries) hand-edited before `/ship`.
- [ ] PR shipped at the version slot reported by check-version-queue.sh (target: v5.0.12) and stops for human review.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Implement S000064 (single atomic story — rename + shim creation + catalog + cross-reference flips, all in one PR).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-31: Created. Casing-only rename of F000027 verbs to align with the rest of the CJ_* family; lowercase deprecation shims under deprecated/ sunset at v6.0.0 with the existing F000027 shim wave.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/cj_goal_feature/` → `skills/CJ_goal_feature/` (rename via two-step git mv on case-insensitive APFS)
- `skills/cj_goal_defect/` → `skills/CJ_goal_defect/` (rename via two-step git mv)
- `deprecated/cj_goal_feature/SKILL.md` (NEW shim)
- `deprecated/cj_goal_defect/SKILL.md` (NEW shim)
- `skills-catalog.json` (6 edits: 2 renames + 2 new deprecated entries + 2 dep-chain fixes on CJ_goal_run/auto)
- `skills/CJ_goal_run/SKILL.md` + `skills/CJ_goal_auto/SKILL.md` (F000027 shim cross-references flipped to uppercase canonical)
- `rules/skill-routing.md` (routing examples flipped, deprecated front doors block expanded)
- `CLAUDE.md` (skill routing section + Auto-worktree paragraph rewrite)
- `CHANGELOG.md` (v5.0.12 entry)
- `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md` (decision tree + mechanism references)
- `README.md` (auto-regenerated)
- `scripts/cj-goal-common.sh` (header comment flip)
- `scripts/test.sh` (S000060 regression-test regex flip + message string update)
- `tests/cj-goal-feature-smoke.test.sh` + `tests/cj-worktree-init.test.sh` (per-row flip per decision rule)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- macOS case-insensitive APFS imposes TWO constraints: (1) `git mv lower UPPER` is a no-op on the same volume — must go through a temp name; (2) the lowercase deprecation shim cannot live at `skills/cj_goal_feature/` (path-collides with the new uppercase canonical at the same inode) — it must live elsewhere, hence `deprecated/cj_goal_feature/`.
- This PR is the FIRST actual use of CLAUDE.md's "Deprecated skills convention" (deprecated skills live under `deprecated/{name}/`). F000027's `CJ_goal_run` + `CJ_goal_auto` shims didn't follow it (they're at `skills/` for historical reasons); migrating them is deferred to v6.0.0 sunset PR where they get removed anyway — mid-life migration would be pure churn.
- The "goal" token in CJ_goal_* names is a load-bearing family signal (end-to-end orchestrator vs single-phase utility), not noise. The user's initial framing ("remove the goal token") inverted when the family-signal meaning surfaced; the actual defect is casing-only.
- The user defaulted to "ship the fix while it's in your head" (Approach A: full rename + shims now) over "defer to v6.0.0 bundle" (Approach B). The CLAUDE.md hygiene conventions section reads like a postmortem on stale bundled-future TODO rows, so a self-contained PR now beats coordinated transition later.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-31 [decision]: Approach A (full rename + shims now) chosen over B (defer to v6.0.0 bundle) and C (codify casing as intentional). Rationale: self-contained PR; immediate cleanup; reuses tested F000027 shim pattern; doesn't create a new sunset wave (rides v6.0.0 already retiring CJ_goal_run/auto).
- 2026-05-31 [decision]: Lowercase deprecation shims placed under `deprecated/{name}/` per CLAUDE.md documented convention (first actual use). F000027's existing shims stay at `skills/` until v6.0.0 sunset removes them entirely (deferred migration = pure churn).
- 2026-05-31 [decision]: Single atomic user-story decomposition (S000064) — no further splitting. All 10 implementation steps land together because they're tightly coupled (catalog edits + cross-reference flips + test-regex update all must commit atomically to keep validate.sh + test.sh green).
- 2026-05-31 [finding]: Memory file references at `~/.claude/projects/.../memory/` are operator-local state — excluded from this PR's diff per `feedback_workbench_scope` memory rule (touching them would leak personal state into PR and not apply on other operators' machines). Operator-local follow-up after merge: grep + flip active-routing references; leave historical artifacts verbatim.
