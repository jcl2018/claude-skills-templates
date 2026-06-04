---
name: "Windows CI job + docs"
type: user-story
id: "S000080"
status: active
created: "2026-06-03"
updated: "2026-06-04"
parent: "F000044"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-103751-36825"
blocked_by: ""
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session. The parent's design is sufficient context; DESIGN.md is a brief
     stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/windows_ci_and_docs` (or use parent's branch if shipping in same PR)
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

- [x] windows-latest CI job added (green pending the first PR run — E1, post-ship)
- [x] CI fails on Windows regression (blocking job, by construction — no continue-on-error)
- [x] README "Running on Windows" section
- [x] CLAUDE.md Windows-support note

## Todos

<!-- Actionable items for this story. -->

- [x] add windows-latest job (Git Bash) running the portable-date + copy-mode-install subset — windows.yml runs windows-smoke.sh + the full test-deploy.sh
- [x] write README "Running on Windows" (via generate-readme.sh BODY + regen)
- [x] add CLAUDE.md note
- [ ] (optional) skills-deploy doctor platform line — DEFERRED (out of v1 scope; not required for any AC)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Windows CI job + docs (WI-4 of F000044).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- scripts/windows-smoke.sh (New) — portable Windows-relevant smoke: CRLF (S000077) + portable-date probe (S000078) + copy-mode install (S000079); green on macOS/Linux via FORCE_COPY, the live check on Git Bash
- .github/workflows/windows.yml (New) — blocking windows-latest job (shell bash / Git Bash) on pull_request + push to main; runs windows-smoke.sh + the full test-deploy.sh
- scripts/test-deploy.sh (Modified) — `SYMLINK_CAPABLE` probe gates the 4 symlink-only cases (Test 9/12/C6/C7 skip-with-note; Test 2 substitutes a regular-file count) so the full suite runs green on Git Bash; byte-identical on symlink-capable hosts
- scripts/generate-readme.sh (Modified) — "Running on Windows" section added to the BODY heredoc
- README.md (Modified) — regenerated (carries the new section)
- CLAUDE.md (Modified) — "Running on Windows" agent-facing note (support model + POSIX/LF + portable-date rules)
- scripts/test.sh (Modified) — runs windows-smoke.sh on every host (not Windows-only-untested)

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-04 [impl-decision] Operator chose the maximal-coverage CI option: a blocking windows-latest job running the FULL test-deploy.sh on Git Bash (not just the smoke subset). To make that correct, test-deploy.sh is now symlink-capability-aware — a probe (mirrors skills-deploy's `_can_symlink`, honors `SKILLS_DEPLOY_FORCE_COPY=1`) gates the 4 genuinely symlink-only cases; every copy-mode + mode-agnostic case still runs. Byte-identical on symlink-capable hosts (probe=yes → all cases run as before, no regression).
- 2026-06-04 [impl-decision] Job is BLOCKING (no `continue-on-error`) on `pull_request` + `push` to main → satisfies AC-2 (CI fails on Windows regression). It runs on S000080's own PR, so E1 (live Git-Bash green) is observable pre-merge even though TEST-SPEC tags it post-ship.
- 2026-06-04 [impl-finding] README.md is fully auto-generated by generate-readme.sh (two heredocs) — a hand-added section would be clobbered on the next regen. The "Running on Windows" section went into the BODY heredoc + README was regenerated (idempotency reconfirmed).
- 2026-06-04 [impl-finding] Validated Option C locally WITHOUT a Windows host: `SKILLS_DEPLOY_FORCE_COPY=1 ./test-deploy.sh` faithfully simulates Git Bash (every install copy-mode + SYMLINK_CAPABLE=no). Both runs green — normal (all 66 cases) + simulated-Git-Bash (4 skip, rest copy-mode). Residual real-Git-Bash unknowns (`date -d`, `ln -s`) are covered by windows-smoke.sh or not relied on by any running case.
- 2026-06-04 [impl] 7 files: +scripts/windows-smoke.sh, +.github/workflows/windows.yml, ~scripts/test-deploy.sh (symlink-aware), ~scripts/generate-readme.sh + ~README.md (regen), ~CLAUDE.md, ~scripts/test.sh. validate.sh PASS (0/0); test.sh PASS (0 failures, incl. the new windows-smoke check). Deferred the optional skills-deploy doctor platform line (not required for any AC).
- 2026-06-04 [impl-pass] S000080: implementation complete. Phase 2 implementer-owned gates (Todos / Files) transitioned; QA-owned gates (AC-verified / smoke) left for /CJ_qa-work-item.
- 2026-06-04 [qa-e2e-deferred] E1 (AC-2): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship. windows.yml runs only on remote refs; live Git-Bash green is observable on this PR's own CI / via `gh workflow run` post-merge.
- 2026-06-04 [qa-smoke] S1 (AC-1): green — `runs-on: windows-latest` present in .github/workflows/windows.yml:30 (exit 0).
- 2026-06-04 [qa-smoke] S2 (AC-3): green — `## Running on Windows` heading present in README.md:57 (exit 0).
- 2026-06-04 [qa-smoke] S3 (AC-4): green — `windows` mentioned in CLAUDE.md (heading + body, lines 16/18/20; exit 0).
- 2026-06-04 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending)
- 2026-06-04 [qa-pass] S000080 (user-story): green smoke + 1 E2E row deferred to post-merge (all post-ship). Phase 2 gates transitioned; post-ship AC (AC-2, E1) awaiting post-merge verification (see [qa-e2e-deferred] entry above).
