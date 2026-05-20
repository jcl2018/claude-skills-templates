# Philosophy

## Why this repo exists

Claude Code follows structured instructions reliably. That means the hard part of doc-first development is not getting AI to follow a process, it's having good templates to follow. This repo exists because the templates and the `work-items/` directory pattern are the actual product. The skills that used to orchestrate them (/workflow, /contracts) turned out to be thin wrappers around what Claude Code does naturally when given clear CLAUDE.md rules.

The target user is a solo developer using Claude Code who wants lightweight lifecycle management without adopting a project management platform. Work items live in the repo. Templates live in `~/.claude/templates/`. No external service required.

## Design principles and tradeoffs

**1. Templates over orchestration.** The repo started with 7 skills orchestrating a 4-phase workflow pipeline. After real usage, 5 were deleted. The logic that survived moved to CLAUDE.md rules (`rules/work-items.md`) and `artifact-manifests.json`. The tradeoff: less guardrail enforcement in exchange for less code to maintain. Evidence: commits `8a03260` (delete /workflow and /contracts) and `38abd03` (deliver rules via skills-deploy).

**2. Absorb what you own, compose what you don't.** When the /docs skill needed template enforcement (formerly /contracts), it absorbed the logic directly rather than calling a sibling skill. But for post-ship doc updates, it composes with gstack's `/document-release` rather than reimplementing. The tradeoff: absorbing means you maintain it, composing means you depend on upstream. Evidence: `skills/docs/DESIGN.md` key decision #1.

**3. Filesystem as protocol.** Parent/child relationships are expressed by directory nesting (`work-items/F000001/S000001/T000001/`). Work item types are determined by branch naming conventions (`feat/*` = feature, `fix/*` = defect). Template resolution follows a 3-level fallback chain (`templates/` then `~/.claude/spec/templates/` then `~/.claude/templates/`). The tradeoff: no database, no API, no sync, but the conventions must be documented and followed. Evidence: `rules/work-items.md`, `artifact-manifests.json`.

**4. Declare, don't hardcode.** `artifact-manifests.json` is the single source of truth for which artifacts each work item type requires. The manifest drives scaffolding, validation, and template resolution. Adding a new artifact type means adding one JSON entry, not editing 5 files. The tradeoff: one more file to keep in sync. Evidence: `artifact-manifests.json` v2.0.0.

**5. Flag, don't fix.** `/docs check` detects staleness and drift but never auto-regenerates content. Philosophy docs need the human's voice. Work item validation flags missing sections but doesn't auto-fix. The tradeoff: more manual work, but no surprise overwrites. Evidence: `skills/docs/DESIGN.md` key decision #3.

## What this intentionally does NOT optimize for

- **Teams or collaboration.** Work items have no assignee field. No locking, no merge conflict resolution for trackers. This is a solo dev tool.
- **Universal portability.** Templates assume CLAUDE.md conventions, gstack patterns, and the `work-items/` directory structure. They won't work in an arbitrary repo without adaptation.
- **Runtime enforcement.** CLAUDE.md rules are passive instructions. Nothing prevents a developer from scaffolding a feature without a SPEC. `/CJ_personal-workflow check` catches drift after the fact, not before.
- **Scalability beyond ~50 work items.** The directory-nesting model with max depth 3 works for solo projects. It would not work for a 200-person engineering org.

## Key patterns and conventions

**Template naming prefixes** (`templates/`):
- `doc-*.md` for scaffolding templates (used when creating new docs)
- `tracker-*.md` for work item lifecycle trackers (one per type: feature, defect, task, user-story)

**Skill directory structure** (`skills/{name}/`):
- `SKILL.md` required, with YAML frontmatter (`name`, `description`, `version`, `allowed-tools`)
- `CHANGELOG.md` for version history
- `DESIGN.md` for design decisions
- Supporting `*.md` files for subcommands (e.g., `init.md`, `check.md`)

