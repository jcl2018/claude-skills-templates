---
name: "Tighten doc/test audits — generated human catalogs, forced seeding, consumer enforcement"
type: feature
id: "F000069"
status: active
created: "2026-06-28"
updated: "2026-06-28"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
---

<!-- Distilled from the APPROVED /office-hours design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/audit-tightening-design-20260628-200601.md
     This is an EPIC, built in phases. Story 1 (S000114) shipped. Story 2 (S000115)
     shipped (design doc: workflows-gen-design-20260628-225608.md). Story 3 (S000116)
     is scaffolded + buildable this pass (design doc: forced-seeding-design-20260629-010904.md).
     Story 4 remains tracked below as a deferred follow-up. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/audit_tightening_generated_catalogs`
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

<!-- What "done" looks like for the WHOLE epic. Story 1's slice is the only
     buildable portion this pass; epic-level closure spans all four stories. -->

- [ ] **(Story 1)** `scripts/test-spec.sh --render-docs` generates `docs/tests/<family>.md` (one per unit family) + `docs/test-catalog.md` (index) from the merged test-spec registry's rendered fields only — deterministic + work-item-ID-free.
- [ ] **(Story 1)** A `--render-docs --check` mode renders to a temp dir and diffs vs on-disk, exiting non-zero on any mismatch/missing file.
- [ ] **(Story 1)** `scripts/validate.sh` Check 26 is a hard freshness ERROR (regenerate → diff vs on-disk), with the parallel `scripts/test.sh` integration-fixture assertion added in the SAME story.
- [ ] **(Story 1)** The generated `docs/tests/*.md` + `docs/test-catalog.md` are committed; declared as generated human-docs in `spec/doc-spec-custom.md`; the new test units appear in `spec/test-spec-custom.md` (Check 24 reverse-sweep resolves them).
- [ ] **(Story 1)** `/CJ_test_audit` Stage 1 runs the freshness check and Stage 3 recognizes `docs/tests/` as a generated surface (no false orphan finding); `tests/test-spec-render.test.sh` proves stability, ID-freeness, and check pass/fail.
- [ ] **(Story 2 — S000115)** Workflows full symmetric generation (`spec/workflow-spec.md` + `scripts/workflow-spec.sh` + Check 27; Checks 15b/15c retired, folded into `--validate` registry-completeness + Check 27).
- [ ] **(Story 3 — S000116)** Forced (proactive) seeding — three triggers (`skills-deploy seed-contracts` subcommand + install always-seeds-consumer + audits seed-all-3 lazily) calling a shared `do_seed_contracts` routine + the stale-engine-shadow capability probe (the bug fix).
- [ ] **(Deferred — Story 4)** Consumer-repo deterministic Stage-1 enforcement gate (`scripts/cj-contract-gate.sh` + hook/CI install).

## Todos

- [x] Build Story 1 (S000114) through scaffold → implement → qa → doc-sync → audit → ship.
- [x] Build Story 2 (S000115 — workflows full symmetric generation) through scaffold → implement → qa → doc-sync → audit → ship.
- [ ] Build Story 3 (S000116 — forced contract seeding + stale-engine fix) through scaffold → implement → qa → doc-sync → audit → ship.
- [ ] Defer Story 4 to a subsequent build pass (see "Deferred stories (follow-up)" below).

## Active child stories (scaffolded)

- **Story 2 — Workflows full symmetric generation (S000115; design Part 2).** Scaffolded this pass at `S000115_workflows_full_symmetric_generation/` (TRACKER + DESIGN + SPEC + TEST-SPEC). NEW registry `spec/workflow-spec.md` (two entry shapes — orchestrator [the 4 `CJ_goal_*`: chart + 4-axis Touches + "In words"] and roster [the 2 prose docs: verbatim body] + a header block for the index preamble; migrate the 6 existing `docs/workflows/*.md` bodies + the `docs/workflow.md` intro into it). NEW engine `scripts/workflow-spec.sh` (`--validate` [per-kind fields + closed `kind` enum + registry-completeness] `/--list-workflows/--classify/--seed/--render-docs` + `--render-docs --check`). `validate.sh` Check 27 (regenerate→diff freshness) RETIRES hand-authored Checks 15b/15c — their no-vanish intent folded into `--validate` registry-completeness + Check 27. `/CJ_doc_audit` Stage 1 runs workflows-freshness; Stage 3 treats `docs/workflow.md` + `docs/workflows/` as generated. Decided: a one-time normalized reformat (charts/rosters/preamble verbatim, structure may shift), NOT a strict byte round-trip. The heaviest story.
- **Story 3 — Forced contract seeding + stale-engine fix (S000116; design Part 3 / U2).** Scaffolded this pass at `S000116_forced_contract_seeding/` (TRACKER + DESIGN + SPEC + TEST-SPEC). Makes contract seeding FORCED + RELIABLE in any consumer repo. Part 1 (the bug fix): a stale-engine capability probe in BOTH audits' Step-1 engine resolution — after picking the repo-local `scripts/<engine>.sh`, probe it with the side-effect-free `--classify` (current engines emit `GENERATION=`); a stale copy (no `GENERATION=`) is detected, falls back to `_cj-shared`, and emits `stage1/engine-stale` naming the remedy (`skills/CJ_doc_audit/SKILL.md` probes doc-spec + workflow-spec; `skills/CJ_test_audit/SKILL.md` probes test-spec). Part 2 (forced seeding): a shared `do_seed_contracts` routine in `scripts/skills-deploy` (3-contract loop — doc-spec + test-spec + workflow-spec; engine-resolve with the stale probe; corruption-guarded temp→validate→mv; idempotent present-skip; AIRTIGHT workbench-self-repo skip — data-loss guard) called by THREE triggers: (a) a `seed-contracts` subcommand, (b) `install` always-seeds the consumer cwd (forced, git-guarded, self-skip, visible note), (c) `/CJ_doc_audit` Step 2 also lazily seeds `workflow-spec`. NEW hermetic `tests/seed-contracts.test.sh` + `scripts/test-deploy.sh` coverage + `spec/test-spec-custom.md` units rows. The actual fix behind "the audit skills don't force generate the seeding."

## Deferred stories (follow-up)

<!-- Per the phased-scope directive: Story 4 is RECORDED here but NOT
     scaffolded as a buildable dir this pass. It becomes a fully-specified child
     user-story in a subsequent pass (reusing Story 1's generator/freshness/
     audit primitive). Source: the design doc's "Phasing" + Part 4.
     Story 3 (S000116) was moved up into "Active child stories (scaffolded)". -->

- **Story 4 — Consumer-repo deterministic Stage-1 gate (design Part 4 / U3).** NEW `scripts/cj-contract-gate.sh` runs the deterministic-only checks (`doc-spec.sh --check-on-disk`, `test-spec.sh --validate --check-coverage`, `workflow-spec.sh --validate`, + the freshness checks); non-zero on any finding. `setup-hooks.sh`/`skills-deploy` install it as a consumer-repo pre-commit hook (+ documented CI snippet). In the workbench the gate is a subset of `validate.sh`, so no double-enforcement. Cross-machine — verify via a temp-dir adopt drill.

## Log

- 2026-06-28: Created. Tighten doc/test audits via a unified "generated human catalog, freshness-gated, audit-owned" model + forced seeding + a consumer Stage-1 gate. Epic with 4 stories; Story 1 (S000114) is the buildable slice this pass.
- 2026-06-28: Scaffolded Story 2 (S000115 — workflows full symmetric generation) as a child user-story from the APPROVED design doc (workflows-gen-design-20260628-225608.md). Moved Story 2 out of the deferred section into an active scaffolded child; Stories 3+4 remain deferred. Third instance of Story 1's generate→freshness→audit primitive, applied to the workflow docs.
- 2026-06-29: Scaffolded Story 3 (S000116 — forced contract seeding + stale-engine-shadow fix) as a child user-story from the APPROVED design doc (forced-seeding-design-20260629-010904.md). Moved Story 3 out of the deferred section into an active scaffolded child; Story 4 remains deferred. Makes contract seeding forced + reliable in any consumer repo: a stale-engine `--classify` capability probe in both audits (the actual bug fix) + a shared `do_seed_contracts` routine called by three triggers (`seed-contracts` subcommand, consumer install always-seeds, audits seed-all-3 lazily), with an airtight workbench-self-repo skip guarding against data loss.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement.
     Story 1 scope (see S000114_SPEC.md for the full Components Affected): -->

- `scripts/test-spec.sh` — new `--render-docs` (+ `--render-docs --check`) subcommand
- `scripts/validate.sh` — new Check 26 (tests-catalog freshness)
- `scripts/test.sh` — parallel integration-fixture assertion for Check 26
- `docs/test-catalog.md` + `docs/tests/*.md` — NEW generated surfaces (committed)
- `spec/doc-spec-custom.md` — declare the generated docs as human-docs
- `spec/test-spec-custom.md` — units rows for the new test(s)
- `skills/CJ_test_audit/SKILL.md` — Stage 1 freshness; Stage 3 generated-surface recognition
- `tests/test-spec-render.test.sh` — NEW hermetic test

## Insights

<!-- Non-obvious findings worth remembering. -->

- The reusable primitive (spec registry → engine `--render-docs` → generated `docs/` surface → freshness check that regenerates-and-diffs) is already proven once by `README.md` ↔ `generate-readme.sh` ↔ `validate.sh` Check 25. Story 1 builds the SECOND instance of that primitive; Story 2 the third.
- A new `validate.sh` check ALWAYS needs the parallel `scripts/test.sh` zzz-test-scaffold integration-fixture edit — the recurring implement-subagent blind spot (F000032/F000034/F000035 all hit it). Story 1's SPEC pins it as a P0 requirement so it isn't dropped.
- Rendered fields (`label`, `purpose`, `layer`, `disposition`, `trigger`) are already work-item-ID-free by the existing rendered-field lint (`test-spec.sh`), so the generated docs satisfy Check 19 (no work-item IDs in human-docs) by construction — the generator must render ONLY rendered fields, never the `anchor` as a claim.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-28 — EPIC phased into 4 stories; build Story 1 only this pass. Summary: One silent autonomous build cannot deliver all four reliably (design "Epic size" risk). Story 1 establishes the generator/freshness/audit primitive and is fully E2E-testable inside the workbench; Stories 2–4 reuse it.
- [decision] 2026-06-28 — Test catalog is GENERATED + freshness-gated, not hand-authored. Summary: a hand-maintained second copy of registry-derivable content fights the contract's own `single-owner` rule; the generated-view model keeps the `spec/` registry the single source of truth.
- [decision] 2026-06-28 — Story 2 (S000115) scaffolded; workflow docs become a GENERATED surface too. Summary: applies Story 1's generate→freshness→audit primitive to `docs/workflow.md` + `docs/workflows/*.md` via a new `spec/workflow-spec.md` registry + `scripts/workflow-spec.sh` engine + `validate.sh` Check 27; the shape-only Checks 15b/15c retire, their no-vanish intent folded into `--validate` registry-completeness (stronger than an index-link grep) + Check 27 freshness. Operator chose full symmetry (all 6 docs + index, two entry shapes) + a one-time normalized reformat over a strict byte round-trip.
- [decision] 2026-06-29 — Story 3 (S000116) scaffolded; seeding made forced + reliable, with the stale-engine shadow fixed. Summary: the actual bug behind "the audit skills don't force generate the seeding" is a stale repo-local engine shadowing `_cj-shared` and silently no-oping the seed step. The fix is a side-effect-free `--classify` capability probe in both audits' Step-1 resolution (stale ⇒ fall back to `_cj-shared` + emit `stage1/engine-stale`). The operator chose the MAXIMAL/forced seeding combination — three triggers (a `seed-contracts` subcommand, `install` always-seeds the consumer cwd, and the audits seed-all-3 lazily) all calling one shared `do_seed_contracts` routine — with an AIRTIGHT workbench-self-repo skip (manifest `source == toplevel` AND/OR canonical-contract presence) so the workbench's real `spec/*.md` can never be clobbered with skeletons (data-loss guard).
