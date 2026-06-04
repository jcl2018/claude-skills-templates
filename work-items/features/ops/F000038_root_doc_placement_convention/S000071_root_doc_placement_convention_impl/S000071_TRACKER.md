---
name: "Root-doc placement convention + validate.sh Check 17 — implementation"
type: user-story
id: "S000071"
status: active
created: "2026-06-02"
updated: "2026-06-02T15:55:00Z"
parent: "F000038"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260602-152028-3848"
blocked_by: ""
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `cj-feat-20260602-152028-3848` (parent's worktree branch; ships in same PR as parent F000038)
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
- [x] Acceptance criteria verified met (implementation-scoped: 3 functional files; VERSION/CHANGELOG/ship are downstream)
- [x] Smoke tests pass (`./scripts/validate.sh` exits 0, Check 17 PASS: 5 entries; synthesized STRAY.md violation → non-zero + orphan ERROR; recovery → 0; `./scripts/test.sh` exits 0 incl. new Check 17 assertion)
- [x] Todos section reflects remaining work (remaining = VERSION bump + CHANGELOG + /ship, owned by downstream /ship step)
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
- [x] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [x] `/ship` — PR created (with pre-landing review) against main
- [x] `/land-and-deploy` — merged and deployed (deferred)

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [x] `CLAUDE.md` gains a new H2 section `## Doc placement convention (root vs doc/)`, placed adjacent to the F000034 "/document-release workbench audit conventions" section (for locality). Section contains:
  - **Prose rule**: human-readable *explanation* docs live in `doc/` and are registered in the tracked-doc/ manifest (Check 15); root-level `*.md` is limited to the allowlist below, each entry pinned at root for an external-tool or operational reason; config files stay at root because tooling hardcodes `./` paths; docs under `skills/`, `templates/`, `work-copilot/`, `work-items/`, `tests/` follow their own conventions and are out of this convention's scope.
  - **Load-bearing-constraint comment** (a prose line just ABOVE the YAML block, NOT inside the fence): (1) no `#`-leading comment lines inside the block — Check 17's parser disarms on any `#` line and would silently drop every entry below it; (2) the `### Tracked root docs allowlist` heading text is matched literally — renaming it parses to an empty allowlist, cascading to an orphan ERROR for every root `*.md`.
  - **The `### Tracked root docs allowlist` YAML block** with exactly 5 entries (`- path:` + `reason:`):
    - `README.md` — reason: GitHub renders it as the repo landing page
    - `CLAUDE.md` — reason: Claude Code auto-loads ./CLAUDE.md; moving to doc/ breaks auto-load
    - `CHANGELOG.md` — reason: /ship + /document-release write ./CHANGELOG.md (keep-a-changelog convention)
    - `CONTRIBUTING.md` — reason: GitHub surfaces it from root / docs/ / .github/ (not doc/)
    - `TODOS.md` — reason: operational backlog wired into /CJ_suggest, /CJ_goal_todo_fix, /ship Step 14
- [x] `scripts/validate.sh` gains a new Check 17 inserted AFTER Check 16:
  - Header echo: `=== Check 17: root-doc placement allowlist ===`
  - Parses the allowlist from CLAUDE.md via a flag-based awk: arm on `/^### Tracked root docs allowlist$/`, disarm on `/^#/` (ANY heading, not just `^###` — the allowlist is the last `###` subsection under its `##` section, so disarming only on `###` would over-capture `- path:` lines from a following `##` section), and `flag && /^- path:/ {print $3}`.
  - Enumerates root `*.md` via `find . -maxdepth 1 -type f -name '*.md'` (sed-strip `./`, sort).
  - **17-orphan branch**: for each root `*.md` on disk not in the parsed allowlist → `echo "  ERROR: root doc <f> is not in the CLAUDE.md 'Tracked root docs allowlist'; move it to doc/ (and register in the tracked-doc/ manifest) or add it to the root allowlist with a reason"` + `ERRORS=$((ERRORS+1))`.
  - **17-missing branch**: for each allowlist entry pointing to a missing file → `echo "  ERROR: <p> is in the CLAUDE.md root-docs allowlist but missing from disk"` + `ERRORS=$((ERRORS+1))`.
  - Uses the inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))` form (matching Checks 15/16), NOT the older `fail()` helper (prefix `  FAIL:`) that checks 12–16 abandoned.
  - Count-once PASS line: compute `N_ALLOW=$(echo "$ALLOWED_ROOT_MD" | grep -c . || true)` then `[ "$N_ALLOW" -gt 0 ] && echo "  PASS: root *.md allowlist parsed ($N_ALLOW entries)"`. Empty allowlist is NOT separately guarded — it surfaces as an orphan ERROR for every root `*.md` (fails loudly).
  - The Summary block's `exit 1` on `ERRORS>0` is unchanged.
- [x] On the clean PR HEAD, `./scripts/validate.sh` exits 0: Check 17 prints `PASS: root *.md allowlist parsed (5 entries)`; 0 errors / 0 warnings overall. (All 5 current root docs are allowlisted; nothing violates.)
- [x] Synthesized violation: `touch STRAY.md` at repo root → `./scripts/validate.sh` exits non-zero AND output contains `  ERROR: root doc STRAY.md is not in the CLAUDE.md`. `rm STRAY.md` → `./scripts/validate.sh` exits 0 again. (Verified: clean_rc=0, stray_rc=1 with exact orphan line, after_rm_rc=0.)
- [x] `scripts/test.sh`'s `zzz-test-scaffold` integration test is extended (the KNOWN BLIND SPOT) so that, in the scaffolded fixture repo: (1) `touch STRAY.md` at root → assert `validate.sh` exits non-zero AND its output contains the literal line prefix `  ERROR: root doc STRAY.md is not in the CLAUDE.md` (grep for that string — the `  ERROR:` prefix, NOT `  FAIL:`); (2) `rm STRAY.md` → assert `validate.sh` exits 0. (Added as Step 3b; runs validate.sh from $REPO_ROOT so `find . -maxdepth 1` is cwd-deterministic; STRAY.md removed before Step 4 — no leak.)
- [x] `./scripts/test.sh` exits 0 on PR HEAD (superset suite; the extended zzz-test-scaffold integration test runs + passes). (Verified: Failures: 0, RESULT: PASS, TESTSH_RC=0; both new Check 17 OK lines present.)
- [x] No `SKILL.md` / `USAGE.md` / `skills-catalog.json` / `personal-artifact-manifests.json` / any manifest-JSON modified — this is a CLAUDE.md + validate.sh + test.sh change only (no doc-drift Check 13/14, no catalog churn). (Verified via `git status --short`: only CLAUDE.md + scripts/validate.sh + scripts/test.sh modified.)
- [x] README.md, CLAUDE.md, and all 4 root config files (skills-catalog.json, cj-document-release.json, template-registry.json, VERSION) remain at root, byte-for-byte unchanged (zero file moves). (CLAUDE.md is intentionally modified — additive section only; no file moves; README + the 4 configs untouched per git status.)
- [ ] `CHANGELOG.md` has a new user-forward entry under `### Added` naming F000038 + the root-doc placement convention + Check 17 + symmetry with F000034's tracked-doc/ manifest (together they partition the top-level doc surface). Body: the workbench now declares which `*.md` files are allowed at the repo root in a "Tracked root docs allowlist" in CLAUDE.md (README, CLAUDE, CHANGELOG, CONTRIBUTING, TODOS — each with a stated reason); new validate.sh Check 17 enforces it; no files moved; configs stay at root (tooling-pinned).
- [ ] `VERSION` bumped from `6.0.3` to the next free slot (likely `6.0.4` PATCH); `./scripts/check-version-queue.sh` confirms the slot is free before /ship.
- [ ] PR opened against main via `/ship` (pre-landing review included). /CJ_goal_feature stops at PR per design; no auto-merge, no /land-and-deploy in this PR. PR body notes F000034 lineage (symmetric root-side counterpart, reuses Check 15's parse shape) + F000037 (the root-JSON event).
- [ ] No upstream `/document-release` modification. No changes to `~/.claude/`, `deprecated/`, or `work-copilot/`.

## Todos

<!-- Actionable items for this story. -->

- [x] Edit `CLAUDE.md`: insert a new H2 section `## Doc placement convention (root vs doc/)` adjacent to the F000034 "/document-release workbench audit conventions" section. Write the prose rule (explanation docs → doc/ + tracked-doc manifest; root `*.md` → allowlist; configs stay at root; per-subtree docs out of scope), then a prose comment line stating the two load-bearing constraints, then the `### Tracked root docs allowlist` YAML block with the 5 entries (path + reason). NO `#`-leading lines inside the block.
- [x] Edit `scripts/validate.sh`: insert Check 17 after Check 16. awk parser (arm on `/^### Tracked root docs allowlist$/`, disarm on `/^#/`, `flag && /^- path:/ {print $3}`); `find . -maxdepth 1 -type f -name '*.md'` enumeration; 17-orphan + 17-missing branches via inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))`; count-once `N_ALLOW` + PASS line.
- [x] Edit `scripts/test.sh`: extend the `zzz-test-scaffold` integration test with the Check 17 orphan assertion (touch STRAY.md → assert validate.sh non-zero + output contains `  ERROR: root doc STRAY.md is not in the CLAUDE.md`; rm STRAY.md → assert exit 0). KNOWN BLIND SPOT — do not skip. (Added as Step 3b.)
- [ ] Run `./scripts/check-version-queue.sh` to confirm the next free VERSION slot (expect 6.0.4). (DOWNSTREAM — owned by /ship.)
- [ ] Bump `VERSION` to the confirmed free slot (6.0.4). (DOWNSTREAM — owned by /ship.)
- [ ] Write `CHANGELOG.md` entry under `### Added` (user-forward voice) naming F000038 + the convention + Check 17 + F000034 symmetry. (DOWNSTREAM — owned by /ship.)
- [x] Run `./scripts/validate.sh` locally → expect 0 errors / 0 warnings (Check 17 PASS: 5 entries).
- [x] Manually walk the synthesized-violation smoke: `touch STRAY.md`; `./scripts/validate.sh` (expect non-zero + Check 17 orphan ERROR); `rm STRAY.md`; `./scripts/validate.sh` (expect 0).
- [x] Run `./scripts/test.sh` locally → expect exit 0 (extended zzz-test-scaffold runs + passes).
- [ ] Stage all touched files (CLAUDE.md, scripts/validate.sh, scripts/test.sh, CHANGELOG.md, VERSION) in one atomic commit (pre-commit hook runs validate.sh) → `/ship` against main with diff-review AUQ suppressed (orchestrator behavior). STOP at PR. (DOWNSTREAM — owned by /ship.)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-02: Implemented (Phase 2) via /CJ_implement-from-spec (auto mode). Edited 3 functional files: `CLAUDE.md` (new `## Doc placement convention (root vs doc/)` section + prose constraint note + `### Tracked root docs allowlist` block, 5 entries with reasons), `scripts/validate.sh` (Check 17 after Check 16 — verbatim from the approved design doc Step 2: flag-based awk arming on the literal heading + disarming on `/^#/`, `find . -maxdepth 1` enumeration, inline `  ERROR:` orphan + missing branches, count-once `N_ALLOW` PASS line), `scripts/test.sh` (zzz-test-scaffold Step 3b — the KNOWN BLIND SPOT — touch STRAY.md → assert non-zero + `  ERROR: root doc STRAY.md is not in the CLAUDE.md`; rm → assert 0; runs validate.sh from $REPO_ROOT for cwd-deterministic `find`). Self-verify GREEN: `./scripts/validate.sh` exits 0 (Check 17 PASS: 5 entries); synthesized STRAY.md → rc=1 with exact orphan line; recovery → rc=0; `./scripts/test.sh` exits 0 (Failures: 0, both new Check 17 OK lines present). git status confirms ONLY the 3 functional files modified — no catalog/SKILL.md/USAGE.md/manifest-JSON touched, no file moves. VERSION + CHANGELOG intentionally left to the downstream /ship step (queue-aware bump). NOT committed (commit happens at /ship).
- 2026-06-02: Created. Single-story decomposition of F000038 — `CLAUDE.md` new `## Doc placement convention (root vs doc/)` section + `### Tracked root docs allowlist` YAML block (5 entries: README, CLAUDE, CHANGELOG, CONTRIBUTING, TODOS, each with a reason) + `scripts/validate.sh` Check 17 (NEW: flag-based-awk allowlist parser disarming on any heading, `find -maxdepth 1` root-md enumeration, orphan + missing ERROR branches via inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))`, count-once PASS line) + `scripts/test.sh` zzz-test-scaffold orphan assertion (KNOWN BLIND SPOT) + VERSION (6.0.3 → next free slot) + CHANGELOG. Codify + enforce only — ZERO file moves; ERROR-strict (all 5 current root docs allowlisted, nothing violates day-one). Branch cut from origin/main HEAD post-PR #194 merged (F000037 v6.0.3, commit 10644ac). No upstream stacking.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #195: v6.0.4 feat: F000038 root-doc placement convention + validate.sh Check 17](https://github.com/jcl2018/claude-skills-templates/pull/195) — MERGED

## Files

<!-- Affected file paths. -->

- `CLAUDE.md` (MODIFIED — new `## Doc placement convention (root vs doc/)` section with prose rule + load-bearing-constraint comment + `### Tracked root docs allowlist` YAML block, 5 entries each with a reason)
- `scripts/validate.sh` (MODIFIED — new Check 17 after Check 16: flag-based-awk allowlist parser disarming on any heading, `find -maxdepth 1` root-md enumeration, orphan + missing ERROR branches via inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))`, count-once PASS line)
- `scripts/test.sh` (MODIFIED — zzz-test-scaffold integration extended with the Check 17 orphan assertion: touch STRAY.md → ERROR+exit1; rm → exit0)
- `VERSION` (MODIFIED — PATCH bump 6.0.3 → next free slot, likely 6.0.4)
- `CHANGELOG.md` (MODIFIED — new `### Added` entry in user-forward voice naming F000038 + the convention + Check 17 + F000034 symmetry)

