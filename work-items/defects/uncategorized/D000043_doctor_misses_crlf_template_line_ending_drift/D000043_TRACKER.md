---
name: "skills-deploy doctor misses CRLF line-ending drift in deployed templates (Windows P0 bucket c): the committed content is LF, but a Windows checkout (core.autocrlf=true) can leave CRLF, install copies it AND records the CRLF source_checksum, so doctor's checksum comparison passes while the deployed copy is still CRLF — the drift stays silent. Finishing the Windows test.sh P0 (bucket a shipped as D000040/PR #328; bucket b resolved by F000081 + D000040's SIGPIPE fix; bucket c: this independent doctor CR probe + an operational renormalize + re-install)"
type: defect
id: "D000043"
status: active
created: "2026-07-05"
updated: "2026-07-05"
repo: "E:/projects/claude-skills-templates"
branch: "claude/heuristic-albattani-eace9b"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/doctor_misses_crlf_template_line_ending_drift
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: claude/heuristic-albattani-eace9b
3. Required docs scaffolded (D000043 RCA + test-plan)
4. Root cause confirmed by live reproduction on the affected Windows box

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (branch field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Fix written directly to source (independent CR probe in skills-deploy do_doctor)
2. Regression test added (test-deploy.sh Test 8c)
3. Fix + work-item artifacts committed (before QA)
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
- [x] /ship — PR created
- [ ] /land-and-deploy — merged and deployed

## Reproduction Steps

On Windows Git Bash with `core.autocrlf=true`, a `~/.claude/templates/*` copy can be
CRLF while the workbench source (and committed blob) is LF (`.gitattributes eol=lf`).
`skills-deploy doctor` reports the template `OK` because it compares the deployed
copy's checksum against the manifest's recorded `source_checksum` — and a CRLF
install recorded the CRLF sum, so they match. Meanwhile `scripts/test.sh`'s D000012
byte-`cmp` of source-vs-deployed fails ("deployed template differs from workbench")
when run from an LF checkout. Live on this box: 9/10 CJ_personal-workflow deployed
templates + `doc-SKILL-DESIGN.md` were CRLF while source was LF; `doctor` said OK.

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy
- [ ] On land: strike the P0 row in TODOS.md (all three buckets resolved)

## Log

- 2026-07-05: Finishing the Windows test.sh P0. Confirmed bucket (b) already resolved (a full test.sh reproduction passed all drill-harness checks, 0 failures — F000081's targeted-engine rework + D000040's SIGPIPE fix). Cleared bucket (c) operationally (renormalized the root + deployed templates to LF, doctor now clean) and added an independent CR probe to `skills-deploy doctor` so the drift is no longer checksum-invisible. Domain defaulted to 'uncategorized'.

## PRs

- https://github.com/jcl2018/claude-skills-templates/pull/331 (v6.0.121) — OPEN, closes the Windows test.sh P0

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the D000043 RCA. -->

## Journal
- 2026-07-05T00:00:00Z [auto-scaffolded] /CJ_goal_defect ("finish all the p0 ones"): confirmed bucket (b) resolved via reproduction, cleared bucket (c) drift operationally, and shipped the doctor CR probe closing the P0's last gap. Promoted to D000043.
- 2026-07-05T00:00:00Z [qa-pass] /CJ_personal-workflow check VALID (3 artifacts, 0 missing, 0 drift; 3 phases, 11 gates). Test-plan green: test-deploy.sh Test 8c passes in isolation (doctor WARNs on a CRLF-drifted deployed template; silent on a clean LF install), shellcheck clean on skills-deploy + test-deploy.sh, and the live machine is clean (deployed templates LF, doctor 0 CRLF warnings, D000012 drift 0). E2E=ambiguous (defect). AUDITS=deferred (runs on-demand off the build path).
