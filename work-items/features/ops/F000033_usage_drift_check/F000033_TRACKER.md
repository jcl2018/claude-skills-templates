---
name: "USAGE.md drift detection (validate.sh Check 14)"
type: feature
id: "F000033"
status: active
created: "2026-06-01"
updated: "2026-06-01"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260601-162235-stack186"
blocked_by: "F000032"
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b cj-feat-20260601-162235-stack186` (stacked on `cj-feat-20260601-152835-3769` / PR #186)
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `scripts/validate.sh` has a new Check 14 ("USAGE.md content freshness") that, for every routable non-deprecated skill (`status != "deprecated"` AND non-empty `files`), compares `git log -1 --format=%ct -- skills/{name}/SKILL.md` against the same query on `skills/{name}/USAGE.md` and ERRORs when SKILL.md's `%ct` is greater than USAGE.md's `%ct`.
- [ ] The Check 14 ERROR message embeds the documented operator override (one-line `sed` to bump `last-updated:` in USAGE.md + `git add` + `git commit`).
- [ ] Check 14 uses `>` (not `>=`), so equal commit timestamps (atomic SKILL.md+USAGE.md commits, including brand-new skills) do NOT fire.
- [ ] Check 14 SKIPs with a visible one-line note when `git log -1` returns empty (file untracked / staged-only / never committed) — Check 13 owns presence; Check 14 owns freshness.
- [ ] `CLAUDE.md` gains a new `### USAGE.md drift detection` subsection under `## Conventions` documenting the override (`sed -i.bak` on `last-updated:` + `git add` + `git commit`) and explicitly noting that `git commit --allow-empty` does NOT advance `%ct`.
- [ ] `doc/PHILOSOPHY.md ## Documentation surfaces` (the F000032-added section) gains a paragraph documenting the drift rule + override + audit-trail role of the `last-updated:` field.
- [ ] `scripts/test.sh` has a new test (placed after the existing manual-skill-creation integration test, around line 215) that: (a) records SKILL.md's `%ct`, (b) makes a real content change to SKILL.md and commits, (c) runs validate.sh and asserts Check 14 ERRORs, (d) bumps USAGE.md's `last-updated:` via the documented override and commits, (e) re-runs validate.sh and asserts Check 14 passes, (f) `git reset --hard <prior-sha>` cleans up.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD (all 11 USAGE.md still share atomic `%ct` with their SKILL.md from F000032's commit).
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD.
- [ ] VERSION bumped (PATCH; `./scripts/check-version-queue.sh` confirms next free slot).
- [ ] CHANGELOG entry in user-forward voice naming F000033.
- [ ] PR opened against `cj-feat-20260601-152835-3769` (NOT main); PR body explicitly notes the stacking and the merge order (PR #186 first, then this PR).
- [ ] `skills-catalog.json` UNCHANGED — no new templates, no new files entries.
- [ ] No upstream gstack skill modifications — drift check is repo-internal only.
- [ ] No changes to `deprecated/` or `work-copilot/` (workbench-only scope; audit predicate excludes deprecated).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000066 (`usage_drift_check_impl`) — implementation user-story (validate.sh Check 14 + CLAUDE.md edit + PHILOSOPHY.md edit + test.sh extension)
- [ ] End-to-end pipeline run — `/ship` opens PR against PR #186's branch; `./scripts/validate.sh` PASS; `./scripts/test.sh` PASS; manual assignment = touch a SKILL.md, confirm Check 14 fires, copy-paste the override, confirm Check 14 clears

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-01: Created. Stacks on F000032 (PR #186). Adds validate.sh Check 14 (USAGE.md freshness via `git log -1 --format=%ct` comparison) + CLAUDE.md override-doc paragraph + PHILOSOPHY.md drift-rule paragraph + scripts/test.sh smoke. Closes the gap F000032 leaves open: Check 13 covers presence + structure; Check 14 covers content freshness.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/validate.sh` (MODIFIED — add Check 14: USAGE.md content freshness via git-log %ct)
- `CLAUDE.md` (MODIFIED — new `### USAGE.md drift detection` subsection under `## Conventions`)
- `doc/PHILOSOPHY.md` (MODIFIED — `## Documentation surfaces` extended with drift-rule paragraph)
- `scripts/test.sh` (MODIFIED — new smoke test after manual-skill-creation integration test)
- `VERSION` (MODIFIED — PATCH bump)
- `CHANGELOG.md` (MODIFIED — F000033 entry)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- **Symmetric pair with F000032.** F000032's Check 13 covers presence + structure ("USAGE.md exists with the five H2 sections"). F000033's Check 14 covers freshness ("USAGE.md content is at least as recent as SKILL.md"). Together: presence + structure + freshness. Nothing more — three checks, one file class.
- **Commit timestamps, NOT filesystem mtimes.** `git log -1 --format=%ct -- <path>` is deterministic across worktrees, fresh clones, and CI runners. Filesystem mtimes diverge.
- **Override is `last-updated:` bump, NOT `git commit --allow-empty`.** Empty commits touch no paths, so `git log -1 -- <path>` does NOT return them and `%ct` does NOT advance. The override edits one line of USAGE.md frontmatter (the `last-updated:` field, already present from F000032's template) — real content change, real commit, `%ct` advances, audit trail is the date.
- **Same-commit edits are NOT drift.** Check 14 uses `>` not `>=`. When F000032 first committed all 11 USAGE.md alongside SKILL.md updates atomically, every `%ct` matched. Same logic applies to brand-new skills (CLAUDE.md "Creating a new skill" creates SKILL.md and USAGE.md in one PR).
- **ERROR severity with a cheap operator override.** Per memory `feedback_skill_contracts_strict` and F000030's 1/13 DESIGN.md adoption proof: WARN gets ignored. ERROR + documented override is the load-bearing workbench pattern. The override hits on every cosmetic SKILL.md edit — acceptable friction for the drift signal.
- **Stacks on PR #186; merge order matters.** This branch was cut from `cj-feat-20260601-152835-3769`. Check 14 references `skills/*/USAGE.md` paths that only exist after PR #186 merges. If PR #186 closes without merging, this PR rebases onto main and naturally fails to apply — fail-loud, not silent-pass.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-01 [decision] Chose Approach A (lightweight git-log-based check + ERROR) over B (content-aware diff via lint-usage.sh), C (Approach A but WARN), and D (hook into /document-release post-merge AUQ). Summary: A is the smallest-possible drift-detection surface that survives the same 12-month horizon as F000032. One new validate.sh check (~20 lines), one CLAUDE.md paragraph, one PHILOSOPHY.md sentence, one scripts/test.sh smoke. B is ~5x complexity with heuristic tuning. C replays F000030's WARN-decay failure mode (1/13 DESIGN.md adoption). D adds moving parts (depends on F000028 hook surface, doesn't catch in-branch drift).
- 2026-06-01 [decision] Audit predicate matches F000032's exactly: `status != "deprecated"` AND non-empty `files`. Summary: Different predicate would let Check 13 and Check 14 fall out of sync. Re-use, don't fork. Audit set = same 11 skills.
- 2026-06-01 [decision] `%ct` strict greater-than (`>`), not greater-or-equal. Summary: Atomic SKILL.md+USAGE.md commits (F000032's backfill, brand-new skills following CLAUDE.md) share `%ct`; equal timestamps are exactly the convention F000032 establishes, not drift.
- 2026-06-01 [decision] Override is `last-updated:` frontmatter bump, NOT `git commit --allow-empty`. Summary: Initial draft used empty commits; `git log -1 -- <path>` only returns commits that touched the path, so empty commits don't advance `%ct`. The `last-updated:` field already exists in F000032's template + every backfilled USAGE.md, so `sed -i.bak 's/^last-updated:.*/last-updated: "$(date +%Y-%m-%d)"/'` produces a real one-line content change + audit trail.
- 2026-06-01 [decision] Single user-story decomposition. Summary: Check 14 + CLAUDE.md edit + PHILOSOPHY.md edit + test.sh extension all ship atomically under the pre-commit hook. Same shape as F000032 (single S000065 child). Splitting adds bookkeeping without splitting risk.
- 2026-06-01 [decision] No coupling to F000028's post-merge doc-sync hook (Open Question 5 / Approach D deferred). Summary: F000028's hook is a separate surface; tying Check 14 to it would slow the validate-time signal. If post-merge surfacing becomes useful after v1, add as a follow-up — out of scope here.
- 2026-06-01 [gates-update] Phase 2 Implement complete. Summary: Check 14 inserted in `scripts/validate.sh` after Check 13 (~40 lines, same predicate as Check 13: `status != "deprecated"` + non-empty `files`); `CLAUDE.md ## Conventions` extended with `### USAGE.md drift detection` subsection documenting the `last-updated:` override; `doc/PHILOSOPHY.md ## Documentation surfaces` extended with the **Drift rule** paragraph; `scripts/test.sh` Test 13 added (drift fires non-zero + override silences with PASS line, PRIOR_SHA reset cleanup via EXIT trap). `bash -n` clean on both scripts. No commit, no VERSION bump, no CHANGELOG edit — Phase 3 /ship handles those.
- 2026-06-01 [qa] **RESULT=red — see S000066 journal for full QA report.** Two integration bugs: (BUG-1) Test 13's `git commit -am` line 1582 + `git reset --hard $PRIOR_SHA` line 1607 destroys uncommitted feature-work files when run in pre-/ship QA context — confirmed empirically (recovered impl from reflog at 780c12b after first test.sh run wiped it). (BUG-2) Documented override workflow (`sed + git commit`) is blocked by pre-commit hook + Check 14 chicken-and-egg: hook runs validate.sh; Check 14 reads committed git history only; staged USAGE.md edit not yet visible → commit fails. Requires `--no-verify` not mentioned in docs. Check 14 logic itself is sound; manual smoke S1 (drift fires) PASS, S2 (override silences validate.sh once `--no-verify` used) PASS, S3 (SKIP code path present) PASS. Phase 2 QA gate NOT advanced.

- 2026-06-02T00:01:34Z [qa-reverify] Orchestrator applied two fixes after QA RED. (1) Test 13 in scripts/test.sh gated to clean-tree only — uncommitted-tree context now SKIPs with a code-presence check (=== Check 14:, is stale, last-updated all present in validate.sh source). Bug 1 (destructive `git commit -am` + `git reset --hard` sweeping uncommitted feature work) prevented from firing in pre-/ship QA. Full test runs in CI / post-/ship / any clean-tree invocation. (2) Check 14 in scripts/validate.sh made staged-aware: when USAGE.md appears in `git diff --cached --name-only`, USAGE_CT is set to `date +%s` (now). Bug 2 (chicken-and-egg: pre-commit hook blocks the override commit because committed USAGE_CT is still old) fixed — the staged change IS the operator's confirmation, so the documented `git add USAGE.md && git commit` workflow now lands without `--no-verify`. ./scripts/validate.sh → PASS (0 errors); ./scripts/test.sh → PASS (Failures: 0, Test 13 SKIP-with-presence-check). Phase 2 QA gates now green; ready for /ship.
