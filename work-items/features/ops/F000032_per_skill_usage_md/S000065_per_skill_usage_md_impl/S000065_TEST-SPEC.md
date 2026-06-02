---
type: test-spec
parent: S000065
feature: F000032
title: "Per-skill USAGE.md convention + audit — Test Specification"
version: 1
status: Draft
date: 2026-06-01
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Template file exists with all five required H2 headings | Story #1 — `templates/doc-SKILL-USAGE.md` present and structurally correct | `for H in '^## When to use$' '^## When NOT to use$' '^## Mental model$' '^## Common pitfalls$' '^## Related skills$'; do grep -qE "$H" templates/doc-SKILL-USAGE.md \|\| { echo "missing: $H"; exit 1; }; done` |
| S2 | core | AC-2, AC-3 | Eleven USAGE.md files exist with all required H2 headings | Story #2 + #3 — every routable non-deprecated skill has a complete USAGE.md | `jq -r '.[] \| select(.status != "deprecated") \| select((.files \| length) > 0) \| .name' skills-catalog.json \| while read n; do for H in '^## When to use$' '^## When NOT to use$' '^## Mental model$' '^## Common pitfalls$' '^## Related skills$'; do grep -qE "$H" "skills/$n/USAGE.md" \|\| { echo "missing $H in $n"; exit 1; }; done; done` |
| S3 | observability | AC-4, AC-10 | validate.sh Check 13 catches a missing USAGE.md (negative test) | Story #4 + #10 — audit is computed from catalog and ERRORs on drift | `mv skills/CJ_suggest/USAGE.md /tmp/usage_bak && ! ./scripts/validate.sh >/dev/null 2>&1; rc=$?; mv /tmp/usage_bak skills/CJ_suggest/USAGE.md; [ $rc -ne 0 ] \|\| { echo "validate.sh did not ERROR on missing USAGE.md"; exit 1; }` |
| S4 | resilience | AC-8 | validate.sh green on PR HEAD | Story #8 — full validate suite passes | `./scripts/validate.sh` |
| S5 | resilience | AC-9 | test.sh green on PR HEAD | Story #9 — full test suite passes (superset of validate) | `./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-5, AC-6 | Decision-tree → USAGE.md chain answers "should I invoke this skill?" | Open `doc/PHILOSOPHY.md`. Read the new `## Documentation surfaces` section to confirm it describes the three-doc model. Then jump to `## Decision tree`. Pick two random skill entries; click their USAGE links. Read each USAGE.md cold. | Each USAGE.md answers (a) when to invoke (b) when NOT to invoke (c) the mental model — without needing to read SKILL.md afterwards. | PASS if both random USAGE.md answer (a)+(b)+(c) clearly in under 60 sec of reading; FAIL if either feels like placeholder fill. |
| E2 | usability | AC-7 | CLAUDE.md guides a new-skill author | Read `CLAUDE.md` "Skill directory structure" and "Creating a new skill" sections cold. Imagine you are creating skill `foo`. | The Skill directory structure block lists USAGE.md as required. The Creating-a-new-skill step list instructs creating `skills/foo/USAGE.md` from `templates/doc-SKILL-USAGE.md`. DESIGN.md step explicitly says optional. | PASS if a reader following the doc would create USAGE.md before running `./scripts/validate.sh`; FAIL if USAGE.md is implied/buried. |
| E3 | usability | AC-11 | skills-deploy install does NOT propagate USAGE.md | After PR's HEAD, run `./scripts/skills-deploy install` (or `doctor`). | No USAGE.md files appear under `~/.claude/skills/{name}/`. `skills-deploy doctor` reports no drift findings about USAGE.md. The new template `templates/doc-SKILL-USAGE.md` is also NOT copied to `~/.claude/templates/`. | PASS if `find ~/.claude/skills -name USAGE.md` returns empty AND doctor shows no USAGE.md drift; FAIL otherwise. |
| E4 | observability post-ship | AC-4 | CI catches a future USAGE.md regression | After ship, in a follow-up branch, intentionally delete one USAGE.md and push. | CI `validate.sh` step fails with a clear ERROR naming the missing file. | PASS if CI red on the throwaway branch; FAIL if green. (post-ship — workflow only exists on main after merge) |

<!-- If an E2E test skill exists for this feature, reference it here:
     N/A — manual smoke. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| USAGE.md content quality beyond "has five H2 sections with non-empty bodies" | Subjective; cheaper to handle via the E1 manual smoke than to encode in the audit | A USAGE.md could ship with low-quality but structurally-valid content; mitigation = the E1 manual smoke + post-ship "Assignment" |
| Frontmatter shape | Not audited by design (see SPEC tradeoff row) | A USAGE.md could ship with malformed frontmatter; risk accepted — frontmatter is recommended via template, not enforced |
| work-copilot/ has no USAGE.md analog | Workbench-only scope (Constraint #1) | Copilot bundle remains without a USAGE-style surface; decide separately if/when work-copilot grows |
| README.md per-skill USAGE.md links | Deferred (catalog + script change) | Discovery relies on PHILOSOPHY decision tree; if insufficient, open a TODOS row |
| Concurrent-PR collision on the new template | Only one PR is opening this surface | If another open PR adds a competing `templates/doc-SKILL-*.md` they could race; surface area too small to matter |
