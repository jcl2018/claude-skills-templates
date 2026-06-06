---
name: "Develop-in-place enablement (bundle-status + origin-repoint)"
type: user-story
id: "S000087"
status: active
created: "2026-06-05"
updated: "2026-06-05"
parent: "F000049"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260605-185939-49060"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker (F000049) + S000086 (the `--bundle` mode this builds on)
2. Use the parent's working branch (ship in the same PR): `cj-feat-20260605-185939-49060`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours S3 design (`.gstack/gstack-s3-develop-in-place-design-20260605.md`)
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. Atomic story — no child-task decomposition

**Gates:**
- [x] /office-hours design referenced (the S3 design doc, with the scope decision)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement per the SPEC architecture: origin-repoint in `do_bundle_install` + the `bundle-status` subcommand + docs
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
3. Walk E2E manually — `--bundle` then push a branch from the bundle
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

- [x] `skills-deploy install --bundle` repoints the bundle's `origin` to the GitHub upstream (`SKILLS_DEPLOY_BUNDLE_UPSTREAM` → manifest `upstream_url`), so you can branch/push/PR FROM the bundle even when it was cloned from a local `.source`
- [x] `skills-deploy bundle-status` reports the develop-in-place checkout state (install_mode, bundle path, branch, origin, dirty)
- [x] `bundle-status` on a non-bundle install reports `dev-clone` (no false install==clone claim)
- [x] Additive: the default `skills-deploy install` and the separate-clone machinery (`.source`, the worktree flow, `post-land-sync`) are untouched — NO rip-out (deferred to S4)
- [x] The develop-in-place flow is documented (usage note + install summary + `bundle-status` hint); `validate.sh` + `scripts/test.sh` green, shellcheck clean

## Todos

- [x] Repoint the bundle's `origin` to the GitHub upstream in `do_bundle_install` (the genuine develop-in-place enabler)
- [x] Add the `bundle-status` read-only subcommand + dispatcher entry + usage
- [x] Add the S000087 hermetic test (origin-repoint + bundle-status, incl. the non-bundle case)
- [x] Document develop-in-place (usage note + install summary + status hint)
- [ ] (S4) retire `.source` + the worktree flow + flip `--bundle` to default; (S5) Windows copy-mode parity

## Log

- 2026-06-05: Created + implemented. S3 of F000049 — develop-in-place enablement. SCOPED: delivers develop-in-place (origin-repoint + bundle-status), DEFERS the `.source`/worktree rip-out to S4 (the dangerous subtractive part). Additive + reversible. `validate.sh` + `scripts/test.sh` green; shellcheck clean.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `scripts/skills-deploy` — `do_bundle_install` origin-repoint (track the GitHub upstream) + the new `do_bundle_status` subcommand + dispatcher/usage
- `scripts/test.sh` — S000087 hermetic test (origin-repoint + bundle-status, incl. the non-bundle dev-clone case)
- `.gstack/gstack-s3-develop-in-place-design-20260605.md` — the S3 /office-hours design (the scope decision)

## Insights

After S2, "develop-in-place" was almost free — the bundle is a git checkout with the flat `/CJ_*` symlinked into it, so editing in the bundle reflects live. The ONE real gap: `--bundle` clones from the LOCAL `.source` (for speed/offline), so the bundle's `origin` was the local clone — you couldn't push/PR to GitHub from it. Repointing `origin` to the upstream is the whole enabler. The scary "retire the separate-clone machinery" half (28 `.source` refs + 15 worktree refs + the running machinery) is deferred to S4 — it's intertwined with dropping `.source`, and ripping it out undesigned in the same PR that USES it would be reckless.

## Journal

- 2026-06-05T18:59:00Z [decision] Operator chose "Build S3 now" after I surfaced that S3 is subtractive/undesigned/retires-the-running-machinery (unlike additive S1/S2). I scoped the build to the SAFE half: deliver develop-in-place (origin-repoint + bundle-status, additive), defer the `.source`/worktree rip-out to S4. Stated explicitly in the design + PR so the scoping isn't a surprise.
- 2026-06-05T19:02:00Z [finding] The genuine develop-in-place blocker was the bundle's `origin`: cloned from a local `.source`, origin pointed at the local clone, so `git push`/PR didn't reach GitHub. Repoint to `upstream_url` fixes it. `bundle-status` surfaces the dev checkout state. Both additive; the separate-clone machinery is untouched.
