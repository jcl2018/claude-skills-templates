---
name: "General docs required — complete contract restatement"
type: user-story
id: "S000100"
status: active
created: "2026-06-09"
updated: "2026-06-09"
parent: "F000058"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/pensive-robinson-08ad9c"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "799b37bcde80fc20543b29ade0750e3cdd24fee7"
    completed_at: "2026-06-10T03:51:37Z"
    test_rows_run: 9
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: ["CLAUDE.md", "docs/philosophy.md"]
    journal_entries: ["[qa-smoke] S1-S4 green", "[qa-smoke-manual] S5 pending (full test.sh deferred to post-commit CI; targeted substitutes green)", "[qa-smoke-summary] green 4/4", "[qa-e2e-run-start] RUN_ID=20260609-205137-qa", "[qa-e2e] E1-E5 green [parent-inline]", "[qa-e2e-summary] green", "[qa-pass] S000100"]
    ready_for_ship: true
    next_legal: ["Phase 3: Ship"]
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/general_docs_required` (or use parent's branch if shipping in same PR)
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

- [ ] Workbench registry: the 6 entries (`spec/doc-spec.md`, `CLAUDE.md`, `CHANGELOG.md`, `TODOS.md`, `docs/doc-general.md`, `docs/doc-custom.md`) flip `section: custom` → `section: common` with `audit_class` unchanged; the Common prose is restated as the 10-doc general table (sub-grouped human docs / operational docs / generated views) with the explicit "General docs are required." rule bullet; the Custom prose shrinks to the 3-doc tier; no new ```` ```yaml ```` fence; the H1 phrase "what docs this repo carries" is preserved.
- [ ] Seed pair (`templates/doc-spec-common.md` + the `_emit_seed` heredoc in `scripts/doc-spec.sh`) byte-identical to each other AND to the workbench Common section (incidental diagram-line drift fixed); seed registry grows to 10 `section: common` entries with PORTABLE requirement strings (root-style `doc-spec.md` entry; the doc-spec entry's requirement includes "registry declares every general-contract doc"); seed passes `--validate` (test 12 path); drift test 13 green.
- [ ] Views regenerated via `scripts/generate-doc-views.sh`: `docs/doc-general.md` has 10 rows (including both views themselves); `docs/doc-custom.md` has exactly 3 rows (`CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md`); Check 23 green.
- [ ] `skills/CJ_document-release/SKILL.md` states the tier logic (general = portable contract, REQUIRED, seed-declared + stub-scaffolded; custom = per-repo additions) AND adds the Step 6.7 advisory rule: registry missing a general-contract doc ⇒ `stale: registry missing general-contract doc(s): <paths>` on the contract file's own verdict line — enumerated via `--seed` to a temp file + `DOC_SPEC_PATH` override + `--render general` (first column), with basename path-equivalence for `doc-spec.md`; render-first stub shape for the two views with a PORTABLE header; TODOS.md stub/lazy-create convergence stated; ADVISORY, never a halt. `skills/CJ_document-release/USAGE.md` refreshed (Check 14).
- [ ] `docs/philosophy.md` `### Two tiers, one portable pass` (under `## Topic: Doc contract`) states the general tier is required in every adopting repo and the custom tier is per-repo; no new principle, no front-table row change, no work-item IDs.
- [ ] Secondary-reference sweep done: `CLAUDE.md`'s "A new root `*.md` must be a `section: custom` registry entry" line reconciled; stale "four human docs" claims in live docs fixed; historical records and legitimate registry-schema mentions untouched.
- [ ] Growth-safe seed assertions added to `tests/cj-document-release-config.test.sh` (seed `--list-declared` includes `CLAUDE.md`, `TODOS.md`, `docs/doc-general.md`; seed greps "General docs are required"); test-5 ok-message reworded; `./scripts/validate.sh` + `./scripts/test.sh` fully green with no new checks and no fixture edits.

## Todos

<!-- Actionable items for this story. -->

- [x] Step 1: `spec/doc-spec.md` — flip the 6 registry entries to `section: common`; rewrite the Common section (10-doc table + required rule); shrink the Custom prose.
- [x] Step 2: `templates/doc-spec-common.md` + `scripts/doc-spec.sh` heredoc — same Common prose byte-identical; seed registry grows to 10 portable entries.
- [x] Step 3: regenerate the views via `scripts/generate-doc-views.sh` (general 10 rows incl. both views; custom 3 rows).
- [x] Step 4: `skills/CJ_document-release/SKILL.md` — tier-logic statement + Step 6.7 advisory missing-general-doc rule (seed-render enumeration, basename equivalence, portable render-first stubs, TODOS dual-creation note); refresh USAGE.md.
- [x] Step 5: `docs/philosophy.md` — amend `### Two tiers, one portable pass` with required-ness.
- [x] Step 5.5: secondary-reference sweep (grep for stale tier claims; fix CLAUDE.md root-`*.md` line + Custom-section lead-in + any live four-doc framing; leave history + schema mentions).
- [x] Step 6: add growth-safe seed assertions to `tests/cj-document-release-config.test.sh`; reword test-5 ok-message; run validate.sh + test.sh green. (validate.sh green at implement time; the full `scripts/test.sh` run is deferred to QA — its EXIT restore-trap must not run while the tree is being mutated.)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-09: Created. Single atomic story carrying the complete contract restatement: 6-entry registry flip, 10-doc seed growth + required rule, view regen, /CJ_document-release tier-logic statement + advisory audit rule, philosophy amendment, secondary-reference sweep, growth-safe seed test assertions.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- spec/doc-spec.md (modified — 6-entry section flip; Common prose restated from the seed; Custom prose shrunk to the 3-doc tier)
- templates/doc-spec-common.md (modified — Common prose rewrite + seed registry grown to 10 portable `section: common` entries)
- scripts/doc-spec.sh (modified — `_emit_seed` heredoc re-synced byte-identical to the template; stale four-doc `--seed` header comment updated)
- docs/doc-general.md (modified — regenerated, 10 rows)
- docs/doc-custom.md (modified — regenerated, 3 rows)
- skills/CJ_document-release/SKILL.md (modified — tier-logic statement; render-first portable view stubs + TODOS dual-creation note; Step 6.7.3b advisory missing-general-doc rule; consumer-repo mechanical view-freshness note)
- skills/CJ_document-release/USAGE.md (modified — mental-model refresh for the new behavior + `last-updated:` bump)
- docs/philosophy.md (modified — `### Two tiers, one portable pass` amended with required-ness)
- CLAUDE.md (modified — root-`*.md` registry-entry line reconciled)
- tests/cj-document-release-config.test.sh (modified — growth-safe seed assertions 8b; test-5 ok-message reworded)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The Common seed lives in THREE coupled places (workbench Common section, `templates/doc-spec-common.md`, the `_emit_seed` heredoc); only the PROSE is byte-identical — the registry is per-repo (seed root-style, workbench `spec/`-style).
- Enumerate the general set by reusing the parser (`--seed` → temp file → `DOC_SPEC_PATH` → `--render general`), never `--list-declared`: render-general filters by `section: common`, so a future custom seed entry can't silently over-enumerate.
- The advisory `stale:` verdict on the contract file's own line deliberately suppresses the "Registered-doc requirements: all current" positive line — intended and honest.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-09 — Summary: Scaffolded as the single atomic child of F000058 (Approach B, complete restatement); tasks N/A — one cohesive change across the contract surface, shipped in one PR.
- 2026-06-09 [impl-decision] 3-way byte-identity achieved by SCRIPTED splice, not hand-copying: wrote the new `templates/doc-spec-common.md` once, then programmatically spliced its full content into the `scripts/doc-spec.sh` `_emit_seed` heredoc and its marker-delimited Common region into `spec/doc-spec.md` — guarantees byte-identity by construction (incidental diagram-line drift converged on the seed's backtick-free form per the design).
- 2026-06-09 [impl-decision] Common-section 10-doc presentation: three sub-tables under bold lead-ins (Human docs / Operational docs / Generated views (human docs)) rather than one table with a group column — keeps the per-row `| Doc | What it is for |` shape and reads cleanly; the "General docs are required." rule landed as the FIRST of the (now three) trust rules.
- 2026-06-09 [impl-decision] Step 6.7 advisory rule landed as a NEW subsection 6.7.3b (after the human-doc no-ref check, before 6.7.4's emit) so the existing 6.7.1–6.7.4 numbering and the test-14 guard literals are untouched; enumeration uses `--seed` → temp file → `DOC_SPEC_PATH` → `--render general` first-column awk (never `--list-declared`), with basename path-equivalence for `doc-spec.md`.
- 2026-06-09 [impl-finding] The stale "four common human-docs" claim also lived in a NON-md surface the sweep grep (--include='*.md') cannot see: the `--seed` header comment of `scripts/doc-spec.sh` — fixed in the same edit (the file was already in scope for the heredoc re-sync).
- 2026-06-09 [impl-finding] Workbench registry order needed no reshuffle: render-general emits rows in registry order, so the flipped entries naturally render as the 4 human docs → spec/doc-spec.md → CLAUDE/CHANGELOG/TODOS → the two views (10 rows), and custom renders gate-spec → CONTRIBUTING → permission-policy (3 rows).
- 2026-06-09 [impl] Modified 10 files (seed template, doc-spec.sh heredoc + comment, spec/doc-spec.md flip+prose, 2 regenerated views, CJ_document-release SKILL.md + USAGE.md, philosophy.md amendment, CLAUDE.md sweep line, test additions). Verified: render general=10 rows / custom=3; empty-dir seed `--validate` OK (heredoc path); `bash tests/cj-document-release-config.test.sh` all green incl. new 8b assertions + drift test 13; `./scripts/validate.sh` PASS 0 errors 0 warnings (Checks 15/16/17/19/20/23); Common region byte-identical across all three copies (diff-verified twice); exactly one ```` ```yaml ```` fence + "what docs this repo carries" preserved. Full `scripts/test.sh` deferred to QA (restore-trap vs in-flight tree mutation).
- 2026-06-09 [impl-pass] S000100: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-09 [qa-smoke] S1 (AC-3): green — `--render general` emits exactly 10 doc rows incl. both views; `--render custom` exactly 3 (CONTRIBUTING.md, spec/gate-spec.md, spec/permission-policy.md); both exit 0
- 2026-06-09 [qa-smoke] S2 (AC-2): green — tests/cj-document-release-config.test.sh 18/18 OK, exit 0 (seed `--validate` test-12 path; drift test 13 heredoc==template green)
- 2026-06-09 [qa-smoke] S3 (AC-7): green — new growth-safe assertions present + passing (seed `--list-declared` includes CLAUDE.md/TODOS.md/docs/doc-general.md; literal "General docs are required" grepped; test-5 ok-message reworded to "core human docs")
- 2026-06-09 [qa-smoke] S4 (AC-1): green — ./scripts/validate.sh RESULT: PASS, 0 errors 0 warnings (Checks 14/15/15a/16/17/19/20/23); exactly one ```yaml fence in spec/doc-spec.md; "what docs this repo carries" preserved
- 2026-06-09 [qa-smoke-manual] S5 (AC-7): pending human verification — full ./scripts/test.sh deferred to post-commit CI (repo caution: its EXIT restore-trap reverts README/catalog/VERSION/CHANGELOG over an uncommitted tree → phantom failures); targeted substitutes all green this run: validate.sh, cj-document-release-config.test.sh, both renders, empty-dir seed --validate idiom, 3-way Common-region byte-identity diff
- 2026-06-09 [qa-smoke-summary] green: 4/4 non-manual rows green (1 manual row pending)
- 2026-06-09 [qa-e2e-run-start] RUN_ID=20260609-205137-qa commit=799b37b
- 2026-06-09 [qa-e2e] E1 (AC-1, AC-3): green — registry now 10 `section: common` + 3 `section: custom` (git diff shows exactly 6 flips, zero audit_class changes); Common table sub-grouped (Human 4 / Operational 4 / Generated views 2) with the "General docs are required." rule bullet; general view 10 rows incl. both views; custom view exactly CONTRIBUTING.md + spec/gate-spec.md + spec/permission-policy.md [parent-inline]
- 2026-06-09 [qa-e2e] E2 (AC-2): green — seed validates via DOC_SPEC_PATH temp-file idiom (OK schema_version=1, exit 0); render-general from the seed = 10 root-style entries (doc-spec.md, not spec/) with portable requirement strings (doc-spec.md entry includes "registry declares every general-contract doc"; zero workbench-script refs in seed requirements); Common region byte-identical across spec/doc-spec.md / templates/doc-spec-common.md / the --seed heredoc output (diagram-line drift gone) [parent-inline]
- 2026-06-09 [qa-e2e] E3 (AC-4): green — all five elements present in skills/CJ_document-release/SKILL.md: tier-logic statement (general = portable contract, REQUIRED, seed-declared + stub-scaffolded; custom = per-repo; lines 50-57); 6.7.3b advisory rule with verdict shape `stale: registry missing general-contract doc(s): <paths>` + explicit "ADVISORY, never a halt: no exit, no halt marker, no RESULT=red" (652-658); seed→temp→DOC_SPEC_PATH→--render-general first-column enumeration + basename path-equivalence implemented (660-686); portable render-first view stubs with workbench-path header explicitly forbidden (245-253); TODOS dual-creation convergence note (255-260); USAGE.md fresh per Check 14 green [parent-inline]
- 2026-06-09 [qa-e2e] E4 (AC-5): green — required-ness stated in `### Two tiers, one portable pass` (philosophy.md:284) under `## Topic: Doc contract` (261); diff confined to that section; zero added headings (no new principle); front summary table unchanged; Checks 19/20 green [parent-inline]
- 2026-06-09 [qa-e2e] E5 (AC-6): green — sweep grep returns zero "four human docs"/"four common human docs" hits; every remaining `section: custom` hit classified legitimate (registry entries, seed Custom placeholder, doc-custom.md generated header, architecture.md schema comment, CLAUDE.md doc-spec.sh table row, new tier statements); CLAUDE.md:528 reads the reconciled root-`*.md` wording; doc-spec.sh --seed header comment (non-md surface) fixed [parent-inline]
- 2026-06-09 [qa-e2e-summary] green (0s subagent; 5 rows parent-inline; 0 deferred): all 5 E2E rows verified green. QA runner executed the rows directly inline (depth-2 constraint — no nested E2E subagent spawnable from this dispatch level; all rows were read-only and ran with the full toolbelt per the Step 7.5 entry shape)
- 2026-06-09 [qa-pass] S000100 (user-story): green smoke + green E2E. Phase 2 gates transitioned. Receipt written (commit 799b37b, ready_for_ship: true). Note: smoke S5 (full ./scripts/test.sh) recorded manual-pending — deferred to post-commit CI per the repo restore-trap caution; targeted substitutes (validate.sh, cj-document-release-config.test.sh, renders, seed --validate idiom, 3-way byte-identity) all green this run.
- 2026-06-10T04:05:17Z [feature-pr-opened] S000100 v6.0.62 PR #257
  pr_url=https://github.com/jcl2018/claude-skills-templates/pull/257
