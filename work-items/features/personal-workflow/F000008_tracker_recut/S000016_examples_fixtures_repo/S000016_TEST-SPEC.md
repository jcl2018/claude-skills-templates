---
type: test-spec
parent: S000016
feature: F000008
title: "Examples + fixtures + repo-level surfaces — Test Specification"
version: 1
status: Draft
date: 2026-05-05
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Examples directory contains new docs and lacks old | example-doc-SPEC.md + example-doc-ROADMAP.md present; the 4 deleted example-doc files absent | `D=skills/personal-workflow/examples; test -f $D/example-doc-SPEC.md && test -f $D/example-doc-ROADMAP.md && for f in example-doc-PRD.md example-doc-ARCHITECTURE.md example-doc-feature-summary.md example-doc-milestones.md; do test ! -f $D/$f \|\| { echo "FAIL: $f still exists"; exit 1; }; done` |
| S2 | core | AC-2 | scripts/test.sh exits 0 (fixtures consistent with new manifest) | Full test suite passes including fixture-driven assertions | `./scripts/test.sh` |
| S3 | core | AC-3 | template-registry.json declares new doc_types and version | jq query returns the new array and version 3.0.0 | `jq -e '.sets["personal-workflow"] \| .version == "3.0.0" and (.doc_types == ["design","spec","roadmap","test-spec","rca","test-plan"])' template-registry.json` |
| S4 | core | AC-4 | scripts/test-deploy.sh exits 0 | No broken-path failures from canary swap | `./scripts/test-deploy.sh` |
| S5 | core | AC-1, AC-3, AC-5 | No stale artifact name references in active repo surfaces | grep across active surfaces returns no matches | `! grep -REn "doc-PRD\.md\|doc-ARCHITECTURE\.md\|doc-feature-summary\|doc-milestones\.md" CONTRIBUTING.md PHILOSOPHY.md template-registry.json skills-catalog.json scripts/test-deploy.sh skills/personal-workflow/examples/` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-1 | Example trackers usable as scaffolding starter | (1) Copy example-tracker-feature.md to /tmp/F999_test_TRACKER.md; (2) Hand-substitute placeholders; (3) Run `/personal-workflow check /tmp/` | Tracker is structurally identical to one scaffolded directly from the template; check returns PASS for tracker structure | 0 [DRIFT] findings on the synthetic tracker |
| E2 | core | AC-5 | CONTRIBUTING and PHILOSOPHY read consistently | Open CONTRIBUTING.md and PHILOSOPHY.md; read every line that mentions an artifact name | All references are SPEC/ROADMAP/DESIGN; no PRD/ARCHITECTURE/feature-summary/milestones references except in sealed-history contexts (e.g., "the v0.x artifact set was...") | Manual read; narrative coherent |
| E3 | observability | AC-6 | skills-deploy doctor reports clean state | Run `./scripts/skills-deploy doctor` | personal-workflow shows version 3.0.0; templates list matches catalog; no orphan-template warnings | 0 warnings on personal-workflow |
| E4 | resilience | AC-4 | scripts/test-deploy.sh's drift-detection test (T6) actually works | Manually trigger T6's "drift detected → --overwrite restores" flow; verify the diff comparison at line 414 succeeds (i.e., $REPO_ROOT/templates/personal-workflow/doc-RCA.md path resolves) | T6 passes; no "file not found" warnings; --overwrite restores the canary template to source content | Test exits 0; expected output present |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| External consumer behavior after template-registry.json changes | Outside repo scope | Downstream consumers re-read on next deploy; no coordinated rollout needed |
| Visual diff of example-tracker rewrites against new tracker templates | Subjective (style + voice) | Manual review during implementation suffices; no automated assertion |
| skills-deploy with `--overwrite` actually deploying the new template set | Already covered by S000014's smoke check + skills-deploy's own tests | If S000014's smoke passes, deploy is fine |
| Per-workflow split in scripts/test.sh tested on company-workflow path | company-workflow is deprecated; the loop should still iterate it for backward compat but the personal-workflow path is the active surface | If company-workflow loop branch breaks silently, only deprecated-skill validation suffers |
