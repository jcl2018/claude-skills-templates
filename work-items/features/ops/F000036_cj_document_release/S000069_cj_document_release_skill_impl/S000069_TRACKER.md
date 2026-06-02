---
name: "CJ_document-release skill + cj_goal orchestrator inline wiring — implementation"
type: user-story
id: "S000069"
status: active
created: "2026-06-02"
updated: "2026-06-02"
parent: "F000036"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260602-011228-64202"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `cj-feat-20260602-011228-64202` (parent's worktree branch; ships in same PR as parent F000036)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's session) — from `templates/doc-DESIGN.md`
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
5. Run `/ship` — creates PR (against main), bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment (deferred — /CJ_goal_feature stops at PR)

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review) against main
- [ ] `/land-and-deploy` — merged and deployed (deferred)

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `skills/CJ_document-release/SKILL.md` exists with valid YAML frontmatter:
  - `name: CJ_document-release`
  - `description:` non-empty one-line summary mentioning `--docs` flag + halt-on-red + auto-commit-doc-only behavior
  - `version: 0.1.0`
  - `allowed-tools: [Bash, Read, Glob, Grep, Skill]`
- [ ] SKILL.md body contains: preamble (skills-update-check), arg parse (`--docs <comma-list>`), branch + clean-tree gate, project-context block construction, Skill(`/document-release`) invocation, halt-on-red emit with `[doc-sync-red]` marker, auto-commit doc-only with whitelist check + `[doc-sync-non-doc-write]` halt class, success summary print.
- [ ] `skills/CJ_document-release/USAGE.md` exists with all 5 required H2 sections (When to use / When NOT to use / Mental model / Common pitfalls / Related skills), each populated per parent design doc Step 1.
- [ ] `skills-catalog.json` has a new entry for CJ_document-release with:
  - `name: "CJ_document-release"`
  - `version: "0.1.0"`
  - `description` matching SKILL.md frontmatter
  - `source: "local"`
  - `depends.skills: ["document-release"]`
  - `depends.tools: ["Bash", "Read", "Glob", "Grep", "Skill"]`
  - `portability: "workbench"`
  - `files: ["skills/CJ_document-release/SKILL.md"]`
  - `templates: []`
  - `status: "experimental"`
- [ ] `doc/SKILL-CATALOG.md` has a new `### CJ_document-release` section under the Phase-step skills grouping with:
  - `**Status:** experimental (new, F000036)`
  - `**Source:** skills/CJ_document-release/SKILL.md · skills/CJ_document-release/USAGE.md`
  - `**Invoke when:** ...` line describing both orchestrator-driven (auto) and manual invocation (`/CJ_document-release [--docs <subset>]`)
  - Explicit tag line `(phase-step in /CJ_goal_feature chain)` matching Check 15's tag regex
- [ ] `skills/CJ_goal_feature/pipeline.md` has a new "Step 5.5: Doc-sync" subsection inserted between QA pass (Step 5) and `/ship` (Step 6) containing: Skill invocation of CJ_document-release (no `--docs` flag in v1), RESULT=red HALT path with `[doc-sync-red]` marker + resume_cmd `/CJ_goal_feature`, RESULT=green continue path, RESULT=green-noop continue path.
- [ ] `skills/CJ_goal_feature/SKILL.md` halt-taxonomy table has two new rows inserted after the qa-red row and before the ship-declined row: `halted_at_doc_sync` / `[doc-sync-red]` and `halted_at_doc_sync_non_doc_write` / `[doc-sync-non-doc-write]`.
- [ ] `skills/CJ_goal_defect/pipeline.md` has the same "Step 5.5: Doc-sync" subsection (modulo `<verb>` in resume_cmd).
- [ ] `skills/CJ_goal_defect/SKILL.md` halt-taxonomy table has the same two new rows in the same position.
- [ ] `skills/CJ_goal_todo_fix/pipeline.md` has the same "Step 5.5: Doc-sync" subsection (modulo `<verb>` in resume_cmd).
- [ ] `skills/CJ_goal_todo_fix/SKILL.md` halt-taxonomy table has the same two new rows in the same position.
- [ ] `tests/cj-document-release.test.sh` is executable (`chmod +x`) and tests:
  - Skill files exist (`skills/CJ_document-release/SKILL.md` + `USAGE.md`)
  - SKILL.md YAML frontmatter parses: `name`, `description`, `version`, `allowed-tools`
  - USAGE.md has all 5 required H2 sections
  - skills-catalog.json contains the CJ_document-release entry with correct path
  - doc/SKILL-CATALOG.md contains the `### CJ_document-release` section
  - `[doc-sync-red]` halt marker grep returns ≥ 1 in SKILL.md
  - `[doc-sync-non-doc-write]` halt marker grep returns ≥ 1 in SKILL.md
  - Branch refusal prose grep (e.g. "refuses on the base branch") returns ≥ 1 in SKILL.md
  - Clean-tree refusal prose grep (e.g. "Working tree has uncommitted non-doc changes") returns ≥ 1 in SKILL.md
  - `--docs` arg parsing prose mentioned (grep ≥ 1) in SKILL.md
