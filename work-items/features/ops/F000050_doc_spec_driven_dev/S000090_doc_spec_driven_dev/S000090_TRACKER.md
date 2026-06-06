---
name: "doc-spec.md doc-driven development (12-step migration + 3 retirements)"
type: user-story
id: "S000090"
status: active
created: "2026-06-06"
updated: "2026-06-06"
parent: "F000050"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/pedantic-agnesi-68fa3f"
blocked_by: ""
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Prerequisite: design distilled from the parent feature's /office-hours session.
     This is the single implementable story carrying the full SPEC + TEST-SPEC for
     F000050's 12-step sequence. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/doc_spec_driven_dev` (uses parent's branch — shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story: one cohesive doc-spec migration delivered via the ordered 12-step sequence; no parallel sub-units warrant separate task dirs)

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

- [ ] `doc-spec.md` authored at root: portable Common + repo Custom + a single fenced ```yaml registry (schema_version 1; docs[] with path/section/audit_class/purpose/requirement; audit_class enum {human-doc, operational}), migrating the two `CLAUDE.md` manifests + `cj-document-release.json` content into it.
- [ ] `doc/` trio renamed to `docs/` via tracked `git mv` (philosophy.md / architecture.md / workflow.md, lowercase, singular workflow); all 41 work-item refs scrubbed; ASCII charts present; human-facing rewrite.
- [ ] `README.md` brought to spec (folder-structure + getting-started naming the major workflows; no work-item refs).
- [ ] `scripts/validate.sh` Checks 15/15a/15b/16/17 re-pointed to doc-spec.md/docs/, NEW Check 19 (no-work-item-ref lint on every human-doc) added; validate.sh green.
- [ ] `scripts/test.sh` `zzz-test-scaffold` fixture updated in lockstep with EVERY validate.sh check change; test.sh green.
- [ ] `/CJ_document-release` (+ helper) rewritten: read doc-spec.md, self-bootstrap if missing, stub-scaffold missing declared docs, run no-ref audit, derive the doc-only whitelist from the registry.
- [ ] `cj-document-release.json` deleted; helper + Check 16 re-pointed; grep-clean.
- [ ] `/CJ_repo-init` retired (catalog status flip + skill relocation + work-item-history relocation + removed from routing + decision tree + workflow.md).
- [ ] `CJ-DOC-RELEASE.md` content absorbed (docs/architecture.md + doc-spec.md), file removed; grep-clean.
- [ ] `CLAUDE.md` updated (manifests removed, prose fixed, scripts table + routing); portable Common seed shipped.

## Todos

<!-- Actionable items for this story (the 12-step sequence, verbatim from the design). -->

- [x] Step 1: Author `doc-spec.md` (Common + Custom + YAML registry) by migrating the two `CLAUDE.md` manifests + `cj-document-release.json` content into it.
- [x] Step 2: `git mv` the `doc/` trio → `docs/` (lowercase, `workflow.md` singular).
- [x] Step 3: Scrub work-item refs + ensure ASCII charts + human-facing rewrite of the three `docs/` files.
- [x] Step 4: Bring `README.md` to spec.
- [x] Step 5: Update `validate.sh` (15/15a/15b/16/17 + new 19) **and** the `test.sh` fixture in the same step.
- [x] Step 6: Rewrite `/CJ_document-release` (read doc-spec.md, self-bootstrap, stub-scaffold, no-ref audit, derived whitelist) + its helper (`scripts/doc-spec.sh`).
- [x] Step 7: Delete `cj-document-release.json` (+ old `cj-document-release-config.sh`); re-point the helper + Check 16.
- [x] Step 8: Retire `/CJ_repo-init` (catalog status=deprecated + relocate src/test/history to deprecated/ + routing + decision tree).
- [x] Step 9: Absorb + remove `CJ-DOC-RELEASE.md`.
- [x] Step 10: Update `CLAUDE.md` (remove manifests, fix prose, scripts table, routing).
- [x] Step 11: Add the portable Common seed (`templates/doc-spec-common.md`).
- [x] Step 12: `validate.sh` + `test.sh` green; QA.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. The single implementable story for F000050 — carries the full 12-step doc-spec migration + the 3 retirements (cj-document-release.json, CJ-DOC-RELEASE.md, /CJ_repo-init).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `doc-spec.md` (new, root — Common + Custom + yaml registry)
- `templates/doc-spec-common.md` (new — portable Common seed; `doc-spec.sh --seed` prefers it)
- `scripts/doc-spec.sh` (new — registry parser/validator + derived whitelist + seed)
- `docs/philosophy.md`, `docs/architecture.md`, `docs/workflow.md` (tracked `git mv` from `doc/` + rewritten, refs scrubbed; architecture.md absorbed CJ-DOC-RELEASE.md mechanism)
- `README.md` (rewrite — folder-structure + getting-started; via `scripts/generate-readme.sh` template edit)
- `scripts/generate-readme.sh` (added Repository layout + Getting started sections)
- `scripts/validate.sh` (Checks 15/15a/15b/16/17 re-pointed to doc-spec.md/docs/, NEW Check 19, Check 9b re-adds `deprecated`)
- `scripts/test.sh` (zzz-test-scaffold Check 17 message + NEW Check 19 negative test; T000040 → docs/workflow.md; deposit assertion → doc-spec.sh; repo-init test runner removed)
- `skills/CJ_document-release/SKILL.md` + `USAGE.md` (rewritten: read doc-spec.md, self-bootstrap, stub-scaffold, no-ref audit, derived whitelist via `scripts/doc-spec.sh`)
- `tests/cj-document-release.test.sh`, `tests/cj-document-release-config.test.sh` (rewritten to assert the doc-spec.md world)
- `skills/CJ_goal_feature|defect|todo_fix/SKILL.md` (halt-table `[doc-sync-no-config]` rows → doc-spec.md)
- `skills/CJ_portability-audit/SKILL.md` + `USAGE.md`, `scripts/cj-portability-audit.sh` (standalone-tier allowed set → doc-spec contract files)
- `CLAUDE.md` (removed both manifests + cj-document-release.json convention; doc-spec.md-based sections; fixed routing + scripts table), `skills-catalog.json` (descriptions scrubbed; CJ_repo-init → deprecated), `rules/skill-routing.md` (dropped /CJ_repo-init), `scripts/skills-deploy` (discover_skills excludes deprecated)
- DELETED: `cj-document-release.json`, `scripts/cj-document-release-config.sh`, `CJ-DOC-RELEASE.md`
- RELOCATED to `deprecated/CJ_repo-init/`: skill source (SKILL.md, USAGE.md, scripts/cj-repo-init.sh) + test + work-item history (F000042, D000032)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Implementation ordering is load-bearing: author doc-spec.md (step 1) and migrate docs (steps 2-4) BEFORE flipping validate.sh checks (step 5), so the new checks land green rather than red mid-build. Check 19 (no-work-item-ref) in particular requires the scrub (step 3) to precede it.
- The `test.sh` `zzz-test-scaffold` fixture parallel-edit is a repeatedly-forgotten blind spot (missed on F000032/F000034/F000035). Step 5 explicitly couples the fixture edit to the same step as the validate.sh check change; TEST-SPEC row S2 is its dedicated regression guard.
- The auto-commit whitelist is DERIVED from the registry, not hand-maintained — this is what makes deleting `cj-document-release.json` (step 7) safe.

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] 2026-06-06: Atomic story (no task children). The 12-step sequence is one cohesive, strictly-ordered migration with a single shipping unit; it does not split into parallel sub-units that warrant separate task dirs. Recorded as Phase 1 gate `Tasks broken down (N/A — atomic story)`.
- [decision] 2026-06-06: `audit_class` is a closed two-value enum {human-doc, operational}. `human-doc` = human-facing, must exist + no work-item IDs (`[FSTD]NNNNNN`) + ASCII flowcharts preferred (advisory). `operational` = must exist, work-item refs allowed (CHANGELOG, CLAUDE.md). Summary: two audit classes, only human-doc gets the no-ref lint.
- [decision] 2026-06-06: NEW Check 19 is hard (ERROR on any `[FSTD][0-9]{6}` hit in a human-doc), not advisory — the migration scrubs the docs first (step 3) so it lands green (step 5/12).
- [impl-decision] 2026-06-06 [impl-auto]: Helper-shape Open Question resolved → NEW `scripts/doc-spec.sh` (not re-pointing the old `cj-document-release-config.sh`). It parses the doc-spec.md yaml registry with awk only (no python/yaml dep, bash-3.2 portable), and is the single helper both `validate.sh` (Checks 15/16/17/19) and the rewritten `/CJ_document-release` consume. Subcommands: `--validate` / `--list-declared` / `--list-human-docs` / `--expand-whitelist` (derived whitelist) / `--seed` (portable Common section for self-bootstrap).
- [impl-decision] 2026-06-06: `/CJ_repo-init` retired via the F000031 RELOCATION pattern (not the F000035 full-nuke), because the SPEC's "flip catalog status (deprecated)" requires `deprecated` to be a valid catalog status — so re-added `deprecated` to `validate.sh` Check 9b's closed enum and kept a catalog entry (status=deprecated, files→`deprecated/CJ_repo-init/`) so Check 4 (orphan) stays satisfied while every `!= deprecated` selector excludes it. Its doc-bootstrap duty is subsumed by `/CJ_document-release`'s self-bootstrap + stub-scaffold; non-doc prereqs lazy-create.
- [impl-finding] 2026-06-06: Introducing the first `deprecated` skill surfaced a latent bug — `skills-deploy`'s `discover_skills()` returned ALL catalog names (`.[].name`) with no status filter, so the default install deployed the deprecated skill too (test-deploy.sh: "Expected 12 skills, got 13"). Fixed `discover_skills()` to `select((.status // "active") != "deprecated")`, matching test-deploy's SKILL_COUNT selector AND the "deprecated = not deployed" semantics. An explicit `install <name>` still works for any entry.
- [impl-finding] 2026-06-06: The two `tests/cj-document-release*.test.sh` files (run by test.sh) were deeply coupled to the deleted JSON+helper world. Repurposed BOTH (kept filenames to avoid test.sh-invocation churn): `-config.test.sh` now tests the doc-spec.md registry + doc-spec.sh subcommands + strict gates + cwd-portability; the other asserts the rewritten SKILL.md (doc-spec self-heal + derived-whitelist wiring, no JSON ref).
- [impl] 2026-06-06: Implemented the full 12-step F000050 migration. New: doc-spec.md + templates/doc-spec-common.md + scripts/doc-spec.sh. git mv doc/→docs/ (3 tracked renames, all 41 work-item refs scrubbed, ASCII charts kept/added, CJ-DOC-RELEASE.md mechanism absorbed into docs/architecture.md). validate.sh Checks 15/15a/15b/16/17 re-pointed + NEW Check 19 + Check 9b deprecated re-add; test.sh fixture in lockstep (Check 17 message + Check 19 negative test + T000040 path + deposit assertion + repo-init-test runner removed). /CJ_document-release SKILL.md + USAGE.md rewritten. cj-document-release.json + cj-document-release-config.sh + CJ-DOC-RELEASE.md deleted. /CJ_repo-init relocated to deprecated/. CLAUDE.md rewritten (manifests removed, doc-spec.md sections, routing + scripts table fixed). README regenerated.
- [impl-auto] 2026-06-06: Autonomous --auto build (silent /CJ_goal_feature runner, no AUQ). Sensitive surfaces (validate.sh/test.sh/skills-catalog.json/skill files) edited per the design-gate-approved scope.
- [impl-pass] 2026-06-06: S000090 implementation complete. `bash scripts/validate.sh` exit 0 (0 errors/0 warnings); `bash scripts/test.sh` RESULT: PASS (0 failures); `grep -rnE '[FSTD][0-9]{6}' docs/` zero matches; no live `cj-document-release.json`/`CJ-DOC-RELEASE.md` refs in scripts/skills/CLAUDE.md; no `doc/` dir remains. Phase 2 implementer-owned gates transitioned.
- 2026-06-06 [qa-smoke] S1 (AC-5): green — `bash scripts/validate.sh` exit 0; Errors 0 / Warnings 0; Check 19 present + passing ("no work-item refs in any human-doc (4 human-docs scanned)").
- 2026-06-06 [qa-smoke] S2 (AC-6): green — `bash scripts/test.sh` exit 0; Failures 0 / RESULT: PASS. zzz-test-scaffold fixture updated in lockstep (Step 3b = Check 17 re-pointed to doc-spec.md registry; Step 3c = NEW Check 19 planted-F000999 negative test; doc-spec.md registry + doc-spec.sh helper regression block at scripts/test.sh:1384).
- 2026-06-06 [qa-smoke] S3 (AC-5): green — planted `F000999` into docs/philosophy.md → validate.sh exit 1 with literal Check-19 ERROR (`human-doc docs/philosophy.md contains work-item ref(s)`); removed → exit 0. Check 19 verified to FIRE, not default-green. Real tree restored byte-identical.
- 2026-06-06 [qa-smoke] S4 (AC-3,AC-4): green — `grep -rnE '[FSTD][0-9]{6}'` over docs/{philosophy,workflow,architecture}.md + README.md = ZERO; `doc/` absent; docs/ holds lowercase philosophy.md/workflow.md(singular)/architecture.md.
- 2026-06-06 [qa-smoke] S5 (AC-1): green — doc-spec.md exists; `doc-spec.sh --validate` = `OK schema_version=1`; registry docs[] entries all carry path/section/audit_class; every audit_class ∈ {human-doc, operational}; --list-declared/--list-human-docs/--expand-whitelist all work.
- 2026-06-06 [qa-smoke] S6 (AC-8,9,10): green — `cj-document-release.json` + `CJ-DOC-RELEASE.md` absent + no live refs in scripts/skills/CLAUDE.md; residual `CJ_repo-init` mentions are deprecation/history only (test.sh removed-runner comment, CLAUDE.md retirement prose, CJ_portability-audit descriptive prose); NOT in rules/skill-routing.md, NOT in docs/ decision tree; catalog status=deprecated + files under deprecated/CJ_repo-init/ (paired-layer deprecation confirmed: catalog flip + source + work-item-history relocation).
- 2026-06-06 [qa-smoke-summary] green: 6/6 non-manual rows green (0 manual rows pending).
- 2026-06-06 [qa-e2e-run-start] RUN_ID=20260606-qa-leaf commit=working-tree-uncommitted
- 2026-06-06 [qa-e2e] E1 (AC-7,AC-12): red — self-bootstrap of a MISSING doc-spec.md is BROKEN. `doc-spec.sh --seed` (the dedicated self-bootstrap path per its own line-25 comment) runs the unconditional validation-gate chain (scripts/doc-spec.sh:86-114) BEFORE subcommand dispatch; that chain requires a valid doc-spec.md to already exist, so when doc-spec.md is absent --seed exits 1 and emits a `[doc-sync-no-config]` halt string to stdout. The SKILL.md self-bootstrap block (skills/CJ_document-release/SKILL.md:152-157) redirects that halt string INTO the new doc-spec.md, producing a ~70-byte corrupt file with no Common marker, no yaml registry, no schema_version that fails `--validate`. Reproduced with real preconditions (templates/doc-spec-common.md present, cwd inside a fresh git repo). Sub-steps (2) stub-scaffold + (3) idempotency PASS; only sub-step (1) self-bootstrap fails. See scripts/doc-spec.sh:86 + :140-152 and skills/CJ_document-release/SKILL.md:152-157. [parent-inline]
- 2026-06-06 [qa-e2e] E2 (AC-1,2,3,4): green — doc-spec.md answers "what docs + what each is for" from one file (Common + Custom + registry); docs/{philosophy,workflow,architecture}.md + README.md read human-facing with ASCII charts and ZERO `[FSTD][0-9]{6}` refs; README has folder-structure + getting-started naming the workflows. [parent-inline]
- 2026-06-06 [qa-e2e] E3 (AC-9,10,11): green — three retirements clean: /CJ_repo-init not routable (absent from rules/skill-routing.md + docs/ decision tree), source+test+history relocated to deprecated/CJ_repo-init/, catalog status=deprecated; cj-document-release.json + CJ-DOC-RELEASE.md gone with content absorbed (whitelist→registry derivation in doc-spec.sh --expand-whitelist; contract/mechanism→docs/architecture.md + doc-spec.md); CLAUDE.md carries neither manifest and points to doc-spec.md. No content lost. [parent-inline]
- 2026-06-06 [qa-e2e] E4 (AC-13): ambiguous — orchestrator Step 5.5 doc-sync is a runtime integration of the rewritten /CJ_document-release; structurally the wrapper's halt taxonomy ([doc-sync-no-config]/[doc-sync-red]/[doc-sync-non-doc-write]) + derived-whitelist gate are wired against doc-spec.md (SKILL.md verified), but a live Step-5.5 run was not executed in this leaf QA context (no AUQ/recursive dispatch). Note: the E1 self-bootstrap defect would only trip here if doc-spec.md were missing — in this repo it is present, so Step 5.5 would not hit the broken --seed path. [parent-inline]
- 2026-06-06 [qa-e2e-summary] red (parent-inline; 4 rows; 0 deferred): E1 self-bootstrap of a missing doc-spec.md is broken (doc-spec.sh validation gate precedes --seed dispatch; SKILL.md redirects the halt string into the new doc-spec.md). E2/E3 green; E4 ambiguous (runtime, structurally sound). Smoke 6/6 green.
- 2026-06-06 [qa-red] S000090 (user-story): E2E RED on E1 (AC-7/AC-12 self-bootstrap). Phase 2 QA-owned gates NOT transitioned (per qa.md Step 9, gates transition only on green smoke AND green E2E). Root cause: scripts/doc-spec.sh:86-114 runs the full registry-validation gate chain on EVERY subcommand including --seed, so --seed cannot emit the Common seed when doc-spec.md is absent — the exact precondition self-bootstrap exists to handle. Test gap: tests/cj-document-release-config.test.sh:115 only runs --seed against the live repo (doc-spec.md present), never with it absent, so test.sh stays green despite the broken self-bootstrap. Suggested fix: move the validation gates AFTER subcommand dispatch (or exempt --seed from the doc-spec.md-must-exist gate), and add a test asserting --seed emits a valid Common seed when doc-spec.md is absent.
- 2026-06-06 [qa-smoke] S1 (AC-5): green — `bash scripts/validate.sh` exit 0; Errors 0 / Warnings 0; Check 19 present + passing ("no work-item refs in any human-doc (4 human-docs scanned)"). [RE-RUN on fixed tree]
- 2026-06-06 [qa-smoke] S2 (AC-6): green — `bash scripts/test.sh` exit 0; Failures 0 / RESULT: PASS. zzz-test-scaffold fixture in lockstep; F000049 doc-spec migration integration blocks (S000086/087/088) all green. [RE-RUN on fixed tree]
- 2026-06-06 [qa-smoke] S3 (AC-5): green — planted `F000999` into docs/philosophy.md → validate.sh exit 1 with literal Check-19 ERROR (`human-doc docs/philosophy.md contains work-item ref(s)` at line 151); removed → exit 0 / RESULT: PASS. Byte-exact restore verified (shasum identical before/after: 0bff5977…). Check 19 FIRES, not default-green. [RE-RUN on fixed tree]
- 2026-06-06 [qa-smoke] S4 (AC-3,AC-4): green — `grep -rE '[FSTD][0-9]{6}'` over docs/{philosophy,workflow,architecture}.md + README.md = ZERO; `doc/` absent; docs/ holds lowercase philosophy.md/workflow.md(singular)/architecture.md. [RE-RUN on fixed tree]
- 2026-06-06 [qa-smoke] S5 (AC-1): green — doc-spec.md exists; `doc-spec.sh --validate` = `OK schema_version=1`; --list-declared/--list-human-docs/--expand-whitelist all work; every audit_class ∈ {human-doc, operational}. [RE-RUN on fixed tree]
- 2026-06-06 [qa-smoke] S6 (AC-8,9,10): green — `cj-document-release.json` + `CJ-DOC-RELEASE.md` absent + no live refs in scripts/skills/CLAUDE.md; residual `CJ_repo-init` mentions are deprecation/history/descriptive prose only (test.sh removed-runner comment, CLAUDE.md retirement prose, CJ_portability-audit "counterpart" prose); NOT in rules/skill-routing.md (0), NOT in docs/philosophy.md decision tree (0); catalog status=deprecated + files under deprecated/CJ_repo-init/; skills/CJ_repo-init/ gone. [RE-RUN on fixed tree]
- 2026-06-06 [qa-smoke-summary] green: 6/6 non-manual rows green (0 manual rows pending). [RE-RUN on fixed tree]
- 2026-06-06 [qa-e2e-run-start] RUN_ID=20260606-qa-leaf-rerun commit=working-tree-uncommitted
- 2026-06-06 [qa-e2e] E1 (AC-7,AC-12): green — self-bootstrap of a MISSING doc-spec.md now WORKS (both prior bugs fixed + verified). FIX 1 (helper): scripts/doc-spec.sh now wraps the registry-validation gates in `_run_registry_gates()` invoked per-subcommand; `--seed` (line 296-299) explicitly does NOT call them, so it emits a complete 6052-byte valid doc-spec.md (DOC-SPEC-COMMON marker + yaml fence + schema_version:1) even when doc-spec.md is absent. FIX 2 (SKILL.md): the self-bootstrap block (skills/CJ_document-release/SKILL.md:156-175) writes the seed to a mktemp file, asserts non-empty (`-s`) AND `REPO_ROOT=$tmp --validate` passes, THEN `mv`s into place — so a halt string can never be redirected into doc-spec.md. Verified all 3 sub-steps with REAL preconditions in a fresh git repo: (1) ran the VERBATIM SKILL.md block → doc-spec.md created, validates `OK schema_version=1`, ZERO corrupt halt strings in file; (2) stub-scaffold → all 4 missing declared docs (README.md, docs/architecture.md/philosophy.md/workflow.md) stubbed with title + `<!-- TODO: fill in -->`; (3) idempotency → re-run finds nothing missing, no second stub, tree clean. Also verified the embedded-heredoc fallback (no templates/ dir → consumer repo) emits a byte-identical valid seed. Regression tests #12 (seed-with-doc-spec-absent) + #13 (no-drift) added to tests/cj-document-release-config.test.sh and green under test.sh. [parent-inline]
- 2026-06-06 [qa-e2e] E2 (AC-1,2,3,4): green — doc-spec.md answers "what docs + what each is for" from one file (Common + Custom markers + yaml registry); docs/{philosophy,workflow,architecture}.md + README.md read human-facing with ASCII charts (13/65/24 chart lines) and ZERO `[FSTD][0-9]{6}` refs; README has `## Repository layout` + `## Getting started: the major workflows`. [parent-inline]
- 2026-06-06 [qa-e2e] E3 (AC-9,10,11): green — three retirements clean: /CJ_repo-init not routable (0 in rules/skill-routing.md + 0 in docs/philosophy.md decision tree + 0 in docs/workflow.md), source+test+history relocated to deprecated/CJ_repo-init/, catalog status=deprecated; cj-document-release.json + CJ-DOC-RELEASE.md gone with content absorbed (whitelist→registry derivation in doc-spec.sh --expand-whitelist; contract/mechanism→docs/architecture.md + doc-spec.md); CLAUDE.md carries neither manifest (0 cj-document-release.json refs) and points to doc-spec.md (14 refs). No content lost. [parent-inline]
- 2026-06-06 [qa-e2e] E4 (AC-13): green — Step 5.5 doc-sync wiring verified sound against the migrated repo: halt taxonomy ([doc-sync-no-config]/[doc-sync-red]/[doc-sync-non-doc-write]) wired (28 refs in SKILL.md), derived-whitelist gate references doc-spec.sh --expand-whitelist (5 refs), all 3 orchestrators dispatch /CJ_document-release with halt-table rows re-pointed to doc-spec.md (0 cj-document-release.json refs each). In THIS repo doc-spec.md is present + validates `OK schema_version=1`, so Step 5.5 takes the clean --validate path and no `[doc-sync-*]` halt is possible; the E1 fix additionally removes the only prior residual risk (a missing-doc-spec.md path now self-heals correctly). Prior run marked this ambiguous solely because a live recursive Step-5.5 run is not executable in a depth-≤2 leaf context (the orchestrator runs its own Step 5.5 as its immediate next step after this QA returns); per the autonomous-build adjudication, treat-as-green on verified-no-halt-possible evidence. [parent-inline]
- 2026-06-06 [qa-e2e-summary] green (parent-inline; 4 rows; 0 deferred): E1 self-bootstrap of a missing doc-spec.md now PASSES (both bugs fixed + verified end-to-end with the verbatim SKILL.md block + regression tests). E2/E3 green; E4 green (Step 5.5 wiring verified no-halt-possible; live recursive run is the orchestrator's own next step). Smoke 6/6 green. [RE-RUN — supersedes the prior RED]
- 2026-06-06 [qa-pass] S000090 (user-story): green smoke (6/6) + green E2E (E1/E2/E3/E4). Phase 2 QA-owned gates transitioned. RE-VERIFY of the previously-RED E1/AC-7 self-bootstrap row on the now-fixed tree: both bugs fixed (helper --seed gate-exemption + SKILL.md temp/validate/mv), verified with real preconditions + verbatim SKILL.md block; validate.sh + test.sh both green.
