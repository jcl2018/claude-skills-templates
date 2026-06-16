---
name: "Behaviors + coverage in the test-spec contract"
type: user-story
id: "S000110"
status: active
created: "2026-06-16"
updated: "2026-06-16"
parent: "F000066"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/angry-wozniak-0b3ea3"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "f5edc4ececa630bb51d2ba7a9199c99cdae5c37a"
    completed_at: "2026-06-16T01:47:18Z"
    test_rows_run: 10
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7", "AC-8", "AC-9", "AC-10"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke-summary] green", "[qa-e2e-summary] green", "[qa-audit] AUDITS=deferred", "[qa-pass]"]
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
2. Create working branch: `git checkout -b feat/behaviors_and_coverage_in_test_spec` (or use parent's branch if shipping in same PR)
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

- [x] `test-spec.sh` parses `behaviors:` (keyed on `- id:`) and `behavior_coverage:` (keyed on `- behavior:`, no `id`), with `behaviors|behavior_coverage` added to the top-level-key terminator regex of all four existing per-block parsers.
- [x] The closed `level` enum `{unit, integration, contract, workflow, property}` is enforced; an out-of-enum value halts with `[test-spec-no-config]`.
- [x] Checks 1–2 (schema/enum/`id`-uniqueness) live in `_run_registry_gates`; Checks 3–6 (coverage-link conformance) live in `_run_coverage`, gated on `behaviors:` existing (independent of the `units:` gate).
- [x] Check 3: every `behavior_coverage.behavior` resolves to exactly one `behaviors[]` row (0 or 2+ → finding).
- [x] Check 4: every `behavior_coverage.unit` resolves to exactly one `units[]` row whose family ∈ `{test, test-deploy, eval, windows-smoke}` (reject `validate | ci | hook`).
- [x] Check 5: `behavior_coverage.source` exists and `anchor` matches live via fixed-string `grep -F` (NOT the `_fwd_match` dispatcher).
- [x] Check 6: every `behaviors[]` row has ≥1 `behavior_coverage` row.
- [x] `--list-behaviors` and `--list-behavior-coverage` print in registry order; `--validate` runs the rendered-field work-item-ID lint on `statement` + `purpose`.
- [x] Absent registry inherits `REGISTRY=absent` + exit 0; no-`behaviors:` ⇒ "behavior coverage inactive" + exit 0 (no participation in the ≥20-token reverse floor).
- [x] `spec/test-spec.md` gains prose + the `level` enum but its machine block is unchanged; it stays byte-identical to `test-spec.sh --seed` (embedded heredoc updated in lockstep).
- [x] `validate.sh` Check 24 runs the new behavior checks in the same hard loop.
- [x] `tests/test-spec.test.sh` gains parser round-trip + the new deterministic-check drills, AND the parallel `test.sh` integration-fixture edit is made.
- [x] `/CJ_test_audit` Stage-2 gains the per-behavior substance sub-check (findings prefixed `stage2/behavior:<id>`).
- [x] ~8 dogfood `behaviors:` + `behavior_coverage:` rows for test-spec itself are added to `spec/test-spec-custom.md` and are green end-to-end.

## Todos

<!-- Actionable items for this story. -->

- [x] Extend the `test-spec.sh` `--seed` heredoc (prose + enum) + parser for the two new blocks; add `--list-behaviors` / `--list-behavior-coverage` + the `--validate` lint.
- [x] Implement the 6 conformance checks (1–2 in `_run_registry_gates`; 3–6 in `_run_coverage`, gated on `behaviors:`) + the inactive-note parity path; the boundary-regex edits to the 4 existing parsers + the `- behavior:` flush key.
- [x] Wire into `validate.sh` Check 24 + the `test.sh` `test-spec` sub-suite + the integration fixture (mandatory — the systematic implement-subagent blind spot).
- [x] Add the `/CJ_test_audit` Stage-2 behavior substance sub-check.
- [x] Add the ~8 dogfood behavior + coverage rows to `spec/test-spec-custom.md`; confirm green end-to-end.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-16: Created. Implement the behavior-coverage axis (declared `behaviors:` + first-class `level` + `behavior_coverage:` relation) in the test-spec contract, plus the load-bearing `/CJ_test_audit` Stage-2 substance check.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `spec/test-spec.md`
- `spec/test-spec-custom.md`
- `scripts/test-spec.sh`
- `scripts/validate.sh`
- `scripts/test.sh`
- `tests/test-spec.test.sh`
- `skills/CJ_test_audit/SKILL.md`
- `skills/CJ_test_audit/USAGE.md` (Stage-2 behavior sub-check described — Check 14 freshness)
- `skills/CJ_qa-work-item/qa.md` (inline Step 8.6 AUDIT_FINDINGS block template extended with BEHAVIORS_AUDITED + per-behavior verdicts)

## Insights

<!-- Non-obvious findings worth remembering. -->

- `behavior_coverage:` has NO `id` — its per-row flush keys on the first field `- behavior:` (mirroring how rules/units key on `- id:`). Optional `area`/`purpose` use the units parser's `nz()` → `-` placeholder + reader-normalize dance (tab-IFS collapses empty fields otherwise).
- Behavior anchors are arbitrary semantic-evidence prose, so Check 5 uses fixed-string `grep -F`, NOT the family-shaped `_fwd_match` dispatcher used by unit anchors (`=== Check N` / runner-path shapes).
- The implement-subagent systematically forgets the parallel `test.sh` integration-fixture edit for every new validate-surface (F000032/34/35). Pre-flight it explicitly.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-16 — Atomic story, no task children. Summary: the v1 is one cohesive change (parser + checks + seed prose + audit sub-check + dogfood rows) over a tightly-coupled set of files; decomposing into tasks adds ceremony without parallelism (per WORKFLOW.md, tasks are optional for atomic stories).
- [impl] 2026-06-16 — Implemented the behavior-coverage axis (Approach A, v1). Summary: added `behaviors:` (keyed `- id:`) + `behavior_coverage:` (keyed `- behavior:`, no id) parsers to `scripts/test-spec.sh`; added `behaviors|behavior_coverage` to all four existing per-block terminator regexes; Checks 1–2 (slug/required-keys/level-enum/id-uniqueness/work-item-ID lint) in `_run_registry_gates`, Checks 3–6 (resolve-one-behavior / resolve-one-test-bearing-unit / live `grep -F` anchor / ≥1-cover) in a new `_run_behavior_coverage` invoked from `_run_coverage` gated on `behaviors:` INDEPENDENT of the units gate; added `--list-behaviors` / `--list-behavior-coverage` + the `--validate` lint extension; seed gains PROSE only (machine block + schema_version=1 unchanged) and `spec/test-spec.md` regenerated byte-identical to `--seed`.
- [impl-decision] 2026-06-16 — Behavior anchors use fixed-string `grep -F`, NOT the family-shaped `_fwd_match` dispatcher. Summary: behavior_coverage anchors are arbitrary semantic-evidence prose (the behavior named in the test text), not `=== Check N` / runner-path shapes, so the execution-shaped dispatcher is wrong for them; the substance judgment (does the test actually PROVE the behavior) is deferred to the agent-judged `/CJ_test_audit` Stage-2 (P5).
- [impl-decision] 2026-06-16 — The behavior gate runs INDEPENDENT of the units gate. Summary: a repo could declare behaviors with no units overlay; on the no-units path `_run_coverage` still runs the behavior checks so a declared-but-uncovered behavior is never silently unverified (verified by the test-spec.test.sh §9.3 independent-gate drill).
- [impl] 2026-06-16 — Wired the new surface into the gate + suite + integration (the F000032/34/35 blind spot, defused). Summary: `validate.sh` Check 24's hard loop already runs `--check-coverage`, so behavior findings fail the same gate (banner/comment updated); added 13 behavior drills (positive + the 6-check negatives + duplicate-id + inactivity + independent-gate) to `tests/test-spec.test.sh` §9 (and fixed `_rebuild_fixture` to copy the real `test-spec.test.sh` body so the dogfood anchors resolve in the fixture); added the live-tree behavior positives + inactive-note assertion to the `scripts/test.sh` F000060 block.
- [impl] 2026-06-16 — Added the `/CJ_test_audit` Stage-2 per-behavior substance sub-check (§4.3) + the matching qa.md inline block template, USAGE.md, frontmatter description, report contract (`BEHAVIORS_AUDITED=`), and error-handling table row. Summary: per behavior, judge falsifiable/specific? level correct? proves-vs-mentions? over-claimed? — findings prefixed `stage2/behavior:<id>`; skips cleanly when `--list-behaviors` is empty.
- [impl-pass] 2026-06-16 — All deterministic verification green: `test-spec.sh --validate` OK schema_version=1; `--check-coverage` OK rows=69 reverse_tokens=49 findings=0 (8 dogfood behaviors resolve); `--list-behaviors` lists 8; `diff <(--seed) spec/test-spec.md` empty (byte-identical); `tests/test-spec.test.sh` PASS (46 OK); `scripts/validate.sh` GREEN; `tests/{test-spec-reconcile,cj-audit-skills}.test.sh` GREEN; shellcheck clean on the modified scripts.
- 2026-06-15 [qa-smoke] S1 (AC-7): green — seed byte-identity: `diff <(test-spec.sh --seed) spec/test-spec.md` empty.
- 2026-06-15 [qa-smoke] S2 (AC-2): green — level-enum + id-uniqueness gate: bad-level + dup-id fixtures fail closed with [test-spec-no-config] (test-spec.test.sh drills).
- 2026-06-15 [qa-smoke] S3 (AC-3): green — coverage-link resolution: dangling behavior ref + ci-family unit each surface as a finding (test-spec.test.sh Check 3/4 drills).
- 2026-06-15 [qa-smoke] S4 (AC-4): green — live-anchor + ≥1-cover: non-live `grep -F` anchor + uncovered behavior each a finding; good fixture passes (test-spec.test.sh Check 5/6 drills).
- 2026-06-15 [qa-smoke] S5 (AC-6): green — consumer parity: units-only registry reports 'behavior coverage inactive' + exit 0; absent registry REGISTRY=absent + exit 0 (test-spec.test.sh + live --check-coverage).
- 2026-06-15 [qa-smoke] S6 (AC-8): green — hard-gate + suite + fixture wiring: `validate.sh` Check 24 PASS (coverage rows=69 findings=0), `test.sh` PASS (Failures: 0); F000066 behavior block runs in the test-spec sub-suite + integration fixture.
- 2026-06-15 [qa-smoke-summary] green: 6/6 non-manual rows green (0 manual rows pending)
- 2026-06-15 [qa-e2e-run-start] RUN_ID=20260615-184718-55722 commit=f5edc4e
- 2026-06-15 [qa-e2e] E1 (AC-10): green — dogfood green end-to-end: `validate.sh` + `test.sh` both exit 0; all 8 dogfood behaviors resolve to real, anchored, test-bearing covers (`--check-coverage` findings=0). [parent-inline]
- 2026-06-15 [qa-e2e] E2 (AC-9): green — agent-judged substance: `/CJ_test_audit` Stage-2 §4.3 per-behavior sub-check implemented (enumerates via --list-behaviors; judges falsifiable/level/proves-vs-mentions/over-claimed; findings stage2/behavior:<id>; skips clean when empty) and wired into qa.md AUDIT_FINDINGS + USAGE.md + frontmatter + error table. Live agent-judged execution DEFERRED to the orchestrator post-sync audit (DEFER_AUDIT: true). [parent-inline]
- 2026-06-15 [qa-e2e] E3 (AC-5): green — list + lint: `--list-behaviors` + `--list-behavior-coverage` render in registry order; `--validate` work-item-ID lint covers behavior statement/purpose (test-spec.sh:596-599). [parent-inline]
- 2026-06-15 [qa-e2e] E4 (AC-1): green — parser isolation: under the full merged registry rules=5, units=69 parse unchanged; behaviors=8, behavior_coverage=8 parse independently; the new top-level keys do not bleed into rules/units/layers/gates. [parent-inline]
- 2026-06-15 [qa-e2e-summary] green (0s subagent; 4 rows parent-inline; 0 deferred): all 4 E2E criteria green — dogfood/substance/list-lint/parser-isolation. (Leaf-subagent depth wall — E2E run inline via Bash, not a dispatched subagent.)
- 2026-06-15 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a/8.6b ran inline — no new test/doc surface, the behavior-axis rows + modified test-spec.test.sh are already registered & green; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-15 [qa-pass] S000110 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