- [ ] `tests/cj-goal-doc-sync-wiring.test.sh` is executable (`chmod +x`) and tests:
  - All 3 pipeline.md files contain "Step 5.5: Doc-sync"
  - All 3 SKILL.md halt-taxonomy tables contain `[doc-sync-red]` row
  - All 3 SKILL.md halt-taxonomy tables contain `[doc-sync-non-doc-write]` row
  - Halt-taxonomy row ordering: doc-sync rows appear after the qa-red row and before the ship-declined row in all 3 files
- [ ] `scripts/test.sh` wires both new test files in (invocation block in the appropriate phase of test.sh).
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD. The catalog audit set grows from 11 to 12 routable non-deprecated skills; Check 13 (USAGE.md presence) + Check 14 (USAGE.md drift) + Check 15a (manifest) + Check 15b (catalog completeness) all PASS for CJ_document-release.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD (superset suite: validate + cj-document-release.test.sh + cj-goal-doc-sync-wiring.test.sh + existing tests).
- [ ] `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` Big Decision #1 row has the "SUPERSEDED BY F000036 (v6.0.1)" annotation appended in-place. The annotation captures: (a) the strict capability-superset rationale (`--docs` parameterization + halt-on-red + auto-commit-doc-only); (b) F000029 marker-AUQ stays as fallback for non-orchestrator paths.
- [ ] `VERSION` reads `6.0.1`. `./scripts/check-version-queue.sh` confirmed the slot is free before /ship (no open PRs claim 6.0.1).
- [ ] `CHANGELOG.md` has a new `## [6.0.1] — 2026-06-02` entry under `### Added`, in user-forward voice, naming F000036 + the F000029 BD#1 supersession callout + the 3-orchestrator wiring.
- [ ] PR opened against main via `/ship` (pre-landing review included). /CJ_goal_feature stops at PR per design; no auto-merge, no /land-and-deploy in this PR. PR body notes F000028+F000029+F000034 lineage + F000029 BD#1 supersession.
- [ ] No upstream `/document-release` modification. No changes to `~/.claude/`, `deprecated/`, or `work-copilot/`.

## Todos

<!-- Actionable items for this story. -->

