# /qa-work-item — QA Orchestration

QA a personal-workflow work-item per its type-appropriate test rows. For
user-stories: smoke first, then E2E via a QA engineer subagent; transitions
qa-owned Phase 2 gates on green. For defects/tasks: runs test-plan rows as
smoke-equivalent; records `[qa-pass]` journal entry on green (no qa-owned
Phase 2 gates per template; verification lands at Phase 3 `Test-plan verified`).

This file is the step-by-step logic invoked from [SKILL.md](SKILL.md). Read
SKILL.md first for path resolution, error handling, and usage; then follow
the steps below.

---

## Step 1: Validate Input + Type Dispatch

Parse the user's argument:

- The first positional argument is `<work-item-dir>` (any type accepted; type-dispatch resolves test-row source).

Verify the directory exists and is a work-item directory:

```bash
[ -d "$WORK_ITEM_DIR" ] || { echo "Error: work-item dir not found at $WORK_ITEM_DIR"; exit 1; }
TRACKER=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "*_TRACKER.md" -o -name "TRACKER.md" 2>/dev/null | head -1)
[ -z "$TRACKER" ] && { echo "Error: $WORK_ITEM_DIR is not a work-item directory (no TRACKER.md)"; exit 1; }
```

Read the tracker's frontmatter `type` field. Apply Type Spelling normalization
(per `personal-workflow/check.md` Normalization Rules: hyphens removed for
comparison; "user-story" and "userstory" both normalize to "userstory").
Display the hyphenated form ("user-story") in messages.

If `type:` is missing or empty: print
`Error: TRACKER.md frontmatter missing or malformed `type:` field; cannot dispatch.` and stop.

**Type dispatch table** — per-type test-row source:

