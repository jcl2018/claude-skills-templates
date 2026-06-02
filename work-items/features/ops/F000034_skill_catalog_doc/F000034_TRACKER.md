---
name: "doc/SKILL-CATALOG.md + tracked-doc/ manifest"
type: feature
id: "F000034"
status: active
created: "2026-06-01"
updated: "2026-06-01"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260601-225856-skills-doc"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b cj-feat-20260601-225856-skills-doc` (cut from origin/main HEAD `caac454`, post-#186 + post-#188 merged; no upstream stacking)
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

- [ ] `doc/SKILL-CATALOG.md` exists with one `### <name>` section per routable non-deprecated skill (predicate: `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json` — 11 skills as of 2026-06-01).
- [ ] Orchestrators (CJ_goal_feature, CJ_goal_defect, CJ_goal_todo_fix, CJ_personal-pipeline) each carry a fenced ASCII workflow chart distilled from their SKILL.md `## Overview` section.
- [ ] Phase-step + validator + utility skills each carry an explicit tag line: `(single-step utility)` / `(validator)` / `(phase-step in /CJ_goal_feature chain)`. No silent omission.
- [ ] `templates/doc-SKILL-CATALOG-section.md` exists with the per-skill section structure (status, source, invoke-when, workflow-or-tag) and inline instructions per field.
- [ ] `CLAUDE.md ## /document-release workbench audit conventions` gains a new `### Tracked doc/ files manifest` subsection inside the section, before the `### Reporting` subsection. The manifest is a YAML fenced block enumerating each `doc/*.md` file with `path`, `audit_class`, `owner`. Three entries land in v1: PHILOSOPHY.md (`skill-routing-drift`), ARCHITECTURE.md (`skill-routing-drift`), SKILL-CATALOG.md (`skill-catalog-completeness`).
- [ ] `CLAUDE.md ### Reporting` subsection notes that Check 15 drift findings appear under `### Doc/ manifest drift` in the PR body, with a positive `Doc/ manifest drift: none` line when clean.
- [ ] `CLAUDE.md ## Conventions ### Skill directory structure` references the SKILL-CATALOG.md requirement (one-liner pointing to Check 15).
- [ ] `CLAUDE.md ## Creating a new skill` gains a new Step 7 (existing step 7 renumbered to 8) instructing the author to add a SKILL-CATALOG.md section using the template, with either an ASCII chart or an explicit tag.
- [ ] `scripts/validate.sh` has a new Check 15 (placed after Check 14 from F000033) that:
  - Parses the YAML manifest from the `### Tracked doc/ files manifest` subsection of CLAUDE.md via awk-range.
  - ERRORs on any `doc/*.md` file on disk not registered in the manifest (orphan).
  - ERRORs on any manifest entry whose `path` does not exist on disk.
  - For `doc/SKILL-CATALOG.md` (when present): for each routable non-deprecated skill from the same audit predicate, ERRORs if the catalog is missing `### <name>` OR if the section has neither a fenced ASCII chart (≥2 fenced lines) NOR a tag line matching `^\((single-step utility|validator|phase-step in /CJ_goal_feature chain)\)`.
  - Defensive: SKILL-CATALOG.md completeness check is skipped (silently) when the file does not exist yet (test-mode robustness).
