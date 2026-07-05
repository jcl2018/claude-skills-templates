---
name: "The git ls-remote version-notification is inert against the real upstream: releases are never tagged vX.Y.Z, so scripts/skills-update-check reads origin's newest v-tag (frozen at v1.1.0) and computes remote < local (6.0.119) forever — the SKILLS_UPGRADE_AVAILABLE nudge can never fire on any consumer machine even though VERSION has advanced. The land flow bumps VERSION+CHANGELOG but never creates/pushes a git tag."
type: defect
id: "D000042"
status: active
created: "2026-07-05"
updated: "2026-07-05"
repo: "E:/projects/claude-skills-templates"
branch: "cj-def-20260705-101333-1358"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/the_git_ls_remote_version_notification_is_inert_ag
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: cj-def-20260705-101333-1358
3. Required docs scaffolded (D000042 RCA + test-plan)
4. Root cause confirmed (Iron-Law gate passed — status DONE)

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (branch field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Fix written directly to source (new `scripts/tag-release.sh` + fail-soft wiring in `scripts/post-land-sync.sh`)
2. Regression test added (`tests/tag-release.test.sh`, hermetic) + wired into `scripts/test.sh` + registered in `spec/test-spec-custom.md`
3. Fix + work-item artifacts committed (pre-doc-sync commit, Step 8.4)
4. RCA updated with the final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. /CJ_qa-work-item — verify the test-plan rows
2. Deterministic doc-regen — doc-sync
3. /ship — open the fix PR
4. /land-and-deploy — merge + verify

**Gates:**
- [x] /CJ_personal-workflow check — validation passed
- [x] Test-plan verified (regression scenarios passing)
- [ ] /ship — PR created
- [ ] /land-and-deploy — merged and deployed

## Reproduction Steps

`git ls-remote --tags https://github.com/jcl2018/claude-skills-templates 'v*'`
returns ONLY `v1.1.0` while `VERSION` is `6.0.119`. `scripts/skills-update-check`
`remote_max_tag()` reads the max published `v<X.Y.Z>` tag via `git ls-remote --tags`,
and `cmd_default` compares it to the manifest `collection_version`, nudging only when
the remote is strictly newer. Since the newest origin tag is permanently below local,
`version_gte(remote, local)` is false and the `SKILLS_UPGRADE_AVAILABLE` banner is
never emitted on any consumer machine. `validate.sh` Error check 8 only guards VERSION
from regressing below the latest LOCAL tag, so nothing forces a tag per release.

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy (or manual squash-merge)
- [ ] OPERATIONAL BACKFILL (out of scope for the code fix; operator-gated): push a real
      `v6.0.119` tag to origin so the nudge starts working immediately. From the next land
      onward `scripts/tag-release.sh` keeps it current automatically.
- [ ] Follow-on (deferred): the F000082 live `git ls-remote` portability smoke that would
      catch this class per-PR/nightly (TODOS.md F000082 follow-up (c)).

## Log

- 2026-07-05: Confirmed origin's newest v-tag is `v1.1.0` vs VERSION 6.0.119; root cause is a MISSING producer (no tag on release), not a consumer bug. Fix = new `scripts/tag-release.sh` invoked fail-soft from `post-land-sync.sh` at land; per-PR gate deliberately avoided (VERSION is bumped in the PR before the tag exists at land). Domain defaulted to 'uncategorized'.

## PRs

<!-- populated at /ship -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns; see the D000042 RCA. -->

## Journal
- 2026-07-05T00:00:00Z [auto-scaffolded] /CJ_goal_defect captured the bug, /investigate confirmed the root cause (origin frozen at v1.1.0; no tag-on-release producer) and wrote the fix directly to source, then promoted the draft to D000042.
- 2026-07-05 [qa-fix] Boundary check found the hand-written RCA + test-plan drifted from doc-RCA.md / doc-test-plan.md (RCA: `## Reproduction`→`## Reproduction Steps`, `## Fix`→`## Fix Description`, missing `## Regression Risk`, frontmatter missing parent/author/severity/status; test-plan: `## Regression Tests`→`## Regression Test Cases`, missing `## Scope`/`## Verification Steps`/`## Environments Tested`, frontmatter missing parent/author/status). Restructured both to template shape (all real content preserved — Prevention/Evidence/Out-of-Scope folded into Regression Risk; Coverage Cross-Check/Gaps folded into Verification Steps/Environments Tested). Re-check clean: all required sections + frontmatter keys present, no placeholders.
- 2026-07-05 [qa-smoke] R1 (tag publish when absent): green — `bash tests/tag-release.test.sh` assert #3 published v<VERSION> to the hermetic bare origin; RESULT: PASS.
- 2026-07-05 [qa-smoke] R2 (idempotent no-op): green — assert #4: second run exit 0, origin tag unchanged.
- 2026-07-05 [qa-smoke] R3 (fail-soft push failure): green — asserts #8/#9: `--strict`→rc 2, default→WARN+exit 0 (never halts a land).
- 2026-07-05 [qa-smoke] R4 (bad invocation guarded): green — assert #7: non-semver VERSION→exit 1, nothing pushed.
- 2026-07-05 [qa-smoke] R5 (post-land-sync surfaces + invokes): green — `bash scripts/post-land-sync.sh --dry-run` prints the `would run: …/tag-release.sh (publish v<VERSION> to origin if absent)` plan line.
- 2026-07-05 [qa-smoke-summary] green: 5/5 non-manual test-plan rows green (0 manual). Whole `tests/tag-release.test.sh` suite RESULT: PASS (9/9 asserts, hermetic, no network).
- 2026-07-05 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none-new(test-tag-release already registered; --validate OK, --check-coverage findings=0),doc-spec-custom:none (Step 8.6a/8.6b: deterministic new-surface rows verified inline; the agent-judged amendment sweep SKIPPED via DEFER_SYNC + 8.6c/8.6d SKIPPED via DEFER_AUDIT — the agentic doc/test sync + audit run on-demand off the build path).
- 2026-07-05 [qa-pass] D000042 (defect): green smoke from test-plan rows (5 rows). No qa-owned Phase 2 gates per template; Phase 3 `/CJ_personal-workflow check — validation passed` + `Test-plan verified (regression scenarios passing)` gates transitioned on green QA + repaired-compliant artifacts.
