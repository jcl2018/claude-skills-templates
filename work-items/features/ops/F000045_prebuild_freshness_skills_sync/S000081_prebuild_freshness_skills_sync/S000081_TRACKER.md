---
name: "Pre-build base-freshness + skills-sync (Fork 1 + Fork 2 + all-3-orchestrator wiring)"
type: user-story
id: "S000081"
status: active
created: "2026-06-04"
updated: "2026-06-04"
parent: "F000045"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-000025-81623"
blocked_by: ""
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Prerequisite: derives directly from the parent feature's /office-hours
     session; the parent's design is sufficient context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/prebuild_freshness_skills_sync` (using parent's branch — shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's session) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; three tightly-coupled script edits shipped as one cohesive change)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [ ] Fork 1: `cj-worktree-init.sh` fast-forwards local `main` to `origin/$BRANCH` before `git worktree add`, only when on trunk and `origin/$BRANCH` exists; records `ff'd N commits` in the JSON `note`.
- [ ] Fork 1: diverged local `main` → WARN in `note` (`local main diverged from origin; building on local main`), no ff, no halt.
- [ ] Fork 1: offline / no origin / fetch failed → silently proceed on local main, `note: freshness skipped (offline)`, exit 0.
- [ ] Fork 1: already-fresh local main → no-op ff path.
- [ ] Fork 2: new `--phase sync` in `cj-goal-common.sh` delegates to `post-land-sync.sh`'s guarded core; installs `skills-deploy` from `.source`; emits `SYNC_RAN`, `VERSION_BEFORE`, `VERSION_AFTER`, `PHASE_RESULT`.
- [ ] Fork 2: `--dry-run` previews with no mutation; `--no-sync` skips entirely → `PHASE_RESULT=skipped`; guard refusal / offline pull → `PHASE_RESULT=skipped` (not `failed`), exit 0.
- [ ] Piece 3: all three orchestrators call `--phase sync` in the preamble before the worktree block; `--no-sync` is forwarded; `todo_fix` additionally gains the `skills-update-check` snippet.
- [ ] `scripts/validate.sh` + `scripts/test.sh` pass, including new `cj-worktree-init.test.sh` cases (behind/diverged/offline/already-fresh) + the sync-phase tests + the `zzz-test-scaffold` fixture update.

## Todos

<!-- Actionable items for this story. -->

- [x] Fork 1: insert fail-soft fetch + `git merge --ff-only` step in `cj-worktree-init.sh` between dirty-state check and name composition (Step 5.5); extend the `note` field; update header comment.
- [x] Fork 2: add `--phase sync` + `--no-sync` flag to `cj-goal-common.sh`; reuse `post-land-sync.sh` guarded core (invoked as subprocess via 2-level resolver); update `--phase` validation list + header doc.
- [x] Piece 3: wire `--phase sync` into `CJ_goal_feature`, `CJ_goal_defect`, `CJ_goal_todo_fix` preambles (before Default-worktree block); add update-check snippet to `todo_fix`; document `--no-sync` in each Usage/flags section + USAGE.md.
- [x] Tests: added behind/diverged/offline/already-fresh cases to `tests/cj-worktree-init.test.sh`; added sync-phase test `tests/cj-goal-common-sync.test.sh` (dry-run / `--no-sync` / guard-refusal / real-run); parallel-edited `scripts/test.sh` (`zzz-test-scaffold` integration block + two new test-runner blocks).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Atomic story carrying Fork 1 (ff local main), Fork 2 (`--phase sync`), and all-3-orchestrator wiring.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/cj-worktree-init.sh` (modified — Fork 1: Step 5.5 fail-soft fetch + ff; header doc; Step 9 note)
- `scripts/cj-goal-common.sh` (modified — Fork 2: `--phase sync` + `--no-sync` + `resolve_post_land_sync` helper; `--phase` list + header doc)
- `scripts/post-land-sync.sh` (UNCHANGED — invoked as a subprocess by the sync phase; no CLI behavior change needed)
- `skills/CJ_goal_feature/SKILL.md` (modified — Pre-build skills-sync preamble + `--no-sync` flag doc)
- `skills/CJ_goal_defect/SKILL.md` (modified — Pre-build skills-sync preamble + `--no-sync` flag doc)
- `skills/CJ_goal_todo_fix/SKILL.md` (modified — Preamble: update-check snippet [newly gained] + Pre-build skills-sync; `--no-sync` input-shape doc)
- `skills/CJ_goal_feature/USAGE.md` (modified — Check 14 drift: pre-build sync + ff mental model, `--no-sync`)
- `skills/CJ_goal_defect/USAGE.md` (modified — Check 14 drift: pre-build sync + ff mental model, `--no-sync`)
- `skills/CJ_goal_todo_fix/USAGE.md` (modified — Check 14 drift: pre-build sync + update-check mental model, `--no-sync`)
- `tests/cj-worktree-init.test.sh` (modified — 4 new Fork-1 cases: behind/diverged/offline/already-fresh, local fake origin)
- `tests/cj-goal-common-sync.test.sh` (NEW — sync-phase test: dry-run / `--no-sync` / guard-refusal / real-run; hermetic)
- `scripts/test.sh` (modified — sync-phase end-to-end in the zzz-test-scaffold integration block + 2 new test-runner blocks + updated cj-worktree-init runner comment)