**Work item hierarchy** (`work-items/{slug}/`):
- `TRACKER.md` at every level (feature > user-story > task, max depth 3)
- Doc artifacts (DESIGN, SPEC, TEST-SPEC) for user-stories
- ID-prefixed filenames (`F000001_SPEC.md`) to avoid collisions
- ID format: `{TYPE_PREFIX}{NNNNNN}` where prefix is F/S/T/D

**Version management:**
- 4-digit `VERSION` file at repo root (`MAJOR.MINOR.PATCH.MICRO`)
- Per-skill versions in SKILL.md frontmatter (semver)
- `skills-catalog.json` tracks all skill versions and template ownership
- Collection version bumps on every ship

## The CJ_ skill family — workflow map

The CJ_ family is the workbench's user-facing pipeline. Top-level orchestrators take different inputs (idea, design doc, defect, TODO row) and converge on the same downstream chain (`/CJ_personal-pipeline` → `/ship` → `/land-and-deploy`). Internal phase-step skills are called transitively by orchestrators — route to the top-level ones.

### Decision tree: which CJ_ skill to call?

```
START: What's your input?

  ┌─ Just a one-liner idea? ─────► /CJ_goal_auto "<idea>"
  │  (small, unambiguous)            ├─ --auto-merge-small-diffs  (opt-in auto-merge)
  │                                  ├─ --dry-run                 (zero-write preview)
  │                                  └─ --audit                   (last 10 receipts)
  │
  ├─ Have an approved design doc? ─► /CJ_goal_run <path/to/design-doc.md>
  │  (from /office-hours, in .gstack/)
  │
  ├─ Mid-work-item, resume? ──────► /CJ_goal_run                  (no args)
  │  ("pick up where I left off")    auto-scans current branch
  │
  ├─ Resume specific work-item? ──► /CJ_goal_run <work-item-dir>
  │
  ├─ Defect to root-cause + ship? ► /CJ_goal_investigate <D-id | fragment>
  │  (Iron Law: no fix without RCA)
  │
  ├─ Drain TODOs.md? ─────────────► /CJ_goal_todo_fix [<T-id> | "<frag>"]
  │  ├─ Auto-drain:                  /CJ_goal_todo_fix --max-drain 3
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
  └─ Found a Claude best-practice ► /CJ_improve-queue evaluate <url>
     URL? Audit the repo?            ├─ /CJ_improve-queue audit
                                     └─ /CJ_improve-queue research <topic>
```

### Per-skill pipelines (what each one actually does)

**`/CJ_goal_auto "<one-liner>"`** — full one-liner-to-deployed:

```
[Stage 0]    auto-worktree + version-queue check + --handoff capability sentinel
     │
     ▼
[Stage 0.5]  classifier: small-unambiguous | needs-human-taste | too-big
     │       (halts non-small)
     ▼
[Stage 1]    workbench-owned design-doc generator → ~/.gstack/projects/<slug>/...
     │
     ▼
[Stage 1.5]  fail-closed doc gate (file exists + APPROVED + required sections)
     │
     ▼
[Stage 2]    inline /CJ_goal_run <doc> --handoff --no-drain
     │       ├─ default: GATE #2 = human /ship AUQ
     │       └─ --auto-merge-small-diffs: GATE #2 = scripts/cj-handoff-gate.sh
     │         (frozen merge-base, denylist, ≤5 files, ≤120 lines, Phase-2 green)
     ▼
[Stage 3]    audit receipt → ~/.gstack/analytics/CJ_goal_auto.jsonl
             + retro AUQ (first 5 auto-merges, then every 5th)
```

**`/CJ_goal_run <design-doc | work-item-dir>`** — the canonical full pipeline:

```
[Pre-flight]   validate APPROVED doc path; auto-worktree if on main with args
     │
     ▼
[Phase 1: /autoplan]   CEO + design + eng + DX reviews
     │                 → GATE #1 = autoplan native final-approval AUQ (always human)
     ▼
[Phase 2: /CJ_personal-pipeline]   Agent subagent, --suppress-final-gate
     │                             scaffold → implement → QA
     ▼
[Phase 3: /ship]   diff review + VERSION bump + PR
     │             → GATE #2 = /ship diff-review AUQ (always human)
     ▼
[Phase 4: /land-and-deploy --suppress-readiness-gate]   merge + CI + canary
     │
     ▼
[Phase 5: TODO drain]   diff TODOS.md for added rows; AUQ "drain N?" → loop
     │
     ▼
[Telemetry]   ~/.gstack/analytics/CJ_goal_run.jsonl + sunset trip-wire
```

