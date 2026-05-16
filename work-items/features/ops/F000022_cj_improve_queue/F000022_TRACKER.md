---
name: "/CJ_improve-queue — proactive improvement TODO feeder"
type: feature
id: "F000022"
status: active
created: "2026-05-15"
updated: "2026-05-15"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "F000021_cj_goal_family_rename_and_drain--S000047_cj_goal_todo_fix_quiet_flag-20260515-184308"
blocked_by: "F000021"
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_improve_queue`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   -> detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

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

- [ ] Phase 1 (`evaluate <url>`) ships: `/CJ_improve-queue evaluate <url>` writes a single inline-comment-marked TODOS.md row matching the existing schema, with canonical URL + source-quote (HTML-comment-wrapped, ≤200 bytes) + impr-sig signature, on a Claude docs page.
- [ ] Idempotency holds: re-running `evaluate <url>` on the same canonical URL is a NO-OP (signature grep hit).
- [ ] The full flow works end-to-end: user removes the `<!--impr-draft-->` marker -> `/CJ_suggest` ranks the row -> `/CJ_goal_todo_fix` carries it to a merged PR citing the source URL.
- [ ] Atomic-write discipline: simulated kill -9 between mktemp + mv leaves TODOS.md byte-identical to its pre-run state.
- [ ] Pre-write dirty-check on TODOS.md refuses to run when uncommitted changes exist; clear stderr message.
- [ ] Concurrency: parallel `evaluate` invocations on different URLs serialize at the write step via mkdir-based lock; second invocation retries or exits 0 with "in-progress, retry".
- [ ] macOS-only gate fires loudly on non-Darwin.
- [ ] Subagent contract: stubbed verdict (`CJ_IMPROVE_QUEUE_VERDICT_FILE`) produces deterministic test output; malformed JSON is handled gracefully (stderr line, exit 0, no row appended).
- [ ] WebFetch failure mode: `verdict: "fetch_failed"` -> stderr line, exit 0, no row appended.
- [ ] WebFetch source-domain allowlist defaults to `docs.anthropic.com`/`anthropic.com`/`claude.com`/`github.com/anthropics/*`; off-allowlist URLs require `--allow-untrusted-source`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship `S000048_phase1_evaluate_url` — Phase 1 MVP (`evaluate <url>` mode).
- [ ] Defer Phase 2 (`audit`) and Phase 3 (`research <topic>`) until Phase 1 has been used on >=3 real URLs.
- [ ] (Optional/follow-on) `/CJ_suggest` patch to filter `<!--impr-draft-->`-tagged headings out of the active band — split across S000047 ship vs S000048's own scope (depending on bundling decision at implementation time).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-15: Created. F000022 scaffold from /office-hours design doc `chjiang-F000021_cj_goal_family_rename_and_drain-design-20260515-175709.md`. The misleading filename slug reflects the branch the design was generated on; the design's actual subject is `/CJ_improve-queue` and is a NEW feature, not a child of F000021. F000021 is named as a blocker (TODOS.md churn against legacy CJ_run/CJ_goal names).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_improve-queue/SKILL.md` (new)
- `skills/CJ_improve-queue/scripts/improve_queue.sh` (new)
- `skills-catalog.json` (catalog entry, status experimental)
- `rules/skill-routing.md` (routing entries for URL-evaluation phrasings)
- `tests/fixtures/CJ_improve-queue/*` (verdict + fetch fixtures)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Improvement-as-TODO unifies via OUTPUT (TODOS rows), not input — the three input dimensions (URL eval, repo audit, topic research) all converge on one shipping pipeline (`/CJ_suggest -> /CJ_goal_todo_fix -> /ship`), letting improvement work compound through the existing loop.
- The HANDOFF envelope pattern (mirroring `/CJ_goal_todo_fix`'s `CJ_GOAL_HANDOFF_BEGIN/END`) keeps subagent dispatch deterministic — bash owns canonicalization + allowlist + idempotency + write, orchestrator owns Agent dispatch, subagent owns reasoning + verdict JSON. Crisp ownership lines reduce the prose-only re-invocation footgun /autoplan flagged as CRITICAL-1.
- `<!--impr-draft-->` inline HTML-comment marker (chosen over `DRAFT —` heading prefix per /autoplan MAJOR-14) is invisible-in-rendered-markdown but greppable; promotion = remove the marker token, and `/CJ_suggest`'s patch becomes a one-line awk filter rather than two heading regex changes.
- WebFetch trust-boundary defense is layered: domain allowlist (default-on; bypass requires explicit flag) + source-quote HTML-comment-wrap (neutralizes downstream sensitive-surface regex match in `/CJ_goal_todo_fix`'s preflight). Closes /autoplan CRITICAL-4.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-15: Chose Approach C (improvement-as-TODO) over Approach B (sister skill with sub-modes). Summary: B's findings are ephemeral and reinvent queue management; C composes with the user's already-running `/loop /CJ_goal_todo_fix` and gets the existing pipeline's hygiene + ranking for free.
- [decision] 2026-05-15: Adopted HANDOFF envelope pattern from `/CJ_goal_todo_fix` instead of prose-only re-invocation (per /autoplan CRITICAL-1 fix). Summary: prose-only contract is the least-reliable surface; a model skipping the re-invoke leaves orphan request.json with no error.
- [decision] 2026-05-15: Re-scoped temp/backup/lock locations to `/tmp/cj-improve-queue/` (matching `/CJ_goal_todo_fix`'s precedent) rather than `.claude/tmp/` (per /autoplan CRITICAL-2 fix). Summary: `~/.claude/` is the user's global config, not a per-repo temp dir.
- [decision] 2026-05-15: Replaced `DRAFT — ` heading prefix with `<!--impr-draft-->` inline HTML-comment marker (per /autoplan MAJOR-14 fix). Summary: invisible-in-rendered-markdown + opt-out by single-token removal; eliminates typo-prone promotion gate and simplifies `/CJ_suggest` patch.
- [decision] 2026-05-15: Dropped synthetic `I<NNNNNN>` ID range from heading (per /autoplan CRITICAL-3 fix). Summary: rows flow through `/CJ_suggest`'s existing orphan-row path (no tracker join, +2 unblocked, default P3/M priority); avoids broadening regex propagation across validator + scaffolder + drain paths.
- [decision] 2026-05-15: WebFetch source-domain allowlist defaults on; off-allowlist URLs require explicit `--allow-untrusted-source` flag (per /autoplan CRITICAL-4 fix). Allowlist: `docs.anthropic.com`, `anthropic.com`, `claude.com`, `github.com/anthropics/*`. Combined with source-quote HTML-comment-wrapping, closes the regex-injection attack surface into `/CJ_goal_todo_fix` sensitive-surface preflight.
- [decision] 2026-05-15: Phased rollout — Phase 1 (`evaluate <url>`) ships first; Phase 2 (`audit`) and Phase 3 (`research <topic>`) deferred until Phase 1 has been used on >=3 real URLs to validate the cross-reference subagent's reasoning accuracy.
