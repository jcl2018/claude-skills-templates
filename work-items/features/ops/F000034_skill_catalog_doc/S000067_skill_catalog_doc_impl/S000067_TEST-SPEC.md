---
type: test-spec
parent: S000067
feature: F000034
title: "doc/SKILL-CATALOG.md + tracked-doc/ manifest — Test Specification"
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
| S1 | core | AC-1, AC-2, AC-3 | Catalog covers all audited skills; orchestrators have charts; single-step skills have tags | Stories #1, #2, #3 — catalog is structurally complete | `for s in $(jq -r '.[] \| select(.status != "deprecated") \| select((.files \| length) > 0) \| .name' skills-catalog.json); do grep -qE "^### ${s}$" doc/SKILL-CATALOG.md \|\| { echo "MISSING: $s"; exit 1; }; done && echo ALL-PRESENT` |
| S2 | core | AC-5, AC-6, AC-7 | CLAUDE.md tracked-doc/ manifest subsection exists; Check 15a fires on orphan + missing-from-disk | Stories #5, #6, #7 — manifest convention is wired | `grep -q "^### Tracked doc/ files manifest$" CLAUDE.md && grep -q "audit_class:" CLAUDE.md && bash -n scripts/validate.sh && grep -q "is in doc/ but not registered" scripts/validate.sh && grep -q "missing from disk" scripts/validate.sh` |
| S3 | core | AC-8, AC-9 | Check 15b fires on missing section + missing chart-and-tag | Stories #8, #9 — catalog-completeness is wired | `grep -q "missing section: ### " scripts/validate.sh && grep -q "neither ASCII chart" scripts/validate.sh && grep -q 'TAG_RE=' scripts/validate.sh` |
| S4 | resilience | AC-12, AC-13 | validate.sh + test.sh green on PR HEAD | Stories #12, #13 — no regressions | `./scripts/validate.sh && ./scripts/test.sh` |
| S5 | resilience | AC-14 | Check 15b gated by `if [ -f "$CATALOG_FILE" ]` (defensive) | Story #14 — intermediate-state safety | `grep -E 'if \[ -f "?\$CATALOG_FILE"? \]' scripts/validate.sh \|\| grep -E 'if \[ -f .*SKILL-CATALOG\.md.* \]' scripts/validate.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-1, AC-2 | Reader scans catalog and understands an orchestrator's flow in 10 lines | Open `doc/SKILL-CATALOG.md`. Read the `### CJ_goal_feature` section. Read the ASCII chart. | The chart shows the topic → office-hours → silent-build → /ship → PR flow clearly. A reader who has never seen `/CJ_goal_feature` understands what it does. | PASS if the chart is legible and matches SKILL.md's `## Overview` shape. FAIL if the chart is wrong, missing, or so abstract it doesn't help. |
| E2 | usability | AC-3 | Reader distinguishes single-step skills from orchestrators | Read the catalog sections for `### CJ_scaffold-work-item` vs `### CJ_goal_feature`. | Scaffold has tag `(phase-step in /CJ_goal_feature chain)`; goal_feature has a chart. The distinction is one line of search. | PASS if a reader can tell at a glance which is which. FAIL if the visual difference is unclear. |
| E3 | usability | AC-5, AC-10, AC-11 | New-skill author discovers the catalog requirement | Read `CLAUDE.md ## Conventions ### Skill directory structure`. Read `CLAUDE.md ## Creating a new skill`. | Skill-directory structure references SKILL-CATALOG.md + Check 15. Creating-a-new-skill has Step 7 instructing the catalog section. | PASS if a reader unfamiliar with F000034 can resolve "do I need to add anything to doc/?" using only CLAUDE.md. FAIL if they have to read validate.sh source. |
| E4 | core, observability | AC-6, AC-7, AC-8, AC-9 | Manual breakage smoke (the assignment in the design doc) | `touch doc/UNREGISTERED.md && ./scripts/validate.sh` → expect orphan ERROR; `rm doc/UNREGISTERED.md`. Then temporarily edit CLAUDE.md to add a manifest entry `path: doc/MISSING.md` → expect missing-from-disk ERROR; revert. Then delete one `### <name>` line in SKILL-CATALOG.md → expect missing-section ERROR; revert. | All three error paths fire with clear, actionable messages. | PASS if each manual breakage surfaces the right ERROR + the right path/skill name. FAIL if any path silently passes or surfaces a confusing message. |
| E5 | resilience post-ship | AC-12 | Post-ship: doc/ manifest drift findings surface in /document-release PR body | After merge, run `/document-release` on a follow-up PR. Read the `## Documentation` section of the PR body. | A `### Doc/ manifest drift` subheading appears with `Doc/ manifest drift: none` (or specific drift findings). | PASS if the audit ran and the subheading is present. FAIL if absent or silently skipped. (Post-ship — only verifiable after merge.) |

<!-- If an E2E test skill exists for this feature, reference it here:
     N/A — manual smoke. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Whether the ASCII chart text is semantically correct (matches actual skill behavior) | Cannot be encoded in a structural audit | Mitigation = `/document-release` post-ship audit reads the catalog; a wrong chart surfaces during the next release cycle. Operator owns content accuracy; Check 15 owns structure. |
| Whether `**Invoke when:** ...` lines accurately distill USAGE.md | Cannot be encoded in a structural audit; would require NLP heuristics | Mitigation = the operator writes them by hand from USAGE.md `## When to use`; cross-skill consistency is the audit trail. Drift surfaces if a reader using SKILL-CATALOG.md gets a wrong impression. |
| Manifest parser robustness under fancy YAML (multi-line values, nested keys, etc.) | v1 manifest is intentionally simple (path/audit_class/owner; one-line values) | Mitigation = manifest is hand-written; fancy YAML would be caught in code review. Hoist to real YAML parser when manifest needs the features. |
| Concurrent-PR collision (two PRs both adding doc/ files without updating manifest) | Out of scope; Check 15 runs at validate-time per-PR | Each PR's own validate.sh catches orphans within that PR; cross-PR coordination is /ship's queue-collision check, not Check 15's job. |
| work-copilot/ skills | Workbench-only scope (Constraint #1 from parent design) | Copilot bundle has no doc/ surface; no Check 15 needed there. |
| Per-skill snooze of Check 15 | Single global ERROR is sufficient for v1 | If a specific skill genuinely shouldn't have a catalog entry but is routable, the right fix is to deprecate / hide it from the audit predicate, not add per-skill snooze. |
| Whether the closed `audit_class` enum is strictly enforced (e.g. ERROR on invalid `audit_class: foo`) | Out of scope for v1; the enum is doc-only in v1 | The validate-time check only uses `path` from the manifest; `audit_class` is informational text consumed by `/document-release`. Future work could add ERROR on unknown enum values. |
