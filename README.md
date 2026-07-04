# claude-skills-templates

A doc-first development workbench: a work lifecycle pipeline, doc-contract enforcement, and authoring tooling. It ships from one source of truth to **two delivery surfaces** — Claude Code skills, and a self-contained GitHub Copilot bundle (`work-copilot/`) for machines without Claude. It is deliberately not Claude-skill-only.

## Delivery surfaces

- **`skills/`** — Claude Code skills (the `CJ_` workflow family + utilities), auto-discovered and listed below.
- **`work-copilot/`** — a self-contained **GitHub Copilot** bundle carrying the same work-item templates + `/validate` workflow to non-Claude machines. Deploy with `python3 scripts/copilot-deploy.py install <target>`; see [`work-copilot/README.md`](work-copilot/README.md).

## Repository layout

```
.
├── spec/               # machine registries (doc-spec + doc-spec-custom / permission-policy / test-spec + test-spec-custom)
├── docs/                # human docs (workflow.md index + workflows/, philosophy.md, architecture.md)
├── skills/              # Claude Code skills (the CJ_ family + utilities)
├── templates/           # work-item + doc authoring templates
├── work-copilot/        # the GitHub Copilot delivery bundle (Python-CLI deployed)
├── scripts/             # validate / test / deploy / helper scripts
├── work-items/          # the structured per-feature work tree (features, defects, tasks)
├── tests/               # the registered test suites (see spec/test-spec-custom.md)
├── deprecated/          # retired skills + their work-item history (kept for provenance)
├── rules/               # skill-routing rules deployed to ~/.claude/rules/
├── CLAUDE.md            # agent operating instructions (auto-loaded by Claude Code)
├── CONTRIBUTING.md      # contributor authoring guide
├── CHANGELOG.md         # release history
└── TODOS.md             # operational backlog
```

For the full doc map (and the machine registry the validator parses), see [`spec/doc-spec.md`](spec/doc-spec.md).

## Skills

