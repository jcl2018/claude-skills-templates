---
name: "Self-healing contract-file reconcile for the audit skills"
type: feature
id: "F000065"
status: active
created: "2026-06-13"
updated: "2026-06-13"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-audit-self-heal"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b cj-feat-audit-self-heal`
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

- [ ] `doc-spec.sh --classify` correctly labels `absent` / `canonical` / `legacy` / `duplicate` fixtures (read-only machine block: `GENERATION=`, `POSITIONS=`, `DUPLICATE=`, `CANONICAL_PATH=`); `test-spec.sh --classify` does the same.
- [ ] `doc-spec.sh --reconcile` migrates a legacy YAML fixture (multi-row, incl. a 40+-row fixture) to a canonical 3-column Markdown table **preserving every declared row** (`path`→Doc, `purpose`→Purpose, `requirement`→Requirement; dropping `section`/`audit_class`/`front_table`), writes atomically (temp → `--validate`-clean → `mv`), keeps a `.bak`, and is idempotent on re-run (`RECONCILE: already canonical`).
- [ ] The `audit_class` asymmetry guard fires a `RECONCILE-WARN` for a `docs/*` row that was declared `operational` but whose path derives `human-doc`.
- [ ] On a `legacy`/`duplicate` classification, a plain (no-flag) audit run emits a `RECONCILE:` directive into the Stage-1 report naming the issue + remedy (`run /CJ_doc_audit --reconcile`) and performs **no write** (read-mostly preserved); `--reconcile` is the only new write path and is opt-in.
- [ ] `/CJ_doc_audit` on a legacy fixture surfaces the `RECONCILE:` directive; `/CJ_doc_audit --reconcile` performs the migration; a canonical repo emits **zero** reconcile lines. Symmetric coverage for `/CJ_test_audit`.
- [ ] The canonical contract-file template (required vs optional files, canonical position, format) is documented in each audit's USAGE.md and the `spec/doc-spec.md` / `spec/test-spec.md` prose.
- [ ] `scripts/validate.sh` stays green (0/0) and the live workbench classifies `canonical` with no reconcile noise; new `tests/*.test.sh` are registered in `scripts/test.sh` AND `spec/test-spec-custom.md`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Phase 1 (S000109): recover the old YAML doc-spec grammar from git history (root `doc-spec.md` @ pre-F000057, e.g. `716a537`); build `doc-spec.sh --classify` (read-only) + `--reconcile` (migrate-preserving + atomic + `.bak` + `audit_class` asymmetry guard); confirm the legacy test-spec signature from git history and add `test-spec.sh --classify` (+ `--reconcile` scoped to whatever legacy form exists / dedup).
- [ ] Phase 2 (S000109): wire the audit skills' Step-2 reconcile directive + the opt-in `--reconcile` flag for both `/CJ_doc_audit` + `/CJ_test_audit` (read-mostly default; advisory `RECONCILE:` directive like D000034's `REMEDIATION:`); document the canonical contract-file template in the audits' USAGE.md + the spec prose; add classify + reconcile fixtures for both engines registered in `scripts/test.sh` + `spec/test-spec-custom.md`; verify the workbench baseline classifies `canonical` with zero reconcile noise and the suite is green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-13: Created. Self-healing contract-file reconcile: the two audit skills already seed a MISSING contract file but dead-stop on one that exists in a non-canonical shape (legacy YAML, duplicated, wrong-position). This feature makes `/CJ_doc_audit` / `/CJ_test_audit` idempotent across *generations* of the contract — detect + classify, emit a `RECONCILE:` directive on a plain run, and migrate legacy→canonical (declared-rows-preserving) behind an opt-in `--reconcile` flag. Single feature, one atomic child story (Approach A).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/doc-spec.sh` (new `--classify` + `--reconcile` subcommands), `scripts/test-spec.sh` (symmetric `--classify` + `--reconcile`)
- `skills/CJ_doc_audit/SKILL.md`, `skills/CJ_doc_audit/USAGE.md`, `skills/CJ_test_audit/SKILL.md`, `skills/CJ_test_audit/USAGE.md` (Step-2 reconcile directive + opt-in `--reconcile` flag + canonical-template doc section)
- `spec/doc-spec.md`, `spec/test-spec.md` (canonical contract-file template prose)
- `skills-catalog.json` (audit-skill flag/version bump — sensitive surface)
- `tests/*.test.sh` (classify + reconcile fixtures for both engines), `scripts/test.sh` (register + integration-fixture drills), `spec/test-spec-custom.md` (register the new test units)
- `CLAUDE.md`, `CHANGELOG.md` (convention/version notes)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The real defect behind the earlier "missing docs" misdiagnosis is NOT the genuinely-missing case (D000034/PR #268 already added a remediation pointer for that) — it is the non-canonical-but-present case: a `doc-spec.md` still on the old YAML generation gets rejected with `[doc-sync-no-config] … has no registry table` and a dead stop, with no reconcile and no actionable next step.
- The audit has **no AskUserQuestion tool** and runs **inline inside QA** (`/CJ_qa-work-item` Step 8.6c) as a subagent that cannot prompt — so "prompt to update" must be **report-borne + an opt-in flag**, not a true interactive AUQ. Same constraint that shaped D000034/PR #268.
- The operator separated the one-off fix from the durable capability and chose the capability ("I don't need you to do any kind of migration here") — and reset hard when the frame was wrong ("Actually, let's revert from scratch") rather than letting a half-right migration tool ride. The feature is the *right abstraction* (idempotent-across-generations audit), not a passing one-off patch.
- `legacy` must be distinguished from `genuinely malformed`: only a file matching an old-generation signature (doc-spec: a fenced ```yaml block with `schema_version:` + `docs:`) is reconcilable; a malformed canonical file still halts `[doc-sync-no-config]`.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-13 — Approach A: reconcile + migrate, flag-gated (CHOSEN). The audits classify each contract file (canonical / legacy / duplicate / wrong-position / absent); absent → seed (today's behavior); non-canonical → emit a `RECONCILE:` directive + an opt-in `--reconcile` migrates legacy→canonical preserving declared rows, dedups, reports. Rejected B (auto re-seed + prompt — destructive: re-seed is the ~10-row template, not the repo's declared rows; a 47-doc registry would lose all declarations) and C (interactive AUQ in the audit — only works standalone, breaks the read-mostly / no-AUQ design). Summary: the only option preserving declared rows that works identically standalone AND inline-in-QA while staying read-mostly.
- [decision] 2026-06-13 — "Prompt to update" = report directive + opt-in `--reconcile` flag, NOT an interactive AUQ (D1). The in-QA subagent cannot prompt; the directive is advisory (like D000034's `REMEDIATION:`), surfaces in the per-stage report + QA digest, and does NOT crash the audit or flip QA red — the cj_goal post-QA checkpoint owns Continue/Halt/act. Summary: report-borne prompt, opt-in write.
- [decision] 2026-06-13 — Duplicate handling is report-only in v1, no auto-delete (D2). `--reconcile` reconciles the canonical-position copy and reports the redundant one (`RECONCILE-WARN: duplicate contract at <root path>; remove after verifying`); a future `--reconcile --prune-duplicates` could delete it after the canonical write verifies — deferred. Root-only stays advisory `wrong-position` (root is an accepted position), relocation is opt-in future work. Summary: safe-by-default, never deletes on a plain reconcile.
- [decision] 2026-06-13 — Migration parser stays awk/sed, POSIX-shell / bash-3.2, no python/yaml dep (D3). Matches `doc-spec.sh` / `test-spec.sh`. The old-generation YAML grammar is recoverable from git history (root `doc-spec.md` @ pre-F000057, e.g. `716a537`) — the converter's input grammar. Summary: no new runtime dependency.
