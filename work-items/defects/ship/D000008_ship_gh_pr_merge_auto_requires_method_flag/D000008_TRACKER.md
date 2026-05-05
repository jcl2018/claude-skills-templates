---
name: "/ship + /land-and-deploy: gh pr merge --auto silently fails without a merge method flag"
type: defect
id: "D000008"
status: active
created: "2026-04-17"
updated: "2026-04-17"
repo: "jcl2018/claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/ship-gh-pr-merge-auto-method-flag`
3. Scaffold required docs:
   - `D000008_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000008_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented (recurred 2x in this session)
- [ ] Working branch created (`branch` field populated — currently on shared `claude/nostalgic-volhard`)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (gh CLI requires explicit merge method when `--auto` is used)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed (CLAUDE.md merge-convention section + scripts/test.sh D000008 regression block; commit pending `/ship`)
- [x] RCA doc updated (Fix Description matches what shipped; commit SHA populated by `/ship`)
- [x] Todos section reflects remaining work (no stale items — upstream gstack PR is documented as out-of-scope follow-up)

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

The defect is in the **gstack `/ship` and `/land-and-deploy` skill workflows** (not in this repo's code), but it affects every release this repo does. The fix is partially upstream (gstack) and partially local (a CLAUDE.md guard / wrapper script).

### Symptom

When the LLM follows /ship's Step 4 ("Try auto-merge first") or /land-and-deploy's Step 4 verbatim:

```bash
gh pr merge --auto --delete-branch
```

The gh CLI does NOT enable auto-merge. It prints its **help text** to stdout (because `--auto` requires an explicit merge method) and exits 0. The LLM thinks the merge succeeded (exit 0), but no merge happened. On detection (next `gh pr view --json state` returns `OPEN` instead of `MERGED`), the LLM falls back to `gh pr merge --squash --delete-branch` which works.

The fall-back path also has a known follow-on issue: `--delete-branch` does a local `git checkout` of the base branch to do the cleanup, which fails in worktrees where `main` is checked out elsewhere ("error: 'main' is already checked out at..."), forcing a `gh api -X DELETE refs/heads/...` workaround.

### Recurrence

This session shipped 2 PRs back-to-back; the auto-merge silent-failure happened on **both**:

1. **PR #32 (D000006, v0.7.2)** ship at 2026-04-17T03:38Z — `gh pr merge --auto --delete-branch` returned help text; fell back to `--squash`; remote-branch-delete via `gh api`
2. **PR #35 (D000007, v0.9.0)** ship at 2026-04-17T04:33Z — same exact pattern

Both /land-and-deploy reports flagged the quirk in the closing summary. Two recurrences in one session is a learnings trigger.

### Reproduction (clean)

1. From a feature branch with an open PR on this repo:
   ```bash
   gh pr merge --auto --delete-branch
   ```
2. **Observe:** stdout begins with `-m, --merge ...` (gh's help text). Exit code is 0.
3. `gh pr view --json state -q .state` → still `OPEN`. No merge happened.
4. With explicit method:
   ```bash
   gh pr merge --auto --squash --delete-branch
   ```
   → succeeds (auto-merge enabled, or merges immediately if checks already pass).

**Environment:** macOS Darwin 25.3.0; gh CLI (latest from Homebrew); GitHub repo without a default merge method configured at the org level. Reproducible deterministically.

## Todos

### Local fixes (this repo)

- [x] Added `## CI/CD merge convention` section to `CLAUDE.md` (between Skill routing and Work item templates). Documents: this repo uses squash merges; the correct `gh pr merge` invocation is `gh pr merge <PR#> --auto --squash --delete-branch` (combined `--auto` AND `--squash`); cites D000008 for the upstream gstack fix rationale.
- [x] Added regression test block in `scripts/test.sh` ("Regression test (D000008)") with 3 checks: section header present, `--auto --squash` combined invocation present, `gh api -X DELETE git/refs/heads` workaround present. Greps anchor on key tokens so trivial reword is OK but full removal trips the test.

### Worktree-aware cleanup follow-up

- [x] Folded into the same CLAUDE.md section: documented that `--delete-branch` does a local `git checkout main` that fails inside a worktree (parent has `main` checked out), and that the workaround is `gh api -X DELETE repos/jcl2018/claude-skills-templates/git/refs/heads/<branch>` after the merge. Both symptoms now have a single source of truth in CLAUDE.md.

### Upstream fix (gstack)

