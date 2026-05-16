# claude-skills-templates

Work lifecycle pipeline, doc contract enforcement, and skill authoring workbench for Claude Code.

## Skills

| Name | Description | Status | Portability | Version |
|------|-------------|--------|-------------|---------|
| CJ_system-health | ~/.claude/ health dashboard with dependency graph and usage trends. Scans installed skills, builds dependency graph, checks filesystem health, surfaces skill usage analytics with behavioral topology overlay, invokes waza for config hygiene. | active | standalone | 2.0.0 |
| templates | Skill authoring template for new skills. | active | standalone | 0.1.0 |
| CJ_personal-workflow | Personal work item validation. Validates tracker files and work item directories against personal templates and personal-artifact-manifests.json. Templates + WORKFLOW.md are the single source of truth for structural rules. | active | standalone | 4.0.0 |
| CJ_scaffold-work-item | Scaffold a CJ_personal-workflow work item from an /office-hours design doc. Reads design + templates + manifest + WORKFLOW.md, produces a compliant work-item directory tree with all required artifacts. Runs /CJ_personal-workflow check at boundaries; idempotent (re-run on same input is NO-OP). | experimental | standalone | 1.0.0 |
| CJ_qa-work-item | QA a CJ_personal-workflow work-item (user-story, defect, or task) per its test rows. For user-stories: runs Smoke Tests then dispatches a QA engineer subagent (fresh context, 5-min cap) for E2E verification per TEST-SPEC. For defects/tasks: runs test-plan rows as smoke-equivalent (no E2E subagent in v1). Writes findings to tracker journal; transitions Phase 2 qa-owned gates for user-stories; records [qa-pass] for defects/tasks. Idempotent (re-run on green work-item is NO-OP). Boundary check refuses on incomplete Phase 2. | experimental | standalone | 1.0.0 |
| CJ_implement-from-spec | Implement a CJ_personal-workflow work-item (user-story, defect, task, or feature) from its input artifacts. Reads per-type input (SPEC+DESIGN for user-stories, RCA+test-plan for defects, TRACKER+test-plan for tasks; features delegate to a child user-story via AUQ), plans the change against the artifact's Components Affected / Data Flow, writes code via Read/Edit/Write tools. Sensitive-surface AUQ (catalog/manifest/validator). Propose-and-confirm by default; --auto for trivial changes (≤2 files, no sensitive surface). Idempotent (re-run on completed work-item is NO-OP). Boundary check refuses on incomplete Phase 1; verifies post-write compliance. | experimental | standalone | 1.0.0 |
| CJ_personal-pipeline | INTERNAL -- invoked by /CJ_goal_run. Do not call directly. Single-keystroke orchestrator over the 3 CJ_personal-workflow pipeline skills (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item). Dispatches each phase as a fresh-context Agent subagent with file-only handoff, runs independent inter-step quality gates, pre-collects AUQs at orchestrator (subagents have no AUQ tool). Auto-decides intermediate AUQs using 6 principles, classifies each decision as Mechanical / Taste / User Challenge, and surfaces Taste + User-Challenge-Approved decisions at one final approval gate (Step 8.5; mirrors /autoplan's single-mode contract). Halt-on-red default; idempotent; sunset criterion built in. | experimental | standalone | 1.1.0 |
| CJ_goal_run | Unified pipeline entry point (formerly /CJ_run; renamed v4.0.0). Accepts (a) an APPROVED /office-hours design doc -> full pipeline (autoplan -> scaffold -> impl -> QA -> PR -> deploy), (b) a work-item directory -> Branch(f) full phase-detection + dispatch (impl_qa_ship / qa_ship / ship / open_pr / already_shipped / pr_unknown_state) using verbatim Phase 2 gate strings + gh PR-state check with graceful UNKNOWN fallback, (c) NO ARG -> Branch(g) scans current branch's work-items/ for in-progress user-stories and hands off to Branch(f). Phase 4 invokes /land-and-deploy with --suppress-readiness-gate (opt-in upstream flag mirroring CJ_personal-pipeline's --suppress-final-gate pattern) so green end-to-end runs surface only the autoplan + /ship AUQs; red signals (CI, merge conflict, free-test regression, deploy/canary failure) still halt. Branch(f) open_pr mode auto-continues into /land-and-deploy with the same flag + inline-parsed PR_NUM. Replaces /CJ_ship-feature (renamed) and the public /CJ_personal-pipeline routing (now internal). Halt-on-red default; idempotent via each sub-skill's own re-entry path; sunset criterion at 6th invocation. | active | standalone | 1.0.0 |
| CJ_suggest | Print a ranked top-5 of next-up work items from TODOS.md and tracker frontmatter. Optional --for-skill / --limit flags pre-filter and extend the candidate window for downstream callers like /CJ_goal_todo_fix. | experimental | local-only | 1.1.0 |
| CJ_goal_todo_fix | Auto-resolve a TODO from TODOS.md into a shipped PR (formerly /CJ_goal; renamed v4.0.0). Bridges TODOS.md rows to the existing /CJ_personal-pipeline + /ship + /land-and-deploy chain via an auto-scaffolded T-task work-item. One keystroke turns fix-this-TODO into a merged PR. Workbench-only; halt-on-red preserved end-to-end. | active | standalone | 2.0.0 |
| CJ_run | DEPRECATED ALIAS — renamed to /CJ_goal_run in v4.0.0. This thin alias prints a one-line deprecation banner then delegates to /CJ_goal_run with the same args. Will be removed in v5.0.0. | experimental | standalone | 4.0.0 |
| CJ_goal | DEPRECATED ALIAS — renamed to /CJ_goal_todo_fix in v4.0.0. This thin alias prints a one-line deprecation banner then delegates to /CJ_goal_todo_fix with the same args. Will be removed in v5.0.0. | experimental | standalone | 4.0.0 |

