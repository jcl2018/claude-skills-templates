---
name: "Subagent capabilities spike"
type: user-story
id: "S000026"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000014"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/personal-pipeline"
blocked_by: ""
---

<!-- BLOCKING for S000027 (pipeline.md authoring). The /personal-pipeline design
     hinges on two unverified premises about Agent-tool subagent behavior. This
     story verifies them before any orchestrator code is written. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/personal-pipeline` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `tests/spike/subagent-capabilities/probe-auq.sh` runs and produces a clear YES/NO verdict on whether `AskUserQuestion` calls inside an Agent subagent reach the human
- [ ] `tests/spike/subagent-capabilities/probe-result.sh` runs 5+ trials and reports whether the subagent reliably terminates with a parseable `RESULT: <key>=<value>` final line
- [ ] `tests/spike/subagent-capabilities/findings.md` exists with both verdicts + recommended downstream action ("design as-is" vs "redesign Phase 2 to pre-collect AUQs")
- [ ] Findings report committed BEFORE S000027's `pipeline.md` authoring begins

## Todos

- [ ] Confirm exact `Agent` vs `Task` allowed-tools identifier in `~/.claude/settings.json` (60-second grep — Step 0 of parent design; not blocking S000026 itself)
- [x] Implement `probe-auq.sh` — operator-driven (claude -p has no human for AUQ leg) + optional `--try-headless` secondary signal
- [x] Implement `probe-result.sh` — 5-trial automated; lenient last-line check; raw outputs preserved under raw-outputs/
- [x] Run both probes; document findings in `findings.md` (executed live during QA: leg-a Agent subagent + leg-b claude -p × 5 trials)
- [x] If leg (a) FAILS: document Phase 2 redesign options for parent (findings.md "Implications": orchestrator pre-collects AUQs before dispatch)
- [x] If leg (b) FAILS: document parser-leniency options (findings.md "Implications": strip `>` prefixes + code fences; use `grep RESULT: | tail -1` not strict `^RESULT: `)
- [x] (Follow-up; closed during S000027 implement) Updated F000014_DESIGN.md "Big decisions" with rows 2.1 + 2.2 (Phase 2 dispatch SUPERSEDED + RESULT-line parser leniency); S000027_SPEC.md Mental Model + Data Flow + Tradeoffs + Open Questions all aligned with spike findings

## Log

- 2026-05-09: Created. Spike to verify two unverified premises in F000014's /personal-pipeline design before orchestrator skill is built.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `tests/spike/subagent-capabilities/probe-auq.sh` (NEW)
- `tests/spike/subagent-capabilities/probe-result.sh` (NEW)
- `tests/spike/subagent-capabilities/findings.md` (NEW)

## Insights

- **`claude -p` is fundamentally non-interactive.** This shaped the probe design: leg (a) had to become operator-driven because there's no human in headless mode for AUQ to bubble to. Future spikes that depend on human-in-loop behavior should plan for an interactive operator step from day one, not assume `claude -p` covers everything.
- **The orchestrator's `RESULT:` parser is best designed as last-line lenient even before knowing leg (b)'s outcome.** The probe's hit-check itself uses last-line matching because isolating "just the subagent's final message" from `claude -p` output is brittle; the orchestrator will face the same constraint at runtime, so the parser shape is foreshadowed.
- **AskUserQuestion is not even REACHABLE inside Agent subagents in Claude Code 2.1.91.** Leg (a) found that ToolSearch `select:AskUserQuestion` returns "no matching deferred tools found" from inside a `subagent_type: general-purpose` context — the tool isn't in the subagent's deferred-tool list at all. This is stronger than "AUQ hangs" or "AUQ auto-cancels" — it's "AUQ doesn't exist." Any orchestrator design that assumes subagents can AUQ is broken by construction. Pre-collect AUQs at the orchestrator (parent session) layer; subagents run in `--auto`-equivalent mode with answers threaded into prompt tail.
- **Subagents reliably produce RESULT-line CONTENT, but inconsistently FORMAT it.** Leg (b) hit 2/5 strict, but the actual `RESULT: STATUS=ok` text was present in all 5 — sometimes wrapped in markdown blockquotes (`> RESULT: ...`), sometimes inside a closing code fence. The fix is parser leniency, not prompt-engineering the subagent into compliance. Strip `>` prefixes + ` ``` ` fences and use `grep 'RESULT: ' | tail -1` against the full output.

## Journal