- [ ] Write `skills/CJ_document-release/SKILL.md` with YAML frontmatter (name, description, version, allowed-tools) + body covering: preamble, `--docs` arg parse, branch + clean-tree gate, project-context block, Skill(`/document-release`) invocation, halt-on-red emit, auto-commit doc-only with whitelist check, success summary.
- [ ] Write `skills/CJ_document-release/USAGE.md` with 5 required H2 sections per parent design Step 1 (When to use / When NOT to use / Mental model / Common pitfalls / Related skills).
- [ ] Append CJ_document-release entry to `skills-catalog.json` with `status: experimental`, `portability: workbench`, `depends.skills: ["document-release"]`.
- [ ] Add `### CJ_document-release` section to `doc/SKILL-CATALOG.md` under the Phase-step skills grouping with explicit tag `(phase-step in /CJ_goal_feature chain)`.
- [ ] Edit `skills/CJ_goal_feature/pipeline.md` to insert new "Step 5.5: Doc-sync" between QA pass and `/ship`.
- [ ] Edit `skills/CJ_goal_feature/SKILL.md` halt-taxonomy table to add 2 new rows after qa-red and before ship-declined.
- [ ] Edit `skills/CJ_goal_defect/pipeline.md` to insert same Step 5.5 (modulo `<verb>` in resume_cmd).
- [ ] Edit `skills/CJ_goal_defect/SKILL.md` halt-taxonomy table to add same 2 new rows.
- [ ] Edit `skills/CJ_goal_todo_fix/pipeline.md` to insert same Step 5.5 (modulo `<verb>` in resume_cmd).
- [ ] Edit `skills/CJ_goal_todo_fix/SKILL.md` halt-taxonomy table to add same 2 new rows.
- [ ] Write `tests/cj-document-release.test.sh` (executable; ≥10 assertions per parent design Step 8).
- [ ] Write `tests/cj-goal-doc-sync-wiring.test.sh` (executable; ≥5 assertions per parent design Step 8).
- [ ] Edit `scripts/test.sh` to wire both new test files into the test phase.
- [ ] Append "SUPERSEDED BY F000036 (v6.0.1)" annotation to `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` Big Decision #1 row in-place.
- [ ] Run `./scripts/check-version-queue.sh` to confirm 6.0.1 slot is free.
- [ ] Bump `VERSION` to `6.0.1`.
- [ ] Write `CHANGELOG.md` entry for `## [6.0.1] — 2026-06-02` under `### Added`, user-forward voice, naming F000036 + supersession.
- [ ] Run `./scripts/validate.sh` locally → expect 0 errors / 0 warnings.
- [ ] Run `./scripts/test.sh` locally → expect exit 0.
- [ ] Stage all 16 files in one atomic commit (pre-commit hook + Check 13 + Check 15 require atomic landing) → `/ship` against main with diff-review AUQ suppressed (orchestrator behavior).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-02: Created. Single-story decomposition of F000036 — SKILL.md + USAGE.md + catalog entry + doc/SKILL-CATALOG.md section + 3 pipeline.md edits (Step 5.5: Doc-sync) + 3 SKILL.md halt-taxonomy edits (2 new rows) + 2 tests + scripts/test.sh wiring + F000029_DESIGN.md BD#1 supersession annotation + VERSION + CHANGELOG. Branch cut from origin/main HEAD `006ffe3` (post-F000034 merged + WIP commit); auto-created by /CJ_goal_feature worktree phase. No upstream stacking.
- 2026-06-02 [QA pass — Phase 2 gates green]: /CJ_qa-work-item leaf run completed. Smoke: S1 (cj-document-release.test.sh) exit 0, 17 OKs; S2 (cj-goal-doc-sync-wiring.test.sh) exit 0, 18 OKs; S3 (grep wiring + halt markers) all 4 OK; S4 (./scripts/validate.sh && ./scripts/test.sh) both exit 0 (validate: 0 errors / 0 warnings, audit set = 12 routable skills with CJ_document-release passing Check 13/14/15; test: 0 failures). S5 (F000029 supersession grep) OK; VERSION + CHANGELOG checks deferred-to-ship by design (orchestrator's /ship step handles bumps). E2E pre-ship: E1 (docs readable, 363+89 lines), E2 (Step 5.5 symmetric in all 3 pipeline.md modulo verb), E3 (validate+test green pre-ship) all PASS. Phase 2 gates transitioned green; ready for Phase 3 /ship.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_document-release/SKILL.md` (NEW — wrapper skill, ~80-120 lines)
- `skills/CJ_document-release/USAGE.md` (NEW — 5 required H2 sections)
- `skills-catalog.json` (MODIFIED — new entry appended)
- `doc/SKILL-CATALOG.md` (MODIFIED — new `### CJ_document-release` section)
- `skills/CJ_goal_feature/pipeline.md` (MODIFIED — new Step 5.5: Doc-sync)
- `skills/CJ_goal_feature/SKILL.md` (MODIFIED — halt-taxonomy: 2 new rows)
- `skills/CJ_goal_defect/pipeline.md` (MODIFIED — same Step 5.5)
- `skills/CJ_goal_defect/SKILL.md` (MODIFIED — same halt-taxonomy rows)
- `skills/CJ_goal_todo_fix/pipeline.md` (MODIFIED — same Step 5.5)
- `skills/CJ_goal_todo_fix/SKILL.md` (MODIFIED — same halt-taxonomy rows)
- `tests/cj-document-release.test.sh` (NEW — unit-shape tests)
- `tests/cj-goal-doc-sync-wiring.test.sh` (NEW — integration-shape tests)
- `scripts/test.sh` (MODIFIED — wire both test files in)
- `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` (MODIFIED — BD#1 supersession annotation in-place)
- `VERSION` (MODIFIED — 5.0.19 → 6.0.1)
- `CHANGELOG.md` (MODIFIED — [6.0.1] entry)

## Insights

<!-- Non-obvious findings worth remembering. -->

- **First workbench skill with explicit "thin wrapper around upstream gstack skill" shape.** `/CJ_document-release` calls `/document-release` via the Skill tool. If we later want similar wrappers for other upstream skills (`/CJ_ship`? `/CJ_review`?), this is the template.
- **Project-context block to `/document-release` is documentation-only, not programmatic.** The block tells `/document-release` "this run is filtered to <subset>; audit ONLY those categories and skip the rest." If `/document-release` honors the request, filtering works; if it audits everything anyway, CJ_document-release still auto-commits whatever the upstream skill produced. Best-effort filter, not enforced filter — the workbench skill doesn't reach into upstream to gate which audits fire.
- **Doc-only auto-commit whitelist is conservative on purpose.** Whitelist = `README\|CHANGELOG\|CLAUDE\|ARCHITECTURE.md` + `doc/.+\.md` + `templates/doc-.*\.md`. Anything outside → HALT with `[doc-sync-non-doc-write]`. Stealth code edits via the doc-sync surface would be a serious security/integrity surface; the conservative whitelist closes that door without operator override. Extending whitelist is a follow-up if false-positive surfaces in dogfood.
- **`HAS_CHART >= 2` doesn't apply to CJ_document-release's catalog section.** Per F000034 Check 15b, the chart-OR-tag predicate is `(HAS_CHART >= 2) OR (HAS_TAG >= 1)`. CJ_document-release is classified as a phase-step skill and uses the tag, not a chart. A one-box chart is less informative than the `(phase-step in /CJ_goal_feature chain)` tag.
- **Atomic-commit ordering through pre-commit hook covers 16 files.** Validate.sh Check 13 (USAGE.md presence) would BLOCK any intermediate commit between SKILL.md and USAGE.md landing. Check 15b (per-skill catalog completeness) would BLOCK any intermediate commit between catalog entry and doc/SKILL-CATALOG.md section landing. Stage everything once.
- **Halt-on-red is a hard halt, not a warning.** `[doc-sync-red]` propagates as a build failure; orchestrator HALTs with journal entry naming resume_cmd. Cron-mode `/CJ_goal_todo_fix --quiet` suppresses summary banners + AUQs but NOT halt-on-red contracts (memory `feedback_skill_contracts_strict`: WARN gets ignored; ERROR-with-cheap-override is load-bearing).
- **F000029 marker-AUQ STAYS as fallback (not deprecated).** Non-orchestrator paths (raw `git push`, manual `/ship` from outside cj_goal pipeline) still need a doc-drift surface. The two mechanisms layer; they don't fight. F000036 fires inline in orchestrator paths; F000029 fires on next-session for non-orchestrator paths.
- **In-place BD#1 supersession in F000029_DESIGN.md is the legitimate-reopen audit pattern.** Future readers scanning F000029 BD#1 see "SUPERSEDED BY F000036 (v6.0.1)" + rationale immediately. Git blame preserves the original; the annotation makes the supersession discoverable without commit-history archaeology.
- **3-way symmetric edits across cj_goal_feature/defect/todo_fix is the right shape.** Memory `feedback_premise_gate_reframe`: cleaner architecture (one skill, three thin invocations) over scope-creep (three different per-verb behaviors). The Step 5.5 block is identical modulo the `<verb>` in resume_cmd. Tests/cj-goal-doc-sync-wiring.test.sh asserts the symmetry.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-02 [decision] Approach A (new SKILL.md skill) chosen over B (hybrid skill + script helper) and C (inline triplicate in 3 pipeline.md). Summary: A reuses the just-shipped F000032+F000033+F000034 pattern; `--docs` flag + halt-on-red + auto-commit-doc-only live in one skill folder. C is the exact anti-pattern F000029 BD#1 itself flagged when rejecting its own internal "Approach A" — same reason.
- 2026-06-02 [decision] Single user-story decomposition (atomic implementation across 16 files). Summary: SKILL.md + USAGE.md + catalog + SKILL-CATALOG.md section + 3 pipeline.md edits + 3 SKILL.md halt-taxonomy edits + 2 tests + scripts/test.sh wiring + F000029 BD#1 annotation + VERSION + CHANGELOG all ship atomically. Same shape as F000032 (S000065), F000033 (S000066), F000034 (S000067). Splitting adds bookkeeping without splitting risk.
- 2026-06-02 [decision] F000029 BD#1 superseded; in-place annotation in F000029_DESIGN.md. Summary: F000029 rejected new-skill shape three weeks ago citing "adds to catalog forever" + "extra invocation hop." This PR reopens with strict capability-superset (`--docs` + halt-on-red + auto-commit) that earns the catalog cost. In-place annotation keeps audit trail navigable.
- 2026-06-02 [decision] F000029 marker-AUQ STAYS as fallback (not deprecated). Summary: Non-orchestrator paths (raw `git push`, manual `/ship` from outside cj_goal pipeline) still need doc-drift surface. Two mechanisms layer; F000036 fires inline in orchestrator paths, F000029 fires on next-session for non-orchestrator paths.
- 2026-06-02 [decision] All 3 cj_goal orchestrators get identical Step 5.5 wiring (modulo `<verb>` in resume_cmd). Summary: Uniform across the family. Single evolution surface (the skill itself) for future per-verb behavior — divergence would mean adding orchestrator-specific args, not duplicated logic.
- 2026-06-02 [decision] Halt-on-red is hard halt; doc-sync failure = build failure. Summary: Per memory `feedback_skill_contracts_strict` + F000030/F000032/F000033/F000034 precedent: WARN gets ignored; ERROR-with-cheap-override is load-bearing. CJ_document-release returning non-green emits `[doc-sync-red]` marker the orchestrator treats as build failure. Cron `--quiet` doesn't suppress halt contracts.
- 2026-06-02 [decision] Doc-only auto-commit whitelist: `^(README\|CHANGELOG\|CLAUDE\|ARCHITECTURE)\.md$` + `^doc/.+\.md$` + `^templates/doc-.*\.md$`. Summary: Conservative > permissive. Anything outside → `[doc-sync-non-doc-write]` HALT (new halt class for upstream-misbehaved case). Stealth code edits via doc-sync surface would be serious; whitelist closes that door.
- 2026-06-02 [decision] `[doc-sync-non-doc-write]` is a new halt class. Summary: Distinct from `[doc-sync-red]` — `[doc-sync-red]` = `/document-release` itself failed (audit error, mid-write failure); `[doc-sync-non-doc-write]` = `/document-release` succeeded but wrote files outside the whitelist (upstream-skill misbehavior or bug). Separating them gives diagnostic clarity in the halt journal.
- 2026-06-02 [decision] `portability: workbench` for the catalog entry. Summary: This skill depends on workbench-specific conventions; explicit signal. Other CJ_* skills could be retroactively normalized; deferred.
- 2026-06-02 [decision] PR-stop at /ship per /CJ_goal_feature semantics; no /land-and-deploy in this PR. Summary: /CJ_goal_feature stops at PR by design — PR is the architecture gate (human review). Per memory `project_workbench_auto_deploy_unsafe`, auto-deploy is unsafe (cj-handoff-gate denylist blocks the skill surfaces every feature touches). Step 5.5 wiring works with PR-stop precisely because same-PR shape doesn't depend on /land-and-deploy.
- 2026-06-02 [decision] No upstream `/document-release` modification (workbench-only). Summary: Per memory `feedback_workbench_scope` + `project_workbench_auto_deploy_unsafe`. Upstream invoked via Skill tool with project-context priming; filter/halt/auto-commit logic lives in workbench skill, not upstream. Mirrors F000034 precedent.
- 2026-06-02 [decision] No validate.sh changes needed. Summary: Existing Check 13 (USAGE.md presence) + Check 14 (USAGE.md drift) + Check 15a (manifest) + Check 15b (catalog completeness) all auto-cover CJ_document-release once it's added with `status: experimental` + `files: [...SKILL.md]`. Audit set grows from 11 to 12 skills.
