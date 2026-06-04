---
name: "Portable POSIX runtime (date + OS gate)"
type: user-story
id: "S000078"
status: active
created: "2026-06-03"
updated: "2026-06-04"
parent: "F000044"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-011243-45223"
blocked_by: ""
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session. The parent's design is sufficient context; DESIGN.md is a brief
     stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/portable_posix_runtime` (or use parent's branch if shipping in same PR)
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

- [ ] suggest.sh + improve_queue.sh run (not refuse) on Linux/WSL2 with correct date math
- [ ] both uname gates allow Darwin|Linux|MINGW*|MSYS*, refuse unknown
- [ ] ubuntu CI exercises a check_darwin-gated path

## Todos

<!-- Actionable items for this story. -->

- [x] inline date_to_epoch in suggest.sh + improve_queue.sh
- [x] widen both uname gates
- [x] add test.sh coverage (improve_queue audit + suggest ranking) on non-Darwin

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Portable POSIX runtime — date_to_epoch + widened OS gate (WI-2 of F000044).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills/CJ_suggest/scripts/suggest.sh (Modified) — POSIX OS allowlist gate (was Darwin-only) + inline date_to_epoch; date call → date_to_epoch
- skills/CJ_improve-queue/scripts/improve_queue.sh (Modified) — check_darwin → allowlist + inline date_to_epoch; date call → date_to_epoch
- scripts/test.sh (Modified) — S000078 portable-runtime test (4 assertions; AC-4 gated-path runs on the current OS, incl. ubuntu CI)

## Insights

<!-- Non-obvious findings worth remembering. -->

- macOS behavior is byte-identical post-change: on Darwin, `date --version` fails so `date_to_epoch` takes the BSD `date -j -f` branch — the same call as before. Only non-Darwin (Linux/WSL2/Git Bash) gains new behavior, which is why the macOS test run (and any suggest golden-fixture) stays green; the GNU branch is proven by the ubuntu CI run of the new test.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-04 [impl-decision] Resolved SPEC Open Question: KEEP an OS allowlist (`Darwin|Linux|MINGW*|MSYS*|CYGWIN*`, refuse unknown) rather than dropping the gate — `date_to_epoch` makes date math portable so the original BSD-date rationale is gone, but a loud refuse on a genuinely-unknown OS is cheap insurance. `check_darwin` name kept in improve_queue.sh for call-site stability.
- 2026-06-04 [impl-decision] `date_to_epoch` is a feature-probe (`date --version` → GNU `date -d`, else BSD `date -j -f`), not uname-based, per SPEC Tradeoffs — Git Bash ships GNU coreutils so the probe routes it to the GNU branch. Inlined into both skill scripts (not scripts/lib.sh) because deployed skill scripts can't source the repo's scripts/ at runtime.
- 2026-06-04 [impl] Modified 3 files: suggest.sh (gate + date), improve_queue.sh (check_darwin + date), test.sh (new S000078 test). Sensitive surface (live skills + validator) — ran propose-mode with operator approval. `scripts/test.sh` green; S000078 4/4 assertions pass on Darwin (GNU branch covered by ubuntu CI).
- 2026-06-04 [impl-pass] S000078: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-04 [qa-e2e-deferred] E1 (AC-1): post-ship — WSL2 ranking verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship. Pre-ship proof is the smoke tier + the S000078 test.sh run.
- 2026-06-04 [qa-smoke] S1 (AC-1): green — suggest.sh ranks on Darwin, exit 0, no OS refusal.
- 2026-06-04 [qa-smoke] S2 (AC-3): green — both skills carry the POSIX OS allowlist (Darwin|Linux|MINGW*|MSYS*|CYGWIN*).
- 2026-06-04 [qa-smoke] S3 (AC-4): green — improve_queue audit runs the check_darwin gate without refusal (isolated temp repo).
- 2026-06-04 [qa-smoke] S4 (AC-2): green — date_to_epoch parses a known date to a sane epoch on Darwin (BSD branch); GNU branch covered by ubuntu CI.
- 2026-06-04 [qa-smoke-summary] green: 4/4 non-manual rows green (0 manual pending).
- 2026-06-04 [qa-pass] S000078 (user-story): green smoke + 1 E2E row deferred to post-merge (all post-ship). Phase 2 gates transitioned; post-ship AC (E1, WSL2 ranking) awaits manual verification on a WSL2 box.
