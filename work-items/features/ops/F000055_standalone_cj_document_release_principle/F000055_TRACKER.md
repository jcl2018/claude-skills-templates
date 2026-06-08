---
name: "Standalone /CJ_document-release + the general/custom doc-contract principle"
type: feature
id: "F000055"
status: active
created: "2026-06-08"
updated: "2026-06-08"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/sleepy-cerf-e8f24b"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/standalone_cj_document_release_principle`
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

- [ ] `docs/philosophy.md` carries a new sibling principle under `## Topic: Deployment` stating the general/custom two-tier doc model + the portable any-repo pass + the wire-into-CI hook, with a matching front-table row, no work-item IDs; `validate.sh` Checks 19 + 20 stay green.
- [ ] `/CJ_document-release` Step 6.7.2 guards the `skills-catalog.json` read: with the catalog absent it emits one clean skip note (no `jq` stderr noise), skips the skill-MD audit half AND the `.cj-goal-feature/` scratch write; the registry-doc audit (6.7.1/6.7.3) including the human-doc no-work-item-ID lint still runs.
- [ ] The gstack-absent failure surfaces a `[doc-sync-red]` message at the Step 4→5 boundary naming "gstack `/document-release` not installed" as a possible cause (covers resolution-failure AND non-green; no programmatic skill-presence probe).
- [ ] `CJ_document-release` portability stays honest at `local-only` (not relabeled `workbench`); the Step 5.7 portability gate passes with no `[portability-red]`; USAGE.md drift (Check 14) resolved.
- [ ] `docs/architecture.md` documents the portable CI hook scoped honestly (`doc-spec.sh --validate` is portable; the declared⇔on-disk loop + `front_table` are workbench-local) AND a new cold-repo smoke row in `tests/cj-document-release-config.test.sh` proves the Step 6.7.2 guard path runs with no `jq` error and no stray `.cj-goal-feature/` artifact.
- [ ] `scripts/validate.sh` + `scripts/test.sh` green; the PR opens and STOPS for review (no auto-merge).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000097 — implement all five deltas (philosophy principle + front-table row; Step 6.7.2 catalog guard; Step 4→5 [doc-sync-red] message; portability/USAGE bookkeeping; architecture.md CI recipe + cold-repo smoke test)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-08: Created. Standalone /CJ_document-release runnable in any repo + a general/custom doc-contract principle in philosophy.md, scaffolded from the APPROVED /office-hours design `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-sleepy-cerf-e8f24b-design-20260608-093825.md`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `docs/philosophy.md` — new sibling principle under `## Topic: Deployment` + front-table row
- `skills/CJ_document-release/SKILL.md` — Step 6.7.2 `skills-catalog.json` guard + Step 4→5 `[doc-sync-red]` message
- `skills/CJ_document-release/USAGE.md` — drift bump + note new behavior
- `docs/architecture.md` — portable CI-hook recipe (scoped honestly)
- `tests/cj-document-release-config.test.sh` — cold-repo smoke row

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Two of the three asks were already built: the two-tier general/custom model (`doc-spec.md` `section: common`/`section: custom`, used by the knowledge-base repo with 4 common + 43 custom docs) and the single canonical seed (`doc-spec.sh --seed` byte-identical to `templates/doc-spec-common.md`). So the feature is small and additive — name the principle, fix one real cold-run rough edge, document the CI hook.
- "Standalone in any repo" means decoupled from workbench-repo-local files (no hard dependency on this repo's `skills-catalog.json`), NOT "runs without gstack" — gstack `/document-release` stays a HARD dependency by operator decision.
- The `skills-catalog.json`-absent path does NOT halt today; it emits stderr `jq` noise and silently produces a skill-MD-less audit. The fix only makes that skip explicit and clean (and avoids leaving a stray untracked `.cj-goal-feature/` artifact in a consumer repo where it isn't gitignored).
- Scope honesty: the general doc SET + the mechanical `doc-spec.sh --validate` gate travel to a consumer repo; this repo's philosophy PROSE and the declared⇔on-disk loop + `front_table` discipline (validate.sh Checks 15/15a) do NOT.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Approach A (robustness + principle + CI recipe, minimal additive) chosen over Approach B (native rebuild dropping gstack) and Approach C (principle doc only). Summary: B is mostly rework with regression risk given the existing native registry audit + self-heal; C leaves the cold-run rough edge in place. A is the smallest diff delivering all three asks.
- [decision] gstack `/document-release` stays a HARD dependency (operator decision); "standalone" = decoupled from workbench-repo-local files, not gstack-free. No programmatic skill-presence probe (false-halt risk, cf. TODO #251); the actionable message goes at the Step 4→5 boundary covering resolution-failure AND non-green.
- [decision] New sibling principle under `## Topic: Deployment` (accepting one extra front-table row) over expanding the existing `### The doc contract is one file` principle in place — the general/custom + portable-pass + CI framing is a distinct idea worth its own row.
- [decision] `doc-spec.sh --check-on-disk` (declared⇔on-disk subcommand) deferred to a TODOS follow-up, NOT this PR — out of scope per Scope honesty.
