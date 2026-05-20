---
name: "v5.0.0 alias removal — delete /CJ_run and /CJ_goal"
type: task
id: "T000034"
status: active
created: "2026-05-19"
updated: "2026-05-19"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/vigorous-panini-fa76f6"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/v5_alias_removal`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [ ] Parent scope read (parent tracker reviewed)
- [ ] Working branch created (`branch` field populated)
- [ ] Required docs scaffolded (test-plan)
- [ ] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigorous-panini-fa76f6-design-20260519-183906.md`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

**Deletions / migrations (6):**

- [x] **Edit 1:** `git rm -r skills/CJ_run/` — delete the alias skill directory entirely.
- [x] **Edit 2:** `git rm -r skills/CJ_goal/` — delete the alias skill directory entirely.
- [x] **Edit 3:** Remove the two catalog entries via jq (don't trust line numbers):
      ```bash
      jq 'del(.[] | select(.name == "CJ_run" or .name == "CJ_goal"))' \
        skills-catalog.json > skills-catalog.json.tmp \
        && mv skills-catalog.json.tmp skills-catalog.json
      ```
      Verify length drops by exactly 2.
- [x] **Edit 4:** `rules/skill-routing.md` — drop the "Legacy aliases (v4.x grace window;
      removed in v5.0.0):" block (currently lines 19-22). Anchor by literal block text, not line numbers.
- [x] **Edit 5:** `README.md` — remove the `| CJ_run | ...` and `| CJ_goal | ...` table rows. Run
      `scripts/generate-readme.sh` after the catalog edit; the table regenerates from the
      catalog deterministically.
- [x] **Edit 6:** `tests/eval/CJ_goal/` migration — TWO coordinated changes:
      - `git mv tests/eval/CJ_goal tests/eval/CJ_goal_todo_fix`
      - Rewrite fixture content (7 dirs, ~25 inline `/CJ_goal` references in `prompt.md`,
        `expected.schema.json`, `fixture/TODOS.md`):
        ```bash
        find tests/eval/CJ_goal_todo_fix -type f \( -name '*.md' -o -name '*.json' \) \
          -exec sed -i '' 's|/CJ_goal\b|/CJ_goal_todo_fix|g' {} +
        ```
        (macOS workbench uses `sed -i ''`; Linux CI uses `sed -i` without quotes.) Verify
        with `grep -r '/CJ_goal\b' tests/eval/CJ_goal_todo_fix/` returning empty.

**Documentation bumps (3):**

- [x] **Edit 7:** `CLAUDE.md` (workbench) — remove the "Legacy aliases /CJ_run and /CJ_goal
      remain through v4.x..." line in the "Skill routing" section.
- [x] **Edit 8:** `VERSION` — bump from `4.6.15` to `5.0.0`.
- [x] **Edit 9:** `CHANGELOG.md` — prepend a `## v5.0.0` section explaining the breaking
      change, the deprecation timeline served (v4.0.0 → v4.6.15), and the canonical
      replacements (`/CJ_goal_run`, `/CJ_goal_todo_fix`).