| Name | Description | Status | Portability | Version |
|------|-------------|--------|-------------|---------|
| CJ_system-health | ~/.claude/ health dashboard with dependency graph and usage trends. Scans installed skills, builds dependency graph, checks filesystem health, surfaces skill usage analytics with behavioral topology overlay, invokes waza for config hygiene. | active | standalone | 2.0.0 |
| templates | Skill authoring template for new skills. | active | standalone | 0.1.0 |
| CJ_personal-workflow | Personal work item validation. Validates tracker files and work item directories against personal templates and personal-artifact-manifests.json. Templates + WORKFLOW.md are the single source of truth for structural rules. | active | workbench | 4.0.0 |
| CJ_scaffold-work-item | Scaffold a CJ_personal-workflow work item from an /office-hours design doc. Reads design + templates + manifest + WORKFLOW.md, produces a compliant work-item directory tree with all required artifacts. Runs /CJ_personal-workflow check at boundaries; idempotent (re-run on same input is NO-OP). | experimental | standalone | 1.0.1 |
| CJ_qa-work-item | QA a CJ_personal-workflow work-item (user-story, defect, or task) per its test rows. For user-stories: runs Smoke Tests then dispatches a QA engineer subagent (fresh context, 5-min cap) for E2E verification per TEST-SPEC. For defects/tasks: runs test-plan rows as smoke-equivalent (no E2E subagent in v1). Every green path then reaches the Step 8.6 audit block: it ALWAYS refreshes spec/test-spec-custom.md + spec/doc-spec-custom.md inline, then runs the agent-judged /CJ_doc_audit + /CJ_test_audit INLINE only for standalone runs (findings ride the GREEN RESULT's AUDITS= field + a fenced AUDIT_FINDINGS block — never flipping QA red); under an orchestrator the dispatch carries DEFER_AUDIT: true so the inline agent-judged audit is SKIPPED (AUDITS=deferred) — that audit now runs on-demand (via /CJ_doc_audit + /CJ_test_audit, or scripts/audit-nightly.sh), off the build path. Writes findings to tracker journal; transitions Phase 2 qa-owned gates for user-stories; records [qa-pass] for defects/tasks. Idempotent (re-run on green work-item is NO-OP). Boundary check refuses on incomplete Phase 2. | experimental | standalone | 1.0.0 |
| CJ_implement-from-spec | Implement a CJ_personal-workflow work-item (user-story, defect, task, or feature) from its input artifacts. Reads per-type input (SPEC+DESIGN for user-stories, RCA+test-plan for defects, TRACKER+test-plan for tasks; features delegate to a child user-story via AUQ), plans the change against the artifact's Components Affected / Data Flow, writes code via Read/Edit/Write tools. Sensitive-surface AUQ (catalog/manifest/validator). Propose-and-confirm by default; --auto for trivial changes (≤2 files, no sensitive surface). Idempotent (re-run on completed work-item is NO-OP). Boundary check refuses on incomplete Phase 1; verifies post-write compliance. | experimental | standalone | 1.0.0 |
| CJ_suggest | Print a ranked top-5 of next-up work items from TODOS.md and tracker frontmatter. Internal phase-step skill rows (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, *-workflow validators) are filtered by default; pass --include-internal to surface them. Optional --for-skill / --limit flags pre-filter and extend the candidate window for downstream callers like /CJ_goal_todo_fix. | experimental | local-only | 1.2.0 |
| CJ_goal_todo_fix | Auto-resolve TODOs from TODOS.md into shipped PRs (formerly /CJ_goal; renamed v4.0.0; native drain mode added v4.2.0; --quiet added v4.3.0). Default mode (no args) drains up to 10 easy-fix TODOs end-to-end via the /CJ_implement-from-spec → /CJ_qa-work-item (DEFER_AUDIT: true — the agent-judged doc/test audit is skipped inline and runs on-demand off the build path instead) → /CJ_document-release → /ship → /land-and-deploy chain — no /loop wrapper needed. The deterministic per-PR gate (validate.sh / validate.yml / pre-commit) is unchanged and still halts a broken change. Single-TODO mode preserved when arg is T-ID or fragment. --max-drain N caps the loop; --dry-run previews; --quiet suppresses Phase 3 summary AUQ for cron / /schedule consumers (autonomy ceiling preserved — /ship Gate #2 still fires per child). Workbench-only; halt-on-red preserved end-to-end. | active | local-only | 2.2.0 |
| CJ_improve-queue | Workbench self-improvement skill. Three modes: (1) evaluate <url> — fetch an Anthropic best-practices article, classify pattern fit against existing workbench skills via subagent reasoning, append a draft TODOS.md row if novel/conflict. (2) audit — offline repo self-scan for stale skills + missing frontmatter; emits draft rows directly. (3) research <topic> — orchestrator-driven WebSearch + per-result evaluate, with privacy gate. All rows land with <!--impr-draft--> markers; /CJ_suggest skips them until promoted. Workbench-only (macOS); domain allowlist + HTML-comment-wrap defense; mkdir-based write lock; atomic mv; backup rotation. | experimental | standalone | 0.2.0 |
| CJ_goal_defect | Bug-description-to-shipped-fix orchestrator (the `defect` verb; experimental). Takes a plain bug description with NO pre-existing defect dir, scaffolds a throwaway `.inbox/<slug>/DRAFT.md`, root-causes it via /investigate as an Agent subagent (sentinel-wrapped JSON, Iron-Law: no root cause ⇒ HALT, nothing promoted or shipped), then on a populated root cause writes RCA + test-plan, promotes the draft to a canonical `work-items/defects/uncategorized/D000NNN_<slug>/` dir (D-ID minted only after the Iron-Law gate passes), runs /CJ_qa-work-item (leaf subagent, DEFER_AUDIT: true — the agent-judged doc/test audit is skipped inline and runs on-demand off the build path instead; the deterministic per-PR gate via validate.sh is unchanged), folds doc updates via /CJ_document-release, and ships on the proven human-gated tail: /ship (Gate #2 always human) → /land-and-deploy --suppress-readiness-gate. Flat pipeline; depth ≤ 2 (no subagent-spawns-subagent). Consumes scripts/cj-goal-common.sh --mode defect for the deterministic worktree + pr-check phases. Halt taxonomy with next_action= / resume_cmd= / pr_url= journal entries; telemetry appends one JSONL line to ~/.gstack/analytics/CJ_goal_defect.jsonl. --dry-run previews the chain plan + write paths without mutation. Workbench-only (macOS). Drain mode / family-drain lock / --quiet all deferred. Use when: 'fix this bug end-to-end from a description', 'bug report to deployed fix', 'root-cause and ship a fix'. | experimental | local-only | 0.1.0 |
| CJ_goal_feature | One-line-topic-to-reviewable-PR feature orchestrator (the `feature` verb; experimental). Takes a plain feature topic, creates a `cj-feat-*` worktree, runs /office-hours INLINE (the one interactive design phase; emits an APPROVED design doc — on not-APPROVED/abandoned it HALTs), then shows a design-summary approval gate in chat (a concise digest of the APPROVED doc + a single go/no-go before the autonomous build budget is spent — Abort HALTs as halted_at_design_gate and preserves the doc for resume), then SILENTLY (past the gate) dispatches /CJ_scaffold-work-item → /CJ_implement-from-spec → /CJ_qa-work-item (DEFER_AUDIT: true — the agent-judged doc/test audit is skipped inline and runs on-demand off the build path instead) as depth-≤2 leaf Agent subagents, folds doc updates via /CJ_document-release INLINE, and runs /ship INLINE with the diff-review AUQ suppressed to open a PR — then STOPs at the PR. The deterministic per-PR gate (validate.sh) is unchanged and still halts a broken change. The PR is the architecture gate (human review). No plan-review phase, no automatic merge, no /land-and-deploy (deploy is a separate human step). Strengthened resume: a state file records `last_completed_phase` + per-phase HEAD SHA + PR number and validates-before-skipping (recorded SHA must be ancestor-of/equal-to current HEAD AND any open PR must still be OPEN, else the affected phase restarts); office-hours resume re-locates the doc by the RECORDED PATH and re-confirms `Status: APPROVED` rather than a blind newest-glob; the design-summary gate re-fires on resume while still parked at the office-hours boundary and is skipped once the build has progressed. Consumes scripts/cj-goal-common.sh --mode feature for the deterministic worktree + pr-check phases; telemetry appends one JSONL line to ~/.gstack/analytics/CJ_goal_feature.jsonl. Halt taxonomy (green_pr_opened, halted_at_officehours/design_gate/scaffold/impl/qa/doc_sync/ship, already_shipped) with next_action= / resume_cmd= / pr_url= journal entries. --dry-run previews the chain plan without mutation. Workbench-only (macOS). An automatic merge-and-deploy path is unsafe-by-construction here (the handoff-gate denylist blocks exactly the skill surfaces every feature touches) and is parked, not deferred. Use when: 'build this feature end-to-end from a topic', 'one-line idea to a reviewable PR', 'scaffold + implement + qa from a topic and stop at the PR'. | experimental | local-only | 0.2.0 |
| CJ_goal_task | Small-ad-hoc-task-to-reviewable-PR orchestrator (the `task` verb; experimental). The lightweight sibling of /CJ_goal_feature: takes a plain free-text `"<small task>"` (refine a doc, add a file, clean up files, a one-line fix), runs a HARD complexity gate (refuses design-rework topics → routes to /CJ_goal_feature, refuses bug/investigation topics → routes to /CJ_goal_defect, refuses explicit-large-scope topics; HALTs as halted_at_too_complex), creates a `cj-task-*` worktree, then SILENTLY bash-scaffolds a `type: task` work-item (T-ID) directly from the topic via scripts/cj-task-scaffold.sh — NO /office-hours, NO design doc, NO pre-existing TODOS row — and dispatches /CJ_implement-from-spec → /CJ_qa-work-item (DEFER_AUDIT: true — the agent-judged doc/test audit is skipped inline and runs on-demand off the build path instead) as depth-≤2 leaf Agent subagents, folds doc updates via /CJ_document-release INLINE (doc-sync; halt-on-red), and runs /ship INLINE with the diff-review AUQ suppressed to open a PR — then STOPs at the PR. The deterministic per-PR gate (validate.sh) is unchanged and still halts a broken change. PR-stop only (like /CJ_goal_feature): no automatic merge, no /land-and-deploy; the PR is the review. Strengthened resume: a state file records `last_completed_phase` + per-phase HEAD SHA + work-item dir + PR number and validates-before-skipping; QA always re-runs on resume. Consumes scripts/cj-goal-common.sh --mode task for the deterministic worktree / sync / pr-check / cleanup phases; telemetry appends one JSONL line to ~/.gstack/analytics/CJ_goal_task.jsonl. Halt taxonomy (green_pr_opened, halted_at_too_complex/not_isolated/scaffold/impl/qa/doc_sync/ship, already_shipped) with next_action= / resume_cmd= / pr_url= journal entries. --dry-run previews the chain plan without mutation. Workbench-only (macOS). Use when: 'do this small task end-to-end', 'refine a doc / add a file / clean up files to a PR', 'fix this small thing and stop at the PR', 'a small ad-hoc cleanup that does not need design or investigation'. | experimental | local-only | 0.1.0 |
| CJ_document-release | Workbench wrapper around upstream gstack /document-release (upstream skill, not in this catalog — invoked via Skill tool). Adds a --docs <comma-list> subset flag for per-invocation doc filtering (best-effort, documentation-only), a halt-on-red contract that emits [doc-sync-red] on upstream failure, and an auto-commit step gated by a doc-only whitelist DERIVED from the doc-spec.md registry (non-whitelist writes HALT with [doc-sync-non-doc-write]). Reads the MERGED two-tier registry (general spec/doc-spec.md, resolved spec/-then-root, + the optional spec/doc-spec-custom.md overlay; self-bootstraps a missing general file from the portable seed INTO spec/doc-spec.md; stub-scaffolds missing declared docs — spec/test-spec.md special-cased via test-spec.sh --seed); a missing/invalid registry HALTs with [doc-sync-no-config] BEFORE any audit. Invoked inline by the cj_goal orchestrators at Step 5.5 — between the QA pass and /ship — so doc updates fold into the same code PR rather than chasing them post-merge. | experimental | local-only | 0.1.0 |
| CJ_portability-audit | Static dependency lint for declared skill portability. Compares each catalog skill's declared portability field against its ACTUAL executed repo-local dependencies (root scripts/*.sh helpers, root config, CLAUDE.md, the manifest .source reach-back) using a strict tier ladder (standalone < local-only < workbench), an EXECUTED-vs-documented precision rule, bundled-own-script + scoped self-resolution-preamble carve-outs, and an optional portability_requires accepted-deps field. Emits a per-skill verdict (portable / portable-with-notes / findings:<list>). Engine-in-script (scripts/cj-portability-audit.sh, resolved repo-local-first then via .source); also wired into validate.sh as Check 18 (strict-by-default — a finding hard-fails; PORTABILITY_STRICT=0 downgrades to advisory). Workbench-only. Use when: 'audit skill portability', 'check declared-vs-actual dependencies', 'is this skill really standalone'. | experimental | workbench | 0.1.0 |
| CJ_doc_audit | Three-stage doc audit against a repo's doc contract — runnable standalone in ANY repo. Ensures the two-tier doc contract is CANONICAL via doc-spec.sh --classify: absent → seed-deliver spec/doc-spec.md (seeded: yes; idempotent seeded: no on re-run); canonical → ok; legacy/duplicate → an advisory RECONCILE: directive in the Stage-1 report (NO auto-write; run /CJ_doc_audit --reconcile to migrate a legacy yaml registry to the canonical 3-column Markdown table preserving every row). Stage 1 (deterministic — engine): doc-spec.sh --check-on-disk (declared-exists, orphans, root-declared, human-doc-ids vs the MERGED registry — four checks), printed verbatim, PLUS the workflow-docs freshness check (workflow-spec.sh --render-docs --check when the engine is present — the generated docs/workflow.md + docs/workflows/ surface, the same owner validate.sh Check 27 calls; stage1/workflow-render); pre-stage failures count as stage1/engine|seed|registry. Stage 2 (requirement compliance — agent-judged, evidence-forced): each declared doc's requirement: quoted, decomposed into clauses, verdicts satisfies | missing-requirement (soft) | n/a | FINDING: stage2/<path> with cited evidence. Stage 3 (implementation drift — agent-judged): ground-truth enumeration FIRST (catalog skills, scripts, workflows, spec family, dirs), then a per-doc cross-walk; docs/workflow.md + docs/workflows/ are recognized as a GENERATED surface (sourced from spec/workflow-spec.md), never an orphan/drift; verdicts no-drift | FINDING: stage3/<path> — <named delta>. Standalone runs MUST dispatch Stages 2+3 to ONE fresh-context subagent (Agent tool); inside a QA subagent (qa.md Step 8.6c) they run INLINE (a subagent cannot spawn subagents). Per-stage report: DOC_AUDIT: <ok|findings> + FINDINGS= + STAGE1/2/3_FINDINGS= + DOCS_AUDITED= + seeded: + three --- stage N --- sections. Findings (and the RECONCILE directive) never crash the audit — a broken contract IS the report. Engine resolution repo-local scripts/doc-spec.sh then ~/.claude/_cj-shared/scripts/. Use when: 'audit this repo's docs', 'check doc hygiene', 'does this repo follow its doc contract'. | experimental | local-only | 0.3.0 |
| CJ_test_audit | Three-stage test audit against a repo's test contract — runnable standalone in ANY repo. Ensures the two-tier test contract is CANONICAL via test-spec.sh --classify: absent → seed-deliver spec/test-spec.md (seeded: yes; idempotent seeded: no on re-run); canonical → ok; duplicate → an advisory RECONCILE: directive in the Stage-1 report (NO auto-write; run /CJ_test_audit --reconcile — a dedup/no-op, since test-spec's fenced-yaml format never diverged, so unlike doc-spec there is no legacy migration). Stage 1 (deterministic — engine): test-spec.sh --validate + --check-coverage (forward anchor-grep per unit, reverse sweep of live surfaces, >=20-token floor — all units-gated, so a rules-only consumer repo gets a named 'coverage cross-check inactive' note, never a misleading finding) PLUS, when the engine carries them, --render-docs --check (the generated docs/tests/ test-catalog freshness gate, the same owner validate.sh Check 26 calls — so a stale catalog is caught standalone in any repo) and --check-workflow-coverage (the forward+reverse workflow-coverage gate, the same owner validate.sh Check 28 calls — so a documented-but-untested CJ_goal_* orchestrator is caught standalone), findings prefixed stage1/. Stage 2 (requirement compliance — agent-judged, evidence-forced): each general RULE's statement quoted and judged with cited evidence (suite-green cites the freshest full-suite run; new-code-tested cites the diff-vs-units comparison), each overlay UNIT's purpose/label judged for truthfulness against the source at its anchor (the anchor-greps-while-the-description-rots catch), AND — when the overlay declares the behavior-coverage axis — each declared BEHAVIOR judged for substance the deterministic check can't reach (statement falsifiable/specific? level correct? linked test proves vs merely mentions? one broad test over-claimed?), findings prefixed stage2/behavior:&lt;id&gt;. Stage 3 (implementation drift — agent-judged): enumerate live verification surfaces (tests on disk, validate banners, workflows, hooks), judge coverage-in-substance — a unit row that no longer reflects reality, or a NEW surface class the rules don't contemplate. Stage 1 ALSO carries the category-based test contract: --check-structure runs the six structural checks a-f (tests/ folder, one per-category tests/<category>/ subfolder for each DISTINCT declared category — taxonomy V2 {workflow, CI-push, CI-nightly}, derived from the overlay's categories: rows so a repo that declares no nightly test is never forced to create an empty tests/CI-nightly/, a category-scoped spec, one docs/tests/<category>/<name>.md per declared test, a docs/tests/ INDEX, and check (f) — the front-door rule — each per-test doc carries the three sections '## What it is' / '## How to run' / '## Explanation') as findings-not-crashes, preceded by an idempotent --seed-docs that seeds missing per-test doc stubs (already carrying the three front-door sections) + the index (present => skip) but NEVER moves test scripts — standalone-safe on a repo it does not own; an unadopted repo reports the honest 'category contract not adopted / inactive' note. Stage 2 ALSO judges each per-test category doc's front-door content is TRUTHFUL (the '## How to run' command matches the declared command; the What it is / Explanation are accurate and the family cross-link resolves). Standalone runs MUST dispatch Stages 2+3 to ONE fresh-context subagent (Agent tool; the same subagent MAY judge both audits when run together); inside a QA subagent (qa.md Step 8.6d) they run INLINE (a subagent cannot spawn subagents). Per-stage report: TEST_AUDIT: <ok|findings> + FINDINGS= + STAGE1/2/3_FINDINGS= + UNITS_AUDITED= + seeded: + three --- stage N --- sections. Findings never crash the audit — a broken contract IS the report. Engine resolution repo-local scripts/test-spec.sh then ~/.claude/_cj-shared/scripts/. Use when: 'audit this repo's tests', 'are tests aligned with the test spec', 'check the test coverage contract'. | experimental | local-only | 0.4.0 |
| CJ_test_run | Execute a repo's test contract and report evidence-derived pass/fail — the 'does it pass?' companion to /CJ_test_audit's 'is it wired?'. Runs a deterministic Stage-1 audit pre-step (the four test-spec.sh engine calls — --validate / --check-coverage / --render-docs --check / --check-workflow-coverage — printed verbatim, with the invalid-registry-HALTS / valid-with-findings-surface-and-continue / absent-registry-SKIP split), then scripts/test-run.sh which reads the runners: axis of the merged test-spec registry and runs the selected tier's runners ONCE each (default tier: free; --evals adds paid, --e2e adds local-only, --all everything — a default run NEVER touches a model), then narrates the materialized report (tests/test-run/reports/<UTC-ts>.md) + machine-readable ledger (.json: schema 1, timestamp, HEAD SHA, aggregate, per-runner rc/outcome/covered-families). Aggregate is the closed enum {pass, fail, all-skipped}: any executed runner failing => fail + exit 1; >=1 green and none failed => pass; zero executed => all-skipped (NEVER rendered pass). Registry edges are honest: absent => REGISTRY=absent + exit 0; invalid => the [test-spec-no-config] passthrough + exit 1; valid with zero runners => 'SKIP: no runners declared' + exit 0 (no report, no ledger, no inference). Two selection modes: the default runners mode runs the whole tiered suite; category mode (--category <workflow|CI-push|CI-nightly> or a single test NAME) runs exactly the category's / named test's command(s) from the categories: axis, reusing the docs/tests/<category>/<name>.md name — that per-test doc is the test's authoritative What/How/Why front door, and a single-name run surfaces/links its '## How to run' so the executed and documented command agree — and honoring the SAME cost tiers (a default run touches no paid model; a paid/local-only test is skip(tier-not-selected) without --evals/--e2e/--all); an unadopted repo reports 'category contract not adopted / inactive'. Runnable in ANY repo the skills are installed for; engines resolve sibling-in-scriptdir -> $REPO_ROOT/scripts/ -> deployed _cj-shared. Use when: 'run the tests', 'do the tests pass', 'execute the test suite'. | experimental | local-only | 0.2.0 |

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

## Getting started: the major workflows

Once the skills are installed (see Installation below), the workbench is driven by
a handful of `CJ_` front doors. Pick by what you have in hand:

| You have... | Run | What it does |
|-------------|-----|--------------|
| A one-line feature topic | `/CJ_goal_feature "<topic>"` | Designs, scaffolds, implements, QAs, and opens a reviewable PR — stops at the PR for human review. |
| A bug description | `/CJ_goal_defect "<bug>"` | Root-causes it, writes the fix + tests, and ships the deployed fix. |
| A `TODOS.md` backlog to drain | `/CJ_goal_todo_fix` | Drains shippable TODO rows into PRs (one, or up to N in drain mode). |
| "What should I work on?" | `/CJ_suggest` | Prints a ranked top-5 of next-up work items. |
| "Is my `~/.claude/` healthy?" | `/CJ_system-health` | A read-only health dashboard for the install. |

Every front door converges on the same `/ship` → `/land-and-deploy` tail. For the
full per-workflow charts see [`docs/workflows/`](docs/workflows/), indexed from
[`docs/workflow.md`](docs/workflow.md); for the routing decision tree see
[`docs/philosophy.md`](docs/philosophy.md).

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
| `cj-hook-lib.sh` | Shared git-hook install library (`cj_install_hook`) — the one clobber-safe, sentinel-aware hook installer both `setup-hooks.sh` and `skills-deploy` source | sourced (no standalone exit) |
| `cj-contract-gate.sh` | Deterministic Stage-1 contract gate — the engine-only subset of `validate.sh` (doc/test/workflow contracts); runnable with no agent from a pre-commit hook or CI. HARD except a soft `declared-exists` remediation; registry-absent ⇒ SKIP | 1 on a hard finding |
| `setup-gstack-symlink.sh` | Per-machine: symlink `~/.gstack/projects/<slug>/` to `<main-repo>/.gstack/` so gstack output commits in git. Idempotent; `--force` to re-point or merge non-empty target. | 1 on error |
| `teardown-gstack-symlink.sh` | Reverse the gstack symlink: restore `~/.gstack/projects/<slug>/` to a real directory. Refuses if the symlink target doesn't match expected. | 1 on wrong target |
| `copilot-deploy.py` | Install/doctor/remove the Copilot bundle in a target repo | 1 on error |
| `skills-update-check` | Passive update detector — emits `SKILLS_UPGRADE_AVAILABLE` banner when origin/main has a newer collection version. Auto-invoked from instrumented skill preambles. | 0 (advisory) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full authoring guide.
