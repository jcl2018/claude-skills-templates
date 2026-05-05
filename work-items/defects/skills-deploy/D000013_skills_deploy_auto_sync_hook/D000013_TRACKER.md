---
name: "skills-deploy: post-merge hook auto-syncs ~/.claude on workbench pull (closes D000012's Option C2)"
type: defect
id: "D000013"
status: active
created: "2026-05-01"
updated: "2026-05-01"
repo: "jcl2018/claude-skills-templates"
branch: "fix/skills-deploy-auto-sync-hook"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/skills-deploy-auto-sync-hook`
3. Scaffold required docs:
   - `D000013_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000013_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (drift mechanism = no auto-refresh trigger between workbench source and `~/.claude/templates/`; resolved via post-merge hook)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/{slug}/`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. On a fresh workbench checkout, run `scripts/setup-hooks.sh` (existing convention: per-machine bootstrap that writes hooks to `.git/hooks/`).
2. Edit any template (e.g. `templates/personal-workflow/tracker-feature.md`), commit, merge to `main`, push.
3. From a second machine, `git pull` the workbench.
4. **Pre-fix observation:** `~/.claude/templates/personal-workflow/tracker-feature.md` does NOT update. The workbench source is current, but the deployed copy lags until someone manually re-runs `scripts/skills-deploy install --overwrite`. This is the systemic mechanism documented in D000012.
5. **Post-fix expectation:** the post-merge hook detects the changed template file in `git diff-tree ORIG_HEAD HEAD`, runs `scripts/skills-deploy install --overwrite`, and `~/.claude/templates/` is byte-current before the user's next skill invocation.

**Environment:** workbench at v1.1.1 (D000012 closed in #49). `setup-hooks.sh` currently installs only a `pre-commit` hook; no `post-merge` or `post-checkout` hook exists.

## Todos

**In scope (this PR — narrow):**

- [x] Extend `scripts/setup-hooks.sh` to also write a `post-merge` hook (per-machine, untracked, matches existing pre-commit convention)
- [x] Hook content: filter `git diff-tree ORIG_HEAD HEAD` for changes under `templates/`, `skills/`, `skills-catalog.json`, or `rules/`; if any match, run `scripts/skills-deploy install --overwrite`. Silent no-op when nothing relevant changed.
- [x] Re-run `scripts/setup-hooks.sh` on this machine to install the new hook
- [x] Add D000013 regression block to `scripts/test.sh` verifying `setup-hooks.sh` writes a post-merge hook that invokes `skills-deploy install --overwrite`
- [x] Update D000012's TRACKER "out of scope" to mark Option C2 as shipped here

**Out of scope (follow-up if still needed):**

- [ ] **Post-checkout hook** — branch switches that bring in template changes won't trigger post-merge. Less common workflow on the workbench (maintainer is on `main` most of the time); revisit if drift becomes visible across branches.
- [ ] **Deployed-extra detection** — D000012's drift block iterates over workbench templates only. Stale templates (removed from workbench, lingering in `~/.claude/`) still slip through. Same mechanism could clean them up; deferred.
- [ ] **WORKFLOW.md type-to-artifact tables** — `skills/personal-workflow/WORKFLOW.md` lines 19-25 and 62-67 still say "Feature: tracker + milestones (2 artifacts)" (deferred since D000009; not validator-breaking).

## Log

- 2026-05-01: Created. D000012 (closed in v1.1.1) added a regression check that catches deploy drift but doesn't prevent it — the dev still has to manually re-run `skills-deploy install --overwrite` after every workbench pull. The user's framing ("deploy as a sync-up for this machine, so templates should be ready") points at C2 from D000012's RCA: a post-merge git hook that auto-runs the deploy whenever a pull brings in template/skill/catalog changes. Filing as a follow-up defect to track the implementation.

## PRs

## Files

- `scripts/setup-hooks.sh` — extended to also install a `post-merge` hook (heredoc, same style as the existing `pre-commit` hook)
- `scripts/test.sh` — D000013 regression block verifying `setup-hooks.sh` emits a post-merge hook that runs `skills-deploy install --overwrite`
- `.git/hooks/post-merge` — installed per-machine via re-running `setup-hooks.sh` (untracked)
- `work-items/defects/D000012_personal_workflow_template_deploy_drift/D000012_TRACKER.md` — out-of-scope item updated to mark C2 done

## Insights

<!-- Initial observation: D000012 implemented Option B (regression check) and explicitly deferred C as a "design call." User picked C2 (post-merge hook) over C1 (symlink the templates dir) with the framing that deploy should be the per-machine sync-up — templates ready, not "go fetch them." Matches the existing repo convention: hooks are written per-machine by `setup-hooks.sh`, not committed; setup is a one-time bootstrap step on each clone. The post-merge hook is the second hook installed by setup-hooks.sh, slotting in next to the existing pre-commit hook. The hook runs `skills-deploy install --overwrite` only when relevant files changed (template/skill/catalog/rules), so a normal code-only pull stays silent. -->

## Journal
