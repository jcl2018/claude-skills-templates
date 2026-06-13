---
name: "Three-stage audit hardening — engine-backed Stage 1 (doc-spec.sh --check-on-disk), evidence-forced Stage 2, drift-hunting Stage 3, fresh-context judging, per-stage findings reports"
type: feature
id: "F000061"
status: active
created: "2026-06-12"
updated: "2026-06-12"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/unruffled-kalam-e25974"
branch: "claude/unruffled-kalam-e25974"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/three_stage_audit_hardening`
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

- [ ] **Stage-1 engine:** `bash scripts/doc-spec.sh --check-on-disk` on the clean workbench prints every check line PASS, `FINDINGS=0`, exit 0. Each of the seven seeded violations in the test battery flips exactly its own `FINDING: stage1/<id>` line + exit 1. Registry-absent ⇒ `REGISTRY=absent` + exit 0 (the probe-before-gates carve-out); present-but-invalid ⇒ `[doc-sync-no-config]` + exit 1.
- [ ] **Per-stage reports, both skills:** `/CJ_doc_audit` standalone on the workbench emits `STAGE1/2/3_FINDINGS=` + the three `--- stage N ---` sections, with Stages 2+3 produced by ONE dispatched fresh-context subagent, and `DOC_AUDIT: ok` only when all three counts are 0. Same for `/CJ_test_audit` with `UNITS_AUDITED=`.
- [ ] **Evidence-forced judging:** Stage 2 verdict lines each quote a clause + cite the decisive evidence (spot-checkable); the retired `up-to-date`/`stale:` wording appears nowhere; Stage 3 opens with the ground-truth enumeration line and each drift finding names the delta.
- [ ] **Drift-hunting proven:** a deliberately planted drift (temp fixture repo whose workflow doc omits a catalog skill) produces a `FINDING: stage3/...` naming the missing skill — asserted in the extended `tests/cj-audit-skills.test.sh` battery.
- [ ] **QA surface refined, pipelines untouched:** qa.md's AUDIT_FINDINGS template carries the per-stage shape; the four cj_goal pipelines need ZERO edits (verified by grep — they print the block verbatim).
- [ ] `./scripts/validate.sh` PASS (validate.sh itself untouched — D11; Check 24 green with the two suites' updated purpose text in `spec/test-spec-custom.md`); `./scripts/test.sh` PASS; both audits run green end-to-end on the workbench (FINDINGS=0 at all three stages, or honest findings fixed before ship).
- [ ] **Docs + catalog current:** both skills' catalog descriptions + `doc_requirement` strings name the three-stage contract; both `allowed-tools`/`depends.tools` carry `Agent`; USAGE.md files current; `docs/architecture.md`'s stale "future `--check-on-disk` … deferred" passage (~L285–296) describes the shipped subcommand; TODOS row for validate.sh convergence added; the registered-doc audit on this run's own QA passes.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000103: full build — `doc-spec.sh --check-on-disk` (6 checks: declared-exists / orphans / root-declared / human-doc-ids / front-table / views-render; subcommand-local registry-absent probe BEFORE the parse gates; orphans counts a non-self-declaring overlay as an orphan; all loops `while IFS= read -r`; env overrides for hermetic temp-dir tests), BOTH skills' three-stage restructure (Stage 1 = one engine call; Stage 2 clause-by-clause evidence-cited verdicts with the `satisfies` / `missing-requirement (soft)` / `n/a` / `FINDING: stage2/<path>` grammar; Stage 3 ground-truth enumeration + doc-type cross-walk playbook), the REQUIRED fresh-context subagent dispatch standalone (+ `Agent` in both skills' allowed-tools + catalog depends.tools; in-QA inline degradation documented), the per-stage report contract (`STAGE1/2/3_FINDINGS=` + three sections + `stageN/` prefixes; pre-stage findings count as STAGE1; skipped-stage grammar), qa.md AUDIT_FINDINGS per-stage template (pipelines: ZERO edits), the docs sweep (workflow.md, CLAUDE.md, architecture.md ~L285–296, catalog descriptions/doc_requirement, USAGE.mds), the TODOS convergence row, and the two extended test suites + their updated purpose text in `spec/test-spec-custom.md` (no new suites)
- [ ] Coordinate: no tree mutations while `scripts/test.sh` runs (its EXIT restore-trap clobbers concurrent edits)
- [ ] Coordinate: the modified `doc-spec.sh` passes the stricter apt shellcheck in CI (SC2015/SC2016 class), not just local 0.11
- [ ] Coordinate: SKILL.md edits to both audit skills trigger Check 14 USAGE.md drift — update USAGE.mds with real content in the same PR (normal path), not timestamp overrides
- [ ] Post-land assignment: re-run the dogfood — `/CJ_doc_audit` standalone — confirming (a) Stage 1 is a single engine call, (b) Stage 2/3 sections arrive from the dispatched subagent with cited evidence, (c) per-stage counts render; then plant a one-line drift in a scratch worktree and confirm Stage 3 names it

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-12: Created. Three-stage audit hardening: F000060's audit skills get an engine-backed Stage 1 (NEW `doc-spec.sh --check-on-disk` — the word-split defect class designed out, consumer repos gain a real CI-able conformance check), an evidence-forced Stage 2 (clause-by-clause verdicts against the quoted `requirement:`, citing decisive evidence), a NEW Stage 3 implementation-drift cross-walk (ground truth first, judgment second), REQUIRED fresh-context subagent judging for Stages 2+3 standalone (inline inside QA — the nested-subagent wall), and per-stage findings reports (`STAGE1/2/3_FINDINGS=` + grep-able `stageN/` prefixes) in BOTH `/CJ_doc_audit` and `/CJ_test_audit` symmetrically. validate.sh untouched (D11).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- scripts/doc-spec.sh (modified — NEW `--check-on-disk` subcommand: 6 deterministic checks against the MERGED registry, one line per check + `CHECKS_RUN=`/`FINDINGS=` tail, registry-absent probe before the parse gates, `while IFS= read -r` loops, env overrides)
- skills/CJ_doc_audit/SKILL.md + USAGE.md (modified — three named stages, fresh-context dispatch posture, per-stage report, pre-stage/skipped-stage error grammar)
- skills/CJ_test_audit/SKILL.md + USAGE.md (modified — symmetric three-stage shape, D10.3)
- skills-catalog.json (modified — both audit entries: descriptions + `doc_requirement` name the three-stage contract; `depends.tools` + frontmatter `allowed-tools` gain `Agent`), README.md (regenerated)
- skills/CJ_qa-work-item/qa.md (modified — AUDIT_FINDINGS block template adopts the per-stage shape; Step 8.6 mechanics otherwise unchanged)
- docs/workflow.md, docs/architecture.md (~L285–296 stale "deferred" passage rewritten), CLAUDE.md (modified — audit-internals mentions refreshed)
- TODOS.md (modified — new row: converge validate.sh Checks 15/17/19/20 onto `--check-on-disk`, Approach B deferred)
- spec/test-spec-custom.md (modified — the two extended suites' purpose text updated; anchors unchanged)
- tests/doc-spec-overlay.test.sh (extended — `--check-on-disk` battery: clean + 7 seeded violations + registry-absent + invalid-registry)
- tests/cj-audit-skills.test.sh (extended — per-stage report shape + planted-drift stage3 drill)
- NOT touched by design: scripts/validate.sh (D11), scripts/test-spec.sh (grows NONE), the seeds (no schema change), the four cj_goal pipelines (print the block verbatim), scripts/test.sh runner blocks (both suites already wired)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The dogfood run's word-split incident (two phantom findings + one silently VACUOUS check hours after F000060 landed) is a REAL defect class of prose-described bash: every executor re-derives the loops and each derivation can rot differently. Moving the loops into ONE tested engine (`--check-on-disk`) designs the class out — the lesson lives inside a script where it can never be re-derived wrong.
- Resident-context rubber-stamping is the Stage-2 bias: "the build just updated these docs" verdicts from the invoking session's own beliefs. Fresh-context dispatch (the subagent prompt carries ONLY repo root + engine path + Stage-1 report + the protocols — explicitly NOT the session's beliefs) is what makes the verdicts earned.
- Pre-stage failures keep the stage grammar: engine-unreachable / seed-failure / registry-invalid findings are deterministic, so they count toward `STAGE1_FINDINGS` (prefixes `stage1/engine`, `stage1/seed`, `stage1/registry`), and unjudgeable later stages still print their section header with one `skipped: <reason>` line + `STAGE*_FINDINGS=0` — the report shape never collapses on the error path.
- `views-render` compares TABLE BLOCKS, not whole files: view headers legitimately differ between workbench (generator header) and consumer (portable stub header); the whole-file regen-diff remains Check 23 (workbench CI), unchanged.
- The `orphans` check deliberately counts a non-self-declaring overlay file as an orphan — an overlay MUST self-declare (the workbench's does); the finding is honest guidance for a consumer repo, not a false positive to carve out.
- Three operator instincts shaped the design: stages map exactly onto the deterministic/judged boundary the system already had (design along existing fault lines); the fresh-context ask came from spotting the rubber-stamp risk in one audit run; and D10.3 chose symmetry over the smaller doc-only diff — one format, fully enforced.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-12 [decision] D10.1 — Stage 1 becomes an engine call: NEW `doc-spec.sh --check-on-disk` subcommand (the only subcommand added; `test-spec.sh` grows NONE — its Stage 1 is already engine calls). The word-split bug class is designed out and consumer repos gain a CI-able conformance check, closing the deferred follow-up already on record.
- 2026-06-12 [decision] D10.2 — standalone runs MUST dispatch Stages 2+3 to ONE fresh-context general-purpose subagent (REQUIRED, not optional); in-QA (Step 8.6c/d, already a subagent) the QA agent executes both stages inline per the same protocols — both SKILL.mds state the degradation honestly.
- 2026-06-12 [decision] D10.3 — BOTH audits get the identical three-stage shape + per-stage report in this PR (operator chose symmetry over the smaller doc-only diff).
- 2026-06-12 [decision] D11 — Approach A: skill-layer hardening only; validate.sh untouched (Checks 15/17/19/20 keep their own implementations); convergence onto `--check-on-disk` is a tracked TODOS row, not part of this diff.
- 2026-06-13T01:45:18Z [feature-pr-opened] F000061 v6.0.66 PR #262
  pr_url=https://github.com/jcl2018/claude-skills-templates/pull/262