**`/CJ_goal_investigate <D-id | fragment>`** — defect to deployed fix, Iron-Law enforced:

```
[Resolve]     D-ID exact / fragment fuzzy / zero-match → .inbox/<slug>/DRAFT.md
     │        (canonical D-ID minted ONLY after Iron-Law gate passes)
     ▼
[Preflight]   5-row idempotency table → R/F/P/M signals → resume row
     │
     ▼
[Isolation]   T000033 isolation gate — halt if working tree dirty
     │
     ▼
[/investigate]   Agent subagent, sentinel-wrapped JSON output
     │           FIX_PLAN_BEGIN_JSON + DEBUG_REPORT_BEGIN_JSON
     │           (Phase 4 writes fix DIRECTLY to source — no /CJ_implement-from-spec)
     ▼
[Iron-Law]   empty root_cause → halt; DONE_WITH_CONCERNS → halt
     │       blast radius >5 files → halt pre-write
     ▼
[Write artifacts]   D000NNN_RCA.md + test-plan.md row
     │
     ▼
[/CJ_qa-work-item <defect-dir>]
     │
     ▼
[/ship]   GATE #2 = human diff-review AUQ
     │
     ▼
[/land-and-deploy --suppress-readiness-gate]
     │
     ▼
[Journal]   [investigate-shipped] D000NNN vX.Y.Z PR #NNN + telemetry
```

**`/CJ_goal_todo_fix [<T-id> | "<frag>"]`** — TODOS.md drain to merged PRs:

```
     ┌─ no args ─────────► drain mode  ──┐
     └─ T-id / fragment ─► single mode ──┤
                                          ▼
[drain Phase 1]   /CJ_suggest --for-skill cj-goal --limit 2×max → ranked candidates
     │            (--max-drain N caps; default 10)
     ▼
[drain Phase 2]   for each TODO: scripts/drain-one-todo.sh dispatch
     │            ↓ shared lockfile, atomic
     │            ↓ scripts/todo_fix.sh single-mode
                                          │
per-TODO chain (shared between drain + single):
     ▼
[Preflight gates]   body <50 chars / missing (P,S) / P1 / L|XL /
     │              sensitive surface / design-needed keyword / idempotency hit
     ▼
[T-task scaffold]   TRACKER + test-plan
     │
     ▼
[/CJ_personal-pipeline]   scaffold → impl → QA
     │
     ▼
[/ship]   GATE #2 fires per TODO (NOT suppressed by --quiet — autonomy ceiling)
     │
     ▼
[/land-and-deploy]
     │
     ▼
[TODOS.md DONE-mark]   hash-verified strikethrough
     │
     ▼
[Telemetry]   ~/.gstack/analytics/CJ_goal_todo_fix.jsonl
              (+ session log if --quiet)
```

**`/CJ_suggest [--for-skill <name>] [--limit N] [--include-internal]`** — read-only backlog ranker:

```
[Read]     ./TODOS.md (auto-detect mode 1 "## Active work" vs mode 2 domain H2)
     │     + ./work-items/**/*_TRACKER.md frontmatter
     ▼
[Score]    pri_w (P1=4..P4=1) + size_w (S=3, M=2, L=1)
     │     + unblocked (+2) − recency (age_days / 14)
     ▼
[Filter]   exclude internal phase-step skills by default
     │     (CJ_personal-{workflow,pipeline}, CJ_{scaffold,implement,qa}-*)
     ▼
[--for-skill predicate]   (v1: cj-goal only — preflight gates + heading gates)
     │
     ▼
[Print top-N]   markdown table to stdout (default N=5)
                (deterministic bash — no LLM, no subagent, no AUQ)
```

