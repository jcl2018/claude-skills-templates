---
type: test-plan
parent: T000041
title: "Surface utilities + phase-step skills in doc/WORKFLOWS.md (re-partition roster out of ARCHITECTURE) — Test Plan"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- Scope: ONE task — MOVE the 9 component skills (4 phase-step + CJ_personal-workflow
     validator + 4 standalone utilities) out of doc/ARCHITECTURE.md's `## Component skills
     (non-workflow roster)` into a NEW doc/WORKFLOWS.md `## Utilities & phase-step skills`
     section (lighter per-skill shape); slim ARCHITECTURE's roster to a one-line pointer
     (NO duplication); re-point CLAUDE.md authoring conventions + both tracked-doc manifest
     requirements + the section template; rewrite tests/cj-document-release.test.sh assertions
     9/9b to the new WORKFLOWS location. The DETERMINISTIC guarantees are validate.sh green
     (Check 15a still parses 3 doc/ paths; Check 15b unchanged) + test.sh green (the rewritten
     9/9b pass against WORKFLOWS); the all-9-present + no-duplicate-roster checks are manual
     greps; the dogfood (Step 6.7 verdicts) is best-effort, not a gate. -->

## Scope

This task re-partitions the doc surface — no new artifact, no new audit class, no validate.sh
check change. It (a) MOVES the 9 component skills from doc/ARCHITECTURE.md's roster into a NEW
doc/WORKFLOWS.md `## Utilities & phase-step skills` section (lighter per-skill shape:
`### <skill>` + **Status** + **Source** + **Invoke when** + a compact **Touches** =
`Scripts · tools · shell:` + `Reads / writes:`), (b) slims ARCHITECTURE's roster to a one-line
pointer (no duplication), (c) re-points the CLAUDE.md authoring conventions + both tracked-doc
manifest `requirement:` values + the section template, and (d) rewrites
tests/cj-document-release.test.sh assertions 9/9b to grep the new WORKFLOWS location. Files modified:

- `doc/WORKFLOWS.md` — §1: intro L3/L5 + the T000040 granular-enumeration rule block RE-SCOPED
  to the `## Orchestrators` sections; the "workflow altitude only / see ARCHITECTURE" redirect
  dropped; `## See also` dangling roster cross-ref removed; NEW `## Utilities & phase-step skills`
  section (below `## Orchestrators`), sub-grouped `### Phase-step skills` / `### Validators` /
  `### Standalone utilities`, holding all 9 MOVED entries in the lighter shape.
- `doc/ARCHITECTURE.md` — §2: `## Component skills (non-workflow roster)` (incl. its L121
  preamble) slimmed to a ONE-LINE pointer to WORKFLOWS.md `## Utilities & phase-step skills`;
  `## Decision tree mirror` UNTOUCHED (does not name the roster).
- `CLAUDE.md` — §3: the `### Skill directory structure` note + "Creating a new skill" step 6 +
  the `## /document-release workbench audit conventions` note re-pointed from the ARCHITECTURE
  roster → WORKFLOWS utility section. §4: the `doc/WORKFLOWS.md` `requirement:` VALUE gains the
  `## Utilities & phase-step skills` clause + the 4-bullet-Touches-is-orchestrators-only
  clarification; the `doc/ARCHITECTURE.md` `requirement:` VALUE drops "lists every non-workflow
  routable skill" → "roster now lives in WORKFLOWS.md". Both single in-block double-quoted scalars.
- `templates/doc-WORKFLOWS-section.md` — §5: L8–13 author guidance rewritten — non-orchestrator
  skills now go in WORKFLOWS.md's `## Utilities & phase-step skills` (lighter shape), NOT
  doc/ARCHITECTURE.md's roster.
- `tests/cj-document-release.test.sh` — §6: assertions 9 + 9b rewritten to grep the new
  `doc/WORKFLOWS.md` `## Utilities & phase-step skills` location for the `CJ_document-release`
  entry (9) + its Step-5.5 mention (9b, or drop the Step-5.5 prose check); L18-20 / L117-130
  comments updated. The ONE non-doc edit.
- `CHANGELOG.md` / `VERSION` — §7: at `/ship` (version reconciled per the version queue).

