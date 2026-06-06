---
name: "Single-bundle layout + git-checkout install (skills-deploy install --bundle)"
type: user-story
id: "S000086"
status: active
created: "2026-06-05"
updated: "2026-06-05"
parent: "F000049"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260605-181820-91748"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker (F000049) + S000085 (the `_cj-shared` deposit this builds on)
2. Use the parent's working branch (ship in the same PR): `cj-feat-20260605-181820-91748`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours S2 design (`.gstack/gstack-s2-bundle-install-design-20260605.md`, which resolves O1)
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. Atomic story — no child-task decomposition

**Gates:**
- [x] /office-hours design referenced (the S2 design doc, capturing the O1 resolution)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement per the SPEC architecture: `skills-deploy install --bundle` — ensure a managed git checkout + delegate the install INTO it + stamp the manifest
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests`)
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
3. Walk E2E manually — the hermetic `--bundle` install (clone a checkout, assert install==clone)
4. Ensure all child tasks (if any) have shipped — N/A (atomic)
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] `skills-deploy install --bundle [path]` ensures a managed git checkout of the workbench at the bundle path (default `~/.claude/skills/cj-workbench`)
- [x] The flat `/CJ_*` skill dirs symlink INTO the bundle checkout (install == clone)
- [x] The manifest records the install==clone receipt: `install_mode: bundle`, `bundle_path`, `bundle_commit`, and `source` = the bundle
- [x] Additive: the default `skills-deploy install` (no `--bundle`) is unchanged — it still symlinks to the dev clone and writes no bundle marker
- [x] The bundle bootstraps offline from a local clone source (`SKILLS_DEPLOY_BUNDLE_SOURCE` → manifest `.source` → `upstream_url`); a hermetic test proves install==clone with no network

## Todos

- [x] Decide O1: Claude Code discovers skills from flat `~/.claude/skills/<name>/`; gstack flat-exports each via a symlink into its bundle checkout — the CJ_ family is already ~90% there
- [x] Add `skills-deploy install --bundle` (ensure managed checkout → delegate to the bundle's own install → stamp the manifest)
- [x] Env hooks `SKILLS_DEPLOY_BUNDLE_TARGET` / `SKILLS_DEPLOY_BUNDLE_SOURCE` for path + clone-source override (tests/offline)
- [x] Add the S000086 hermetic test (install==clone + the additive guarantee)
- [ ] (S3) make the bundle the dev checkout (develop-in-place) + retire the external clone / `.source` / worktree flow
- [ ] (S4) flip `--bundle` to the default + drop legacy; (S5) Windows copy-mode parity + CI + update-check on the in-place checkout

## Log

- 2026-06-05: Created + implemented. S2 of F000049 — the single-bundle layout + git-checkout install. O1 resolved empirically from the gstack reference bundle. Built `skills-deploy install --bundle` (additive, opt-in, legacy untouched). `validate.sh` + `scripts/test.sh` green; shellcheck clean.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `scripts/skills-deploy` — new `do_bundle_install` + the `--bundle` flag short-circuit in `do_install` + usage note (ensure managed checkout → delegate → stamp manifest with the install==clone receipt)
- `scripts/test.sh` — S000086 hermetic test (install==clone + the default-install-untouched additive guarantee)
- `.gstack/gstack-s2-bundle-install-design-20260605.md` — the S2 /office-hours design (O1 resolution + the approach)

## Insights

O1 was not a blocker — the gstack bundle is the reference implementation: `~/.claude/skills/gstack/` is a git checkout, and each user-facing skill is flat-exported (`~/.claude/skills/office-hours/SKILL.md` → symlink into the bundle). The CJ_ family is ALREADY ~90% this shape (flat symlink dirs, just pointing at the external dev clone). So `--bundle` is small: **delegate to the bundle's OWN `skills-deploy install`** — its `REPO_ROOT` auto-resolves to the bundle, so the existing per-file-symlink install symlinks INTO the bundle with zero new discovery logic. The only new code is ensure-the-checkout + the manifest stamp.

## Journal

- 2026-06-05T18:20:00Z [decision] Operator chose "Build S2 now (flagged)" — additive opt-in `--bundle` mode, legacy install untouched, PR-stop. The eventual flip-to-default + develop-in-place + retiring the external clone are S3/S4; Windows parity is S5.
- 2026-06-05T18:25:00Z [finding] O1 resolved by inspecting the live gstack bundle: Claude Code discovers `~/.claude/skills/<name>/SKILL.md` (flat); gstack flat-exports each skill via a symlink into its `~/.claude/skills/gstack/` git checkout. The CJ_ family already installs as flat symlink dirs — so install==clone needs only a managed-checkout target + repointed symlinks, achieved by delegating to the bundle's own install.
