---
name: "Shared scripts travel with the install (runtime de-coupling foundation)"
type: user-story
id: "S000085"
status: active
created: "2026-06-05"
updated: "2026-06-05"
parent: "F000049"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260605-160453-69246"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker (F000049) to understand the epic scope
2. Use the parent's working branch (ship in the same PR): `cj-feat-20260605-160453-69246`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the parent's /office-hours design (`.gstack/gstack-style-deployment-design-20260605.md`) — brief stub linking the parent (atomic story)
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. Atomic story — no child-task decomposition

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement per the SPEC architecture: deposit the shared scripts at the deployed home; rewire the 4 orchestrator-family skills' resolution preambles to the 3-tier chain; re-tier the catalog
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests`)
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
3. Walk E2E manually — the consumer-repo simulation (no `.source` present)
4. Ensure all child tasks (if any) have shipped — N/A (atomic)
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] `skills-deploy install` deposits the shared `scripts/*.sh` set (+ `skills-update-check`, 27 files) into the deployed `_cj-shared/scripts/` home that travels with the install
- [x] The 4 orchestrator-family skills resolve shared scripts via a 3-tier chain: repo-local → deployed `_cj-shared` → `.source` (legacy fallback)
- [x] A shared-script-dependent skill path resolves + runs with NO separate source clone present (S000085 consumer-sim test green)
- [x] The 4 orchestrator-family skills are re-tiered `workbench → local-only` in `skills-catalog.json`; `/CJ_portability-audit --no-adjudication` confirms `FINDINGS=0`
- [x] Non-breaking: workbench self-dev (repo-local) and the legacy `.source` fallback both still work; `validate.sh` + `scripts/test.sh` green

## Todos

- [x] Decide O2: deployed shared-scripts home → `~/.claude/_cj-shared/scripts/` (a deposited dir, deposited as a SET so the scripts' dirname-relative sibling resolution holds; NOT a proto-bundle — that would bleed S2 into S1)
- [x] Teach `skills-deploy install` to deposit the shared scripts at that home (checksum-tracked in the manifest `shared_scripts` map, like templates)
- [x] Author the shared 3-tier resolution idiom; wire it into the 4 orchestrator-family skills (8 resolution blocks)
- [x] Re-tier the 4 orchestrator-family skills `workbench → local-only` in `skills-catalog.json`; teach `/CJ_portability-audit` the deployed-home recognition + a comment-line precision fix
- [x] Add a consumer-repo simulation test (S000085, D000030/D000032 pattern) proving no-`.source` resolution
- [x] Update the docs/tests that asserted the old `workbench` tier (the `tests/cj-document-release.test.sh` portability assertion + the F000025 todo_fix wiring guard)

## Log

- 2026-06-05: Created. S1 of F000049 — the non-breaking runtime de-coupling foundation. Scaffolded (DESIGN/SPEC/TEST-SPEC).
- 2026-06-05: Implemented (operator resumed the build on this branch). Deposit + 3-tier preambles (4 skills) + catalog re-tier (4 → local-only) + audit deployed-home recognition + comment-line precision fix + S000085 consumer-sim test. `validate.sh` + `scripts/test.sh` green (Failures: 0); `/CJ_portability-audit --no-adjudication` FINDINGS=0. Reconciled the design's "12 skills" estimate to the 4 that actually re-tier.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `scripts/skills-deploy` — new `SHARED_SCRIPTS_SRC`/`SHARED_SCRIPTS_TARGET` vars + a deposit block (`scripts/*.sh` + `skills-update-check` → `~/.claude/_cj-shared/scripts/`, checksum-tracked in the manifest `shared_scripts` map) + an install summary line
- `skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_defect/SKILL.md`, `skills/CJ_goal_todo_fix/SKILL.md`, `skills/CJ_document-release/SKILL.md` — inserted the deployed `_cj-shared` middle tier into 8 resolution blocks (3-tier: repo-local → `_cj-shared` → `.source`)
- `skills-catalog.json` — re-tiered the 4 orchestrator-family skills `workbench → local-only`
- `scripts/cj-portability-audit.sh` — deployed-home recognition (`has_deployed_tier` → a root-script reach needs only `local-only`) + a comment-line `is_exec` precision fix (a `#`-comment line executes nothing)
- `scripts/test.sh` — S000085 consumer-sim integration test (5 assertions) + relaxed the F000025 todo_fix wiring guard to the 3-tier form
- `tests/cj-document-release.test.sh` — portability assertion now expects `local-only`

## Insights

Three ground-truth findings reshaped the build vs the design estimate:

1. **12 → 4.** 12 skills reach `.source`, but only 4 EXECUTE shared root scripts and re-tier (`CJ_goal_feature`/`CJ_goal_defect`/`CJ_goal_todo_fix`/`CJ_document-release`). The other 8 reach `.source` only for the passive `skills-update-check` nudge (already standalone). Two other `workbench` skills (`CJ_personal-workflow`, `CJ_portability-audit`) are pinned by different patterns — out of S1's shared-scripts scope.
2. **Scripts already self-resolve siblings.** `cj-goal-common.sh` resolves its siblings `dirname`-relative (`BASH_SOURCE`) FIRST, then `.source`. So depositing the whole `scripts/` set into one `_cj-shared/scripts/` dir makes every transitive sibling co-locate automatically — **no script-internal changes needed.** Only the 4 skill *preambles* (which resolve the entry-point script) needed the deployed tier.
3. **The re-tier exposed an audit FP.** Re-tiering to `local-only` turned two prose comments (`# (CLAUDE.md), so ...`) into false "depends on CLAUDE.md (needs workbench)" findings — the `(` trips `is_exec`'s statement-start cue (the D000032 class, for comment lines). Fixed in the audit alongside the deployed-home recognition.

Net: S1 is a narrow, mechanical change (deposit + a shared preamble idiom + a catalog re-tier + two audit-precision touches), not a deep rewrite. The wide part (install==clone, retiring worktree/`.source`/`post-land-sync`) is S2–S5.

## Journal

- 2026-06-05T23:50:00Z [decision] O2 resolved: the deployed shared-scripts home is `~/.claude/_cj-shared/scripts/`, populated by a `skills-deploy install` deposit step (modeled on the rules/templates deposit, manifest-tracked under `shared_scripts`). NOT a `cj-workbench/` proto-bundle — that would bleed S2's single-bundle layout into S1, which S1's non-goals exclude. The whole `scripts/*.sh` set deposits together so the scripts' dirname-relative sibling resolution keeps transitive helpers co-located.
- 2026-06-05T23:55:00Z [finding] The design's "12 skills re-tier" was an over-count. Ground truth: 12 skills reach `.source`, only 4 execute shared root scripts and re-tier (`CJ_goal_feature`/`CJ_goal_defect`/`CJ_goal_todo_fix`/`CJ_document-release`). SPEC/DESIGN/TRACKER reconciled to 4; a reconciliation note added to the SPEC Problem Statement.
- 2026-06-05T23:58:00Z [finding] Re-tiering to `local-only` surfaced an `is_exec` false positive: a `# (CLAUDE.md), so ...` prose comment was mis-read as an executed CLAUDE.md read (the `(` trips the statement-start cue — the D000032 quoted-literal FP class, for comment lines). Fixed in `cj-portability-audit.sh` (a `#`-comment line is non-runnable) alongside the `has_deployed_tier` deployed-home recognition. The S000083 audit fixtures (incl. S000083i) stay green — no regression.
- 2026-06-05T16:30:00Z [decision] Atomic story — DESIGN is a brief stub linking the parent F000049 design (`.gstack/gstack-style-deployment-design-20260605.md`); the full target architecture + S1 scope live there. Scope frozen to the non-breaking foundation: shared scripts travel with the install + 3-tier resolution + tier re-classification, with the `.source` fallback retained (removed only in S4).
