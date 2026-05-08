---
name: "test-deploy.sh stale doc-RCA.md template references"
type: defect
id: "D000016"
status: active
created: "2026-05-08"
updated: "2026-05-08"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "fix/test-deploy-stale-templates"
blocked_by: ""
---

<!-- Source design (lake-boil approach C):
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-fix-test-deploy-stale-templates-design-20260508-142011.md
     Closes both P2 (template-ownership test failures) and P3 (wire test-deploy.sh into CI)
     TODOs in TODOS.md. -->

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/test-deploy-stale-templates`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented (see Reproduction Steps section)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (template moved subfolders in v1.3.x; references in test-deploy.sh never updated; CI never invoked test-deploy.sh so failure was invisible)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-fix-test-deploy-stale-templates-design-20260508-142011.md`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix applied (22 doc-RCA.md → doc-SKILL-DESIGN.md re-points in test-deploy.sh; 3 of those were `templates/personal-workflow/doc-RCA.md` → `templates/doc-SKILL-DESIGN.md` source-path edits)
- [x] CI wire-up applied (test-deploy.sh invocation added to scripts/test.sh between manifest schema-parity tests and Summary block)
- [x] RCA doc populated at scaffold time (Investigation Trail + Root Cause + Fix Description all complete)
- [x] Todos section reflects remaining work (no stale items)
- [x] Verified: `./scripts/test-deploy.sh` exits 0; `./scripts/test.sh` exits 0 with new test-deploy.sh phase visible
- [x] Negative test: temporarily reintroduced one stale reference → test.sh failed loudly with named failure → restored → test.sh PASS again. The wire-up catches future regressions of this exact shape.

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

1. Clone repo at v1.7.0 or any version since v1.3.x.
2. Run `./scripts/test-deploy.sh` end-to-end (NOT `./scripts/test.sh` — that one only greps test-deploy.sh, doesn't execute it).
3. **Observe:** test cases T2, T4, T5, T6, T7 fail with errors related to `doc-RCA.md` not being found at the top-level templates path.

**Environment:** macOS 25.3.0 (Darwin), bash 5.x, jq + git toolchain. Reproduces on any platform with that toolchain.

## Todos

- [x] Replace 22 references to `doc-RCA.md` in `scripts/test-deploy.sh` with `doc-SKILL-DESIGN.md` (single-Edit replace_all)
- [x] Modify `scripts/test.sh` to invoke `scripts/test-deploy.sh` end-to-end after the existing wrapper-grep pre-flight check
- [x] Verify locally: `./scripts/test-deploy.sh` exits 0 (8 tests pass: T1, T2, T3, T4, T5, T6, T7, T8); `./scripts/test.sh` exits 0 with test-deploy.sh phase visible in output
- [x] Negative test: revert one edit → test.sh FAIL with named failure → restore → test.sh PASS
- [ ] Audit other potential stale references in test-deploy.sh: `grep -E 'templates/[^/]*\.md' scripts/test-deploy.sh` — DEFERRED, low priority (no failures observed in current end-to-end run)
- [ ] Mark "Pre-existing template-ownership test failures in test-deploy.sh (P2, S)" as **Completed** in TODOS.md (will close after this commit)
- [ ] Mark "Wire test-deploy.sh into CI / test.sh (P3, S)" as **Completed** in TODOS.md (will close after this commit)

## Log

- 2026-05-08: Created. test-deploy.sh tests T2/T4-T7 fail because doc-RCA.md was subfoldered to templates/personal-workflow/doc-RCA.md in v1.3.x and references in test-deploy.sh were never updated. CI never caught it because scripts/test.sh doesn't invoke test-deploy.sh. Approach C from /office-hours: re-point references AND wire test-deploy.sh into CI to prevent recurrence.
- 2026-05-08: Implemented. Two Edits in test-deploy.sh (replace_all=true): first the specific `templates/personal-workflow/doc-RCA.md` → `templates/doc-SKILL-DESIGN.md` (3 occurrences at lines 794, 808, 816), then the bare `doc-RCA.md` → `doc-SKILL-DESIGN.md` (19 remaining occurrences). One Edit in test.sh: added test-deploy.sh invocation block between the T11 manifest schema-parity tests and the Summary block. End-to-end verification: test-deploy.sh PASS (8/8); test.sh PASS with new phase visible. Negative test confirmed wire-up catches future regressions.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `scripts/test-deploy.sh` (modified — 5+ doc-RCA.md → doc-SKILL-DESIGN.md re-points)
- `scripts/test.sh` (modified — added invocation of test-deploy.sh after wrapper-grep check)
- `TODOS.md` (modified — both linked TODOs moved to Completed section)

## Insights

- **CI invisibility is the meta-bug.** The literal symptom was 5 stale references; the underlying cause was that test-deploy.sh was never wired into CI, so any future template move would produce the same silent failure. Approach C closes the meta-bug, not just the symptom.
- **doc-SKILL-DESIGN.md is the only remaining flat template.** Once it became the lone top-level template, it was the unambiguous replacement target for the test fixtures. If a future PR moves it into a subfolder too, test-deploy.sh tests will need to grow a synthetic test-only template instead.
- **Boil the lake worked here.** Original TODO scope (re-point only) would have left the latent CI gap. Lake-boil scope (re-point + wire-into-CI) closes both TODOs in one PR with marginal extra effort (~30 min more human / ~10 min more CC).

## Journal

- 2026-05-08 [decision] Picked Approach C from /office-hours over A (re-point only) and B (retire tests). Reason: A treats the symptom; B loses real coverage; C closes the underlying CI gap that produced the bug.
- 2026-05-08 [decision] Slug `test_deploy_stale_templates` chosen to match branch name `fix/test-deploy-stale-templates` for grep affinity, even though it under-describes the lake-boil scope (CI wire-up).
- 2026-05-08 [decision] Component `personal-workflow` chosen because skills-deploy primarily manages personal-workflow templates and doc-RCA.md is itself a personal-workflow template. Considered `ops` (CI/scripts layer) but rejected for following existing convention (group by skill/feature, not by tooling layer).
- 2026-05-08 [implementation] Edit strategy: ordered the two replace_all=true edits carefully. First `templates/personal-workflow/doc-RCA.md` → `templates/doc-SKILL-DESIGN.md` (3 occurrences, the source-path references). Then bare `doc-RCA.md` → `doc-SKILL-DESIGN.md` (19 occurrences). Reverse order would have produced wrong path strings (`templates/personal-workflow/doc-SKILL-DESIGN.md`, which doesn't exist). Worth remembering for similar string-overlap edits.
- 2026-05-08 [finding] test.sh wire-up site: the natural insertion point was AFTER the T11 manifest schema-parity tests (around line 1980, just before `set -e`) and BEFORE the Summary block. Keeping the new phase outside the `set +e` ... `set -e` window was deliberate — test-deploy.sh has its own error handling (its `fail_test` function), and we want hard-fail on non-zero exit code in CI.
- 2026-05-08 [decision] One Todo deferred (audit of other stale references in test-deploy.sh). The current end-to-end run shows zero failures, so any remaining stale references are at minimum quiescent (don't cause test failures). If a future template move surfaces them, the wire-up will catch it loudly. Acceptable to defer.
