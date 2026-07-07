---
name: "Vendor the gate + drop the CI workflow"
type: user-story
id: "S000138"
status: active
created: "2026-07-07"
updated: "2026-07-07"
parent: "F000089"
repo: "E:/projects/claude-skills-templates"
branch: "claude/consumer-contract-adopt"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/consumer_contract_adopt_vendored_gate` (or use parent's branch if shipping in same PR)
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

<!-- What "done" looks like for this story. -->

- [x] `install-contract-gate` (consumer path) vendors `cj-contract-gate.sh` + `doc-spec.sh` + `test-spec.sh` + `workflow-spec.sh` into `<consumer>/.cj-contract/`, each with a stamped version header, LF-normalized + `chmod +x`; overwrite by default (sync).
- [x] `install-contract-gate` drops `<consumer>/.github/workflows/cj-contract-gate.yml` (from an embedded `ci_workflow_body` template) that checks out, installs jq, and runs `bash .cj-contract/cj-contract-gate.sh --repo .`; it does NOT clobber a differing hand-authored workflow of that name (sentinel-gated skip-with-note).
- [x] `--remove` removes `.cj-contract/` + the dropped workflow (only if sentinel-marked / unmodified), symmetric with the hook removal.
- [x] The workbench self-repo is skipped for the vendor + CI-template drop (as it already is for seeding/adoption).
- [x] The vendored `.cj-contract/cj-contract-gate.sh --repo .` runs green / red / SKIP correctly with NO `~/.claude/_cj-shared` present. **Verified independently:** on a bare runner (`HOME` + `CJ_SHARED_SCRIPTS` → empty dirs), exit 0 on a clean seeded contract (skips=0 — engines resolved from `.cj-contract/`), exit 1 on a planted undeclared orphan (`FINDING: stage1/orphans → VERDICT: BLOCK`). Requires the contract be seeded — see the one-command-seeding fix in the journal.
- [x] `docs/adopting-the-contract.md` is written, declared in `spec/doc-spec-custom.md`, and carries no work-item IDs; catalogs regenerated.
- [x] `test-deploy.sh` gains a case (S000138) covering vendor + drop + gate-runs-green/red (bare-runner) + remove + hand-authored-protection + self-repo-skip — GREEN (full `test-deploy.sh` "All tests passed").

## Todos

<!-- Actionable items for this story. -->

- [x] Add the CI-workflow template (embedded heredoc `ci_workflow_body`) + the vendor + drop logic to `install-contract-gate` in `scripts/skills-deploy` (consumer-only, self-repo-skip, `--remove` symmetric).
- [x] Write `docs/adopting-the-contract.md`; declare it in `spec/doc-spec-custom.md`; regenerate catalogs.
- [x] Extend `scripts/test-deploy.sh` with the vendor/drop/gate-runs/remove/self-skip case (inside the existing `test-deploy` unit — no new `tests/*.test.sh`, so no new `units:` row / front-door doc needed).
- [x] Verify: test-deploy S000138 case green, doc-spec/test-spec engines green, seed identity, shellcheck; the bare-runner gate proof (no `_cj-shared`) green-on-clean / non-zero-on-planted-violation.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-07: Created. Extend `install-contract-gate` to vendor the 4 gate engines into `.cj-contract/` + drop a CI workflow that runs the vendored gate; add the one-command-adopt doc + a test-deploy case.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/skills-deploy` — modified: added `vendor_gate_engines` / `drop_ci_workflow` / `remove_vendored_gate` / `ci_workflow_body` / `cj_vendor_version` / `cj_vendor_source_dir` helpers + the vendor-sentinel/dir constants; wired vendor+drop into `do_install_contract_gate` (install branch + `--remove`) and the consumer-path `install` block; updated usage text. CI-workflow template lives as the embedded `ci_workflow_body` heredoc (mirrors `gate_hook_body` — no new tracked file, no new validate guard).
- `scripts/cj-contract-gate.sh` — modified: `resolve_engine` own-dir last resort now accepts a READABLE (`-r`) co-located sibling, not just `-x`. Engines are always invoked via `bash`, and on Windows Git-Bash copy-mode `chmod +x` on a freshly-written file is a no-op, so a vendored engine lands 644 — requiring `-x` would break the bare-runner path on Windows.
- `docs/adopting-the-contract.md` — new declared human-doc (the one-command-adopt guide; no work-item IDs).
- `spec/doc-spec-custom.md` — modified: declare `docs/adopting-the-contract.md` as a human-doc row.
- `scripts/test-deploy.sh` — modified: new `Test S000138` case (vendor + stamp + drop + bare-runner green/red + `--remove` symmetric + hand-authored-workflow protection + workbench-self skip); platform-aware exec-bit assertion (asserts `-x` where chmod sticks, `-r` on Windows copy-mode).

## Insights

<!-- Non-obvious findings worth remembering. -->

- The gate resolves engines from its own dir (`BASH_SOURCE` dirname) as last resort, so co-locating the 4 scripts in one `.cj-contract/` dir makes the gate self-contained on a bare CI runner — no `~/.claude` needed.
- test-deploy is CI-nightly per F000075 — acceptable for a deploy-harness feature; add a fast `windows-smoke.sh` assertion only if cheap.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-07: Ship as a single atomic story — the change set is one cohesive extension of one entry point (`install-contract-gate`) plus its doc + test; no parallel sub-units warranting task children.
- [impl-decision] 2026-07-07: CI template lives as an embedded heredoc (`ci_workflow_body`) mirroring `gate_hook_body`, NOT a tracked `templates/cj-contract-gate.yml` — consistent with the existing pre-commit-hook idiom and avoids a needless new `validate.sh` expected-file guard (per the SPEC Tradeoffs "Where the CI template lives" row + the resolved Open Question).
- [impl-finding] 2026-07-07: The bare-runner proof exposed a real Windows portability bug — on Git-Bash copy-mode `chmod +x` on a freshly-written (redirect-created 644) file is a NO-OP (`touch x; chmod +x x` leaves it 644), while `cp` from an executable source preserves the bit. The vendor writes via `{ echo header; tr < src; } > out` (a redirect), so the vendored engines land 644 on Windows and the gate's `resolve_engine` `[ -x "$self_local" ]` last resort could not find them (→ "engine absent" SKIP, defeating the whole purpose). Fixed at the gate: the own-dir last resort now accepts `-r` (engines are always run via `bash`, so `-x` is never needed for a co-located sibling). The vendor keeps its `chmod +x` (beneficial on POSIX, harmless on Windows).
- [impl-finding] 2026-07-07: Standalone `install-contract-gate` completes adoption + vendors but does NOT seed the contracts (seeding is the `install`/`seed-contracts` path). The test-deploy S000138 case therefore `seed-contracts` first, so the bare-runner clean/red proof has a real contract; the planted RED violation is an undeclared orphan `docs/orphan.md` (a HARD doc-spec orphan finding).
- [impl] 2026-07-07: Modified scripts/skills-deploy (vendor/drop/remove helpers + heredoc + wiring + usage), scripts/cj-contract-gate.sh (readable own-dir resolution), scripts/test-deploy.sh (S000138 case); wrote docs/adopting-the-contract.md; declared it in spec/doc-spec-custom.md; regenerated the test + workflow catalogs (no diff). 3 scripts modified, 1 doc new, 1 overlay + tracker edited.
- [impl-pass] S000138: implementation complete. Phase 2 implementer-owned gates transitioned. Self-checks green: shellcheck (3 scripts), doc-spec --validate + --check-on-disk FINDINGS=0, test-spec --validate + --check-coverage findings=0 + --render-docs --check + workflow-spec --render-docs --check in sync, seed byte-identical, no work-item IDs in the new doc, and the isolated test-deploy S000138 case passes (incl. the bare-runner green-on-clean / non-zero-on-planted-violation proof).

- 2026-07-07 [orchestrator-fix] DEFECT found by the orchestrator's independent bare-runner reproduction (the subagent's test-deploy case had MASKED it by pre-seeding via `seed-contracts`, with a comment admitting "install-contract-gate ... does NOT seed"): the DOCUMENTED one-command adopt (`install-contract-gate`, per docs/adopting-the-contract.md step 1 "Seeds the contracts") did NOT seed — `do_install_contract_gate` called `complete_consumer_adoption` only when a `spec/` registry ALREADY existed, so a fresh consumer got a vendored-but-INERT gate (every check `REGISTRY=absent`-SKIP → vacuous PASS → drift never caught). FIX: added an idempotent, self-repo-skipped `do_seed_contracts --repo "$target"` step to `do_install_contract_gate`'s install branch BEFORE adoption, so one command genuinely seeds → adopts → vendors → drops → hooks (matching the doc). Also TIGHTENED the test-deploy S000138 case: removed its `seed-contracts` pre-step + added an assertion that `install-contract-gate` alone seeds `spec/test-spec.md` — so the test now guards the one-command-seeds promise (a regression would red it).
- 2026-07-07 [qa-smoke] BARE-RUNNER PROOF (re-run by the orchestrator after the fix): `install-contract-gate` on a bare `git init` scratch repo seeds (doc/test/workflow) + adopts (declared 4 docs) + vendors 4 engines into `.cj-contract/` + drops the CI workflow + installs the hook; then `env HOME=<empty> CJ_SHARED_SCRIPTS=<empty> bash .cj-contract/cj-contract-gate.sh --repo .` → exit 0 (skips=0) on the clean seeded contract, exit 1 on a planted undeclared `docs/orphan.md` (`FINDING: stage1/orphans → VERDICT: BLOCK`). Engines resolved from the co-located `.cj-contract/` dir with NO `~/.claude`.
- 2026-07-07 [qa-smoke] `scripts/test-deploy.sh` ran to completion → "All tests passed" incl. the tightened S000138 case (vendor+stamp+drop+bare-runner green/red+remove+hand-authored-protection+self-skip). `doc-spec.sh --validate`+`--check-on-disk` FINDINGS=0 (adopting doc declared/present/ID-free); `test-spec.sh --validate`/`--check-coverage`/`--render-docs --check` green; `workflow-spec --render-docs --check` in sync; seed byte-identity IDENTICAL; shellcheck clean (skills-deploy, test-deploy.sh, cj-contract-gate.sh). The `cj-contract-gate.sh` own-dir resolution `[ -x ]→[ -r ]` change is scoped to the last-resort tier only (repo-local + shared stay `-x`); inert for the workbench. Full `scripts/test.sh` deferred to CI.
- 2026-07-07 [qa-pass] S000138: QA GREEN. Phase 2 QA-owned gates transitioned; all 7 acceptance criteria met. E2E rows are manual consumer-adopt scenarios (proven via the orchestrator's scratch-repo reproduction). Ready for pre-doc-sync commit + /ship.
