---
name: "CJ_repo-init — verify/scaffold per-repo prerequisites for the CJ_ skill family"
type: feature
id: "F000041"
status: active
created: "2026-06-03"
updated: "2026-06-03"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-174453-41356"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_repo_init`
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

- [ ] Run in a fresh repo with CJ_ skills deployed → prints a 3-row gap table, scaffolds valid `TODOS.md` + `cj-document-release.json` + `work-items/` after one confirm, re-run is a clean no-op (exit 0).
- [ ] Scaffolded `cj-document-release.json` passes `validate.sh` Check 16 (parseable JSON, supported `schema_version`).
- [ ] `cj-repo-init.sh` detects an invalid/unparseable `cj-document-release.json` (not just a missing one).
- [ ] `--dry-run` writes nothing and the exit code reflects the gap count.
- [ ] Not-a-git-repo and missing-deployed-manifest paths error / degrade cleanly.
- [ ] `validate.sh` green: skills-catalog entry, USAGE.md 5 sections, doc/SKILL-CATALOG.md section + `(single-step utility)` tag, rules/skill-routing.md trigger.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Implement `scripts/cj-repo-init.sh` (default detect, `--dry-run`, `--fix`) with inline generic seeds.
- [ ] Write `skills/CJ_repo-init/SKILL.md` (frontmatter, detection wrapper, single confirm AUQ) + `USAGE.md` (5 sections).
- [ ] Add `tests/cj-repo-init.test.sh` and wire it into `scripts/test.sh`.
- [ ] Add skills-catalog.json entry (status: experimental), doc/SKILL-CATALOG.md section, rules/skill-routing.md trigger.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. CJ_repo-init — a standalone utility that verifies + scaffolds the per-repo prerequisites (cj-document-release.json, TODOS.md, work-items/ tree) the CJ_ skill family needs to run in a target repo.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-repo-init.sh` (new) — detection/verification/scaffolding engine
- `skills/CJ_repo-init/SKILL.md` (new) — skill wrapper + confirm AUQ
- `skills/CJ_repo-init/USAGE.md` (new) — usage doc
- `tests/cj-repo-init.test.sh` (new) — script unit tests
- `scripts/test.sh` (modified) — wire in the new test
- `skills-catalog.json` (modified) — catalog entry
- `doc/SKILL-CATALOG.md` (modified) — catalog section
- `rules/skill-routing.md` (modified) — routing trigger

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The gap was named from lived experience — hitting `[doc-sync-no-config]` HALTs and `/CJ_suggest` exit-1 on a repo with skills installed but config files absent. Installation (`setup.sh` / `skills-deploy`) and `~/.claude/` audit (`CJ_system-health`) are covered; the per-repo config seam was not.
- Renamed from the original `cj_goal_init` ask to `CJ_repo-init` once the namespace cost was named: `cj_goal_*` is reserved for topic→PR orchestrators; a standalone utility belongs in the `CJ_<thing>` namespace alongside `CJ_suggest` / `CJ_system-health`.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-03: Adopt detection-in-script / AUQ-in-prose split (mirrors the documented `skills-doc-sync-check` pattern). Summary: the bash engine does pure, testable, idempotent detect/verify/scaffold; SKILL.md prose owns the single confirm AUQ. Chosen over a pure-SKILL.md approach because the workbench standardizes on logic-in-`scripts/` + a `tests/*.test.sh`, making the skill QA-able by `/CJ_qa-work-item`.
- [decision] 2026-06-03: Seed content lives inline in the script (heredocs) for v1 rather than under `templates/CJ_repo-init/`. Summary: the two seed files are tiny + generic, so avoiding a new templates deployment surface keeps skills-catalog `templates` entries + manifest churn out of v1. Revisit if seeds grow.
