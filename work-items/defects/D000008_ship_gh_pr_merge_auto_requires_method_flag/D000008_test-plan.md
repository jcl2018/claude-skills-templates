---
type: test-plan
parent: D000008
title: "/ship + /land-and-deploy: gh pr merge --auto silently fails without a merge method flag — Test Plan"
date: 2026-04-17
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Local fix only (this repo). Upstream gstack fix is filed separately.

- ADD `## CI/CD merge convention` section to `CLAUDE.md` documenting the right `gh pr merge` invocation for /ship and /land-and-deploy in this repo (combine `--auto --squash --delete-branch`)
- ADD worktree-aware cleanup note (delete remote branch via `gh api` when `--delete-branch` fails in worktrees)
- ADD regression test in `scripts/test.sh` ("Regression test (D000008)") that asserts CLAUDE.md still has the merge-convention section so future edits don't silently drop the guard

No skill code changes. No template changes. No upstream gstack changes (out of scope for this PR).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | CLAUDE.md has the new merge-convention section | Asserted by test.sh D000008 block: `grep -q "^## CI/CD merge convention" CLAUDE.md` | Match found | Pass |
| 2 | CLAUDE.md mentions the explicit `--squash` requirement | Asserted by test.sh D000008 block: `grep -qE 'gh pr merge.*--auto.*--squash' CLAUDE.md` | Match found | Pass |
| 3 | CLAUDE.md mentions the worktree `gh api` workaround | Asserted by test.sh D000008 block: `grep -qE 'gh api .*-X DELETE.*git/refs/heads' CLAUDE.md` | Match found | Pass |
| 4 | scripts/test.sh has D000008 regression block | `grep -qE "Regression test \(D000008\)" scripts/test.sh` | Match found | Pass |
| 5 | scripts/validate.sh PASS post-edit | `./scripts/validate.sh` | 0 errors / 0 warnings | Pass |
| 6 | scripts/test.sh PASS post-edit (incl. new D000008 block) | `./scripts/test.sh` | 0 failures, 3 new D000008 checks all OK | Pass |
| 7 | Live verification: next /ship run uses correct invocation | When this defect ships via `/ship`, the LLM reads CLAUDE.md first and uses `gh pr merge --auto --squash --delete-branch` directly (no help-text fallback), AND uses `gh api -X DELETE` for remote-branch cleanup (no local-checkout failure stderr). Observable in the /ship transcript. | Single clean merge command, no fall-back, no local-checkout error | Pending (will verify when D000008 ships) |
| 8 | D000008 work item passes /personal-workflow check under template-derived rules | Apply check.md flow to D000008/* (read template-derived rules, compare to instance) | All 3 docs pass: 9/9 frontmatter keys, 8/8 sections in expected order, 3 phases present, 11/11 checkboxes (template count) | Pass |

## Verification Steps

- [x] `./scripts/validate.sh` PASS (0 errors / 0 warnings)
- [x] `./scripts/test.sh` PASS (0 failures, 3 new D000008 regression checks green)
- [x] Re-read `CLAUDE.md` after the edit; section is scoped to "this repo," gives the exact command (`gh pr merge <PR#> --auto --squash --delete-branch`), explains why `--auto` alone fails, gives the worktree `gh api` workaround with rationale
- [x] D000008 docs structurally compliant: 9/9 frontmatter keys match template, 8/8 sections in expected order, 3 phases present (Track/Implement/Ship), 11/11 checkboxes match template count
- [ ] (Live) When this defect ships via `/ship`: confirm the LLM uses `gh pr merge --auto --squash --delete-branch` directly. Confirm `gh api -X DELETE` is used for the remote-branch cleanup. Both observable in the /ship transcript — this is the proof the local guard works.
- [ ] CHANGELOG entry under the new version cites D000008 and explains the new repo merge convention (deferred to `/ship`)
- [ ] Upstream gstack issue/PR URL captured in this defect's PRs section once filed (out of scope for this PR — local guard ships first as defense-in-depth)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 | branch `claude/nostalgic-volhard` (CLAUDE.md + test.sh edits) | Pass |
| Live /ship run for D000008 | next ship | Pending (will verify in real time) |
