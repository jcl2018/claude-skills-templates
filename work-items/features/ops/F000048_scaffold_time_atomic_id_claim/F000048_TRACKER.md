---
name: "Scaffold-time atomic F-ID claim (close the pre-push collision race)"
type: feature
id: "F000048"
status: active
created: "2026-06-04"
updated: "2026-06-04"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-225454-7907"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/scaffold_time_atomic_id_claim`
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

- [ ] Two concurrent `cj-id-claim.sh` invocations with the same floor return distinct IDs every time (race test green, looped 20+ rounds).
- [ ] A claim whose ID is on origin/main, or older than the TTL, is reaped and not counted.
- [ ] Scaffold re-run on the same branch (pre-completion) keeps its ID (idempotent).
- [ ] Helper-absent fallback still mints an ID (scaffold never breaks).
- [ ] `tests/cj-id-claim.test.sh` is explicitly registered in `scripts/test.sh` and observably executed; validate.sh + test.sh green.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000084 — implement `cj-id-claim.sh` + Step 5.1 wiring + tests (the whole feature is this one atomic story)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Scaffold-time atomic F-ID claim — a 4th ID source (mkdir-CAS claim dir in the shared `.git` common-dir) closes the scaffold-before-push collision race for concurrent same-machine cj_goal worktrees. Source design doc: `/Users/chjiang/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-225454-7907-design-20260604-231729.md`

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-id-claim.sh` (NEW — claim engine)
- `skills/CJ_scaffold-work-item/scaffold.md` (Step 5.1 edit — Source 4 + claim + fail-soft fallback + prose)
- `tests/cj-id-claim.test.sh` (NEW — 7 cases incl. the race)
- `scripts/test.sh` (register the new test file)
- `skills-catalog.json` (bump CJ_scaffold-work-item version; portability_requires if declared)
- `skills/CJ_scaffold-work-item/USAGE.md` (Check-14 drift)
- `CLAUDE.md`, `doc/WORKFLOWS.md`, `doc/ARCHITECTURE.md` (doc-sync, some folded by Step 5.5)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The fix is a lock-free atomic counter built from one POSIX primitive: `mkdir` fails if the directory exists, so `mkdir .git/cj-id-claims/<ID>` IS a compare-and-swap. Git worktrees share one `.git` (the common dir), so the claim is instantly visible to every sibling worktree the moment it is made — before any commit, push, or PR.
- ID gaps are harmless: a stale claim costs at most a skipped number, never a wrong or duplicate ID. So lazy, conservative reaping (claim older than a TTL, OR its ID already on origin/main) suffices — no aggressive liveness detection needed.
- Two DELIBERATELY DIFFERENT git-dir queries are in play: the *script* is located via `git rev-parse --show-toplevel` (the worktree's own `scripts/`), while the *claim dir* lives under `git rev-parse --git-common-dir` (the SHARED `.git`). Don't conflate them.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-04 — Chose Approach A (helper script + `mkdir` CAS) over B (`git update-ref` CAS) and C (inline in scaffold.md). Summary: A is the simplest atomic CAS, trivially unit-testable in isolation (race/reap/prefix-isolation), and portable (Git-Bash/Windows-safe). C violates engine-in-script (untestable). B is git-native but needs an object + ref cleanup + ref-date plumbing for zero v1 benefit.
- [decision] 2026-06-04 — v1 scope = same-machine / same-clone (shared `.git`) only. Cross-machine pre-push (two clones, neither pushed) is NOT regressed — it stays covered post-push by Sources 2+3 — just not pre-empted. Deferred. Summary: match the fix to the actual failure (worktrees), not the largest conceivable one.
