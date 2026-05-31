---
type: test-spec
parent: S000063
feature: F000030
title: "Move + rewrite philosophy.md → doc/PHILOSOPHY.md, add doc/ARCHITECTURE.md, README + CLAUDE.md edits — Test Specification"
version: 1
status: Approved
date: 2026-05-31
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. For a single fix or task, use test-plan.md instead.

     Two tiers, distinguished by who edits them and when they run:
     - Smoke = automated regression. Lives in CI. You write it once and
       never touch it again.
     - E2E   = manual user-scenario verification. You sit down and run it
       after implementing and before /ship.

     Soft cap: 5 rows per tier. Validator emits [INFO] advisory if exceeded;
     not a violation. Exceed only when justified — the cap is a forcing
     function to pick the tests that prove the story works, not the tests
     that demonstrate completeness. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Once written, you should not need to edit these. Soft cap: 5 rows.
     Pick the structural checks that catch real regressions, not all checks
     that could exist. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | doc/ folder + files exist; root philosophy.md is absent; rename history preserved | `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md` present; `philosophy.md` absent at root; `git log --follow` walks back through the rename | `test -f doc/PHILOSOPHY.md && test -f doc/ARCHITECTURE.md && test ! -f philosophy.md && git log --follow --oneline doc/PHILOSOPHY.md \| head -5 \| grep -q .` |
| S2 | core | AC-3 | PHILOSOPHY references new front doors; no orphan retired-skill references | `/cj_goal_feature` AND `/cj_goal_defect` appear; every match of `/workflow`, `/contracts`, `/docs`, `/CJ_goal_auto`, `/CJ_goal_run` is inside `## Retired skills` (or absent) | `grep -q "/cj_goal_feature" doc/PHILOSOPHY.md && grep -q "/cj_goal_defect" doc/PHILOSOPHY.md && awk '/^## Retired skills/{in_section=1; next} /^## /{in_section=0} {if (!in_section && /\/(workflow\|contracts\|docs\|CJ_goal_auto\|CJ_goal_run)([^a-zA-Z_-]\|$)/) {print "ORPHAN: " FILENAME ":" NR; exit_code=1}} END{exit exit_code+0}' doc/PHILOSOPHY.md` |
| S3 | core | AC-4, AC-5 | PHILOSOPHY Decision tree present; ARCHITECTURE has all five required headings | `## Decision tree` heading exists in PHILOSOPHY with active CJ_ skills named; ARCHITECTURE contains exactly the five required `##` headings | `grep -q "^## Decision tree$" doc/PHILOSOPHY.md && for h in "## The shared cj-goal-common.sh helper (S000057)" "## F000028 doc-sync hooks (post-merge + post-rewrite)" "## F000029 marker-pickup AUQ (cj_goal preambles)" "## Decision tree mirror" "## Deprecation tombstones"; do grep -qF "$h" doc/ARCHITECTURE.md \|\| { echo "MISSING: $h"; exit 1; }; done` |
| S4 | core | AC-6, AC-7, AC-8, AC-9, AC-10 | Each ARCHITECTURE section answers its content questions | S000057 section names worktree+pr-check+telemetry+feature/defect/investigate+three consumers; F000028 section names marker schema + 4 fields + 2 hooks; F000029 section names script-output-AUQ split + branch ordering + 3 subcommands; Decision-tree-mirror points back; Deprecation-tombstones names three-shape pattern + F000005/6/7 + F000027 | `awk '/^## The shared cj-goal-common.sh helper/{f=1} f && /worktree.*pr-check.*telemetry\|worktree/&&/pr-check/&&/telemetry/{p1=1} f && /feature/&&/defect/&&/investigate/{p2=1} f && /cj_goal_feature/&&/cj_goal_defect/&&/CJ_goal_investigate/{p3=1} /^## (F000028\|$)/{f=0} END{exit !(p1 && p2 && p3)}' doc/ARCHITECTURE.md && grep -A50 "^## F000028 doc-sync hooks" doc/ARCHITECTURE.md \| grep -q "~/.gstack/doc-sync-pending" && grep -A50 "^## F000028 doc-sync hooks" doc/ARCHITECTURE.md \| grep -q "head_sha" && grep -A50 "^## F000028 doc-sync hooks" doc/ARCHITECTURE.md \| grep -q "post-merge" && grep -A50 "^## F000028 doc-sync hooks" doc/ARCHITECTURE.md \| grep -q "post-rewrite" && grep -A50 "^## F000029 marker-pickup AUQ" doc/ARCHITECTURE.md \| grep -q "DOC_SYNC_PENDING" && grep -A50 "^## F000029 marker-pickup AUQ" doc/ARCHITECTURE.md \| grep -q -- "--resolved" && grep -A20 "^## Decision tree mirror" doc/ARCHITECTURE.md \| grep -q "PHILOSOPHY" && grep -A30 "^## Deprecation tombstones" doc/ARCHITECTURE.md \| grep -qE "F00000[567]" && grep -A30 "^## Deprecation tombstones" doc/ARCHITECTURE.md \| grep -q "F000027"` |
| S5 | integration | AC-11, AC-12, AC-13 | CLAUDE.md convention + CHANGELOG entry + README Deeper reading | CLAUDE.md has the new section with both literal jq commands; CHANGELOG has F000030 entry; README has Deeper reading with both links | `grep -q "^## /document-release workbench audit conventions" CLAUDE.md && grep -qF 'jq -r '"'"'.[] | select(.status=="deprecated") | .name'"'"' skills-catalog.json' CLAUDE.md && grep -qF 'jq -r '"'"'.[] | select(.status=="active") | .name'"'"' skills-catalog.json' CLAUDE.md && grep -qE "(DEPRECATED\|sunset\|tombstone)" CLAUDE.md && grep -q "F000030" CHANGELOG.md && grep -q "^## Deeper reading" README.md && grep -q "doc/PHILOSOPHY.md" README.md && grep -q "doc/ARCHITECTURE.md" README.md` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section
     below for semantics — applies to E2E rows only; smoke rows do not support
     post-ship deferral). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     You drive the feature as a real user would and observe the outcome.
     Soft cap: 5 rows. Each row should be one user-visible scenario,
     not one branch in the code. AC column maps each row to a SPEC
     acceptance criterion.

     Post-ship rows: if a row is structurally only verifiable AFTER the PR
     merges to main (e.g., `gh workflow run` against a CI workflow that
     doesn't exist on remote refs until merge), add the literal token
     `post-ship` to the row's Tag column (e.g., Tag = `core post-ship`
     or just `post-ship`). /CJ_qa-work-item Step 4 will filter these rows
     out of the E2E subagent dispatch and record a [qa-e2e-deferred] journal
     entry naming the row + its AC instead of forcing a pretend-green
     adjudication. Verification of post-ship rows happens after merge (via
     manual `gh workflow run` or via post-merge tooling). -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-3, AC-4 | Operator reads `doc/PHILOSOPHY.md` and answers two routing questions correctly | (1) Open `doc/PHILOSOPHY.md` in editor or GitHub. (2) Read top-to-bottom. (3) Answer: "Which CJ_ skill do I call to start a feature?" (4) Answer: "What closes the doc-sync loop?" (5) Optionally cross-reference with `## Decision tree` section. | Answer (3) is `/cj_goal_feature`. Answer (4) names F000028 hooks + F000029 marker-pickup AUQ. If either wrong, the doc is not legible enough for its stated goal. | Both answers correct on first read without re-deriving from skill descriptions. |
