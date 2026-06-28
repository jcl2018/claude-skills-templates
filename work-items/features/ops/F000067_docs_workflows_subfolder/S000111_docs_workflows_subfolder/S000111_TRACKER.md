---
name: "docs/workflows/ subfolder — full split + contract/engine/validator/test/prose changes"
type: user-story
id: "S000111"
status: active
created: "2026-06-27"
updated: "2026-06-27"
parent: "F000067"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "2a636745793c671832b2c42f3dc826740f119959"
    completed_at: "2026-06-27T21:48:06Z"
    test_rows_run: 9
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-smoke-summary] green 5/5", "[qa-e2e] E1/E2/E3/E4 green", "[qa-e2e] E5 deferred (DEFER_AUDIT)", "[qa-e2e-summary] green", "[qa-audit] AUDITS=deferred", "[qa-pass]"]
    ready_for_ship: true
    next_legal: ["Ship"]
---

<!-- Atomic story: derives directly from the parent feature's /office-hours session.
     See parent F000067_DESIGN.md for the full design context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/docs_workflows_subfolder` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (N/A — atomic story; one cohesive reorganize + contract-teach change)

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

- [ ] Six `docs/workflows/*.md` files created with verbatim-moved content; `docs/workflow.md` reduced to a ~80–120-line pure index linking all six.
- [ ] Portable seed (3-way: `spec/doc-spec.md` + `templates/doc-spec-common.md` + `doc-spec.sh --seed` heredoc) edited byte-identically: reworded `docs/workflow.md` Requirement + the `docs/workflows/` mandate prose.
- [ ] `doc-spec.sh --check-on-disk` adds the `workflows-subfolder` check + recurses `docs/` for orphans; `--list-human-docs` surfaces the subfolder files; registry-absent ⇒ exit 0.
- [ ] `spec/doc-spec-custom.md` declares the 6 new `docs/workflows/*.md` overlay rows.
- [ ] `validate.sh` Check 15a recurses, Check 15b retargets to `docs/workflows/<name>.md`, new Check 15c verifies the index links each orchestrator file.
- [ ] `spec/test-spec-custom.md` units rows + tests updated (`doc-spec-overlay`, `cj-document-release-config` no-drift, `test.sh` zzz-test-scaffold fixture); `validate.sh` + `test.sh` green.

## Todos

<!-- Actionable items for this story. -->

- [x] Move the six sections verbatim into `docs/workflows/*.md`; reduce `workflow.md` to the index.
- [x] Edit the 3-way seed byte-identically (Requirement reword + mandate prose).
- [x] Add the `workflows-subfolder` engine check + orphan-scan recursion + `--list-human-docs` fix in `doc-spec.sh`.
- [x] Add the 6 overlay rows to `spec/doc-spec-custom.md`.
- [x] `validate.sh`: Check 15a recursion, Check 15b retarget, new Check 15c.
- [x] `spec/test-spec-custom.md` units rows; updated `tests/doc-spec-overlay.test.sh` + `tests/cj-document-release.test.sh` (NOT `cj-document-release-config.test.sh` — its seed no-drift test passes unchanged since the 3-way seed stays byte-identical). The `scripts/test.sh` integration runs validate.sh against the live tree (now green); the T000040 Touches smoke block was retargeted to `docs/workflows/<name>.md`.
- [x] Sync prose (`CLAUDE.md`, `docs/architecture.md`, `docs/philosophy.md`, `templates/doc-WORKFLOWS-section.md`).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-27: Created. Atomic story carrying the full docs/workflows/ split + the portable doc-contract mandate.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

Changed in this implementation:

- NEW `docs/workflows/{CJ_goal_feature,CJ_goal_task,CJ_goal_defect,CJ_goal_todo_fix,utilities-and-phase-steps,utility-audits}.md` (verbatim-moved sections + the necessary cross-file link retargets)
- modified `docs/workflow.md` (reduced to a 64-line pure index linking the 6 files)
- modified `spec/doc-spec.md`, `templates/doc-spec-common.md`, `scripts/doc-spec.sh` (3-way byte-identical seed: Requirement reword + `docs/workflows/` mandate prose; engine: recursed `docs/` orphan scan + new `workflows-subfolder` check)
- modified `spec/doc-spec-custom.md` (+6 `docs/workflows/*.md` overlay rows + the custom-tier prose)
- modified `scripts/validate.sh` (Check 15a recursion, Check 15b retarget to `docs/workflows/<name>.md`, new Check 15c no-vanish guard, orphan-doc-dir carve-out for `docs/workflows/`)
- modified `spec/test-spec-custom.md` (Check-15 unit row purpose + doc-spec-overlay unit row purpose)
- modified `tests/doc-spec-overlay.test.sh` (5-check battery + the 3 new F000067 violation drills), `tests/cj-document-release.test.sh` (retargeted to `docs/workflows/utilities-and-phase-steps.md`), `scripts/test.sh` (T000040 Touches smoke block retargeted to `docs/workflows/<name>.md`)
- modified `CLAUDE.md`, `docs/architecture.md`, `docs/philosophy.md`, `templates/doc-WORKFLOWS-section.md` (prose sync to the two-level model)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The mandate lives in the **engine** (`doc-spec.sh --check-on-disk`), not just the overlay — that is what makes it portable + uniform across adopting repos.
- Registry-gating (`REGISTRY=absent` ⇒ exit 0) is the carve-out that keeps the mandate from firing on an unrelated repo.
- `--expand-whitelist` already recurses `find docs`; `--list-human-docs` may be maxdepth-limited and needs verifying after the move.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-27 — Atomic story (no task children). Summary: the whole change is one cohesive reorganize-plus-teach-the-contract unit; recorded the choice with the Phase 1 gate `Tasks broken down (N/A — atomic story)`.
- 2026-06-27 [impl-decision] Implemented Approach C (bake the mandate into the portable seed) with a HARD mandate + a FULL split, per the APPROVED design doc + the SPEC Tradeoffs table (Chosen column). The new `workflows-subfolder` engine check is registry-gated (it only runs from `_check_on_disk`, which the `--check-on-disk` arm calls AFTER the registry-absent probe returns early) so it never fires on a non-adopting repo — verified by a temp-dir drill.
- 2026-06-27 [impl-decision] Content move is verbatim EXCEPT for the necessary cross-file link retargets that the move forces: the 3 orchestrator files' `[How the machinery works](#how-the-machinery-works)` → `utilities-and-phase-steps.md#...`; `utilities-and-phase-steps.md`'s sibling-doc links → `../philosophy.md` / `../architecture.md` (now one level deeper) + the "just below" cross-ref → a link to `utility-audits.md`. A broken intra-doc anchor would be a real regression; these are link-target correctness fixes, not prose rewrites. Verified each moved section is otherwise byte-identical to `git HEAD:docs/workflow.md`.
- 2026-06-27 [impl-finding] The `scripts/test.sh` zzz-test-scaffold integration block runs `validate.sh` against the LIVE tree (it does NOT build a synthetic `docs/` tree), so once the live repo's `docs/workflows/` + the retargeted Check 15a/15b/15c are green, the fixture passes automatically. The real parallel-edit the new checks needed was (a) the standalone T000040 Touches smoke block (retargeted to `docs/workflows/<name>.md`) and (b) `tests/cj-document-release.test.sh` (retargeted `WORKFLOWS_DOC` to `docs/workflows/utilities-and-phase-steps.md`). Both were forgotten-blind-spot candidates; caught + fixed.
- 2026-06-27 [impl-finding] The split added a new `docs/workflows/` subdir, which validate.sh's "orphan doc directory" Warning check (assumes every `docs/<subdir>/` is a per-skill doc dir) flagged. Added a carve-out skipping `workflows/` (it is a contract-mandated subfolder whose files are declared human-docs). The `cj-document-release-config.test.sh` seed no-drift test was NOT touched — the 3-way seed stays byte-identical, so it passes unchanged.
- 2026-06-27 [impl] Wrote 6 new files (`docs/workflows/*.md`); modified 14 (`docs/workflow.md`, the 3-way seed trio, `spec/doc-spec-custom.md`, `scripts/validate.sh`, `scripts/test.sh`, `spec/test-spec-custom.md`, 2 test files, 4 prose docs). 3-way seed byte-identity verified; `validate.sh` 0 errors/0 warnings; full `scripts/test.sh` suite GREEN (0 failures); `doc-spec.sh --check-on-disk` 5 checks PASS; registry-absent skip + E3 no-vanish + E4 orphan drills all verified.
- 2026-06-27 [impl-auto] Auto-mode run (orchestrator-dispatched, no AUQ surface). The change touches sensitive surfaces (`validate.sh`, `test.sh`) + >2 files, so a standalone run would have demoted `--auto` to propose-mode and AUQ'd; in this orchestrated leaf-subagent context the parent owns the gate.
- 2026-06-27 [impl-pass] S000111: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-27 [qa-smoke] S1 (AC-2): green — seed 3-way byte-identity test passes (tests/cj-document-release-config.test.sh exit 0; no-drift heredoc==templates/doc-spec-common.md).
- 2026-06-27 [qa-smoke] S2 (AC-3): green — doc-spec.sh --check-on-disk reports `workflows-subfolder — PASS`, recursed orphan scan clean (CHECKS_RUN=5, FINDINGS=0, exit 0).
- 2026-06-27 [qa-smoke] S3 (AC-4): green — doc-spec-overlay.test.sh exit 0; registry-absent drill reports REGISTRY=absent + exit 0 (mandate does not fire) plus all 3 F000067 violation drills (recursed-orphan, registry-gated-missing-subfolder, empty-subfolder) flip the right stage1 finding.
- 2026-06-27 [qa-smoke] S4 (AC-5): green — validate.sh PASS (0 errors / 0 warnings); Check 15a recursion, Check 15b retarget to docs/workflows/<name>.md, new Check 15c index-links-each-orchestrator, Check 16/17/19/24 all PASS.
- 2026-06-27 [qa-smoke] S5 (AC-6): green — full scripts/test.sh suite PASS (Failures: 0), incl. the zzz-test-scaffold integration fixture and the new engine-check coverage; tree restored clean by test.sh trap.
- 2026-06-27 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-27 [qa-e2e-run-start] RUN_ID=20260627-144431-51179 commit=2a63674
- 2026-06-27 [qa-e2e] E1 (AC-1): green — all 6 moved sections appear verbatim in their new docs/workflows/*.md files (utility-audits.md 0/156 lines changed; the only deltas are the documented forced cross-file link retargets: the in-doc `[How the machinery works](#...)` anchor → `utilities-and-phase-steps.md#how-the-machinery-works` in the 3 orchestrator files, and `philosophy.md`/`architecture.md` sibling links → `../` plus the "just below" cross-ref → `utility-audits.md` in utilities-and-phase-steps.md). All retargets verified landed; no prose dropped. [parent-inline]
- 2026-06-27 [qa-e2e] E2 (AC-1): green — docs/workflow.md is a pure index linking all 6 docs/workflows/*.md files (incl. all four CJ_goal_* orchestrators) with no deep detail inline. Line count 64 (under the ~80–120 soft band; per the TEST-SPEC Coverage Gaps table this band is an explicit soft target — reviewer judgment, not a hard gate; the no-vanish Check 15c + content-preservation E1 are the real guards and both pass). [parent-inline]
- 2026-06-27 [qa-e2e] E3 (AC-5): green — no-vanish drill: removed the CJ_goal_defect index link → validate.sh Check 15c ERRORed `docs/workflow.md index does not link workflows/CJ_goal_defect.md (no-vanish: the overview must name every CJ_goal_* workflow)` (RESULT: FAIL, exit 1); restored byte-identically → validate.sh PASS (0 errors). [parent-inline]
- 2026-06-27 [qa-e2e] E4 (AC-3): green — orphan drill: added undeclared docs/workflows/zzz_tmp.md → doc-spec.sh --check-on-disk emitted `FINDING: stage1/orphans — undeclared docs *.md on disk (orphan): docs/workflows/zzz_tmp.md` (FINDINGS=1, exit 1; recursed scan reaches the subfolder); removed it → 5 PASS / FINDINGS=0 / exit 0. [parent-inline]
- 2026-06-27 [qa-e2e] E5 (AC-6): ambiguous — post-sync three-stage /CJ_doc_audit + /CJ_test_audit DEFERRED via DEFER_AUDIT (orchestrator runs them at the authoritative post-sync point after /CJ_document-release). The deterministic declared-coverage precondition E5 rides on is already green (S2/S4: declared-exists + orphans + workflows-subfolder checks all PASS ⇒ every docs/workflows/*.md is declared; test-spec coverage cross-check clean rows=69). Full audit verdict belongs to the orchestrator's post-sync run. [parent-inline]
- 2026-06-27 [qa-e2e-summary] green (0s subagent; 5 rows parent-inline; 0 deferred): E1/E2/E3/E4 green; E5 audit-row DEFERRED to the orchestrator's post-sync audit per DEFER_AUDIT (its deterministic declared-coverage precondition is green). E2E_VERDICT=green (E5's deferred three-stage audit is the orchestrator's gate, not a pre-ship red).
- 2026-06-27 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a/8.6b ran inline — both overlays already in sync from implementation: 6 docs/workflows/*.md rows declared in doc-spec-custom, 2 unit-row purposes amended + anchors resolve in test-spec-custom, --validate + --check-coverage green; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync three-stage doc/test audit)
- 2026-06-27 [qa-pass] S000111 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