- 2026-05-09 [decision] Two-leg spike (AUQ bubble + RESULT-line reliability) over a single combined probe — failure modes are different (AUQ may hang; RESULT-line may be flaky), so probing them independently isolates the diagnosis.
- 2026-05-09 [impl-decision] probe-auq.sh is operator-driven (prints prompt + rubric for paste into a fresh Claude Code session) rather than fully automated. Reason: `claude -p` headless mode has no interactive human to bubble AUQ to, so testing "does AUQ reach the operator" fundamentally requires a live interactive session. Secondary `--try-headless` flag gives optional signal on how AUQ-from-subagent degrades in -p mode.
- 2026-05-09 [impl-decision] probe-result.sh hit-check uses lenient last-non-blank-line match against the entire `claude -p` stdout (not just the subagent's final message). Reason: parent's final message often re-quotes the subagent's, and isolating just the subagent's last message from `claude -p` output is brittle. Last-line match is the orchestrator parser's likely fallback anyway, so the probe directly tests the parser-friendly path.
- 2026-05-09 [impl-decision] Default trial count = 5 (overridable via `--trials N`). 5 is a forcing function from F000014_DESIGN ("5+ trials" for statistical signal vs anecdote); raising it is operator-owned.
- 2026-05-09 [impl] Wrote 3 files: tests/spike/subagent-capabilities/{probe-auq.sh, probe-result.sh, findings.md}. Both .sh files made executable. raw-outputs/ subdir created on first probe-result run (gitignored implicitly via test-artifact convention).
- 2026-05-09 [impl-pass] S000026: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-05-09 [qa-e2e] E1 (AC-1, AC-4): ambiguous — probe-auq.sh stdout prints rubric covering all four verdict shapes (yes / no+hang / no+error / no+auto-cancel) but no actual operator-classified verdict. Spike is operator-driven (probe-auq.sh:36-77 instructs paste-into-fresh-session); per spike caveat in QA instructions, post-probe-run verdict is expected to be ambiguous until operator runs probe and updates findings.md.
- 2026-05-09 [qa-e2e] E2 (AC-2): ambiguous — probe-result.sh has not been executed (tests/spike/subagent-capabilities/raw-outputs/ does not exist); no N/5 tally available. Script requires `claude` CLI and ~15-min budget (probe-result.sh:41 timeout 180s × 5 trials); operator-driven per spike design.
- 2026-05-09 [qa-e2e] E3 (AC-3): ambiguous — findings.md is a stub with placeholders ({YYYY-MM-DD}, {N}/{TRIALS}, unchecked recommended-action checkboxes). See findings.md:8-12 (Context placeholders), :15 (leg-a verdict placeholder), :26 (leg-b verdict placeholder), :39-42 (no checkbox marked). Operator must run probes and fill stub before E3 can transition.
- 2026-05-09 [qa-test-spec-fix] During smoke, caught two TEST-SPEC bugs and fixed inline: (1) S2's command was `tests/spike/subagent-capabilities/probe-result.sh` (5 × claude-p × 180s = ~15min, too slow for smoke + requires claude CLI) → replaced with `bash -n tests/spike/subagent-capabilities/probe-result.sh` (syntax check only; full 5-trial run verified at E2E instead). (2) S3's grep string `"Recommended action:"` did not match findings.md's actual heading `"## Recommended downstream action"` → grep updated to match. Both are doc-only fixes (TEST-SPEC was sloppy at scaffold time); no implementation change required.
- 2026-05-09 [qa-smoke] S1 (AC-1): green — probe-auq.sh exits 0 (65 lines printed; rubric covers all four verdict shapes).
- 2026-05-09 [qa-smoke] S2 (AC-2): green — `bash -n probe-result.sh` exit 0 (syntax valid; full 5-trial run verified at E2E).
- 2026-05-09 [qa-smoke] S3 (AC-3): green — findings.md contains `VERDICT:` lines + `Recommended downstream action` heading.
- 2026-05-09 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending).
- 2026-05-09 [qa-followup] User chose to run probes live during QA (option 1 of E2E ambiguous AUQ). Both legs executed in-session; findings.md filled in with verdicts + recommended action.
- 2026-05-09 [qa-e2e] E1 (AC-1, AC-4): green (after live run) — leg (a) verdict captured: AUQ_BUBBLES=no SUBCLASS=error. Sub-classification present per rubric. Subagent's ToolSearch confirmed AskUserQuestion is not in the deferred-tools list of the Agent subagent context; tool unavailable, not hang/auto-cancel. See tests/spike/subagent-capabilities/findings.md:14-29.
- 2026-05-09 [qa-e2e] E2 (AC-2): green (after live run) — leg (b) verdict captured: RESULT_LINE_HITS=2/5. Raw outputs preserved in tests/spike/subagent-capabilities/raw-outputs/trial-{1..5}.txt. Failure modes inspected: trials 3-4 wrapped RESULT in markdown blockquote (`> RESULT: STATUS=ok`); trial 5 closed inside a code fence. See findings.md:32-44.
- 2026-05-09 [qa-e2e] E3 (AC-3): green (after live run) — findings.md no longer stub; Context filled (date 2026-05-09, Claude Code 2.1.91, opus overlay, operator chjiang); both VERDICT lines populated; Recommended downstream action checkbox marked: `[x] Both redesigns`; Implications section names two concrete pipeline.md adjustments for S000027 (Phase 2 pre-collect AUQs at orchestrator + RESULT-line parser leniency).
- 2026-05-09 [qa-e2e-summary] green (≈90s subagent + ~3min claude -p × 5 trials): all 3 E2E criteria green after live probe execution.
- 2026-05-09 [qa-finding] **Spike outcome implies F000014_DESIGN updates required.** Both probes failed → F000014's "Big decisions" #2 (Phase 2 dispatch via subagent AUQ_NEEDED return contract) is supplanted by "orchestrator pre-collects AUQs before dispatch" — the subagent has no AskUserQuestion tool to call. RESULT-line parser must be lenient (strip `>` prefixes + code fences). S000027's pipeline.md MUST be authored with these two adjustments (documented in findings.md "Implications" section). Updating F000014_DESIGN big-decisions table is a follow-up TODO (not blocking S000026 ship).
- 2026-05-09 [qa-pass] S000026 (user-story): green smoke + green E2E. Phase 2 gates transitioned. Spike findings.md committed at tests/spike/subagent-capabilities/findings.md; ready to unblock S000027 (with the design adjustments from findings.md).
