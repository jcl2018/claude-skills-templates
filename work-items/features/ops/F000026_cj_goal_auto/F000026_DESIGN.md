---
type: design
parent: F000026
title: "/CJ_goal_auto — full-handoff one-liner-to-deployed skill — Feature Design"
version: 1
status: Draft
date: 2026-05-19
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

`/CJ_goal_run` already chains the entire pipeline (autoplan → scaffold → impl → QA → /ship → /land-and-deploy). It requires an APPROVED design doc as input (pre-flight asserts the doc is under `~/.gstack/projects/` and has `Status: APPROVED`; `skills/CJ_goal_run/SKILL.md:140`, `:245-246`). For small features, or features where the user has no design preference, producing that doc through the interactive `/office-hours` diagnostic is disproportionate friction.

The user wants to hand a one-line idea to Claude and get a deployed change back, with Claude making every recommended decision — but only when the change is small and safe enough that unattended auto-approval is defensible. Verbatim ask: "for some smaller features or features I don't have preference, I can handoff to you entirely."

## Shape of the solution

A thin new skill `/CJ_goal_auto` that takes a one-liner and stages it through:

- **Stage 0** — worktree (reuses F000025 `cj-worktree-init.sh` with per-run-unique naming) + `check-version-queue.sh` preflight + `--handoff` capability self-check via sentinel grep on resolved `CJ_goal_run/run.md`. Fail-closed: if the deployed copy predates the flag, halt with the manual route.
- **Stage 0.5** — orchestrator-owned pre-code scope classifier. Returns `small-unambiguous | needs-human-taste | too-big`. Only `small-unambiguous` proceeds. Append-only jsonl log at `~/.gstack/analytics/cj-goal-auto-classifier.jsonl` (orchestrator owns the write; the subagent only returns a verdict).
- **Stage 1** — workbench-owned design-doc generator from a fixed template (NOT headless office-hours, which is not a real contract — see Decisions). Writes the required sections (`Problem Statement`, `Premises`, `Recommended Approach`, `Success Criteria`, `Distribution Plan`, `Status: APPROVED`) directly to `~/.gstack/projects/<slug>/<user>-<branch>-design-<datetime>.md` — the exact path the orchestrator computes; Stage 1.5 verifies, never assumes.
- **Stage 1.5** — fail-closed post-condition doc gate: assert the file exists at the computed path, contains `Status: APPROVED`, and every required section is present and non-empty. Any miss → abort with manual-route message; Stage 2 never invoked.
- **Stage 2** — invoke `/CJ_goal_run <doc> --handoff --no-drain`. `--handoff` does NOT inject into `/ship`. The auto-merge gate lives in workbench-owned `/CJ_goal_run`, evaluated AFTER Phase 3 (`/ship` has created the PR — that's PR-prep, F000021-allowed) and BEFORE Phase 4 (`/land-and-deploy`, which performs the merge). GATE #1 (autoplan-final) is unchanged: always human in v1.
- **Stage 3** — Deploy. Phase 4 runs `/land-and-deploy --suppress-readiness-gate`; `--no-drain` suppresses Phase 5's TODO-drain AUQ. PR body carries the pinned `BASE` SHA + `auto-merged under handoff: N files / M lines / QA <markers>` when the gate auto-approved.

Single user-story decomposition — the design doc constrains v1 to single-PR changes only:

| Concern | User-story | Artifact |
|---------|-----------|----------|
| v1.0 thin orchestrator + workbench-owned generator + handoff gate (Stages 0–3, gate helper, tests, wiring) | S000056 | [S000056_cj_goal_auto_v1/S000056_TRACKER.md](S000056_cj_goal_auto_v1/S000056_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (chosen, corrected): thin orchestrator + workbench-owned Stage-1 generator + `/CJ_goal_run --handoff` | Reuses the existing pipeline unchanged; only the design-doc *source* changes. B (two-skill split) folded in until a second caller appears. C (handoff queue) deferred to v2 — premature indirection before A is proven. Rejected: headless office-hours — `SPAWNED_SESSION` triggers solely on `OPENCLAW_SESSION` env var, has no extension point for an injected taxonomy or "don't write a doc" mode; driving it headlessly is not a real contract. |
| 2 | Stage 1 is a workbench-owned autonomous generator, NOT headless office-hours (P4 corrected by spec review) | Spec review proved office-hours spawned mode would either block on `AskUserQuestion` or self-report `BLOCKED`, and even with the env var forced, no way to inject the `small-unambiguous | needs-human-taste | too-big` taxonomy or to conditionally skip writing a doc. Recorded so it is not re-litigated. |
| 3 | GATE #1 auto-approve cut from v1; GATE #1 is always-human | Confirmed first-hand by reading the `autoplan` skill: review-log artifacts (`*-reviews.jsonl`) are written ONLY on-approval. No pre-gate machine-readable verdict at any stable path. v2 prerequisite, not a v1 unknown. v1 has one mandatory human prompt per run. |
| 4 | GATE #2 is an orchestrator-owned merge gate (post-`/ship`/pre-`/land-and-deploy`) via deterministic helper `scripts/cj-handoff-gate.sh` | Eng dual-voice proved `--handoff` cannot inject into `/ship` (upstream, no-arg, owns its flow — D9 → option A). `/CJ_goal_run` is workbench-owned and modifiable; the gate lives there, not in `/ship`. Helper extracted as a real script so it is unit-testable from `scripts/test.sh`, NOT dependent on the `eval.sh` LLM harness (F5). |
| 5 | Frozen base via `git fetch origin main` + `BASE=$(git merge-base origin/main HEAD)`, pinned for every subsequent diff | Two-dot from frozen merge-base = three-dot from origin/main, stable under main drift (F2). Pinned `BASE` SHA written to PR body for auditability. |
| 6 | Rename/symlink-safe denylist matching via `git diff --no-renames --raw -z $BASE HEAD` | `--no-renames` makes a rename of a denylisted file surface as add+delete so the delete trips the denylist. Fail closed on `R`/`C`/`T` status touching denylisted glob on EITHER old or new path; fail closed on any new/changed symlink (mode 120000) anywhere (F4). |
| 7 | QA predicate uses real Phase-2 markers (`PIPELINE_END_STATE=green` AND `SMOKE=pass` AND `E2E=pass` AND all `PHASE2_GATES` checked) | `/CJ_personal-pipeline` emits these markers (`pipeline.md:597`); there is no "high/medium severity" scale. Codex finding; predicate redefined to what actually exists. |
| 8 | Denylist `tests/**`, `scripts/*test*.{sh,py}`, `*fixture*`, `*.golden` in addition to the inherited sensitive-surface list | validate.sh treats those paths as consistency-checked, not security-sensitive. A ≤120-line diff that weakens a test assertion while touching no other denylisted path would otherwise pass every GATE #2 condition. Closes CEO-flagged hole. |
| 9 | Flag rename `--handoff` → `--auto-merge-small-diffs`; `--handoff` deprecated alias kept | Both DX voices independently rated user-facing contract not ship-ready; biggest risk = "accidental consent." Literal name says what it does. Skill name `/CJ_goal_auto` stays (family-consistent). |
| 10 | Three explicit public shapes + resolved-mode echo at run start | `/CJ_goal_auto "<idea>"` = human-gated on-ramp (both-CEO-voices-preferred); `--auto-merge-small-diffs "<idea>"` = auto-merge; `--dry-run "<idea>"` = Stage 0+0.5 only, zero writes. Ports `CJ_goal_todo_fix` `todo_fix.sh` mode echo + `CJ_goal_investigate --dry-run`. |
| 11 | Structured halt contract: every halt emits stop block + `next_action=` + `resume_cmd=` + `pr_url=`/`work_item_dir=` when applicable | Ports `CJ_goal_investigate`. GATE #2 demotion MUST name which condition tripped (with actual count vs cap / denylisted path / Phase-2 marker) and state "PR #N is created and review-ready; `gh pr diff N`, merge manually if good." |
| 12 | Per-run audit receipt at `~/.gstack/analytics/CJ_goal_auto.jsonl`; `--audit`/`--list-handoffs` read-only mode | Replaces thin 3-way cross-reference audit. Every run records classifier verdict, doc path, work-item dir, PR URL, pinned BASE SHA, changed files, added lines, denylist result, Phase-2 markers, gate result, resume_cmd. |
| 13 | Every-run retro AUQ for first 5 auto-merges, then every-5th cadence | Tightest trust margin while the classifier has no data; relaxes once a baseline accumulates. Real feedback loop without per-run friction. |
| 14 | Informed GATE #1: print generated doc's Problem Statement + Recommended Approach before the autoplan AUQ fires | So the user is not reflexively approving a plan they never read. |
| 15 | F000021 autonomy ceiling exception is scoped, ratified by user at D8 against both CEO voices' re-scope recommendation, recorded inline (not buried) | Single-developer personal dogfood tooling; explicit fire-and-forget intent on no-preference changes; residual risk bounded by size cap + fail-closed gates + denylist; per-invocation opt-in, not default. Narrower than F000021's TODO-drain case because of the pre-code classifier + post-impl size/denylist/QA gate that the TODO-drain did not have. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Classifier false-negative rate (no oracle; the jsonl log records the classifier's own verdict, not ground truth) | Accepted residual; bounded by size cap + denylist + every-5th retro AUQ. The "disable on ≥1 bad auto-merge" sunset trigger only fires if a human notices and annotates the log. Real controls are the size cap and denylist, not the log. |
| Concurrent VERSION collision (Eng F3) — `check-version-queue.sh` only reads open PRs; two `/CJ_goal_auto` runs started seconds apart both pass preflight then claim the same slot | Accepted v1 limitation. Preflight is advisory, not a hard guarantee. Do not run two `--auto-merge-small-diffs` invocations concurrently. Atomic slot reservation deferred to v2 (only matters once Approach C scheduled drain lands). |
| Detection signal for skill-md changes is "a later skill invocation behaves wrong" — no telemetry loop | Accepted with eyes open (P5). Mitigated by size cap (small blast radius) + denylist (shipping/test machinery protected) + per-invocation opt-in + audit log. Not detected in real time. |
| `--handoff` flag-name confusion / accidental consent | Resolved at design — flag rename `--handoff` → `--auto-merge-small-diffs`; deprecated alias kept; resolved-mode echo at run start; three explicit shapes documented up front; informed GATE #1. |
| GATE #1 verdict artifact — RESOLVED not open | autoplan has no pre-gate machine-readable verdict (writes logs on-approval only). GATE #1 is always-human in v1; re-opening is a v2 prerequisite, not a v1 unknown. |
| v2 = Approach C (`[handoff]` TODOS-row convention + scheduled `/CJ_goal_todo_fix --quiet` drain) | Defer until A is proven on ≥ ~5 real small features. Not v1 scope. |

## Definition of done

- [ ] `/CJ_goal_auto "<small idea>"` produces a deployed change with exactly one interactive prompt in v1 (autoplan GATE #1) when Stage 0.5 passes AND all GATE #2 conditions are provably met.
- [ ] `/CJ_goal_auto --dry-run "<idea>"` runs Stage 0+0.5 only, prints classifier verdict + reason, would-create paths, sentinel presence, and gate caps; zero writes, no Stage 1.
- [ ] `scripts/cj-handoff-gate.sh` is deterministic, exit-coded, and unit-tested in `scripts/test.sh` via tests 1–7 (denylist, size cap, rename, symlink, test surface, frozen base, QA predicate).
- [ ] Tests 8–10 (lint/regression): `--handoff` never suppresses autoplan GATE #1 AUQ; `CJ_goal_run` sentinel co-located with the gate call; Stage 1.5 aborts when doc invalid and Stage 2 never invoked.
- [ ] Test 11 (classifier spot-check, labeled non-proof): fixed one-liner set maps to expected verdicts.
- [ ] Flag rename + alias + three shapes + resolved-mode echo + structured halt contract + per-run audit receipt + every-5th retro AUQ + informed GATE #1 wired and observable in dogfood run.
- [ ] `validate.sh` + `test.sh` green; catalog entry `status: experimental`; routing rule added; `--handoff`/`--no-drain` + co-located sentinel wired into `skills/CJ_goal_run/run.md` (NOT `SKILL.md`, NOT inside `/ship`); VERSION + CHANGELOG bumped.
- [ ] One dogfood run end-to-end on a real small item before unattended trust.

## Not in scope

- GATE #1 auto-approve — autoplan has no pre-gate machine-readable verdict; v2 prerequisite, not a v1 stretch.
- `/ship` fork or injection — `/ship` is upstream, no-arg; gate lives in workbench-owned `/CJ_goal_run` post-`/ship`/pre-`/land-and-deploy`.
- Multi-story / multi-PR auto-iterate — design doc explicitly restricts v1 to "Single-PR changes only." `/CJ_goal_run` Branch (b) multi-story path is excluded because it ships per-child PRs without bundled TODOS cleanup (CLAUDE.md "Edge case 2") and unattended runs have no operator to reconcile.
- Headless office-hours as Stage 1 — `SPAWNED_SESSION` is `OPENCLAW_SESSION`-gated only, no extension point for the classifier taxonomy or doc-write refusal. Rejected approach, recorded.
- Approach C (handoff queue: `[handoff]` TODOS row + scheduled `/CJ_goal_todo_fix --quiet` drain) — v2, after A is proven on ≥ ~5 real items.
- Atomic VERSION slot reservation — v2; only matters once concurrent unattended scheduled drain (Approach C) lands.
- Copilot bundle portability — workbench-only in v1 (macOS, this repo).
- Web-app canary / health checks as the primary mitigation for skill-md changes — they were built for a web app; for prompt content the real mitigation is the size cap (small blast radius) + denylist.
- An automated ground-truth oracle for classifier false-negatives — not achievable; the every-5th-auto-merge retro AUQ + the size cap + denylist are the real controls.

## Pointers

- Parent tracker: [F000026_TRACKER.md](F000026_TRACKER.md)
- Roadmap: [F000026_ROADMAP.md](F000026_ROADMAP.md)
- /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-flamboyant-johnson-c3d0e5-design-20260517-125333.md`
- Autoplan restore point: `~/.gstack/projects/jcl2018-claude-skills-templates/claude-flamboyant-johnson-c3d0e5-autoplan-restore-20260517-132850.md`
- Sibling skills: `/CJ_goal_run`, `/CJ_goal_todo_fix`, `/CJ_goal_investigate`
- F000021 autonomy ceiling decision: `work-items/features/ops/F000021_cj_goal_family_rename_and_drain/F000021_DESIGN.md:106`
- F000025 worktree pattern: `scripts/cj-worktree-init.sh`
- Upstream gstack: `/autoplan`, `/ship`, `/land-and-deploy`, `/investigate`