## Insights

<!-- Non-obvious findings worth remembering. -->

- **The two manifests fully partition the top-level doc surface.** F000034's tracked-doc/ manifest declares `doc/` contents (Check 15); this story adds a symmetric "Tracked root docs" allowlist declaring root `*.md` + *why* (Check 17). New explanation doc → `doc/` + tracked-doc manifest entry; new root `*.md` → justified + allowlisted. Drift either way fails validate.sh. No human-readable doc can land at root by accident again.
- **Self-documenting + zero blast radius.** Each allowlist entry carries a `reason:`, so the convention explains itself at the point of enforcement. Nothing moves; nothing currently violates the rule, so it ships ERROR-strict day-one with no migration.
- **Check 17 disarms on ANY heading (`^#`), not just `^###` — strictly more robust than Check 15.** The allowlist is the last `###` subsection under its `##` section; disarming only on `###` would over-capture `- path:` lines from a following `##` section. Check 15 works as-is given its position; retrofitting it is out of scope.
- **The inline ERROR form is load-bearing for the test assertion.** Check 17 uses `echo "  ERROR:"; ERRORS=$((ERRORS+1))` (matching Checks 15/16), NOT the older `fail()` helper (`  FAIL:`). The test.sh assertion greps for the literal `  ERROR: root doc STRAY.md is not in the CLAUDE.md` — using the wrong prefix would silently break the test.
- **The test.sh zzz-test-scaffold edit is a KNOWN RECURRING BLIND SPOT.** F000032 (Check 13), F000034 (Check 15), F000035, F000037 (Check 16) all needed this parallel edit and the implement step forgot it each time. For Check 17 it is a mandatory pre-flight item + an explicit TEST-SPEC smoke row (S3), not an afterthought.
- **Empty-allowlist fails loudly, never silently.** A renamed heading or a `#`-comment-line mid-block parses to an empty allowlist → orphan ERROR for every root `*.md`. The CLAUDE.md constraint comment warns the editor; the check needs no extra guard.
- **No SKILL.md change keeps the diff narrow.** Because nothing under `skills/` is touched, Check 13 (USAGE.md presence) + Check 14 (USAGE.md drift) stay untouched, no catalog churn, no manifest-JSON edits. The change is CLAUDE.md + validate.sh + test.sh + VERSION + CHANGELOG only — purely additive except the version bump.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-02 [decision] Mechanism = manifest in CLAUDE.md (D3, Approach B). Summary: A `### Tracked root docs allowlist` YAML block in CLAUDE.md parsed by validate.sh Check 17, the same flag-based-awk way Check 15 parses the tracked-doc/ manifest. Chosen over Approach A (hardcoded bash array + separate prose — splits allowlist from rationale into two drifting places, no co-located `reason:`) and Approach C (JSON config — over-engineering for 5 filenames; adds another root config surface, ironic for a tidy-the-root feature).
- 2026-06-02 [decision] Check 17 disarms on ANY heading (`/^#/`), not just `^###`. Summary: The allowlist is the LAST `###` subsection under its `##` section. Disarming only on `^###` would over-capture `- path:` lines from a following `##` section. Disarm-on-any-heading is strictly more robust; Check 15's narrower form is left as-is (works given its position).
- 2026-06-02 [decision] Inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))` form, not the fail() helper. Summary: Checks 15/16 increment ERRORS inline with the `  ERROR:` prefix; Check 17 matches its neighbors rather than the abandoned `fail()` helper (`  FAIL:`, line 12, unused by checks 12–16). Keeps the new check consistent + lets the test.sh assertion grep for the right literal.
- 2026-06-02 [decision] Root allowlist = the 5 current root docs, each with a stated reason. Summary: README (GitHub landing), CLAUDE (auto-load), CHANGELOG (/ship + /document-release write target), CONTRIBUTING (GitHub-surfaced), TODOS (operational backlog wired into /CJ_suggest, /CJ_goal_todo_fix, /ship Step 14). Nothing currently violates → ERROR-strict ships safely day-one.
- 2026-06-02 [decision] ERROR-strict, not warning. Summary: Matches the repo ethos (F000037 strict-required; Checks 12–16 ERROR-strict). A stray new root `*.md` ERRORs + exits 1, forcing the contributor to move it to `doc/` (+ tracked-doc manifest) or allowlist it with a reason.
- 2026-06-02 [decision] Empty-allowlist is not separately guarded; fails loudly via orphan errors. Summary: A renamed `### Tracked root docs allowlist` heading or a `#`-comment line mid-block parses to an empty allowlist, which surfaces as an orphan ERROR for every root `*.md` — never a silent pass. The CLAUDE.md prose-comment warns the editor; the check needs no extra guard.
- 2026-06-02 [decision] test.sh zzz-test-scaffold orphan assertion is mandatory (KNOWN BLIND SPOT). Summary: Every prior new validate.sh check (F000032 Check 13, F000034 Check 15, F000035, F000037 Check 16) needed a parallel edit to scripts/test.sh's zzz-test-scaffold integration fixture, and the implement step systematically forgot it. For Check 17 the assertion (touch STRAY.md → ERROR+exit1; rm → exit0) is a pre-flight item + explicit TEST-SPEC row.
- 2026-06-02 [decision] No SKILL.md change → no USAGE.md drift (Check 13/14 untouched). Summary: CLAUDE.md + validate.sh + test.sh + VERSION + CHANGELOG only. No catalog churn, no manifest-JSON edits. Narrow + additive diff (except the version bump).
- 2026-06-02 [decision] Single user-story decomposition (atomic implementation). Summary: CLAUDE.md section + Check 17 + test.sh assertion + VERSION + CHANGELOG ship atomically in one commit/PR (same shape as F000037 / S000070). Pre-commit hook runs validate.sh; stage everything once.
- 2026-06-02 [decision] Config-placement enforcement deferred to v2. Summary: A sibling "tracked root configs" manifest is deferred. Configs are tooling-pinned + stable; the prose documents the rule, no enforcement churn in v1.
- 2026-06-02 [decision] PR-stop at /ship per /CJ_goal_feature semantics; no /land-and-deploy. Summary: /CJ_goal_feature stops at PR by design — PR is the architecture gate (human review). Per memory `project_workbench_auto_deploy_unsafe`.
- 2026-06-02 [decision] No upstream `/document-release` modification (workbench-only). Summary: The new CLAUDE.md section rides /document-release's existing project-context read at Step 2; no upstream skill modification. Per memory `feedback_workbench_scope`.
- 2026-06-02 [qa-smoke] S1 (AC-3): green — `./scripts/validate.sh` exits 0; Check 17 prints `PASS: root *.md allowlist parsed (5 entries)`; Errors: 0 / Warnings: 0. S1 grep (`PASS: root *.md allowlist parsed (5 entries)`) matched.
- 2026-06-02 [qa-smoke] S2 (AC-3): green — synthesized violation: `touch STRAY.md` → validate.sh exits 1 AND output contains exact orphan line `  ERROR: root doc STRAY.md is not in the CLAUDE.md 'Tracked root docs allowlist'...`; `rm STRAY.md` → validate.sh exits 0. Enforcement proven both directions; STRAY.md confirmed removed (no tree leak).
- 2026-06-02 [qa-smoke] S3 (AC-4): green — `./scripts/test.sh` exits 0 (Failures: 0, RESULT: PASS). zzz-test-scaffold Check 17 assertions both OK: "stray root doc STRAY.md triggers orphan ERROR + non-zero exit" and "validate.sh exits 0 again after the stray root doc is removed". The KNOWN BLIND SPOT (test.sh integration fixture) is wired, not shipped naked.
- 2026-06-02 [qa-smoke] S4 (AC-1, AC-2): green — CLAUDE.md has `## Doc placement convention (root vs doc/)` + `### Tracked root docs allowlist` (5 `- path:` entries); validate.sh has `=== Check 17: root-doc placement allowlist ===` with both orphan + missing branches (verified via the clean-PASS + synthesized-violation runs above).
- 2026-06-02 [qa-smoke-manual] S5 (AC-5): pending human verification — VERSION bump (→6.0.4) + CHANGELOG F000038 entry are DOWNSTREAM (owned by /ship); not yet present pre-ship. The no-SKILL/USAGE/catalog-churn half is satisfied (git status shows only CLAUDE.md + scripts/validate.sh + scripts/test.sh modified). Full-suite half (./scripts/test.sh green) verified at S3.
- 2026-06-02 [qa-smoke-summary] green: 4/4 non-manual rows green (1 manual row pending — S5 VERSION/CHANGELOG deferred to /ship).
- 2026-06-02 [qa-e2e-deferred] E4 (AC-2): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); live pre-commit-hook dogfood (commit a stray root FOO.md → hook blocks via Check 17) is only verifiable after merge on a feature branch; not run pre-ship.
- 2026-06-02 [qa-e2e-run-start] RUN_ID=20260602-163429-11232 commit=10644ac
- 2026-06-02 [qa-e2e] E1 (AC-1): green — CLAUDE.md `## Doc placement convention (root vs doc/)` section answers all three contributor questions from the section alone: new explanation doc → doc/ + tracked-doc manifest; a required root *.md → allowlist it with a reason; CLAUDE.md itself allowed at root → Claude Code auto-loads ./CLAUDE.md. No need to read validate.sh or the TEST-SPEC. [parent-inline]
- 2026-06-02 [qa-e2e] E2 (AC-1, AC-2): green — diff review: CLAUDE.md block has 5 entries each `- path:` + `reason:`, NO `#`-leading lines inside the block, constraint comment OUTSIDE the fence. Check 17 disarms on `/^#/` (any heading), uses inline `  ERROR:` form (not `fail()`/`  FAIL:`), has both 17-orphan and 17-missing branches + count-once PASS line. [parent-inline]
- 2026-06-02 [qa-e2e] E3 (AC-3, AC-4): green — full local pipeline walk: `check-version-queue.sh` confirms next free slot v6.0.4; clean validate.sh exit 0 + Check 17 PASS (5 entries) + 0 errors/0 warnings; STRAY.md → non-zero + exact orphan ERROR; rm → exit 0; test.sh exit 0 (zzz-test-scaffold Check 17 assertions pass). No regression in Checks 1–16. [parent-inline]
- 2026-06-02 [qa-e2e-summary] green (0s subagent; 3 rows parent-inline; 1 deferred): All 3 pre-ship E2E rows (E1/E2/E3) green via parent-inline shell-assertion verification; E4 deferred to post-merge (post-ship). No subagent dispatched (shell-command E2E rows, depth-limit context — run inline). Tracker journal updated.
- 2026-06-02 [qa-pass] S000071 (user-story): green smoke (4/4 non-manual; 1 manual S5 pending /ship) + green E2E (E1/E2/E3; E4 post-ship deferred). Phase 2 QA-owned gates already [x] (re-verified green this run; commit deferred to /ship per /CJ_goal_feature pipeline). Evidence: T1 validate exit 0 + Check 17 PASS 5 entries; T2 STRAY.md → rc=1 exact orphan ERROR → rm → rc=0; T3 test.sh exit 0 incl. both zzz-test-scaffold Check 17 assertions.
- 2026-06-02 [gates-update] Phase 3: /ship — PR #195,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #195,PRs section: linked PR #195 (MERGED).
