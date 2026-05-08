---
name: "Phase 3 gate auto-update — engine + post-merge hook"
type: user-story
id: "S000020"
status: active
created: "2026-05-08"
updated: "2026-05-08"
parent: "F000011"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/phase3-gate-autoupdate"
blocked_by: ""
---

<!-- Source design (parent): ../F000011_DESIGN.md
     Office-hours doc: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-phase3-gate-autoupdate-design-20260508-165047.md
     Bundles engine + hook in one user-story since they ship together. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker (F000011_TRACKER.md) for scope
2. Use parent's branch (`feat/phase3-gate-autoupdate`)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from parent's design (engine + hook brief stub)
5. Scaffold `SPEC.md` (P0 requirements, AC, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. (No child tasks — atomic story)

**Gates:**
- [x] /office-hours design referenced (parent F000011_DESIGN.md links to source)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement per SPEC's Components Affected and Data Flow
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI
3. Walk E2E manually
4. Ensure all child tasks (if any) have shipped
5. Run `/ship`
6. Run `/land-and-deploy`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `/personal-workflow check --update <work-item-dir>` exists, registered in `personal-workflow/check.md`, validated by `validate.sh`
- [ ] `--update` flag triggers Phase 3 gate inference (Step 13.5 in check.md)
- [ ] Engine reads external state via `gh pr view <PR> --json state,mergeStateStatus`, `gh pr checks <PR>`, `git log` for child recursion
- [ ] Engine writes `[x]` for inferable Phase 3 gates with positive signal: `/personal-workflow check`, `Smoke tests pass in CI`, `All children shipped`, `/ship — PR created`, `/land-and-deploy — merged and deployed`, `/document-release`
- [ ] Engine NEVER auto-marks `E2E walked manually` (purely human-driven; explicit exclusion)
- [ ] Engine is idempotent: re-running on already-converged state is a NO-OP; never downgrades `[x]` → `[ ]`
- [ ] Engine appends `[gates-update]` journal entry summarizing what changed
- [ ] Engine appends merged PR link + status to `## PRs` section (additive; doesn't duplicate)
- [ ] `scripts/post-merge-hook.sh` exists, executable, with shebang + clear comments
- [ ] Hook checks branch == main; silently no-ops on feature branches
- [ ] Hook reads `git log @{1}..HEAD --name-only` to find files touched by incoming commits, filters to `work-items/**/*_TRACKER.md`, runs `--update` on each containing dir
- [ ] Hook failures are best-effort: print warning, exit 0 (don't block git operation)
- [ ] `scripts/setup-hooks.sh` extended to install the post-merge hook into `.git/hooks/` (alongside existing pre-commit)
- [ ] End-to-end manual verification: ship a small change, `git pull main`, observe Phase 3 gates auto-update on the touched work-item without any manual checkbox edits

## Todos

- [ ] Add `--update` flag handling to `skills/personal-workflow/check.md` (parse flag in Step 1; route to Step 13.5 if set)
- [ ] Implement Step 13.5 (gate inference) in check.md: gh queries + child recursion + checkbox writeback
- [ ] Implement Step 13.6 (PR linking) in check.md: append merged PR to `## PRs` section if not already there
- [ ] Implement Step 13.7 (journal entry) in check.md: append `[gates-update]` entry summarizing changes
- [ ] Write `scripts/post-merge-hook.sh` (the hook script itself)
- [ ] Modify `scripts/setup-hooks.sh` to install the post-merge hook
- [ ] Add tests covering: --update on a known-shipped work item, --update on unshipped work item (no-op), --update with offline `gh` (graceful fallback), hook firing on main vs feature branch
- [ ] After ship: end-to-end manual verification (the success criterion from the design)

## Log

- 2026-05-08: Created. Bundles engine + hook for the Phase 3 gate auto-update feature. Engine = `--update` flag in `/personal-workflow check`. Hook = `scripts/post-merge-hook.sh` wired via `scripts/setup-hooks.sh`. Together they auto-mark inferable Phase 3 gates after `git pull main` post-ship.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/personal-workflow/check.md` (modified — adds `--update` flag handling + Steps 13.5/13.6/13.7)
- `scripts/post-merge-hook.sh` (NEW — hook script)
- `scripts/setup-hooks.sh` (modified — wires post-merge hook into install pass)

## Insights

- **Pipeline dogfood end-to-end.** S000020 is the first user-story to flow through the full F000010 pipeline (/scaffold-work-item → /implement-from-spec → /qa-work-item → /ship). Process bugs surface here. If implement or qa fails on this user-story, that's a pipeline bug, not an S000020 bug.
- **Idempotent + additive only.** The engine never downgrades a gate from `[x]` to `[ ]`. This protects against the "user manually unchecked" footgun: if user explicitly marks a gate unchecked, re-running --update doesn't override that.
- **Post-merge hook fires on `git pull main` after ship.** That's the natural step the user already takes to clean up after a successful ship. No new habit required. The "web UI / cross-machine merge" gap (hook only fires for local merges) is a known and accepted limitation.

## Journal

- 2026-05-08 [decision] Bundle engine + hook in one user-story (not split). They ship together — engine is incomplete without trigger; hook is useless without engine. Splitting would mean two PRs both partially functional.
- 2026-05-08 [decision] `--update` is a flag on existing `/personal-workflow check`, not a new skill. Keeps the surface small and reuses the existing path resolution / template fallback / boundary check infrastructure.
- 2026-05-08 [decision] Steps 13.5 / 13.6 / 13.7 are new sub-steps inside check.md, between existing Step 13 (Directory Mode report) and Step 14 (Tier 2). Tier 2 then re-validates the post-update tracker for compliance.
- 2026-05-08 [decision] Hook detects work-item dirs by filtering `git log` output to paths matching `work-items/**/*_TRACKER.md`. Doesn't require a manifest of registered dirs — purely path-pattern based.
- 2026-05-08 [decision] Hook failures print a warning and exit 0. Best-effort contract. The user can run `/personal-workflow check --update <dir>` manually if the hook missed something.
