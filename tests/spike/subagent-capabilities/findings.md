# Subagent capabilities spike — Findings

## Context

- **Date run:** 2026-05-09
- **Claude Code version:** 2.1.91
- **Model overlay:** opus (Opus 4.7 / claude-opus-4-7)
- **Operator:** chjiang
- **Spike runner:** Live in-session execution (Agent tool subagent for leg a + `claude -p` × 5 trials for leg b)

## Leg (a): AUQ bubble

**VERDICT:** AUQ_BUBBLES=no SUBCLASS=error

### Notes

The Agent tool subagent (`subagent_type: general-purpose`) reported that
`AskUserQuestion` is **not in the deferred-tools list** of its environment at
all. ToolSearch with `select:AskUserQuestion` returned "No matching deferred
tools found"; keyword search for "ask user question" surfaced unrelated tools
(scheduled-tasks, Monitor, TaskStop) but never AskUserQuestion. The probe
failed at the schema-load step — the subagent could not even attempt to call
AUQ.

This is closer to "tool unavailable" than "hang" or "auto-cancel" — the call
never happens at all from inside the subagent.

Implication: any orchestrator design that has the implement-phase subagent
AUQ the human (e.g., for sensitive-surface confirmations or taste forks) is
broken by construction in this Claude Code version. The orchestrator (parent
session) is the only layer where AUQ works.

## Leg (b): RESULT-line reliability

**VERDICT:** RESULT_LINE_HITS=2/5

### Notes

Failure modes (from `tests/spike/subagent-capabilities/raw-outputs/trial-{3,4,5}.txt`):

- **Trials 1, 2 — HIT.** Last non-blank line was the bare `RESULT: STATUS=ok`. Strict `^RESULT: ` parsing would catch these.
- **Trials 3, 4 — MISS, markdown-quote prefix.** Last non-blank line was `> RESULT: STATUS=ok` (the parent re-quoted the subagent's final line in a markdown blockquote). The text is present; the prefix throws strict parsing.
- **Trial 5 — MISS, fenced code block.** Last non-blank line was ` ``` ` (a closing code fence). The subagent wrapped its output in a fence; `RESULT: STATUS=ok` is inside the fence, not the last line.

The signal: subagents reliably produce the correct **content**, but the
final-line wrapping is non-deterministic. Strict `grep -E '^RESULT: '` against
the last-line-only is fragile (60% miss in 5 trials). A lenient parser that
strips `>` prefixes / code fences and uses `grep 'RESULT: '` against the full
output (then `tail -1` of matches) would have caught all 5 trials in this run.

## Recommended downstream action

(Pick exactly one. Refer to F000014_DESIGN.md Big decisions table.)

- [ ] **Design as-is** — both legs green; S000027's pipeline.md can be authored per F000014 design without modification.
- [ ] **Redesign Phase 2 to pre-collect AUQs** — leg (a) failed; orchestrator must scan SPEC for sensitive-surface markers BEFORE dispatching the implement subagent, then AUQ to human, then dispatch with answer threaded into prompt tail. Phase 2 subagent never calls AUQ.
- [ ] **Add parser leniency** — leg (b) failed; orchestrator's `RESULT:` parser must do last-line matching, accept fenced output, or instruct subagent to wrap RESULT in fences and parse the wrapper.
- [x] **Both redesigns** — both legs failed; apply both mitigations above.

## Implications for F000014 / S000027

S000027's `pipeline.md` MUST be authored with two adjustments to the F000014_DESIGN baseline:

1. **Phase 2 dispatch model: orchestrator pre-collects AUQs.** Before invoking the implement subagent, the orchestrator scans the user-story SPEC's Components Affected for sensitive-surface paths (catalog, manifests, validators, templates) AND scans Tradeoffs for taste-fork rows with multiple alternatives. The orchestrator AUQs the human for every potential AUQ point UP FRONT, then dispatches the subagent in an `--auto`-equivalent mode threading the human's answers as additional prompt context. The subagent runs without ever attempting to call AskUserQuestion. The `RESULT: AUQ_NEEDED=...` return contract proposed in F000014_DESIGN becomes redundant for the AUQ surface (subagent has no way to AUQ anyway) — instead the contract should be `RESULT: STATUS=...` plus optional `RESULT: ESCALATION_NEEDED=<reason>` for cases the orchestrator's pre-scan missed.

2. **RESULT-line parser leniency.** Use `grep -E 'RESULT: [A-Z_]+=' "$output" | tail -1 | sed 's/^[> ]\+//;s/```//g'` (or equivalent) instead of `grep -E '^RESULT: '`. This strips markdown blockquote prefixes and code fences, so subagent output wrapping doesn't break parsing. Document the leniency contract in pipeline.md.

These adjustments should be applied to S000027's SPEC + the eventual pipeline.md authoring; F000014_DESIGN's "Big decisions" table should be updated to reflect that Phase 2 dispatch is "pre-collect AUQs" not "subagent reports AUQ_NEEDED".

## 2026-05-11 Re-probe: Skill tool surface (D000018)

**VERDICT (re-probe, both subagent types):** SKILL=yes, AUQ=no, AGENT=no.

### Why re-probed

D000018 surfaced a recurring `[qa-e2e] ambiguous — structural inspection`
pattern across S000027, S000028, S000022, S000020, and S000030. The 2026-05-09
spike above correctly established AUQ + Agent absence but did NOT explicitly
audit whether the subagent had the `Skill` tool. The /CJ_qa-work-item Step 7
prompt named only Read / Bash / Grep / Glob, which would silently cause
skill-invoking E2E rows to degrade even if `Skill=yes` at the tool surface
level. A direct re-probe was needed to disambiguate "subagent can't /skill"
(architectural) from "Step 7 prompt forgot to mention Skill" (prompt blind
spot).

### Re-probe method

Spawned a fresh Agent subagent with `subagent_type: "general-purpose"` and
asked it to enumerate its deferred-tools surface via ToolSearch. Repeated
with `subagent_type: "claude"`. Both reported `Skill` as available; both
confirmed `AskUserQuestion` and `Agent` were absent (matching the 2026-05-09
result for those two tools).

### Implication

The Step 7 prompt was the blind spot, not the subagent capabilities. The
fix in D000018 (Approach B) is:

1. Update Step 7's stable preamble to list `Skill` alongside Read/Bash/Grep/Glob
   and to grant explicit permission for /skill invocation. This addresses the
   prompt-only failure mode.
2. Add a Step 4.5 row classifier that partitions E2E rows by tool-need
   (read-only / skill-invoking → subagent; interactive / recursive →
   parent-inline). This addresses the AUQ + Agent absence (which the
   2026-05-09 spike correctly identified).
3. Add a Step 7.5 parent-inline execution path for the interactive /
   recursive partition.
4. Update Step 8 to aggregate `[qa-e2e]` entries from both sources by row
   number.

Net effect: skill-invoking rows execute end-to-end inside the subagent (no
degradation to structural inspection); interactive / recursive rows execute
parent-inline using the parent's full toolbelt. Both sources write to the
same `[qa-e2e] E#` journal-entry shape so Step 8 aggregates cleanly.

### Correction to the 2026-05-09 spike

The earlier spike's leg (a) and leg (b) findings are still correct. The
spike's implication block, however, implied (by omission) that all
E2E-execution problems would route through the AUQ-absence axis, which left
the prompt-text blind spot unaudited. The two re-probes (this 2026-05-11
note + the qa.md Step 7 prompt text in `skills/CJ_qa-work-item/qa.md`)
together close the gap.
