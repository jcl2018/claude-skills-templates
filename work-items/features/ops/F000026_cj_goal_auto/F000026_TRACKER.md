---
name: "/CJ_goal_auto — full-handoff one-liner-to-deployed skill"
type: feature
id: "F000026"
status: active
created: "2026-05-19"
updated: "2026-05-19"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/flamboyant-johnson-c3d0e5"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_goal_auto`
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

- [ ] `/CJ_goal_auto "<small idea>"` produces a deployed change with exactly one interactive prompt in v1 (the autoplan GATE #1 final-approval AUQ) when Stage 0.5 passes AND all GATE #2 conditions are provably met.
- [ ] `/CJ_goal_auto --dry-run "<idea>"` runs Stage 0 + 0.5 only and prints classifier verdict, would-create paths, sentinel presence, and gate caps — zero writes, no Stage 1.
- [ ] `--handoff` deprecated alias resolves to `--auto-merge-small-diffs`; flag name + three explicit shapes echoed at run start.
- [ ] `scripts/cj-handoff-gate.sh` is deterministic, exit-coded, unit-tested in `scripts/test.sh` (no eval.sh dependency).
- [ ] Every gate is fail-closed: tests 1–10 in `scripts/test.sh` enforce the deterministic part (denylist, size cap, rename/symlink, test surface, frozen base, QA predicate, GATE #1 untouched, sentinel co-located, Stage 1.5 abort).
- [ ] Per-run audit receipt written to `~/.gstack/analytics/CJ_goal_auto.jsonl`; `--audit` mode prints last N.
- [ ] Every-run retro AUQ fires for first 5 auto-merges; cadence relaxes to every-5th after.
- [ ] `validate.sh` + `test.sh` green; catalog entry `status: experimental`; routing rule added; `--handoff`/`--no-drain` + co-located sentinel wired into `skills/CJ_goal_run/run.md` at post-`/ship`/pre-`/land-and-deploy` point.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000056 — v1.0 full-handoff one-liner-to-deployed skill
- [ ] (v2 deferred) Approach C — `[handoff]` TODOS-row convention + scheduled `/CJ_goal_todo_fix --quiet` drain
- [ ] (v2 deferred) GATE #1 auto-approve — requires autoplan to emit a stable pre-gate verdict artifact first
- [ ] (v2 deferred) Atomic VERSION slot reservation — concurrent `--handoff` runs not supported in v1

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-19: Created. Thin orchestrator `/CJ_goal_auto` — one-liner → workbench-owned design-doc generator → `/CJ_goal_run --handoff --no-drain` → orchestrator-owned merge gate (`scripts/cj-handoff-gate.sh`) between `/ship` PR-prep and `/land-and-deploy` merge. v1.0 single-PR only. F000021 autonomy ceiling exception is scoped, ratified by the user at D8, and recorded inline.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills/CJ_goal_auto/SKILL.md (new)
- skills/CJ_goal_auto/auto.md (new)
- scripts/cj-handoff-gate.sh (new)
- skills/CJ_goal_run/run.md (modified — `--handoff` / `--no-drain` / sentinel)
- skills-catalog.json (modified — experimental entry)
- rules/skill-routing.md (modified — `/CJ_goal_auto "<idea>"` route)
- scripts/test.sh (modified — 10 deterministic + lint tests)
- VERSION (modified)
- CHANGELOG.md (modified)
- README.md (modified)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The headless-office-hours premise is not a contract: `SPAWNED_SESSION` triggers solely on the `OPENCLAW_SESSION` env var and has no extension point for an injected taxonomy or "don't write a doc" mode. Stage 1 must therefore be workbench-owned (P4 corrected by spec review).
- `--handoff` cannot inject into `/ship`: `/ship` is upstream, Skill-tool-invoked with no argument channel, and owns its own non-interactive flow. The auto-merge gate has to live in the workbench-owned `/CJ_goal_run` between Phase 3 (`/ship` PR-prep, F000021-allowed) and Phase 4 (`/land-and-deploy` merge). No `/ship` fork.
- GATE #1 auto-approve is not buildable in v1: autoplan writes its review-log artifacts only on-approval; there is no stable pre-gate machine-readable verdict at any path. v1 is always-human at GATE #1; re-opening it is a v2 prerequisite, not a v1 unknown.
- For skill-markdown changes, `/land-and-deploy`'s web canary/health checks are near-vacuous. The real mitigation is the size cap making the blast radius small, plus the denylist keeping all shipping/test machinery out of the autonomous path. Detection is the expensive part, and it's not real-time for prompt content.
- The classifier jsonl log records the classifier's *own* verdict, not ground truth. The every-5th-auto-merge retro AUQ is the only real feedback loop; the log is audit, not a control.
- `tests/**` had to be denylisted explicitly: validate.sh treats those paths as consistency-checked, not security-sensitive, so the inherited list missed test-assertion weakening — a ≤120-line diff that quietly lowers a test bar would otherwise pass every other GATE #2 condition.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-19: Approach A (corrected) — thin orchestrator + workbench-owned Stage-1 generator + `/CJ_goal_run --handoff`. Rejected: headless office-hours (no real contract), two-skill split (premature), handoff queue (premature indirection, deferred to v2).
- [decision] 2026-05-19: P4 corrected — Stage 1 is a workbench-owned autonomous generator, not headless office-hours. `SPAWNED_SESSION` only flips on `OPENCLAW_SESSION` env var; no extension point for the classifier taxonomy or refusal-to-write semantics.
- [decision] 2026-05-19: GATE #1 auto-approve cut from v1 — autoplan has no pre-gate machine-readable verdict (writes logs on-approval only). v1 is unconditionally one human prompt per run; re-opening is a v2 prerequisite.
- [decision] 2026-05-19: GATE #2 reframed as orchestrator-owned merge gate via `scripts/cj-handoff-gate.sh`, evaluated between Phase 3 and Phase 4 inside `/CJ_goal_run`. No `/ship` fork. Frozen `git merge-base origin/main HEAD` base, rename/symlink-safe matching via `git diff --no-renames --raw -z`, deterministic exit-coded helper.
- [decision] 2026-05-19: QA predicate fixed to real Phase-2 markers (`PIPELINE_END_STATE=green` AND `SMOKE=pass` AND `E2E=pass` AND all `PHASE2_GATES` checked). No fictional severity scale.
- [decision] 2026-05-19: `tests/**` + `scripts/*test*.{sh,py}` + `*fixture*` / `*.golden` denylisted — closes CEO-flagged test-assertion-weakening hole.
- [decision] 2026-05-19: Flag rename `--handoff` → `--auto-merge-small-diffs`; `--handoff` kept as deprecated alias. Three explicit public shapes (`"<idea>"` human-gated, `--auto-merge-small-diffs "<idea>"`, `--dry-run "<idea>"`). Resolved-mode echo at run start.
- [decision] 2026-05-19: Per-run audit receipt at `~/.gstack/analytics/CJ_goal_auto.jsonl`; `--audit`/`--list-handoffs` read-only mode. Every-run retro AUQ for first 5 auto-merges, then every-5th.
- [decision] 2026-05-19: F000021 autonomy ceiling exception is scoped, ratified by user at D8 against both CEO voices' re-scope recommendation, recorded as a single gated opt-in puncture (not a silent reversal).
- [decision] 2026-05-19: Concurrent `--handoff` VERSION collision (Eng F3) is an accepted v1 limitation. `check-version-queue.sh` preflight is advisory, not a hard guarantee. Atomic slot reservation deferred to v2 (only matters once Approach C scheduled drain lands).
- [decision] 2026-05-19: Bootstrap PR is human-reviewed by construction — it edits `skills/CJ_goal_run/SKILL.md` (denylisted) + adds `skills/CJ_goal_auto/**` (denylisted), so the gate can never auto-approve its own introduction.
