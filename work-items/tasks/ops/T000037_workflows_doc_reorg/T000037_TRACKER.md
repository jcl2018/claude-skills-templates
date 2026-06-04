---
name: "doc/WORKFLOWS.md — workflow-centric doc reorg"
type: task
id: "T000037"
status: active
created: "2026-06-04"
updated: "2026-06-04"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-004813-68066"
blocked_by: ""
---

<!-- Source design doc (/office-hours, APPROVED):
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-004813-68066-design-20260604-010511.md
     Design context distilled into ## Insights below. This is Job 1 (the doc reorg)
     of a two-job split; Job 2 (registered-doc requirements audit) is a tracked
     follow-up TODO filed by this PR (see ## Todos). -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
   (no parent — standalone task scaffolded from an APPROVED /office-hours design doc)
2. Create working branch: `git checkout -b feat/{slug}`
   (ships in the existing `cj-feat-20260604-004813-68066` worktree branch / same PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from the design's Success Criteria + the ~12-file ripple list

**Gates:**
- [x] Parent scope read (N/A — standalone task; scope read from APPROVED design doc)
- [x] Working branch created (`branch` field populated: cj-feat-20260604-004813-68066)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + the file-by-file plan in ## Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-004813-68066-design-20260604-010511.md`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment
   (NOTE: under /CJ_goal_feature this task STOPS at the PR; deploy is a separate human step)

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- The full ~12-file ripple surface from the design's "Recommended Approach"
     (Approach A — Lean reframe). Each numbered group maps to a design section §N. -->

- [x] **§1 Rename + rewrite the doc.** `git mv doc/SKILL-CATALOG.md doc/WORKFLOWS.md`. Retitle to `# Workflows`; intro points component lookups at doc/ARCHITECTURE.md and routing at doc/PHILOSOPHY.md. **Keep only** `### CJ_goal_feature`, `### CJ_goal_defect`, `### CJ_goal_todo_fix` — each retains its existing ASCII chart and gains a new `**Touches:**` block (Skills dispatched / Scripts+tools / Docs updated). **Remove** the `## Phase-step skills`, `## Validators / utilities`, and `## Companion surfaces (non-skill)` sections. Update `## See also` links and drop the old self-reference (SKILL-CATALOG.md line ~268 "read SKILL-CATALOG.md (this file)…").
- [x] **§2 doc/ARCHITECTURE.md — add component roster.** New section `## Component skills (non-workflow roster)`: one compact line per skill (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, CJ_document-release [phase-steps]; CJ_personal-workflow [validator]; CJ_system-health, CJ_suggest, CJ_improve-queue, CJ_repo-init [utilities]) — `**name**` + one-line role + Source link. Fix the work-copilot section's internal link `doc/SKILL-CATALOG.md#work-copilot` (line ~97). Update `## Decision tree mirror` prose only if it names SKILL-CATALOG. Update the audit_class enum list (line ~71): `skill-catalog-completeness` → `workflow-completeness`.
- [x] **§3 scripts/validate.sh — Check 15.** `CATALOG_FILE="doc/SKILL-CATALOG.md"` → `doc/WORKFLOWS.md`. Re-scope 15b predicate to `select(.name | startswith("CJ_goal_"))` (full: `select(.status != "deprecated") | select((.files|length)>0) | select(.name | startswith("CJ_goal_"))`). Update the Check 15 header comment to workflow-only semantics. Self-verify: 15b enumerates EXACTLY {CJ_goal_feature, CJ_goal_defect, CJ_goal_todo_fix}; confirm no other CJ_goal_*-prefixed entry exists.
- [x] **§4 scripts/test.sh — zzz-test-scaffold fixture (KNOWN BLIND SPOT — decided, not deferred).** REMOVE the fixture's catalog-doc interaction entirely (Approach b). DELETE the Step 1c stub-append block (lines ~228-247). REMOVE the doc backup/restore plumbing: line ~177 (`cp … doc/SKILL-CATALOG.md … /tmp/skill-catalog-backup-$$`), the `skill-catalog-backup` EXIT-trap clause (line ~178), the inline-cleanup restore (line ~304). UPDATE stale comments: Step 1c (lines ~228-233), blind-spot warning (line ~260), integration-test description (line ~1220 — now "non-orchestrator skill registers in skills-catalog.json only, no workflow-doc section required"). The fixture becomes a positive regression test: a non-orchestrator scaffolded skill passes validate with NO workflow-doc section.
- [x] **§5 CLAUDE.md (5 refs).** Tracked-doc manifest entry: `doc/SKILL-CATALOG.md` → `doc/WORKFLOWS.md`; audit_class `skill-catalog-completeness` → `workflow-completeness` (+ update the audit_class enum definition + the "Check 15b enforces" prose). "Creating a new skill" step 6: rewrite to the WORKFLOWS (orchestrator) / ARCHITECTURE-roster (non-orchestrator) split, both still added to PHILOSOPHY decision tree. "Skill directory structure" note (line ~162): update the "every active routable skill must have a section in doc/SKILL-CATALOG.md" line. "/document-release workbench audit conventions" section: update any SKILL-CATALOG mention.
- [x] **§6 cj-document-release.json.** `categories.skill-catalog: ["doc/SKILL-CATALOG.md"]` → `categories.workflows: ["doc/WORKFLOWS.md"]`. Whitelist `doc/**/*.md` already covers the renamed file (no change).
- [x] **§7 tests/cj-document-release.test.sh (7) + tests/cj-document-release-config.test.sh (4).** Update assertions referencing the `skill-catalog` category / doc/SKILL-CATALOG.md → `workflows` / doc/WORKFLOWS.md. **Hardcoded exact-string assertion (MEDIUM):** cj-document-release-config.test.sh line ~92 `F36_COMPAT="readme changelog claude architecture philosophy skill-catalog"` and line ~100 ok-message — change `skill-catalog` → `workflows` in BOTH. Grep `-i` for `skill-catalog` (lowercase token, easy to miss).
- [x] **§8 templates/doc-SKILL-CATALOG-section.md.** `git mv` → `templates/doc-WORKFLOWS-section.md`, reshaped to the workflow "Touches" section format. (No template-registry.json reference exists — verified.)
- [x] **§9 doc/PHILOSOPHY.md (2 refs).** Update SKILL-CATALOG → WORKFLOWS links/mentions. (Decision-tree New-skills check itself is UNCHANGED — it stays the no-vanish safety net.)
- [x] **§10 skills/CJ_document-release/SKILL.md (1 ref).** Seed-categories example prose (line ~195) listing `... philosophy, skill-catalog` → `workflows`. Move in lockstep with §6 (JSON) + §7 (F36_COMPAT).
- [x] **§11 TODOS.md (1 ref) + new Job-2 row.** Line ~294's `skill-catalog` refers to **skills-catalog.json** (the JSON registry), NOT doc/SKILL-CATALOG.md — **LEAVE IT UNCHANGED** (grep false positive). ADD a tracked TODO row for **Job 2** (registered-doc requirements audit — the deferred half of the original ask).
- [ ] **§11 CHANGELOG.md.** `/ship` adds the new entry (do not rewrite the 8 historical refs).
- [x] **QA grep-sweep.** `git grep -in 'SKILL-CATALOG\|skill-catalog'` returns zero hits in source — excluding .gstack/, work-items/, CHANGELOG.md historical entries, AND the TODOS.md false-positive (skills-catalog.json reference — must be LEFT). Verified: only 2 hits remain, both `skills-catalog.json` references (TODOS.md:300 + doc/PHILOSOPHY.md:181 "Skill-catalog version drift" = the frontmatter-vs-catalog-entry version check), neither a `doc/SKILL-CATALOG.md` ref.
- [x] **File the Job 2 follow-up TODO** (registered-doc requirements audit) for a future run — requirement format + advisory-vs-hard-halt verdict left to that design. Added as `### Job 2: registered-doc requirements audit for /CJ_document-release (P2, M)` under TODOS.md `## Active work`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Job 1 doc reorg — rename doc/SKILL-CATALOG.md → doc/WORKFLOWS.md (workflow-only), push component roster to doc/ARCHITECTURE.md, re-scope validate.sh Check 15b to the CJ_goal_* prefix, ripple ~12 source files. Scaffolded from APPROVED /office-hours design doc via /CJ_scaffold-work-item under /CJ_goal_feature.
- 2026-06-04: Core changes committed at `97c2fa7` (feat: T000037 doc/SKILL-CATALOG.md → doc/WORKFLOWS.md (workflow-centric reorg)) — 16 files in the commit (14 source + TRACKER + test-plan). QA verified the tree clean at this SHA.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `doc/SKILL-CATALOG.md` → `doc/WORKFLOWS.md` (DONE — `git mv` + full rewrite to workflow-only: 3 cj_goal sections, each chart + new `**Touches:**` block; phase-step/validators/companion sections removed; intro + See also rewritten — §1)
- `doc/ARCHITECTURE.md` (DONE — new `## Component skills (non-workflow roster)` with 9 skills; work-copilot internal link self-targeted; audit_class enum `skill-catalog-completeness`→`workflow-completeness` — §2)
- `scripts/validate.sh` (DONE — Check 15: `CATALOG_FILE`→`doc/WORKFLOWS.md`; 15b predicate gains `select(.name | startswith("CJ_goal_"))`; header comment rewritten — §3)
- `scripts/test.sh` (DONE — zzz-test-scaffold fixture: Step 1c stub-append removed, line-177 cp + EXIT-trap clause + inline restore removed, comments updated to new convention — §4)
- `CLAUDE.md` (DONE — tracked-doc manifest entry path+audit_class, audit_class enum def + Check 15b prose, new-skill step 6, structure-note line 162 — §5; no separate audit-conventions SKILL-CATALOG ref existed)
- `cj-document-release.json` (DONE — `categories.skill-catalog`→`categories.workflows`, path→`doc/WORKFLOWS.md` — §6)
- `tests/cj-document-release.test.sh` (DONE — `SKILL_CATALOG`→`ARCHITECTURE_DOC`; assertions #9/#9b repointed at the ARCHITECTURE roster entry since CJ_document-release no longer has a `### ` doc section — §7)
- `tests/cj-document-release-config.test.sh` (DONE — `F36_COMPAT` array + line-100 ok-message + 2 header comments: `skill-catalog`→`workflows` — §7)
- `templates/doc-SKILL-CATALOG-section.md` → `templates/doc-WORKFLOWS-section.md` (DONE — `git mv` + reshape to workflow "Touches" section format — §8)
- `doc/PHILOSOPHY.md` (DONE — 2 `SKILL-CATALOG.md#work-copilot` links repointed at the ARCHITECTURE work-copilot section; line-181 "Skill-catalog version drift" LEFT — skills-catalog.json ref — §9)
- `skills/CJ_document-release/SKILL.md` (DONE — seed-categories prose line ~195 `skill-catalog`→`workflows` — §10)
- `TODOS.md` (DONE — new `### Job 2: registered-doc requirements audit` row added under `## Active work`; line-300 `skill-catalog` LEFT unchanged = skills-catalog.json ref — §11)
- `CHANGELOG.md` (PENDING — new entry added by /ship — §11)

## Insights

<!-- Design context distilled from the APPROVED /office-hours design doc. -->

- **Two jobs, one shipped.** The user's "tighten /CJ_document-release" split into (1) a WORKFLOWS doc showing the meaningful end-to-end workflows + what each touches, and (2) a separate future audit that verifies each registered doc (doc/ files AND skill MDs) against requirements declared at registration. THIS task = Job 1 only; Job 2 is a tracked follow-up TODO.
- **Altitude split is the core idea.** Today's doc/SKILL-CATALOG.md (F000034) mixes two altitudes: end-to-end workflows (the 3 cj_goal chains) and the individual component skills those chains dispatch. The reorg pulls the workflow altitude into its own focused doc (WORKFLOWS.md) and pushes the component altitude down to ARCHITECTURE.md (mechanism reference) "like the cj_personal_workflow."
- **Why "WORKFLOWS" (plural).** Chosen at D3 to disambiguate from the two existing `WORKFLOW.md` files (skills/CJ_personal-workflow/WORKFLOW.md, work-copilot/WORKFLOW.md) which mean "the work-item scaffolding method" — a different concept.
- **No skill silently vanishes.** Every active routable skill stays enforced: workflows in WORKFLOWS.md (Check 15b, re-scoped to CJ_goal_*) AND every routable skill in PHILOSOPHY.md's decision tree (F000030 New-skills check, UNCHANGED — this is the no-vanish safety net). The ARCHITECTURE component roster is documentation, NOT Check-enforced in this build (per-doc requirement enforcement is exactly what deferred Job 2 adds).
- **No schema change.** The workflow set is identifiable by the existing `CJ_goal_*` name prefix — no new `role`/`kind` field on skills-catalog.json.
- **audit_class rename is doc-only.** `skill-catalog-completeness` → `workflow-completeness` lives at two prose sites (CLAUDE.md manifest entry + enum definition; ARCHITECTURE.md line ~71 enum list). validate.sh enforces the manifest *path*, NOT the enum *value* (verified in Check 15a) — no script/test greps the literal string.
- **Reviewer caught three real gaps (all folded in):** (1) BLOCKING — the test.sh zzz-test-scaffold fixture stops matching Check 15b's re-scoped predicate, so its catalog-doc interaction is dead → decision: remove it, fixture becomes a positive "no workflow section required" regression test (§4). (2) MEDIUM — the lowercase `skill-catalog` token breaks a hardcoded F36_COMPAT assertion in cj-document-release-config.test.sh (§7). (3) MEDIUM — the audit_class enum rename also lives in ARCHITECTURE.md line ~71 (§2).
- **Approach A (Lean reframe) chosen** over B (full mechanism weave + new completeness check — deferred to Job 2) and C (machine-readable Touches manifest — YAGNI). Smallest faithful diff; the "Touches" block is prose (Job 2 will re-shape it into the machine-readable form when its real audit requirements are pinned).

## Journal

<!-- Structured entries (decision/finding/blocker) with Summary fields. -->

- [decision] 2026-06-04 — Scaffolded as a **task** (not a user-story or parent feature). Rationale: the design is a single, coherent, directly-implementable doc-reorg with a test plan; under /CJ_goal_feature's silent subagent context a user-story would error at scaffold.md Step 8 (user-stories must nest under a parent feature, which the directly-implementable mandate forbids), while a standalone task (TRACKER + test-plan) is an established on-disk convention (work-items/tasks/ops/). Component `ops` matches the F000030/F000034/F000037 doc-infra lineage.
- [decision] 2026-06-04 — Approach A (Lean reframe) confirmed at design D4: rename + workflow-only WORKFLOWS.md with prose "Touches" blocks; component roster → ARCHITECTURE.md; Check 15b re-scoped to CJ_goal_* prefix; PHILOSOPHY decision-tree stays the no-vanish safety net; ARCHITECTURE roster unenforced (Job 2 adds enforcement).
- [decision] 2026-06-04 — test.sh zzz-test-scaffold fixture: REMOVE its catalog-doc interaction entirely (design §4, Approach b) so the implement subagent does not have to choose — the new convention is that a non-orchestrator scaffolded skill needs NO workflow-doc section, and the surviving fixture becomes a positive regression test for that.
- 2026-06-04 [impl-decision] Repointed `cj-document-release.test.sh` assertions #9/#9b at the doc/ARCHITECTURE.md component roster (`grep '^- \*\*CJ_document-release\*\*'` + a Step-5.5 sub-match) instead of the old `### CJ_document-release` SKILL-CATALOG section grep. Rationale: CJ_document-release is a phase-step, not a CJ_goal_* orchestrator, so under the re-scoped Check 15b it has NO `### ` section in any doc — it moved to the ARCHITECTURE roster as a `**name**` bullet. The test had to follow the skill to its new home (design §7 named the F36_COMPAT token but the #9/#9b section grep was the implied dependent edit).
- 2026-06-04 [impl-decision] doc/PHILOSOPHY.md + ARCHITECTURE.md `SKILL-CATALOG.md#work-copilot` operator-facing links repointed at the ARCHITECTURE `## The work-copilot Copilot bundle` section (not at WORKFLOWS.md). Rationale: the work-copilot entry was REMOVED from the catalog doc by the workflow-only rewrite (§1 keeps only the 3 cj_goal orchestrators), so the link's old target no longer exists; ARCHITECTURE is where the work-copilot mechanism + operator reference now lives.
- 2026-06-04 [impl-finding] Grep-sweep ends with 2 residual `skill-catalog` hits, both genuine `skills-catalog.json` references (NOT `doc/SKILL-CATALOG.md`): TODOS.md:300 (the design-named false positive, shifted from ~294 by the Job-2 row insertion) and doc/PHILOSOPHY.md:181 "**Skill-catalog version drift.**" (the SKILL.md-frontmatter-version-vs-catalog-entry check). Both correctly LEFT — renaming them would mis-describe the JSON registry. The 4 new explanatory comments I wrote in test.sh + the test file were reworded to drop the literal `SKILL-CATALOG` token so the sweep stays maximally clean.
- 2026-06-04 [impl-finding] CLAUDE.md had only 5 SKILL-CATALOG sites, not a separate "audit-conventions" one: the tracked-doc manifest entry (path+audit_class), the audit_class enum definition, the structure-note (line 162), and the new-skill step 6 — plus the manifest entry doubling as the Check-15a-registered path. Confirmed via `grep -in 'SKILL-CATALOG\|skill-catalog' CLAUDE.md` → clean after edits.
- 2026-06-04 [impl] Executed all 11 design sections. 2 `git mv` renames (doc/SKILL-CATALOG.md→doc/WORKFLOWS.md history-preserved; templates/doc-SKILL-CATALOG-section.md→templates/doc-WORKFLOWS-section.md), 2 full rewrites (WORKFLOWS.md workflow-only with Touches blocks; the template reshaped), and edits across doc/ARCHITECTURE.md, scripts/validate.sh, scripts/test.sh, CLAUDE.md, cj-document-release.json, both cj-document-release test files, doc/PHILOSOPHY.md, skills/CJ_document-release/SKILL.md, and TODOS.md (Job-2 row). 13 files changed.
- 2026-06-04 [impl] Self-verify GREEN: `./scripts/validate.sh` exits 0 (0 errors / 0 warnings; Check 15 now "doc/ manifest + WORKFLOWS.md completeness", 15a no orphan/missing for doc/WORKFLOWS.md, 15b PASS for exactly {CJ_goal_feature, CJ_goal_defect, CJ_goal_todo_fix}, Check 16 schema_version=1, Check 17 allowlist 5 entries). `./scripts/test.sh` exits 0 (RESULT: PASS, 0 failures — incl. the updated zzz-test-scaffold integration fixture staying green with NO workflow-doc section, and both cj-document-release test files).
- 2026-06-04 [impl-pass] T000037: implementation complete. Phase 2 implementer-owned gates transitioned (Todos section reflects remaining work; Files section updated). Commit + CHANGELOG remain for /ship.
- 2026-06-04 [qa-boundary] Boundary check at start GREEN. /CJ_personal-workflow check (Directory Mode): ARTIFACTS — TRACKER.md (10/10 frontmatter fields) + test-plan.md (6/6 fields), no placeholders; LIFECYCLE — 3 phases (Track/Implement/Ship), 11 checkboxes = template min 11, sections in template order. No [MISSING]/[DRIFT]. Commit-gate `Core changes committed` marked [x] (was [ ]): the implement subagent writes files but does not commit; the work IS committed at HEAD 97c2fa7 (clean tree; all 14 source files in the commit) — stale-checkbox case per qa.md Step 2; SHA recorded below in Log.
- 2026-06-04 [qa-smoke] T1 (validate.sh GREEN + Check 15b == 3 orchestrators): green — `./scripts/validate.sh` exits 0, RESULT: PASS (0 errors/0 warnings) AFTER the Check-14 remedy below. Check 15b enumerates EXACTLY {CJ_goal_todo_fix, CJ_goal_defect, CJ_goal_feature} (verified by validate output AND by the 15b jq predicate `startswith("CJ_goal_")` resolving to exactly those 3; no 4th entry). Check 16 schema_version=1 GREEN; Check 17 allowlist 5 entries GREEN.
- 2026-06-04 [qa-finding] T1 first run was RED: `./scripts/validate.sh` exit 1, 1 ERROR — Check 14 "skills/CJ_document-release/USAGE.md is stale (SKILL.md @97c2fa7, USAGE.md @677dfeb)". Root cause: T000037 §10 committed a cosmetic one-token edit to CJ_document-release/SKILL.md (`skill-catalog`→`workflows` in seed-categories prose), bumping SKILL.md's git %ct past USAGE.md's. NOT in the test-plan's named scope (validate.sh was GREEN at the implement subagent's pre-commit self-verify; the commit re-tripped Check 14). USAGE.md does not reference the renamed token → content-accurate. Remedy (the exact CLAUDE.md "USAGE.md drift detection" cosmetic path): bumped USAGE.md `last-updated:` to 2026-06-04T08:47:37Z and `git add`'d it (Check 14 is staged-aware → treats staged USAGE.md %ct as now). Re-run: validate.sh exit 0 GREEN. ACTION FOR /ship: this staged USAGE.md bump MUST be committed alongside the tracker journal, else its git %ct does not persist and a fresh (unstaged) validate run re-flags Check 14.
- 2026-06-04 [qa-smoke] T2 (test.sh RESULT: PASS): green — `./scripts/test.sh` exits 0, RESULT: PASS, Failures: 0. Embedded validate run prints `OK: validate.sh passed` (Check 15 → WORKFLOWS.md GREEN; staged USAGE.md shows `current`). zzz-test-scaffold §4 fixture (non-orchestrator skill, NO workflow-doc section) exercised inside the validate pass with 0 errors; both cj-document-release test files (cj-document-release.test.sh + cj-document-release-config.test.sh, F000037 assertions) pass.
- 2026-06-04 [qa-smoke] T3 (grep-sweep, zero dangling SKILL-CATALOG/skill-catalog in source): green — `git grep -in 'SKILL-CATALOG\|skill-catalog'` scoped (exclude .gstack/, work-items/, CHANGELOG.md) returns EXACTLY 2 hits, both genuine skills-catalog.json references: TODOS.md:300 + doc/PHILOSOPHY.md:181 ("Skill-catalog version drift"). ZERO doc/SKILL-CATALOG.md refs. doc/SKILL-CATALOG.md gone from disk; doc/WORKFLOWS.md present.
- 2026-06-04 [qa-smoke] T4 (doc/WORKFLOWS.md structural shape): green — titled `# Workflows`; exactly 3 `###` orchestrator sections (CJ_goal_feature L13, CJ_goal_defect L56, CJ_goal_todo_fix L96, count=1 each) under `## Orchestrators`, each with a fenced ASCII chart (6 fence lines = 3 charts) + a `**Touches:**` block (3 blocks: L50/L90/L134). Removed sections (## Phase-step skills / ## Validators-utilities / ## Companion surfaces) all ABSENT.
- 2026-06-04 [qa-smoke] T5 (doc/ARCHITECTURE.md component roster): green — `## Component skills (non-workflow roster)` present (L99) listing all 9 component skills exactly once (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, CJ_document-release, CJ_personal-workflow, CJ_system-health, CJ_suggest, CJ_improve-queue, CJ_repo-init). audit_class enum reads `workflow-completeness` (L71), no `skill-catalog-completeness`. Zero SKILL-CATALOG links; work-copilot internal link repointed at the in-doc ARCHITECTURE anchor.
- 2026-06-04 [qa-smoke] T6 (PHILOSOPHY decision-tree no-vanish safety net): green — F000030 New-skills predicate `jq '.[]|select(.status=="active")|select((.files|length)>0)|.name'` resolves to {CJ_system-health, CJ_personal-workflow, CJ_goal_todo_fix}; all 3 present in doc/PHILOSOPHY.md `## Decision tree` (missing_count=0). Check unchanged by the reorg, as designed.
- 2026-06-04 [qa-smoke] T7 (cj-document-release.json category rename): green — `.categories` keys = [architecture, changelog, claude, philosophy, readme, workflows]; `skill-catalog` key ABSENT; `workflows` → ["doc/WORKFLOWS.md"]; whitelist_patterns unchanged (incl. doc/**/*.md); schema_version=1; valid JSON. Check 16 GREEN.
- 2026-06-04 [qa-smoke-summary] green: 7/7 non-manual rows green (T1–T7), 0 manual rows. One in-scope-adjacent RED found and fixed during QA (Check 14 USAGE.md drift for CJ_document-release — cosmetic last-updated bump applied + staged; must be committed by /ship).
- 2026-06-04 [qa-pass] T000037 (task): green smoke from test-plan rows (7 rows: T1–T7). No qa-owned Phase 2 gates per task template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. NOTE: a staged-but-uncommitted fix (skills/CJ_document-release/USAGE.md last-updated bump) is required for validate.sh to stay GREEN post-commit — /ship must include it.
