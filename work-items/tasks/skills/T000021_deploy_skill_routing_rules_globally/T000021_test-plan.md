---
type: test-plan
parent: T000021
title: "Deploy skill-routing rules globally via skills-deploy install — Test Plan"
date: 2026-05-12
author: chjiang
status: Draft
---

<!-- Scope: ONE task. Cases must be concrete and reproducible. -->

## Scope

Creates `rules/skill-routing.md` as the single source of truth for skill routing
triggers. `scripts/skills-deploy install` copies it to `~/.claude/rules/skill-routing.md`
(auto-loaded by Claude Code globally). CLAUDE.md's "## Skill routing" section becomes a
2-line pointer stub. Additional hardening: sentinel check, WARN flag, validate.sh check,
test-deploy.sh tests, and doctor reporting.

Files changed: `rules/skill-routing.md`, `CLAUDE.md`, `scripts/skills-deploy`,
`scripts/validate.sh`, `scripts/test-deploy.sh`.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | rules/skill-routing.md deploys via `skills-deploy install` | Run `./scripts/skills-deploy install` from workbench | `~/.claude/rules/skill-routing.md` exists with correct routing content | Pending |
| 2 | Auto-load in sibling repo — positive trigger | Open Claude Code session in `cjiang327-exploration` or `jcl2018-portfolio`, say "ship feature" | `/CJ_ship-feature` is suggested or invoked | Pending |
| 3 | Auto-load in sibling repo — negative trigger | In same sibling session, say "implement work item" | `/CJ_implement-from-spec` is NOT suggested (internal step, not a top-level route) | Pending |
| 4 | CLAUDE.md stub preserves HAS_ROUTING detection | Run gstack preamble from workbench | Preamble reports `HAS_ROUTING: yes` | Pending |
| 5 | Editing routing = one file change | Edit `rules/skill-routing.md`, run `skills-deploy install` | `~/.claude/rules/skill-routing.md` reflects the edit; CLAUDE.md unchanged | Pending |
| 6 | validate.sh passes after full implementation | Run `./scripts/validate.sh` | No errors related to rules/ deploy | Pending |
| 7 | test-deploy.sh rules/ tests pass | Run `./scripts/test-deploy.sh` | rules/ deploy tests green | Pending |
| 8 | `skills-deploy doctor` reports rules health | Run `skills-deploy doctor` | Rules deploy status shown (deployed/missing/drifted) | Pending |

## Verification Steps

- [ ] Local build succeeds (`./scripts/validate.sh` passes)
- [ ] `./scripts/test-deploy.sh` passes (includes new rules/ tests)
- [ ] Manual auto-load verification in sibling repo session (Test Cases 2 + 3)
- [ ] gstack preamble HAS_ROUTING: yes confirmed in workbench session (Test Case 4)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 / zsh | claude/competent-tu-96c934 | Pending |