**`/CJ_system-health [--quick]`** — ~/.claude/ health dashboard:

```
[Step 1: Scan ~/.claude/]
     │   • SKILL inventory (frontmatter, symlink targets, OK/broken)
     │   • cross-references (grep 'skills/<name>')
     │   • settings.json structural keys (no creds)
     │   • rules/, templates/
     ▼
[Step 2: Graph analysis]
     │   • adjacency list, in-degree per skill
     │   • orphans (in-degree 0), hubs (>5 = HIGH FRAGILITY)
     │   • broken symlinks, dead references, circular deps
     ▼
[Step 3: Filesystem health]
     │   • disk usage per subdir
     │   • history.jsonl size, stale sessions (>24h)
     │   • temp files (.tmp/.bak/.pending-*), empty dirs
     ▼
[Step 4: Waza integration]   (optional; skipped on --quick or missing)
     │
     ▼
[Report]   composite score + trend tracking
           + usage analytics overlay from skill-usage.jsonl
```

**`/CJ_improve-queue {evaluate <url> | audit | research <topic>}`** — workbench self-improvement, trust-split:

```
Trust-split architecture (load-bearing):

  bash envelope   ←──→   orchestrator   ←──→   Agent subagent (fresh context)
  (improve_       (this skill)                (general-purpose,
   queue.sh)                                   WebFetch + JSON verdict)
  — deterministic                              — match | conflict | novel |
    I/O, allowlist,                              reject | fetch_failed
    locking, atomic write

evaluate <url>:
  [1] preflight: Darwin gate, TODOS.md clean, allowlist
   ▼  (docs.anthropic.com, anthropic.com, claude.com, github.com/anthropics/*)
  [2] HANDOFF JSON: canonical_url + in-scope skills
   ▼
  [3] subagent WebFetches + reads SKILL.md → JSON verdict
   ▼
  [4] apply: confidence <7 → REVIEW: prefix; novel/conflict → append
      TODO row with <!--impr-draft--> marker (filtered from /CJ_suggest)

audit:     offline self-scan — stale skills (no usage 30d) + missing frontmatter
           → synthetic verdicts → same apply

research <topic>:
  [R1] privacy gate AUQ → [R2] WebSearch ≤3, allowlist filter →
  [R3] per-result: compose Phase 1 evaluate
```

### Internal phase-step skills — called transitively, do not route directly

| Skill | Called by | Job |
|---|---|---|
| `/CJ_personal-pipeline` | `/CJ_goal_run` Phase 2; `/CJ_goal_todo_fix` per-TODO | Chains scaffold → impl → QA in a fresh-context Agent subagent |
| `/CJ_scaffold-work-item` | `/CJ_personal-pipeline` | Design-doc → `work-items/<type>/<id>_<slug>/` tree |
| `/CJ_implement-from-spec` | `/CJ_personal-pipeline` | Reads SPEC + DESIGN, writes code via Edit/Write |
| `/CJ_qa-work-item` | `/CJ_personal-pipeline`; `/CJ_goal_investigate` | Runs TEST-SPEC rows (smoke + E2E subagent per row) |
| `/CJ_personal-workflow` | All of the above (boundary checks) | Validates work-item dirs + tracker files against manifest |

### Quick rule of thumb

| Your situation | Call |
|---|---|
| Vague idea, want auto-ship | `/CJ_goal_auto "<idea>"` |
| Have an approved design doc | `/CJ_goal_run <doc>` |
| Bug to ship a fix for | `/CJ_goal_investigate <D-id>` |
| Backlog has shippable rows | `/CJ_goal_todo_fix` (or `--max-drain N`) |
| Lost track, what's next? | `/CJ_suggest` |
| Resume current branch | `/CJ_goal_run` (no args) |
| Health check the workbench | `/CJ_system-health` |
| Triage a Claude best-practice URL | `/CJ_improve-queue evaluate <url>` |

