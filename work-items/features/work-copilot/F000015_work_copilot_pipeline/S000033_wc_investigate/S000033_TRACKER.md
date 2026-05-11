---
name: "/wc-investigate — scoping conversation + design doc + domain skeletons"
type: user-story
id: "S000033"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: "S000032"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker
2. Create working branch: `git checkout -b feat/wc_investigate`
3. Scaffold work item directory and TRACKER.md
4. Distill DESIGN.md
5. Scaffold SPEC.md
6. Scaffold TEST-SPEC.md
7. Break into child tasks if needed

**Gates:**
- [x] /office-hours design referenced
- [x] Working branch created
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A)

### Phase 2: Implement

1. Read DESIGN + SPEC
2. Implement
3. Smoke tests
4. `/CJ_personal-workflow check`
5. Update tracker + journal
6. Update Files section

**Gates:**
- [ ] Acceptance criteria verified
- [ ] Smoke tests pass
- [ ] Todos current
- [ ] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check`
2. Smoke in CI
3. E2E manually
4. Children shipped
5. `/ship`
6. `/land-and-deploy`

**Gates:**
- [ ] `/CJ_personal-workflow check` — pass
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship`
- [ ] `/land-and-deploy`

## Acceptance Criteria

- [ ] `work-copilot/prompts/investigate.prompt.md` exists with `tools: [codebase, search, searchResults, editFiles]`.
- [ ] Prompt reads every file under `.github/work-copilot/domain/*.md` as ambient context (skips `.template.md` skeletons).
- [ ] Prompt greps/searches the target codebase for entities in the user's prompt.
- [ ] Prompt walks user through scoping conversation (problem, target user, narrowest wedge, key risks) in plain chat.
- [ ] Prompt synthesizes design doc to `.github/work-copilot/designs/<short-slug>-design-<datetime>.md` with required frontmatter (`status: DRAFT`, `work_item_type`, `scaffolded_to: null`, `receipts.investigate` block).
- [ ] `work-copilot/domain/domain-knowledge.template.md` exists with skeleton content.
- [ ] `work-copilot/domain/coding-conventions.template.md` exists with skeleton content.
- [ ] `work-copilot/domain/architecture-overview.template.md` exists with skeleton content.
- [ ] `scripts/copilot-deploy.py` extended: installs domain skeletons on first install only (skips with `[KEEP-USER]` if user `.md` exists).
- [ ] `scripts/copilot-deploy.py` extended: creates `.github/work-copilot/designs/.gitkeep` on install.
- [ ] Manual smoke pass: invoke `/wc-investigate` in a test target repo; verify design doc lands at `.github/work-copilot/designs/`; verify domain skeletons survive re-install.

## Todos

- [ ] Author `work-copilot/prompts/investigate.prompt.md` with frontmatter + 5 main steps.
- [ ] Author 3 domain skeleton templates with light content (commented placeholders).
- [ ] Extend `scripts/copilot-deploy.py`: detect filled-vs-skeleton, skip filled on re-install.
- [ ] Extend `scripts/copilot-deploy.py`: create `.github/work-copilot/designs/.gitkeep`.
- [ ] Document `[KEEP-USER]` and `.gitkeep` behavior in `copilot-deploy.py` help text.
- [ ] Smoke + fixture exercise in a test target repo.

## Log

- 2026-05-11: Created. Build #4 of Approach C. Blocked by S000032 (consumes /wc-scaffold's design-doc frontmatter schema). Largest story by scope — touches `copilot-deploy.py`.

## PRs

## Files

- `work-copilot/prompts/investigate.prompt.md` (new)
- `work-copilot/domain/domain-knowledge.template.md` (new)
- `work-copilot/domain/coding-conventions.template.md` (new)
- `work-copilot/domain/architecture-overview.template.md` (new)
- `scripts/copilot-deploy.py` (modified — first-install rule + designs/.gitkeep)

## Insights

- The first-install-only rule for domain skeletons is the same shape as `~/.claude/` template overwrite-by-default-with-flag-to-preserve (`skills-deploy install --no-overwrite`), but inverted: domain templates are USER DATA by default (skeleton fills the slot on first install; never overwritten on re-install). The difference matters: workbench templates are source-of-truth that gets pushed down; domain templates are per-target seeds that the user fills in.

## Journal

- [decision] 2026-05-11: Domain skeletons use `.template.md` suffix on the bundle side (`work-copilot/domain/*.template.md`); they install to `.github/work-copilot/domain/<name>.md` (no suffix) on first install. The suffix difference is the install-time signal: "if the target file exists without `.template.md`, it's user-filled; skip."
