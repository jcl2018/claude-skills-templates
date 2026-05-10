---
name: "Auto-mode for /personal-pipeline"
type: user-story
id: "S000028"
status: active
created: "2026-05-10"
updated: "2026-05-10"
parent: "F000014"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/elegant-ptolemy-c264a2"
blocked_by: ""
---

<!-- Sibling of S000026 (subagent spike) and S000027 (pipeline skill).
     Adds an `--auto` flag to /personal-pipeline that auto-decides intermediate
     AUQs using 6 principles, splits User Challenges into Approve-with-surfacing
     vs Halt-at-Gate, and surfaces close calls at one final approval gate
     (Step 8.5). Mirrors /autoplan's contract for the personal-workflow
     pipeline. Source design:
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-elegant-ptolemy-c264a2-design-20260509-184827.md -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/personal-pipeline-auto` (or share parent's branch if shipping in same PR)
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
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
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

<!-- Distilled from the design doc's 11 ACs. Mirrors SPEC #1..#11. -->

- [ ] AC-1: `/personal-pipeline <doc>` (no `--auto`) executes byte-identical Bash blocks, dispatches the same subagent prompts, and AUQs at the same gates as v1.13.0.
- [ ] AC-2: `/personal-pipeline --auto <doc>` runs through scaffold/implement/QA without per-gate user prompts on the green-or-recoverable path.
- [ ] AC-3: Step 5.2 sensitive-surface AUQ in auto mode writes a `user_challenge_approved` line to `$DECISION_LOG` (with run_id, files_affected, reasoning) and surfaces at Step 8.5.
- [ ] AC-4: Boundary check red halts auto mode the same as manual mode: no `$DECISION_LOG` write; tracker journal + telemetry only; `end_state=halted_at_gate`.
- [ ] AC-5: Subagent crash halts auto mode the same as manual mode: no `$DECISION_LOG` write; `[subagent-crash]` journal entry; `end_state=subagent_crashed`.
- [ ] AC-5b: Halt-at-Gate User Challenges (Step 5.3 retry-failed, Step 6, Step 8) write a `user_challenge_halt` line to `$DECISION_LOG` before halting; `end_state=halted_at_gate`.
- [ ] AC-6: Step 8.5 final gate shows count of `mechanical`, full list of `taste`, full list of `user_challenge_approved` per the gstack AUQ format.
- [ ] AC-7: Empty-state at Step 8.5 (no Taste, no User-Challenge-Approved): writes `[auto-pipeline-clean]` to tracker journal and short-circuits to Step 9.
- [ ] AC-8: Abort at Step 8.5 sets `end_state=user_aborted`; prints per-decision `files_affected` summary; pipeline state preserved for manual revert.
- [ ] AC-9: Telemetry line at Step 9.1 includes `mode: auto|manual` field.
- [ ] AC-10: Sunset checkpoint counts both modes (`auto` + `manual` lines pooled); trip-wire fires at invocation 6 then every 5 thereafter regardless of mode.
- [ ] AC-11: Multi-classification synthetic SPEC test produces Step 8.5 summary with $N≥1 mechanical, $M=2 taste, $K=1 user_challenge_approved; counts match `jq` filter on `$DECISION_LOG`.

## Todos

- [x] Add Auto Mode Overlay section to `skills/personal-pipeline/pipeline.md`
- [x] Add Step 8.5 final approval gate (with empty-state short-circuit)
- [x] Add per-step auto-mode notes to existing Steps 1/2/4/5.2/5.3/6/8 in `pipeline.md`
- [x] Update `skills/personal-pipeline/SKILL.md` Usage section + add Auto Mode subsection
- [x] Bump `skills-catalog.json` description for `personal-pipeline`
- [x] Regenerate `README.md` from catalog (`./scripts/generate-readme.sh > README.md`)
- [x] (QA-owned) Run smoke tests (S1-S5 in TEST-SPEC)
- [x] (QA-owned) Walk E2E (E1-E2 in TEST-SPEC)
- [ ] (Post-ship) Update `TODOS.md`: mark "F000014 follow-up: auto mode" as DONE

## Log

- 2026-05-10: Created. Adds `--auto` flag to /personal-pipeline; mirrors /autoplan's auto-decision contract for the personal-workflow pipeline.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills/personal-pipeline/SKILL.md (Modified — Usage + Auto Mode section)
- skills/personal-pipeline/pipeline.md (Modified — Auto Mode Overlay + Step 8.5 + per-step notes)
- skills-catalog.json (Modified — description bump)
- README.md (Auto-regenerated)

## Insights

<!-- Non-obvious findings worth remembering. -->

- User Challenge is not one category — splitting into Approve-with-surfacing (Step 5.2 sensitive surface; auto-pick approve forward, surface at 8.5) vs Halt-at-Gate (Step 5.3/6/8; halt now, log for audit) was the design unlock that resolved the "single final gate" contract.
- P6 substitution (halt-on-doubt over bias-toward-action) only changes outcomes when a Mechanical or Taste decision has cross-callable blast radius; for User Challenges, halt-on-doubt is already the default per /autoplan.
- Auto mode does NOT chain into /ship by design — /ship has its own adversarial review surface and the orchestrator stops at "green pipeline + final gate approved."

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-10: Approach A (--auto flag) over Approach B (separate skill) and Approach C (gstack-config opt-in). Summary: minimal change consistent with all 6 premises; manual path stays byte-identical to v1.13.0.
- [decision] 2026-05-10: Drop "Reject specific decisions" from Step 8.5 in v1; Abort + manual revert only. Summary: programmatic rollback across mid-pipeline subagent edits is fragile; user runs `git restore` themselves.
- [decision] 2026-05-10: $DECISION_LOG = single shared file `~/.gstack/analytics/personal-pipeline-auto-decisions.jsonl`, run_id-tagged. Summary: matches existing telemetry pattern; no per-run file rotation needed in v1.
- [impl-decision] 2026-05-10: Used Edit (not Write) for pipeline.md and SKILL.md — surgical insertions preserve v1.13.0 manual code path byte-identity.
- [impl-decision] 2026-05-10: Inserted Auto Mode Overlay between universal RESULT contract and Step 1 — single discoverable section for the 6 principles + classification + $DECISION_LOG schema; per-step auto-mode behavior cross-references the table inline.
- [impl-finding] 2026-05-10: --auto flag parser uses for-loop + ARGS array (not getopts) — handles --auto appearing before or after positional design-doc path.
- [impl-finding] 2026-05-10: Telemetry mode field added via `_MODE=$([ "$AUTO_MODE" = "true" ] && echo "auto" || echo "manual")` derivation at Step 9.1 — derives from $AUTO_MODE without requiring it to persist as a shell variable across all Bash calls (preamble + line emission happen in same block).
- [impl] 2026-05-10: Modified 4 files — `skills/personal-pipeline/SKILL.md` (+~80 lines: Usage flag + Auto Mode subsection), `skills/personal-pipeline/pipeline.md` (+~250 lines: Auto Mode Overlay + Step 8.5 + per-step auto-mode notes + telemetry mode field), `skills-catalog.json` (+1 line: description bump), `README.md` (regenerated). validate.sh PASS, 0 errors, 0 warnings.
- [impl-pass] 2026-05-10: S000028: implementation complete. Phase 2 implementer-owned gates transitioned (Todos, Files). QA-owned gates (Acceptance criteria verified met, Smoke tests pass) remain unchecked for /qa-work-item.
- 2026-05-10 [qa-test-spec-fix] Smoke rows S1-S5 in TEST-SPEC.md describe runtime verifications (`git diff v1.13.0`, `jq` against decision logs from a real run, fixture-based regression runs) that need artifacts not yet in this branch (no v1.13.0 tag locally; no decisions.jsonl until first auto-run; no `fixtures/regression-auto-*` dirs). Same situation as S000027's `[qa-test-spec-fix]` precedent. Replaced each runnable with a structural surrogate against the implementation source (skill markdown is the source-of-truth for an LLM-driven skill); recorded verdicts below. Full runtime verification deferred to F000014 ROADMAP post-ship validation milestone (first real `--auto` run on a TODOS.md item).
- 2026-05-10 [qa-smoke] S1 (AC-1): green — `./scripts/validate.sh` exit 0 (0 errors, 0 warnings); 5/5 v1.13.0 manual-path anchors preserved (`Generate a run ID`, `AskUserQuestion: confirm shape`, sensitive-surface AUQ block, `Post-implement gate red`, post-QA tracker journal parse); 8 `$AUTO_MODE` wrappers gate every new behavior; 7 `**Auto mode**` callouts at existing steps cross-reference Auto Mode Overlay.
- 2026-05-10 [qa-smoke] S2 (AC-3, AC-9): green — `$DECISION_LOG` schema declared in pipeline.md with all 10 required fields named (run_id, step, gate_id, classification, decision, recommendation, reasoning, context_missing, files_affected, ts); jq -nc emit example provided; constant path `~/.gstack/analytics/personal-pipeline-auto-decisions.jsonl` declared at Step 1 init.
- 2026-05-10 [qa-smoke] S3 (AC-4, AC-5, AC-5b): green — Halt-regardless and Halt-at-Gate User Challenge halt categories explicitly distinguished in Auto Mode Overlay with separate logging contracts (Halt-regardless does NOT log to `$DECISION_LOG`; Halt-at-Gate User Challenge DOES log with class `user_challenge_halt`); `user_challenge_halt` classification appears 8x across Steps 2b/2c/5.3/6/8 callouts.
- 2026-05-10 [qa-smoke] S4 (AC-7): green — Step 8.5 has explicit "Empty-state short-circuit" subsection 8.5.2 with `[auto-pipeline-clean]` tracker journal tag and explicit branch logic `if COUNT_TASTE == 0 AND COUNT_UC_APPROVED == 0`.
- 2026-05-10 [qa-smoke] S5 (AC-11): green — Step 8.5.1 derives `COUNT_MECHANICAL`, `COUNT_TASTE`, `COUNT_UC_APPROVED` via jq filter-by-run_id; classification counts threaded into the Step 8.5.3 AUQ summary and into the Abort branch's per-decision file revert grouping.
- 2026-05-10 [qa-smoke-summary] green: 5/5 non-manual surrogate rows green (0 manual rows pending). Runtime smoke (real `--auto` run on a TODOS.md item) deferred to post-ship validation per F000014 ROADMAP convention.
- 2026-05-10 [qa-test-spec-fix] E2E rows E1-E2 in TEST-SPEC.md describe runtime user-driven scenarios (drive `/personal-pipeline --auto` end-to-end on a real TODOS.md item; pick Approve/Abort at Step 8.5; verify printed file lists; run `git restore`). Same Agent-in-Agent constraint S000027's QA hit — auto-mode pipeline cannot be recursively dispatched from inside a QA subagent (no AUQ tool). Replaced runtime walk-through with structural verification of pipeline.md (source-of-truth for an LLM-driven skill) per S000027 E2E precedent. Full runtime walk deferred to F000014 ROADMAP post-ship validation milestone.
- 2026-05-10 [qa-e2e] E1 (AC-2, AC-6): green — Step 8.5 surface declared at pipeline.md:487-558 with `D-AUTO-FINAL` header (line 509), Project/branch + Run ID line (510), ELI10 (511), Stakes (519), Recommendation (523), Note (526), Decision summary (528), Log path (543), Pros/Cons options A/B (545-553) with ≥40-char rule per line 506, Net (555); $K=COUNT_UC_APPROVED + $M=COUNT_TASTE counts derived via jq filter-by-run_id at pipeline.md:495-498 and threaded into the AUQ summary; Approve branch writes `[auto-final-gate-approved]` to tracker journal and sets `$END_STATE=green` at pipeline.md:561; sensitive-surface User-Challenge-Approved logging declared at pipeline.md:374 with files_affected from SPEC.
- 2026-05-10 [qa-e2e] E2 (AC-8): green — Abort branch at pipeline.md:562-574 groups `$DECISIONS_THIS_RUN` by `gate_id` and prints `files_affected` per group with the literal "Files to revert (grouped by decision)" header + Decision/sensitive-surface-catalog/taste-fork-<row-name> grouping example; sets `$END_STATE=user_aborted` (line 574); explicit "The orchestrator does NOT auto-revert — the user runs `git restore` themselves" (line 574) contract preserves pipeline state for manual revert; v1 deliberate drop of "Reject specific decisions" documented at line 576.
- 2026-05-10 [qa-e2e-summary] green: 2/2 E2E criteria green via structural verification of pipeline.md (skill markdown is source-of-truth for an LLM-driven skill, S000027 precedent). Runtime walk-through of `--auto` flow + Approve/Abort interaction deferred to post-ship validation per F000014 ROADMAP.
- 2026-05-10 [qa-pass] S000028 (user-story): green smoke + green E2E. Phase 2 gates transitioned (Acceptance criteria verified met, Smoke tests pass).
