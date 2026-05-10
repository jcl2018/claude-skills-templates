---
type: design
parent: F000014
title: "Personal-pipeline orchestrator — Feature Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Cross-story design for F000014. Story-scope detail (SPEC/TEST-SPEC) lives
     on S000026 + S000027. Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-135305.md -->

## Problem

The personal-workflow phase 2-4 loop (scaffold → implement → qa) ships as three
independent skills today (F000010). Manual invocation requires three keystrokes,
no enforced inter-phase gate, and trust in upstream skill self-checks is uneven
(e.g., scaffold-work-item runs `/personal-workflow check` at boundary but the
known Step 5 idempotency hole means the check passes vacuously on a duplicate
dir — TODOS.md:26).

F000011 + F000012 + F000013 all shipped through the manual three-step over the
past week. The friction is real and the signal about which gates matter is
sufficient to design an orchestrator. PHILOSOPHY.md:11/:61 warns against
orchestration skills (5 of 7 deleted historically as prose wrappers around what
Claude Code does naturally given CLAUDE.md rules); this orchestrator's structural
distinction is `Agent` tool dispatch with `subagent_type` per phase — fresh
context, file-only handoff between subagents, halt-on-red gates between phases —
which is plumbing, not prose.

## Shape of the solution

Single `/personal-pipeline` skill that takes a design-doc path. Internally:

- **Pre-scaffold idempotency check** (orchestrator) — read source design doc footer; route to Phase 1 or skip.
- **Phase 1: scaffold subagent** (Agent tool, fresh context) — invokes `/scaffold-work-item`, returns `RESULT: WORK_ITEM_DIR=<path>`.
- **Post-scaffold gate** (orchestrator) — `/personal-workflow check` + footer-write-back confirm + multi-story-feature halt branch + AskUserQuestion to confirm shape.
- **Phase 2: implement subagent** — invokes `/implement-from-spec`. **Orchestrator pre-collects AUQs from SPEC scan BEFORE dispatch** (subagents have no AskUserQuestion tool — see S000026 spike findings). Subagent runs in `--auto`-equivalent mode with answers threaded into prompt tail.
- **Post-implement gate** — `/personal-workflow check` + `scripts/validate.sh`.
- **Phase 3: qa subagent** — invokes `/qa-work-item`. Returns smoke/E2E/Phase2-gates triplet.
- **Post-QA gate** — parse tracker journal entries; halt on red.
- **Final summary + telemetry write** to `~/.gstack/analytics/personal-pipeline.jsonl`.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Verify Agent-subagent capabilities (AUQ bubble + RESULT-line reliability) | S000026 | [S000026_TRACKER.md](S000026_subagent_spike/S000026_TRACKER.md) |
| Build the /personal-pipeline skill (SKILL.md + pipeline.md + fixtures) | S000027 | [S000027_TRACKER.md](S000027_pipeline_skill/S000027_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A: full Agent-tool orchestrator (over B inline-prose, C shell-harness) | B is structurally identical to deleted /workflow (PHILOSOPHY anti-pattern); C trades interactive AskUserQuestion gates for marginal isolation gain over Agent subagents. A honors all 8 locked premises by construction. |
| 2 | File-only handoff BETWEEN SUBAGENTS; orchestrator-as-broker | User-added constraint mid-session. Subagents communicate only via filesystem with fresh context; the orchestrator passes file paths as Bash args (broker layer, not subagent-to-subagent state). Stating the carve-out explicitly avoids a self-contradictory premise. |
| 2.1 | **Phase 2 dispatch: orchestrator pre-collects AUQs (SUPERSEDES original design)** | S000026 spike (2026-05-09) found AskUserQuestion is **not in the deferred-tools list inside Agent subagents** in Claude Code 2.1.91 — tool unreachable, not hang. The original "subagent reports `RESULT: AUQ_NEEDED=...` and orchestrator re-AUQs" pattern is moot because the subagent cannot AUQ at all. New shape: orchestrator scans the SPEC's Components Affected for sensitive-surface paths AND Tradeoffs for taste-fork rows BEFORE dispatch, AUQs the human up front, then dispatches the subagent with answers threaded in. Findings in `tests/spike/subagent-capabilities/findings.md`. |
| 2.2 | **RESULT-line parser leniency (SUPERSEDES strict `^RESULT: ` parsing)** | S000026 spike leg (b) found subagents reliably produce RESULT-line CONTENT but inconsistently FORMAT it (2/5 strict hits; misses wrapped in markdown blockquotes or code fences). Strict `grep -E '^RESULT: '` is fragile. New parser shape: `grep -E 'RESULT: [A-Z_]+=' "$output" \| tail -1 \| sed 's/^[> ]\+//;s/```//g'` — strips `>` blockquote prefixes and code fences, finds the line wherever it lands. |
| 3 | Independent inter-step quality gates | User-added constraint mid-session. Orchestrator runs its own checks (does not trust upstream skill self-checks). Pre-scaffold idempotency, post-scaffold check + footer confirm, post-implement check + validate.sh, post-QA tracker parse. Halt-on-red default. |
| 4 | Decouple from TODOS.md:26 (scaffold Step 5 idempotency hole) | Orchestrator's pre-scaffold check uses the `Status: SCAFFOLDED → <path>` footer signal that scaffold ALREADY writes (Step 12). No upstream change required. TODOS.md:26 stays open as defense-in-depth for direct (non-orchestrator) invocations. |
| 5 | Sunset criterion: ≥3 of 5 `halted_at_gate` (mechanical only, no qualitative leg) | Spec-review iteration 2 caught the qualitative leg as retro-litigation by another name (recall bias guaranteed). Trip-wire is fully observable from `~/.gstack/analytics/personal-pipeline.jsonl` without user self-report. |
| 6 | Spike S000026 BLOCKS pipeline.md authoring | Two load-bearing unverified premises (AUQ bubble through Agent subagents; RESULT-line reliability across 5+ trials) gate the design. ~30 min each; either outcome workable but design changes shape based on results. |
| 7 | `subagent_type: general-purpose` for all 3 phases in v1 | Custom subagent types (`scaffold-runner` etc.) are deferred — would lock down tool access per phase but add infra. Revisit when there's a real need. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| AUQ bubble through Agent subagents may not work | S000026 spike (BLOCKING; pre-pipeline.md) |
| RESULT-line reliability across 5+ trials may be flaky (subagent appends helpful prose) | S000026 spike, leg (b) |
| Concurrent invocation may race on `work-items/` ID generation | Documented as accepted risk in v1 (PHILOSOPHY does not gate); revisit if a real collision happens |
| Multi-story feature decomposition pattern (orchestrator halts after scaffold for features with ≥1 child) may be the wrong call when we hit a real multi-story feature | Defer until we hit it; revisit at sunset checkpoint |
| Sensitive-surface AUQ propagation depends on subagent honoring "report and exit" instruction rather than auto-accepting | S000026 spike, leg (a) |

## Definition of done

- [ ] S000026 spike findings committed; both legs (AUQ bubble, RESULT-line reliability) have YES/NO verdicts
- [ ] `skills/personal-pipeline/SKILL.md` exists with valid frontmatter; cataloged; validated by `validate.sh`; deployed by `skills-deploy install`
- [ ] First real run on a small TODO entry green end-to-end via single `/personal-pipeline` invocation
- [ ] Pre-scaffold idempotency regression on F000010's design doc passes (footer detected, Phase 1 skipped, work-item reused)
- [ ] Post-implement gate catches a deliberately broken `validate.sh` invocation (regression test)
- [ ] Post-QA gate halts with AskUserQuestion on red smoke (regression test)
- [ ] Telemetry line appended to `~/.gstack/analytics/personal-pipeline.jsonl` per invocation
- [ ] Sunset trip-wire (≥3 of 5 `halted_at_gate`) verifiable from telemetry on the 6th invocation

## Not in scope

- **Multi-story feature looping in v1** — orchestrator halts after scaffold for feature-shaped work-items with ≥1 user-story child; user invokes implement+qa per child manually. Defer the outer loop until we hit a real multi-story feature.
- **`scripts/test.sh` in the post-implement gate** — slow; v1 runs `validate.sh` only. Revisit in v2 if real-world runs catch issues only test.sh would have caught.
- **Process-level isolation (`claude -p` shell harness)** — explicitly rejected as Approach C. Marginal isolation gain over Agent subagents costs the interactive AskUserQuestion gates.
- **Custom `subagent_type` per phase** — `general-purpose` for all 3 in v1.
- **TODOS.md:26 (scaffold Step 5 idempotency hole) fix** — defense-in-depth for non-orchestrator scaffold use; stays open as a separate item.
- **Concurrent-invocation locking on `work-items/`** — documented as accepted risk in v1.

## Pointers

- Parent tracker: [F000014_TRACKER.md](F000014_TRACKER.md)
- Roadmap: [F000014_ROADMAP.md](F000014_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-135305.md`
- Closes deferred entry: TODOS.md:20 (`/personal-pipeline` orchestrator P3/M)
- Extends: F000010 (the 3 pipeline skills this orchestrator wraps) and `chjiang-main-design-20260508-102829.md` (the original "three skills, no orchestrator" design that captured this as a deferred follow-up)
- Related TODO (defense-in-depth, not prereq): TODOS.md:26 (scaffold Step 5 idempotency hole)