- [ ] File a gstack issue (or PR) against `~/.claude/skills/gstack/ship/SKILL.md` Step 4 + `~/.claude/skills/gstack/land-and-deploy/SKILL.md` Step 4. Recommended fix: change the `--auto` invocation from `gh pr merge --auto --delete-branch` to `gh pr merge --auto --squash --delete-branch` (combine flags), with a comment explaining gh CLI requires the method. The fall-back path's `--delete-branch` worktree issue is also worth a comment (suggest `--delete-branch` only when not in a worktree).
- [ ] Track the upstream issue/PR URL in this defect's PRs section.

### Verification + ship

- [x] Verified D000008 docs against v0.9.0 template-derived rules: tracker frontmatter keys MATCH (9/9), sections MATCH (8/8), 3 phases present, 11/11 checkboxes (template count)
- [x] Regression test passing: all 3 D000008 grep checks OK in `./scripts/test.sh`
- [ ] Update `CHANGELOG.md` and bump skill version per `scripts/collection-version.sh` (deferred to `/ship`)
- [ ] Ship via `/ship` — dogfood the new `--auto --squash` invocation in the same PR (live verification of the fix)

## Log

- 2026-04-17: Created. Both /ship runs in this session (PR #32 v0.7.2 and PR #35 v0.9.0) hit the same quirk: `gh pr merge --auto --delete-branch` printed help text instead of merging; fell back to `gh pr merge --squash --delete-branch`. Plus on both, `--delete-branch` failed locally because `main` is checked out in the parent worktree, requiring `gh api -X DELETE refs/heads/...` for the remote-branch cleanup. Two recurrences in one session triggers this defect entry.
- 2026-04-17: Implemented local fix. Edited `CLAUDE.md` to add a `## CI/CD merge convention` section between Skill routing and Work item templates — documents the correct `gh pr merge <PR#> --auto --squash --delete-branch` invocation, explains why `--auto` alone fails, and gives the `gh api -X DELETE git/refs/heads/...` workaround for worktree-aware remote-branch cleanup. Edited `scripts/test.sh` to add a "Regression test (D000008)" block with 3 grep checks (section header, combined `--auto --squash`, `gh api -X DELETE` workaround). Verifications: `validate.sh` PASS (0/0), `test.sh` PASS (0 failures, all D000005/006/007/008 regression blocks green). Upstream gstack PR is documented as out-of-scope follow-up — local guard is in place regardless.

## PRs

## Files

- `CLAUDE.md` — new `## CI/CD merge convention` section (local guard so future /ship runs in this repo use the right invocation)
- `scripts/test.sh` — new "Regression test (D000008)" block
- (upstream, not in this repo) `~/.claude/skills/gstack/ship/SKILL.md` Step 4
- (upstream, not in this repo) `~/.claude/skills/gstack/land-and-deploy/SKILL.md` Step 4

## Insights

The root cause is gh CLI's documented behavior: `--auto` requires an explicit merge method (`--merge`, `--squash`, or `--rebase`) unless the repo has a default configured at the org level. Without a method, gh prints help and exits 0 — silent failure as far as exit status is concerned, which is what makes this trip up automation.

The /ship and /land-and-deploy skill workflows in gstack instruct: "Try auto-merge first: `gh pr merge --auto --delete-branch`. If `--auto` is not available... merge directly: `gh pr merge --squash --delete-branch`." The intent is correct (prefer auto-merge to respect repo settings + merge queues), but the invocation is broken. The fix is to combine `--auto` AND `--squash` (or whichever method) in the first command — gh's `--auto` flag does NOT mean "use the repo default method," it means "queue for auto-merge once required checks pass." The method is still mandatory.

Two related issues surface together for this repo:
1. The `--auto` silent-failure (the primary defect — affects every gstack-driven repo, fix lives upstream).
2. The worktree-aware `--delete-branch` failure (specific to repos that use git worktrees — also upstream-fixable but workaround is local-script-friendly).

Both are skill-workflow-level defects, not application code defects. The local fix in this repo (a CLAUDE.md note) is a defense-in-depth measure: even if gstack ships an upstream fix, our CLAUDE.md guard ensures the LLM in this repo always picks the right invocation regardless of which gstack version is installed.

**Cross-reference:**
- Related to /ship + /land-and-deploy operational behavior; not a code defect in this repo's skill set
- Independent of D000003-D000007 (those were all about the personal-workflow / company-workflow skills shipped from this repo)

## Journal
