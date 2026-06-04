---
name: "Symlink-free copy-mode install"
type: user-story
id: "S000079"
status: active
created: "2026-06-03"
updated: "2026-06-04"
parent: "F000044"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-095839-52244"
blocked_by: ""
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session. The parent's design is sufficient context; DESIGN.md is a brief
     stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/symlink_free_install` (or use parent's branch if shipping in same PR)
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

- [ ] install + doctor succeed in BOTH symlink-mode and copy-mode
- [ ] manifest schema extended with install_kind + per-file source_checksum
- [ ] remove/relink branch on mode
- [ ] test-deploy.sh covers both modes + doctor each

## Todos

<!-- Actionable items for this story. -->

- [x] add _can_symlink() probe
- [x] copy-mode install path
- [x] manifest install_kind + source_checksum
- [x] branch doctor/remove/relink on mode
- [x] test-deploy.sh both-mode + doctor cases (C1-C7)
- [x] PARALLEL test.sh fixture update (repo blind spot) — done: test.sh S000079 structural guards added + green

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Symlink-free copy-mode install + manifest schema (WI-3 of F000044, the L-effort risk item).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- scripts/skills-deploy (Modified) — `_can_symlink()` probe + `SKILLS_DEPLOY_FORCE_COPY` override; install/doctor/remove/relink branch on `install_kind`; copy-mode = `cp` + per-file `source_checksums` (symlink branch byte-identical)
- scripts/test-deploy.sh (Modified) — copy-mode C1-C7 (install / doctor-healthy / doctor-drift / relink-repair / remove / symlink-records-kind / back-compat-default)
- scripts/test.sh (Modified) — S000079 structural guards (probe + override + schema + back-compat default present)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The runtime manifest stores no per-skill-file checksum today (skill records are {path, installed_at}; source_checksum is templates/rules only) — copy-mode doctor requires a new schema. This is the hidden cost that makes this story L, not M.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-04 [impl-decision] Symlink-mode kept byte-identical (existing `ln -snf` paths wrapped in `if install_kind=symlink`); copy-mode purely additive. `install_kind` defaults to `"symlink"` when absent at all 3 read sites (doctor/remove/relink) for back-compat with pre-S000079 installs. macOS stays symlink (preserves the instant-edit dev loop); copy-mode is Git-Bash-only via `_can_symlink` probe + `SKILLS_DEPLOY_FORCE_COPY=1` override for tests/CI.
- 2026-06-04 [impl-decision] Resolved SPEC Open Questions: copy-mode doctor drift = FAIL (mirrors the template-checksum FAIL); subdirs are copied + presence-checked, NOT deep per-file-hashed (bounds the manifest schema); macOS NOT unified onto copy-mode.
- 2026-06-04 [impl-finding] Mirrored the existing TEMPLATE-side `source_checksum` machinery (install/relink/doctor) for skills — reused `file_checksum()` + the same jq idioms, lowering novelty + risk on the critical install path.
- 2026-06-04 [impl] Modified 3 files: scripts/skills-deploy (+238/-34), scripts/test-deploy.sh (+129, C1-C7), scripts/test.sh (+42, S000079 guards). Built via a delegated implementer subagent against the approved design, then reviewed line-by-line (every symlink branch confirmed unchanged) and re-ran all suites. Sensitive surface (install path) — propose-mode with operator approval.
- 2026-06-04 [impl] Blind-spot honored: test-deploy.sh AND test.sh updated in the same change — verified green (test-deploy.sh C1-C7 pass; test.sh RESULT PASS, 0 failures; validate.sh PASS).
- 2026-06-04 [impl-pass] S000079: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-04 [qa-e2e-deferred] E1 (AC-1): post-ship — real Git Bash install verification deferred to post-merge (Tag 'post-ship'); live check is the windows-latest CI from S000080. Pre-ship proof: test-deploy.sh C1-C7 copy-mode (via FORCE_COPY).
- 2026-06-04 [qa-smoke] S1 (AC-1): green — copy-mode install lands regular files + manifest install_kind=copy (test-deploy.sh C1).
- 2026-06-04 [qa-smoke] S2 (AC-3): green — doctor healthy on copy-mode AND symlink-mode, no false 'not a symlink' (test-deploy.sh C2/C6).
- 2026-06-04 [qa-smoke] S3 (AC-5): green — manifest records install_kind + non-empty source_checksums on copy install (test-deploy.sh C1).
- 2026-06-04 [qa-smoke] S4 (AC-2,AC-4): green — drift detected + relink repairs + remove deletes copies; probe/FORCE_COPY selects mode (test-deploy.sh C3/C4/C5).
- 2026-06-04 [qa-smoke] S5 (AC-6): green — test-deploy.sh carries both-mode coverage C1-C7 + back-compat C7; full scripts/test.sh PASS, 0 failures.
- 2026-06-04 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual pending).
- 2026-06-04 [qa-pass] S000079 (user-story): green smoke + 1 E2E row deferred post-merge (all post-ship). Phase 2 gates transitioned; post-ship AC (E1, real Git Bash install) awaits the windows-latest CI from S000080.