| Type | Test rows source | E2E subagent (v1) |
|---|---|---|
| `user-story` | `*_TEST-SPEC.md` (`## Smoke Tests` + `## E2E Tests`) | YES |
| `defect` | `*_test-plan.md` (`## Regression Test Cases` table — all rows treated as smoke-equivalent) | NO |
| `task` | `*_test-plan.md` (`## Regression Test Cases` table — all rows treated as smoke-equivalent) | NO |
| `feature` | (delegates to a child work-item via AUQ) | (per chosen child's type) |

**Feature dispatch:** if type is `feature`, list child user-story / defect / task
directories (subdirectories containing `*_TRACKER.md`), then AskUserQuestion:

> {feature_id} is a feature. Which child work-item should I QA?
>
> Options:
> - {child_id_1}_{slug_1} ({child_type_1})
> - {child_id_2}_{slug_2} ({child_type_2})
> - ...
> - Cancel

If the user picks a child, set `WORK_ITEM_DIR` to that child path, re-resolve
`TRACKER`, re-read the tracker's `type:` field, and continue with the chosen
child's type. If cancel: print "Aborted." and stop.

If type is none of `user-story` / `defect` / `task` / `feature` (after normalization):
`Error: TRACKER.md \`type: {value}\` is not recognized; expected feature/user-story/task/defect.` and stop.

Locate the per-type test-row source:

```bash
case "$TYPE" in
  user-story|userstory)
    TEST_SPEC=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "*_TEST-SPEC.md" -o -name "TEST-SPEC.md" 2>/dev/null | head -1)
    [ -z "$TEST_SPEC" ] && { echo "Error: TEST-SPEC.md not found in $WORK_ITEM_DIR (required for type user-story QA)"; exit 1; }
    ;;
  defect|task)
    TEST_PLAN=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "*_test-plan.md" -o -name "test-plan.md" 2>/dev/null | head -1)
    [ -z "$TEST_PLAN" ] && { echo "Error: test-plan.md not found in $WORK_ITEM_DIR (required for type $TYPE QA)"; exit 1; }
    ;;
esac
```

For backwards compatibility with the v1.10.0 user-story-only path, this skill
historically used the variable name `USER_STORY_DIR`. Treat it as an alias for
`WORK_ITEM_DIR` in any code path that still references it.

Capture the work-item ID from the tracker filename (e.g., `S000019` from
`S000019_TRACKER.md`) → `WORK_ITEM_ID`.

## Step 2: Boundary Check at Start (Premise 1.3)

Run `/personal-workflow check` on the work-item directory. The skill's job
is to QA completed implementation work; running on a half-implemented
work-item is a category error.

**Phase 2 implementer-owned gates are per-type** (must be CHECKED at start):

### user-story (`tracker-user-story.md`)
- `Todos section reflects remaining work (no stale items)` — implementer-owned
- `Files section updated with changed files` — implementer-owned
- `Acceptance criteria verified met` — qa-owned (must be UNCHECKED at start)
- `Smoke tests pass` — qa-owned (must be UNCHECKED at start)

### defect (`tracker-defect.md`)
- `Fix committed` — user/`/ship`-owned commit gate (must be CHECKED at start; if not, the fix isn't committed yet)
- `RCA doc updated` — implementer-owned (must be CHECKED at start)
- `Todos section reflects remaining work` — implementer-owned (must be CHECKED at start)
- (no qa-owned Phase 2 gates per template)

### task (`tracker-task.md`)
- `Core changes committed (>=1 commit SHA in Log)` — user/`/ship`-owned commit gate (must be CHECKED at start)
- `Todos section reflects remaining work` — implementer-owned (must be CHECKED at start)
- `Files section updated with changed files` — implementer-owned (must be CHECKED at start)
- (no qa-owned Phase 2 gates per template)

Read the TRACKER's `## Lifecycle` → `### Phase 2: Implement` → `**Gates:**`
block. Match each `- [x]` / `- [ ]` line by gate label substring. If any
**implementer-owned** gate for this type is unchecked:

```
Error: Phase 2 incomplete; run /implement-from-spec first (or commit + update tracker manually for commit gates).
Unchecked implementer gates:
  - {gate_label_1}
  - {gate_label_2}
```

Stop. Do not proceed to smoke.

Note: for defect/task, the commit gates (`Fix committed`, `Core changes committed`)
are user-owned and may be unchecked even after `/implement-from-spec` runs (since
this skill writes files but doesn't commit). If the commit gate is unchecked,
QA refuses — the user must commit (or wait for `/ship`'s commit step) before
running QA.

Also run `/personal-workflow check "$WORK_ITEM_DIR"` (Tier 1 Directory Mode)
and capture the result. If the output contains `[MISSING]` or `[DRIFT]`
findings:

```
Error: work-item dir has structural issues; refusing to QA.
{summary of violations}
```

Stop. The user must resolve drift before QA can proceed.

## Step 3: Idempotency Check (Premise 1.1)

If both QA-owned gates (`Acceptance criteria verified met` AND
`Smoke tests pass`) are already CHECKED, AND the most recent journal entry
matching `[qa-pass]` is dated today (or matches the current `git rev-parse HEAD`):

```
INFO: {WORK_ITEM_ID} already QA'd green; nothing to do.
```

Exit 0 (NO-OP).

If the gates are checked but no `[qa-pass]` journal entry exists, treat as
**stale state** — the gates may have been hand-checked. Re-run QA. (Cheaper
to re-verify than to assume the user knows what they're doing if the audit
trail is missing.)

If only one of the two gates is checked: treat as **partial state from a
prior interrupted run** — re-run QA. The smoke or subagent output will
re-establish ground truth.

## Step 4: Read Test Rows (per type)

### Step 4.user-story (existing path)

Read `$TEST_SPEC`. Parse the two relevant sections:

- `## Smoke Tests` table — extract rows. Columns: `#`, `Tag`, `AC`, `Check`,
  `What It Validates`, `Script/Command`. Store as `SMOKE_ROWS`.
- `## E2E Tests` table — extract rows. Columns: `#`, `Tag`, `AC`, `Scenario`,
  `Steps (as a real user would)`, `Expected Outcome`, `Rubric`. Store as
  `E2E_ROWS`.

Filter out template-placeholder rows. A row is a placeholder if its `#`
column is literally `S{n}` or `E{n}` (curly-brace style), or if the
`Script/Command` column matches the regex `^(TBD|—|N/A)$`.

### Step 4.defect / Step 4.task

Read `$TEST_PLAN`. Parse the relevant section:

- `## Regression Test Cases` table — extract rows. Columns: `#`, `Test Case`,
  `Steps`, `Expected Result`, `Status`. Store as `SMOKE_ROWS` (treated as
  smoke-equivalent in v1; no separate E2E).

Set `E2E_ROWS = []` (empty) — defects and tasks do not dispatch the E2E
subagent in v1.

Filter out template-placeholder rows. A row is a placeholder if its `#`
column is literally `1` AND its `Steps` column is `{steps}` (template
placeholder).

For test-plan rows, the `Steps` column may be free-form prose rather than a
runnable command. Two sub-cases:
- **Steps starts with `manual:`** (or `Manual:` etc.) — record as
  `manual_pending` (same shape as user-story `manual:` rows).
- **Steps is free-form prose** without a runnable command — record as
  `manual_pending`. Test-plan rows describing user actions belong in manual
  verification; the QA skill cannot execute prose.
- **Steps is a single shell command** (or chained with `&&` / `||`) — execute
  as a runnable; record as automated.

Default to `manual_pending` if uncertain — manual verification is safer than
attempting to execute ambiguous prose.

### Edge cases (all types)

- **Test rows empty (only placeholder rows):** log `INFO: {test_rows_source} has no
  populated test rows; treating as vacuous PASS.` Skip to Step 9 (gate
  transition / [qa-pass]).
- **Smoke empty, E2E populated** (user-story only): log `INFO: no smoke rows; proceeding to
  E2E directly.` Skip to Step 7.
- **Smoke populated, E2E empty:** run smoke (Steps 5-6); skip Step 7;
  proceed to gate transition only if smoke green.
- **For defect/task: E2E always empty** (skipped per type dispatch); proceed
  to gate transition / [qa-pass] after Step 6 if smoke green.

## Step 5: Run Smoke

For each row in `SMOKE_ROWS`:

1. Read the row's `Script/Command` cell. If the cell starts with the literal
   string `manual:`, mark the row as `manual_pending` — these require human
   execution and are recorded as `[qa-smoke-manual]` (see below) without
   running anything.
2. For non-manual rows: execute the command via the Bash tool, capturing
   exit code, stdout (head 20 lines), stderr (head 20 lines).
3. Determine pass/fail by exit code: `0` = green, non-zero = red.
4. Append a journal entry to the TRACKER's `## Journal` section in this
   format:

   ```
   - {YYYY-MM-DD} [qa-smoke] {S#} ({AC}): {green|red} — {one-line summary}
   ```

   On red, also include the first failing line of stderr (or "exit code N
   with no stderr" if empty).

For manual rows, the journal entry uses `[qa-smoke-manual]` and the summary
documents what the user must do, e.g.:

```
- {YYYY-MM-DD} [qa-smoke-manual] {S#} ({AC}): pending human verification — {Check column verbatim}
```

After all rows are recorded, compute aggregate `SMOKE_VERDICT`:

- `green` — all non-manual rows green; manual rows are not failures
- `red` — at least one non-manual row red

Append a single summary journal entry:

```
- {YYYY-MM-DD} [qa-smoke-summary] {SMOKE_VERDICT}: {N_green}/{N_total_non_manual} non-manual rows green ({N_manual} manual rows pending)
```

## Step 6: Smoke Red Short-Circuit

If `SMOKE_VERDICT` is `red`:

Do NOT spawn the QA subagent. Smoke red means the implementation is broken
at a layer the cheap script catches — burning subagent tokens on top would
waste cycles.

AskUserQuestion:

> Smoke red: {N_failed} failure(s) in {WORK_ITEM_ID}. Fix smoke before E2E.
>
> Options:
> - Re-run after fix (recommended)
> - Skip smoke and run E2E anyway (NOT RECOMMENDED — E2E will likely also fail)
> - Abort

Default: re-run after fix. On `Re-run`: stop and let the user fix the
implementation, then re-invoke `/qa-work-item`. On `Skip smoke`: continue
to Step 7 with `SMOKE_VERDICT = red` recorded in the tracker; the parent
skill caller bears responsibility. On `Abort`: print "Aborted." and exit.

## Step 7: Spawn QA Engineer Subagent (E2E — user-story only)

For type = defect or type = task: skip to Step 9 (the type dispatch in Step 4
already set `E2E_ROWS = []`; this guard re-confirms for clarity).

If `E2E_ROWS` is empty: skip to Step 9.

Otherwise, dispatch the QA engineer subagent via the Agent tool. The prompt
is structured **stable preamble first, variable parts last** for prompt-cache
friendliness (Premise: cache amortizes the stable preamble across runs).

**Stable preamble** (identical every run; cacheable):

```
You are a QA engineer. Your job is to verify each E2E acceptance criterion in
the TEST-SPEC.md you are given.

For each row in the ## E2E Tests table:
1. Read the Scenario, Steps, Expected Outcome, Rubric columns.
2. Use Read, Bash, Grep, and Glob tools to verify the Expected Outcome.
3. Categorize the result:
   - green: criterion verified to pass
   - red: criterion verified to fail
   - ambiguous: cannot determine pass/fail with available tools
4. Append a journal entry to TRACKER.md (path provided below) for each row,
   in this format:
   - {YYYY-MM-DD} [qa-e2e] {E#} ({AC}): {green|red|ambiguous} — {1-line summary}
   On red or ambiguous, include a file path and line range that supports
   the verdict (e.g., "see scripts/test.sh:42").

CONSTRAINTS:
- Do NOT spawn subagents (no Agent tool calls). You are the leaf node.
- Do NOT modify source files. The only file you write to is the TRACKER.md
  provided below (Edit/Write to append journal entries).
- Do NOT exceed 5 minutes of wall-clock work. If you can't verify a row
  efficiently, mark it ambiguous and move on.
- Stay within the work-item directory tree for verification. You may Read
  files outside it for context, but do not modify any.

RETURN VALUE:
End your turn with a single 1-2 sentence summary of the overall E2E result,
plus a file pointer to the tracker. Examples:
- "All 5 E2E criteria green. Tracker journal updated at <path>."
- "1 red finding (E2): expected exit code 0, got 1. See <path> journal."
- "2 ambiguous (E3, E5): need user judgment on rubric. See <path>."

Do NOT return a verbose findings dump in your response. Detailed findings
go to the tracker; the response is for the parent skill's summary.
```

**Variable parts** (per-invocation; not cached):

```
Work-item directory: {USER_STORY_DIR}
TEST-SPEC path: {TEST_SPEC}
TRACKER path: {TRACKER}
WORK_ITEM_ID: {WORK_ITEM_ID}
SMOKE_VERDICT (already run): {SMOKE_VERDICT}

Now run the E2E verification per the stable preamble above.
```

Invoke the Agent tool with this prompt and a 5-minute timeout
(`timeout: 300000`). Use `subagent_type: "general-purpose"` (the QA work
needs full filesystem read + bash; no specialized agent type matches).

Capture the subagent's response into `SUBAGENT_SUMMARY`. Capture the wall-
clock duration into `SUBAGENT_DURATION_S`.

**On timeout:**

Append a journal entry:
```
- {YYYY-MM-DD} [qa-e2e-timeout] subagent exceeded 5-min cap; partial findings (if any) recorded above
```

AskUserQuestion:

> Subagent timed out after 5 minutes for {WORK_ITEM_ID}.
>
> Options:
> - Re-run E2E (recommended if the timeout was transient)
> - Skip E2E and proceed with smoke-only verdict (Phase 2 gates remain unchecked)
> - Abort

Default: re-run. On Re-run: re-invoke Step 7 once (no auto-retry beyond
this; if it times out again, re-prompt). On Skip: proceed to Step 9 with
`E2E_VERDICT = unknown`; gates will not transition. On Abort: stop.

## Step 8: Process Subagent Result

Parse `SUBAGENT_SUMMARY` for verdict signals:

- `all green` / `N green` (no mention of red or ambiguous) → `E2E_VERDICT = green`
- `red` / `failed` mentioned → `E2E_VERDICT = red`
- `ambiguous` / `need user` / `unable to determine` → `E2E_VERDICT = ambiguous`

Append a summary journal entry:

```
- {YYYY-MM-DD} [qa-e2e-summary] {E2E_VERDICT} ({SUBAGENT_DURATION_S}s): {SUBAGENT_SUMMARY verbatim}
```

**On `E2E_VERDICT = green`:** silent path. Continue to Step 9. NO
AskUserQuestion (Premise: AUQ only on red/ambiguous, autoplan-style).

**On `E2E_VERDICT = red`:**

AskUserQuestion:

> QA found red findings in {WORK_ITEM_ID}: {SUBAGENT_SUMMARY one-line}
>
> Options:
> - Review tracker findings and fix (recommended)
> - Mark as known issue and proceed (gates will NOT transition)
> - Abort

Default: review and fix. On Review: print the tracker journal's recent
`[qa-e2e]` entries and stop (let the user fix). On Mark known: write a
`[qa-known-issue]` entry to the journal and stop without transitioning
gates. On Abort: stop.

**On `E2E_VERDICT = ambiguous`:**

AskUserQuestion:

> QA returned ambiguous verdict for {WORK_ITEM_ID}: {SUBAGENT_SUMMARY one-line}
>
> Options:
> - Treat as green (proceed to Phase 2 gate transition)
> - Treat as red (record as red, do not transition)
> - Re-run E2E (subagent gets a fresh attempt)
> - Abort

No default — the user must adjudicate. Process the choice accordingly.

## Step 9: Transition Phase 2 Gates / Record [qa-pass] (per type, if green)

Only if `SMOKE_VERDICT = green` AND `E2E_VERDICT = green` (or `E2E_ROWS`
empty AND smoke green):

### Step 9.user-story

Edit the TRACKER's `## Lifecycle` → `### Phase 2: Implement` → `**Gates:**`
block. Find the lines:

```
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
```

Change `[ ]` to `[x]` on those two specific gates. Do NOT touch the other
two gates (`Todos section reflects remaining work`,
`Files section updated with changed files`) — those are owned by
`/implement-from-spec` and were already green per Step 2's boundary check.

### Step 9.defect / Step 9.task

Defect and task templates have no qa-owned Phase 2 gates. Do NOT modify
the Phase 2 Gates block.

The Phase 3 `Test-plan verified` gate (defect) / `Test-plan verified (all
scenarios passing)` gate (task) is the verification-state recipient, but
this skill does not transition Phase 3 gates in v1 — those are marked at
`/ship` time or by `/personal-workflow check --update`'s post-merge
inference. The `[qa-pass]` journal entry below provides the audit trail
that links the green-QA event to the eventual Phase 3 transition.

### Append journal entry (all types)

Append a journal entry. The entry text records the test-row source and the
type-dispatch path:

For user-story:
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (user-story): green smoke + green E2E. Phase 2 gates transitioned.
```

If E2E was empty (vacuous green path):
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (user-story): green smoke + no E2E rows. Phase 2 gates transitioned.
```

If smoke was empty (E2E only, green):
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (user-story): no smoke rows + green E2E. Phase 2 gates transitioned.
```

If both empty (vacuous PASS from Step 4):
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (user-story): vacuous PASS (no smoke or E2E rows in TEST-SPEC). Phase 2 gates transitioned.
```

For defect:
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (defect): green smoke from test-plan rows ({N} rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
```

For task:
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (task): green smoke from test-plan rows ({N} rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
```

## Step 10: Boundary Check at End (Premise 1.3)

Run `/personal-workflow check "$WORK_ITEM_DIR"` (Tier 1 Directory Mode).

**If the result contains no `[MISSING]` or `[DRIFT]` findings:** continue to
Step 11.

**If the result contains violations** (the QA writes broke compliance):

AskUserQuestion:

> /personal-workflow check failed after QA writes:
>   {summary of violations}
>
> Options:
> - Surface and exit (recommended — manual repair is safer)
> - Show full check output and continue (the violations may be advisory)
> - Abort

Default: surface and exit. The user inspects what the skill broke and fixes
manually.

`[EXTRA]` advisory flags (e.g., "unexpected section") do not count as
violations for the boundary check — only `MISSING` and `DRIFT`.

## Step 11: Print Summary and Exit

Print a tight summary in the chat:

```
QA COMPLETE: {WORK_ITEM_ID}

Smoke:    {SMOKE_VERDICT} ({N_green}/{N_total_non_manual}, {N_manual} manual)
E2E:      {E2E_VERDICT} ({SUBAGENT_DURATION_S}s)
Phase 2:  {gates transitioned | unchanged}

Tracker:  {TRACKER}
Next:
  /personal-workflow check {WORK_ITEM_DIR}    # verify
  /ship                                        # if all Phase 2 green (user-story) or commit gate satisfied (defect/task)
```

Last line in the chat is the tracker path, formatted for copy-paste.

---

## Error Handling

See [SKILL.md](SKILL.md)'s Error Handling table. All errors are
non-recoverable (skill exits cleanly); the user re-runs after fixing the
underlying issue.

## Idempotency Contract (Premise 1.1)

This skill is idempotent. Three behaviors:

1. **Already QA'd green** (Step 3): both QA-owned gates checked AND a
   `[qa-pass]` journal entry exists today/at-current-commit. NO-OP, exit
   clean.
2. **Stale gate state** (Step 3): gates checked but no `[qa-pass]` audit
   trail. Re-run smoke + E2E to re-establish ground truth.
3. **Partial-run recovery** (Step 3): one gate checked, other unchecked.
   Re-run from Step 4; gate transitions in Step 9 will reset to consistent
   state.

No automatic rollback on smoke or E2E failure. Tracker journal records what
was tried and the verdict; gates stay in their pre-run state if QA didn't
complete green.

## Boundary Validation Contract (Premise 1.3)

`/personal-workflow check` runs at:

- **Step 2 (start):** on `WORK_ITEM_DIR` — gates input drift, refuses on
  Phase 2 implementer-gate gaps or structural drift.
- **Step 10 (end):** on `WORK_ITEM_DIR` after writes — catches
  self-inflicted compliance breaks.

Both invocations use Tier 1 Directory Mode. The boundary check uses
`MISSING` and `DRIFT` for blocking violations; `EXTRA` and `INFO` are
advisory and do not block.

## Subagent Contract

The QA engineer subagent (Step 7) runs in a fresh Agent tool context. It
must:

- Stay read-only on source files; only TRACKER.md is mutable
- Not spawn its own subagents (anti-recursion)
- Return a 1-2 sentence summary, not a verbose findings dump
- Write detailed per-row findings to the tracker journal as `[qa-e2e]` entries

The subagent's filesystem boundary is documented but not enforced —
verification relies on the prompt instruction. If the subagent violates
the contract (e.g., modifies source files), the user notices via git diff
on the next commit.

## Spec Deviations

The S000019 SPEC mentions a separate `## QA Run` section consolidating
findings (AC-13, observability). This v1 implementation uses
`## Journal` entries with `[qa-smoke]`, `[qa-e2e]`, `[qa-pass]`, and
sibling prefixes instead. Rationale: a separate section would generate
`[EXTRA]` advisory flags from `/personal-workflow check` Step 16 every
QA'd work item; the journal-with-prefix approach satisfies the
underlying motivation (grep-friendly output: `grep '\[qa-' TRACKER.md`)
without polluting the section structure. If grep-friendliness proves
insufficient in practice, a future iteration can lift QA findings into a
dedicated section by extending the `tracker-user-story.md` template.
