---
name: "Workbench-side change: pass --suppress-readiness-gate, fix Branch(f) open_pr"
type: user-story
id: "S000040"
parent: "F000018"
status: active
created: "2026-05-13"
updated: "2026-05-13"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/modest-meitner-0c7600"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_run_suppress_readiness_gate` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (or N/A — atomic story)

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
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `skills/CJ_run/run.md` Step 5 passes `--suppress-readiness-gate` literally when invoking `/land-and-deploy` via the Skill tool (no conditional; always pass under /CJ_run).
- [ ] `skills/CJ_run/run.md` Branch(f) `open_pr` mode (around line 267 of the table row) is updated to auto-dispatch `/land-and-deploy --suppress-readiness-gate #<PR_NUM>` (inline-duplicate the PR-num parsing block from Step 5) instead of printing exit-0.
- [ ] `skills/CJ_run/SKILL.md` description mentions the suppression behavior; Phase 4 entry updated to "Phase 4 — /land-and-deploy (Skill, inline, --suppress-readiness-gate) — merge PR, verify deploy. AUQ-free on green; alerts on red."
- [ ] CJ_run version bumped 0.4.0 → 0.5.0 in SKILL.md frontmatter.
- [ ] CHANGELOG entry added (under a new `[3.4.0]` or matching collection version per /ship's bump logic) describing the workbench-side change + forward-compat note.
- [ ] `scripts/validate.sh` passes (catalog/manifest/template integrity check).
- [ ] `/CJ_personal-workflow check` passes on F000018 + S000040.

## Todos

<!-- Actionable items for this story. -->

- [x] Edit `skills/CJ_run/run.md` Step 5 — add `--suppress-readiness-gate` to the /land-and-deploy invocation prose
- [x] Edit `skills/CJ_run/run.md` Branch(f) `open_pr` row in the dispatch table — change from print-and-exit to auto-dispatch with inline PR_NUM parsing
- [x] Edit `skills/CJ_run/SKILL.md` description frontmatter + Phase 4 entry
- [x] Bump CJ_run version 0.4.0 → 0.5.0 in `skills/CJ_run/SKILL.md`
- [x] Add CHANGELOG entry (CHANGELOG.md `[3.4.0]`)
- [x] Update `skills-catalog.json` version entry for CJ_run (0.4.0 → 0.5.0 + description sync)
- [x] Run `./scripts/validate.sh` — PASS (0 errors, 0 warnings)
- [ ] (Deferred to /ship) VERSION file bump (3.3.2 → 3.4.0)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-13: Created. Workbench-side change for F000018: pass `--suppress-readiness-gate` and fix Branch(f) open_pr.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_run/run.md` (modified) — Step 5 invocation prose passes `--suppress-readiness-gate`; Branch(f) `open_pr` table row dispatches into /land-and-deploy with the flag + inline-parsed PR_NUM; new "Branch(f) open_pr PR_NUM parsing" subsection inserted between the dispatch table and the telemetry block (duplicates Step 5's parsing block verbatim).
- `skills/CJ_run/SKILL.md` (modified) — description frontmatter updated with the suppression behavior + Branch(f) note; Phase 4 entry updated to "(Skill, inline, `--suppress-readiness-gate`) — AUQ-free on green; alerts on red"; AUQ-gate summary line updated; version 0.4.0 → 0.5.0.
- `CHANGELOG.md` (modified) — new `[3.4.0]` entry covering the workbench-side change + forward-compat notes + out-of-scope follow-ups.
- `skills-catalog.json` (modified) — CJ_run entry version 0.4.0 → 0.5.0 + description sync to match SKILL.md.
- `VERSION` (deferred — bumped by /ship at ship time per workbench convention).

## Insights

<!-- Non-obvious findings worth remembering. -->

- This change is a safe no-op until the gstack `/land-and-deploy --suppress-readiness-gate` flag also lands. gstack's loose arg parsing (case-statement warns-and-continues on unknown flags) ensures the flag is silently ignored if the upstream PR hasn't merged yet.
- Branch(f) `open_pr` was previously a dead-end ("PR already open. Run /land-and-deploy to merge." + exit 0). After this change, it auto-continues — which means the resume-from-PR-open path now matches the design-doc-mode end-to-end behavior.
- The PR_NUM parsing block in Step 5 (run.md ~lines 749-766) is the canonical recipe: try `${PR_URL##*/}` first; if that's not all-digits, fall back to `gh pr list --head ...`. The Branch(f) open_pr handler inline-duplicates this block (taste decision in /autoplan: cheaper than introducing a /CJ_run-internal helper abstraction).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-13: PR_NUM parsing in Branch(f) → inline duplicate (vs extracting a helper). Cheaper than introducing the abstraction; ~15 lines duplicated.
- [decision] 2026-05-13: Flag name `--suppress-readiness-gate` (vs `--from-pipeline`, `--non-interactive`, `--auto-merge`). Mirrors the existing `--suppress-final-gate` pattern.
- [decision] 2026-05-13: Pass the flag unconditionally under /CJ_run (no env var, no conditional). /CJ_run is the only caller; the only reason to not pass it would be to test the legacy behavior, which the user can do by invoking /land-and-deploy directly.
- [impl-decision] 2026-05-13: Wrote the new "Branch(f) open_pr PR_NUM parsing" subsection between the dispatch table (line 269) and the telemetry block (originally line 271). Subsection contains the duplicated parsing block (matching Step 5 verbatim) plus a short rationale. Decision: subsection placement (vs inlining parsing block directly into the table cell) keeps the table cell readable while preserving the inline-duplicate taste decision.
- [impl-decision] 2026-05-13: Updated `skills-catalog.json` CJ_run description to match SKILL.md description (was stale, still mentioning "v0.3.0 ships"). Sync-by-default avoids future review confusion.
- [impl-decision] 2026-05-13: Did NOT bump VERSION file (3.3.2 → 3.4.0) — that's /ship's job at ship time per workbench convention. CHANGELOG entry uses `[3.4.0]` as a forward declaration that /ship will reconcile.
- [impl-finding] 2026-05-13: scripts/validate.sh `Check 11: rules/ deploy health` confirms `rules/skill-routing.md` is deployed to `~/.claude/rules/skill-routing.md` — no rules change needed for this work-item; the description change in SKILL.md alone is sufficient.
- [impl] 2026-05-13: Modified 4 files (skills/CJ_run/run.md, skills/CJ_run/SKILL.md, skills-catalog.json, CHANGELOG.md). 8 journal entries added. Smoke tests S1-S5 pass; validate.sh PASS (0 errors, 0 warnings). Phase 2 implementer-owned gates transitioned ([x] Todos section reflects remaining work, [x] Files section updated with changed files).
- [impl-pass] 2026-05-13: S000040: implementation complete. Phase 2 implementer-owned gates transitioned. QA-owned gates ([ ] Acceptance criteria verified met, [ ] Smoke tests pass) remain for /CJ_qa-work-item.
- 2026-05-13 [qa-smoke] S1 (AC-1, AC-8): green — grep run.md for `--suppress-readiness-gate` returned 5 matches (≥ 2 required)
- 2026-05-13 [qa-smoke] S2 (AC-2, AC-3): green — Branch(f) open_pr row matches the regex; flag + PR_NUM + do-NOT-exit-0 all present
- 2026-05-13 [qa-smoke] S3 (AC-4): green — SKILL.md frontmatter reads `version: 0.5.0`
- 2026-05-13 [qa-smoke] S4 (AC-6): green — Phase 4 entry mentions `--suppress-readiness-gate`; description frontmatter also updated
- 2026-05-13 [qa-smoke] S5 (AC-9): green — `./scripts/validate.sh` exit 0 (0 errors, 0 warnings)
- 2026-05-13 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-05-13 [qa-e2e-run-start] RUN_ID=20260513-225800-qa commit=$(git rev-parse --short HEAD)
- 2026-05-13 [qa-e2e] E1 (AC-1): green — Step 5 invocation prose contains `--suppress-readiness-gate` (3 occurrences in lines 745-825) AND `#<PR_NUM>` threading (1 occurrence)
- 2026-05-13 [qa-e2e] E2 (AC-2, AC-3): green — Branch(f) open_pr table row (line 267) contains flag + `#<PR_NUM>` + "do NOT exit 0" semantics; print-and-exit replaced by auto-dispatch
- 2026-05-13 [qa-e2e] E3 (AC-5): green — CHANGELOG.md [3.4.0] entry mentions Step 5 (3x), Branch(f) (1x), and forward-compat (2x); all three required topics covered
- 2026-05-13 [qa-e2e] E4 (AC-7): green — invocation form is `/land-and-deploy --suppress-readiness-gate` as positional flag (no `=` value-form); matches gstack's loose case-statement-warn-and-continue arg-parser contract
- 2026-05-13 [qa-e2e] E5 (AC-8): green — `grep suppress-readiness-gate skills/CJ_run/run.md` returns 5 matches (≥ 2 required)
- 2026-05-13 [qa-e2e-summary] green: 5/5 E2E rows green (parent-inline execution; Agent tool unavailable for nested subagent dispatch, all rows were read-only-eligible)
- 2026-05-13 [qa-pass] S000040: QA complete. Smoke green (5/5); E2E green (5/5). Phase 2 qa-owned gates transitioned ([x] Smoke tests pass, [x] Acceptance criteria verified met).
- 2026-05-13 [auto-final-gate-suppressed] 1 mechanical, 2 taste, 1 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (filter run_id=20260513-224902-66557)
