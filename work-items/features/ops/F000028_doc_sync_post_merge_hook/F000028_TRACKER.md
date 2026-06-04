---
name: "Doc-sync via post-merge git hook (zero changes to the three cj_goal skills)"
type: feature
id: "F000028"
status: active
created: "2026-05-30"
updated: "2026-05-30"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260530-200501-31190"
blocked_by: ""
---

> **RETIRED by F000040 (2026-06-03).** The post-merge/post-rewrite doc-sync
> marker hooks shipped by this feature were removed once F000036's inline
> Step 5.5 doc-sync made them redundant. This tracker is kept as archival
> history only. See `work-items/features/ops/F000040_retire_doc_sync_marker_mechanism/`.

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/doc_sync_post_merge_hook`
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

- [ ] `./scripts/setup-hooks.sh` installs a `post-merge` hook AND a `post-rewrite` hook, both containing the `# doc-sync trigger block` marker (greppable) and both carrying the existing `# Auto-installed by scripts/setup-hooks.sh` sentinel.
- [ ] After a simulated main-moving merge (test fixture in `tests/`, flat `tests/<name>.test.sh` convention), the hook writes `~/.gstack/doc-sync-pending/<slug>.json` atomically with `head_sha` matching `git rev-parse HEAD` and `diff_base` resolving to a valid tree-ish.
- [ ] Re-running the hook on the same HEAD is a no-op (idempotency check via `.doc-sync-last-head`).
- [ ] A doc-only merge does not write the marker (triviality filter) — unless `DOC_SYNC_FORCE=1` is set.
- [ ] `git pull --rebase` on main triggers the same marker write via `post-rewrite`.
- [ ] The existing D000013 skills-deploy auto-sync still runs in the same `post-merge` hook (no regression — sentinel-aware re-install does NOT backup-thrash).
- [ ] `validate.sh` still passes (no new shellcheck violations in the hook body or in setup-hooks.sh).
- [ ] `test.sh` includes new test rows for the doc-sync trigger: (a) main-moving merge writes marker; (b) same HEAD is idempotent; (c) doc-only merge skips; (d) `FORCE=1` overrides skip; (e) initial-commit edge case (empty `_LAST_SYNCED`, no `HEAD^`) falls back to empty-tree diff base; (f) `post-rewrite` writes the same marker as `post-merge`.
- [ ] CLAUDE.md "Scripts reference" table — the existing `setup-hooks.sh` row gets "post-merge + post-rewrite doc-sync trigger" APPENDED (not overwritten) to existing "post-merge auto-sync" wording.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Extend `scripts/setup-hooks.sh` heredoc body for `post-merge` to APPEND the new doc-sync trigger block as section 3 (after D000013 skills-deploy + F000011 lifecycle-gate, before final `exit 0`).
- [ ] Add a fresh `install_hook post-rewrite` call carrying the same trigger block (standalone install — no prior post-rewrite hook).
- [ ] Wrap the new trigger block in `{ ... } || true` so failure never blocks the merge.
- [ ] Add 6 new test rows in `tests/setup-hooks.test.sh` (flat convention) — see Acceptance Criteria (h) for the row inventory.
- [ ] Append "post-merge + post-rewrite doc-sync trigger" to CLAUDE.md `setup-hooks.sh` row (don't overwrite existing "post-merge auto-sync" wording).
- [ ] Add CHANGELOG entry for the new doc-sync trigger.
- [ ] Run `./scripts/validate.sh` + `./scripts/test.sh` locally before /ship.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-30: Created. Doc-sync via post-merge + post-rewrite git hook — zero changes to the three cj_goal skills; symmetric trigger at the "main moved" event for all three pipelines.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/setup-hooks.sh` (extended: post-merge heredoc body grows section 3; new `install_hook post-rewrite` call)
- `tests/setup-hooks.test.sh` (new file, flat-convention test rows)
- `CLAUDE.md` (Scripts reference row append)
- `CHANGELOG.md` (new entry)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The literal "step at end of three cj_goal skills" framing has two structural problems: (1) the three pipelines end at load-bearing-ly different places (feature PR-stops; defect/investigate post-deploy), so a byte-symmetric "doc-sync at end" inside the skills is impossible; (2) the three skills already have known misalignment (resume-state model, telemetry schema, halt-marker naming) that would propagate into any copy-pasted step. Reframing doc-sync as "a property of main moving" — implemented as a post-merge hook — sidesteps both problems and gives a single evolution surface for the doc-sync logic.
- `post-merge` is a LOCAL git hook; it does NOT fire on `gh pr merge` (that's a remote merge). The actual trigger in this workbench's workflow is `git pull` on `main` AFTER the PR merges on GitHub. To also cover rebase-flow users (`git pull --rebase`), the same trigger block is installed as a `post-rewrite` hook. `git reset --hard origin/main` is uncoverable by hooks (documented gap).
- The trigger block is shared between both hook bodies but lives INSIDE a single-quoted outer heredoc (`<< 'HOOK'`) so its body passes through verbatim, while its inner `<<EOF` is UNQUOTED so `$_REPO_SLUG` / `$_CURRENT_HEAD` / `$_DIFF_BASE` expand at hook-execution time. Both quoting choices are load-bearing — flipping either silently breaks expansion timing.
- Decision: drop a marker (option a) — not spawn `claude --print /document-release` from the hook. Rationale: spawning a Claude session from a git hook is heavy (~30–60s + auth) and runs synchronously inside the user's merge — too disruptive. The marker pickup AUQ in the cj_goal skills is a deliberately separate, deferred follow-up.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-30: Chose Approach C (post-merge + post-rewrite hook) over A (per-skill inline doc-sync) and B (shared helper `cj-goal-common.sh --phase doc-sync`). Summary: Approach A triplicates the wrap pattern across two skills and gives feature an asymmetric PR-body-checklist shape; Approach B fights the "ship doc-sync first" sequencing because the helper-addition IS partial alignment work. The hook approach is the only one with zero skill-side changes.
- [decision] 2026-05-30: Drop a marker instead of spawning `claude --print /document-release` from the hook. Synchronous Claude invocation inside a user's merge is too disruptive (~30–60s + auth). The marker-pickup AUQ in cj_goal skills is a deliberately separate follow-up.
- [decision] 2026-05-30: Install BOTH `post-merge` and `post-rewrite` hooks. `post-merge` covers `git pull` (fast-forward + merge-commit cases). `post-rewrite` covers `git pull --rebase`. The same trigger block lives in both. `git reset --hard origin/main` is uncoverable by either; documented as a known gap.
- [decision] 2026-05-30: Heredoc nesting — outer `<< 'HOOK'` single-quoted (body passes through verbatim); inner `<<EOF` unquoted (so `$_REPO_SLUG` / `$_CURRENT_HEAD` / `$_DIFF_BASE` expand at hook-execution time, not at install time). Both quoting choices are load-bearing.
- [decision] 2026-05-30: Triviality filter — skip if the merge touched only docs (`README.md|CHANGELOG.md|CLAUDE.md|CONTRIBUTING.md|ARCHITECTURE.md|docs/`). Anchored regex so `READMEs.py` does not match. Opt out via `DOC_SYNC_FORCE=1`.
