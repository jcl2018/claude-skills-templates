---
type: design
parent: S000026
title: "Subagent capabilities spike — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Brief stub — see parent F000014_DESIGN.md for the orchestrator context that
     motivates this spike. -->

## Problem

Two premises in F000014's design are load-bearing but unverified:

1. **AUQ bubble:** Can `AskUserQuestion` calls inside an Agent subagent reach the human, or do they fail/hang? Phase 2 (implement) of the orchestrator dispatches sensitive-surface AUQs by design; if those AUQs don't bubble, Phase 2 must be redesigned to pre-collect AUQs at the orchestrator before dispatch.
2. **RESULT-line reliability:** Across 5+ identical trial runs, does the subagent reliably end its final message with a controlled `RESULT: <key>=<value>` line, or does it tack on helpful prose? The orchestrator parses this contract with `grep -E '^RESULT: '`; if subagents are flaky, the parser must be lenient (last-line-matching, fenced output, or instruct subagent to wrap).

Either outcome is workable, but the design changes shape based on results. Spike before authoring pipeline.md.

## Shape of the solution

Two minimal shell probes + a markdown findings report. No skill code is written
during this story; orchestrator authoring is downstream.

```
tests/spike/subagent-capabilities/
  probe-auq.sh        # leg (a): AUQ bubble
  probe-result.sh     # leg (b): RESULT-line reliability across 5+ trials
  findings.md         # YES/NO verdicts + recommended downstream action
```

Each probe is ≤ 30 minutes of work. Probes use `claude -p` (or in-session manual
dispatch) to spawn a subagent with the test prompt and capture behavior.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Shell-script probes (not a real skill) | Goal is information, not shipped functionality. Quickest path to a YES/NO. Throwaway after findings.md is written. |
| 2 | Two probes, not one combined | AUQ-hang and RESULT-line-flakiness are different failure modes; isolating them speeds diagnosis. |
| 3 | 5+ trials for RESULT-line probe | One trial is anecdote, 5 is signal. If 5/5 reliable → good as-is. If 4/5 or worse → parser must be lenient. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Probe results may depend on Claude Code version / model overlay | Document version + overlay in findings.md alongside verdicts |
| AUQ-bubble behavior may differ between MCP AUQ variant and native | Probe both variants if both are available; document the asymmetry |
| 5 trials may not be enough to detect rare flakes | If verdict ambiguous, run 10 more |

## Definition of done

- [ ] Both probe scripts exist and are executable
- [ ] Both probes have been run; raw outputs captured (committed or referenced)
- [ ] `findings.md` documents verdicts (YES/NO) for both legs + version/overlay context + recommended downstream action
- [ ] If either leg failed: redesign options for parent F000014's Phase 2 documented in findings.md

## Not in scope

- Building any part of the /personal-pipeline skill (S000027's job)
- Probing other Agent-tool behaviors (cost, latency, parallelism) — only the two unverified premises matter for orchestrator design
- Writing automated CI for the probes — these are throwaway one-shots

## Pointers

- Parent tracker: [S000026_TRACKER.md](S000026_TRACKER.md)
- SPEC: [S000026_SPEC.md](S000026_SPEC.md)
- TEST-SPEC: [S000026_TEST-SPEC.md](S000026_TEST-SPEC.md)
- Parent feature: [F000014_DESIGN.md](../F000014_DESIGN.md)
