---
name: "Post-land local skills install + collection_version drift fix"
type: feature
id: "F000041"
status: active
created: "2026-06-03"
updated: "2026-06-03"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-180257-28011"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/post_land_sync`
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

- [ ] `scripts/post-land-sync.sh --dry-run` previews (resolves `.source`, shows the would-run `git pull --ff-only` + `skills-deploy install` + current collection_version) and mutates nothing.
- [ ] Real run: `git -C <.source> pull --ff-only` + `<.source>/scripts/skills-deploy install`, then prints collection_version before→after.
- [ ] `./scripts/validate.sh` → 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` → 0 failures, INCLUDING a new `tests/post-land-sync.test.sh` wired into `scripts/test.sh`.
- [ ] `CLAUDE.md` "CI/CD merge convention" documents the post-merge step (a) + the bypass reason (b) + the drift note (c).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000074 — implement `scripts/post-land-sync.sh` + CLAUDE.md docs + test wiring (single child story carries the whole feature)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Post-land local skills install helper + collection_version drift fix (a+b+c scope).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/post-land-sync.sh` (NEW)
- `CLAUDE.md` (EDIT — CI/CD merge convention)
- `tests/post-land-sync.test.sh` (NEW)
- `scripts/test.sh` (EDIT — wire new test)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- `gh pr merge` is a REMOTE merge; the local post-merge auto-sync hook (`setup-hooks.sh` → `skills-deploy install`) only fires on a LOCAL `git pull`/`merge`. So after a skill PR lands, the operator's `~/.claude/skills/` is not refreshed and the manifest `collection_version` is not updated until someone manually runs `skills-deploy install`.
- Live evidence: after merging PR #200 + #201, `~/.claude/.skills-templates.json` `collection_version` read 6.0.8 while `.source` (main) was at 6.0.10 — a 2-version drift. The fix is dogfoodable on completion (running the helper reconciles this exact drift).
- A single helper collapses (a) the post-merge install step and (c) the drift reconciliation into one operator command — "fix the drift" stops being a manual ritual and becomes `./scripts/post-land-sync.sh`.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Summary: Chose Approach A (a `post-land-sync.sh` helper + CLAUDE.md docs) over Approach B (doc-only reminder line). Rationale: a helper encodes the correct pull-checkout + install-from-where once, instead of two commands the operator must remember and get right; it is also testable via `--dry-run` and dogfoodable against the live drift.
- [decision] Summary: Scope held to a+b+c (operator-chosen) — a small helper + docs + test, NOT a re-architecture of skills-deploy. Wiring the helper into `/land-and-deploy`'s tail is deferred to a follow-up (v1 ships the convention doc + manual invocation).
