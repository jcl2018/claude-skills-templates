---
name: "CRLF safety (.gitattributes)"
type: user-story
id: "S000077"
status: active
created: "2026-06-03"
updated: "2026-06-04"
parent: "F000044"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-234927-99694"
blocked_by: ""
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session. The parent's design is sufficient context; DESIGN.md is a brief
     stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/crlf_safety` (or use parent's branch if shipping in same PR)
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

- [ ] .gitattributes forces LF on *.sh/*.py + the two extensionless scripts (scripts/skills-deploy, scripts/skills-update-check)
- [ ] `git check-attr eol` confirms `eol: lf` for the entrypoints
- [ ] Binaries (*.png/*.jpg/*.ico) marked binary

## Todos

<!-- Actionable items for this story. -->

- [x] Write .gitattributes at repo root
- [x] Document the one-time `git add --renormalize .` on adoption (noted in Journal; operator-facing doc lands in S000080)
- [x] Verify line endings via `git ls-files --eol`

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. CRLF safety via .gitattributes (WI-1 of F000044).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- .gitattributes (NEW) — force LF for text (`* text=auto eol=lf`) + explicit `text eol=lf` for the two extensionless entrypoints + mark binaries

## Insights

<!-- Non-obvious findings worth remembering. -->

- `scripts/lib.sh` already has a `jq()` CRLF shim, but that normalizes runtime jq OUTPUT — a different layer. This story fixes checked-out SOURCE line endings via .gitattributes; it builds on the shim rather than duplicating it.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-04 [impl-decision] EOL policy = `* text=auto eol=lf` (force LF for all text) per SPEC Tradeoffs. The two extensionless entrypoints (`scripts/skills-deploy`, `scripts/skills-update-check`) get explicit `text eol=lf` lines since no `*.ext` pattern matches them. Binaries (`png/jpg/jpeg/gif/ico/pdf`) marked `binary`.
- 2026-06-04 [impl-finding] `git add --renormalize .` is a no-op on this repo (macOS-developed, already all-LF) so it stages nothing here; the operator-facing "run it on adoption" instruction belongs in the Running-on-Windows docs delivered by S000080. Recorded so the renormalize step isn't lost.
- 2026-06-04 [impl] Wrote 1 file: `.gitattributes` (NEW). Verified via `git check-attr`: entrypoints → eol lf; `*.sh` → text=auto eol=lf; `*.png/.ico/.jpg` → binary set; no tracked `*.sh` resolves to non-lf.
- 2026-06-04 [impl-auto] Auto-mode run; `--auto` allowed (1 file touched, non-sensitive surface).
- 2026-06-04 [impl-pass] S000077: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-04 [qa-e2e-deferred] E1 (AC-1): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship. Live check is the windows-latest CI from S000080.
- 2026-06-04 [qa-smoke] S1 (AC-1): green — no tracked *.sh resolves to non-lf (`git ls-files --eol`).
- 2026-06-04 [qa-smoke] S2 (AC-2): green — scripts/skills-deploy + skills-update-check report `eol: lf` (`git check-attr`).
- 2026-06-04 [qa-smoke] S3 (AC-3): green — .gitattributes marks 6 binary patterns (png/jpg/jpeg/gif/ico/pdf).
- 2026-06-04 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending).
- 2026-06-04 [qa-pass] S000077 (user-story): green smoke + 1 E2E row deferred to post-merge (all post-ship). Phase 2 gates transitioned; post-ship AC (E1) awaits post-merge verification (see [qa-e2e-deferred] above).
