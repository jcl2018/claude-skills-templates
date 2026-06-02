---
name: "Per-skill USAGE.md convention + audit — implementation"
type: user-story
id: "S000065"
status: active
created: "2026-06-01"
updated: "2026-06-01"
parent: "F000032"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260601-152835-3769"
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
2. Create working branch: `git checkout -b cj-feat-20260601-152835-3769` (shipping in same PR as parent)
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
- [x] Tasks broken down (or N/A — atomic story)

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

- [ ] `templates/doc-SKILL-USAGE.md` exists with the five required H2 headings (`^## When to use$`, `^## When NOT to use$`, `^## Mental model$`, `^## Common pitfalls$`, `^## Related skills$`) plus DESIGN.md-shaped frontmatter (skill-name, version, status, created, last-updated).
- [ ] For each name returned by `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json` (currently: CJ_system-health, CJ_personal-workflow, CJ_goal_todo_fix, CJ_scaffold-work-item, CJ_qa-work-item, CJ_implement-from-spec, CJ_personal-pipeline, CJ_suggest, CJ_improve-queue, CJ_goal_feature, CJ_goal_defect — 11 skills), `skills/{name}/USAGE.md` exists with all five required H2 sections filled (not empty placeholders) using content distilled from that skill's SKILL.md description and `rules/skill-routing.md`.
- [ ] `scripts/validate.sh` has a new Check 13 block that: (a) iterates the audit set above, (b) ERRORs if `skills/{name}/USAGE.md` is missing, (c) ERRORs per missing required H2 (line-anchored grep `^## When to use$` etc.), (d) prints `PASS: skills/{name}/USAGE.md has all required sections` on success.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD.
- [ ] `doc/PHILOSOPHY.md` has a NEW top-level `## Documentation surfaces` section placed between `## Key patterns and conventions` and `## Decision tree`, documenting the three-doc-per-skill model (SKILL.md required, USAGE.md required for routable non-deprecated skills, DESIGN.md optional) and naming Check 13 as the audit rule.
- [ ] Each active-skill entry under `doc/PHILOSOPHY.md ## Decision tree` is appended with a USAGE link (relative path: `[USAGE](../skills/{name}/USAGE.md)`).
- [ ] `CLAUDE.md` "Skill directory structure" lists `USAGE.md` as required between `SKILL.md` and `*.md  # optional supporting files`.
- [ ] `CLAUDE.md` "Creating a new skill" section adds a step (between current step 4 and step 5) instructing new-skill authors to create `skills/{name}/USAGE.md` from `templates/doc-SKILL-USAGE.md`; existing DESIGN.md step is rephrased to clarify it stays optional.
- [ ] `skills-catalog.json` is NOT modified — no USAGE.md added to `files` arrays, no `templates/doc-SKILL-USAGE.md` added to any `templates` entry.
- [ ] `~/.claude/` is unaffected: skills-deploy does not need to copy USAGE.md or the new template anywhere; running `skills-deploy install` after this PR does not produce drift findings about USAGE.md.
- [ ] `deprecated/` skills (5 shims: CJ_goal_run, CJ_goal_auto, CJ_goal_investigate, cj_goal_feature, cj_goal_defect) do NOT get USAGE.md; `work-copilot/` is untouched.
- [ ] CHANGELOG.md has an entry for the next free version slot (queried via `./scripts/check-version-queue.sh`) describing the feature in user-forward voice.

## Todos

<!-- Actionable items for this story. -->

- [ ] Write `templates/doc-SKILL-USAGE.md` (five required H2 sections + DESIGN.md-shaped frontmatter + 2-3 line prompt per section explaining what belongs there)
- [ ] Write 11 backfill `skills/{name}/USAGE.md` files (distill content from each SKILL.md description + rules/skill-routing.md)
- [ ] Add Check 13 to `scripts/validate.sh` (after current Check 12 at scripts/validate.sh:518; line-anchored greps; ERROR on missing file or missing H2)
- [ ] Add `## Documentation surfaces` section to `doc/PHILOSOPHY.md` (between `## Key patterns and conventions` and `## Decision tree`)
- [ ] Append `[USAGE](../skills/{name}/USAGE.md)` link to each active-skill decision-tree entry in `doc/PHILOSOPHY.md`
- [ ] Update `CLAUDE.md` "Skill directory structure" — add `USAGE.md` line
- [ ] Update `CLAUDE.md` "Creating a new skill" — new step 5 for USAGE.md; renumber existing 5-6 to 6-7; rephrase DESIGN.md step
- [ ] Run `./scripts/validate.sh` locally → expect 0 errors / 0 warnings
- [ ] Run `./scripts/test.sh` locally → expect exit 0
- [ ] Write CHANGELOG.md entry (next free version slot)
- [ ] Stage all changes in one commit (atomic-ordering for pre-commit hook) → `/ship`

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-01: Created. Single-story decomposition of F000032 — template + 11 USAGE.md backfills + validate.sh Check 13 + CLAUDE.md edits + PHILOSOPHY.md `## Documentation surfaces` + decision-tree USAGE links.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `templates/doc-SKILL-USAGE.md` (NEW)
- `skills/CJ_system-health/USAGE.md` (NEW)
- `skills/CJ_personal-workflow/USAGE.md` (NEW)
- `skills/CJ_goal_todo_fix/USAGE.md` (NEW)
- `skills/CJ_scaffold-work-item/USAGE.md` (NEW)
- `skills/CJ_qa-work-item/USAGE.md` (NEW)
- `skills/CJ_implement-from-spec/USAGE.md` (NEW)
- `skills/CJ_personal-pipeline/USAGE.md` (NEW)
- `skills/CJ_suggest/USAGE.md` (NEW)
- `skills/CJ_improve-queue/USAGE.md` (NEW)
- `skills/CJ_goal_feature/USAGE.md` (NEW)
- `skills/CJ_goal_defect/USAGE.md` (NEW)
- `scripts/validate.sh` (MODIFIED — add Check 13)
- `doc/PHILOSOPHY.md` (MODIFIED — new `## Documentation surfaces` section + decision-tree USAGE links)
- `CLAUDE.md` (MODIFIED — Skill directory structure + Creating a new skill steps)
- `CHANGELOG.md` (MODIFIED — F000032 entry)

