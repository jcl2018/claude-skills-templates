---
type: test-plan
parent: T000038
title: "Registered-doc requirements audit for /CJ_document-release (Job 2) — Test Plan"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- Scope: ONE task — the Job 2 registered-doc requirements audit. Cases are
     concrete + reproducible. The deterministic guarantee is producer+surfacing
     WIRING (T1, T2) — the verdict CONTENT is agent-judged (non-deterministic),
     so the live dogfood (T7) is best-effort, not a pass/fail gate. -->

## Scope

The fix adds an advisory "is THIS registered doc up to date against ITS declared requirement?"
audit to `/CJ_document-release`, covering both the 3 tracked-doc/ files AND the active routable
skill MDs. Files modified:

- `skills/CJ_document-release/SKILL.md` — §1 PRODUCER: new advisory Step 6.7 (green-tail of Step 6;
  reads CLAUDE.md tracked-doc manifest `requirement:` lines + jq-enumerated skill `doc_requirement`s,
  agent-judges each registered doc, emits the `### Registered-doc requirements` block to RESULT AND
  writes it to the gitignored scratch file `.cj-goal-feature/registered-doc-verdicts.md`; NEVER halts).
- `skills/CJ_goal_feature/pipeline.md` — §1.5 SURFACING: new post-/ship Step 4.6 (reads the scratch
  file, `gh pr edit <PR#>` to insert/replace `### Registered-doc requirements` under the PR body
  `## Documentation`; idempotent; best-effort).
- `CLAUDE.md` — §2 3 tracked-doc manifest `requirement:` lines + new `## Registered-doc requirements
  audit` convention section + `### Reporting` subsection update + optional `doc_requirement` field doc.
- `skills-catalog.json` — §3 `doc_requirement` on the `CJ_document-release` exemplar entry.
- `doc/ARCHITECTURE.md` — §4 new `## Registered-doc requirements audit (Job 2)` mechanism section.
- `TODOS.md` — §5 Job-2 row struck DONE.
- `scripts/test.sh` — §6 two deterministic smoke checks (producer-wired + surfacing-wired).