- [ ] Check 15 ERROR messages name the offending path and the specific failure mode (orphan / missing-from-disk / missing-section / missing-chart-and-tag).
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD (full suite).
- [ ] Smoke verification (manual): break the manifest's PHILOSOPHY.md `path` to `doc/PHILOSOFY.md`, re-run validate.sh, confirm Check 15 ERRORs `missing from disk`; restore. Delete one `### <name>` line in SKILL-CATALOG.md, re-run, confirm Check 15 ERRORs with `missing section`; restore.
- [ ] CHANGELOG.md entry in user-forward voice naming F000034; VERSION PATCH-bumped via `./scripts/check-version-queue.sh` (5.0.19 or next free slot).
- [ ] PR opened against main; PR body notes the F000030/F000032/F000033 lineage + Check 15 addition.
- [ ] `skills-catalog.json` UNCHANGED — no new skill, no template registration changes.
- [ ] No upstream gstack skill modifications — convention extends via CLAUDE.md project-context (existing F000030 pattern).
- [ ] No changes to `deprecated/` or `work-copilot/` (workbench-only scope).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000067 (`skill_catalog_doc_impl`) — implementation user-story (templates/doc-SKILL-CATALOG-section.md + doc/SKILL-CATALOG.md with 11 hand-written sections + CLAUDE.md tracked-doc/ manifest subsection + CLAUDE.md Skill-directory + Creating-a-new-skill edits + validate.sh Check 15)
- [ ] End-to-end pipeline run — `/ship` opens PR against main; `./scripts/validate.sh` PASS; `./scripts/test.sh` PASS; manual smoke = break a manifest path / delete a section heading, confirm Check 15 ERRORs as designed

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-01: Created. Cut from origin/main HEAD `caac454` (post-PR #186 + post-PR #188 merged). Builds the workbench's first **catalog**-shaped doc: a consolidated `doc/SKILL-CATALOG.md` with per-skill sections (status, invoke-when, ASCII workflow chart for orchestrators / tag for single-step skills, links) + a tracked-doc/ manifest in CLAUDE.md registering every doc/*.md with an audit_class. Closes the F000030 extensibility question ("what happens when a third doc/ file is added"). Validate.sh Check 15 enforces orphan-detection + per-skill section completeness. No upstream stacking; independent F-ID after F000032 + F000033 already merged.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `doc/SKILL-CATALOG.md` (NEW — consolidated per-skill catalog with ASCII charts / tags)
- `templates/doc-SKILL-CATALOG-section.md` (NEW — per-skill section template)
- `CLAUDE.md` (MODIFIED — new `### Tracked doc/ files manifest` subsection inside `## /document-release workbench audit conventions`; `### Reporting` subsection extended with Check 15 line; `### Skill directory structure` subsection + `## Creating a new skill` extended to reference SKILL-CATALOG.md)
- `scripts/validate.sh` (MODIFIED — new Check 15: manifest parse + orphan detection + SKILL-CATALOG.md completeness)
- `VERSION` (MODIFIED — PATCH bump)
- `CHANGELOG.md` (MODIFIED — F000034 entry in user-forward voice)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- **Workbench's first catalog-shaped doc.** Not "principles" (PHILOSOPHY), not "mechanisms" (ARCHITECTURE), not "how to use" (per-skill USAGE.md). It is "scan-everything-at-once." The ASCII chart per skill is the load-bearing UX primitive — a reader who has never seen `/CJ_goal_feature` can see the topic → office-hours → silent-build → /ship → PR chain in 10 lines and know what they're about to invoke.
- **Hand-written, not auto-generated.** Per F000032's precedent (auto-gen rejected for the same reason). ASCII charts aren't derivable from SKILL.md prose; the chart is the operator's distillation. Check 15 enforces structural completeness, not content correctness.
- **Tracked-doc/ manifest closes F000030's extensibility gap.** F000030 named two doc/ files (PHILOSOPHY, ARCHITECTURE) but had no convention for "what happens when a third file is added." This PR establishes the pattern: any new file in doc/ must register with an audit_class. Future doc/ additions just append one entry.
- **`audit_class` enum is closed but extensible.** Four values: `skill-routing-drift` (F000030), `skill-catalog-completeness` (this PR), `static-reference` (reserved for future hand-written ref docs), `auto-generated` (reserved for future script-regenerated docs). Listed in the enum to leave the door open without backfilling.
- **Reused F000032/F000033 audit predicate.** `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json` — the same 11 skills audited by Check 13 + 14. Do not fork. Three checks, same predicate, one truth.
- **ERROR severity, not WARN.** Per F000030 + F000032 + F000033 precedent. The `### Decision tree` of PHILOSOPHY.md proved (F000030's 1/13 DESIGN.md adoption) that WARN decays to noise; ERROR + cheap-override is the load-bearing pattern.
- **Awk-range YAML parsing is good enough for v1.** The manifest is inline in CLAUDE.md (no separate file). A real YAML parser would be overkill — the manifest is hand-written, line-anchored (`- path: …`), and the awk-range grabs everything between the H3 heading and the next H3. If a future tool needs structured parsing, hoist to a JSON file then.
- **Atomic commit ordering through the pre-commit hook.** Same constraint as F000032 + F000033: stage everything once (CLAUDE.md manifest + SKILL-CATALOG.md + 11 skill-sections + template + Check 15). Only failure mode is operator running `git commit` mid-implement on partial state.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-01 [decision] Chose Approach A (new doc/SKILL-CATALOG.md + extend audit) over B (extend USAGE.md), C (auto-generated catalog), D (extend PHILOSOPHY.md decision tree). Summary: A reuses the established convention shape (ERROR-strict validate.sh enforcement + hand-written content audited at commit + /document-release time). The manifest is the extensibility primitive future doc/ additions need; ASCII charts give the "verdict at a glance" UX the user described. B couples per-skill how-to with cross-skill index; C is brittle (parsing prose, ASCII charts aren't derivable); D loses the chart real-estate.
- 2026-06-01 [decision] Single user-story decomposition. Summary: All edits (templates/doc-SKILL-CATALOG-section.md + doc/SKILL-CATALOG.md content + CLAUDE.md tracked-doc/ manifest + validate.sh Check 15) ship atomically under the pre-commit hook. Same shape as F000032 + F000033. Splitting adds bookkeeping without splitting actual risk; orphan-detection + section-completeness only validates against present-state, which has to land atomically anyway.
- 2026-06-01 [decision] ASCII chart mandatory for orchestrators; explicit no-chart tag mandatory for single-step skills. Summary: A reader seeing a section without either is silent-omission territory — Check 15 forbids this via `(chart present) OR (tag present)` predicate. The 4 orchestrators (CJ_goal_feature/defect/todo_fix/personal-pipeline) get charts; the 7 single-step skills (CJ_scaffold/implement/qa-work-item phase-steps + CJ_personal-workflow validator + CJ_system-health/suggest/improve-queue utilities) get tags. No middle ground.
- 2026-06-01 [decision] Manifest inline in CLAUDE.md, NOT a separate JSON file. Summary: CLAUDE.md inline is simpler for v1 (one file to read; awk-parseable). Separate JSON would be cleaner for tool consumption but adds a file + parser surface. Defer hoisting until a future tool actually needs structured parsing.
- 2026-06-01 [decision] `audit_class` enum is closed (`skill-routing-drift` / `skill-catalog-completeness` / `static-reference` / `auto-generated`). Summary: Closed enum prevents per-doc free-text drift. `static-reference` + `auto-generated` are reserved for future doc/ additions; v1 only uses the first two values but listing the enum keeps the door open without backfilling.
- 2026-06-01 [decision] Audit predicate matches F000032 + F000033 exactly. Summary: Same `status != "deprecated"` AND `(files | length) > 0` jq query. Three checks (13, 14, 15), one predicate, one truth. Diverging the predicate would let the three checks fall out of sync; reuse — do not fork.
- 2026-06-01 [decision] No upstream gstack `/document-release` modification. Summary: Per memory `project_workbench_auto_deploy_unsafe`, upstream skills are not ours to edit. The integration is via extending the CLAUDE.md `/document-release workbench audit conventions` section, which `/document-release` reads as project context at Step 2 (the existing F000030 pattern). Drift findings surface in the PR body's `## Documentation` section under a new `### Doc/ manifest drift` subheading.

- 2026-06-02T07:02:29Z [impl-recovery+qa-reverify] /CJ_implement-from-spec leaf subagent socket-disconnected mid-flight after writing templates/doc-SKILL-CATALOG-section.md, doc/SKILL-CATALOG.md (11 sections), and scripts/validate.sh Check 15. CLAUDE.md edits (### Tracked doc/ files manifest subsection + ### Skill directory structure addendum + ## Creating a new skill step 6 renumber) and tracker gates-update did NOT land before disconnect. Orchestrator applied: (a) the 3 CLAUDE.md edits manually; (b) two real-bug fixes in Check 15 caught by re-running validate.sh: the manifest-parser awk `/start/,/end/` range collapsed because both patterns matched `^### ` — switched to flag-based awk (manifest extracts 3 entries correctly); the per-section parser had the same range-collapse — same fix (sections extract correctly); the tag regex was anchored `^\(...\)` but the catalog uses markdown backticks `\`(validator)\`` — dropped the anchor since the closed enum makes anywhere-in-line matching safe. (c) test.sh manual-skill-creation integration test extended to ALSO scaffold a doc/SKILL-CATALOG.md section for zzz-test-scaffold (and back up + restore the catalog file in the EXIT trap + Step 5 inline cleanup), so Check 15 finds the section and the test passes. ./scripts/validate.sh → PASS (0 errors, all 11 catalog sections pass + 3-entry manifest consistent). ./scripts/test.sh → PASS (Failures: 0, Test 13 SKIP-with-presence-check per F000033). Phase 2 gates now green; ready for /ship.