### Deprecated

Skills below remain in the repo for reference but are skipped by `skills-deploy install` by default. Use `skills-deploy install --include-deprecated` to install them anyway.

| Name | Description | Portability | Version |
|------|-------------|-------------|---------|

## Quick Start

```bash
# Clone the repo
git clone https://github.com/jcl2018/claude-skills-templates.git
cd claude-skills-templates

# Validate the repo
./scripts/validate.sh

# Run full test suite
./scripts/test.sh
```

## Installation

### As a Claude Code plugin

```bash
claude plugin install claude-skills-templates@your-marketplace
```

### Via git clone

```bash
git clone https://github.com/jcl2018/claude-skills-templates.git
claude --plugin-dir ./claude-skills-templates
```

## gstack plans live in this repo

Plans, designs, and reviews from gstack skills (`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/context-save`) land at `<repo>/.gstack/` and are committed to git, so PR reviewers see the design intent that produced the code and design history travels alongside code history. Machine-local gstack state (sessions, analytics, learnings) stays out of git via `.gitignore`.

After cloning, wire up the per-machine redirect:

```bash
cd <repo>
./scripts/setup-gstack-symlink.sh
```

This creates a symlink from `~/.gstack/projects/<slug>/` (where gstack writes by default) to `<main-repo>/.gstack/`. Run from the repo root; the script resolves the main checkout via `git rev-parse --git-common-dir` so it works from worktrees too. Reverse with `./scripts/teardown-gstack-symlink.sh`.

See `CLAUDE.md` for the `.gstack/` (lateral/exploratory) vs `work-items/` (structured per-feature) split convention.

## Scripts

| Script | Purpose | Exit code |
|--------|---------|-----------|
| `setup.sh` | Bootstrap: clone-or-update repo and deploy all skills | 1 on error |
| `skills-deploy` | Install/remove/relink/doctor skills from this repo into `~/.claude/` (also deploys `rules/*.md` → `~/.claude/rules/`) | 1 on error |
| `validate.sh` | Catalog-to-filesystem validation | 1 on error |
| `test.sh` | Smoke tests (superset of validate) | 1 on failure |
| `test-deploy.sh` | Automated tests for `skills-deploy` in isolated temp dirs | 1 on failure |
| `collection-version.sh` | Get/bump/manifest for collection version | 1 on error |
| `doctor.sh` | Skill health diagnostics | 0 (advisory) |
| `lint-skill.sh` | Content-level skill linting | 0 (advisory) |
| `deps.sh` | Dependency graph visualization | 0 (advisory) |
| `generate-readme.sh` | Auto-generate this README | 1 on write failure |
| `sync-upstream.sh` | Compare upstream gstack skills | 0 (local-only) |
| `setup-hooks.sh` | Install git hooks (pre-commit validate + post-merge auto-sync). Auto-run by `setup.sh`; run manually only after a direct `git clone` + `skills-deploy install` (that path does not install hooks). | 0 |
| `setup-gstack-symlink.sh` | Per-machine: symlink `~/.gstack/projects/<slug>/` to `<main-repo>/.gstack/` so gstack output commits in git. Idempotent; `--force` to re-point or merge non-empty target. | 1 on error |
| `teardown-gstack-symlink.sh` | Reverse the gstack symlink: restore `~/.gstack/projects/<slug>/` to a real directory. Refuses if the symlink target doesn't match expected. | 1 on wrong target |
| `copilot-deploy.py` | Install/doctor/remove the Copilot bundle in a target repo | 1 on error |
| `skills-update-check` | Passive update detector — emits `SKILLS_UPGRADE_AVAILABLE` banner when origin/main has a newer collection version. Auto-invoked from instrumented skill preambles. | 0 (advisory) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full authoring guide.
