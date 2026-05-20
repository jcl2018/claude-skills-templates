---
type: roadmap
parent: F000026
title: "/CJ_goal_auto — full-handoff one-liner-to-deployed skill — Roadmap"
date: 2026-05-19
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

`/CJ_goal_auto` ships a thin orchestrator that turns a one-line idea into a deployed change with exactly one mandatory human touchpoint in v1 (the autoplan GATE #1 final-approval AUQ). The skill stages: worktree + capability self-check (Stage 0) → orchestrator-owned pre-code scope classifier (Stage 0.5) → workbench-owned design-doc generator (Stage 1) → fail-closed post-condition doc gate (Stage 1.5) → `/CJ_goal_run <doc> --handoff --no-drain` (Stage 2) → orchestrator-owned merge gate via `scripts/cj-handoff-gate.sh` between Phase 3 (`/ship` PR-prep) and Phase 4 (`/land-and-deploy` merge) → deploy (Stage 3). v1.0 single-PR only. Every gate is fail-closed: auto-approval requires positive proof of safety; absence of proof routes to human review.

## Non-Goals

- GATE #1 auto-approve — autoplan has no pre-gate machine-readable verdict (writes review logs on-approval only). v2 prerequisite, not a v1 stretch.
- `/ship` fork or argument injection — upstream, no-arg, owns its own flow. Auto-merge lives in workbench-owned `/CJ_goal_run` post-`/ship`/pre-`/land-and-deploy`.
- Multi-story / multi-PR auto-iterate — design doc restricts v1 to single-PR changes only; `/CJ_goal_run` Branch (b) excluded (no operator to reconcile bundled TODOS cleanup in an unattended run).
- Headless office-hours as Stage 1 — `SPAWNED_SESSION` is `OPENCLAW_SESSION`-gated only with no extension point for the classifier taxonomy or doc-write refusal. Rejected.
- Approach C (handoff queue: `[handoff]` TODOS row + scheduled `/CJ_goal_todo_fix --quiet` drain) — v2, only after Approach A is proven on ≥ ~5 real items.
- Atomic VERSION slot reservation — v2; concurrent `--handoff` runs are an accepted v1 limitation (preflight is advisory).
- Copilot bundle portability — workbench-only in v1 (macOS, this repo).
- Web-app canary as the primary mitigation for skill-md changes — size cap + denylist are the real controls.
- Automated ground-truth oracle for classifier false-negatives — not achievable; bounded by every-5th retro AUQ + size cap + denylist.

## Success Criteria

- [ ] `/CJ_goal_auto "<small idea>"` produces a deployed change with exactly one interactive prompt in v1 (autoplan GATE #1) when Stage 0.5 passes AND all GATE #2 conditions are provably met.
- [ ] `/CJ_goal_auto --dry-run "<idea>"` runs Stage 0+0.5 only and prints classifier verdict + reason, would-create paths, sentinel presence, and gate caps — zero writes, no Stage 1.
- [ ] Three explicit shapes echoed at run start: `"<idea>"` = human-gated, `--auto-merge-small-diffs "<idea>"` = auto-merge, `--dry-run "<idea>"` = preview. `--handoff` accepted as deprecated alias.
- [ ] `scripts/cj-handoff-gate.sh` is deterministic, exit-coded, and unit-tested in `scripts/test.sh` via tests 1–7 (denylist hit, size cap, rename, symlink, test-surface, frozen-base regression, QA predicate). Tests 8–10 lint: GATE #1 AUQ untouched, sentinel co-located with the gate call, Stage 1.5 abort path verified. Test 11 (classifier spot-check) labeled non-proof.
- [ ] Flag rename `--handoff` → `--auto-merge-small-diffs` + alias resolves; structured halt contract (`next_action=`/`resume_cmd=`/`pr_url=`/`work_item_dir=`); per-run audit receipt at `~/.gstack/analytics/CJ_goal_auto.jsonl`; `--audit`/`--list-handoffs` mode; every-run retro AUQ for first 5 auto-merges then every-5th; informed GATE #1 prints Problem Statement + Recommended Approach pre-AUQ.
- [ ] `validate.sh` + `test.sh` green; catalog entry `status: experimental`, `depends.skills: [CJ_goal_run]`; routing rule in `rules/skill-routing.md`; `--handoff`/`--no-drain` + co-located sentinel wired into `skills/CJ_goal_run/run.md` at the post-`/ship`/pre-`/land-and-deploy` point (NOT `SKILL.md`, NOT inside `/ship`); VERSION + CHANGELOG bumped.
- [ ] Bootstrap PR is human-reviewed by construction (it edits denylisted paths so the gate cannot auto-approve its own introduction).
- [ ] One dogfood run end-to-end on a real small item before unattended trust.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000056](S000056_cj_goal_auto_v1/S000056_TRACKER.md) | v1.0 full-handoff one-liner-to-deployed skill — Stages 0–3 + `scripts/cj-handoff-gate.sh` + `/CJ_goal_run` wiring (`--handoff` / `--no-drain` / co-located sentinel) + `scripts/test.sh` tests 1–11 + catalog + routing + VERSION + CHANGELOG + dogfood | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000056 — v1.0 thin orchestrator + handoff gate | 2026-05-20 | Not Started | chjiang | Stages 0–3 + gate helper + 10 deterministic/lint tests + classifier spot-check + `/CJ_goal_run` wiring + flag rename + audit receipt + retro AUQ + informed GATE #1 | — |
| 2 | End-to-end pipeline dogfood — one real small item through `/CJ_goal_auto --auto-merge-small-diffs` | 2026-05-20 | Not Started | chjiang | Validates Stage 1 generator's required-section contract end-to-end + GATE #2 helper against real Phase-2 markers; surfaces v1.0.1 follow-ups | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- {YYYY-MM-DD}: {PR# or version} — {brief description}

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000056 v1.0 thin orchestrator + handoff gate --> #2 End-to-end dogfood on one real small item
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Does the workbench-owned Stage 1 generator's output reliably clear `/CJ_goal_run` pre-flight on first invocation? | Assignment Q2 (hand-write minimal doc; confirm pre-flight passes) is the pre-scaffold validation; first Stage 1 dogfood run is the real proof. |
| Classifier false-negative rate over the first 5 auto-merges | Every-run retro AUQ surfaces the diffs; recalibrate the classifier prompt if any should have been human-reviewed. The "disable on ≥1 bad auto-merge" sunset trigger only fires if the human notices and annotates the jsonl log — bounded by size cap + denylist as the real controls. |
| Should the FIX_PLAN preamble pattern (blast-radius detection BEFORE fix is written) port from `/CJ_goal_investigate`? | Out of v1 scope; revisit if Stage 0.5 classifier proves insufficient at preventing blast-radius surprises. |
