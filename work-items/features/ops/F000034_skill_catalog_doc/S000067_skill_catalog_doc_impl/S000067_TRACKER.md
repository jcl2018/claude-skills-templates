---
name: "doc/SKILL-CATALOG.md + tracked-doc/ manifest — implementation"
type: user-story
id: "S000067"
status: active
created: "2026-06-01"
updated: "2026-06-01"
parent: "F000034"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260601-225856-skills-doc"
blocked_by: ""
# pr: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b cj-feat-20260601-225856-skills-doc` (cut from origin/main HEAD `caac454`; ships in same PR as parent)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

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
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR (against main), bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review) against main
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `templates/doc-SKILL-CATALOG-section.md` exists with the per-skill section structure:
  - `### {name}` heading
  - `**Status:** ...` line
  - `**Source:** ...` line linking SKILL.md + USAGE.md
  - `**Invoke when:** ...` one-to-two-line invocation pattern
  - `**Workflow:**` block with either a fenced ASCII chart OR an explicit tag line (`(single-step utility)` / `(validator)` / `(phase-step in /CJ_goal_feature chain)`)
  - Each instruction inline so the author knows what to write.
- [ ] `doc/SKILL-CATALOG.md` exists with:
  - Header (title + one-paragraph description naming Check 15).
  - One `### <name>` section per routable non-deprecated skill (predicate: `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json` → 11 skills as of 2026-06-01).
  - Orchestrators (CJ_goal_feature, CJ_goal_defect, CJ_goal_todo_fix, CJ_personal-pipeline) each have a fenced ASCII workflow chart distilled from their SKILL.md `## Overview` section.
  - Phase-step skills (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item) each have the tag `(phase-step in /CJ_goal_feature chain)`.
  - Validator (CJ_personal-workflow) has tag `(validator)`.
  - Utilities (CJ_system-health, CJ_suggest, CJ_improve-queue) each have tag `(single-step utility)`.
  - Footer linking PHILOSOPHY.md `## Decision tree` (routing rules) + per-skill USAGE.md (operator best-practice).
- [ ] `CLAUDE.md ## /document-release workbench audit conventions` has a new `### Tracked doc/ files manifest` subsection inserted **after** `### New-skills check` and **before** `### Reporting`. The subsection contains:
  - A 1-2 sentence prose intro naming Check 15 + orphan-detection.
  - A YAML fenced block (` ```yaml ... ``` `) with three entries: PHILOSOPHY.md (`skill-routing-drift`, F000030), ARCHITECTURE.md (`skill-routing-drift`, F000030), SKILL-CATALOG.md (`skill-catalog-completeness`, F000034).
  - The `audit_class` enum documented as a closed bulleted list (`skill-routing-drift` / `skill-catalog-completeness` / `static-reference` / `auto-generated`).
  - A one-line reference noting `/document-release` reads this manifest as project context (existing F000030 pattern).
