---
name: "suggest-skill"
type: task
id: "T000017"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/quizzical-panini-a78b33"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (no parent — standalone task; design doc reviewed)
- [x] Working branch created (`branch` field populated — claude/quizzical-panini-a78b33)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate.
     Acceptance criteria (from design's Success Criteria):
       - /suggest runs in under 3 seconds on this repo's TODOS.md + ~12 trackers.
       - Output is a 5-row markdown table; columns are Rank, Title, Pri, Size, Status, Why.
       - Top 5 includes at least one P1 item if any P1 active items exist.
       - Strikethrough/DONE/RETIRED entries from TODOS.md never appear.
       - Re-running /suggest immediately produces identical output (idempotent).
       - User can scan the output and pick a thing in under 30 seconds. -->

- [x] Create `skills/suggest/SKILL.md` with frontmatter (`name: suggest`, description from catalog entry, `version: 0.1.0`, `allowed-tools: [Bash, Read]`).
- [x] Write the bash body per the design's sketch (six steps: band-pass parser, heading regex, tracker walk, score, format, render). ~165 lines shell (within the 60-100 estimate plus comments + edge-case handling).
- [x] Implement Step 1: band-pass TODOS.md to the active section between `## Active work` and `## Deferred work`; extract heading rows; skip strikethrough (`~~...~~`) entries; parse `### {title} (P{1-4}, {S|M|L})` regex; extract leading `[FSTD][0-9]{6}` ID from heading line only (not body prose).
- [x] Implement Step 2: walk all `*_TRACKER.md` files via `find work-items -type f -name '*_TRACKER.md'`; YAML frontmatter parser via awk (single-line scalars only — see fragility note); index `id -> {status, blocked_by, updated, name, type}`.
- [x] Implement Step 3: enrich each TODOS.md row by joining on extracted ID; orphan rows (no ID or ID not found) included with no recency penalty and treated as unblocked.
- [x] Implement Step 4: compute `age_days` from tracker `updated` field using macOS-compatible `date -j -f "%Y-%m-%d"`; default 0 if missing/unparseable.
- [x] Implement Step 5: scoring per design premise #2 — `pri_w` (P1=4..P4=1) + `size_w` (S=3, M=2, L=1) + unblocked bonus (+2 if blocked_by empty or no tracker) − recency_penalty (`age_days/14` integer division).
- [x] Implement Step 6: sort desc by score, alphabetic-asc tiebreak by title; take top 5; render markdown table with columns Rank, Title, Pri, Size, Status, Why.
- [x] Implement edge cases: missing TODOS.md → exit 1 with clear message; no matching active entries → print `No actionable items.` and exit 0; no trackers → degrade to TODOS-only ranking. Verified all 4 cases (T9, T10, T11, T12, T13) in /tmp dry-run.
- [x] Verify `awk` YAML parser fragility check: ran `find work-items -name '*_TRACKER.md' -exec awk '/^---$/{f=!f;next} f && /^[a-z_]+:.*:/' {} +`. Found 7 hits, ALL on `name:` field values containing `: ` (e.g. `name: "personal-workflow: deployed templates drift..."`). The parser truncates `name` values, but `/suggest` only consumes `id`, `status`, `blocked_by`, `updated`, `type` — none of which currently contain `: ` — so the parser is safe in practice. FRAGILITY NOTE updated in SKILL.md to document this. If a consumed field ever starts to contain `: `, migrate to yq.
- [x] Add catalog entry to `skills-catalog.json` per the literal shape in the design (name `suggest`, version `0.1.0`, source `local`, portability `local-only`, files `["skills/suggest/SKILL.md"]`, status `experimental`).
- [x] Run `./scripts/generate-readme.sh > README.md` to refresh the Skills table.
- [x] Run `./scripts/validate.sh` to verify catalog↔filesystem consistency. PASS (0 errors, 0 warnings).
- [x] Manually invoke `/suggest` against this repo; eyeball top 5; sanity-check ranking matches gut. Top 5 surfaces `F000013 V1 eval harness` (P1) at #1, then 4 P3/P4 orphan items. Matches design premise that orphans (no leading ID in heading) get the unblocked bonus.
- [ ] (Deferred — post-soak) If ranking feels off after a week of use, tune weights in scoring step. Initial output looks reasonable — keep weights as-shipped.
- [x] Run `./scripts/test.sh` to ensure no regressions. PASS.
- [ ] (Deferred — implementer-discovery) During implementation: bash parameter expansion `${heading#### }` does NOT strip `### ` — bash parses the leading `##` as the greedy-prefix operator (matching empty pattern), then leaves `## ` literal. Replaced with `sed 's/^### //'`. Documented inline as a comment so future maintainers don't trip on it. No follow-up needed.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-09: Created. Scaffolded from /office-hours design doc `chjiang-claude-quizzical-panini-a78b33-design-20260509-193825.md`. Adds a new `/suggest` slash-command skill that prints a top-5 ranked next-up list from TODOS.md headings joined to work-items tracker frontmatter (status, blocked_by, updated). Single-file SKILL.md, bash body, no scripts/ artifact in v1, no new runtime deps. Approach A chosen over Approach B (script + eval) because the heuristic isn't validated yet — promote to B post-soak if needed.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/suggest/SKILL.md` — NEW. Frontmatter (`name: suggest`, `version: 0.1.0`, `description` from catalog, `allowed-tools: [Bash, Read]`) + bash body implementing all 6 design steps (band-pass parser, heading regex, tracker walk, score, sort, render markdown table). ~165 lines including comments + edge-case handlers. Verified end-to-end in 0.66s on the current repo state.
- `skills-catalog.json` — MODIFIED. Added one entry for `suggest` (`status: experimental`, `portability: local-only`, single-file, no templates, no skill deps, `tools: [bash, awk, find, grep, sed, sort]`).
- `README.md` — MODIFIED (regenerated via `./scripts/generate-readme.sh > README.md`). Picks up the new Skills-table row from the catalog entry. One-line diff.
- `work-items/tasks/ops/T000017_suggest_skill/T000017_TRACKER.md` — MODIFIED (this file). Phase 2 implementer-owned gates transitioned, Todos closed, journal entries appended.

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- **TODOS.md is the candidate set; trackers enrich it.** TODOS.md holds priority + size + intent and bounds the search space. Trackers add live status/blocked_by/updated. Trackers without a TODOS.md mention are out of scope in v1 (assumed already done, deferred, or not in current focus).
- **Scoring is intentionally simple.** `priority_weight + size_weight + unblocked_bonus - recency_penalty`. P1=4..P4=1, S=3/M=2/L=1, +2 unblocked, -1/14 days stale. Tie-break alphabetic by title. Premise #2 — locked.
- **Heading-only ID extraction.** TODOS body prose often references other work items (`Closed by F000014`, etc.); extracting from the body would cause false-positive joins. Match the FIRST `\b[FSTD][0-9]{6}\b` in the heading line ONLY.
- **YAML parser fragility.** The awk-based parser splits on first `: ` and strips quotes — fine for current trackers, breaks if a value contains `: ` (e.g. `description: "Fix: foo"`). Pre-ship one-liner check is in the Todos. If it ever prints output, migrate to `yq` (premise #6 violation acceptable for correctness).
- **macOS-compatible date math.** `date -j -f "%Y-%m-%d" "$updated" +%s` differs from GNU `date -d`. The bash body must use the BSD form; tested on Darwin.
- **Single-file skill matches "smallest version" preference.** Office-hours noted the user picked the smallest viable version of every choice (top-5 list over coach, single-file over script+eval, skipped Codex review). Approach A honors that. Promote to Approach B (`scripts/suggest.sh` + eval case) only when the heuristic stabilizes or invocation outside Claude is needed.
- **Well-maintained TODOS.md is what makes parsing tractable.** The strikethrough-DONE convention, `(Pn, X)` heading suffix, and `## Deferred work` boundary are the affordances `/suggest` exploits. A messier TODOS.md would need a smarter parser.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] D1: Approach A (single-file SKILL.md) over Approach B (script + eval) over Approach C (fold into /system-health). Summary: smallest viable form of the request; ships in 1-2h; promotion path to B is mechanical post-soak.
- [decision] D2: Scoring formula = `priority_weight + size_weight + unblocked_bonus - recency_penalty` with weights P1=4..P4=1, S=3/M=2/L=1, +2 unblocked, age_days/14 stale. Summary: simple enough to reason about by eye; tunable post-ship via weight constants.
- [decision] D3: Top-5 hard-coded; no `--top N` flag in v1. Summary: smallest viable surface; add when asked.
- [decision] D4: Heading-only ID extraction (not body prose). Summary: avoids false-positive joins on cross-references like "Closed by F000014".
- [decision] D5: Orphan TODOs (no tracker join) included with `(orphan)` in Why column, ranked by priority+size only (no recency penalty). Summary: keeps TODOs-without-trackers actionable; they often represent quick wins.
- [decision] D6: type `task`, slug `suggest_skill`, component `ops`. Summary: small atomic operational change (~3 files, 1 PR, ~1-2h CC time), no natural sub-stories, fits work-items/tasks/ops/ pattern alongside T000015 and T000016.
- 2026-05-09 [impl-decision] D7: kept the design's awk-based YAML parser (premise #6 — no new deps over yq). Pre-ship fragility check found 7 hits (all on `name:` field values like `name: "personal-workflow: deployed templates drift..."`), but `/suggest` only consumes `id`, `status`, `blocked_by`, `updated`, `type` — none of which currently contain `: ` in any tracker. Documented inline as FRAGILITY NOTE; if a consumed field ever starts to contain `: `, migrate to yq.
- 2026-05-09 [impl-decision] D8: `(orphan)` lives in BOTH Status and Why columns for orphan rows. Design D5 + test-plan #6 require `(orphan)` in Why; the design example (line 173) shows it in Status. Putting it in both satisfies the test contract AND the example display. The Status column shows `(orphan)` literal because the tracker join missed; the Why column starts with `(orphan)` followed by score-contributor flags.
- 2026-05-09 [impl-finding] Bash parameter expansion gotcha: `${heading#### }` does NOT strip `### ` — bash parses the leading `##` as the greedy-prefix operator (matching empty pattern), then leaves `## ` literal. Replaced with `sed 's/^### //'` for clarity. Documented inline so future maintainers don't trip on it.
- 2026-05-09 [impl-finding] End-to-end runtime: 0.66s wall on current repo (TODOS.md ~106 lines + 57 trackers). Well under the 3-second budget. P1 item (`F000013 V1 eval harness`) surfaces at #1 as expected.
- 2026-05-09 [impl] Wrote 1 NEW file (`skills/suggest/SKILL.md`, ~165 lines). MODIFIED 2 files (`skills-catalog.json` adds 1 entry; `README.md` adds 1 row via `./scripts/generate-readme.sh`). MODIFIED tracker. Ran `./scripts/validate.sh` → PASS. Ran `./scripts/test.sh` → PASS. Ran end-to-end `/suggest` dry-run via extracted bash block → produces 5-row markdown table with P1 surfaced at #1.
- 2026-05-09 [impl-auto] Auto-mode run via /personal-pipeline orchestrator. Sensitive-surface (`skills-catalog.json`) AUQ pre-collected and APPROVED. README.md regeneration AUQ pre-collected and APPROVED.
- 2026-05-09 [impl-pass] T000017: implementation complete. Phase 2 implementer-owned gates transitioned (`Todos section reflects remaining work` + `Files section updated with changed files`). Commit gate (`Core changes committed`) remains user/`/ship`-owned and untouched.
- 2026-05-09 [qa-smoke] #1 (basic invocation): green — exit 0, runtime 0.66s, 5 data rows, columns Rank|Title|Pri|Size|Status|Why.
- 2026-05-09 [qa-smoke] #2 (strikethrough excluded): green — no `~~...~~` heading appears in output rows.
- 2026-05-09 [qa-smoke] #3 (deferred section excluded): green — no heading from `## Deferred work` (14 deferred candidates) appears in output.
- 2026-05-09 [qa-smoke] #4 (P1 surfaces): green — `F000013 V1 eval harness` (only active P1) appears at rank #1.
- 2026-05-09 [qa-smoke] #5 (tracker join): green — `F000013` row Status=`active` (joined from tracker), Why=`unblocked`, no `(orphan)` token.
- 2026-05-09 [qa-smoke] #6 (orphan labeled): green — ranks 2-5 all show `(orphan)` in both Status and Why per impl-decision D8.
- 2026-05-09 [qa-smoke] #7 (blocked items show blocker): green — synthetic F000050 with `blocked_by: "F000020"` produced `blocked by F000020` in Why; unblocked bonus NOT applied.
- 2026-05-09 [qa-smoke] #8 (recency penalty): green — synthetic F000051 with `updated` 60d ago produced `stale 60d` in Why.
- 2026-05-09 [qa-smoke] #9 (idempotent): green — back-to-back invocations produced byte-identical output (`diff` empty).
- 2026-05-09 [qa-smoke] #10 (read-only): green — `git status --short` identical before vs after invocation; no working-tree mutations.
- 2026-05-09 [qa-smoke] #11 (missing TODOS.md): green — exit 1 with stderr `Error: TODOS.md not found in <pwd>. /suggest requires a TODOS.md at the repo root.` (verified in /tmp/qa_t000017/fakerepo).
- 2026-05-09 [qa-smoke] #12 (no actionable items): green — TODOS.md with only strikethrough Active entries → stdout `No actionable items.`, exit 0.
- 2026-05-09 [qa-smoke] #13 (no trackers degrade): green — fake repo with no `work-items/` → 5 rows produced, all `(orphan)`, no `stale` markers, exit 0.
- 2026-05-09 [qa-smoke] #14 (defaults for missing suffix): green — heading without `(Pn, X)` → `P4 | M | (orphan) | (orphan), default P4/M`.
- 2026-05-09 [qa-smoke] #15 (YAML parser fragility check): green — fragility check found 7 hits, all on `name:` field; consumed fields (`id`, `status`, `blocked_by`, `updated`, `type`) clean. Parser safe in practice per FRAGILITY NOTE.
- 2026-05-09 [qa-smoke] #16 (eyeball sanity): green — 5/5 model picks match the 5 active non-strikethrough Active headings; ordering matches scoring model (P1 first, then 3× P3 alphabetic by title, then P4 last).
- 2026-05-09 [qa-smoke] #17 (alphabetic-asc tiebreak): green — synthetic identical-score pair `Apple task` / `Zebra task` ranked Apple #1, Zebra #2.
- 2026-05-09 [qa-smoke-summary] green: 17/17 non-manual rows green (0 manual rows pending). Verification scripts re-run post-QA: `./scripts/validate.sh` → PASS (0 errors, 0 warnings); `./scripts/test.sh` → PASS (0 failures).
- 2026-05-09 [qa-pass] T000017 (task): green smoke from test-plan rows (17 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