## Insights

<!-- Non-obvious findings worth remembering. -->

- **Line-anchored grep is load-bearing.** `^## When to use$` with `grep -qE` rejects substring matches inside fenced code blocks. A naive `grep -F` would falsely pass on USAGE.md whose body quotes the required heading inside ```` ``` ```` markers.
- **Atomic-commit is the only ordering constraint.** Pre-commit hook runs validate.sh; if Check 13 lands in a commit before all 11 USAGE.md files, the hook blocks. /ship stages everything once at the end — natural fit. Only failure mode is operator running `git commit` mid-implement on partial state.
- **Audit set is computed, not hard-coded.** Check 13 derives the audit set from `skills-catalog.json` via jq each run. Adding a new routable skill automatically requires USAGE.md; deprecating one automatically excludes it. No coupling between the audit and the explicit list of names.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-01 [decision] Single-story decomposition of F000032 (no further sub-tasks). Summary: All 11 USAGE.md backfills + the new template + validate.sh Check 13 + CLAUDE.md edits + PHILOSOPHY.md edits ship as one atomic commit. Pre-commit hook's atomic-ordering requirement (validate.sh runs Check 13 against the audit set; intermediate states fail) makes splitting into sub-tasks counterproductive. Mirrors F000030's single-story shape (S000063 carried all of F000030's work).
- 2026-06-01 [gates-update] Phase 2 Implement complete. Summary: Wrote `templates/doc-SKILL-USAGE.md` + 11 USAGE.md backfills (CJ_system-health, CJ_personal-workflow, CJ_goal_todo_fix, CJ_scaffold-work-item, CJ_qa-work-item, CJ_implement-from-spec, CJ_personal-pipeline, CJ_suggest, CJ_improve-queue, CJ_goal_feature, CJ_goal_defect). Added validate.sh Check 13 (line-anchored H2 grep over the `status != "deprecated"` + non-empty-files predicate). Updated CLAUDE.md "Skill directory structure" + "Creating a new skill" steps. Added `doc/PHILOSOPHY.md ## Documentation surfaces` section between Key patterns and Decision tree; appended `[USAGE](../skills/{name}/USAGE.md)` links to the 6 quick-rule-of-thumb rows and the 5 internal phase-step skill rows. validate.sh and /ship deferred to subsequent phase (atomic-commit ordering — pre-commit hook would block intermediate state).
- 2026-06-01 [qa-fail] /CJ_qa-work-item leaf subagent under /CJ_goal_feature ran against uncommitted working tree. Summary: validate.sh PASS (0 errors / 0 warnings; Check 13 fires + passes for all 11 USAGE.md). Smoke S1+S2 PASS (template + 11 USAGE.md all have 5 required H2). Smoke S3 PASS (renaming skills/CJ_suggest/USAGE.md makes validate.sh exit 1 with `ERROR: skills/CJ_suggest/USAGE.md missing`; restore returns to PASS). Smoke S4 PASS (deleting the `^## When to use$` line makes validate.sh exit 1 with `ERROR: skills/CJ_suggest/USAGE.md missing section heading: ## When to use`; restore returns to PASS). File counts: 11 USAGE.md + 11 with `^## When to use$` (line-anchored). CLAUDE.md + doc/PHILOSOPHY.md edits present. **Smoke S5 FAIL: ./scripts/test.sh exits 1 with `FAIL: validate.sh fails after manual skill creation`** (test.sh:200) — the integration test scaffolds a `zzz-test-scaffold` skill with only SKILL.md (the CLAUDE.md-guided shape pre-F000032). Check 13 now requires USAGE.md for every routable non-deprecated skill, so the synthesized scaffold fails the audit. Test fixture must be updated alongside the new check to also create `skills/zzz-test-scaffold/USAGE.md`. Phase 2 QA-owned gates (`Smoke tests pass`, `Acceptance criteria verified met`) NOT transitioned. RESULT=red. Follow-up implement-phase task: extend scripts/test.sh:179-194 to also write a templated USAGE.md for zzz-test-scaffold (and ensure the EXIT trap cleanup at line 177 includes the USAGE.md path).

- 2026-06-01T23:09:08Z [qa-reverify] Orchestrator applied one-line fix to scripts/test.sh:194 (added USAGE.md scaffolding for zzz-test-scaffold inside the existing integration-test heredoc block; EXIT trap unchanged — `rm -rf $SKILLS_DIR/zzz-test-scaffold` already covers the new file). Re-ran ./scripts/test.sh → RESULT: PASS (Failures: 0, all 12 tests OK). ./scripts/validate.sh → PASS (0 errors / 0 warnings; Check 13 + all 11 USAGE.md). Phase 2 QA-owned gates now green; ready for /ship.