| E2 | integration post-ship | AC-11 | Plant an unannotated retired-skill reference in `doc/PHILOSOPHY.md`; run `/document-release`; verify the drift fires | (1) On a throwaway feature branch from main, edit `doc/PHILOSOPHY.md` to add an unannotated `/workflow` mention OUTSIDE the `## Retired skills` subsection and NOT near any DEPRECATED/sunset/tombstone words. (2) Commit. (3) Run `/document-release` against the branch. (4) Inspect PR body's `## Documentation` section. (5) Cleanup: revert the test edit. | PR body's `## Documentation` section contains a `### Skill-routing drift` subheading naming `/workflow` as a drift finding. | Subheading present; finding lists `/workflow`; no false-positive on annotated mentions inside `## Retired skills` or near suppression keywords. Tag: post-ship because requires `/document-release` reading the merged CLAUDE.md convention. |
| E3 | integration post-ship | AC-11 | Add an active-skill stub not referenced in `## Decision tree`; run `/document-release`; verify the new-skill drift fires | (1) On a throwaway feature branch from main, add a `skills/CJ_smoketest/SKILL.md` stub + catalog entry (`status: active`). (2) Do NOT mention `CJ_smoketest` in `doc/PHILOSOPHY.md ## Decision tree`. (3) Commit. (4) Run `/document-release` against the branch. (5) Inspect PR body's `## Documentation` section. (6) Cleanup: revert the stub. | PR body's `## Documentation` section contains a `### Skill-routing drift` subheading naming "active skill not in decision tree: CJ_smoketest". | Subheading present; finding lists `CJ_smoketest`. Tag: post-ship because requires `/document-release` reading the merged CLAUDE.md convention. |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| `/document-release` Step 1 base-branch abort behavior (skill refuses to run on main) | Out of scope; documented as separate F000029 contract gap. The workbench convention is still read on any feature branch. | The audit convention lands but only fires on feature-branch runs of `/document-release`. Operator who runs `/document-release` on main sees the abort message, switches to a feature branch, then the convention fires correctly. |
| Annotation suppression window edge cases (e.g., 199 vs 201 chars from a suppression keyword) | Deterministic boundary cases are easy to miss; tested empirically via E2 (planted mention OUTSIDE the window) but not parameterized | If false-positives on legitimate prose, the operator sees the drift finding and either tightens the window (smaller spec change) or ignores. Either path is recoverable. |
| `doc/ARCHITECTURE.md` semantic accuracy of mechanism claims (e.g., did F000028 hook really fire on post-rewrite or just post-merge?) | Content-gating checks for named entities, not factual correctness of the prose | Operator/reviewer eye-checks during PR review. Reviewer catches a wrong claim in normal code review. |
| CHANGELOG entry text quality (e.g., does the entry name all four touched surfaces in the right order?) | Validated by presence of "F000030" only, not by entry composition | Reviewer eye-checks during PR review. Wrong/incomplete entry caught in normal review. |
| `git log --follow` history depth (how many pre-rename commits surface) | Only checks presence of any pre-rename commits, not full history depth | git itself handles the rename detection; depth depends on git's heuristic. Acceptable as long as at least one pre-rename commit is reachable. |
