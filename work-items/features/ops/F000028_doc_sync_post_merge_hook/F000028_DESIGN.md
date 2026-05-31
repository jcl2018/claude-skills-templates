---
type: design
parent: F000028
title: "Doc-sync via post-merge git hook (zero changes to the three cj_goal skills) — Feature Design"
version: 1
status: Draft
date: 2026-05-30
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The three CJ_ orchestrator skills (`/cj_goal_feature`, `/cj_goal_defect`, `/CJ_goal_investigate`) ship code that lands on `main`, but project documentation (README, ARCHITECTURE, CONTRIBUTING, CLAUDE.md, etc.) drifts because nothing in the pipelines reads the merged diff and updates the docs to match. The user's initial framing was "add a doc-sync step at the end of these three so the doc is well maintained." A pre-design audit revealed that literal framing has two structural problems:

1. **The three pipelines end at load-bearing-ly different places.** `/cj_goal_feature` PR-stops by design (architecture gate is the PR). `/cj_goal_defect` and `/CJ_goal_investigate` continue through `/land-and-deploy`. A byte-symmetric "doc-sync at end" step is structurally impossible inside the pipelines.
2. **The three skills already have known structural misalignment** (resume-state model, telemetry schema drift, halt-marker naming, missing-jq halt blocks) that would propagate into any new step copy-pasted across them.

Reframing doc-sync as a property of "main moved" — implemented as a `post-merge` + `post-rewrite` git hook — sidesteps both problems. The hook fires regardless of HOW main moved: `/cj_goal_defect`'s `/land-and-deploy`, `/CJ_goal_investigate`'s `/land-and-deploy`, an operator-merged `/cj_goal_feature` PR, a manual `/ship`, even a hotfix `git push` direct to main. One evolution surface for doc-sync logic; no per-skill drift surface.

## Shape of the solution

Extend `scripts/setup-hooks.sh` to install (or augment) a `post-merge` hook AND install a new `post-rewrite` hook. Both hook bodies carry the same doc-sync trigger block, which:

1. Verifies HEAD is on `main` (otherwise exits 0 — not a main-moving sync).
2. Reads `.doc-sync-last-head` and exits 0 if HEAD hasn't moved since the last doc-sync (idempotency).
3. Runs a triviality filter on the diff (`README.md|CHANGELOG.md|CLAUDE.md|CONTRIBUTING.md|ARCHITECTURE.md|docs/`) and exits 0 if only docs changed (unless `DOC_SYNC_FORCE=1`).
4. Otherwise atomically writes a marker file at `~/.gstack/doc-sync-pending/<repo-slug>.json` with `repo`, `head_sha`, `main_moved_at`, `diff_base`, `changed_files`.
5. Echoes a `[doc-sync]` note to stderr telling the operator to run `/document-release` in their next Claude session.

The hook does NOT spawn `claude --print /document-release` directly — that's too heavy (~30–60s + auth) to run synchronously inside the user's git operation. The marker-pickup AUQ in the cj_goal skills is a deliberately separate, deferred follow-up.