Posture: doc re-partition + ONE test-fixture rewrite; NO validate.sh check change; NO upstream
gstack `/document-release` or `/ship` modification (only workbench-owned docs/templates/tests).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | validate.sh PASS — Check 15a parses the manifest, Check 15b unchanged (DETERMINISTIC) | `./scripts/validate.sh; echo "exit=$?"` after the re-partition | `exit=0`, RESULT: PASS, 0 errors. Check 15a still maps exactly 3 doc/ manifest paths (PHILOSOPHY/ARCHITECTURE/WORKFLOWS) — the two `requirement:` edits stayed in-block (single double-quoted scalars). Check 15b stays `startswith("CJ_goal_")`-scoped (orchestrator 4-bullet Touches still green); Check 15 maps WORKFLOWS + ARCHITECTURE (no orphan/missing) | Pending |
| 2 | test.sh PASS — the rewritten cj-document-release.test.sh 9/9b pass against WORKFLOWS (DETERMINISTIC — primary regression proof) | `./scripts/test.sh; echo "exit=$?"` AND `bash tests/cj-document-release.test.sh; echo "exit=$?"` | `exit=0`, RESULT: PASS, 0 failures. Assertions 9 + 9b now grep `doc/WORKFLOWS.md` `## Utilities & phase-step skills` for the `CJ_document-release` entry (9) + its Step-5.5 mention (9b) and PASS; all other assertions unaffected | Pending |
| 3 | §1 NEW `## Utilities & phase-step skills` section present + all 9 component skills MOVED in (none lost) | `grep -n '^## Utilities & phase-step skills' doc/WORKFLOWS.md`; then for each of the 9 names confirm a `### <skill>` entry exists in that section | The section exists below `## Orchestrators`, sub-grouped `### Phase-step skills` / `### Validators` / `### Standalone utilities`; all 9 present exactly once — CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, CJ_document-release (phase-step); CJ_personal-workflow (validator); CJ_system-health, CJ_suggest, CJ_improve-queue, CJ_repo-init (utilities) | Pending |
| 4 | §1 lighter per-skill shape used (NOT the orchestrator 4-bullet Touches) | Inspect 2–3 utility entries in the new WORKFLOWS section | Each entry = `### <skill>` + **Status** + **Source** + **Invoke when** (1 line) + a compact **Touches** (`Scripts · tools · shell:` + `Reads / writes:`); NO **Skills dispatched** / **Steps · phases** bullets (empty for single-step skills) | Pending |
| 5 | §2 ARCHITECTURE roster slimmed to a one-line pointer — NO duplication | `grep -n 'Component skills (non-workflow roster)' doc/ARCHITECTURE.md` AND confirm the 9 skill bullets are GONE from ARCHITECTURE | The `## Component skills (non-workflow roster)` heading is now a ONE-LINE pointer to WORKFLOWS.md `## Utilities & phase-step skills` (the L121 "documentation, not Check-enforced" preamble + the 9 `**name**` bullets removed); the 9 skills appear in WORKFLOWS only — no skill is duplicated across the two docs | Pending |
| 6 | §1 intro re-scoped + redirect/See-also cleaned | In `doc/WORKFLOWS.md`: confirm L3/L5 + the T000040 rule block now say "**orchestrator** section"; the "workflow altitude only … see ARCHITECTURE for the component reference" redirect is GONE; `## See also` no longer carries the dangling "PLUS the `## Component skills (non-workflow roster)`" cross-ref | Intro reframed to cover "every routable skill — orchestrator chains AND the component skills," the 4-bullet mandate scoped to orchestrator sections, a one-liner notes the utility section's lighter shape; the ARCHITECTURE redirect + See-also roster cross-ref removed | Pending |
| 7 | §4 CLAUDE.md tracked-doc manifest — both `requirement:` values re-pointed in place; block shape intact | `grep -n 'doc/WORKFLOWS.md\|doc/ARCHITECTURE.md' CLAUDE.md` (the manifest entries) AND `./scripts/validate.sh` Check 15a | The `doc/WORKFLOWS.md` `requirement:` value now adds the `## Utilities & phase-step skills` clause + scopes the 4-bullet-Touches mandate to the `## Orchestrators` sections only; the `doc/ARCHITECTURE.md` `requirement:` value drops "lists every non-workflow routable skill" → "roster now lives in WORKFLOWS.md". Both stay SINGLE double-quoted YAML scalars (no bare `#`, no unquoted `:`); the `- path:`/`audit_class:`/`owner:`/`requirement:` block shape is intact; Check 15a reads the manifest cleanly (3 paths, no orphan/FAIL) | Pending |
| 8 | §3 CLAUDE.md authoring conventions re-pointed (skill-dir note + step 6 + audit-conventions note) | `grep -n 'Component skills (non-workflow roster)' CLAUDE.md` | The `### Skill directory structure` note, "Creating a new skill" step 6, and the `## /document-release workbench audit conventions` note (if it named the ARCHITECTURE roster) now point non-orchestrator skills at WORKFLOWS.md `## Utilities & phase-step skills`; no reader-facing CLAUDE.md prose still routes component skills to the ARCHITECTURE roster | Pending |
| 9 | §5 templates/doc-WORKFLOWS-section.md author guidance re-pointed | `grep -n 'Component skills (non-workflow roster)\|Utilities & phase-step skills' templates/doc-WORKFLOWS-section.md` | The L8–13 guidance no longer says non-orchestrator skills "go to doc/ARCHITECTURE.md `## Component skills (non-workflow roster)`"; it now routes them to WORKFLOWS.md's `## Utilities & phase-step skills` (lighter shape) | Pending |
| 10 | No-vanish net UNTOUCHED + grep-sweep for dangling roster cross-refs | `git grep -n 'Component skills (non-workflow roster)'` (exclude .gstack/, work-items/, CHANGELOG.md) AND confirm `scripts/validate.sh` Check 15b + doc/PHILOSOPHY.md `## Decision tree` are unmodified | PHILOSOPHY decision tree + the New-skills check are UNCHANGED (the agent-judged no-vanish net targets PHILOSOPHY ONLY, not the ARCHITECTURE roster); Check 15b still `startswith("CJ_goal_")`. The only remaining reader-facing `## Component skills (non-workflow roster)` strings are the ARCHITECTURE pointer + the CLAUDE.md/manifest re-point text (+ the CHANGELOG history line) — no dangling cross-ref points readers at a now-empty roster | Pending |
| 11 | Dogfood — THIS PR's body carries the verdict section, both WORKFLOWS + ARCHITECTURE up-to-date (BEST-EFFORT, not a pass/fail gate) | After `/ship` opens the PR, `gh pr view <PR#> --json body -q .body \| grep -F '### Registered-doc requirements'`; confirm `doc/WORKFLOWS.md` AND `doc/ARCHITECTURE.md` read `up-to-date` against their rewritten requirements | The PR body's `## Documentation` section contains a real `### Registered-doc requirements` block; both `doc/WORKFLOWS.md` (incl. the utility section — lighter shape NOT flagged stale) and `doc/ARCHITECTURE.md` (roster removed) read `up-to-date`. NON-BLOCKING: realized at `/ship`/Step 4.6; the deterministic proof is T1+T2 | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` exits 0 (no new ERROR; Check 15a still parses the CLAUDE.md tracked-doc manifest — 3 doc/ paths; Check 15b unchanged, orchestrator 4-bullet Touches still green)
- [ ] `./scripts/test.sh` exits 0 (RESULT: PASS; the rewritten cj-document-release.test.sh assertions 9/9b pass against the new WORKFLOWS location) — re-run `bash tests/cj-document-release.test.sh` explicitly
- [ ] T1 + T2 (the two DETERMINISTIC checks — validate.sh green + test.sh/9-9b green) both pass — the primary proof the re-partition is structurally sound
- [ ] All 9 component skills appear in the new WORKFLOWS `## Utilities & phase-step skills` section (none lost), in the lighter per-skill shape; ARCHITECTURE's roster is a one-line pointer with the 9 bullets removed (no duplication)
- [ ] CLAUDE.md authoring conventions (skill-dir note + step 6 + audit-conventions note) + both tracked-doc manifest requirements + templates/doc-WORKFLOWS-section.md all re-pointed at WORKFLOWS `## Utilities & phase-step skills`; WORKFLOWS intro re-scoped + See-also redirect removed
- [ ] No-vanish net untouched: PHILOSOPHY `## Decision tree` + the New-skills check + validate.sh Check 15b are unmodified; grep-sweep finds no dangling reader-facing roster cross-ref (only the ARCHITECTURE pointer + re-point text + CHANGELOG history remain)
- [ ] No upstream modification: `git diff` touches only workbench-owned files (doc/WORKFLOWS.md, doc/ARCHITECTURE.md, CLAUDE.md, templates/doc-WORKFLOWS-section.md, tests/cj-document-release.test.sh, CHANGELOG.md) — no upstream gstack `/document-release` or `/ship` files; no validate.sh check change
- [ ] Best-effort dogfood (T11): THIS PR's body carries a real `### Registered-doc requirements` section with both doc/WORKFLOWS.md + doc/ARCHITECTURE.md `up-to-date` against their rewritten requirements (non-blocking)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (workbench, zsh) | branch cj-feat-20260604-151208-16431 | Pending |