**Follow-up TODO (added inline in this same PR's TODOS.md edit):**

- [x] **Edit 10:** Append a row to `TODOS.md`:
      `chore: post-v5.0.0 telemetry fallback-read cleanup (~20 LOC across 4 files referencing
      legacy CJ_run.jsonl / CJ_goal.jsonl analytics paths)`. P3, S. So it doesn't get lost.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-19: Created. Scaffolded by /CJ_scaffold-work-item from design doc
  chjiang-claude-vigorous-panini-fa76f6-design-20260519-183906.md (Approach A:
  minimal cut — delete 2 alias skills + 6 doc/test surfaces + 3 doc bumps).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_run/` — DELETE (entire dir, alias skill removed per v5.0.0 grace window expiry)
- `skills/CJ_goal/` — DELETE (entire dir, alias skill removed per v5.0.0 grace window expiry)
- `skills-catalog.json` — REMOVE the two catalog entries (`name == "CJ_run"`, `name == "CJ_goal"`) via jq rewrite
- `rules/skill-routing.md` — REMOVE the "Legacy aliases (v4.x grace window; removed in v5.0.0):" block
- `README.md` — REGENERATE via `scripts/generate-readme.sh` after catalog edit (drops the two table rows)
- `tests/eval/CJ_goal/` → `tests/eval/CJ_goal_todo_fix/` — `git mv` + content rewrite (7 fixture dirs, ~25 inline references)
- `CLAUDE.md` — REMOVE legacy-aliases line in "Skill routing" section
- `VERSION` — BUMP `4.6.15` → `5.0.0`
- `CHANGELOG.md` — PREPEND v5.0.0 entry with breaking-change + canonical-name migration
- `TODOS.md` — APPEND P3/S row for post-v5.0.0 telemetry fallback-read cleanup

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

**Source:** `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigorous-panini-fa76f6-design-20260519-183906.md` (Approach A: minimal cut, chosen over Approach B [complete cut including telemetry fallback removal] and Approach C [defer v5.0.0]).

**Why minimal cut over complete cut:** Approach B rolls telemetry fallback-read cleanup (~20 LOC across 4 files) into the breaking-change PR, conflating "remove deprecated public surface" with "remove internal dead code." Cleaner to track the cosmetic cleanup as a P3 TODO row post-v5.0.0. Approach A keeps the v5.0.0 PR narrowly scoped to the contract-honored deletion.

**Why not defer v5.0.0:** the deprecation banner has been live for ~7 months across v4.0.0 - v4.6.15. There's no other v5.0-gated work in TODOS.md to bundle with, and "wait for a better v5.0" is kick-the-can: no forcing function for the next breaker, banner stays forever.

**Catalog edit via jq, not line-number sed.** `skills-catalog.json` is a bare JSON array; jq-driven `del(.[] | select(.name == "CJ_run" or .name == "CJ_goal"))` is order-independent and survives any future reordering of the array. Validate length drops by exactly 2 before/after as a sanity gate.

**README regenerates from catalog.** `scripts/generate-readme.sh` reads `skills-catalog.json` and rebuilds the skill table deterministically. Run it AFTER the catalog edit — no manual README diff needed; the script produces the cleaned README.

**Test fixture migration is two coordinated changes, not one.** `tests/eval/CJ_goal/` exists because the eval harness historically referenced the un-prefixed name; the 7 fixture dirs still test `/CJ_goal_todo_fix` preflight gates. Two changes required: (a) `git mv` the dir to `tests/eval/CJ_goal_todo_fix/`, (b) `sed -i '' 's|/CJ_goal\b|/CJ_goal_todo_fix|g'` over the 7 fixture-content files (~25 inline references in `prompt.md`, `expected.schema.json`, `fixture/TODOS.md`). After the alias is deleted, those prompts would fail with "skill not found" if the content wasn't rewritten. `scripts/eval.sh` and `.github/workflows/eval-nightly.yml` do NOT hardcode the path (they iterate `tests/eval/*/`), so the dir rename needs no harness wiring change.

**Telemetry fallback-reads explicitly out of scope.** ~20 LOC across `skills/CJ_goal_run/SKILL.md` (lines 146, 164, 267), `skills/CJ_goal_run/run.md` (lines 1434-1436), `skills/CJ_goal_todo_fix/SKILL.md` (line 249), `skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (lines 40, 45) reference the legacy `CJ_run.jsonl` / `CJ_goal.jsonl` paths. These are cheap to keep (preserve historical analytics for the sunset-trip-wire). Tracked as a follow-up TODO row in this same PR's TODOS.md edit so it doesn't get lost.

**Work-item tracker journals stay untouched.** Two T-trackers (`T000026_TRACKER.md`, `T000027_TRACKER.md`) reference legacy alias names in their commit history. These are historical-record entries documenting past commits — don't rewrite history. Leave as-is.

**Operator analytics files on existing machines stay untouched.** `~/.gstack/analytics/CJ_run.jsonl` and `CJ_goal.jsonl` on operator machines are individual operator analytics, not workbench artifacts. No cleanup script ships with v5.0.0.

**`work-copilot/` is unaffected.** Reviewer-verified: `grep -rE 'CJ_(run|goal)([^_]|$)' work-copilot/` returns nothing. The Copilot consumer bundle does not surface these aliases.

**Squash-merge convention applies.** Per CLAUDE.md: `gh pr merge <PR#> --squash --delete-branch` without `--auto`. Verify `gh pr view <PR#> --json state -q .state` returns `MERGED` before any branch cleanup.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigorous-panini-fa76f6-design-20260519-183906.md -->

- 2026-05-19 [decision] Approach A (minimal cut) chosen over Approach B (complete cut) and Approach C (defer v5.0.0). Rationale: honor the deprecation contract on the published timeline; keep the breaking-change PR narrowly scoped; track cosmetic cleanup separately. (Premise 1: aliases get removed in v5.0.0. Premise 2: v5.0.0 ships alias-removal-only.)
- 2026-05-19 [decision] Scope ceiling locked at 9 surfaces: 6 deletions/migrations + 3 documentation bumps. Anything beyond this list is scope creep for v5.0.0.
- 2026-05-19 [decision] Telemetry fallback-reads (~20 LOC, 4 files) deferred to a follow-up P3/S TODO row appended in this same PR. Cosmetic-only; no live consumers post-removal.
- 2026-05-19 [finding] `tests/eval/CJ_goal/` migration is two coordinated changes: `git mv` the dir AND `sed -i ''` rewrite the 7 fixture-content files (~25 inline `/CJ_goal` references). Without the content rewrite, fixture prompts would fail with "skill not found" after the alias is deleted.
- 2026-05-19 [finding] `work-copilot/` bundle unaffected — `grep -rE 'CJ_(run|goal)([^_]|$)' work-copilot/` returns nothing.
- 2026-05-19 [impl-decision] Catalog edit applied via jq (per Edit 3 contract); array length dropped 14 → 12 (exact delta 2). Both `CJ_run` and `CJ_goal` entries removed; no orphaned references in remaining 12 entries.
- 2026-05-19 [impl-decision] README.md regenerated via `./scripts/generate-readme.sh > README.md` (script prints to stdout — needed shell redirect to land on disk). Post-regen grep `^\| (CJ_run|CJ_goal) \|` returns empty (alias table rows removed).
- 2026-05-19 [impl-finding] macOS BSD `sed` does not honor `\b` word-boundary the way GNU sed does — the test-plan's documented `sed -i '' 's|/CJ_goal\b|/CJ_goal_todo_fix|g'` command produced zero substitutions on the workbench. Replaced with a two-pass BSD-compatible regex: `sed -i '' -E 's|/CJ_goal$|/CJ_goal_todo_fix|g; s|/CJ_goal([^_a-zA-Z0-9])|/CJ_goal_todo_fix\1|g'`. Post-rewrite verification `grep -r '/CJ_goal\b' tests/eval/CJ_goal_todo_fix/` returns empty (the original test-plan AC #5 form still passes via BSD grep's different boundary semantics). 25 references rewritten across 7 fixture dirs.
- 2026-05-19 [impl] Wrote 9 surface edits: 2 dir deletions (skills/CJ_run, skills/CJ_goal), 1 catalog edit, 1 routing-rules edit, 1 README regen, 1 fixture rename + content rewrite, 1 CLAUDE.md edit, 1 VERSION bump, 1 CHANGELOG prepend. Plus 1 follow-up TODO row appended. Phase 2 implementer-owned gates → green. Commit-owned gate (`Core changes committed`) untouched (owned by /ship).
- 2026-05-19 [impl-auto] Auto-mode run; --auto honored — change is sensitive-surface (catalog + routing-rules + validator-script invocations) but pre-collected AUQs approved each (sensitive-surface-catalog, sensitive-surface-validator-invoked, sensitive-surface-test-invoked).
- 2026-05-19 [impl-pass] T000034: implementation complete. Phase 2 implementer-owned gates transitioned. Ready for /ship.
- 2026-05-19 [qa-boundary] Phase 2 implementer-owned gates green (Todos + Files); commit-owned gate (`Core changes committed`) unchecked per task-type contract (commit lands at /ship). Proceeding to test-plan verification on staged tree (MEMORY.md project_cj_personal_pipeline_task_type_qa_halt — surface verification evidence).
- 2026-05-19 [qa-smoke] 1 (alias dirs deleted): green — `ls skills/CJ_run skills/CJ_goal` returns "No such file or directory" for both.
- 2026-05-19 [qa-smoke] 2 (catalog entries removed): green — `jq '[.[] | select(.name == "CJ_run" or .name == "CJ_goal")] | length'` returns 0; total length 12 (delta exactly 2 from pre-edit 14).
- 2026-05-19 [qa-smoke] 3 (skill-routing rule block removed): green — `grep -c 'Legacy aliases (v4.x grace window' rules/skill-routing.md` returns 0.
- 2026-05-19 [qa-smoke] 4 (README regenerated cleanly): green — `grep -E '^\| (CJ_run\|CJ_goal) \|' README.md` returns 0 matching lines.
- 2026-05-19 [qa-smoke] 5 (test fixture migration + content rewrite): green — dir renamed (`tests/eval/CJ_goal_todo_fix` exists, `tests/eval/CJ_goal` absent); `grep -r '/CJ_goal\b' tests/eval/CJ_goal_todo_fix/` returns empty.
- 2026-05-19 [qa-smoke] 6 (CLAUDE.md legacy-aliases line removed): green — `grep -c 'Legacy aliases /CJ_run and /CJ_goal' CLAUDE.md` returns 0.
- 2026-05-19 [qa-smoke] 7 (VERSION bumped to 5.0.0): green — `cat VERSION` outputs `5.0.0`.
- 2026-05-19 [qa-smoke] 8 (CHANGELOG v5.0.0 entry prepended): green — `head -20 CHANGELOG.md` shows `## v5.0.0 - 2026-05-19` header with breaking-change + canonical-name migration narrative (`/CJ_run` → `/CJ_goal_run`, `/CJ_goal` → `/CJ_goal_todo_fix`).
- 2026-05-19 [qa-smoke] 9 (follow-up TODO row appended): green — TODOS.md line 252 has `### Post-v5.0.0: rip out legacy telemetry fallback-reads (P3, S)` heading, body lists all 4 files (`skills/CJ_goal_run/SKILL.md`, `skills/CJ_goal_run/run.md`, `skills/CJ_goal_todo_fix/SKILL.md`, `skills/CJ_goal_todo_fix/scripts/todo_fix.sh`).
- 2026-05-19 [qa-smoke] 10 (validate.sh passes): green — `./scripts/validate.sh` exit 0; final `RESULT: PASS` with `Errors: 0, Warnings: 0`.
- 2026-05-19 [qa-smoke] 11 (test.sh passes): green — `./scripts/test.sh` exit 0; final `RESULT: PASS` with `Failures: 0`; cj-worktree-init + drain-one-todo + investigate-did-allocator regression suites all green.
- 2026-05-19 [qa-smoke] 12 (eval-nightly wiring unaffected): green — `grep -E 'tests/eval/CJ_goal($|/)' .github/workflows/eval-nightly.yml scripts/eval.sh` returns empty (no hardcoded old path; both iterate `tests/eval/*/`).
- 2026-05-19 [qa-smoke] 13 (work-copilot/ bundle untouched): green — `grep -rE 'CJ_(run|goal)([^_]|$)' work-copilot/` returns empty.
- 2026-05-19 [qa-smoke-manual] 14 (post-deploy /CJ_run errors on fresh session): pending human verification — requires post-merge `git pull` + `./scripts/skills-deploy install` on operator machine, then `/CJ_run` in fresh Claude Code session.
- 2026-05-19 [qa-smoke-manual] 15 (post-deploy /CJ_goal errors on fresh session): pending human verification — same shape as #14 with `/CJ_goal`.
- 2026-05-19 [qa-smoke-manual] 16 (post-deploy canonical names still work): pending human verification — post-deploy `/CJ_goal_run --help` and `/CJ_goal_todo_fix --help` should resolve and print usage.
- 2026-05-19 [qa-smoke-manual] 17 (PR squash-merge succeeds): pending human verification — verified at `/land-and-deploy` time via `gh pr view <PR#> --json state -q .state` returning `MERGED`.
- 2026-05-19 [qa-smoke-summary] green: 13/13 automated rows green (4 manual rows pending post-deploy).
- 2026-05-19 [qa-pass] T000034 (task): green smoke from test-plan rows (13 automated + 4 manual-pending). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. Commit-owned Phase 2 gate (`Core changes committed`) unchecked — owned by /ship.

- 2026-05-20T02:12:51Z [gate-red] post-QA Step 8: PHASE2_GATES=partial (Core-changes-committed unchecked; commit lands at /ship). Structural per task-type contract. SMOKE=green (13/13), validate.sh PASS. Surfacing meta-AUQ to operator: proceed-to-/ship vs abort.
