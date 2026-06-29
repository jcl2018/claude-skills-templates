---
name: "Forced contract seeding + stale-engine-shadow fix"
type: user-story
id: "S000116"
status: active
created: "2026-06-29"
updated: "2026-06-29"
parent: "F000069"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "efef2945195363dbcf5559ede5827824d96a67bb"
    completed_at: "2026-06-29T09:19:14Z"
    test_rows_run: 10
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7", "AC-8"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-e2e] E1-E5 green [parent-inline]", "[qa-audit] AUDITS=deferred", "[qa-pass] S000116"]
    ready_for_ship: true
    next_legal: ["Ship"]
---

<!-- Story 3 of the F000069 epic. Buildable + fully-specified this pass.
     Design context: F000069_DESIGN.md + the parent's /office-hours design doc
     (Part 3 / U2) and the Story-3 design doc
     (~/.gstack/projects/jcl2018-claude-skills-templates/forced-seeding-design-20260629-010904.md).
     Makes contract seeding FORCED + RELIABLE in any consumer repo: fixes the
     stale-engine shadow (the actual bug) so the existing seeding fires, and
     force-generates ALL THREE contracts (doc-spec + test-spec + workflow-spec)
     through every adoption path. Stories 1 (S000114) + 2 (S000115) shipped. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/forced_contract_seeding` (shipping in the F000069 branch / PR)
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
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [ ] **Stale-engine capability probe (the bug fix):** BOTH audits' Step-1 engine resolution gains a probe — after picking the repo-local engine, probe it side-effect-free with `--classify` (current engines emit `GENERATION=`). `skills/CJ_doc_audit/SKILL.md` probes its doc-spec.sh + workflow-spec.sh engines; `skills/CJ_test_audit/SKILL.md` probes its test-spec.sh engine. If the repo-local engine does NOT emit `GENERATION=`, treat it as STALE: fall back to `_cj-shared` AND emit `FINDING: stage1/engine-stale — repo-local <engine> is stale (missing --classify); using _cj-shared. Remedy: update/remove the vendored scripts/<engine>.sh or re-run 'skills-deploy install'.` Documented in each skill's error-path grammar / Step 6 report shape. If BOTH repo-local(stale) + `_cj-shared` are unusable → the existing `stage1/engine` unreachable finding.
- [ ] **Shared `do_seed_contracts` routine in `scripts/skills-deploy`** operating on a TARGET repo (cwd or `--repo <path>`): for each of doc-spec, test-spec, workflow-spec — resolve its engine (repo-local → stale-probe → `_cj-shared`); if `spec/<contract>.md` is ABSENT, seed via the engine's `--seed`, CORRUPTION-GUARDED (write temp → require non-empty AND `--validate`-clean → `mv` into `spec/`); idempotent (present ⇒ skip); per-contract line (`seeded` / `present` / `seed-failed`). MUST skip the workbench self-repo (target toplevel == manifest `source`/`bundle_path`, OR the repo already carries the canonical non-skeleton contracts) — re-seeding the workbench would clobber its real `spec/*.md` (DATA LOSS — guarded airtight).
- [ ] **`seed-contracts` subcommand:** `seed-contracts) shift; do_seed_contracts "$@"` + a usage line. Operates on cwd (or `--repo`). The explicit re-runnable adoption command.
- [ ] **`install` always-seeds on the consumer path:** in `do_install` / `do_bundle_install`, AFTER the skills install, if cwd is a git repo AND NOT the workbench self-repo, call `do_seed_contracts` on it (idempotent, forced — no flag). Workbench self-install (install==clone, `source == bundle_path == cwd`) skips. A visible one-line note reports whether seeding ran. Git-repo-guarded so `install` from a non-git dir is a clean no-op.
- [ ] **Audits seed-all-3 lazily:** `/CJ_doc_audit` Step 2 ALSO seeds `workflow-spec` when absent (it owns the `docs/workflows/` surface its Stage 1 freshness-checks), reusing the corruption-guarded temp→validate→mv shape; `/CJ_test_audit` Step 2 unchanged (already seeds test-spec); both now reliable via the Part-1 stale probe.
- [ ] **`scripts/test-deploy.sh`** — coverage for `seed-contracts` + the install always-seeds-consumer path (mirror existing test-deploy cases).
- [ ] **NEW hermetic test** `tests/<name>.test.sh`: (a) `skills-deploy seed-contracts` in a temp consumer repo creates valid `spec/{doc,test,workflow}-spec.md`, re-run is a no-op (all present), and a workbench-like temp repo is SKIPPED; (b) the stale-engine probe — plant a stale repo-local engine stub (lacks `--classify`) in a temp repo, run the relevant resolution, assert fallback to `_cj-shared` + the `engine-stale` finding emitted.
- [ ] **`spec/test-spec-custom.md`** — units rows for the new test(s) so Check 24 reverse-sweep resolves them.

## Todos

- [x] Add the stale-engine capability probe to `skills/CJ_doc_audit/SKILL.md` Step 1 (doc-spec + workflow-spec engines) + `skills/CJ_test_audit/SKILL.md` Step 1 (test-spec engine); document `stage1/engine-stale` in each error-path grammar.
- [x] Build `do_seed_contracts` in `scripts/skills-deploy` (3-contract loop; engine-resolve with stale-probe; corruption-guarded temp→validate→mv; idempotent present-skip; per-contract report; airtight workbench-self-repo skip).
- [x] Add the `seed-contracts` subcommand dispatch + usage line.
- [x] Wire the install always-seeds-consumer hook into `do_install` (git-repo-guarded, self-repo-skip, visible note). `do_bundle_install` delegates to the bundle's own `install`, which is the workbench self-repo and is skipped by the same guard — no separate hook needed there.
- [x] Extend `/CJ_doc_audit` Step 2 (Step 2b) to also lazily seed `workflow-spec` when absent (corruption-guarded shape).
- [x] Add `scripts/test-deploy.sh` coverage for `seed-contracts` + the install always-seeds path (Tests S000116a + S000116b).
- [x] Author the NEW hermetic test `tests/seed-contracts.test.sh` (seed-contracts seeds-all-3 + idempotent + workbench-self skip; stale-engine probe falls back + emits `engine-stale`; corruption guard).
- [x] Add units row in `spec/test-spec-custom.md` (`test-seed-contracts`) for the new test; regenerated the test-catalog (Check 26) accordingly.

## Log

- 2026-06-29: Created. Forced/proactive contract seeding (3 triggers: `seed-contracts` subcommand + install always-seeds-consumer + audits seed-all-3 lazily) + the stale-engine-shadow capability probe (the actual bug fix). Story 3 of the F000069 epic; makes the existing lazy seeding fire reliably in a consumer repo carrying a stale vendored engine, and force-generates all three contracts through every adoption path.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Implement. -->

Changed (this implement pass):

- `scripts/skills-deploy` — modified: NEW `resolve_contract_engine` (repo-local→stale-probe→`_cj-shared`), `is_workbench_self_repo` (worktree-aware manifest-source match OR custom-overlay signal), `do_seed_contracts` (3-contract loop; corruption-guarded temp→non-empty→`--validate`-clean→mv; idempotent present-skip; per-contract report; git-repo guard; airtight self-repo skip); the `seed-contracts` subcommand dispatch + usage; the install always-seeds-consumer hook at the end of `do_install` (git-guarded, self-skip, visible note)
- `skills/CJ_doc_audit/SKILL.md` — modified: Step 1 stale-engine capability probe (doc-spec); Step 3b probe (workflow-spec); NEW Step 2b lazy `workflow-spec` seed; `stage1/engine-stale` in the error-path grammar (prose + error table + report shape)
- `skills/CJ_doc_audit/USAGE.md` — modified: stale-engine probe + lazy workflow-spec seed pitfall (Check-14 content update)
- `skills/CJ_test_audit/SKILL.md` — modified: Step 1 stale-engine capability probe (test-spec); `stage1/engine-stale` in the error-path grammar; Step 2 unchanged (already seeds test-spec)
- `skills/CJ_test_audit/USAGE.md` — modified: stale-engine probe pitfall (Check-14 content update)
- `scripts/test-deploy.sh` — modified: Test S000116a (`seed-contracts` consumer seed-all-3 + idempotent + workbench-self skip) + Test S000116b (install always-seeds consumer cwd + non-git no-op)
- `tests/seed-contracts.test.sh` — NEW hermetic test (A seed-all-3 + validate-clean + idempotent; B workbench-self skip via both signals; C stale-engine fallback + `engine-stale`; D corruption guard)
- `scripts/test.sh` — modified: hand-wired runner block for `tests/seed-contracts.test.sh`
- `spec/test-spec-custom.md` — modified: NEW `test-seed-contracts` units row (Check 24 reverse-sweep resolves it)
- `docs/test-catalog.md` + `docs/tests/test.md` — regenerated (generated surface; Check 26 freshness)

Confirmed no change needed:

- `spec/doc-spec-custom.md` — no new declared doc (skills-deploy is a script, not a doc); validate.sh Check 15a/17 report no orphan
- `docs/architecture.md` / `CLAUDE.md` — narrative doc-sync (folded by `/CJ_document-release` at the orchestrator's Step 5.5, not in this implement pass)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The stale-engine probe is the single highest-value fix: it makes the EXISTING lazy seeding (and the whole audit) work in a consumer repo that carries a stale vendored `scripts/<engine>.sh`. Without it, a stale copy WINS over `_cj-shared` and the seed step silently no-ops — the operator's "the audit skills don't force generate the seeding" symptom.
- `--classify` is the chosen probe because it is SIDE-EFFECT-FREE (read-only) AND every current engine emits `GENERATION=`. A future engine must keep `--classify` side-effect-free for the probe to stay safe.
- The workbench self-repo skip must be AIRTIGHT: a false negative would re-seed the workbench's real `spec/*.md` with empty skeletons (DATA LOSS). Defense-in-depth: detect via manifest `source == repo toplevel` AND/OR canonical-contract presence; the corruption guard + the idempotent `present`-skip add a second + third line; the hermetic test asserts the workbench-self skip.
- `install` always-seeds is a new SURPRISE write surface — running `install` from a non-workbench git repo now writes `spec/*.md`. It is idempotent (skips if present), git-repo-guarded, visible (a one-line note), and the skeletons are valid+minimal. Accepted per the operator's "forced/always" choice.
- A new validate-resolvable test ALWAYS needs its `spec/test-spec-custom.md` units row(s) — Check 24 reverse-sweep makes an unregistered `tests/*.test.sh` a hard failure. Pinned as a P0 requirement so it isn't dropped.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-29 — The stale-engine capability probe is IN regardless. Summary: it is the actual bug behind "the audit skills don't force generate the seeding" — a stale repo-local engine shadows `_cj-shared` and the seed step silently no-ops. The probe (`--classify` → `GENERATION=`) detects the stale copy, falls back to `_cj-shared`, and emits `stage1/engine-stale` naming the remedy.
- [decision] 2026-06-29 — Maximal/forced proactive seeding: three triggers, not one. Summary: the operator chose `seed-contracts` (explicit) + install-always-seeds-consumer (forced, no flag) + audits-seed-all-3-lazily, so EVERY adoption path force-generates all three contracts (doc-spec + test-spec + workflow-spec). A single `do_seed_contracts` routine is the shared implementation all three call.
- [decision] 2026-06-29 — Workbench self-repo detection must be airtight (data-loss guard). Summary: seeding must NEVER fire on the workbench's own checkout (it AUTHORS the contracts). Detect via manifest `source == repo toplevel` AND/OR canonical-contract presence; the corruption guard + idempotent present-skip + a hermetic workbench-self-skip assertion are defense-in-depth.
- [decision] 2026-06-29 — `/CJ_doc_audit` owns the lazy `workflow-spec` seed. Summary: the doc audit's Stage 1 freshness-checks the `docs/workflows/` surface, so it is the natural owner of seeding `workflow-spec` lazily when absent; `/CJ_test_audit` Step 2 stays unchanged (already seeds test-spec).
- [impl-decision] 2026-06-29 — Self-repo detection resolves the target's MAIN toplevel via the git-common-dir parent (not raw `--show-toplevel`). Summary: the manifest `source`/`bundle_path` records the MAIN repo, but a git WORKTREE's `--show-toplevel` differs — a naive equality would FALSE-NEGATIVE inside a worktree (the catastrophic case). `is_workbench_self_repo` uses `dirname "$(git -C "$target" rev-parse --path-format=absolute --git-common-dir)"` (the same idiom `do_install` uses) as the primary signal, OR'd with the secondary `spec/{doc,test}-spec-custom.md` overlay-presence signal. Proven: running `seed-contracts` against THIS worktree is correctly SKIPPED.
- [impl-decision] 2026-06-29 — The corruption guard pins `REPO_ROOT` to the TARGET on `--validate`. Summary: `workflow-spec.sh --seed` emits a registry that `--validate`s clean ONLY in a repo whose catalog has no `CJ_goal_*` orchestrators (the no-vanish check reads the live catalog). Seeding only ever runs on a NON-workbench target (self-repo skipped), so pinning `REPO_ROOT=$target` makes the workflow seed validate vacuously clean in a no-catalog consumer (answers SPEC Open Question #2). Verified all 3 seeds validate-clean in a fresh consumer git repo.
- [impl-finding] 2026-06-29 — `do_bundle_install` needs no separate seeding hook. Summary: it delegates to the bundle's OWN `skills-deploy install` (which runs `do_install`, hence the seeding hook), and the bundle IS the workbench self-repo (install==clone: source==bundle_path==cwd), so the same data-loss guard skips it. The hook lives once, in `do_install`.
- [impl] 2026-06-29 — Wrote 1 new file (tests/seed-contracts.test.sh) + modified 9 (scripts/skills-deploy, skills/CJ_doc_audit/SKILL.md+USAGE.md, skills/CJ_test_audit/SKILL.md+USAGE.md, scripts/test-deploy.sh, scripts/test.sh, spec/test-spec-custom.md, docs/test-catalog.md+docs/tests/test.md regenerated). shellcheck clean on skills-deploy + test-deploy.sh + the new test; validate.sh 0/0; test-spec.sh --validate + --check-coverage green; tests/seed-contracts.test.sh PASS; test-deploy.sh "All tests passed"; live drills confirm consumer seed + idempotent + workbench-self skip + stale-engine fallback + corruption guard.
- [impl-pass] S000116: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-29 [qa-smoke] S1 (AC-2, AC-3, AC-4): green — tests/seed-contracts.test.sh RESULT: PASS (Case A: all 3 contracts seeded + validate-clean + idempotent re-run; workbench-self skip).
- 2026-06-29 [qa-smoke] S2 (AC-1): green — tests/seed-contracts.test.sh Case C: stale repo-local engine (no --classify) falls back to _cj-shared + emits stage1/engine-stale (not a silent no-op).
- 2026-06-29 [qa-smoke] S3 (AC-2): green — tests/seed-contracts.test.sh Case D: corruption guard held; --validate-dirty seed reported seed-failed, nothing written to spec/.
- 2026-06-29 [qa-smoke] S4 (AC-7): green — scripts/test-deploy.sh "All tests passed" incl. Test S000116a (seed-contracts) + S000116b (install always-seeds); grep confirms both case anchors present.
- 2026-06-29 [qa-smoke] S5 (AC-8): green — test-spec.sh --validate (OK schema_version=1) + --check-coverage (OK rows=76 findings=0; test-seed-contracts units row resolves); validate.sh Errors:0 Warnings:0.
- 2026-06-29 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-29 [qa-e2e-run-start] RUN_ID=20260629-021914-87391 commit=efef294
- 2026-06-29 [qa-e2e] E1 (AC-4, AC-2, AC-3): green — live drill in fresh temp consumer repo: first run seeded=3 (each --validate-clean); re-run idempotent seeded=0 present=3. [parent-inline]
- 2026-06-29 [qa-e2e] E2 (AC-3): green — live drill: seed-contracts AND install run from the workbench worktree both report the self-repo SKIP; spec/{doc,test,workflow}-spec.md md5 byte-unchanged before/after (data-loss guard). [parent-inline]
- 2026-06-29 [qa-e2e] E3 (AC-1): green — live drill: planted stale scripts/doc-spec.sh stub (no --classify) in a temp consumer; resolution emitted stage1/engine-stale naming the engine+remedy, fell back to _cj-shared, still seeded valid; negative control (clean engine) emits no finding. [parent-inline]
- 2026-06-29 [qa-e2e] E4 (AC-5, AC-6): green — isolated-target live drill: (a) consumer `install` seeds 3 contracts + visible note; (b) non-git install cwd is a clean no-op (skip note, no spec/); (c) workbench self-install skips + spec/*.md byte-unchanged. [parent-inline]
- 2026-06-29 [qa-e2e] E5 (AC-7, AC-8): green — full suite scripts/test.sh RESULT: PASS (Failures:0), incl. the hand-wired tests/seed-contracts.test.sh runner block + the test-deploy S000116a/b cases; Check 24 reverse-sweep resolves the new test. [parent-inline]
- 2026-06-29 [qa-e2e-summary] green (0s subagent; 5 rows parent-inline; 0 deferred): all 5 E2E rows green via parent-inline live drills (DEFER_AUDIT run; classifier=read-only).
- 2026-06-29 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a/8.6b ran inline; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-29 [qa-pass] S000116 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