## Insights

<!-- Non-obvious findings worth remembering. -->

- `.source == repo root` collapse: Fork 2 runs first and pulls `.source`'s `main`; Fork 1's ff then finds main already current (no-op). No double-pull.
- `skills-deploy install` MUST run from `.source`, not the worktree — a worktree-invoked install skips foreign-owned skills (collection-version-stuck bug). `post-land-sync.sh` already does this.
- The `zzz-test-scaffold` integration fixture in `scripts/test.sh` is a recurring implement blind spot (F000032/34/35) — pre-flighted as an explicit Todo + smoke row.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-04: Treat as an atomic story (no task children) — the three pieces (Fork 1, Fork 2, wiring) are tightly coupled and ship in one PR; the implement step consumes the single SPEC directly.
- 2026-06-04 [impl-decision] Fork 2 invokes `post-land-sync.sh` as a SUBPROCESS (not a sourced/extracted core) and maps its stdout (`collection_version (before)/(after)`) to the KEY=VALUE schema. Rejected extracting post-land-sync.sh's core into a shared lib — the SPEC's Components Affected marks post-land-sync.sh "refactor OR invoke directly (extract only if trivial+clean)"; a clean subprocess call with output-parsing is simpler and leaves post-land-sync.sh's vetted CLI behavior untouched (zero risk to the F000041 contract). The env var `POST_LAND_SYNC_MANIFEST` is inherited by the subprocess, which is what makes the tests hermetic.
- 2026-06-04 [impl-decision] Fork 1 re-checks BRANCH itself (`git branch --show-current`) inside Step 5.5 rather than trusting Step 4's `$BRANCH` — Step 4 is bypassed by `--force-create` (drain mode), and a forced worktree off a non-trunk branch must NOT fast-forward it. Freshness step is skipped entirely under `--dry-run` (an ff is a filesystem mutation; dry-run's contract is emit-JSON-only).
- 2026-06-04 [impl-decision] Fork 1's freshness outcome rides the EXISTING `note` field of the Step 9 `created` emit (`created $NAME; <freshness-note>`) per the SPEC — no new JSON field, so the caller's existing `jq -r '.note'` parse surfaces it. Three terminal notes: `ff'd N commits` / `local main diverged from origin; building on local main` / `freshness skipped (offline)`.
- 2026-06-04 [impl-finding] `--auto` would normally demote to propose-mode here (sensitive surfaces: `scripts/test.sh` validator + `skills/*/SKILL.md`; >2 files). This run is a SILENT leaf subagent dispatched by /CJ_goal_feature with the design pre-approved at the pipeline's Step 2.7 gate and NO AskUserQuestion tool available — proceeded in auto mode per the orchestrator contract (the SPEC + DESIGN are the pre-approval).
- 2026-06-04 [impl-finding] Parallel-edited `scripts/test.sh`'s `zzz-test-scaffold` integration fixture (TEST-SPEC S6) — the recurring F000032/34/35 implement blind spot. Added a hermetic `--phase sync` end-to-end exercise (dry-run + `--no-sync`) inside the integration block against a throwaway fake `.source`, plus two new test-runner blocks, plus updated the cj-worktree-init runner count comment (13→incl. 4 Fork-1 cases).
- 2026-06-04 [impl] Wrote 1 new file (tests/cj-goal-common-sync.test.sh); modified 10 (cj-worktree-init.sh, cj-goal-common.sh, 3 orchestrator SKILL.md, 3 USAGE.md, cj-worktree-init.test.sh, test.sh). All 8 P0 requirements implemented (Fork 1 + Fork 2 + 3-way wiring). post-land-sync.sh UNCHANGED.
- 2026-06-04 [impl-auto] Auto-mode run (silent leaf subagent; sensitive-surface AUQ not reachable — operator pre-approved at Step 2.7).
- 2026-06-04 [impl-pass] S000081: implementation complete. Phase 2 implementer-owned gates transitioned. Fork-1 freshness cases + sync-phase test + the zzz-test-scaffold S6 fixture all green; validate.sh green (self-verify pending final run).
- 2026-06-04 [qa-smoke] S1 (AC-1): green — cj-worktree-init.test.sh Case F1a: local main 1 behind origin → ff'd 1 commit, worktree base + local main == origin tip.
- 2026-06-04 [qa-smoke] S2 (AC-2): green — cj-worktree-init.test.sh Case F1b: diverged local main → 'diverged' note recorded, no ff (local main unchanged), build proceeded (no halt).
- 2026-06-04 [qa-smoke] S3 (AC-3): green — cj-worktree-init.test.sh Case F1c: offline/no-origin → state=created, note='freshness skipped (offline)', exit 0.
- 2026-06-04 [qa-smoke] S4 (AC-1): green — cj-worktree-init.test.sh Case F1d: already-fresh local main → no freshness note, worktree base == origin tip (the .source==root collapse).
- 2026-06-04 [qa-smoke] S5 (AC-5, AC-6, AC-8): green — cj-goal-common-sync.test.sh: dry-run/--no-sync/guard-refusal(not-on-main, dirty, missing .source)/real-run all emit SYNC_RAN/VERSION_BEFORE/VERSION_AFTER/PHASE_RESULT; guard refusals → PHASE_RESULT=skipped (never failed), exit 0; --no-sync → no skills-deploy invoked; real ~/.claude collection_version unchanged (hermetic via POST_LAND_SYNC_MANIFEST).
- 2026-06-04 [qa-smoke] S6 (AC-7): green — scripts/test.sh full suite exit 0 (0 failures); includes the zzz-test-scaffold-adjacent F000045/S000081 integration block (test.sh:307-351) exercising --phase sync --dry-run (4-key schema, no mutation) + --no-sync (PHASE_RESULT=skipped, no install) hermetically, plus the cj-goal-common-sync.test.sh runner. scripts/validate.sh exit 0 (0 errors / 0 warnings).
- 2026-06-04 [qa-smoke-summary] green: 6/6 non-manual rows green (0 manual rows pending). validate.sh + full test.sh both exit 0.
- 2026-06-04 [qa-e2e-run-start] RUN_ID=20260604-011200-qa commit=61dfeb9
- 2026-06-04 [qa-e2e] E1 (AC-1, AC-4): green — fresh-base+synced-skills verified hermetically: behind/already-fresh Fork-1 cases (smoke F1a/F1d) prove worktree base == origin tip; `cj-goal-common.sh --phase sync --mode feature --dry-run` (fake .source) emits SYNC_RAN/VERSION_BEFORE=6.0.99/VERSION_AFTER=6.0.99/PHASE_RESULT=ok, exit 0, install resolved FROM .source per post-land-sync core; no mutation to fake source HEAD or real ~/.claude. Run inline (depth-3 ceiling — no recursive orchestrator run). [parent-inline]
- 2026-06-04 [qa-e2e] E2 (AC-6): green — `--phase sync --mode feature --no-sync` → PHASE_RESULT=skipped, SYNC_RAN=0, exit 0, message confirms 'Fork-1 ff still runs in the worktree phase'; cj-goal-common.sh:400-402 short-circuits BEFORE resolving/calling .source (no skills-deploy install). Fork-1 ff independence corroborated by smoke F1a (ff runs in worktree phase, separate from sync). [parent-inline]
- 2026-06-04 [qa-e2e] E3 (AC-7): green — all 3 orchestrator preambles invoke `--phase sync` before the Default-worktree block: feature (sync L38/64 < worktree L76/81), defect (sync L38/64 < worktree L76/124), todo_fix (sync L55 < worktree L197/219). `--no-sync` forwarded into _SYNC_FLAGS in all 3 (feature L59, defect L59, todo_fix L49). todo_fix gained the skills-update-check snippet (SKILL.md:19), matching feature/defect. todo_fix passes --mode feature (valid placeholder: sync phase only echoes MODE, never branches on it; --mode todo_fix would be rejected by the feature|defect validator — correct choice). [parent-inline]
- 2026-06-04 [qa-e2e] E4 (AC-3, AC-5): green — offline/guard-refusal never blocks: smoke F1c (offline Fork-1 → note='freshness skipped (offline)', exit 0) + cj-goal-common-sync.test.sh guard cases (not-on-main / dirty .source / missing .source all → PHASE_RESULT=skipped, exit 0, NEVER failed). Both halves fail-soft; build proceeds clean. [parent-inline]
- 2026-06-04 [qa-e2e-summary] green (0s subagent — all rows run parent-inline per depth-3 ceiling; 4 rows parent-inline; 0 deferred): All 4 E2E criteria green via hermetic dry-run + --no-sync + structural inspection (no real recursive orchestrator run, no live ~/.claude mutation). real ~/.claude collection_version (6.0.16) untouched throughout.
- 2026-06-04 [qa-pass] S000081 (user-story): green smoke + green E2E. Phase 2 gates transitioned (Acceptance criteria verified met + Smoke tests pass). 8/8 P0 ACs covered; validate.sh + full test.sh green; all checks hermetic (no live ~/.claude mutation).
