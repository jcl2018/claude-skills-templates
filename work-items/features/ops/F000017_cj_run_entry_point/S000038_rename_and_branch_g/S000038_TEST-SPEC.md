---
type: test-spec
parent: S000038
feature: F000017
title: "Rename + Branch(g) — Test Specification"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
spec: S000038_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `validate.sh` passes after rename | catalog, manifest, file paths all aligned post-rename | `./scripts/validate.sh` |
| S2 | core | AC-1 | `rules/skill-routing.md` has /CJ_run, not /CJ_ship-feature | routing migrated; no stale entries | `grep -c 'CJ_run' rules/skill-routing.md && ! grep -q 'CJ_ship-feature\|CJ_personal-pipeline' rules/skill-routing.md` |
| S3 | core | AC-3 | Branch(g) handles missing work-items/ dir | empty-state guidance printed instead of crash | `cd /tmp/empty-repo && /CJ_run` (mock) |
| S4 | resilience | AC-8 | bash 3.2 compat: Branch(g) uses `while IFS= read` loop (not bash-4 `mapfile`) | macOS users don't hit bash-4 errors | `awk '/^\`\`\`bash$/,/^\`\`\`$/' skills/CJ_run/run.md \| grep -vE "^\s*#" \| grep -qE "^\s*mapfile\s+-\|^\s*readarray\s+-" && exit 1; awk '/^\`\`\`bash$/,/^\`\`\`$/' skills/CJ_run/run.md \| grep -q "while IFS= read"` |
| S5 | observability | AC-6 | Telemetry log path is `CJ_run.jsonl` | post-rename invocations write to fresh log | `grep -q 'CJ_run.jsonl' skills/CJ_run/run.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2 | Single in-progress story → auto-resume | 1) On branch with 1 work-item where Phase 1 done, Phase 2 impl-gate `[ ]`. 2) Run `/CJ_run` with no args. | Branch(g) detects the candidate, dispatches to Branch(f), pipeline resumes from impl phase | User sees the impl dispatch start without passing a path |
| E2 | core | AC-3 | No work-items/ directory → graceful exit | 1) Fresh repo or branch with no work-items/. 2) Run `/CJ_run`. | Message: "No work-items/ found. Run /office-hours or /CJ_scaffold-work-item first." Exit 0. | No error trace; user knows what to do next |
| E3 | core | AC-4 | Multiple in-progress stories → AUQ pick | 1) Branch with 2 in-progress stories. 2) Run `/CJ_run`. 3) Pick one via AUQ. | AUQ enumerates both, user picks one, pipeline resumes for that story | The non-picked story is untouched |
| E4 | usability | AC-5 | Routing no longer suggests /CJ_personal-pipeline | 1) Read CLAUDE.md or test routing in a session. | `/CJ_run` is the routed command; `/CJ_personal-pipeline` is not surfaced | Routing rules match the design |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Defect/task TRACKER in Branch(g) scan | v0.2 scope is user-story only | Defect/task work-items not auto-resumed via no-arg; user passes path explicitly |
| Multi-branch scan (work-items from another git branch) | Out of scope; current worktree state is the truth | A user on the wrong branch might not see their items; switch branches first |
| Performance with hundreds of work-items | Realistic load is dozens; no need to optimize | If repo grows beyond hundreds, Branch(g) scan slows linearly (acceptable) |
| `/CJ_ship-feature` direct callers (scripts, aliases) | No shim by decision; break is intentional | Direct callers break loudly; users update |
