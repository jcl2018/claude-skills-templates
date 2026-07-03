---
name: "CI cadence taxonomy split (V2) + Windows nightly move"
type: user-story
id: "S000125"
status: active
created: "2026-07-03"
updated: "2026-07-03"
parent: "F000075"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/eloquent-cohen-54b476"
branch: "claude/eloquent-cohen-54b476"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "8305e4cae1c5e9978d3f1118c9fc1d21efa371a1"
    completed_at: "2026-07-03T10:01:17Z"
    test_rows_run: 8
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-8", "AC-9"]
    ac_ids_uncovered: []
    ac_ids_deferred_post_ship: ["AC-7"]
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["qa-smoke S1-S5 green", "qa-smoke-summary green 5/5", "qa-e2e E1/E2/E4 green", "qa-e2e-deferred E3 (AC-7) post-ship", "qa-e2e-summary green", "qa-audit deferred"]
    ready_for_ship: true
    next_legal: ["ship"]
    notes: "Smoke 5/5 green. E2E E1/E2/E4 green (E1 with a documented full-test.sh env caveat: the full bash scripts/test.sh could not complete cleanly locally — killed run, 7 nested-validate.sh-capture FAILs all reproduced GREEN directly and none in F000075 scope; jq-CRLF Git-Bash quirk. validate.sh PASS + tests/test-spec.test.sh + tests/test-run.test.sh + scripts/test-deploy.sh all exit 0 + shellcheck clean. CI/ubuntu is the authoritative full-suite gate). E3/AC-7 is post-ship (windows.yml trim + new windows-nightly.yml only observable on origin/main post-merge) — deferred, not uncovered. Audits DEFERRED (DEFER_AUDIT: true) to the orchestrator's post-sync run; overlays verified in-sync inline; README.md regenerated to clear Check 25."
---

<!-- Prerequisite: this atomic story derives directly from the parent feature's
     /office-hours session. The parent's design is sufficient context; DESIGN.md
     here is a brief stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch (use parent's branch — shipping in the same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (N/A — atomic story carrying the feature's eight deliverables)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
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
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any — N/A)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] Portable taxonomy bumped to V2 `{workflow, CI-push, CI-nightly}` in both byte-identical copies; `cmp -s` seed==file green.
- [ ] Every `scripts/test-spec.sh` category-enum site updated; `--check-structure` folder checks derive from the distinct declared categories.
- [ ] `spec/test-spec-custom.md` `categories:` re-keyed to `CI-push` + a `windows-deploy` `CI-nightly` row added.
- [ ] Folders/docs renamed (`tests/CI/`→`tests/CI-push/` + new `tests/CI-nightly/`; `docs/tests/CI/`→`docs/tests/CI-push/` + `docs/tests/CI-nightly/windows-deploy.md`; `docs/tests/index.md` re-rendered) and `spec/doc-spec-custom.md` registry rows rewritten in the implementation commit → Check 15/15a green.
- [ ] `scripts/test-run.sh` enum + error string updated; `--category CI-push`/`CI-nightly` select correctly via `--dry-run`.
- [ ] `windows.yml` runs only `windows-smoke.sh` on PR; new `windows-nightly.yml` runs `test-deploy.sh` on `windows-latest` on schedule + dispatch.
- [ ] Both cj_test skills' SKILL.md + USAGE.md document V2; `tests/test-spec.test.sh` + `tests/test-run.test.sh` updated (incl. the negative enum-rejection test); `CLAUDE.md` updated via doc-sync.
- [ ] Full `test.sh` green + `validate.sh` green (Checks 15/15a, 24, 26, 28) + shellcheck clean.

## Todos

<!-- Actionable items for this story. -->

