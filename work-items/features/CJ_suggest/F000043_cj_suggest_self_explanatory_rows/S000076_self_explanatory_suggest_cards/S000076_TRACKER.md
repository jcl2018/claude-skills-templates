---
name: "Self-explanatory suggest cards"
type: user-story
id: "S000076"
status: active
created: "2026-06-03"
updated: "2026-06-03"
parent: "F000043"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-225728-46346"
blocked_by: ""
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session. The parent's design is sufficient context; DESIGN.md is a brief
     stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/self_explanatory_suggest_cards` (or use parent's branch if shipping in same PR)
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

- [x] No-flag `suggest.sh` prints a card per ranked item: header (`N. [ID] Title   Pri · Effort`), wrapped `What:` line from the body's first non-empty line, `Status:` line folding in the existing `Why` reasons.
- [x] `--for-skill cj-goal --limit 15` prints output byte-identical to today's markdown table.
- [x] `Size` letter expands to label: `S → quick (<1h)`, `M → ~half-day`, `L → large (1-2 days)`.
- [x] Empty-body rows render `What: (no description)`.
- [x] Missing TODOS.md → exit 1; no actionable items → `No actionable items.` + exit 0.

## Todos

<!-- Actionable items for this story. -->

- [ ] Add a `render_cards` path in `suggest.sh` gated on empty `$FOR_SKILL`; keep the table renderer for the consumer path.
- [ ] Add Size→effort-label mapping + first-body-line extraction (reuse `extract_body`) into the per-row data already in `$SCORED`.
- [ ] Update SKILL.md "Surface convention" + USAGE.md.
- [ ] Add/extend a test asserting (a) table byte-stability under `--for-skill cj-goal` and (b) the default path emits card markers.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Render the interactive top-N as scannable cards (what-it-does + effort label) while keeping the byte-stable consumer table.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills/CJ_suggest/scripts/suggest.sh
- skills/CJ_suggest/SKILL.md
- skills/CJ_suggest/USAGE.md

## Insights

<!-- Non-obvious findings worth remembering. -->

- `$SCORED` already carries the raw heading in col 7, so ID + title for the card header come from data already in the scored tempfile — no re-parse of TODOS.md needed.
- Forking on `[ -n "$FOR_SKILL" ]` means the consumer path is literally the old code path, so byte-stability for `/CJ_goal_todo_fix` is structural, not something a test has to babysit beyond one assertion.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-03: First non-empty body line (via `extract_body`) chosen as the `What:` source over a truncated summary. Summary: deterministic, author-controlled text beats a heuristic blurb that can cut mid-thought; empty bodies fall back to `(no description)`.
- 2026-06-03 [qa-smoke] S1 (AC-2): green — `--for-skill cj-goal --limit 15` output byte-identical to committed fixture tests/fixtures/suggest-consumer-table.expected (created this run from current output; also diffed identical against `git show HEAD:.../suggest.sh` output — consumer table is byte-stable, /CJ_goal_todo_fix parse path protected).
- 2026-06-03 [qa-smoke] S2 (AC-1): green — default no-flag path emits card markers (`^What:`, `^Status:`) and the ` · ` effort separator; not the table.
- 2026-06-03 [qa-smoke] S3 (AC-3): green — controlled S/M/L fixture renders all three effort labels: `quick (<1h)` / `~half-day` / `large (1-2 days)`.
- 2026-06-03 [qa-smoke] S4 (AC-4): green — empty-body fixture row renders `What: (no description)`.
- 2026-06-03 [qa-smoke] S5 (AC-4): green — missing TODOS.md exits 1 ("TODOS.md not found"); actionable-empty TODOS.md prints "No actionable items." + exit 0.
- 2026-06-03 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending). validate.sh: 0 errors, 0 warnings (exit 0).
- 2026-06-03 [qa-e2e-run-start] RUN_ID=20260603-232009-23173 commit=d7d9177
- 2026-06-03 [qa-e2e] E1 (AC-1, AC-3): green — `/CJ_suggest` (no flags) against real workbench TODOS.md renders a scannable card list; rank-1 card shows ID `[F000013]`, title, `P1 · quick (<1h)`, a `What:` line, and a `Status:` line. A reader can tell what each top item does and its size without opening TODOS.md. [parent-inline]
- 2026-06-03 [qa-e2e] E2 (AC-2): green — consumer candidate-parse path (`--for-skill cj-goal`) byte-identical to HEAD at --limit 5/10/15; drain mode ranks/selects identically to pre-change behavior. [parent-inline]
- 2026-06-03 [qa-e2e-summary] green (0s subagent; 2 rows parent-inline; 0 deferred): all E2E criteria green — card list verified (E1), consumer parity verified (E2).
- 2026-06-03 [qa-pass] S000076 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
