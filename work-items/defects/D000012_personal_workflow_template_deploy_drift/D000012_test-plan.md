---
type: test-plan
parent: D000012
title: "personal-workflow: deployed templates drift from workbench after D000009/v0.14.2 — Test Plan"
date: 2026-05-01
author: chjiang
status: Verified
---

<!-- Scope: regression coverage for the deploy-drift defect. The fix has two parts:
     (1) restoring the deployed templates to match workbench source, and
     (2) a regression check that flags future drift between the two locations. -->

## Scope

The fix touches:
- `~/.claude/templates/{personal,company}-workflow/` — restored via `scripts/skills-deploy install --overwrite` (one-shot runtime action; not a committed file change)
- `scripts/test.sh` — new D000012 regression block (~50 lines) covering both workflows. Block has two parts: (1) catalog membership check for `doc-DESIGN.md` and `doc-feature-summary.md` in both workflows, and (2) byte-identity check between workbench `templates/{workflow}/*.md` and `~/.claude/templates/{workflow}/*.md` when the deployed dir exists, gracefully skipping with an INFO line when not (e.g. CI).

No source code change to the validator itself; the existing 2-level resolution is correct. The fix is at the deploy-pipeline + test-suite layer.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Deployed templates match workbench source after install | (a) Run `scripts/skills-deploy install --overwrite`. (b) `diff -r templates/personal-workflow/ ~/.claude/templates/personal-workflow/` | Empty diff (or only whitespace differences) | **PASS** — deploy reported `Templates — Installed: 7`; post-deploy `diff -r` is empty for both workflows |
| 2 | All manifest-required templates resolve at Level 2 | For each entry in `jq '.types[].required[].template' skills/personal-workflow/personal-artifact-manifests.json`, assert `~/.claude/templates/personal-workflow/{template}` exists | All templates referenced by the manifest are present | **PASS** — covered by Test #1's empty diff (every manifest-referenced template is a subset of the workbench source set) |
| 3 | skills-catalog.json declares both new templates | `jq -e --arg p "personal-workflow/doc-DESIGN.md" --arg n "personal-workflow" '.[] \| select(.name == $n) \| .templates \| index($p)' skills-catalog.json` (repeated for `doc-feature-summary.md` and for `company-workflow`) | All four index lookups return non-null (verifies D000009 + v0.14.2 catalog claims for both workflows; ensures `skills-deploy install` has the metadata to copy them). Note: catalog stores entries as `{workflow}/{file}` without the `templates/` prefix. | **PASS** — D000012 regression block emits 4 OK lines (one per `{workflow, template}` pair) |
| 4 | Drift check flags a missing template | (a) Temporarily `rm ~/.claude/templates/personal-workflow/doc-DESIGN.md`. (b) Run `./scripts/test.sh`. (c) Restore via `scripts/skills-deploy install --overwrite`. | Test fails with `deployed template missing: personal-workflow/doc-DESIGN.md`; passes after restore | **PASS** — covered by the pre-fix run of the new block, which surfaced 3 missing templates (incl. `personal-workflow/doc-DESIGN.md`); post-deploy run reports 0 missing |
| 5 | Drift check flags a stale template (byte-level delta) | (a) Overwrite a deployed template with an older version. (b) Run `./scripts/test.sh`. (c) Restore via `scripts/skills-deploy install --overwrite`. | Test fails with `deployed template differs from workbench: ...`; passes after restore | **PASS** — covered by the pre-fix run, which surfaced 4 byte-mismatched templates (`tracker-feature.md` in both workflows, `tracker-user-story.md` in personal, `doc-milestones.md` in company); post-deploy run reports 0 differences |
| 6 | discord-v1 still flags `[MISSING]` for unfilled artifacts | From portfolio, run `/personal-workflow check work-items/features/discord-v1/` | `[MISSING] feature-summary` and `[MISSING] design` reported (not silently passed); confirms the validator reaches the existence check rather than short-circuiting on template-not-found | Pending — portfolio-side verification (depends on portfolio having `~/.claude/templates/` refreshed, which it now does) |
| 7 | Validation of an existing portfolio feature directory runs frontmatter checks against restored templates | From `/Users/chjiang/Documents/projects/portfolio`, run `/personal-workflow check work-items/features/cold-start/` (which has `feature-summary.md` present) | No `[WARN] template not found` for `doc-feature-summary.md`; frontmatter validation actually executes (verifiable by introducing a missing required field in `cold-start/feature-summary.md` and confirming it is flagged) | Pending — portfolio-side verification |
| 8 | Same drift coverage extended to company-workflow | (Implementation choice in this PR) Drift block iterates over both `personal-workflow` and `company-workflow` template dirs in a single loop | Both workflows checked in one pass; no `[DRIFT]` flags after deploy | **PASS** — block uses `for _wf in personal-workflow company-workflow` and emits separate OK lines per workflow |

## Verification Steps

- [x] `./scripts/validate.sh` — passes (no skill catalog regressions)
- [x] `./scripts/test.sh` — passes (0 failures) including the new D000012 drift block; pre-fix run surfaced 7 FAILs across both workflows that the deploy then resolved (proves the regression check actually catches drift)
- [x] `diff -r templates/personal-workflow/ ~/.claude/templates/personal-workflow/` is empty (and same for company-workflow)
- [ ] `/personal-workflow check work-items/` from workbench — no new violations (Pending — run as part of `/ship` Phase 3)
- [ ] `/personal-workflow check work-items/features/cold-start/` from portfolio — frontmatter validation runs against the actual template (Pending — portfolio-side, separate session)
- [x] Manual: re-read this defect's RCA and confirm the failure mode is no longer reproducible — pre-fix `./scripts/test.sh` would have caught the original drift; on a future workbench template edit without re-deploy, `./scripts/test.sh` will fail with the same `deployed template missing/differs` messages and a pointer to `scripts/skills-deploy install --overwrite`

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 (workbench) | `fix/personal-workflow-template-deploy-drift` (off `main` @ d00ff78 / v1.1.0) | **PASS** — `./scripts/test.sh` 0 failures including new D000012 block |
| macOS Darwin 25.3.0 (portfolio, downstream consumer) | portfolio main | Pending — separate verification session; templates now restored via Option A so portfolio's `~/.claude/templates/` is current as of this defect's deploy |
