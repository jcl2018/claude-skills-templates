# claude-skills-templates

A doc-first development workbench: a work lifecycle pipeline, doc-contract enforcement, and authoring tooling. It ships from one source of truth to **two delivery surfaces** — Claude Code skills, and a self-contained GitHub Copilot bundle (`work-copilot/`) for machines without Claude. It is deliberately not Claude-skill-only.

## Delivery surfaces

- **`skills/`** — Claude Code skills (the `CJ_` workflow family + utilities), auto-discovered and listed below.
- **`work-copilot/`** — a self-contained **GitHub Copilot** bundle carrying the same work-item templates + `/validate` workflow to non-Claude machines. Deploy with `python3 scripts/copilot-deploy.py install <target>`; see [`work-copilot/README.md`](work-copilot/README.md).

## Skills

| Name | Description | Status | Portability | Version |
|------|-------------|--------|-------------|---------|
| CJ_system-health | ~/.claude/ health dashboard with dependency graph and usage trends. Scans installed skills, builds dependency graph, checks filesystem health, surfaces skill usage analytics with behavioral topology overlay, invokes waza for config hygiene. | active | standalone | 2.0.0 |
| templates | Skill authoring template for new skills. | active | standalone | 0.1.0 |
| CJ_personal-workflow | Personal work item validation. Validates tracker files and work item directories against personal templates and personal-artifact-manifests.json. Templates + WORKFLOW.md are the single source of truth for structural rules. | active | standalone | 4.0.0 |
| CJ_scaffold-work-item | Scaffold a CJ_personal-workflow work item from an /office-hours design doc. Reads design + templates + manifest + WORKFLOW.md, produces a compliant work-item directory tree with all required artifacts. Runs /CJ_personal-workflow check at boundaries; idempotent (re-run on same input is NO-OP). | experimental | standalone | 1.0.0 |
| CJ_qa-work-item | QA a CJ_personal-workflow work-item (user-story, defect, or task) per its test rows. For user-stories: runs Smoke Tests then dispatches a QA engineer subagent (fresh context, 5-min cap) for E2E verification per TEST-SPEC. For defects/tasks: runs test-plan rows as smoke-equivalent (no E2E subagent in v1). Writes findings to tracker journal; transitions Phase 2 qa-owned gates for user-stories; records [qa-pass] for defects/tasks. Idempotent (re-run on green work-item is NO-OP). Boundary check refuses on incomplete Phase 2. | experimental | standalone | 1.0.0 |
| CJ_implement-from-spec | Implement a CJ_personal-workflow work-item (user-story, defect, task, or feature) from its input artifacts. Reads per-type input (SPEC+DESIGN for user-stories, RCA+test-plan for defects, TRACKER+test-plan for tasks; features delegate to a child user-story via AUQ), plans the change against the artifact's Components Affected / Data Flow, writes code via Read/Edit/Write tools. Sensitive-surface AUQ (catalog/manifest/validator). Propose-and-confirm by default; --auto for trivial changes (≤2 files, no sensitive surface). Idempotent (re-run on completed work-item is NO-OP). Boundary check refuses on incomplete Phase 1; verifies post-write compliance. | experimental | standalone | 1.0.0 |
| CJ_suggest | Print a ranked top-5 of next-up work items from TODOS.md and tracker frontmatter. Internal phase-step skill rows (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, *-workflow validators) are filtered by default; pass --include-internal to surface them. Optional --for-skill / --limit flags pre-filter and extend the candidate window for downstream callers like /CJ_goal_todo_fix. | experimental | local-only | 1.2.0 |
| CJ_goal_todo_fix | Auto-resolve TODOs from TODOS.md into shipped PRs (formerly /CJ_goal; renamed v4.0.0; native drain mode added v4.2.0; --quiet added v4.3.0). Default mode (no args) drains up to 10 easy-fix TODOs end-to-end via the /CJ_implement-from-spec → /CJ_qa-work-item → /ship → /land-and-deploy chain — no /loop wrapper needed. Single-TODO mode preserved when arg is T-ID or fragment. --max-drain N caps the loop; --dry-run previews; --quiet suppresses Phase 3 summary AUQ for cron / /schedule consumers (autonomy ceiling preserved — /ship Gate #2 still fires per child). Workbench-only; halt-on-red preserved end-to-end. | active | standalone | 2.2.0 |
| CJ_improve-queue | Workbench self-improvement skill. Three modes: (1) evaluate <url> — fetch an Anthropic best-practices article, classify pattern fit against existing workbench skills via subagent reasoning, append a draft TODOS.md row if novel/conflict. (2) audit — offline repo self-scan for stale skills + missing frontmatter; emits draft rows directly. (3) research <topic> — orchestrator-driven WebSearch + per-result evaluate, with privacy gate. All rows land with <!--impr-draft--> markers; /CJ_suggest skips them until promoted. Workbench-only (macOS); domain allowlist + HTML-comment-wrap defense; mkdir-based write lock; atomic mv; backup rotation. | experimental | standalone | 0.2.0 |
| CJ_goal_defect | Bug-description-to-shipped-fix orchestrator (F000027 `defect` verb; experimental). Takes a plain bug description with NO pre-existing defect dir, scaffolds a throwaway `.inbox/<slug>/DRAFT.md`, root-causes it via /investigate as an Agent subagent (sentinel-wrapped JSON, Iron-Law: no root cause ⇒ HALT, nothing promoted or shipped), then on a populated root cause writes RCA + test-plan, promotes the draft to a canonical `work-items/defects/uncategorized/D000NNN_<slug>/` dir (D-ID minted only after the Iron-Law gate passes), runs /CJ_qa-work-item (leaf subagent), and ships on the proven human-gated tail: /ship (Gate #2 always human) → /land-and-deploy --suppress-readiness-gate. Flat pipeline; depth ≤ 2 (no subagent-spawns-subagent). Consumes scripts/cj-goal-common.sh --mode defect for the deterministic worktree + pr-check phases. Halt taxonomy with next_action= / resume_cmd= / pr_url= journal entries; telemetry appends one JSONL line to ~/.gstack/analytics/CJ_goal_defect.jsonl. --dry-run previews the chain plan + write paths without mutation. Workbench-only (macOS). Drain mode / family-drain lock / --quiet all deferred. Use when: 'fix this bug end-to-end from a description', 'bug report to deployed fix', 'root-cause and ship a fix'. | experimental | standalone | 0.1.0 |
| CJ_goal_feature | One-line-topic-to-reviewable-PR feature orchestrator (F000027 `feature` verb; experimental). Takes a plain feature topic, creates a `cj-feat-*` worktree, runs /office-hours INLINE (the one interactive design phase; emits an APPROVED design doc — on not-APPROVED/abandoned it HALTs), then shows a design-summary approval gate in chat (a concise digest of the APPROVED doc + a single go/no-go before the autonomous build budget is spent — Abort HALTs as halted_at_design_gate and preserves the doc for resume), then SILENTLY (zero AUQ past the gate) dispatches /CJ_scaffold-work-item → /CJ_implement-from-spec → /CJ_qa-work-item as depth-≤2 leaf Agent subagents, and runs /ship INLINE with the diff-review AUQ suppressed to open a PR — then STOPs at the PR. The PR is the architecture gate (human review). No plan-review phase, no automatic merge, no /land-and-deploy (deploy is a separate human step). Strengthened resume: a state file records `last_completed_phase` + per-phase HEAD SHA + PR number and validates-before-skipping (recorded SHA must be ancestor-of/equal-to current HEAD AND any open PR must still be OPEN, else the affected phase restarts); office-hours resume re-locates the doc by the RECORDED PATH and re-confirms `Status: APPROVED` rather than a blind newest-glob; the design-summary gate re-fires on resume while still parked at the office-hours boundary and is skipped once the build has progressed. Consumes scripts/cj-goal-common.sh --mode feature for the deterministic worktree + pr-check phases; telemetry appends one JSONL line to ~/.gstack/analytics/CJ_goal_feature.jsonl. Halt taxonomy (green_pr_opened, halted_at_officehours/design_gate/scaffold/impl/qa/ship, already_shipped) with next_action= / resume_cmd= / pr_url= journal entries. --dry-run previews the chain plan without mutation. Workbench-only (macOS). An automatic merge-and-deploy path is unsafe-by-construction here (the handoff-gate denylist blocks exactly the skill surfaces every feature touches) and is parked, not deferred. Use when: 'build this feature end-to-end from a topic', 'one-line idea to a reviewable PR', 'scaffold + implement + qa from a topic and stop at the PR'. | experimental | standalone | 0.2.0 |
| CJ_document-release | Workbench wrapper around upstream gstack /document-release (upstream skill, not in this catalog — invoked via Skill tool). Adds a --docs <comma-list> subset flag for per-invocation doc filtering (best-effort, documentation-only), a halt-on-red contract that emits [doc-sync-red] on upstream failure, and an auto-commit step gated by a per-repo doc-only whitelist (non-whitelist writes HALT with [doc-sync-non-doc-write]). F000037: whitelist + --docs categories load from a strict-required cj-document-release.json at repo root; missing/invalid config HALTs with [doc-sync-no-config] BEFORE any audit. Invoked inline by the 3 cj_goal orchestrators (CJ_goal_feature / CJ_goal_defect / CJ_goal_todo_fix) at Step 5.5 — between QA pass and /ship — so doc updates fold into the same code PR rather than chasing them post-merge. | experimental | workbench | 0.1.0 |
| CJ_repo-init | Detect which CJ_ skills are deployed, verify each one's per-repo prerequisites (cj-document-release.json, CJ-DOC-RELEASE.md, TODOS.md, work-items/ tree), print a health table, and on one confirm scaffold the missing repo-level prerequisites from generic portable seeds. Standalone utility — in-place, no worktree/ship. Use when: 'set up this repo for the CJ skills', 'init repo prerequisites', 'make this repo ready for CJ_', 'bootstrap repo config', 'verify repo prerequisites'. | experimental | standalone | 0.1.0 |
| CJ_portability-audit | Static dependency lint for declared skill portability. Compares each catalog skill's declared portability field against its ACTUAL executed repo-local dependencies (root scripts/*.sh helpers, root config, CLAUDE.md, the manifest .source reach-back) using a strict tier ladder (standalone < local-only < workbench), an EXECUTED-vs-documented precision rule, bundled-own-script + scoped self-resolution-preamble carve-outs, and an optional portability_requires accepted-deps field. Emits a per-skill verdict (portable / portable-with-notes / findings:<list>). Engine-in-script (scripts/cj-portability-audit.sh, resolved repo-local-first then via .source); also wired into validate.sh as an advisory check (exit 0 in v1; PORTABILITY_STRICT=1 flips to hard-fail). Workbench-only. Use when: 'audit skill portability', 'check declared-vs-actual dependencies', 'is this skill really standalone'. | experimental | workbench | 0.1.0 |

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

## Running on Windows

The workbench is POSIX-shell software. On Windows it runs two ways:

- **WSL2 (recommended).** A real Linux environment — everything behaves exactly as on macOS/Linux, including symlink-based `skills-deploy install`.
- **Git Bash (supported).** The bash that ships with [Git for Windows](https://gitforwindows.org/) — the same shell Claude Code uses to run skill preambles on Windows. Real symlinks are unavailable there, so `skills-deploy install` automatically falls back to **copy-mode** (real files + checksum-tracked drift detection) instead of symlinks.

**Prerequisites** (both paths): `git`, `jq`, `gh`, and `python3` (the last only for the Copilot bundle / `copilot-deploy.py`). On Git Bash, `git` and `jq` come with Git for Windows; install `gh` from [cli.github.com](https://cli.github.com/).

Line endings are pinned to LF by `.gitattributes` (`* text=auto eol=lf`), so shell scripts stay runnable under bash even when `core.autocrlf` is on. A `windows-latest` CI job (`.github/workflows/windows.yml`) runs the Windows-relevant test subset under Git Bash on every PR, so Windows support is exercised continuously. Run the same checks locally with `bash scripts/windows-smoke.sh`.

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
| `setup-hooks.sh` | Install pre-commit hook | 0 |
| `setup-gstack-symlink.sh` | Per-machine: symlink `~/.gstack/projects/<slug>/` to `<main-repo>/.gstack/` so gstack output commits in git. Idempotent; `--force` to re-point or merge non-empty target. | 1 on error |
| `teardown-gstack-symlink.sh` | Reverse the gstack symlink: restore `~/.gstack/projects/<slug>/` to a real directory. Refuses if the symlink target doesn't match expected. | 1 on wrong target |
| `copilot-deploy.py` | Install/doctor/remove the Copilot bundle in a target repo | 1 on error |
| `skills-update-check` | Passive update detector — emits `SKILLS_UPGRADE_AVAILABLE` banner when origin/main has a newer collection version. Auto-invoked from instrumented skill preambles. | 0 (advisory) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full authoring guide.
