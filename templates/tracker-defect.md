---
name: "{DEFECT_NAME}"
type: defect
id: "{DEFECT_ID}"
status: active
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
repo: "{REPO_PATH}"
branch: "{BRANCH_NAME}"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/{slug}`
3. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
4. Log initial symptoms and hypotheses

**Gates:**
- [ ] Reproduction steps documented
- [ ] Working branch created (`branch` field populated)
- [ ] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Implement fix based on root cause analysis
2. Write regression test covering the defect scenario
3. Commit fix and test together
4. Update RCA doc with final root cause

**Gates:**
- [ ] Fix committed with regression test
- [ ] RCA doc updated
- [ ] Todos section reflects remaining work (no stale items)

### Phase 3: Review

1. Run `/docs check` — verify no regressions
2. Run tests: `./scripts/test.sh` — regression test passes
3. Run `/review` for code review

❌ If regression test fails: investigate further

**Gates:**
- [ ] `/docs check` — validation passed
- [ ] Regression test passing
- [ ] Test verification passed
- [ ] `/review` — code review passed

### Phase 4: Ship

1. Run `/ship` — creates fix PR
2. Run `/land-and-deploy` — merges and verifies fix in production

❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

<!-- Steps to reproduce the defect. Include environment details. -->

1. {step}

## Todos

<!-- Actionable items for this defect fix. -->

- [ ] {todo}

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- {YYYY-MM-DD}: Created. {brief defect description}

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

## Insights

<!-- Root cause analysis, patterns discovered, related defects. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
