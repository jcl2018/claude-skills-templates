---
name: "work-copilot pipeline"
type: feature
id: "F000015"
status: active
created: "2026-05-11"
updated: "2026-05-11"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/work_copilot_pipeline`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] All 6 prompts shipped under `work-copilot/prompts/` and deployed via `copilot-deploy install` to a target repo.
- [ ] `.github/work-copilot/domain/` skeleton folder authored; skeletons land on first install; filled-in content survives re-installs.
- [ ] A single work-item can be walked end-to-end (investigate → scaffold → implement → qa → ship → pipeline) in Copilot Chat, with each phase writing a valid receipt block.
- [ ] `/wc-pipeline` prints accurate drift math against a hand-crafted "drifted" fixture work-item (commits ahead of receipts; uncovered ACs; changed files without tests).
- [ ] `validate.sh` existence check added for `work-copilot/prompts/*.prompt.md` and `work-copilot/domain/*.template.md`; the existing `MIRROR_SPECS` invariant continues to propagate the `tracker-*.md` `receipts: {}` stub from `deprecated/CJ_company-workflow/templates/` to `work-copilot/templates/`.
- [ ] `.github/copilot-instructions.md` updated with a "Pipeline commands" section enumerating all 6 new slash commands and recommended invocation order.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Schema prerequisite — add `receipts: {}` stub to `deprecated/CJ_company-workflow/templates/tracker-*.md`; MIRROR_SPECS propagates to `work-copilot/templates/`.
- [ ] Add existence check to `validate.sh` for `work-copilot/prompts/*.prompt.md` and `work-copilot/domain/*.template.md`.
- [ ] S000030 — `/wc-qa` (build #1, schema-locking).
- [ ] S000031 — `/wc-implement` (build #2).
- [ ] S000032 — `/wc-scaffold` (build #3).
- [ ] S000033 — `/wc-investigate` (build #4) + 3 domain skeleton templates + `copilot-deploy.py` first-install rule.
- [ ] S000034 — `/wc-ship` (build #5).
- [ ] S000035 — `/wc-pipeline` (build #6, status compiler).
- [ ] (Parallel follow-up) File `T0NNNNN_template_trim` work item (P2 — not a blocker).
- [ ] Update `.github/copilot-instructions.md` "Pipeline commands" section.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-11: Created. Feature scaffolded from /office-hours design `chjiang-claude-zealous-antonelli-5f8036-design-20260511-095218.md`. Approach C (all 6 prompts, /qa-first bottom-up) chosen; 6 user-story children scaffolded under this feature.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `work-copilot/prompts/qa.prompt.md` (S000030 — new)
- `work-copilot/prompts/implement.prompt.md` (S000031 — new)
- `work-copilot/prompts/scaffold.prompt.md` (S000032 — new)
- `work-copilot/prompts/investigate.prompt.md` (S000033 — new)
- `work-copilot/prompts/ship.prompt.md` (S000034 — new)
- `work-copilot/prompts/pipeline.prompt.md` (S000035 — new)
- `work-copilot/domain/domain-knowledge.template.md` (S000033 — new)
- `work-copilot/domain/coding-conventions.template.md` (S000033 — new)
- `work-copilot/domain/architecture-overview.template.md` (S000033 — new)
- `deprecated/CJ_company-workflow/templates/tracker-*.md` (modified — `receipts: {}` stub)
- `scripts/copilot-deploy.py` (modified — first-install-only rule + `designs/` `.gitkeep` creation)
- `scripts/validate.sh` (modified — new existence check)
- `.github/copilot-instructions.md` (in target repo — modified during install)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Codex's reframe: Copilot's no-subagent constraint becomes a feature when the work-item folder is treated as a **visible state machine** with receipts in tracker frontmatter. The orchestrator becomes a status compiler, not a macro. "Steal the mental model from /CJ_personal-pipeline, not the runtime."
- Recipe UX (5 clicks) is the right tradeoff — legible leverage over autonomy theater. Future single-keystroke = thin printer over the same 5 leaves, not refactor.
- /qa-first build order locks the receipt schema early; downstream prompts conform to a real contract instead of guessing at one.
- Receipts are an orthogonal state surface to /validate. /validate gates structural drift; receipts gate phase progression and drift math. P4 revised to make this explicit.
- Drift math is binary "HEAD has moved past receipts.implement.latest_sha_at_implement" (no count) because counting commits requires `git log`, and Copilot prompts have no shell — only file reads via the `codebase` tool.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-11: Adopted Approach C (all 6 prompts, /qa-first bottom-up). Vs. B (forward top-down): /qa built late means /scaffold and /implement guess at receipts; rework risk. Vs. A (minimal v1, no /investigate): user explicitly asked for the investigate-equivalent. Full scope from v1 is the right call when build order is reliable.
- [decision] 2026-05-11: Receipt schema lives in tracker YAML frontmatter under a top-level `receipts:` key; /wc-investigate uses design-doc frontmatter (since no tracker exists yet); /wc-scaffold copies receipts.investigate into the new tracker.
- [decision] 2026-05-11: User-paste pattern for all git access (no `runCommands` MCP dep). Five touch points: `git rev-parse HEAD`, `git log --oneline <sha>..HEAD`, `git log --name-only --since=<ts> --pretty=format:''`, `git status --porcelain -- <files>`, plus `.git/HEAD` file read via `codebase` tool for the binary stale check.
- [decision] 2026-05-11: Domain folder is per-target-repo user data (P3). `copilot-deploy install` writes skeletons on first install (`.template.md`) and never overwrites filled content. Domain files are NOT byte-mirrored from the workbench.
- [decision] 2026-05-11: No new `MIRROR_SPECS` entries. The 6 new prompts and 3 domain skeletons are `work-copilot/`-only (no deprecated-source counterpart). A separate existence check in `validate.sh` covers them.
- [decision] 2026-05-11: Working-Tree Rule UX — hard-stop for `/wc-implement` and `/wc-qa`; warn-and-write for `/wc-ship` (synthesized PR description is useful even with an unpushed tree). `/wc-scaffold` exception: writes despite uncommitted work-item dir because the dir it just authored will always be dirty; `pending_commit: true` flag in receipts.scaffold flips to false on first /wc-implement.
