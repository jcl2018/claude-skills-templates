---
name: "Phase 3 lifecycle-gate auto-update via post-merge hook"
type: feature
id: "F000011"
status: active
created: "2026-05-08"
updated: "2026-05-08"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/phase3-gate-autoupdate"
blocked_by: ""
---

<!-- Source design: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-phase3-gate-autoupdate-design-20260508-165047.md
     Resolves the Phase 3 lifecycle-gate auto-update gap captured in TODOS.md (P2/M).
     Approach B (engine + post-merge hook) chosen after 6-premise check + 3-alternative review. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/phase3-gate-autoupdate` (already on it)
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, 6-premise check, recommended approach, deferred work)
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery)
5. Define acceptance criteria
6. Decompose into child user-story (S000020 — engine + hook bundled)

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-story drives implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when child completes phases
3. Update Todos section — check off completed children
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [x] Smoke tests pass in CI
- [ ] E2E walked manually
- [x] `/ship` — PR created (with pre-landing review)
- [x] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

- [ ] `/personal-workflow check --update <work-item-dir>` exists, registered in `personal-workflow/check.md`, validated by `validate.sh`
- [ ] Engine infers Phase 3 gate state from external sources (`gh pr view`, `gh pr checks`, `git log`, recursive child checks)
- [ ] Engine writes `[x]` for inferable gates with positive signal; never downgrades `[x]` → `[ ]` (idempotent)
- [ ] Engine NEVER auto-marks `E2E walked manually` (purely human-driven; explicit exclusion)
- [ ] Engine appends `[gates-update]` journal entry summarizing what changed
- [ ] Engine appends merged PR link + status to `## PRs` section (additive, not duplicating existing entries)
- [ ] `scripts/post-merge-hook.sh` exists and is wired into `scripts/setup-hooks.sh`
- [ ] Hook fires only when on `main` branch after a merge/pull (silently no-ops on feature branches)
- [ ] Hook iterates work-item dirs touched by incoming commits and runs `--update` on each
- [ ] Hook failures are best-effort — print warning, don't block git operation
- [ ] End-to-end: ship a small change, `git pull main`, observe Phase 3 gates auto-update on the touched work-item without any manual checkbox edits

## Todos

- [x] Create feat/phase3-gate-autoupdate branch
- [ ] S000020 implement engine + hook — scaffold + ship
- [ ] After ship + merge: run end-to-end verification (the success criterion from the design)

## Log

- 2026-05-08: Created. F000011 captures the Phase 3 lifecycle-gate auto-update work — closes the P2/M TODO that has been observed across every PR shipped this session (S000017/S000019/S000018/D000016 all left Phase 3 gates blank). Approach B (engine + git post-merge hook) chosen after 6-premise check + 3-alternative review in /office-hours. Single user-story child (S000020) bundles the engine + hook since they ship together.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #69: v1.10.0 feat: F000011 Phase 3 lifecycle-gate auto-update — engine + post-merge hook](https://github.com/jcl2018/claude-skills-templates/pull/69) — MERGED

## Files

- `skills/personal-workflow/check.md` (modified — adds Step 13.5 Phase 3 gate inference + Step 13.6 PR linking + Step 13.7 journal entry; adds `--update` flag handling)
- `scripts/post-merge-hook.sh` (NEW — hook script: on-main check, work-item dir detection, per-dir `--update` invocation)
- `scripts/setup-hooks.sh` (modified — wires the post-merge hook into the install pass)
- `TODOS.md` (modified — close the Phase 3 lifecycle-gate auto-update TODO)

## Insights

- **F000010 pipeline dogfood.** F000011 is the first end-to-end pipeline run on a real work-item: /office-hours → /scaffold-work-item → /implement-from-spec → /qa-work-item → /ship. The point is to verify the pipeline mechanics work as a chain, not just per-skill in isolation. If the chain breaks somewhere, that's a bug in the pipeline (not in F000011).
- **Inferable vs human-driven gate split is structural.** 5 of 6 Phase 3 gates have a deterministic external signal; only `E2E walked manually` is purely human. The auto-update engine MUST never auto-mark the human-driven gate — that's the contract. The engine is "make trackers reflect verifiable reality, not all reality."
- **Hook trigger piggybacks on `git pull main`.** The user already runs `git pull` after every successful ship to get back to clean main. The hook fires on that natural step. No new habit required.

## Journal

- 2026-05-08 [decision] Single user-story child (S000020) bundles engine + hook. Splitting into 2 children (engine, hook) was considered but rejected — they ship together (hook is useless without engine; engine is incomplete without trigger), and a single user-story keeps the dogfood lean.
- 2026-05-08 [decision] Approach B (engine + post-merge hook) chosen over A (engine only, manual habit) and C (engine + /personal-workflow ship wrapper). B satisfies P5 (auto-trigger required) without requiring the user to change /ship habit (C's cost). The "hook only fires on local merge" gap (B's cost) is acceptable for solo workflow.
- 2026-05-08 [decision] `E2E walked manually` is explicit-exclusion from auto-marking. The contract is "engine reflects verifiable reality" — human acknowledgment isn't verifiable from external state. User can hand-edit the gate or invoke a separate `--mark-e2e` flag in v2 if needed.
- 2026-05-08 [decision] Web UI / cross-machine merge gap is accepted. Hook only fires for local `git pull` after merge. If user merges via GitHub web UI from another machine, they can run `/personal-workflow check --update <dir>` manually from their main machine after pulling. Documented in CLAUDE.md.
- 2026-05-08 [gates-update] Phase 3: /ship — PR #69,/land-and-deploy — PR merged,PRs section: linked PR #69 (MERGED).
- 2026-05-08 [gates-update] Phase 3: Smoke tests pass — all checks green on PR #69.
