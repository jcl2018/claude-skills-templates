# Philosophy

## Why this repo exists

Claude Code follows structured instructions reliably. That means the hard part of doc-first development is not getting AI to follow a process, it's having good templates to follow. This repo exists because the templates and the `work-items/` directory pattern are the actual product. The skills that orchestrate them are thin by design — most of the load-bearing structure lives in templates, CLAUDE.md rules, and the `personal-artifact-manifests.json` declarations they consume.

The target user is a solo developer using Claude Code who wants lightweight lifecycle management without adopting a project management platform. Work items live in the repo. Templates live in `~/.claude/templates/`. No external service required.

The two intent-named front doors capture the dominant workflows: `/CJ_goal_feature` (build a feature: topic → reviewable PR) and `/CJ_goal_defect` (fix a bug: description → shipped fix). Everything else is either a read-only utility (`/CJ_suggest`, `/CJ_system-health`, `/CJ_improve-queue`) or a backlog drainer (`/CJ_goal_todo_fix`).

## Two delivery surfaces, one contract

The templates and validation surface reach two kinds of consumer, and the repo is deliberately not Claude-only. On Claude Code, the `CJ_` skills orchestrate the doc-first workflow directly. On machines without Claude — where the contributor drives **GitHub Copilot** instead — the self-contained `work-copilot/` bundle carries the same work-item templates + `/validate` workflow + ambient guidance, deployed via `scripts/copilot-deploy.py`. What ports across both is the doc-first *contract* (templates + validation + conventions); what does NOT port is the pipeline automation — the `CJ_` orchestrators are Claude-only by design. `work-copilot/` is canonical (no upstream sync) and its integrity is enforced by `scripts/validate.sh` Error check 10. See [doc/ARCHITECTURE.md](ARCHITECTURE.md#the-work-copilot-copilot-bundle-parallel-delivery-surface) for the deploy mechanism and the operator-facing bundle reference.

## Design principles and tradeoffs

**1. Templates over orchestration.** The repo started with 7 skills orchestrating a 4-phase workflow pipeline. After real usage, 5 were deleted. The logic that survived moved to CLAUDE.md rules and the `personal-artifact-manifests.json` declarations consumed by `/CJ_personal-workflow`. The tradeoff: less guardrail enforcement in exchange for less code to maintain. Today's `/CJ_personal-workflow` carries the validation surface; the orchestration shape is enforced by the templates the operator scaffolds against, not by per-phase wrapper skills.

**2. Absorb what you own, compose what you don't.** The workbench's own skills (scaffold, implement, qa, workflow validator) absorb the logic they need directly. For post-ship documentation updates, the workbench composes with gstack's `/document-release` rather than reimplementing it; for merge + deploy it composes with gstack's `/ship` and `/land-and-deploy`. The tradeoff: absorbing means you maintain it, composing means you depend on upstream. The CLAUDE.md `## /document-release workbench audit conventions` section is a concrete example: it teaches the upstream skill workbench-specific drift checks by riding the existing project-context behavior, no fork required.

**3. Filesystem as protocol.** Parent/child relationships are expressed by directory nesting (`work-items/<domain>/F000NNN_<slug>/S000NNN_<slug>/`). Work item types are determined by branch naming conventions (`cj-feat-*` = feature, `cj-fix-*` = defect). Template resolution follows a fallback chain (`templates/<skill>/` then `~/.claude/templates/<skill>/`). State lives as on-disk JSON files (e.g., the update-check cache at `~/.claude/.skills-templates-update.json`; per-orchestrator telemetry JSONL under `~/.gstack/analytics/`). The tradeoff: no database, no API, no sync, but the conventions must be documented and followed.

**4. Declare, don't hardcode.** `personal-artifact-manifests.json` (owned by `/CJ_personal-workflow`) is the single source of truth for which artifacts each work item type requires. The manifest drives scaffolding, validation, and template resolution. Adding a new artifact type means adding one JSON entry, not editing 5 files. The tradeoff: one more file to keep in sync. The same shape generalizes: `skills-catalog.json` declares which skills exist + their status; `rules/skill-routing.md` declares routing; `WORKFLOW.md` per skill declares structural rules.

**5. Flag, don't fix.** `/CJ_personal-workflow check` detects drift but never auto-regenerates content. Philosophy docs need the human's voice. Work item validation flags missing sections but doesn't auto-fix. The `/document-release` workbench audit conventions (CLAUDE.md) surface skill-routing drift in PR bodies — they do not silently inject missing decision-tree entries. The tradeoff: more manual work, but no surprise overwrites.

## What this intentionally does NOT optimize for

- **Teams or collaboration.** Work items have no assignee field. No locking, no merge conflict resolution for trackers. This is a solo dev tool.
- **Universal portability.** Templates assume CLAUDE.md conventions, gstack patterns, and the `work-items/` directory structure. They won't work in an arbitrary repo without adaptation. (The `work-copilot/` bundle is the deliberate, maintained exception — it ports the template + validation surface to GitHub Copilot targets, as described in *Two delivery surfaces, one contract* above; it does NOT port the CJ_ orchestrators.)
- **Runtime enforcement.** CLAUDE.md rules are passive instructions. Nothing prevents a developer from scaffolding a feature without a SPEC. `/CJ_personal-workflow check` catches drift after the fact, not before.
- **Scalability beyond ~50 work items.** The directory-nesting model with max depth 3 works for solo projects. It would not work for a 200-person engineering org.
- **Headless autonomous merge across the whole workbench.** `/ship` Gate #2 is human-by-default across every front door. The handoff-gate denylist (`scripts/cj-handoff-gate.sh`) blocks exactly the skill surfaces every feature touches, so an auto-merge path here is unsafe-by-construction. PR-stop is the correct stopping point for skill-work.

## Key patterns and conventions

**Template naming prefixes** (`templates/<skill>/`):
- `doc-*.md` for scaffolding templates (used when creating new docs)
- `tracker-*.md` for work item lifecycle trackers (one per type: feature, defect, task, user-story)

**Skill directory structure** (`skills/{name}/`):
- `SKILL.md` required, with YAML frontmatter (`name`, `description`, `version`, `allowed-tools`)
- `CHANGELOG.md` for version history
- `DESIGN.md` for design decisions
- Supporting `*.md` files for subcommands or phase prose

**Work item hierarchy** (`work-items/<domain>/<id>_<slug>/`):
- `TRACKER.md` at every level (feature > user-story > task, max depth 3)
- Doc artifacts (DESIGN, SPEC, TEST-SPEC) for user-stories
- ID-prefixed filenames (`F000001_SPEC.md`) to avoid collisions
- ID format: `{TYPE_PREFIX}{NNNNNN}` where prefix is F/S/T/D

**Version management:**
- 4-digit `VERSION` file at repo root (`MAJOR.MINOR.PATCH.MICRO`)
- Per-skill versions in SKILL.md frontmatter (semver)
- `skills-catalog.json` tracks all skill versions and template ownership
- Collection version bumps on every ship

**Two parallel design surfaces:**
- `.gstack/` — lateral / exploratory. gstack skills (`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/context-save`) write here.
- `work-items/` — structured per-feature. The `/CJ_personal-workflow` taxonomy that drives `/CJ_implement-from-spec` and `/CJ_qa-work-item`.

## The portability principle

A skill's `portability` field in `skills-catalog.json` is a promise about *where it can run*. The workbench treats that promise as a **verified invariant**, not a self-declared label — because a self-declared label nobody checks is a lie waiting to happen. Two complementary skills hold the two halves of that promise honest, one per side of the producer/consumer boundary:

- **Producer side — `/CJ_portability-audit`.** Checks that the workbench's *produced* skills don't secretly depend on repo-local things a fresh target repo won't have. A static lint that compares each catalog skill's declared `portability` against its ACTUAL executed dependencies (root `scripts/*.sh` helpers, root config, `CLAUDE.md`, the manifest `.source` reach-back). It flags a skill that claims `standalone` while it *executes* a workbench helper.
- **Consumer side — `/CJ_repo-init`.** Checks that a *consumer* repo has the prerequisites the CJ_ family needs to run there (`cj-document-release.json`, `CJ-DOC-RELEASE.md`, `TODOS.md`, the `work-items/` tree). It verifies the destination, not the skill.

The two are mirrors: `/CJ_repo-init` asks "does this repo have what the skills need?"; `/CJ_portability-audit` asks "do the skills secretly need more than they admit?"

**The strict tier ladder.** Portability is a closed three-rung enum, each tier a strict superset of the one below:

```
standalone  ⊂  local-only  ⊂  workbench
```

- **`standalone`** — works in a repo that has never seen this workbench. Allowed deps: the skill's own bundled `skills/<name>/scripts/`, plus the repo-init prerequisites a consumer repo scaffolds. The bar is deliberately strict: no root `scripts/*.sh`, no `.source` reach-back, no `CLAUDE.md` reads, no root config.
- **`local-only`** — standalone's set PLUS the user's deployed `~/.claude` state (e.g. `/CJ_suggest`'s bundled ranking helper reaching deployed state).
- **`workbench`** — everything PLUS root `scripts/*.sh`, the `.source` reach-back, `CLAUDE.md` reads, and root config. This is the tier for skills that operate ON the workbench itself — `/CJ_personal-workflow` (it executes a root gate-update helper) and `/CJ_portability-audit` (its own root engine). The `cj_goal` orchestrators + `/CJ_document-release` used to sit here but were re-tiered to `local-only` once the shared scripts traveled with the install (F000049/S1) and their runtime `.source` reach-back was dropped (F000049/S4) — they now resolve `cj-goal-common.sh` + the worktree helpers from the deployed `_cj-shared` home, not a separate clone.

The governing rule is **declared portability must match ACTUAL executed dependencies.** An EXECUTED dependency (a `bash "$X"` / `source "$X"` / `[ -x "$X" ]` inside a `bash` fence or a `.sh` engine) beyond the declared tier is a finding; a merely DOCUMENTED mention (a prose citation, a path-pattern the skill scans FOR) is not. The honest fix for a finding is to relabel the skill to the tier it actually needs — exactly what was done when the three orchestrators + `/CJ_personal-workflow` moved from `standalone` to `workbench` (they genuinely operate on the workbench; the `standalone` claim was a known falsehood). The escape hatch for a deliberately-accepted dep is the optional `portability_requires` catalog field, which adjudicates a named dep so it stops counting as a finding while staying visible + auditable in the catalog.

**Posture: advisory now, gate later.** `/CJ_portability-audit` is wired into `scripts/validate.sh` as **advisory Check 18** — it prints findings but exits 0 in v1, so the invariant is *surfaced* without blocking. Setting `PORTABILITY_STRICT=1` flips Check 18 (and the engine's own exit code) to a hard gate — the documented follow-up, to be turned on once the workbench's declarations are fully reconciled. The one acknowledged debt that once blocked this — `/CJ_repo-init` declared `standalone` while its engine lived at the repo root (`scripts/cj-repo-init.sh`) — was resolved by D000032: the engine is now bundled under `skills/CJ_repo-init/scripts/`, so the skill is genuinely standalone and `--no-adjudication` is `FINDINGS=0`. The workbench's `standalone` declarations are now honest by tier, not by adjudication.

## Documentation surfaces

Each routable skill ships three documentation surfaces, in three intended audiences:

- **`SKILL.md`** (required) — the agent's execution instructions. Loaded into agent context on every skill invocation. Keep operator-facing best-practice prose OUT of this file; every line here pays a per-turn token cost.
- **`USAGE.md`** (required for routable skills) — the operator + agent best-practice surface: When to use / When NOT to use / Mental model / Common pitfalls / Related skills. Five required H2 sections. Human-reading; NOT deployed to `~/.claude/skills/{name}/` (the agent gets SKILL.md at runtime; USAGE.md stays in-repo). Authored from `templates/doc-SKILL-USAGE.md`.
- **`DESIGN.md`** (optional) — developer-facing design rationale: Purpose / Behavior / Design Decisions / Dependencies / Security Boundaries / Test Criteria. Useful for skills complex enough to warrant the rationale doc. Authored from `templates/doc-SKILL-DESIGN.md`.

`scripts/validate.sh` **Check 13** enforces the USAGE.md surface: every entry in `skills-catalog.json` with `status != "deprecated"` AND a non-empty `files` array MUST have a sibling `skills/{name}/USAGE.md` AND that file MUST contain the five required H2 section headings (`## When to use`, `## When NOT to use`, `## Mental model`, `## Common pitfalls`, `## Related skills`), line-anchored. Missing file or missing heading = ERROR. The predicate intentionally diverges from F000030's new-skills check (`status == "active"`, which gates `## Decision tree` placement) because operators route to `experimental` skills today, so USAGE.md must cover them too. The tooling-only `templates` catalog entry is excluded automatically.

**Drift rule**: USAGE.md must be at least as recent as its sibling SKILL.md, measured
by `git log -1 --format=%ct`. validate.sh Check 14 enforces this. When SKILL.md changes
cosmetically and USAGE.md is still accurate, the documented override is bumping the
`last-updated:` frontmatter field in USAGE.md and committing — a one-line content change
that advances USAGE.md's `%ct` past SKILL.md's. The `last-updated:` field is the
human-readable audit trail.

## Decision tree

The CJ_ family is the workbench's user-facing pipeline. Top-level orchestrators take different inputs (topic, bug description, defect, TODO row) and converge on the same downstream chain (`/ship` → `/land-and-deploy`). Internal phase-step skills are called transitively — route to the top-level ones.

```
START: What's your input?

  ┌─ One-line feature topic? ─────► /CJ_goal_feature "<topic>"
  │  (build a feature end-to-end)    ├─ stops at the PR (architecture gate)
  │                                  ├─ /office-hours INLINE (1 interactive phase)
  │                                  └─ scaffold → implement → QA (silent leaves)
  │
  ├─ Bug (with or without D-id)? ──► /CJ_goal_defect "<bug description>"
  │  (description → shipped fix)     ├─ .inbox/<slug>/DRAFT.md scratchpad
  │                                  ├─ /investigate (Iron-Law: no RCA ⇒ HALT)
  │                                  └─ D-ID minted only after RCA gate passes
  │
  ├─ TODOS.md backlog drain? ─────► /CJ_goal_todo_fix [<T-id> | "<frag>"]
  │  ├─ Default (no args):           drains up to 10 easy-fix TODOs
  │  ├─ Single mode:                 /CJ_goal_todo_fix T000NNN
  │  ├─ Cap drain:                   /CJ_goal_todo_fix --max-drain N
  │  ├─ Cron-friendly:               /CJ_goal_todo_fix --quiet
  │  └─ Continuous loop:             /loop /CJ_goal_todo_fix
  │
  ├─ "What should I work on?" ────► /CJ_suggest
  │  (top-5 from TODOS + trackers)   ├─ --include-internal
  │                                  ├─ --for-skill <name>
  │                                  └─ --limit N
  │
  ├─ "Is my ~/.claude/ healthy?" ─► /CJ_system-health [--quick]
  │  (dependency graph + usage)
  │
  ├─ "Set up this repo for CJ_?" ─► /CJ_repo-init
  │  (verify/scaffold per-repo prereqs — consumer-side)
  │
  ├─ "Are my skills' portability ─► /CJ_portability-audit
  │   declarations honest?"          (declared-vs-actual dependency lint — producer-side)
  │
  └─ Found a Claude best-practice ► /CJ_improve-queue evaluate <url>
     URL? Audit the repo?            ├─ /CJ_improve-queue audit
                                     └─ /CJ_improve-queue research <topic>
```

### Quick rule of thumb

| Your situation | Call |
|---|---|
| One-line topic, want a reviewable PR | `/CJ_goal_feature "<topic>"` — [USAGE](../skills/CJ_goal_feature/USAGE.md) |
| Bug — description or existing defect dir | `/CJ_goal_defect "<bug>"` — [USAGE](../skills/CJ_goal_defect/USAGE.md) |
| Backlog has shippable TODOs.md rows | `/CJ_goal_todo_fix` (or `--max-drain N`) — [USAGE](../skills/CJ_goal_todo_fix/USAGE.md) |
| Lost track, what's next? | `/CJ_suggest` — [USAGE](../skills/CJ_suggest/USAGE.md) |
| Health check the workbench | `/CJ_system-health` — [USAGE](../skills/CJ_system-health/USAGE.md) |
| Set up / verify a repo for the CJ_ family (consumer-side prereqs) | `/CJ_repo-init` — [USAGE](../skills/CJ_repo-init/USAGE.md) |
| Audit whether skills' `portability` declarations are honest (producer-side) | `/CJ_portability-audit` — [USAGE](../skills/CJ_portability-audit/USAGE.md) |
| Triage a Claude best-practice URL | `/CJ_improve-queue evaluate <url>` — [USAGE](../skills/CJ_improve-queue/USAGE.md) |

> **Not on Claude Code?** The decision tree above is the Claude-skill surface. If your machine runs **GitHub Copilot** instead, the `work-copilot/` bundle mirrors the same work-item + `/validate` workflow — see [doc/ARCHITECTURE.md → The work-copilot Copilot bundle](ARCHITECTURE.md#the-work-copilot-copilot-bundle-parallel-delivery-surface). The `CJ_` orchestrators themselves are Claude-only.

### Internal phase-step skills — called transitively, do not route directly

| Skill | Called by | Job |
|---|---|---|
| `/CJ_scaffold-work-item` | `/CJ_goal_feature` Step 3.1 | Design-doc → `work-items/<type>/<id>_<slug>/` tree — [USAGE](../skills/CJ_scaffold-work-item/USAGE.md) |
| `/CJ_implement-from-spec` | `/CJ_goal_feature` Step 3.2; `/CJ_goal_todo_fix` impl→qa chain | Reads SPEC + DESIGN, writes code via Edit/Write — [USAGE](../skills/CJ_implement-from-spec/USAGE.md) |
| `/CJ_qa-work-item` | `/CJ_goal_feature` Step 3.3; `/CJ_goal_todo_fix` impl→qa chain; `/CJ_goal_defect` Step 8 | Runs TEST-SPEC rows (smoke + E2E subagent per row) — [USAGE](../skills/CJ_qa-work-item/USAGE.md) |
| `/CJ_document-release` | `/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix` all at Step 5.5 (between QA pass and `/ship`) | Wraps upstream `/document-release` with `--docs <subset>` filter, halt-on-red, and doc-only auto-commit gated by per-repo `cj-document-release.json` (F000036 + F000037 strict-required config) — folds doc updates into the same code PR — [USAGE](../skills/CJ_document-release/USAGE.md) |
| `/CJ_personal-workflow` | All of the above (boundary checks) | Validates work-item dirs + tracker files against `personal-artifact-manifests.json` — [USAGE](../skills/CJ_personal-workflow/USAGE.md) |

The orchestrators all converge on the same downstream chain (`/ship` → `/land-and-deploy`) — they differ in what they take as input (topic / bug / defect / TODO row). **GATE #1** (final approval before code is written) is always human across all four. **GATE #2** (post-implementation merge) is human-by-default; the handoff-gate denylist blocks exactly the skill surfaces every feature touches, so PR-stop is the correct stopping point for skill-work in this workbench.

For the underlying mechanisms (the shared `cj-goal-common.sh` helper, the F000036 inline doc-sync wrapper at pipeline Step 5.5), see [doc/ARCHITECTURE.md](ARCHITECTURE.md).

## How to extend without breaking its character

**Adding a new work item type:** Add an entry to `personal-artifact-manifests.json` with its required artifacts and template filenames. Create the tracker template (`tracker-{type}.md`) and any doc templates. Add the branch naming pattern to the workflow rules. The validation in `/CJ_personal-workflow check` will pick it up automatically via the manifest.

**Adding a new skill:** Create `skills/{name}/SKILL.md` with frontmatter. Add a catalog entry to `skills-catalog.json`. Run `./scripts/validate.sh`. The skill is discovered automatically by Claude Code. If the skill is a routable front door (not an internal phase-step), add it to the `## Decision tree` section above so the `/document-release` workbench audit's new-skills check is satisfied.

**Adding a new template:** Add the file to `templates/<skill>/`. Register it in `skills-catalog.json` under the appropriate catalog entry's `templates` array. Run `./scripts/skills-deploy install` to deploy globally.

**Anti-patterns to avoid:**
- Don't create orchestration skills that wrap gstack skills as **inline prose** (they end up deleted — Claude already follows CLAUDE.md rules without a wrapper). **Exception:** orchestrators that use the `Agent` tool with `subagent_type` per phase for fresh-context isolation are structurally different — file-only handoff between subagents, the orchestrator brokers paths, AUQs are pre-collected at the parent layer because subagents can't reach the AskUserQuestion tool. That's plumbing, not prose, and it earns its keep. See `/CJ_goal_feature` Steps 3.1-3.3 (scaffold → implement → qa leaf subagents) for the pattern.
- Don't hardcode template lists in skill logic (read `personal-artifact-manifests.json` instead).
- Don't add `$AI_CONTENT_DIR` indirection (use `./work-items/` directly).
- Don't add team collaboration features (assignees, locking, notifications).
- Don't fork an upstream gstack skill when CLAUDE.md project context can teach it the workbench convention. The `## CI/CD merge convention` and `## /document-release workbench audit conventions` sections are the precedent: project context rides existing skill behavior with zero upstream modification.

## Dependencies and assumptions

**Runtime:** Git (for history, branching, commit SHAs). Bash (for scripts). `jq` (recommended for JSON parsing in scripts, optional).

**Claude Code ecosystem:** Skills are discovered from `~/.claude/skills/`. Templates deploy to `~/.claude/templates/`. Rules deploy to `~/.claude/rules/`. The `skills-deploy` script manages symlinks and manifests at `~/.claude/.skills-templates.json`.

**gstack (optional but expected for shipping):** `/CJ_goal_feature` and `/CJ_goal_defect` compose with gstack's `/office-hours`, `/ship`, and `/land-and-deploy` to take a topic / bug description through to a shipped fix. `/CJ_system-health` optionally invokes waza for config hygiene. Neither is required for core scaffolding/validation.

**Doc-sync mechanism (F000036 inline Step 5.5):** Doc updates fold into the same PR as the code — each `cj_goal` orchestrator invokes `/CJ_document-release` inline at Step 5.5 (between QA pass and `/ship`), and `/ship` Step 18 covers manual ship paths. The earlier F000028/F000029 post-merge marker + preamble-AUQ mechanism was retired by F000040 once this inline path made it redundant. See [doc/ARCHITECTURE.md](ARCHITECTURE.md) for the full mechanism reference and CLAUDE.md `## Doc-sync coverage` for the accepted gap.

**Assumptions:** The developer uses branch naming conventions for work item type detection. Templates exist either in `templates/<skill>/` (repo root) or `~/.claude/templates/<skill>/` (deployed globally). `personal-artifact-manifests.json` is at the skill's source root and matches the templates on disk.

## Failure modes and maintenance risks

**Template drift.** If `personal-artifact-manifests.json` is updated but templates are not (or vice versa), scaffolding produces wrong artifacts. `/CJ_personal-workflow check` catches this, but only if someone runs it. Mitigation: `./scripts/validate.sh` checks template references at commit time.

**Stale `~/.claude/rules/`.** The rules are deployed globally via `skills-deploy`. If the source rules change but `skills-deploy install` isn't re-run, deployed rules go stale. Mitigation: `skills-deploy doctor` detects drift via SHA256 checksums.

**Stale routing docs.** If a new skill ships without an entry in this file's `## Decision tree`, the workbench audit (CLAUDE.md `## /document-release workbench audit conventions`) flags it as a drift finding in the PR body's `## Documentation` section under `### Skill-routing drift`.

**ID collision.** Work item IDs are auto-incremented from the highest existing ID in `work-items/`. If two sessions scaffold simultaneously, they could generate the same ID. Low risk for solo dev. Mitigation: none (accepted limitation for solo use).

**Skill-catalog version drift.** If a skill's SKILL.md frontmatter version doesn't match its catalog entry, `validate.sh` catches it. But nothing prevents manual edits that create drift between ship cycles.