Posture: ADVISORY / agent-judged, NEVER a hard gate; NO new hard validate.sh check in v1; NO upstream
gstack `/document-release` or `/ship` modification (only the workbench-owned wrapper + pipeline).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | §6a PRODUCER wired in the wrapper SKILL.md (DETERMINISTIC — primary proof) | `grep -F '### Registered-doc requirements' skills/CJ_document-release/SKILL.md` AND `grep -F "select(.status==\"active\")" skills/CJ_document-release/SKILL.md` (the jq enumeration selector) AND `grep -F '.cj-goal-feature/registered-doc-verdicts.md' skills/CJ_document-release/SKILL.md` (the scratch-file write) | All three grep hits present: the new Step 6.7 audit step contains the literal emit block heading, the jq skill-enumeration selector, and the gitignored scratch-file write path | Pending |
| 2 | §6b SURFACING wired in CJ_goal_feature/pipeline.md (DETERMINISTIC — primary proof) | `grep -F 'gh pr edit' skills/CJ_goal_feature/pipeline.md` (the Step 4.6 PR-body edit) AND `grep -F 'registered-doc-verdicts.md' skills/CJ_goal_feature/pipeline.md` (the scratch-file read) | Both grep hits present: the new Step 4.6 surfacing step reads the scratch file and runs `gh pr edit` to land the section in the PR body. Together T1+T2 prove the FULL producer→PR-body path is wired (the second-adversarial-review requirement) | Pending |
| 3 | §2a CLAUDE.md tracked-doc manifest carries a `requirement:` on all 3 entries | In the CLAUDE.md `### Tracked doc/ files manifest` block, confirm a `requirement:` child line under each of `doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `doc/WORKFLOWS.md`. Confirm the `doc/ARCHITECTURE.md` requirement accepts a SKILL.md-step mechanism (matches "…scripts OR skill steps" / equivalent wording) | 3 `requirement:` lines present; ARCHITECTURE's is worded to accept a SKILL.md-step mechanism (so §4's new section does not self-flag a soft-stale verdict on run 1) | Pending |
| 4 | §2b/§2c/§2d CLAUDE.md convention + reporting + field doc | Confirm a new `## Registered-doc requirements audit` H2 section exists (sibling to `## /document-release workbench audit conventions`); confirm the existing `### Reporting` subsection now names `### Registered-doc requirements` alongside `### Skill-routing drift` + `### Doc/ manifest drift`; confirm the optional `doc_requirement` field + the shared-default skill-MD requirement are documented | New convention section present; `### Reporting` lists the new subheading; `doc_requirement` field + shared default documented | Pending |
| 5 | §3 skills-catalog.json `doc_requirement` on the exemplar + tolerated by validate | `jq -r '.[] \| select(.name=="CJ_document-release") \| .doc_requirement' skills-catalog.json` returns a non-empty string with NO `Step N` token (de-step-numbered, review nit #3); `jq empty skills-catalog.json` succeeds (valid JSON) | `doc_requirement` present on CJ_document-release, no hardcoded step number, JSON valid; validate.sh Check 1/2 GREEN (no closed catalog schema → field tolerated) | Pending |
| 6 | §4 doc/ARCHITECTURE.md mechanism section | `grep -F '## Registered-doc requirements audit (Job 2)' doc/ARCHITECTURE.md` | The new mechanism-reference section is present (F000037-section style), documenting the §1 producer step + the registry-with-requirements | Pending |
| 7 | §5 TODOS.md Job-2 row struck DONE | Confirm the `### Job 2: registered-doc requirements audit for /CJ_document-release` row is now `~~strikethrough~~` with a `DONE — closed by T000038 (vX.Y.Z, PR #NNN)` annotation; re-run `/CJ_suggest` (or scan) and confirm the row is excluded from active candidates | Row struck DONE with the standard completion annotation; `/CJ_suggest` no longer ranks it | Pending |
| 8 | validate.sh GREEN (manifest still parses; catalog field tolerated) | `./scripts/validate.sh; echo "exit=$?"` | `exit=0`, 0 errors. Check 15a still parses the tracked-doc manifest with the new `requirement:` child lines (its `$3`-only `- path:` parser is `requirement:`-safe); Check 1/2 tolerate `doc_requirement`; Check 16 (cj-document-release.json schema) unaffected | Pending |
| 9 | test.sh GREEN incl. the two new smoke checks | `./scripts/test.sh; echo "exit=$?"` | `exit=0`, RESULT: PASS, 0 failures. The two new §6 smoke checks (producer-wired + surfacing-wired) pass; the zzz-test-scaffold integration fixture is UNAFFECTED (no validate.sh Check was added) — but explicitly VERIFY per `project_implement_subagent_blind_spot_test_sh` | Pending |
| 10 | Live dogfood — THIS PR's body carries the section (BEST-EFFORT, not a pass/fail gate) | After `/ship` opens the PR and Step 4.6 runs, `gh pr view <PR#> --json body -q .body \| grep -F '### Registered-doc requirements'` | The PR body's `## Documentation` section contains a real `### Registered-doc requirements` block with per-doc verdict lines — a true end-to-end proof. NON-BLOCKING: a failed `gh pr edit` logs a note and does NOT fail the run; verdicts still live in the run output + scratch file (the deterministic proof is T1+T2, not this) | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` exits 0 (no new ERROR; Check 15a/Check 1/Check 16 GREEN)
- [ ] `./scripts/test.sh` exits 0 (RESULT: PASS; the two new §6 smoke checks green; zzz-test-scaffold fixture unaffected — explicitly verified)
- [ ] T1 + T2 (the two DETERMINISTIC producer+surfacing wiring grep checks) both green — the primary proof the feature is wired, not inert
- [ ] Advisory/never-halt posture confirmed: Step 6.7 sits on the green-tail of Step 6 and `missing-requirement` is a soft verdict (no `[doc-sync-*]` halt path added)
- [ ] No upstream modification: `git diff` touches only workbench-owned files (skills/CJ_document-release/, skills/CJ_goal_feature/, CLAUDE.md, skills-catalog.json, doc/ARCHITECTURE.md, TODOS.md, scripts/test.sh) — no upstream gstack `/document-release` or `/ship` files
- [ ] Best-effort dogfood (T10): THIS PR's body carries a real `### Registered-doc requirements` section (non-blocking)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (workbench, zsh) | branch cj-feat-20260604-095407-47056 | Pending |
