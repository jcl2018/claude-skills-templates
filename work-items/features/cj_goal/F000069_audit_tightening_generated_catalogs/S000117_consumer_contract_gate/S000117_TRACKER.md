---
name: "Consumer-repo deterministic Stage-1 enforcement gate"
type: user-story
id: "S000117"
status: active
created: "2026-06-29"
updated: "2026-06-29"
parent: "F000069"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
---

<!-- Story 4 of the F000069 epic — the FINAL story. Buildable + fully-specified
     this pass. Design context: F000069_DESIGN.md + the parent's /office-hours
     design doc (Part 4 / U3) and the Story-4 design doc
     (~/.gstack/projects/jcl2018-claude-skills-templates/contract-gate-design-20260629-114124.md).
     Delivers the "enforced in each repo" half of the original ask: a
     deterministic `scripts/cj-contract-gate.sh` (the engine-only Stage-1 checks,
     no agent) installable as a consumer pre-commit hook (auto on consumer
     adoption, guarded) + a documented CI snippet, so a contract violation fails
     the commit / the PR automatically. Stories 1 (S000114) + 2 (S000115) + 3
     (S000116) shipped; on this story's land the F000069 epic is COMPLETE
     (all 4 stories). -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/consumer_contract_gate` (shipping in the F000069 branch / PR)
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

- [ ] **NEW `scripts/cj-contract-gate.sh` (the gate):** a bash gate, deployed to `_cj-shared` (added to the shared-scripts deploy set in `scripts/skills-deploy` so `install` ships it). Resolves each engine (repo-local → the Story-3 stale-engine `--classify` probe → `_cj-shared`) and runs the DETERMINISTIC checks against cwd: `doc-spec.sh --check-on-disk` (HARD except `declared-exists` → a SOFT remediation note pointing at `/CJ_document-release`, NOT a block), `test-spec.sh --validate` + `--check-coverage` (HARD; rules-only ⇒ "inactive" not a finding), `workflow-spec.sh --validate` (HARD no-vanish), `test-spec.sh --render-docs --check` + `workflow-spec.sh --render-docs --check` (HARD freshness when a generated surface exists). REGISTRY-GATED throughout: an absent contract (`REGISTRY=absent`) is a clean SKIP (exit 0 for that check). Exits non-zero iff any HARD check finds a violation; prints a compact per-check summary (`PASS` / `FINDING` / `REMEDIATION` / `SKIP`). `--quiet` for hook use. It is the engine-only subset of `validate.sh` (NOT the agent-judged Stage 2/3).
- [ ] **Consumer pre-commit hook auto-install (guarded):** extend `scripts/skills-deploy` `do_install`'s consumer-path block (the Story-3 seeding hook) to ALSO install a pre-commit hook whose body resolves `cj-contract-gate.sh` from `_cj-shared` and runs it (non-zero blocks the commit). REUSE `setup-hooks.sh`'s `install_hook` safety (sentinel-aware idempotent; back up a non-workbench hook with a WARN, do NOT clobber; SKIP a custom `core.hooksPath`/husky with a printed note). The workbench self-repo (`is_workbench_self_repo`) is SKIPPED (it runs `validate.sh` — no double-enforcement); a non-git cwd is a clean no-op. Carry the `setup-hooks` SENTINEL in the hook body so re-install is idempotent + uninstall recognizes it. Prefer factoring `install_hook` into a shared helper both `setup-hooks.sh` + `skills-deploy` source (avoid two drifting copies); if extraction is risky, mirror its exact behavior + a parity test.
- [ ] **Standalone command:** `skills-deploy install-contract-gate` (install the gate hook on cwd) + `--remove` (uninstall the sentinel hook; leave a non-workbench hook untouched) + a usage line.
- [ ] **CI snippet (doc-only):** a GitHub Actions snippet in `docs/architecture.md` / `CLAUDE.md` that runs `cj-contract-gate.sh` on PRs (no workflow file shipped into consumers — a copy-paste snippet).
- [ ] **`scripts/test-deploy.sh` coverage:** consumer install installs the sentinel gate hook; husky / custom-`core.hooksPath` SKIPPED; workbench-self SKIPPED; `install-contract-gate --remove` uninstalls.
- [ ] **NEW hermetic test** `tests/<name>.test.sh`: (a) `cj-contract-gate.sh` PASSes on a clean contract, hard-FAILS on a planted violation (hand-edit a generated catalog stale / a malformed registry / an unregistered `tests/*.test.sh`), and treats a missing declared doc as a SOFT remediation (exit 0, not a block); a registry-absent contract is a clean SKIP; (b) the consumer auto-install installs a sentinel pre-commit hook in a temp git repo, SKIPS a temp repo with `core.hooksPath` set, SKIPS the workbench self-repo; `--remove` uninstalls. End with `RESULT: PASS/FAIL`.
- [ ] **`spec/test-spec-custom.md`:** units row(s) for the new test(s) so Check 24 reverse-sweep resolves them; + `scripts/test.sh` runner wiring for the new `tests/*.test.sh`.

## Todos

- [x] Build `scripts/cj-contract-gate.sh` (engine-resolve with the Story-3 stale `--classify` probe; deterministic checks with `declared-exists`-soft + registry-gated SKIPs; non-zero iff any HARD finding; compact per-check summary; `--quiet`).
- [x] Add `cj-contract-gate.sh` to the shared-scripts deploy set in `scripts/skills-deploy` so `install` ships it to `_cj-shared`. (No edit needed — the deploy globs `scripts/*.sh`, so both `cj-contract-gate.sh` and `cj-hook-lib.sh` ship automatically; verified by the test-deploy S000117a case.)
- [x] Extend `do_install`'s consumer-path block to ALSO install the gate pre-commit hook (guarded — sentinel-aware, back-up-non-workbench, SKIP custom `core.hooksPath`/husky, workbench-self SKIP, non-git no-op). Factored `install_hook` into the shared `scripts/cj-hook-lib.sh` that BOTH `setup-hooks.sh` and `skills-deploy` source (extraction path chosen — preferred over mirror); a parity check asserts `setup-hooks.sh` routes through it.
- [x] Add the `install-contract-gate` subcommand (+ `--remove`) dispatch + usage line.
- [x] Document the gate + the auto-install + the CI snippet in `docs/architecture.md` (new `### The deterministic contract gate` subsection under `## Contract seeding`). (CLAUDE.md convention left to doc-sync.)
- [x] Add `scripts/test-deploy.sh` coverage (consumer install installs the sentinel hook; husky/custom-hookspath skipped; workbench-self skipped; `--remove` uninstalls). (Test S000117a.)
- [x] Author the NEW hermetic test `tests/cj-contract-gate.test.sh` (gate PASS/hard-FAIL/declared-exists-soft/registry-absent-SKIP + consumer auto-install sentinel/husky-skip/self-skip/`--remove`); end with `RESULT: PASS/FAIL`.
- [x] Add the units row in `spec/test-spec-custom.md` for the new test + wire its runner block into `scripts/test.sh` (Check 24).
- [ ] (Deferred to doc-sync / land) Update `F000069_TRACKER.md`: epic COMPLETE on this story's land (all 4 stories) — left to the doc-sync / land step.

## Log

- 2026-06-29: Created. Consumer-repo deterministic Stage-1 enforcement gate — `scripts/cj-contract-gate.sh` (the engine-only Stage-1 checks, no agent) + a guarded consumer pre-commit hook auto-install + a standalone `install-contract-gate`/`--remove` command + a documented CI snippet. Story 4 (FINAL) of the F000069 epic; delivers the "enforced in each repo" half of the original ask. On land the epic is COMPLETE (all 4 stories): the audits are available + seeded + reliable (Stories 1-3) AND enforced in each repo (Story 4).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Implement. -->

Changed in this implementation (see S000117_SPEC.md `### Components Affected` for detail):

- `scripts/cj-contract-gate.sh` — NEW. The deterministic engine-only Stage-1 gate: resolves each engine (repo-local→`--classify`-stale-probe→`_cj-shared`), runs `doc-spec.sh --check-on-disk` (HARD except `declared-exists`→SOFT REMEDIATION), `test-spec.sh --validate` + `--check-coverage` (HARD; rules-only⇒inactive), `workflow-spec.sh --validate` (HARD), both `--render-docs --check` freshness (HARD); registry-gated SKIPs; exits non-zero iff a HARD finding; compact per-check summary; `--quiet` (silent on success). Ships to `_cj-shared` via the `scripts/*.sh` glob.
- `scripts/cj-hook-lib.sh` — NEW. The ONE shared, sourceable clobber-safe hook installer (`cj_install_hook` / `cj_remove_hook` / `cj_resolve_hook_dir` / `cj_has_custom_hookspath` + the `CJ_HOOK_SENTINEL`), sourced by BOTH `setup-hooks.sh` and `skills-deploy` (no two drifting copies). Carries the D000022 safety (sentinel-aware idempotent, atomic mktemp+mv, back-up-non-workbench-with-WARN, backup-fail abort).
- `scripts/skills-deploy` — modified: source `cj-hook-lib.sh`; NEW `gate_hook_body` + `install_contract_gate_hook` (guarded auto-install) + `do_install_contract_gate` (standalone + `--remove`); the consumer-path block now ALSO installs the gate hook after the seeding; `install-contract-gate` dispatch case + usage line.
- `scripts/setup-hooks.sh` — modified: sources `cj-hook-lib.sh` and routes installs through `cj_install_hook` (the inline `install_hook` is now a thin wrapper); behavior identical (Smoke 0/1 of `setup-hooks.test.sh` still green).
- `scripts/test-deploy.sh` — modified: NEW Test S000117a (consumer install installs the sentinel gate hook; husky/custom-`core.hooksPath` skipped; workbench-self skipped; `install-contract-gate --remove` uninstalls; the gate + lib are deployed to `_cj-shared`).
- `tests/cj-contract-gate.test.sh` — NEW hermetic test: PART (a) gate PASS/hard-FAIL(stale-catalog + malformed-registry)/declared-exists-SOFT/registry-absent-SKIP; PART (b) consumer auto-install sentinel / husky-skip / self-skip / `--remove`. Ends `RESULT: PASS/FAIL`.
- `scripts/test.sh` — modified: hand-wired runner block for `tests/cj-contract-gate.test.sh`; the D000022 setup-hooks static checks re-anchored onto `cj-hook-lib.sh` (the new home of the safety) + a parity check that `setup-hooks.sh` sources the lib.
- `tests/setup-hooks.test.sh` — modified: Smoke 1 now also stages `cj-hook-lib.sh` into the temp repo (the lib is a real dependency of `setup-hooks.sh` after the extraction).
- `spec/test-spec-custom.md` — modified: NEW `test-cj-contract-gate` units row (Check 24 reverse-sweep resolves the new test).
- `docs/architecture.md` — modified: NEW `### The deterministic contract gate (cj-contract-gate.sh)` subsection (the gate, the guarded consumer auto-install, the standalone command, the doc-only CI snippet); REVISION added the "adoption completes the repo" mechanism + the fully-hard-except-declared-exists framing + the workflows-subfolder empty tolerance.
- `docs/test-catalog.md` + `docs/tests/test.md` — modified: re-rendered from `test-spec.sh --render-docs` so the new units row is reflected (Check 26 freshness).
- `scripts/doc-spec.sh` — modified (REVISION): `workflows-subfolder` check tolerates an empty/absent `docs/workflows/` when the workflow registry declares ZERO workflows (self-contained `^kind:` grep; freshness-checked into `_cj-shared`).
- `tests/doc-spec-overlay.test.sh` — modified (REVISION): clean fixture + 8d/8f-2/8f-3 carry a workflow-declaring `spec/workflow-spec.md`; NEW case 8f-4 (empty-registry tolerance).
- `CLAUDE.md` — modified (REVISION): the `skills-deploy` scripts-reference row now documents the contract gate + turnkey adoption (Story 4).

## Insights

<!-- Non-obvious findings worth remembering. -->

- `cj-contract-gate.sh` is the engine-only (Stage-1) subset of `validate.sh` — the deterministic cores of Checks 15a/16/17/19/24/26/27, runnable with NO agent (a git hook can't run the agent-judged Stage 2/3). It reuses Story 3's stale-engine `--classify` capability probe in its engine resolution, so a consumer with a stale vendored engine falls back to `_cj-shared` cleanly.
- `declared-exists` MUST be soft (a REMEDIATION note pointing at `/CJ_document-release`, not a block): a freshly-seeded consumer (Story 3) has the contracts but not yet the declared docs, so blocking its next commit on "declared doc missing" would brick adoption. Everything else is a hard block.
- Auto-installing a git hook is intrusive — the `install_hook` back-up-and-warn safety, the custom-`core.hooksPath`/husky SKIP, the workbench-self SKIP (it runs `validate.sh` — no double-enforcement), the standalone `--remove`, and the `declared-exists`-soft rule together keep a fresh adopter from being bricked.
- A new `tests/*.test.sh` ALWAYS needs (a) its `spec/test-spec-custom.md` units row (Check 24 reverse-sweep makes an unregistered test a hard failure) AND (b) a parallel `scripts/test.sh` runner block — the recurring implement-subagent blind spot. Pinned as a P0 requirement so it isn't dropped.
- Prefer factoring `install_hook` into ONE shared helper both `setup-hooks.sh` + `skills-deploy` source (avoid two drifting copies of the hook-install safety); if extraction is risky, mirror its exact behavior + add a parity test.
- CI shellcheck is STRICT (quote expansions, `git -C` not `cd &&`, no `local x=$(...)` masking). Do NOT bump VERSION/CHANGELOG — `/ship` owns that.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-29 — Auto-install the gate on consumer install, guarded (operator chose). Summary: symmetric with Story 3's seeding — `skills-deploy install` from a consumer repo ALSO installs the pre-commit hook, reusing `setup-hooks.sh`'s `install_hook` safety (sentinel-aware; backs up a non-workbench hook; SKIPS a custom `core.hooksPath`/husky with a printed note). PLUS a standalone install/remove command. The workbench self-repo is skipped (it has `validate.sh` — no double-enforcement).
- [decision] 2026-06-29 — `declared-exists` is SOFT; everything else is a hard block. Summary: a freshly-seeded consumer has the contracts but not yet the declared docs, so blocking its next commit on "declared doc missing" would brick adoption. The gate prints `declared-exists` as a REMEDIATION note (pointing at `/CJ_document-release`) and does NOT block on it.
- [decision] 2026-06-29 — The gate is the engine-only (Stage-1) subset of `validate.sh`, not the agent-judged Stage 2/3. Summary: a git hook / CI step can't run an agent, so the gate runs only the deterministic engine checks (`doc-spec.sh --check-on-disk`, `test-spec.sh --validate --check-coverage`, `workflow-spec.sh --validate`, + the `--render-docs --check` freshness checks). Registry-gated throughout (an absent contract is a clean SKIP). Reuses Story 3's stale-engine `--classify` probe in its engine resolution.
- [decision] 2026-06-29 — On this story's land the F000069 epic is COMPLETE (all 4 stories). Summary: both halves of the original ask delivered — the audits are available + seeded + reliable (Stories 1-3) AND enforced in each repo (Story 4). No further deferred stories.
- 2026-06-29 [impl-decision] Chose EXTRACTION over mirror for `install_hook` (SPEC P2 #10 / Open Question 1): created `scripts/cj-hook-lib.sh` as the ONE sourceable home for the clobber-safe installer + the SENTINEL, and refactored `setup-hooks.sh` to source it (its inline `install_hook` is now a thin wrapper). Extraction was low-risk in practice — `setup-hooks.sh`'s existing call sites + the `|| echo WARN >&2` guards are unchanged. `skills-deploy` sources the same lib. A parity check in `scripts/test.sh` asserts `setup-hooks.sh` routes through `cj_install_hook` so the wrapper can never drift back to a stale inline copy.
- 2026-06-29 [impl-decision] Shared-scripts deploy ships the gate AUTOMATICALLY: `skills-deploy`'s shared deposit globs `"$SHARED_SCRIPTS_SRC"/*.sh`, so both `cj-contract-gate.sh` and `cj-hook-lib.sh` land in `_cj-shared` with no allowlist edit (the SPEC's "if it globs scripts/*.sh it's automatic" branch). Verified in the test-deploy S000117a case.
- 2026-06-29 [impl-finding] The gate cannot trust `doc-spec.sh --check-on-disk`'s EXIT code alone for the HARD/SOFT split: the engine exits 1 on ANY finding incl. `declared-exists`. The gate parses the `FINDING: stage1/<id>` lines, counts `declared-exists` as SOFT (a REMEDIATION note) and everything else as HARD — exit non-zero IFF a non-declared-exists finding exists. A repo with ONLY missing declared docs therefore exits 0 (verified by hermetic case A4).
- 2026-06-29 [impl-finding] A genuinely-clean contract fixture is non-trivial: once the doc-spec registry is PRESENT, the engines REQUIRE the generated surface (`docs/test-catalog.md`, `docs/workflow.md`) AND a non-empty `docs/workflows/`. A vacuous workflow-spec renders only the index, leaving `docs/workflows/` empty (fails `workflows-subfolder`). The hermetic test's `mk_clean_contract` therefore declares ONE roster section so the render produces a real `docs/workflows/*.md`. The "declared-exists SOFT" + "registry-absent SKIP" cases are tested separately (delete a declared doc / no contracts) — they are NOT a raw fresh-seed (a fresh seed also trips orphan/workflows-subfolder, which is a Story-3 seed shape, out of this story's scope).
- 2026-06-29 [impl] Wrote 3 NEW files (`scripts/cj-contract-gate.sh`, `scripts/cj-hook-lib.sh`, `tests/cj-contract-gate.test.sh`); modified 7 (`scripts/skills-deploy`, `scripts/setup-hooks.sh`, `scripts/test-deploy.sh`, `scripts/test.sh`, `tests/setup-hooks.test.sh`, `spec/test-spec-custom.md`, `docs/architecture.md`); re-rendered 2 (`docs/test-catalog.md`, `docs/tests/test.md`). Sensitive surfaces (skills-deploy, setup-hooks.sh, test.sh, test-deploy.sh) touched in silent/auto-equivalent mode per the runner role.
- 2026-06-29 [impl-finding] The `install_hook` extraction broke 4 D000022 static-grep assertions in `scripts/test.sh` (they grepped `setup-hooks.sh` for the now-moved safety idioms). Re-anchored all 4 onto `cj-hook-lib.sh` (the new home) + added a parity assertion that `setup-hooks.sh` sources the lib — the D000022 regression intent is preserved, the anchors just follow the code. Full `scripts/test.sh` re-run: Failures: 0, RESULT: PASS.
- 2026-06-29 [impl-pass] S000117: implementation complete. Self-verify: `bash scripts/cj-contract-gate.sh` → exit 0 (clean on this workbench, the validate.sh deterministic subset); `bash scripts/validate.sh` → 0 errors / 0 warnings; `bash scripts/test-spec.sh --validate && --check-coverage` → green (rows=77, findings=0); CI-scope `shellcheck scripts/*.sh scripts/skills-deploy scripts/skills-update-check` → exit 0; `bash tests/cj-contract-gate.test.sh` → RESULT: PASS (9 cases); full `bash scripts/test.sh` → Failures: 0, RESULT: PASS. Phase 2 implementer-owned gates transitioned.
- 2026-06-29 [impl-decision] REVISION (coordinator drill): a FRESHLY-SEEDED consumer (Story-3 seed only) made the gate exit 1 — 3 hard findings (orphan `spec/workflow-spec.md`, missing `docs/workflows/`, missing rendered `docs/test-catalog.md`+`docs/workflow.md`), so auto-installing the gate would BRICK a fresh adopter. Operator decision adopted: keep the gate FULLY HARD (declared-exists stays the ONLY soft — can't auto-author prose docs) and instead make ADOPTION complete the repo. NEW `complete_consumer_adoption` in skills-deploy (consumer-path block, AFTER seed, BEFORE gate-install; also run by `install-contract-gate`): (b) refresh generated surfaces via `test-spec.sh`/`workflow-spec.sh --render-docs`, then (a) auto-declare every orphan the doc-spec engine reports into an auto-marked `spec/doc-spec-custom.md` overlay, `--validate` the merge + roll back if invalid. Idempotent; a hand-authored overlay is left untouched.
- 2026-06-29 [impl-finding] The auto-generated `spec/doc-spec-custom.md` tripped `is_workbench_self_repo`'s overlay signal (it keys on ANY `spec/doc-spec-custom.md` ⇒ "self") — which BLOCKED the gate-hook install on a real consumer. Fixed: signal (2) now EXCLUDES an overlay carrying the `auto-generated by skills-deploy` marker (an adoption artifact, not an authored contract). The workbench's own overlay has no marker ⇒ still correctly self; the data-loss guard is intact (verified: a hand-authored overlay still skips seeding).
- 2026-06-29 [impl-decision] `doc-spec.sh` `workflows-subfolder` check: ADDED an empty-registry tolerance — satisfied when the workflow registry declares ZERO workflows (`spec/workflow-spec.md` absent, or present with no top-level `^kind:` line; self-contained grep, no cross-engine call since this engine is freshness-checked into _cj-shared). A repo that declares a workflow still requires a non-empty `docs/workflows/` (workbench unchanged — 6 `kind:` lines). Updated `tests/doc-spec-overlay.test.sh`: the clean fixture + 8d/8f-2/8f-3 now carry a workflow-declaring `spec/workflow-spec.md` (declared in their overlays) so the mandate stays active, + NEW case 8f-4 asserting the empty-registry tolerance.
- 2026-06-29 [impl] Revision changed 4 files beyond the original set: `scripts/skills-deploy` (complete_consumer_adoption + the self-repo-signal fix + wiring into the consumer-path block & install-contract-gate), `scripts/doc-spec.sh` (workflows-subfolder empty tolerance), `tests/doc-spec-overlay.test.sh` (fixture + 8d/8f-2/8f-3 adjust + 8f-4 new), `tests/cj-contract-gate.test.sh` (NEW case A0: a freshly-ADOPTED consumer is gate-clean), `scripts/test-deploy.sh` (S000117a now asserts adoption surfaces + gate-passes), `docs/architecture.md` + `CLAUDE.md` (adoption-completes-the-repo + fully-hard-except-declared-exists). docs/test-catalog.md + docs/tests/test.md unchanged this pass (no new units row).
- 2026-06-29 [impl-pass] S000117 REVISION complete. THE critical drill: a fresh temp git repo → real consumer adoption (`skills-deploy install` consumer path / `install-contract-gate`) → `cj-contract-gate.sh --repo <repo>` exits **0** (PASS; only declared-exists soft). Plus: gate-on-workbench exit 0; CI-scope shellcheck exit 0; `validate.sh` 0/0; `test-spec.sh --validate && --check-coverage` green; `tests/cj-contract-gate.test.sh` RESULT: PASS (10 cases incl. A0); `tests/doc-spec-overlay.test.sh` PASS (incl. 8f-4 empty tolerance); `scripts/test-deploy.sh` RC=0; full `scripts/test.sh` re-run for final confirmation.