- [ ] `CLAUDE.md ### Reporting` subsection gets one additional line: "Doc/ manifest drift findings (Check 15) appear under `### Doc/ manifest drift`. One finding per line; positive `Doc/ manifest drift: none` if clean."
- [ ] `CLAUDE.md ### Skill directory structure` gets a one-line reference: "Additionally, every active routable skill must have a section in `doc/SKILL-CATALOG.md`. Enforced by `scripts/validate.sh` Check 15."
- [ ] `CLAUDE.md ## Creating a new skill` gets a new Step 7 (existing Step 7 → 8): "Add a section for the new skill in `doc/SKILL-CATALOG.md` using `templates/doc-SKILL-CATALOG-section.md` as a starting point. Include either an ASCII workflow chart (for orchestrators / phase-step skills) or an explicit tag line `(single-step utility)` / `(validator)` / `(phase-step in /CJ_goal_feature chain)` (for everything else). Check 15 will ERROR if neither is present."
- [ ] `scripts/validate.sh` has a new Check 15 block (placed after Check 14 from F000033) implementing:
  - **15a (manifest):** parse the YAML block from CLAUDE.md `### Tracked doc/ files manifest` via awk-range. For each `doc/*.md` on disk: ERROR if not in manifest. For each manifest entry: ERROR if file missing from disk.
  - **15b (catalog completeness):** gated by `if [ -f "$CATALOG_FILE" ]`. For each skill from the audit predicate: ERROR if `### <name>` heading missing in SKILL-CATALOG.md. Extract section body (awk between `### <name>` and next `### `); ERROR if neither a fenced ASCII chart (`HAS_CHART >= 2` matching `^```` open + close lines) NOR a tag line (matching `^\((single-step utility|validator|phase-step in /CJ_goal_feature chain)\)`) is present. On success, PASS line per skill.
- [ ] Check 15 ERROR messages name the offending path and the specific failure mode.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD.
- [ ] `skills-catalog.json` UNCHANGED.
- [ ] `~/.claude/` deploy surface unaffected.
- [ ] `deprecated/` skills + `work-copilot/` untouched.
- [ ] CHANGELOG entry in user-forward voice naming F000034; VERSION PATCH-bumped (via `./scripts/check-version-queue.sh`).
- [ ] PR opened against main; PR body notes the F000030/F000032/F000033 lineage + Check 15 addition.

## Todos

<!-- Actionable items for this story. -->

- [ ] Write `templates/doc-SKILL-CATALOG-section.md` (per-skill section template with inline instructions per field)
- [ ] Write `doc/SKILL-CATALOG.md` header + 11 hand-written sections (4 orchestrator charts + 7 single-step tags); group by role
- [ ] Add `### Tracked doc/ files manifest` subsection to `CLAUDE.md ## /document-release workbench audit conventions` (after New-skills check, before Reporting); include YAML manifest + audit_class enum + 1-line /document-release reference
- [ ] Extend `CLAUDE.md ### Reporting` with the Check 15 `### Doc/ manifest drift` line
- [ ] Extend `CLAUDE.md ### Skill directory structure` with SKILL-CATALOG.md requirement reference
- [ ] Add new Step 7 to `CLAUDE.md ## Creating a new skill` (renumber existing 7 → 8)
- [ ] Add Check 15 block to `scripts/validate.sh` (after Check 14): manifest parse + orphan + missing-from-disk + per-skill catalog section completeness (chart-OR-tag predicate)
- [ ] Run `./scripts/validate.sh` locally → expect 0 errors / 0 warnings
- [ ] Run `./scripts/test.sh` locally → expect exit 0
- [ ] Bump VERSION (PATCH; queue-aware via `./scripts/check-version-queue.sh`)
- [ ] Write CHANGELOG.md entry naming F000034 + the Tracked doc/ files manifest convention
- [ ] Stage all changes in one atomic commit (pre-commit hook + Check 15 require it) → `/ship` against main

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-01: Created. Single-story decomposition of F000034 — templates/doc-SKILL-CATALOG-section.md + doc/SKILL-CATALOG.md (header + 11 sections) + CLAUDE.md tracked-doc/ manifest subsection + CLAUDE.md Skill-directory + Creating-a-new-skill edits + validate.sh Check 15. No upstream stacking — branch cut from origin/main HEAD post-#186 + post-#188.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `templates/doc-SKILL-CATALOG-section.md` (NEW — per-skill section template)
- `doc/SKILL-CATALOG.md` (NEW — consolidated catalog with 4 ASCII charts + 7 tag lines)
- `CLAUDE.md` (MODIFIED — new `### Tracked doc/ files manifest` subsection in `## /document-release workbench audit conventions`; `### Reporting` extended; `### Skill directory structure` extended; `## Creating a new skill` extended with new Step 7)
- `scripts/validate.sh` (MODIFIED — new Check 15: manifest parse + orphan + missing-from-disk + per-skill catalog section completeness)
- `VERSION` (MODIFIED — PATCH bump)
- `CHANGELOG.md` (MODIFIED — F000034 entry)

## Insights

<!-- Non-obvious findings worth remembering. -->

- **Chart-OR-tag predicate is the load-bearing audit primitive.** Check 15's per-section logic is `HAS_CHART >= 2` OR `HAS_TAG >= 1`. Without it, a half-finished section (heading only, no body) passes silently. The predicate forces the operator to declare intent — either commit to a workflow chart, or commit to a tag explaining why no chart.
- **awk-range YAML parsing is fine for inline manifests.** `awk '/^### Tracked doc\/ files manifest$/,/^### /{if($0 ~ /^- path:/) print $3}'` is good-enough hand-written-content parsing. No real YAML library needed. Hoisting to JSON is a follow-up when the manifest outgrows inline.
- **Defensive `if [ -f "$CATALOG_FILE" ]` is necessary for test-mode robustness.** The completeness check must be gated to avoid false-fire during early-implementation states where the catalog file doesn't yet exist on disk. For this PR, everything lands in one atomic commit anyway, but defensiveness is cheap.
- **`HAS_CHART >= 2` matches fenced-block open + close.** A single ` ``` ` line is either an unclosed block (broken markdown) or a code-span (shouldn't happen at section level). Two ` ``` ` lines (open + close) is the canonical fenced-block shape; `grep -cE '^```'` returns 2.
- **Atomic-commit ordering through pre-commit hook.** Same constraint as F000032 + F000033: stage everything once. Intermediate state would fire Check 15 (e.g. new doc/SKILL-CATALOG.md without manifest entry). The defensive `-f` guard helps for the catalog file itself but not for the orphan/missing-from-disk halves — those compare disk vs manifest.
- **Audit-predicate parity with F000032 + F000033.** Same jq query. Adding/deprecating a skill in skills-catalog.json auto-adjusts all three checks consistently. Diverging the predicate creates a 2-out-of-3 desync hazard.
- **No upstream `/document-release` modification.** Convention extends via CLAUDE.md project context (the existing F000030 pattern). `/document-release` reads CLAUDE.md at Step 2 and naturally picks up the new manifest section + the audit conventions for the new audit class.
- **`audit_class: auto-generated` is reserved for the door, not for v1 use.** No v1 entries use it. Listing the value in the closed enum keeps the future option (e.g. a generated INDEX.md or DIAGRAM.md) without backfilling.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-01 [decision] Single-story decomposition (atomic implementation). Summary: templates/doc-SKILL-CATALOG-section.md + doc/SKILL-CATALOG.md (header + 11 sections) + CLAUDE.md manifest subsection + Skill-directory + Creating-a-new-skill edits + validate.sh Check 15 all ship in one PR. Same shape as F000032 (S000065) and F000033 (S000066) — the pre-commit hook + Check 15's orphan/missing-from-disk halves force atomic landing.
- 2026-06-01 [decision] Hand-written catalog (Approach A) over auto-generated (Approach C). Summary: ASCII charts aren't derivable from SKILL.md prose without brittle parsing; the chart shape lives in each orchestrator's `## Overview` informally, but formalizing the extraction is over-budget. F000032 already rejected the auto-gen path on the same grounds. Operator writes; Check 15 audits structure + completeness, not content correctness.
- 2026-06-01 [decision] Tracked-doc/ manifest inline in CLAUDE.md, NOT separate JSON file. Summary: CLAUDE.md inline is simpler for v1 (one file to read; awk-parseable). Separate JSON would be cleaner for tool consumption but adds a file + parser surface. v1 has 3 manifest entries; awk-range is sufficient. Defer hoisting until a future tool needs structured parsing.
- 2026-06-01 [decision] `audit_class` enum is closed: `skill-routing-drift` / `skill-catalog-completeness` / `static-reference` / `auto-generated`. Summary: Closed enum prevents per-doc free-text drift. v1 only uses the first two values; `static-reference` (no drift check, file existence only) + `auto-generated` (script-regenerated, content matches output) are reserved for future doc additions whose drift criteria aren't yet worked out. Listing them now avoids a backfill PR later.
- 2026-06-01 [decision] Chart-OR-tag enforcement (no silent omission). Summary: Check 15b's per-section predicate is `(HAS_CHART >= 2) OR (HAS_TAG >= 1)`. A section heading alone (no body, no chart, no tag) is silent omission territory — Check 15 forbids this. 4 orchestrators (CJ_goal_feature/defect/todo_fix + CJ_personal-pipeline) get charts; 7 single-step skills (3 phase-steps + CJ_personal-workflow validator + 3 utilities) get tags. No middle ground.
- 2026-06-01 [decision] Phase-step skills get tag, NOT a full ASCII chart. Summary: CJ_scaffold-work-item / CJ_implement-from-spec / CJ_qa-work-item are called transitively by orchestrators; their "chart" is one box. The tag `(phase-step in /CJ_goal_feature chain)` is more informative than a one-rectangle chart. Resolved Open Question #1 from the design.
- 2026-06-01 [decision] Audit predicate matches F000032 + F000033 exactly (`status != "deprecated"` AND `(files | length) > 0`). Summary: Three checks (13, 14, 15), one predicate, one truth — same 11 routable non-deprecated skills. Diverging the predicate would let the checks fall out of sync; reuse, don't fork.
- 2026-06-01 [decision] Defensive `if [ -f "$CATALOG_FILE" ]` guard for Check 15b. Summary: Completeness check skips silently when the catalog file doesn't yet exist (test-mode robustness, intermediate-implementation-state safety). The orphan + missing-from-disk halves (15a) are not guarded — they always run and compare disk vs manifest.
- 2026-06-01 [decision] No upstream `/document-release` modification. Summary: Per memory `project_workbench_auto_deploy_unsafe`, upstream skills not ours to edit. Convention extends via CLAUDE.md project context (existing F000030 pattern); `/document-release` reads CLAUDE.md at Step 2 and picks up the new manifest section + audit conventions naturally.

- 2026-06-02T07:02:29Z [impl-recovery+qa-reverify] /CJ_implement-from-spec leaf subagent socket-disconnected mid-flight after writing templates/doc-SKILL-CATALOG-section.md, doc/SKILL-CATALOG.md (11 sections), and scripts/validate.sh Check 15. CLAUDE.md edits (### Tracked doc/ files manifest subsection + ### Skill directory structure addendum + ## Creating a new skill step 6 renumber) and tracker gates-update did NOT land before disconnect. Orchestrator applied: (a) the 3 CLAUDE.md edits manually; (b) two real-bug fixes in Check 15 caught by re-running validate.sh: the manifest-parser awk `/start/,/end/` range collapsed because both patterns matched `^### ` — switched to flag-based awk (manifest extracts 3 entries correctly); the per-section parser had the same range-collapse — same fix (sections extract correctly); the tag regex was anchored `^\(...\)` but the catalog uses markdown backticks `\`(validator)\`` — dropped the anchor since the closed enum makes anywhere-in-line matching safe. (c) test.sh manual-skill-creation integration test extended to ALSO scaffold a doc/SKILL-CATALOG.md section for zzz-test-scaffold (and back up + restore the catalog file in the EXIT trap + Step 5 inline cleanup), so Check 15 finds the section and the test passes. ./scripts/validate.sh → PASS (0 errors, all 11 catalog sections pass + 3-entry manifest consistent). ./scripts/test.sh → PASS (Failures: 0, Test 13 SKIP-with-presence-check per F000033). Phase 2 gates now green; ready for /ship.
