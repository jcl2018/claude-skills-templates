---
type: test-spec
parent: S000013_relocate_with_catalog_driven_paths
feature: F000006_relocate_deprecated_skills
title: "Relocate with catalog-driven paths — Test Specification"
version: 2
status: Draft
date: 2026-05-02
updated: 2026-05-05
author: chjiang
spec: S000013_SPEC.md
reviewers: []
---

<!-- Migrated from Test Matrix + Test Tiers shape to Smoke + E2E on 2026-05-05.
     Original 16 Test Matrix rows + 7 smoke + 5 E2E consolidated. AC values
     mapped to PRD P0 stories 1-5. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | usability | AC-1 | `skills/` and `templates/` contain only active skills; `deprecated/company-workflow/` populated | Active skill catalog clean; deprecated tree complete | `! [ -d skills/company-workflow ] && ! [ -d templates/company-workflow ] && [ -f deprecated/company-workflow/SKILL.md ]` |
| S2 | core | AC-4 | No hardcoded `skills/company-workflow` references in skills-deploy or validate.sh outside expected sites | Consumer scripts catalog-driven, not path-hardcoded; catalog `files[]` resolves to `deprecated/company-workflow/...` | `grep -c 'skills/company-workflow' scripts/skills-deploy` = 0; `jq -r '.[] \| select(.name == "company-workflow") \| .files \| .[]' skills-catalog.json` returns `deprecated/...` paths |
| S3 | core | AC-2 | Mirror invariant: byte-identity for all 7 MIRROR_SPECS entries | After retargeting MIRROR_SPECS to `deprecated/company-workflow/`, work-copilot/ byte-mirror still passes | `./scripts/validate.sh` Error check 10 reports PASS for all 7 mirror entries |
| S4 | usability | AC-6, AC-7 | Conventions documented: `deprecated/README.md` + CLAUDE.md mention | `deprecated/README.md` exists with purpose explanation; CLAUDE.md conventions section references the deprecated path convention | `test -f deprecated/README.md && grep -q '^- \`deprecated/' CLAUDE.md` |
| S5 | core | AC-5 | Full repo invariants: validate.sh + test.sh both green | The relocation is a pure path refactor with no behavioral change | `./scripts/validate.sh && ./scripts/test.sh` both exit 0 |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3 | Clean-target install (default) skips company-workflow | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)`. 2. `scripts/skills-deploy install`. 3. `ls $SKILLS_DEPLOY_TARGET/skills/` | personal-workflow + system-health installed; no company-workflow dir; output contains exactly 1 line `WARN: skipping deprecated skill: company-workflow (use --include-deprecated to install)` | Pass = WARN line count = 1, company-workflow absent. Fail = any other line count or company-workflow present |
| E2 | core | AC-3 | Clean-target install with --include-deprecated | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)`. 2. `scripts/skills-deploy install --include-deprecated`. 3. `ls $SKILLS_DEPLOY_TARGET/skills/company-workflow/`. 4. Read `$SKILLS_DEPLOY_TARGET/manifest.json` and inspect `skills["company-workflow"].path` | company-workflow dir exists; manifest path = `deprecated/company-workflow/SKILL.md` | Pass = dir present + manifest path is deprecated/. Fail = dir missing OR manifest path still references skills/ |
| E3 | core | AC-3 | doctor INFO state | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)`. 2. `scripts/skills-deploy install`. 3. `scripts/skills-deploy doctor` | company-workflow appears under INFO line(s); no WARN for it | Pass = INFO line for company-workflow exists; zero WARN for it. Fail = WARN appears or INFO missing |
| E4 | core | AC-2 | Mirror byte-identity (full validate.sh run) | 1. `./scripts/validate.sh`. 2. Inspect output for Error check 10 results | All 7 mirror entries report PASS; exit 0 | Pass = 7/7 PASS. Fail = any FAIL or any unexpected WARN |
| E5 | core | AC-5 | Full test.sh run | 1. `./scripts/test.sh`. 2. Inspect tail of output | "Failures: 0"; exit 0 | Pass. Fail = any failure count > 0 |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Behavior on Windows (CRLF in catalog/file paths) | The repo ships on Mac/Linux primary; F000005 already verified D000005 jq CRLF safety. F000006 doesn't change that surface. | If a Windows user clones, runs install, and hits a path-separator issue, that's an isolated future fix |
| Cross-machine sync of pre-existing manifest path field | Manifest path stale after upgrade is a known acceptable state — F000006 doesn't auto-rewrite manifests | Stale path field with functional install is acceptable; user runs `skills-deploy remove && install --include-deprecated` to refresh if needed |
| Performance regression on `validate.sh` after orphan-check extension to `deprecated/` | `validate.sh` runs in <2s today; adding one more directory walk adds negligible overhead | If validate.sh runtime regresses noticeably (>10s), that's a separate optimization concern |
| Concurrent install on the same target | F000005 didn't test it; F000006 doesn't change concurrency behavior | No new race conditions introduced |
| External downstream consumer with hardcoded `skills/company-workflow` paths | Out of scope (workbench-only scope per CLAUDE.md and user memory) | If a downstream user has a workflow grep-ing `skills/company-workflow/`, they get the same behavior as before for `~/.claude/skills/company-workflow/` (destination unchanged); only repo source path changed |
| Idempotent install (P1) and pre-existing v1.2.0 install (P2) | Consolidated into E2 round-trip; granular cases live in test.sh assertions | If idempotency regresses, E2's manifest path check or test.sh assertion catches it |
| `scripts/test.sh` COMPANY_PATH constants (P2) | Consolidated into S2's grep-count assertion | If hardcoded refs creep back in, S2 catches them |