The four `/CJ_goal_*` orchestrators all converge on the same downstream chain (`/CJ_personal-pipeline` → `/ship` → `/land-and-deploy`) — they differ in what they take as input (idea / doc / defect / TODO row). **GATE #1** (final approval before code is written) is always human across all four. **GATE #2** (post-implementation merge) is human-by-default; `/CJ_goal_auto --auto-merge-small-diffs` is the only path that delegates GATE #2 to a script (`scripts/cj-handoff-gate.sh`) with a strict denylist + size cap.

## How to extend without breaking its character

**Adding a new work item type:** Add an entry to `artifact-manifests.json` with its required artifacts and template filenames. Create the tracker template (`tracker-{type}.md`) and any doc templates. Add the branch naming pattern to `rules/work-items.md`. The validation in `/docs check` will pick it up automatically via the manifest.

**Adding a new skill:** Create `skills/{name}/SKILL.md` with frontmatter. Add a catalog entry to `skills-catalog.json`. Run `./scripts/validate.sh`. The skill is discovered automatically by Claude Code.

**Adding a new template:** Add the file to `templates/`. Register it in `skills-catalog.json` under the appropriate catalog entry's `templates` array. Run `./scripts/skills-deploy install` to deploy globally.

**Anti-patterns to avoid:**
- Don't create orchestration skills that wrap gstack skills as **inline prose** (they end up deleted like /workflow — Claude already follows CLAUDE.md rules without a wrapper). **Exception:** orchestrators that use the `Agent` tool with `subagent_type` per phase for fresh-context isolation are structurally different — file-only handoff between subagents, the orchestrator brokers paths, AUQs are pre-collected at the parent layer because subagents can't reach the AskUserQuestion tool. That's plumbing, not prose, and it earns its keep. See `/CJ_personal-pipeline` (F000014, shipped v1.13.0) for the pattern + the spike findings that locked the design.
- Don't hardcode template lists in skill logic (read `artifact-manifests.json` instead)
- Don't add $AI_CONTENT_DIR indirection (use `./work-items/` directly)
- Don't add team collaboration features (assignees, locking, notifications)

## Dependencies and assumptions

**Runtime:** Git (for history, branching, commit SHAs). Bash (for scripts). `jq` (recommended for JSON parsing in scripts, optional).

**Claude Code ecosystem:** Skills are discovered from `~/.claude/skills/`. Templates deploy to `~/.claude/templates/`. Rules deploy to `~/.claude/rules/`. The `skills-deploy` script manages symlinks and manifests at `~/.claude/.skills-templates.json`.

**gstack (optional):** `/docs` composes with gstack's `/document-release` for post-ship doc updates. `/CJ_system-health` optionally invokes waza for config hygiene. Neither is required for core functionality.

**Assumptions:** The developer uses branch naming conventions for work item type detection. Templates exist either in `templates/` (repo root) or `~/.claude/templates/` (deployed globally). `artifact-manifests.json` is at repo root and matches the templates on disk.

## Failure modes and maintenance risks

**Template drift.** If `artifact-manifests.json` is updated but templates are not (or vice versa), scaffolding produces wrong artifacts. `/docs check` catches this, but only if someone runs it. Mitigation: `./scripts/validate.sh` checks template references at commit time.

**Stale CLAUDE.md rules.** The rules in `rules/work-items.md` are deployed globally via `skills-deploy`. If the source rules change but `skills-deploy install` isn't re-run, deployed rules go stale. Mitigation: `skills-deploy doctor` detects drift via SHA256 checksums.

**ID collision.** Work item IDs are auto-incremented from the highest existing ID in `work-items/`. If two sessions scaffold simultaneously, they could generate the same ID. Low risk for solo dev. Mitigation: none (accepted limitation for solo use).

**claims.json desync.** The `.docs/claims.json` sidecar maps doc sections to evidence files by commit SHA. If history is rewritten (rebase, force-push), stored SHAs become unreachable and staleness detection breaks gracefully with UNVERIFIABLE flags. Mitigation: re-run `/docs init` to rebuild the baseline.

**Skill-catalog version drift.** If a skill's SKILL.md frontmatter version doesn't match its catalog entry, `validate.sh` catches it. But nothing prevents manual edits that create drift between ship cycles.