- [x] D1 — portable seed + parser taxonomy V2 (`spec/test-spec.md` + `scripts/test-spec.sh` seed heredoc, both copies edited in lockstep, `cmp -s` green; every enum site; `--check-structure` folders DERIVE from declared categories)
- [x] D2 — contract overlay rows (`spec/test-spec-custom.md` `categories:` re-keyed CI→CI-push + `windows-deploy` CI-nightly row; block-comment V1→V2; `runners:` axis unaffected)
- [x] D3 — folders + docs + `spec/doc-spec-custom.md` registry rewrite in the code commit (Check 15/15a green)
- [x] D4 — `scripts/test-run.sh` enum + error string (+ help text) → V2
- [x] D5 — CI workflows (`windows.yml` trimmed to fast smoke; new `windows-nightly.yml` deploy suite; matching `ci-windows-nightly` unit row)
- [x] D6 — both cj_test skills' SKILL.md + USAGE.md + `skills-catalog.json` descriptions → V2
- [x] D7 — tests (`tests/test-spec.test.sh` + `tests/test-run.test.sh`: V2 enum, derive-from-declared folder case, CI-push/CI-nightly selection, updated negative enum-rejection test)
- [ ] D8 — convention docs (`CLAUDE.md` V1→V2 prose, via the later doc-sync step — deferred per orchestrator flow); Check 15/15a confirmed green now

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Atomic story carrying the eight deliverables of F000075 (CI cadence taxonomy V2 + Windows nightly move).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `spec/test-spec.md` (modified — V2 seed prose), `scripts/test-spec.sh` (modified — seed heredoc + enum sites + derive-from-declared `--check-structure`), `spec/test-spec-custom.md` (modified — `categories:` re-key + `windows-deploy` row + `ci-windows-nightly` unit row + prose tables), `spec/doc-spec-custom.md` (modified — `docs/tests/CI-push/*` rows + `docs/tests/CI-nightly/windows-deploy.md` row)
- `scripts/test-run.sh` (modified — V2 enum + error + help)
- `tests/CI/`→`tests/CI-push/.gitkeep` (renamed + V2 wording), new `tests/CI-nightly/.gitkeep`
- `docs/tests/CI/*.md`→`docs/tests/CI-push/*.md` (regenerated), new `docs/tests/CI-nightly/windows-deploy.md`, `docs/tests/index.md` (re-rendered)
- `docs/tests/ci.md` + `docs/test-catalog.md` (regenerated — new `ci-windows-nightly` unit row)
- `.github/workflows/windows.yml` (trimmed to windows-smoke), new `.github/workflows/windows-nightly.yml`
- `skills/CJ_test_audit/SKILL.md` + `USAGE.md`, `skills/CJ_test_run/SKILL.md` + `USAGE.md` (V2 taxonomy), `skills-catalog.json` (both descriptions → V2)
- `tests/test-spec.test.sh`, `tests/test-run.test.sh` (V2 + derive-from-declared + CI-push/CI-nightly selection + negative enum-rejection)
- `CLAUDE.md` (V1→V2 prose — deferred to doc-sync)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The category name IS the cadence, so no new `--cadence` flag is needed — `--category CI-push|CI-nightly` is the entire selection API.
- Both byte-identical copies (`spec/test-spec.md` + the `scripts/test-spec.sh --seed` heredoc) must be edited in lockstep or `tests/test-spec.test.sh`'s `cmp -s` assertion fails.
- `--check-structure` folder checks must derive from declared categories, not a hardcoded three-set, or the V2 seed forces an empty `tests/CI-nightly/` on every consumer.
- The `spec/doc-spec-custom.md` registry rewrite is CONTRACT editing that belongs in the code commit, not doc-sync — otherwise Check 15/15a hard-fails.
- Do NOT rename the lowercase `docs/tests/ci.md` (the `ci` FAMILY render) — case-insensitive-FS trap; it is unrelated to the `CI` category dir.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-03 — Single atomic story carries all eight deliverables. Summary: the feature is one coherent change; per the design's Next Steps the deliverables implement together, so decomposing into multiple stories would add ceremony without separable value.
- [finding] 2026-07-03 — `--check-structure` must derive folders from declared categories (spec-review blocker). Summary: hardcoding three categories would force an empty `tests/CI-nightly/` on THIS repo and every consumer that upgrades the seed; deriving from the overlay's `categories:` rows fixes it.
- [finding] 2026-07-03 — The `spec/doc-spec-custom.md` rewrite must land in the implementation commit, not Step 5.5 doc-sync. Summary: the `docs/tests/{workflow,CI}/*.md` rows are registry entries; leaving them stale orphans declared rows and undeclares new on-disk docs → Check 15/15a hard fail.
- 2026-07-03 [impl-decision] Kept `test-deploy` (CI-push) AND `windows-deploy` (CI-nightly) as two rows running the identical `bash scripts/test-deploy.sh` locally, per SPEC tradeoff — same script, two distinct CI contexts (platform + cadence); the two per-test docs state the reason (no `platform:` field yet). Rejected collapsing to one row.
- 2026-07-03 [impl-decision] Adding `.github/workflows/windows-nightly.yml` required a matching `units:` row (`ci-windows-nightly`) in `spec/test-spec-custom.md` — Check 24's reverse sweep flags any workflow file with no unit row. Also updated the `ci-windows` row purpose (now smoke-only) + the overlay's prose workflow table. Rejected leaving it undeclared.
- 2026-07-03 [impl-finding] `--check-structure` derive-from-declared (SPEC decision 1) is implemented by computing `_CS_DISTINCT_CATS` (LC_ALL=C sort -u of the declared `categories:` rows' 2nd column) and iterating THAT in checks (b)/(c)/(d) instead of a hardcoded `for _cs_cat in workflow CI`. The closed enum stays enforced at `--validate`; the folders/docs are required only for categories the repo actually declares.
- 2026-07-03 [impl-finding] Adding the `ci-windows-nightly` unit row + editing the `test-test-spec` unit purpose made the generated `docs/tests/ci.md` + `docs/tests/test.md` + `docs/test-catalog.md` stale; regenerated via `test-spec.sh --render-docs` so Check 26 stays green (these are generated surfaces, not hand-edited).
- 2026-07-03 [impl-finding] The local Git-Bash environment is very slow at subprocess spawning (the documented "slow validate.sh" quirk): `test-spec.sh` subcommands each take ~15-20s and `test-run.sh` category dry-runs ~60-80s. Self-checks needed 120-180s timeouts; not a code defect (verified a command completes correctly given enough time).
- 2026-07-03 [impl] Implemented the eight deliverables of S000125 (CI cadence taxonomy V1→V2 {workflow, CI-push, CI-nightly} + Windows nightly move): edited the byte-identical seed pair in lockstep (cmp -s green), every parser enum site, the derive-from-declared `--check-structure`, the overlay `categories:` + `runners`-adjacent unit rows, the folder/doc renames + doc-spec registry rewrite (Check 15/15a green), the runner enum, the two CI workflows, both cj_test skills + catalog, and both test files. CLAUDE.md prose deferred to doc-sync.
- 2026-07-03 [impl-pass] S000125: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files). Deterministic self-checks green: cmp -s seed==file, --validate, --list-categories (V2), --check-structure (derive-from-declared), --check-coverage, --render-docs --check, doc-spec --check-on-disk, and --category CI-push/CI-nightly dry-runs. QA (smoke + full suite + shellcheck) is the next phase.
- 2026-07-03 [qa-e2e-deferred] E3 (AC-7): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); windows.yml trimmed trigger set + new windows-nightly.yml only observable on origin/main after the PR merges; not run pre-ship
- 2026-07-03 [qa-smoke] S1 (AC-1): green — cmp -s seed==spec/test-spec.md byte-identical (exit 0) AND test-spec.sh --validate → OK schema_version=1
- 2026-07-03 [qa-smoke] S2 (AC-2, AC-4): green — --list-categories shows V2: validate/suite/test-deploy/windows under CI-push, windows-deploy under CI-nightly, goal-task-eval/e2e-local under workflow
- 2026-07-03 [qa-smoke] S3 (AC-3, AC-2): green — --check-structure findings=0; checks a-e pass; folder checks (b/c/d) derive from the distinct declared categories (CI-nightly/CI-push/workflow), not a hardcoded 3-set
- 2026-07-03 [qa-smoke] S4 (AC-6): green — test-run.sh --category CI-push --dry-run plan={validate,suite,test-deploy,windows}; --category CI-nightly --dry-run plan={windows-deploy}; old V1 'CI' rejected with the updated V2 message + exit 2
- 2026-07-03 [qa-smoke] S5 (AC-5): green — validate.sh Check 15/15a doc-spec registry declared⇔on-disk (38 docs); Checks 24/26/28 green. NOTE: first validate.sh run was RED on Check 25 (README.md stale vs generate-readme.sh) because the D6 skills-catalog.json V2 descriptions (CJ_test_audit/CJ_test_run) were not regenerated into README; QA regenerated README.md via `generate-readme.sh` (deterministic, doc-only, whitelisted generated surface) → validate.sh now fully PASS (Errors: 0)
- 2026-07-03 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-07-03 [qa-e2e-run-start] RUN_ID=20260703-014422-4063 commit=8305e4c
- 2026-07-03 [qa-e2e] E2 (AC-6): green — test-run.sh --category CI-push --dry-run → {validate,suite,test-deploy,windows}; --category CI-nightly --dry-run → {windows-deploy}; cost tiers honored (all free); no "outside taxonomy" error on the valid categories; old V1 'CI' correctly rejected (exit 2). Rubric met exactly. [parent-inline]
- 2026-07-03 [qa-e2e] E4 (AC-8): green — the four cj_test docs (CJ_test_audit + CJ_test_run × SKILL/USAGE) all describe {workflow, CI-push, CI-nightly} + --category CI-push|CI-nightly; no stale V1 {workflow, CI} category closed-set in any of them. CLAUDE.md still carries 3 V1 category refs (lines 108/111/517) but that is DEFERRED to Step 5.5 doc-sync by design (story AC + Todo D8 + impl journal); the orchestrator's post-sync doc audit will catch/confirm the CLAUDE.md V2 update. E4's skill-doc scope is green. [parent-inline]
- 2026-07-03 [qa-e2e] E1 (AC-1..6,9): green (with documented env caveat) — validate.sh PASS (Errors:0, Warnings:0; Checks 15/15a/24/25/26/27/28/29 all PASS), shellcheck clean (exit 0), AND the two F000075-exercising suites green: tests/test-spec.test.sh (PASS: test-spec, exit 0 — V2 list/seed/check-structure derive-from-declared + closed-enum HALT) and tests/test-run.test.sh (exit 0 — CI-push/CI-nightly dry-run selection + legacy 'CI' exit-2). scripts/test-deploy.sh exit 0 (All tests passed). CAVEAT: the full `bash scripts/test.sh` could NOT complete cleanly locally — the background run was KILLED and accumulated 7 FAIL lines, ALL from nested-validate.sh-capture guards (S000094 Check21 ×2, S000096 Check24 ×2, F000060 Check24 ×2, Check17-negative ×1) truncated by the documented Git-Bash jq-CRLF nested-capture quirk (MEMORY: local-jq-cr-quirk). Each was reproduced GREEN by running the guard's exact `$(bash scripts/validate.sh 2>&1)` capture directly (all required banners+PASS lines present); NONE of these guards touch any surface F000075 changes (permission-policy/Check21/gate-marker). Killed-run pollution (skills/zzz-test-scaffold/, spec/STRAY.md) was cleaned from the tree. Verdict: the deterministic F000075 coverage is green; the full-suite incompleteness is env, not code — CI (ubuntu) is the authoritative full-suite gate. [parent-inline]
- 2026-07-03 [qa-e2e-summary] green (0s subagent; 3 rows parent-inline; 1 deferred): E1/E2/E4 green (E1 with the full-test.sh env caveat above); E3 post-ship deferred to post-merge. Depth-2 leaf QA — all E2E run inline (no subagent dispatch).
- 2026-07-03 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none(ci-windows-nightly already present+validated; Check24 findings=0),doc-spec-custom:none(CI-push/CI-nightly doc rows already present+validated; Check15/15a green),+README.md-regenerated(Check25 fix) (Step 8.6a/8.6b verified inline — both overlays already reflect this work-item's changes; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-07-03 [qa-pass] S000125 (user-story): green smoke (5/5) + green E2E (E1/E2/E4; E1 with a documented full-test.sh env caveat — CI is the authoritative full-suite gate) + 1 E2E row (E3/AC-7) deferred to post-merge (post-ship). Phase 2 QA-owned gates transitioned (Acceptance criteria verified met + Smoke tests pass); post-ship AC-7 awaits post-merge verification (see [qa-e2e-deferred] above).
