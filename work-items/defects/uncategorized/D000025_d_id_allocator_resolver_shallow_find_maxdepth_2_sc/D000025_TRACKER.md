---
name: "CJ_goal_investigate D-ID allocator/resolver shallow find -maxdepth 2 misses nested domains"
type: defect
id: "D000025"
status: active
created: "2026-05-17"
updated: "2026-05-17"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/friendly-cartwright-8d0f52"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: ".inbox/d_id_allocator_resolver_shallow_find_maxdepth_2_sc"
---

<!-- Auto-scaffolded by /CJ_goal_investigate: zero-match fragment "D-ID
     allocator + resolver shallow find -maxdepth 2 scan in
     skills/CJ_goal_investigate/pipeline.md misses nested 2-segment domains
     (work-items/defects/<a>/<b>/D######_*); caused D000022 re-mint collision
     (renumbered to D000024 mid-ship, PR #161). Also highest-N allocation
     ignores D-IDs in git log / TODOS.md" captured as draft
     .inbox/d_id_allocator_resolver_shallow_find_maxdepth_2_sc, promoted to
     D000025 after /investigate populated a root cause (Iron-Law gate passed).
     Domain defaulted to 'uncategorized' (pipeline v1.x contract; domain
     inference deferred) — `mv` to a more specific subdir if desired.
     Self-referential fix: the D-ID was minted by the orchestrator by hand via
     the FIXED union(fs, git, TODOS) algorithm because the in-context pipeline
     copy was the pre-fix buggy -maxdepth 2 allocator. -->

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Working branch: `claude/friendly-cartwright-8d0f52`
3. Scaffold required docs: D000025_RCA.md + D000025_test-plan.md
4. Run `/investigate` to diagnose root cause — done (dispatched by /CJ_goal_investigate)
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

**Gates:**
- [x] `/CJ_personal-workflow check` — validation passed
- [x] Test-plan verified (regression scenarios passing)
- [x] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. From repo root: `find work-items/defects -maxdepth 2 -type d -name 'D[0-9][0-9][0-9][0-9][0-9][0-9]_*' | wc -l` returns far fewer than the unbounded scan — every depth-3 dir under `ops/skills-deploy/`, `ops/ship/`, `ops/workflow/` is missed (including `ops/skills-deploy/D000022_setup_hooks_blind_clobber`).
2. Run `/CJ_goal_investigate` with a zero-match fragment so it drafts → investigates → promotes (Step 7.4 allocator runs) when the highest existing D-ID lives only in a nested domain or only in git/TODOS.
3. **Pre-fix observe:** the allocator mints an already-used D-ID. Real incident: a run minted D000022 over the existing depth-3 `ops/skills-deploy/D000022_*`; renumbered to D000024 mid-ship (caught at /ship — PR #161 / commit dc7a46f, v4.6.12). A D-ID present only in `git log`/`TODOS.md` with no directory (e.g. deferred D000023, commit b3a67e3) is likewise silently re-mintable.

Deterministic repro: `tests/cj-goal-investigate-did-allocator.test.sh` Case 1
negative control (old `-maxdepth 2` scan returns 50 against an `a/b/D000099`
fixture) — the post-fix deep scan returns 99.

## Todos

- [x] Root-cause the shallow `-maxdepth 2` scan (3 sites) + filesystem-only allocator.
- [x] Remove the depth cap on all 3 `find "$DEFECTS_ROOT"` sites; union allocator over fs + git log + TODOS.md.
- [x] Correct now-false prose in pipeline.md Step 2 + SKILL.md resolver note.
- [x] Add isolated-fixture regression test (nested domain + git/TODOS union + negative control + guard); wire into `scripts/test.sh`.
- [ ] `/ship` + `/land-and-deploy` (driven by /CJ_goal_investigate chain).

## Log

- 2026-05-17: Created (auto-scaffolded from draft). Symptom: `skills/CJ_goal_investigate/pipeline.md`'s Step 7.4 highest-N allocator and Step 2 exact-D-ID / BASENAME_HITS resolvers used `find "$DEFECTS_ROOT" -maxdepth 2`, reaching only depth-2 `work-items/defects/<domain>/D######_*` and missing nested 2-segment domains (depth 3). The allocator under-counted the highest D-ID and re-minted a colliding one (real D000022 incident → renumbered D000024 mid-ship, PR #161); nested-domain defects were unresolvable by exact/fuzzy D-ID. Separately, the filesystem-only highest-N ignored D-IDs recorded only in `git log` subjects or `TODOS.md` (e.g. deferred D000023). Root-caused by `/investigate` (dispatched by `/CJ_goal_investigate`); fix written + independently verified by the orchestrator.

## PRs

- [#162](https://github.com/jcl2018/claude-skills-templates/pull/162) — v4.6.13 — open (created by /ship via /CJ_goal_investigate)

## Files

- `skills/CJ_goal_investigate/pipeline.md` — removed `-maxdepth 2` from all
  three `find "$DEFECTS_ROOT"` sites (Step 2 exact-D-ID, Step 2 BASENAME_HITS,
  Step 7.4 allocator); allocator now `max(union(filesystem, git log --all
  subjects, TODOS.md)) + 1`, POSIX/BSD-portable; all other semantics
  (glob-escaping, the `grep -E '/D[0-9]{6}_'` filter, dedup, case/literal
  safety, mkdir-lock) preserved. Corrected now-false Step 2 prose.
- `skills/CJ_goal_investigate/SKILL.md` — resolver note now documents
  multi-segment domains + the git/TODOS union.
- `tests/cj-goal-investigate-did-allocator.test.sh` — new isolated-fixture
  regression test: depth-3 `a/b/D000099` + shallow `x/D000050` + TODOS-only
  D000150 + git-stub D000200; asserts deep scan / exact / fuzzy / union;
  negative control reproduces the old bug; guard greps pipeline.md so
  `-maxdepth 2` cannot silently return.
- `scripts/test.sh` — wired the new regression test into the suite.

## Insights

- **The depth cap was never load-bearing.** The `D[0-9]{6}_` basename is
  globally unambiguous, so an unbounded `find` is both correct and simpler.
  `-maxdepth 2` only ever encoded a now-false structural assumption (every
  defect domain = exactly one path segment). The repo organically grew
  nested 2-segment domains (`ops/ship/`, `ops/skills-deploy/`,
  `ops/workflow/`), invalidating the assumption silently.
- **A D-ID is recorded in three durable places, not one.** Directory tree,
  git commit subjects, and `TODOS.md` each independently persist a D-ID. A
  shipped-then-relocated or deferred/freestanding defect (no dir; e.g.
  D000023) is invisible to a filesystem-only max. Allocation must union all
  three so a D-ID is never re-minted.
- **Self-referential bootstrap.** This run's own Step 7.4 promotion executed
  the *pre-fix* buggy allocator (the in-context pipeline copy). The
  orchestrator computed the next D-ID by hand via the fixed union algorithm
  (fs=24, git=24, TODOS=23 → D000025) rather than trusting the buggy
  in-context allocator — documented so the provenance is auditable.

## Journal

- [auto-scaffolded] 2026-05-17: /CJ_goal_investigate captured the zero-match fragment as draft .inbox/d_id_allocator_resolver_shallow_find_maxdepth_2_sc, then promoted to D000025 after /investigate populated the root cause (Iron-Law gate passed). Domain defaulted to 'uncategorized'.
- [allocator-note] 2026-05-17: D-ID minted via the FIXED union(filesystem, git log --all, TODOS.md) algorithm executed by the orchestrator by hand — the in-context pipeline copy was the pre-fix buggy `-maxdepth 2` allocator. union max=24 (fs=24, git=24, todos=23) → D000025. No collision.
- [impl] 2026-05-17: 4-file fix (≤5 blast radius) — pipeline.md (3 find sites + allocator union + prose), SKILL.md (prose), new tests/cj-goal-investigate-did-allocator.test.sh, scripts/test.sh wiring.
- [smoke-pass] 2026-05-17: Orchestrator independently verified (not trusting subagent): `./scripts/validate.sh` PASS (0 errors / 0 warnings); new regression test PASS (5 assertions incl. negative control + guard); the sole `./scripts/test.sh` failure is the PRE-EXISTING, unrelated `scripts/test-deploy.sh` version-drift sandbox failure (reproduced identically on a clean `git stash -u` tree — not introduced by this fix; flagged as a separate task).
- 2026-05-17 [qa-smoke] 1 (regression Case 1 — nested-domain deep scan): green — filesystem max N=99 reached `a/b/D000099_*`; negative control confirms old `-maxdepth 2` returns 50
- 2026-05-17 [qa-smoke] 2 (regression Case 2 — exact-D-ID nested): green — D000099 resolved at `.../a/b/D000099_nested_fixture`
- 2026-05-17 [qa-smoke] 3 (regression Case 3 — BASENAME_HITS nested): green — fuzzy matcher resolved the nested defect (grep filter preserved)
- 2026-05-17 [qa-smoke] 4 (regression Case 4 — fs+git+TODOS union): green — union max=200 (git-only D000200 beat on-disk 99 + TODOS 150) → next D000201
- 2026-05-17 [qa-smoke] 5 (regression Guard — no -maxdepth 2 regression): green — no `-maxdepth 2` cap on any `$DEFECTS_ROOT` find in pipeline.md (fix intact)
- 2026-05-17 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending). `bash tests/cj-goal-investigate-did-allocator.test.sh` RESULT: PASS, exit=0; `./scripts/validate.sh` PASS (0 errors / 0 warnings).
- 2026-05-17 [qa-pass] D000025 (defect): green smoke from test-plan rows (5 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-05-17 [ship] D000025 v4.6.13 PR #162 created via /CJ_goal_investigate. Gate #2 (autonomy ceiling) operator-approved: full pipeline → deploy. Commit ddc5ff0 (9 files, +552/-11). Pre-landing review clean; pre-existing/orthogonal scripts/test-deploy.sh failure triaged (independently revert-proven on clean tree, flagged as separate task). VERSION 4.6.12→4.6.13, queue clean.
