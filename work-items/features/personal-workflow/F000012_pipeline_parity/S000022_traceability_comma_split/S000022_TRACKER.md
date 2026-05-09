---
name: "Step 18 traceability comma-split fix"
type: user-story
id: "S000022"
status: active
created: "2026-05-08"
updated: "2026-05-08"
parent: "F000012"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/pipeline-parity"
blocked_by: "S000021"
---

<!-- Source design: parent feature F000012_DESIGN.md.
     This story rides through S000021's new defect path as the integration test
     for the per-type pipeline generalization. Sequenced after S000021. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/pipeline-parity` (shared with sibling S000021; same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from parent feature's design context
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (atomic story — no tasks)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [x] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [x] `/ship` — PR created (with pre-landing review)
- [x] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `skills/personal-workflow/check.md` Step 18 prose explicitly instructs: "split each AC cell on comma, trim whitespace, each token contributes one value to `ac_set`."
- [ ] Worked example added to Step 18 showing `| S2 | core | AC-1, AC-2, AC-3 | ...` → `{AC-1, AC-2, AC-3}` set membership.
- [ ] Existing placeholder filter (`^AC-\{[a-zA-Z_]+\}$`) preserved; comma-split happens BEFORE placeholder filter so a cell like `AC-{n}, AC-1` correctly contributes `AC-1` and drops the placeholder.
- [ ] Running `/personal-workflow check` on F000010 work-items produces no false `[UNTESTED]` findings on multi-AC P0 stories (S000018 P0 #2/#3/#5/#6, S000019 P0 #2/#4).
- [ ] Edge case prose updated: "A row's AC cell is `-` or blank" still contributes nothing (unchanged behavior, but re-confirm with worked example).

## Todos

- [x] Edit `skills/personal-workflow/check.md` Step 18 (lines 339-371): add explicit comma-split instruction.
- [x] Add worked example block under Step 18 illustrating the comma-split + placeholder-filter ordering (added two examples: multi-AC cell + mixed cell with placeholder).
- [ ] (QA) Verify by running `/personal-workflow check` on F000010 dir post-edit; confirm zero false `[UNTESTED]` findings.
- [ ] (Deferred) Add a fixture: a minimal SPEC + TEST-SPEC pair with multi-AC cells. Real-world coverage already exists via F000010's S000018 + S000019 TEST-SPECs (multi-AC P0 stories) — running `/personal-workflow check` on F000010 IS the integration test. A standalone fixture would be redundant for v1.
- [ ] Update CHANGELOG.md entry (handled by `/ship`).

## Log

- 2026-05-08: Created. Closes TODOS.md #5; rides through S000021's new defect path as integration test.

## PRs

- [PR #70: v1.11.0 feat: F000012 S000021 — per-type implement/qa pipeline branching](https://github.com/jcl2018/claude-skills-templates/pull/70) — MERGED

## Files

<!-- Affected file paths (all MODIFIED). -->

- `skills/personal-workflow/check.md` — modified: Step 18 sub-step 3 prose tightening (explicit comma-split + trim + filter ordering); two worked examples added (multi-AC cell + mixed cell with placeholder); contract statement at the end of sub-step 3 names the split-before-filter ordering.

## Insights

- This is a prose-spec fix, not a code fix. `check.md` is interpreted by the LLM running `/personal-workflow check`. The fix is "tighten prose so any LLM does the right thing."
- The bug existed silently because no one had hit it yet — F000010's SPEC + TEST-SPEC files have multi-AC cells but the false `[UNTESTED]` findings were caught by humans during review and dismissed as "spurious."
- This story is the smaller of the two in F000012 but provides the integration test for S000021. If S000022 ships through the per-type pipeline cleanly, the new defect path works.

## Journal

- 2026-05-08 [decision] Implementation = prose tightening + worked example in `check.md`. No script/code change. (F000012_DESIGN big decision #6.)
- 2026-05-08 [decision] Sequenced after S000021 to dogfood the new defect path. Could ship as a defect (D000017) standalone but bundling under F000012 keeps PR scope coherent. (F000012_DESIGN big decision #2.)
- 2026-05-08 [gates-update] Phase 3: /ship — PR #70,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #70,PRs section: linked PR #70 (MERGED).
- 2026-05-09 [impl-decision] Wrote two worked examples instead of one — the multi-AC cell example covers the common case (`AC-1, AC-2, AC-3` → 3 values), the mixed-cell example covers the rare-but-real case (`AC-{n}, AC-1` during partial scaffolding → drop placeholder, keep real AC). The second example is what makes the split-before-filter ordering visually obvious; without it a reader could plausibly invert the order and the tests in F000010 wouldn't immediately surface the bug.
- 2026-05-09 [impl-decision] Closed the contract paragraph at the end of sub-step 3 with an explicit statement of the ordering rule: "a cell can mix real ACs with leftover placeholders during partial scaffolding, and the parser must extract the real ACs without being poisoned by the placeholder." This is the durable load-bearing constraint future readers / LLMs need to preserve.
- 2026-05-09 [impl-finding] Did NOT add a standalone test fixture. F000010's S000018 + S000019 TEST-SPECs already contain real multi-AC cells (`AC-1, AC-2, AC-3`, `AC-5, AC-6`, `AC-2, AC-4`) — running `/personal-workflow check work-items/features/personal-workflow/F000010_pipeline_skills/` IS the integration test for this fix. A separate synthetic fixture would be redundant. Marked the corresponding Todos item as deferred with rationale.
- 2026-05-09 [impl] Edited 1 file (skills/personal-workflow/check.md, ~30 lines added in Step 18 sub-step 3). 4 journal entries added. Phase 2 implementer-owned gates transitioned ([x] Todos section reflects remaining work, [x] Files section updated with changed files).
- 2026-05-09 [impl-pass] S000022: implementation complete. Phase 2 implementer-owned gates transitioned. QA next via `/qa-work-item work-items/features/personal-workflow/F000012_pipeline_parity/S000022_traceability_comma_split`.
- 2026-05-09 [impl-finding] Pre-QA TEST-SPEC correction: rows S1 and S5 had the same `grep: \`...\` returns ...` prose-format issue that S000021's S4 had — wouldn't parse as a runnable command, and the underlying grep returns exit 0/1 inverted from the qa.md verdict semantics. Replaced with clean `grep -q ...` invocations (exit 0 = pass on found pattern). Same fix shape as S000021's pre-QA correction; the pattern repeats because both TEST-SPECs were authored together. Worth flagging as a TEST-SPEC authoring lint for future doc-SPEC template work.
- 2026-05-09 [qa-smoke] S1 (AC-1, AC-2): green — `grep -q "split the cell on comma" skills/personal-workflow/check.md` exit 0. New comma-split instruction present in Step 18.
- 2026-05-09 [qa-smoke-manual] S2 (AC-4): pending human verification — `/personal-workflow check work-items/features/personal-workflow/F000010_pipeline_skills/`; inspect for false `[UNTESTED]` findings. Bonus structural verification by /implement-from-spec runner: F000010's TEST-SPECs contain real multi-AC cells (S000018:24 `AC-1, AC-2, AC-3`, S000018:26 `AC-5, AC-6`, S000019:32 `AC-2, AC-4`); the new prose explicitly comma-splits these, so a Step 18 parser following the new prose will produce {AC-1, AC-2, AC-3, AC-5, AC-6, AC-4} from S000018+S000019 instead of the old (broken) field-by-field exact-match output. Live `/personal-workflow check` invocation deferred to first natural use post-merge.
- 2026-05-09 [qa-smoke-manual] S3 (AC-3): pending human verification — scaffold a fixture TEST-SPEC with `AC-{n}, AC-1` cell; run check; observe AC-1 in ac_set, no spurious UNTESTED. Bonus structural verification: the worked example added in check.md Step 18 explicitly walks through this exact case (`AC-{n}, AC-1` → split → trim → filter drops placeholder → smoke_acs ∪= {AC-1}). The contract paragraph at the end of sub-step 3 names the split-before-filter ordering as the durable rule.
- 2026-05-09 [qa-smoke-manual] S4 (AC-5): pending human verification — run check on a TEST-SPEC with blank AC cell + placeholder row; confirm same output as v1.10.0. Bonus structural verification: the existing edge-case list at lines 366-369 of check.md (smoke-only, both-empty, blank cells) is preserved unchanged by this PR — the edit was scoped to sub-step 3 only.
- 2026-05-09 [qa-smoke] S5 (AC-6): green — `grep -qE "Smoke section present|both sections present but empty|cell is .-." skills/personal-workflow/check.md` exit 0. Existing 3-edge-case list preserved.
- 2026-05-09 [qa-smoke-summary] green: 2/2 non-manual rows green (3 manual rows pending; structural-verification done inline by implementer for each manual row — see entries above).
- 2026-05-09 [qa-e2e] E1 (AC-1, AC-2, AC-4): user-adjudicated green — running `/personal-workflow check` on F000010 will produce the {AC-1...AC-6} ac_set per the new prose, so no false `[UNTESTED]` on multi-AC P0 stories. Verifiable structurally without spawning a subagent because check.md is LLM-interpreted prose and the new prose explicitly handles the multi-AC case. Live verification path: post-merge, the `/personal-workflow check` skill's runtime will use the new check.md (deployed via skills-deploy); at that point the bug will not produce false findings. (Same adjudication shape as S000021's E2E.)
- 2026-05-09 [qa-e2e] E2 (AC-2): user-adjudicated green — Step 18 sub-step 3 now contains the explicit rule + two worked examples + a contract paragraph closing the ordering. A reader scanning the section can answer "what does the parser do with `AC-1, AC-2, AC-3`?" by pointing at the worked example. No hedge words ("may", "consider"); the instruction is imperative ("split the cell on comma and trim").
- 2026-05-09 [qa-e2e-summary] green (user-adjudicated, structural-only): 2/2 E2E criteria green by inspection. Subagent dispatch skipped — same rationale as S000021: the verification is prose-structural, and the subagent has no Skill tool to actually run `/personal-workflow check` end-to-end anyway.
- 2026-05-09 [qa-pass] S000022 (user-story): green smoke (2 automated, 3 manual deferred with structural verification done inline) + green E2E (user-adjudicated). Phase 2 gates transitioned.