The work decomposes into a single atomic user-story (the implementation is one coherent diff to `scripts/setup-hooks.sh` + tests + CLAUDE.md row + CHANGELOG):

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Implement post-merge + post-rewrite doc-sync trigger block and test it end-to-end | S000061 | [S000061_doc_sync_post_merge_hook_impl/S000061_TRACKER.md](S000061_doc_sync_post_merge_hook_impl/S000061_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach C (post-merge + post-rewrite hook) over Approach A (per-skill inline doc-sync) or Approach B (shared `cj-goal-common.sh --phase doc-sync` helper). | A triplicates the wrap-/document-release pattern across two skills and gives `/cj_goal_feature` an asymmetric shape (PR-body checklist != inline invocation). B fights the "ship doc-sync first" sequencing because the helper-addition IS partial alignment work. C is the only approach with zero changes to the three orchestrator skills. |
| 2 | Drop a marker (option a) instead of spawning `claude --print /document-release` (option b) or being read-only (option c). | Spawning a Claude session from a git hook is heavy (~30–60s + auth) and runs synchronously inside the user's merge — too disruptive. A read-only "doc debt detected" check is too weak (no actual updates). The marker is the middle path: hook stays cheap; doc-sync still actually runs (in the next Claude session). |
| 3 | Install BOTH `post-merge` AND `post-rewrite` hooks with the same trigger block. | `post-merge` covers `git pull` (fast-forward + merge-commit cases). `post-rewrite` covers `git pull --rebase`. `git reset --hard origin/main` fires no hook — uncoverable; documented as a known gap. |
| 4 | Append the new trigger block to the existing `post-merge` heredoc body as section 3 (after D000013 skills-deploy + F000011 lifecycle-gate, before final `exit 0`). The `install_hook post-merge` writes the combined body wholesale via atomic mv — there is no runtime append helper. | The existing hook already carries TWO load-bearing sections (D000013 skills-deploy auto-sync at setup-hooks.sh:109-115 + F000011/S000020 lifecycle-gate auto-update at setup-hooks.sh:117-159). Both must be preserved verbatim. The doc-sync trigger is section 3, wrapped in `{ ... } || true` so failure never blocks the merge. |
| 5 | Heredoc nesting — outer `<< 'HOOK'` is single-quoted (body passes through verbatim); inner `<<EOF` is UNQUOTED so `$_REPO_SLUG` / `$_CURRENT_HEAD` / `$_DIFF_BASE` expand at hook-execution time, not at install time. | Both quoting choices are load-bearing. Flipping the outer quoting expands variables at install time (wrong context — `$_CURRENT_HEAD` is empty during install). Flipping the inner quoting prevents expansion at runtime (wrong content in the marker). |
| 6 | Triviality filter regex is anchored: `^(README\.md|CHANGELOG\.md|CLAUDE\.md|CONTRIBUTING\.md|ARCHITECTURE\.md|docs/)`. | Anchoring prevents `READMEs.py` from matching `README.md` and being skipped as a doc-only change. The `docs/` prefix has trailing slash so `docs.py` does not match. `DOC_SYNC_FORCE=1` env var opts out of triviality filter entirely (for testing or operator override). |
| 7 | Ship doc-sync FIRST; alignment cleanup of the three cj_goal skills (resume-state model, telemetry schema, halt-marker naming, investigate's missing-jq halt blocks) is a SEPARATE follow-up work-item, NOT in this PR. | Minimum scope respects the user's "ship doc-sync first" instruction at D2. The alignment cleanup is logged in Next Steps and will be captured as TODOS.md rows by the doc-sync hook's first run on this PR's own merge — instant dogfood. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Per-machine opt-out config flag (`~/.gstack/doc-sync-disabled` sentinel) for users who don't want any doc-sync prompts. | Deferred to v2; trivial to add. Resolved if v1 hook surfaces noisy prompts. |
| `git reset --hard origin/main` and other direct ref-manipulation operations don't fire either hook. | Documented as a known gap in DESIGN.md / SPEC.md; operator runs `/document-release` manually if they reset main. Resolved by acceptance — no hook can cover this. |
| Marker-pickup AUQ in cj_goal skills is the consumer side of this design but is out-of-scope for THIS feature. Without it, markers accumulate silently in `~/.gstack/doc-sync-pending/`. | Logged in Next Steps as a separate follow-up work-item. Manual fallback in v1: operator greps the marker dir and runs `/document-release`. |
| Trigger block lives INSIDE a heredoc inside `setup-hooks.sh` — quoting bugs are silent failures (wrong content in the marker). | Tested directly by tests (b) marker contents validation — `head_sha` must match `git rev-parse HEAD` AT THE TIME THE HOOK FIRED. If quoting flipped, the marker would contain `$_CURRENT_HEAD` literal. |
| Doc-sync runs on EVERY non-trivial main-moving sync — could be noisy for active developers pulling main many times per day with the same HEAD. | Idempotency guard (`.doc-sync-last-head` short-circuit) catches the most common noise case. Resolved by observation if v1 is too noisy in real use. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. -->

- [ ] `./scripts/setup-hooks.sh` installs a `post-merge` hook AND a `post-rewrite` hook, both containing the `# doc-sync trigger block` marker comment (greppable) and both carrying the existing `# Auto-installed by scripts/setup-hooks.sh` sentinel.
- [ ] After a simulated main-moving merge in a test fixture, the hook writes `~/.gstack/doc-sync-pending/<slug>.json` atomically with `head_sha` matching `git rev-parse HEAD` and `diff_base` resolving to a valid tree-ish.
- [ ] Re-running the hook on the same HEAD is a no-op (idempotency check via `.doc-sync-last-head`).
- [ ] A doc-only merge does not write the marker (triviality filter) — unless `DOC_SYNC_FORCE=1`.
- [ ] `git pull --rebase` on main triggers the same marker write via `post-rewrite`.
- [ ] The existing D000013 skills-deploy auto-sync still runs in the same `post-merge` hook (no regression — sentinel-aware re-install does NOT backup-thrash).
- [ ] `validate.sh` still passes (no new shellcheck violations).
- [ ] `tests/setup-hooks.test.sh` covers the 6 test rows: (a) main-moving merge writes marker, (b) same HEAD is idempotent, (c) doc-only merge skips, (d) `FORCE=1` overrides skip, (e) initial-commit edge case (empty `_LAST_SYNCED`, no `HEAD^`) falls back to empty-tree diff base, (f) `post-rewrite` writes the same marker as `post-merge`.
- [ ] CLAUDE.md "Scripts reference" `setup-hooks.sh` row has "post-merge + post-rewrite doc-sync trigger" APPENDED to existing "post-merge auto-sync" wording (not overwritten).
- [ ] CHANGELOG entry added.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Editing any of the three cj_goal skill files (`/cj_goal_feature`, `/cj_goal_defect`, `/CJ_goal_investigate`) — the design's core decision is ZERO changes to them.
- Marker-pickup AUQ inside cj_goal skills (or a new `CJ_doc_sync` helper skill) — separate follow-up; out of scope here.
- Alignment cleanup of the three cj_goal skills' top-3 misalignments (resume-state model, telemetry schema drift, halt-marker naming) — separate follow-up; user explicitly said "ship doc-sync first" at D2.
- Investigate's missing-jq halt blocks (pipeline.md:597/655/668/684/697/710 are `# Telemetry: end_state=...` comments without actual writes) — separate follow-up captured in Next Steps.
- Per-machine opt-out flag (`~/.gstack/doc-sync-disabled` sentinel) — deferred to v2; trivial to add later.
- Coverage of `git reset --hard` and other direct ref-manipulation operations — uncoverable by git hooks. Documented as a known gap, not a deliverable.
- Spawning `claude --print /document-release` from the hook (option b in the design's Implementation Sketch) — rejected as too disruptive (~30–60s + auth synchronous inside merge).
- Read-only "doc debt detected" surface (option c) — rejected as too weak (no actual updates).

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000028_TRACKER.md](F000028_TRACKER.md)
- Roadmap: [F000028_ROADMAP.md](F000028_ROADMAP.md)
- Source design doc (/office-hours): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260530-200501-31190-design-20260530-205001.md`
- Child user-story: [S000061_doc_sync_post_merge_hook_impl/S000061_TRACKER.md](S000061_doc_sync_post_merge_hook_impl/S000061_TRACKER.md)
- Related: `work-items/features/personal-workflow/F000011_phase3_gate_autoupdate/` (section 2 of the existing post-merge hook — DO NOT REMOVE).
- Related: D000013 skills-deploy auto-sync (section 1 of the existing post-merge hook — DO NOT REMOVE; setup-hooks.sh:109-115).
