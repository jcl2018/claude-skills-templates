---
name: "gate-spec.md contract — the doc-spec mirror for gates"
type: user-story
id: "S000096"
status: active
created: "2026-06-07"
updated: "2026-06-07"
parent: "F000054"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/priceless-grothendieck-367489"
branch: "claude/priceless-grothendieck-367489"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "0293a2e101a30e2b8f2f9d158c8657285a7825fa"
    completed_at: "2026-06-07T18:40:19Z"
    test_rows_run: 9
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries:
      - "[qa-smoke] S1 (AC-2): green"
      - "[qa-smoke] S2 (AC-2): green"
      - "[qa-smoke] S3 (AC-3): green"
      - "[qa-smoke] S4 (AC-3): green"
      - "[qa-smoke] S5 (AC-3): green"
      - "[qa-e2e] E1 (AC-1): green"
      - "[qa-e2e] E2 (AC-3): green"
      - "[qa-e2e] E3 (AC-2): green"
      - "[qa-e2e] E4 (AC-4): green"
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/gate_spec_contract` (or use parent's branch if shipping in same PR)
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

- [x] AC1: `gate-spec.md` exists at root — a `doc-spec.md`-style artifact (prose intro + a summary table of the four layers + an ASCII diagram + a "division of labor" + a fenced `yaml` registry) — and a human can read it top-to-bottom and answer "what stops a broken cj_goal change from landing, and at which layer?" without opening any script.
- [x] AC2: `scripts/gate-spec.sh` (mirrors `scripts/doc-spec.sh`) exposes `--validate` (exit 0 + `OK schema_version=<n>` when the registry parses, else exit 1 + `[gate-spec-no-config] <reason>`), `--list-layers`, and `--list-gates`; `--validate` exits 0 on the committed registry and the list subcommands emit the right sets.
- [x] AC3: a new advisory `validate.sh` Check 22 (structurally a clone of Check 21) asserts the registry parses AND runs the per-mode marker drift guard — for every gate, for every mode key in its `markers` map: a literal `"[marker]"` must appear in at least one of that mode's files (`skills/CJ_goal_<mode>/pipeline.md` OR `SKILL.md`); an `{enforced_by: ...}` value is skipped. It is GREEN on the clean tree and REPORTS a finding when a declared literal marker is removed from the registry or from both of its mode's files. Advisory in v1 (a finding prints but does not exit non-zero — exactly like Check 21).
- [x] AC4: the docs disambiguate "gate" (CI checks vs pipeline gates vs ratchets): `architecture.md` gains a "The gate-spec.md contract" section AND the mislabeled "The CI gate (`scripts/validate.sh`)" heading is renamed/reframed to name what it actually covers; `philosophy.md §4` gains a one-line pointer to `gate-spec.md`; the four pipelines + CLAUDE.md gain a one-line canonical-gate-sequence reference; `doc-spec.md` registers `gate-spec.md` (section: custom, audit_class: operational).
- [x] AC5: the parallel `scripts/test.sh` regression-guard row ships in the SAME PR (asserts `gate-spec.sh --validate` is wired + exits 0, Check 22 exists + is ADVISORY, the universal + per-mode markers resolve, and `zzz-test-scaffold` still passes with Check 22 active); `validate.sh` + `test.sh` + the windows Git-Bash job all green; PR-stop for human review.

## Todos

<!-- Actionable items for this story. -->

- [x] Author `gate-spec.md` (prose map + four-layer summary table + ASCII diagram + division-of-labor + fenced `yaml` registry; enumerate the gate rows from the four live pipelines using the per-mode `markers` map + `enforced_by` escape + `order`).
- [x] Write `scripts/gate-spec.sh` (mirror `scripts/doc-spec.sh`; `--validate` / `--list-layers` / `--list-gates` only — `--seed` / `--list-for` deferred; reads `gate-spec.md` via `git rev-parse --show-toplevel`).
- [x] Add advisory `validate.sh` Check 22 (registry parses + per-mode marker drift guard), structurally cloning Check 21 (permission-policy).
- [x] Add the `test.sh` regression-guard row AND verify the `zzz-test-scaffold` integration path still passes with Check 22 active (the known blind spot — copied the S000094 permission-policy block at `scripts/test.sh` as the template; zzz-test-scaffold verified green with Check 22 active).
- [x] Register `gate-spec.md` in `doc-spec.md` (section: custom, audit_class: operational — Check 17).
- [x] Wire docs: `architecture.md` new "gate-spec.md contract" section + relabel the "CI gate" heading; `philosophy.md §4` pointer; the four `skills/CJ_goal_*` pipeline/SKILL reference lines; `CLAUDE.md` pointer.
- [x] Confirm whether `gate-spec.sh` needs a `skills-catalog.json` entry — confirmed NO (root script like `doc-spec.sh` / `permission-policy.sh`, neither of which is cataloged).
- [ ] Run `/CJ_personal-workflow check`; `validate.sh` + `test.sh` green (windows Git-Bash verified at /ship); PR-stop for human review. (validate.sh + test.sh GREEN at implement; QA + /ship pending)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-07: Created. The single child story of F000054. Closes the verification-legibility gap: four verification layers grew up independently with overlaps + an overloaded "gate" vocabulary, and no single map answers "what stops a broken cj_goal change from landing, and at which layer?". Applies the proven `doc-spec.md` pattern to gates (the third member of doc-spec → permission-policy → gate-spec).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `gate-spec.md` — NEW: human verification map (prose + four-layer summary table + ASCII diagram + division-of-labor) + a fenced `yaml` registry of layers + gates (per-mode `markers` map; `{enforced_by: subagent|auq}` escape; `order`).
- `scripts/gate-spec.sh` — NEW: reader mirroring `doc-spec.sh` (`--validate` / `--list-layers` / `--list-gates`; reads via `git rev-parse --show-toplevel`).
- `scripts/validate.sh` — MODIFIED: advisory Check 22 (registry parses via `gate-spec.sh --validate` + per-mode marker drift guard across the four `skills/CJ_goal_*` pipelines; advisory exit 0, mirrors Check 21).
- `scripts/test.sh` — MODIFIED: F000054/S000096 gate-spec regression guards (parser wired + Check-22 advisory wiring + universal/per-mode marker resolution + zzz-test-scaffold still green).
- `doc-spec.md` — MODIFIED: registered `gate-spec.md` (section: custom, audit_class: operational) so root-doc Check 17 passes.
- `docs/architecture.md` — MODIFIED: new "The gate-spec.md contract" section; relabel the mislabeled "The CI gate (`scripts/validate.sh`)" heading.
- `docs/philosophy.md` — MODIFIED: §4 one-line pointer to `gate-spec.md` (no work-item IDs — human-doc).
- `skills/CJ_goal_feature/{pipeline.md,SKILL.md}`, `skills/CJ_goal_defect/{pipeline.md,SKILL.md}`, `skills/CJ_goal_task/{pipeline.md,SKILL.md}`, `skills/CJ_goal_todo_fix/SKILL.md` — MODIFIED: one-line canonical-gate-sequence reference near each halt taxonomy (in the SKILL.md halt-taxonomy section + the pipeline.md intro).
- `skills/CJ_goal_feature/USAGE.md`, `skills/CJ_goal_defect/USAGE.md`, `skills/CJ_goal_task/USAGE.md`, `skills/CJ_goal_todo_fix/USAGE.md` — MODIFIED: `last-updated:` timestamp bumped (the SKILL.md edits are cosmetic one-line pointers; USAGE.md stays accurate — keeps validate.sh Check 14 green post-commit per CLAUDE.md's documented procedure).
- `CLAUDE.md` — MODIFIED: new "Verification contract (gate-spec.md)" section + `gate-spec.md` added to the operational-docs list.

## Insights

<!-- Non-obvious findings worth remembering. -->

- The repo ALREADY solved this for documentation: `doc-spec.md` is ONE file that is both the human-readable map AND the machine source of truth (a fenced yaml registry parsed by `scripts/doc-spec.sh`). The fix is not a new mechanism — it is applying the doc-spec pattern to gates. Maximum human-understandability comes from symmetry with something already in the repo.
- Even closer precedent: `permission-policy.md` + `scripts/permission-policy.sh` + `validate.sh` Check 21 (same F000053 saga) is the SECOND instance of this shape and the closest structural template for Check 22 (a cross-orchestrator drift check). Check 21 shipped ADVISORY, so Check 22 follows the same advisory-first posture.
- The schema must model marker irregularity honestly. Verified against the live pipelines: the isolation gate has THREE markers for one concept (`[feature-not-isolated]` / `[investigate-not-isolated]` for DEFECT — not "defect-not-isolated" / `[task-not-isolated]`) and todo has NO isolation marker (it runs inside the drain worktree). Only `[portability-red]` + `[doc-sync-red]` are universal across all four cj_goals; `[qa-red]` + `[ship-declined]` are feature/defect/task only; `[design-gate-declined]` is feature-only. So `markers` is a per-mode map, and a value is either a literal `"[marker]"` (greppable) OR `{enforced_by: subagent|auq}` (the escape hatch that keeps the baseline honestly clean).
- todo file resolution RESOLVED: `CJ_goal_todo_fix` keeps gate logic in BOTH `SKILL.md` and `pipeline.md`, markers duplicated across both, so the conformance rule is "marker present in EITHER file for that mode" (dir is `CJ_goal_todo_fix`, not `CJ_goal_todo`).
- Known blind spot: every new `validate.sh` check historically needs a parallel `test.sh` zzz-test-scaffold edit and the implement subagent has forgotten it on F000032 / F000034 / F000035. Check 22 greps `skills/CJ_goal_*/` and zzz-test-scaffold is not a `CJ_goal_*` skill, so it is naturally skipped — but verify, don't assume.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-07 [decision] Approach A (full doc-spec mirror) chosen over B (registry inside cj-goal-common.sh) and C (gate-spec.md + grep, no reader). A is the truest mirror of the in-repo doc-spec idiom (maximum legibility) and ships in one PR (new artifact + reader + one check + doc; only light edits to the four pipelines, no gate-execution re-plumbing).
- 2026-06-07 [decision] Declarative contract, NOT a central executor (Premise 1). Interactive AUQ gates (design-summary) and subagent dispatches (QA) cannot run from one shared bash entry point, so "shared gate contract" = a single DECLARED ordered sequence all cj_goals reference + a conformance check, NOT a `--run-all-gates` function.
- 2026-06-07 [decision] `markers` is a per-mode map + an `{enforced_by: subagent|auq}` escape hatch, NOT a flat `applies_to` + single `halt_marker` (the adversarial review caught the flat shape as a fatal over-simplification — the real markers are irregular across modes). "In sync" = "every declared per-mode marker is present where declared" — literally enforceable for portability + doc-sync, per-mode enforceable for everything else.
- 2026-06-07 [decision] Check 22 advisory in v1, mirroring Check 21 (NOT hard-ERROR from day one). The review flagged "hard ERROR from day one" as inconsistent with the Check 21 precedent + risky for a hand-authored registry's first cut. Because the registry is authored honestly, the advisory check is GREEN on the clean baseline today, so the flip-to-strict is a one-line follow-up TODO (a free ratchet).
- 2026-06-08 [impl-decision] Enumerated the full gate set (8 gates) from the four live pipelines, verified every marker by grep BEFORE declaring it: universal `[portability-red]`/`[doc-sync-red]` (all 4); isolation per-mode `[feature-not-isolated]`/`[investigate-not-isolated]`/`[task-not-isolated]` (todo omitted); `[qa-red]`+`[ship-declined]` feature/defect/task (todo `{enforced_by: subagent}`/`{enforced_by: auq}`); `[design-gate-declined]` feature-only; `[investigate-no-root-cause]` defect-only; `[task-too-complex]` task-only.
- 2026-06-08 [impl-decision] `gate-spec.sh` markers-map parser: awk flag-based, scans only within `gates:`, opens the per-mode map at `markers:`, emits `mode=value` tokens (bracket literal OR `enforced_by:<kind>`); comment-only lines (omitted modes) skipped. Check 22 reuses the SAME awk to extract `<gate> <mode> <literal>` triples (skipping `{enforced_by}`), greps each literal in `skills/CJ_goal_<mode-dir>/{pipeline.md,SKILL.md}` (either file). Mirrors doc-spec.sh/permission-policy.sh idioms.
- 2026-06-08 [impl-decision] No `skills-catalog.json` entry for `gate-spec.sh` — confirmed it is a root script like `doc-spec.sh` / `permission-policy.sh`, neither of which is cataloged (the catalog is for invocable skills with a SKILL.md, not root helper scripts).
- 2026-06-08 [impl-finding] Known blind spot (F000032/34/35) verified clear: Check 22 greps only `skills/CJ_goal_<mode>/`, and `zzz-test-scaffold` is not a `CJ_goal_*` skill, so the integration fixture is naturally skipped. Ran the full test.sh — the zzz-test-scaffold cycle (`validate.sh passes with manually created skill`) stays GREEN with Check 22 active. Did NOT assume; verified by running the integration path.
- 2026-06-08 [impl-finding] Proactively bumped the four CJ_goal USAGE.md `last-updated:` fields: the SKILL.md edits are cosmetic one-line gate-spec pointers, so per CLAUDE.md's documented Check-14 procedure the USAGE.md gets a content bump in the SAME commit, keeping commit timestamps in lockstep (Check 14 uses git `%ct`, not mtime).
- 2026-06-08 [impl] Wrote 2 new files (gate-spec.md, scripts/gate-spec.sh +x); modified 11 (validate.sh Check 22, test.sh S000096 block, doc-spec.md registry, docs/architecture.md, docs/philosophy.md, CLAUDE.md, 4 CJ_goal pipeline.md, 4 CJ_goal SKILL.md, 4 CJ_goal USAGE.md). validate.sh + test.sh both GREEN (0 errors); negative drift test confirms Check 22 reports a finding + still exits 0 (advisory).
- 2026-06-08 [impl-pass] S000096: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files). QA-owned gates (Acceptance criteria verified met, Smoke tests pass) left for /CJ_qa-work-item.
- 2026-06-07 [qa-smoke] S1 (AC-2): green — `bash scripts/gate-spec.sh --validate` exit 0, emitted `OK schema_version=1`.
- 2026-06-07 [qa-smoke] S2 (AC-2): green — `--list-layers` emitted 4 ids (local-hook/ci/pipeline-gate/ratchet); `--list-gates` emitted 8 ids (complexity/design-gate/doc-sync/isolation/portability/qa/root-cause/ship), sorted + unique.
- 2026-06-07 [qa-smoke] S3 (AC-3): green — `bash scripts/validate.sh` ran Check 22 ("cj_goal gate-spec marker drift (advisory)"), reported PASS (no finding) on the clean tree, validate.sh exit 0.
- 2026-06-07 [qa-smoke] S4 (AC-3): green — `bash scripts/test.sh` F000054/S000096 gate-spec regression guards OK (universal + per-mode marker resolution asserted); suite RESULT: PASS, Failures: 0.
- 2026-06-07 [qa-smoke] S5 (AC-3): green — `bash scripts/test.sh` zzz-test-scaffold integration case passes with Check 22 active (Check 22 greps `skills/CJ_goal_*/`, scaffold skill naturally skipped); suite exit 0.
- 2026-06-07 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-07 [qa-e2e-run-start] RUN_ID=20260607-184019-96009 commit=0293a2e
- 2026-06-07 [qa-e2e] E1 (AC-1): green — gate-spec.md legibility test: file names the four layers (summary table L20-25, ASCII diagram L34-62, "The plain answer" L86-100) and maps each broken-change class + each guarantee to one owning layer (division-of-labor table L69-83); answerable from the file alone, no script.
- 2026-06-07 [qa-e2e] E2 (AC-3): green — injected drift in a scratch worktree (deleted `[portability-red]` from both skills/CJ_goal_feature/{pipeline.md,SKILL.md}); Check 22 named the drift ("gate 'portability' declares marker [portability-red] for mode 'feature' but it is absent...") and validate.sh still exited 0 (advisory).
- 2026-06-07 [qa-e2e] E3 (AC-2): green — `--list-layers`/`--list-gates` emit exactly the registry's 4 layer + 8 gate ids; `--validate` exits 0 on the committed registry and exits 1 + `[gate-spec-no-config] schema_version field missing...` on a hand-corrupted copy (schema_version dropped).
- 2026-06-07 [qa-e2e] E4 (AC-4): green — all five doc surfaces reference gate-spec.md: architecture.md new `## The gate-spec.md contract` section + the bare "CI gate" mislabel is gone (headings now name what they cover); philosophy.md §4 pointer (no work-item IDs); four CJ_goal_* pipeline/SKILL "Canonical gate sequence" lines; doc-spec.md registry entry (section custom / operational); CLAUDE.md `## Verification contract` section + operational-docs list.
- 2026-06-07 [qa-e2e-summary] green (0s subagent — run inline per workbench-deterministic policy; 4 rows verified; 0 deferred): all 4 E2E criteria green (E1 legibility, E2 advisory-drift, E3 list/validate exit codes, E4 doc disambiguation).
- 2026-06-07 [qa-pass] S000096 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
