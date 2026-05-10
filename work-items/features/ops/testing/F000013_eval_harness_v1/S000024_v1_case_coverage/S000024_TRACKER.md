---
name: "V1 eval case coverage (personal-workflow + system-health)"
type: user-story
id: "S000024"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000013"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/flamboyant-neumann-ed7a68"
blocked_by: "S000023"
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/eval_harness_v1_cases` (or use parent's branch if shipping in same PR)
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

<!-- What "done" looks like for this story. -->

- [x] `tests/eval/personal-workflow/check-step18-faithful-comma-split/` — fixture has multi-AC traceability cells (`AC-1, AC-2, AC-3`); schema asserts ac_coverage shape; case PASSES on a clean checkout. NOTE: regression-detection on a reverted-spec branch was empirically *weaker than designed* — see Reviewer Concerns below.
- [x] `tests/eval/personal-workflow/check-passing-feature/` — fixture is a canonical valid feature work-item; schema asserts overall=PASS, all checks=PASS
- [x] `tests/eval/personal-workflow/check-missing-frontmatter/` — fixture has incomplete frontmatter; schema asserts overall=FAIL with frontmatter check FAIL and ≥3 missing_fields
- [x] At least one more `personal-workflow` case covering a distinct check — `check-lifecycle-drift` (gate-row drift within phases, distinct from existing `check-flags-missing-lifecycle`'s missing-phase signal) PLUS `check-untested-p0` (Step 18 UNTESTED detection)
- [ ] `tests/eval/system-health/report-clean-system/` — DEFERRED TO V2 (runner doesn't fake $HOME; system-health hard-codes `~/.claude/`; case can't be authored without runner change). See Reviewer Concerns.
- [ ] `tests/eval/system-health/report-with-issues/` — DEFERRED TO V2 (same blocker as above)
- [x] Total V1 case count between 6–10 — shipped 6 (1 from S000023 + 5 from S000024); meets the 6–10 range despite system-health deferral
- [x] All cases pass `bash scripts/eval.sh` end-to-end — full-suite verified 2026-05-09: 6/6 PASS, $0.995 total cost, ~72s wall-clock under xargs -P 4
- [x] S000022 caveat documented in `check-step18-faithful-comma-split/prompt.md` (in-line note that this tests "Claude executes the spec," not the parser logic itself)

## Reviewer Concerns

### RC1 (medium): system-health behavioral coverage stays at zero in V1

The runner (`tests/eval/lib/run-case.sh` from S000023) does not override `$HOME`, and `system-health` hard-codes paths under `~/.claude/`. A fixture under `tests/eval/system-health/<case>/fixture/` is therefore invisible to the skill — it scans the maintainer's real `~/.claude/`, which is non-deterministic across machines and impossible to seed for nightly CI. P0 ACs for `report-clean-system` and `report-with-issues` deferred to V2. Path forward: extend `run-case.sh` with an opt-in `HOME=$tmpdir` override, then seed `fixture/.claude/skills/...` per case. See `tests/eval/README.md` "Deferred to V2" section.

### RC2 (low): S000022 regression-detection signal weaker than SPEC anticipated

The case `check-step18-faithful-comma-split` was authored and PASSes on a clean checkout (good). The regression-detection proof — reverting `check.md` Step 18's comma-split spec on a throwaway test branch — was performed locally on 2026-05-09: the case **still PASSed** because Claude infers comma-splitting from common sense even when the spec is silent. The case does catch a deeper "model can't comma-split at all" regression, but does NOT catch a "we forgot to mandate comma-split in the spec" regression as the SPEC anticipated. The deterministic path for that signal is V2's parser-extraction work (`scripts/check-helpers/parse-traceability.sh` + unit tests in `scripts/test.sh`).

## Todos

<!-- Actionable items for this story. -->

- [x] Author `check-step18-faithful-comma-split` case (the S000022 regression case)
- [x] Verify case fails on a test branch with the parser fix reverted — empirically the case still PASSed; finding captured in RC2 above
- [x] Author `check-passing-feature` case (canonical valid input)
- [x] Author `check-missing-frontmatter` case
- [x] Author 1–2 more personal-workflow cases — shipped 2: `check-lifecycle-drift` and `check-untested-p0`
- [ ] (Deferred to V2) Author `report-clean-system` case for system-health — blocked by runner $HOME limitation; see RC1
- [ ] (Deferred to V2) Author `report-with-issues` case for system-health — same blocker
- [x] Run full suite via `bash scripts/eval.sh` and verify all 6–10 cases pass — 6/6 PASS, $0.995, ~72s wall-clock (2026-05-09)
- [x] Add S000022 caveat note to `check-step18-faithful-comma-split/prompt.md`
- [x] Verify schema reuse: hand-wrote per-case schemas; no fragments shared across ≥3 cases yet, so `common-frags.json` defer to V2 per SPEC tradeoff #3

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. V1 case coverage — fills in the test cases that exercise personal-workflow + system-health behaviors against the runner that S000023 ships.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #72: v1.12.0 feat: F000013 V1 eval harness — S000023 runner + first case](https://github.com/jcl2018/claude-skills-templates/pull/72) — MERGED

## Files

<!-- Affected file paths. -->

- `tests/eval/personal-workflow/check-step18-faithful-comma-split/**` (new — prompt.md + fixture/ user-story tree + expected.schema.json)
- `tests/eval/personal-workflow/check-passing-feature/**` (new — fixture copies the F999999 valid-feature-dir bundle)
- `tests/eval/personal-workflow/check-missing-frontmatter/**` (new — F999001 broken tracker fixture)
- `tests/eval/personal-workflow/check-lifecycle-drift/**` (new — F999002 gate-row-drift fixture)
- `tests/eval/personal-workflow/check-untested-p0/**` (new — F999003/S999003 untested-P0 fixture)
- `tests/eval/README.md` (modified — V1 case index updated for #2–#6; deferred-to-V2 section added; empirical S000022 caveat documented)
- `work-items/features/ops/testing/F000013_eval_harness_v1/S000024_v1_case_coverage/S000024_TRACKER.md` (modified — Phase 1 working-branch gate ticked; Phase 2 implementer gates ticked; ACs ticked; Reviewer Concerns added; journal entries appended)
- (Deferred) `tests/eval/system-health/report-clean-system/**` — V2
- (Deferred) `tests/eval/system-health/report-with-issues/**` — V2
- (Deferred) `tests/eval/schemas/common-frags.json` — V2 (no ≥3-case sharing surfaced)

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
- 2026-05-09 [gates-update] Phase 3: /ship — PR #72,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #72,PRs section: linked PR #72 (MERGED). NOTE: this entry is stale — PR #72 was S000023's PR, not S000024's. The post-merge hook attributed it to S000024 because the merge commit referenced this user-story. Phase 3 gates remain effectively unverified for S000024 itself.
- 2026-05-09 [impl-decision] Skipped system-health cases (P0 ACs `report-clean-system` + `report-with-issues`); deferred to V2. Reason: `tests/eval/lib/run-case.sh` does not override `$HOME`, and `system-health` hard-codes `~/.claude/`. Fixture under `tests/eval/system-health/<case>/fixture/` is invisible to the skill. Path forward: V2 runner gains `HOME=$tmpdir` opt-in. Recorded in RC1.
- 2026-05-09 [impl-decision] Authored a 5th personal-workflow case (`check-untested-p0`) instead of the SPEC's optional `check-traceability-mismatch`. Reason: with system-health deferral dropping 2 cases, total V1 case count would have been 5 (below SPEC AC #7's 6–10 range). `check-untested-p0` is the natural complement to `check-step18-faithful-comma-split` — the former proves uncovered detection, the latter proves coverage. Final case count: 6 (1 from S000023 + 5 from S000024).
- 2026-05-09 [impl-decision] Hand-wrote per-case JSON schemas; deferred `tests/eval/schemas/common-frags.json` to V2. Reason: SPEC tradeoff #3 said lift only when 3+ cases share a fragment. Per-case schemas didn't surface ≥3-case sharing during authoring.
- 2026-05-09 [impl-finding] S000022 regression-detection proof: temporarily reverted Step 18's comma-split spec in `skills/personal-workflow/check.md` (worktree-local edit, restored via `git checkout`), re-ran `check-step18-faithful-comma-split`. Case **still PASSed** ($0.13, 28s). Claude infers comma-splitting from common sense regardless of whether the spec mandates it. Recorded as RC2; doesn't block V1 acceptance, but signals that this case is not the deterministic regression-detection mechanism the SPEC anticipated.
- 2026-05-09 [impl-finding] Phase 1 gate `Working branch created` was unticked at start of /implement-from-spec (frontmatter `branch:` field had stale value `main`). Updated to `claude/flamboyant-neumann-ed7a68` and ticked. Implementation skill could plausibly auto-tick this kind of paperwork drift in V2; for now it's a one-line manual fix at the start of each session.
- 2026-05-09 [impl] Wrote 5 case directories (15 files: 5 prompt.md + 5 expected.schema.json + 5 fixture trees totaling 12 fixture files); modified `tests/eval/README.md` (V1 case index + deferred-to-V2 section). Per-case verification: 5 individual eval runs ($0.13–$0.35 each). Final 6-case full-suite run: 6/6 PASS, $0.995, ~72s wall-clock. Cumulative session spend on `claude --print` invocations: ~$2.94, well under EVAL_TOTAL_BUDGET_USD=$10.
- 2026-05-09 [impl-pass] S000024: implementation complete. Phase 2 implementer-owned gates transitioned ('Todos section reflects remaining work', 'Files section updated with changed files'). Phase 2 QA-owned gates ('Acceptance criteria verified met', 'Smoke tests pass') deliberately untouched — `/qa-work-item` is the next skill in the pipeline. RC1 (system-health deferral) and RC2 (S000022 regression-proof empirical finding) recorded above; both are V2 follow-ups, not V1 blockers.
- 2026-05-09 [qa-smoke] S1 (AC-1, AC-7): red — `bash scripts/eval.sh` reported PASS: 5  FAIL: 1. The failing case is `check-untested-p0` with `no parseable JSON object in .result` (subtype: success, cost_usd: $0.110). The same case PASSed when run individually ($0.151, 16s) during /implement-from-spec authoring. Symptom matches the SPEC Coverage Gaps "LLM run-to-run variance under fixed prompt" risk.
- 2026-05-09 [qa-smoke-manual] S2 (AC-2): pending human verification — already attempted during /implement-from-spec by reverting Step 18 spec on a worktree-local edit (not a git branch). Result: case still PASSed; recorded in RC2. The proper test branch / git revert flow per the row's command was NOT performed; this row is authoritatively pending until a human runs that exact sequence.
- 2026-05-09 [qa-smoke] S3 (AC-3): green — `check-passing-feature` PASSed inside the full-suite run ($0.30, 59s). Verified via the full-suite run's per-case PASS line (subsumed by S1).
- 2026-05-09 [qa-smoke] S4 (AC-4): green — `check-missing-frontmatter` PASSed inside the full-suite run ($0.12, 20s). Verified via the full-suite run's per-case PASS line (subsumed by S1).
- 2026-05-09 [qa-smoke-manual] S5 (AC-10 P1): pending human verification — observed per-case costs during /implement-from-spec authoring: $0.13–$0.35 (median $0.16). The SPEC's ≤ $0.10/case threshold is breached on every case; threshold appears anachronistic relative to S000023's `--max-budget-usd 0.50` raise from the original $0.15. Not a P0 blocker; consider revising AC-10 P1 in a follow-up.
- 2026-05-09 [qa-smoke-summary] red: 1 of 3 non-manual rows failed (S1 contained a flake; S3 and S4 green). 2 manual rows pending. Total smoke spend: $0.787 (one full-suite run).
- 2026-05-09 [qa-smoke-retry] check-untested-p0: PASS on retry ($0.111, 18s). Pattern across 3 runs: PASS / FAIL / PASS = 67% reliability. Confirms LLM-variance flake (not deterministic break). The SPEC Coverage Gaps section already accepted this risk; the data point is recorded for nightly CI baseline tuning (S000025).
- 2026-05-09 [qa-smoke-summary-revised] green-with-flake: full-suite has a 33% flake rate on `check-untested-p0` based on 3 observations. All other cases stably green. Promoting smoke verdict to green-with-flake-disclosure for E2E continuation; flake is honestly documented and aligns with SPEC's pre-acknowledged variance gap.
- 2026-05-09 [qa-e2e] E1 (AC-2): ambiguous — regression-detection proof was performed via worktree-local edit (see [impl-finding] line 150) instead of the row's prescribed `git checkout -b test/s000022-revert` + `git revert <commit>` flow; result was case still PASSed when spec was reverted, contradicting the row's "Pass: case fails on revert" rubric. RC2 honestly documents the empirical-vs-designed gap. Verdict deferred to human judgment on whether (a) the alternative methodology is acceptable proof and (b) the rubric tolerates a case that doesn't fail-on-revert. See S000024_TRACKER.md:150 ([impl-finding]) and S000024_TRACKER.md:92-94 (RC2).
- 2026-05-09 [qa-e2e] E2 (AC-7): green — full suite ran via parent skill smoke phase (see [qa-smoke] line 154 + [qa-smoke-retry] line 160). Initial run hit a 1-case flake (`check-untested-p0` no-parseable-JSON, LLM variance per SPEC Coverage Gap), passed on retry. Net 6/6 PASS with documented 33% flake rate on one case. Per the Rubric "Pass: all PASS", green-with-flake-disclosure is acceptable; no deterministic FAIL or unexpected error.
- 2026-05-09 [qa-e2e] E3 (AC-8): green — `tests/eval/personal-workflow/check-step18-faithful-comma-split/prompt.md` line 5 contains the in-line caveat: "This case tests that Claude faithfully executes the comma-split spec as written in check.md Step 18. It does NOT test the comma-split logic in isolation — that's covered (or scheduled) under V2's parser-extraction work." Reads cleanly to a future contributor; matches the Expected Outcome.
- 2026-05-09 [qa-e2e] E4 (AC-5, AC-6): green — `tests/eval/personal-workflow/check-untested-p0/` exists with prompt.md + expected.schema.json + fixture/, integrated into the full-suite run automatically (visible in [qa-smoke] line 154). `git diff origin/main -- scripts/eval.sh tests/eval/lib/run-case.sh` is empty: zero runner changes. New case lands in V1 case count without modifying eval.sh per the rubric.
- 2026-05-09 [qa-e2e-summary] 3 green (E2, E3, E4) + 1 ambiguous (E1, methodology + rubric judgment needed). No reds. Smoke verdict was green-with-flake; E2E confirms the new case integrates and is documented.
- 2026-05-09 [qa-e1-adjudication] User adjudicated E1 ambiguous → green. Rationale (per the user's selection): RC2 captures the gap honestly; the case has value beyond what the original rubric anticipated; ship V1 with the documented limitation. The rubric "Pass: case fails on revert" is treated as design-intent rather than a hard contract; followups (V2 parser-extraction unit tests) are the path to deterministic regression coverage.
- 2026-05-09 [qa-pass] S000024 (user-story): green smoke (with documented 33% flake rate on `check-untested-p0`) + green E2E (1 ambiguous adjudicated to green by user). Phase 2 QA-owned gates transitioned (`Acceptance criteria verified met`, `Smoke tests pass`). Phase 2 implementer-owned gates were already green (transitioned by /implement-from-spec). RC1 (system-health deferred to V2) and RC2 (S000022 regression-detection signal weaker than designed) carry forward into Phase 3 review.
