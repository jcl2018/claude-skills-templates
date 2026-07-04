# /CJ_qa-work-item — QA Orchestration

QA a CJ_personal-workflow work-item per its type-appropriate test rows. For
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
(per `CJ_personal-workflow/check.md` Normalization Rules: hyphens removed for
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

Run `/CJ_personal-workflow check` on the work-item directory. The skill's job
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
Error: Phase 2 incomplete; run /CJ_implement-from-spec first (or commit + update tracker manually for commit gates).
Unchecked implementer gates:
  - {gate_label_1}
  - {gate_label_2}
```

Stop. Do not proceed to smoke.

Note: for defect/task, the commit gates (`Fix committed`, `Core changes committed`)
are user-owned and may be unchecked even after `/CJ_implement-from-spec` runs (since
this skill writes files but doesn't commit). If the commit gate is unchecked,
QA refuses — the user must commit (or wait for `/ship`'s commit step) before
running QA.

Also run `/CJ_personal-workflow check "$WORK_ITEM_DIR"` (Tier 1 Directory Mode)
and capture the result. If the output contains `[MISSING]` or `[DRIFT]`
findings:

```
Error: work-item dir has structural issues; refusing to QA.
{summary of violations}
```

Stop. The user must resolve drift before QA can proceed.

## Step 3: Resume Re-validation Gate (Premise 1.1)

This gate decides, on a re-invocation, whether QA may trust a prior green or must
re-verify. It applies to **user-stories** (the only type with QA-owned Phase-2
gates); defect/task have no qa-owned gates, so the gate condition below is never
met and they always re-run (their existing unconditional behavior).

Read the work-item tracker's frontmatter `receipts.qa` block (written by Step 9
of a prior run; absent on a first run) and extract `commit` (the SHA the receipt
vouches for), `ready_for_ship`, and `ac_ids_uncovered`. Then:

```bash
HEAD_SHA="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
```

`RECEIPT_VOUCHES_HEAD` is TRUE only when the `receipts.qa` block is present AND
`ready_for_ship: true` AND `ac_ids_uncovered: []` AND `commit` == `HEAD_SHA`. A
receipt that is missing, not ready, has uncovered ACs, or whose `commit` differs
from HEAD does NOT vouch.

**There is no date-keyed short-circuit.** A `[qa-pass]` merely *dated today* from
an earlier commit must NOT skip re-verification — that date-only branch was the
GAP-A hole this story (S000093) closes.

- **Both QA-owned gates CHECKED** (a re-QA / orchestrator resume): do NOT NO-OP.
  Re-validate — continue to Step 5 (re-run the smoke rows) and read the receipt.
  Set `E2E_REVALIDATE = NOT RECEIPT_VOUCHES_HEAD`: the expensive E2E subagent
  (Step 7) re-runs ONLY when the receipt does not vouch for HEAD (missing /
  incomplete / not-ready / stale-SHA). When the receipt vouches, smoke still
  re-runs (cheap) but the E2E re-run is skipped and the receipt's E2E verdict is
  reused. This is AC1's cost-curation: re-verify every resume without re-paying
  the ~5-min E2E budget when a HEAD-matching receipt already vouches.
- **Gates checked but the receipt is missing / incomplete:** treat as stale
  state — re-validate with `E2E_REVALIDATE = true` (full re-run). A prior green
  without a HEAD-matching receipt is not trustworthy.
- **One or zero gates checked** (fresh or partially-interrupted run): normal full
  run; `E2E_REVALIDATE = true`.

The WRITES at Step 9 are deduped by the Step 6.5 run-start marker (AC5 — a repeated
resume on the same commit adds no duplicate gate transition and no journal thrash).

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

#### Step 4.user-story — Post-ship E2E filter (T000027)

After placeholder filtering, partition `E2E_ROWS` by post-ship tag. A row
is **post-ship** if its `Tag` column contains the literal token `post-ship`
(case-sensitive, word-boundary anchored; the token may be combined with
other tag values, e.g., `core post-ship` or `post-ship usability`).

Post-ship rows describe acceptance criteria that are **structurally only
verifiable after the PR merges to main** (e.g., `gh workflow run` against
a CI workflow file whose remote ref doesn't exist on `origin/main` until
the PR ships; `gh release` checks; production-URL canary smoke). Running
the E2E subagent against these rows forces an `ambiguous → user adjudicates
treat-as-green` loop on a structurally predetermined answer, which both
wastes the AUQ and falsely transitions Phase 2 QA-owned gates on rows
that are not actually verified pre-ship.

Concretely:

```
# Partition E2E_ROWS by post-ship tag.
# Rows whose Tag column contains the literal token `post-ship`
# (word-boundary anchored, to avoid matching 'pre-post-ship' or similar)
# move to E2E_ROWS_POST_SHIP; the rest stay in E2E_ROWS for the normal
# Step 4.5 classifier.
E2E_ROWS_POST_SHIP=()
for row in E2E_ROWS:
    if row.Tag matches /\bpost-ship\b/:
        E2E_ROWS_POST_SHIP.append(row)
        remove row from E2E_ROWS
```

For each row in `E2E_ROWS_POST_SHIP`, append a `[qa-e2e-deferred]` journal
entry to the TRACKER's `## Journal` section BEFORE running Step 4.5's
classifier and BEFORE the Step 6.5 run-start marker. The deferred entries
name the row and its AC so the audit trail makes the deferral explicit:

```
- {YYYY-MM-DD} [qa-e2e-deferred] {E#} ({AC}): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship
```

The filter is applied BEFORE Step 4.5's tool-need classifier so the
post-ship rows never enter the subagent/parent-inline partition. The
resulting `E2E_ROWS` (after the filter) is the input the Step 4.5
classifier and downstream Steps 7 / 7.5 / 8 operate on. Post-ship rows
are tracked only via the `[qa-e2e-deferred]` journal entries — they do
NOT contribute to Step 8's `E2E_VERDICT` aggregation.

**Edge case — all E2E rows are post-ship:** if `E2E_ROWS` is empty
after the post-ship filter AND `E2E_ROWS_POST_SHIP` is non-empty, treat
the same as the existing "E2E empty" edge case (no E2E phase; smoke is
the verification layer; `[qa-pass]` records the no-E2E-rows variant) —
the post-ship rows already have `[qa-e2e-deferred]` audit entries that
preserve their pre-ship status. The Step 4 "Test rows empty (only
placeholder rows) — HALT" gate does NOT fire here: real post-ship rows
were present, just deferred; this is a valid pre-ship state, not a
vacuous test-plan. Phase 2 QA-owned gates may transition on smoke-green
alone in this case; the post-ship ACs remain visibly un-verified in the
journal until a post-merge verification path records them (out of scope
for v1; see T000027 follow-up for tracker-gate + post-merge inference).

**Edge case — type = defect or task:** post-ship filtering does NOT
apply. Defect/task test-plan rows are smoke-equivalent in v1; there is
no E2E phase to partition. The filter is a no-op for those types; the
existing Step 4.defect / Step 4.task path runs unchanged.

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

- **Test rows empty (only placeholder rows) — HALT (all types: defect, task, user-story).**
  Applies uniformly across all work-item types — the refuse-on-placeholder gate
  does NOT exempt user-story; an unpopulated TEST-SPEC is just as vacuous as an
  unpopulated test-plan. Refuse to write `[qa-pass]`. Write a `[qa-refused]`
  journal entry to `$TRACKER` of the form:
  `[qa-refused] {test_rows_source} has only placeholder rows; populate the
  test-plan with real verification steps, then re-run /CJ_qa-work-item.`
  Skip Steps 5-9 entirely. Return refuse-RESULT
  `RESULT: SMOKE=red; E2E=red; PHASE2_GATES=partial` so the orchestrator's
  Step 7 interprets this as halt-at-gate. Surface to the user the message:
  `populate the test-plan, then re-run` along with the affected work-item
  path. Rationale: a placeholder-only test-plan trivially passes a smoke filter
  and falsely trips the `[qa-pass]` gate; the refuse gate forces real test
  coverage before Phase 2 / Phase 3 gates can transition.
- **Smoke empty, E2E populated** (user-story only): log `INFO: no smoke rows; proceeding to
  E2E directly.` Skip to Step 7.
- **Smoke populated, E2E empty:** run smoke (Steps 5-6); skip Step 7;
  proceed to gate transition only if smoke green.
- **For defect/task: E2E always empty** (skipped per type dispatch); proceed
  to gate transition / [qa-pass] after Step 6 if smoke green.
- **Post-ship E2E rows (user-story only):** rows whose Tag contains
  `post-ship` are filtered out BEFORE Step 4.5's classifier and recorded
  as `[qa-e2e-deferred]`. See Step 4.user-story → Post-ship E2E filter
  for the full semantics. If the post-ship filter leaves `E2E_ROWS`
  empty, the "Smoke populated, E2E empty" edge case above applies (smoke
  is the verification layer; `[qa-pass]` records the no-E2E variant).

### Step 4.5: E2E Row Tool-Need Classifier (user-story only)

For type = defect or type = task: skip this sub-step (`E2E_ROWS` already empty).

For user-stories with non-empty `E2E_ROWS`, classify each row into one of four
tool-need categories. The classifier determines whether the row dispatches to
the subagent (Step 7) or runs parent-inline (Step 7.5).

| Category | Definition | Execution path |
|---|---|---|
| `read-only` | Row can be verified using only Read / Bash / Grep / Glob (e.g., file exists at path, function is exported, exit code of a script) | Subagent (Step 7) |
| `skill-invoking` | Row requires invoking a `/skill` command (e.g., the Expected Outcome mentions running `/CJ_*`, `/qa`, etc.) | Subagent (Step 7) — the subagent has the Skill tool |
| `interactive` | Row requires AskUserQuestion (e.g., Expected Outcome describes a user-decision prompt the QA must answer to proceed) | Parent-inline (Step 7.5) |
| `recursive` | Row requires dispatching an Agent / spawning subagents (e.g., row verifies an orchestrator that itself dispatches phase subagents) | Parent-inline (Step 7.5) |

**Classification heuristic:**

1. **Explicit override (preferred):** If the row's `Tag` column contains the
   token `e2e-parent`, classify as `interactive` (parent-inline) regardless of
   content. This is the deterministic escape hatch for ambiguous rows.
2. **Recursive signal:** If the row's `Steps` or `Expected Outcome` mentions
   dispatching an Agent / spawning a subagent / running an orchestrator that
   itself dispatches phase subagents, classify as `recursive`.
3. **Interactive signal:** If the row's `Steps` or `Expected Outcome` mentions
   AskUserQuestion / answering a prompt / picking an option mid-flow, classify
   as `interactive`.
4. **Skill-invoking signal:** If the row's `Steps` or `Expected Outcome`
   references a `/skill-name` invocation, classify as `skill-invoking`.
5. **Default:** classify as `read-only`. Most TEST-SPEC E2E rows describe
   verification-by-inspection of a finished implementation.

**Ambiguity rule:** when in doubt between `read-only` and `skill-invoking`,
pick `skill-invoking` — the subagent has the Skill tool and the row will
still execute. When in doubt between subagent-eligible (`read-only` /
`skill-invoking`) and parent-inline (`interactive` / `recursive`), pick
parent-inline — parent has the full toolbelt and the row will still run.
Parent-inline is the safer fallback because it never silently degrades to
structural inspection.

**Parent-inline cap (R3 mitigation):** if more than 5 rows classify as
`interactive` or `recursive`, mark the surplus rows (rows 6+) as
`deferred-to-manual`. They get a `[qa-e2e]` entry with `ambiguous —
deferred to manual (parent-inline cap reached)` instead of running. Surface
the cap in the Step 8 aggregate verdict so the user sees the deferral.

Partition `E2E_ROWS` into two groups:

- `E2E_ROWS_SUBAGENT` — rows classified `read-only` or `skill-invoking`
- `E2E_ROWS_PARENT` — rows classified `interactive` or `recursive` (up to 5),
  plus surplus `deferred-to-manual` rows

If both groups are empty (every row deferred): proceed (via Step 8.6) to
Step 9 with `E2E_VERDICT = ambiguous` (all rows deferred to manual).

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
implementation, then re-invoke `/CJ_qa-work-item`. On `Skip smoke`: continue
to Step 6.5 with `SMOKE_VERDICT = red` recorded in the tracker; the parent
skill caller bears responsibility. On `Abort`: print "Aborted." and exit.

## Step 6.5: E2E Run Marker (D000018)

Before any `[qa-e2e]` entry is written (by Step 7 subagent or Step 7.5
parent-inline), the orchestrator writes a run-start marker to the TRACKER's
`## Journal` section. The marker scopes Step 8's verdict aggregation to
entries from THIS run, so prior runs' entries do not pollute the verdict
math (D000018 R5 mitigation).

For type = defect or type = task: skip this step (no E2E phase; the type
dispatch in Step 4 already set `E2E_ROWS = []`).

For user-stories: capture a run ID and write the marker.

```bash
QA_RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
QA_RUN_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
```

Append the marker entry verbatim:

```
- {YYYY-MM-DD} [qa-e2e-run-start] RUN_ID={QA_RUN_ID} commit={QA_RUN_COMMIT}
```

Store `QA_RUN_ID` for use in Step 8 (the aggregator finds the LATEST marker
line and only considers `[qa-e2e]` entries appearing after it).

**Idempotency note:** the marker is written every run. Step 3 no longer has an
early-exit NO-OP path (S000093 — it re-validates instead), so on a re-QA control
always reaches here. The marker is also the **write-idempotency anchor** (AC5):
Step 9 transitions the Phase-2 gates and appends the `[qa-pass]` entry once per
marker, so a re-validation that reuses the same `QA_RUN_COMMIT` does not
duplicate the gate transition or thrash the journal. On re-runs that go through
to E2E, each run gets its own marker; Step 8 always scopes to the latest one.

## Step 7: Spawn QA Engineer Subagent (E2E — user-story only)

For type = defect or type = task: skip to Step 8.6 (the audit block), then
Step 9 (the type dispatch in Step 4 already set `E2E_ROWS = []`; this guard
re-confirms for clarity).

**Resume E2E-revalidation guard (AC1, S000093):** if `E2E_REVALIDATE = false`
(Step 3 found a complete `receipts.qa` that vouches for HEAD), SKIP the E2E
subagent re-run AND Step 7.5 — reuse the receipt's E2E verdict as `E2E_VERDICT`
(a receipt with `ready_for_ship: true` and no uncovered ACs means the prior E2E
passed for this exact SHA). Continue to Step 8.6, then Step 9. This avoids re-paying the ~5-min
E2E budget when the receipt already vouches for HEAD; the smoke rows re-run at
Step 5 provide the cheap re-validation.

If `E2E_ROWS_SUBAGENT` is empty (only parent-inline rows, or all rows
deferred): skip to Step 7.5.

Otherwise, dispatch the QA engineer subagent via the Agent tool with only the
subagent-eligible rows from Step 4.5's partition (`E2E_ROWS_SUBAGENT`). The
prompt is structured **stable preamble first, variable parts last** for
prompt-cache friendliness (Premise: cache amortizes the stable preamble
across runs).

**Stable preamble** (identical every run; cacheable; XML-tag delimited per
Anthropic prompt-engineering guidance):

```
<role>
QA engineer.
</role>

<task>
Verify each E2E acceptance criterion in the TEST-SPEC.md you are given
(filtered to the subset listed in <inputs> — the parent orchestrator handles
interactive/recursive rows separately).

For each row in the filtered E2E rows list:
1. Read the Scenario, Steps, Expected Outcome, Rubric columns.
2. Use Read, Bash, Grep, Glob, AND Skill tools to verify the Expected Outcome.
   - When an E2E row requires running a /skill command, invoke it directly
     via the Skill tool. Do not substitute structural source inspection
     ("file X exists at path Y") for actually running the skill — the row's
     Expected Outcome describes user-observable behavior, not code structure.
3. Categorize the result:
   - green: criterion verified to pass
   - red: criterion verified to fail
   - ambiguous: cannot determine pass/fail with available tools
4. Append a journal entry to TRACKER.md (path in <inputs>) for each row,
   in this format:
   - {YYYY-MM-DD} [qa-e2e] {E#} ({AC}): {green|red|ambiguous} — {1-line summary}
   On red or ambiguous, include a file path and line range that supports
   the verdict (e.g., "see scripts/test.sh:42"). If you marked a row
   ambiguous because the verification needed AskUserQuestion or recursive
   Agent dispatch (tools you don't have), say so explicitly in the summary
   (e.g., "needs AUQ — defer to parent-inline"); the parent orchestrator
   will re-run such rows itself.
</task>

<constraints>
- Do NOT spawn subagents (no Agent tool calls). You are the leaf node. If a
  row genuinely requires recursive Agent dispatch, mark it ambiguous with
  the reason "needs recursive Agent — defer to parent-inline" — the parent
  will handle it.
- Do NOT modify source files. The only file you write to is the TRACKER.md
  in <inputs> (Edit/Write to append journal entries).
- Do NOT exceed 5 minutes of wall-clock work. If you can't verify a row
  efficiently, mark it ambiguous and move on.
- Stay within the work-item directory tree for verification. You may Read
  files outside it for context, but do not modify any.
</constraints>

<return-contract>
End your turn with a single 1-2 sentence summary of the overall E2E result,
plus a file pointer to the tracker. Examples:
- "All 5 E2E criteria green. Tracker journal updated at <path>."
- "1 red finding (E2): expected exit code 0, got 1. See <path> journal."
- "2 ambiguous (E3, E5): need user judgment on rubric. See <path>."

Do NOT return a verbose findings dump in your response. Detailed findings
go to the tracker; the response is for the parent skill's summary.
</return-contract>
```

**Variable parts** (per-invocation; not cached; appended as the `<inputs>` tag):

```
<inputs>
Work-item directory: {USER_STORY_DIR}
TEST-SPEC path: {TEST_SPEC}
TRACKER path: {TRACKER}
WORK_ITEM_ID: {WORK_ITEM_ID}
SMOKE_VERDICT (already run): {SMOKE_VERDICT}
Rows to verify (subagent-eligible only): {E#, E#, ...}
Rows the parent will handle separately (interactive/recursive): {E#, E#, ...}
</inputs>

Now run the E2E verification per the stable preamble above. Verify ONLY the
subagent-eligible rows listed in <inputs>; the parent runs the others inline.
```

Invoke the Agent tool with this prompt and a 5-minute timeout
(`timeout: 300000`). Use `subagent_type: "general-purpose"` (the QA work
needs full filesystem read + bash + Skill; no specialized agent type matches).

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

## Step 7.5: Parent-Inline E2E (interactive / recursive rows)

For type = defect or type = task: skip to Step 8.

If `E2E_ROWS_PARENT` is empty (no interactive/recursive rows from Step 4.5):
skip to Step 8.

Otherwise, the parent orchestrator runs the partitioned rows inline using its
full toolbelt (Skill + AskUserQuestion + Agent). Parent-inline execution is
gated by the same smoke-red short-circuit as Step 7 — if smoke was red and the
user chose to skip-and-proceed, parent-inline still runs (consistent with
Step 7's "Skip smoke" path); if the user aborted at Step 6, control never
reaches here.

For each row in `E2E_ROWS_PARENT`:

1. **Deferred rows (parent-inline cap exceeded):** if the row was marked
   `deferred-to-manual` in Step 4.5, do NOT execute. Write a journal entry:
   ```
   - {YYYY-MM-DD} [qa-e2e] {E#} ({AC}): ambiguous — deferred to manual (parent-inline cap reached at 5 rows) [parent-inline]
   ```
   The trailing `[parent-inline]` source tag is consistent with executed
   parent-inline entries (Step 7.5.5) so the Step 8 aggregator's source
   bookkeeping stays uniform. Continue to the next row.

2. **Recursive rows:** invoke the Agent tool per the row's Expected Outcome
   (e.g., row references an orchestrator that itself spawns phase
   subagents). Capture the dispatched skill's result. Determine
   verdict by inspecting the dispatched skill's RESULT line (lenient parse:
   strip `>` prefixes and code fences) or by inspecting tracker journal
   changes the row's Expected Outcome describes.

3. **Interactive rows:** execute the Steps using the parent's full tool
   surface. When the row's flow requires AskUserQuestion, invoke it; record
   the user's answer in the journal entry's summary so the verdict is
   auditable. When the row requires invoking a skill that prompts the user,
   the parent's AUQ tool handles those prompts natively.

4. Categorize the result per the same rubric as Step 7 (`green` / `red` /
   `ambiguous`).

5. Append a journal entry in the **identical shape** the subagent emits
   (Step 8 aggregator joins on this format):

   ```
   - {YYYY-MM-DD} [qa-e2e] {E#} ({AC}): {green|red|ambiguous} — {1-line summary} [parent-inline]
   ```

   The trailing `[parent-inline]` tag is the source marker for Step 8's
   aggregator. The verdict (`green` / `red` / `ambiguous`) and `E#` are
   identical-shape with subagent entries; only the source tag differs.

6. **Parent-inline timeout:** parent-inline has no hard 5-minute cap (the
   parent runs in user context, not a separate Agent context). However, if a
   single row's execution exceeds 5 minutes of wall-clock, mark the row
   `ambiguous — exceeded 5-minute soft cap` and continue. Surface the soft
   timeout in the Step 8 aggregate.

After all `E2E_ROWS_PARENT` rows are processed, store the per-row verdicts
in `PARENT_VERDICTS` (parallel to the subagent's per-row writes).

If `E2E_ROWS_SUBAGENT` was empty (Step 7 was skipped), set
`SUBAGENT_DURATION_S = 0` and `SUBAGENT_SUMMARY = "(no subagent-eligible rows)"`
so Step 8's aggregate prints coherently.

## Step 8: Process E2E Results (aggregate subagent + parent-inline)

Aggregate `[qa-e2e]` entries from both sources by row number, scoped to
this run via the Step 6.5 marker:

1. **Scope to this run (D000018 R5 mitigation).** Find the line number of
   the LATEST `[qa-e2e-run-start]` entry in the TRACKER (matches the
   `QA_RUN_ID` written at Step 6.5). Only consider `[qa-e2e]` entries
   AFTER that line. Entries before the latest marker are from prior runs
   and MUST NOT be aggregated — they may belong to a different commit, a
   different partition decision, or pre-D000018 schema.

   Concretely:
   ```bash
   MARKER_LINE=$(grep -n '\[qa-e2e-run-start\]' "$TRACKER" | tail -1 | cut -d: -f1)
   # then aggregate only journal lines with index > MARKER_LINE
   ```

2. **Anchored row-number match.** Match each E2E entry's row number with
   an anchor on the trailing ` (` to prevent `E1` matching `E10`, `E11`,
   etc. Regex: `\[qa-e2e\] (E[0-9]+) \(` (capture `E[0-9]+` followed by a
   literal space and `(`). The `(` is always present because the entry
   format is `[qa-e2e] E# (AC-...): ...` — see the format spec in Step 7
   stable preamble and Step 7.5.5.

3. For each distinct row number `E#`, take the most recent entry (last
   wins) as the row's authoritative verdict. Source tag `[parent-inline]`
   is preserved for audit; the verdict word (`green` / `red` /
   `ambiguous`) is what counts.

4. If a row appears in neither source (classifier bug — should not happen),
   record an `[impl-finding] qa-e2e classifier missed row E#; treating as
   ambiguous` entry and treat the row as ambiguous.

Compute aggregate `E2E_VERDICT` from the union of per-row verdicts:

- `green` — all rows green
- `red` — at least one row red
- `ambiguous` — no red rows but at least one ambiguous (including
  `deferred-to-manual` and `exceeded 5-minute soft cap`)

Append a summary journal entry. The summary includes the source split so
the user sees what the subagent vs parent-inline contributed. The
`{N_DEFERRED}` count covers both parent-inline-cap deferrals AND
T000027 post-ship deferrals (`[qa-e2e-deferred]` entries written at
Step 4.user-story → Post-ship E2E filter) — both shapes represent E2E
rows that exist but did not run pre-ship for structural reasons:

```
- {YYYY-MM-DD} [qa-e2e-summary] {E2E_VERDICT} ({SUBAGENT_DURATION_S}s subagent; {N_PARENT} rows parent-inline; {N_DEFERRED} deferred): {SUBAGENT_SUMMARY verbatim}
```

**On `E2E_VERDICT = green`:** silent path. Continue to Step 8.6 (the audit
block), then Step 9. NO AskUserQuestion (Premise: AUQ only on red/ambiguous,
autoplan-style — a standalone run's audit findings are advisory and ride the
RESULT; there is no build-path audit checkpoint).

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

## Step 8.6: Contract refresh + audits (all types — the audit block)

EVERY green path into Step 9 passes through this block (user-stories arrive
from Step 8 green / the receipt-reuse path; defect/task arrive from their
smoke-green type dispatch). It has two halves: the **overlay WRITES** (8.6a
refresh `spec/test-spec-custom.md`, 8.6b refresh `spec/doc-spec-custom.md`) and
the **three-stage AUDITS** (8.6c `/CJ_doc_audit`, 8.6d `/CJ_test_audit`). The
WRITES always run inline (the feedback-loop order that keeps living registries
from rotting: the contract is updated, then verified); the AUDITS are
**conditionally deferrable** — see the defer detection below.

### 8.6.0 — Defer detection (`DEFER_AUDIT: true` + `DEFER_SYNC: true`)

The cj_goal orchestrators run neither the three-stage agent-judged AUDIT nor the
slow agent-judged overlay SYNC sweep inline — both are advisory drift-catches that
now run on-demand (locally via `/CJ_doc_audit` + `/CJ_test_audit`, or `bash
scripts/audit-nightly.sh`), off the build path (F000076 relocated the audit;
F000078 relocated the agentic sync). They signal
this to QA with two sibling literal directives embedded in the QA Agent-tool
dispatch PROMPT (NOT argv flags — `/CJ_qa-work-item` is dispatched as a subagent
prompt, so the carrier is a greppable literal string in the pipeline.md prompt
templates, not a CLI flag):

- `DEFER_AUDIT: true` — skip the inline three-stage audit (gates 8.6c/8.6d).
- `DEFER_SYNC: true` — skip the inline AGENT-JUDGED overlay AMENDMENT sweep in
  8.6a/8.6b (the SLOW part: re-reading the whole diff to judge which EXISTING rows
  need amending for semantic changes). The fast DETERMINISTIC obligation — every
  NEW `tests/*.test.sh` gains its required `units:` row, every NEW declared doc
  gains its overlay row — STILL runs inline, because `validate.sh` Check 24 / the
  doc-spec on-disk check hard-fail the PR without it.

At the START of this block, set both flags by inspecting the dispatch context (the
ROLE/TASK prompt this QA run was invoked with):

- If the dispatch prompt contains the literal string `DEFER_AUDIT: true` →
  `DEFER_AUDIT = true`; otherwise (standalone, no directive) → `DEFER_AUDIT = false`.
- If the dispatch prompt contains the literal string `DEFER_SYNC: true` →
  `DEFER_SYNC = true`; otherwise → `DEFER_SYNC = false`.

Both default to `false` on a standalone `/CJ_qa-work-item` run, so a standalone run
keeps the FULL inline overlay sweep + audit — UNCHANGED. The four cj_goal
orchestrators pass BOTH directives.

`DEFER_AUDIT` gates 8.6c/8.6d (the audits). `DEFER_SYNC` gates ONLY the
agent-judged amendment sweep of 8.6a/8.6b — the deterministic new-surface row
always runs (the orchestrator's pre-doc-sync commit + deterministic doc-regen fold
it into the PR). The on-demand `/CJ_doc_audit` + `/CJ_test_audit` are the safety net
that catches the deferred agentic doc/test drift and files the `audit-drift` issue.

**Verdict semantics (load-bearing).** Audit findings do NOT flip the QA
RESULT red. Tests own the green/red verdict (the existing `[qa-red]` gate);
Step 9 still transitions Phase-2 gates on test-green; findings ride the
`AUDITS=` field of a green RESULT plus the fenced `AUDIT_FINDINGS` block, for the
operator to read at the end of a standalone run. When `DEFER_AUDIT = true` (an
orchestrator-driven run) this skill emits no audit findings at all — the cj_goal
orchestrators no longer run an inline audit; the agent-judged doc/test audit runs
on-demand (locally via `/CJ_doc_audit` + `/CJ_test_audit`, or `bash
scripts/audit-nightly.sh`), off the build path (F000076). (Standalone runs still
audit inline — see below — and there is no
orchestrator checkpoint on either path.)

**Subagent posture.** This skill usually runs AS a leaf subagent, and a
subagent cannot spawn subagents (the nested-subagent wall) — so 8.6c/8.6d
execute the audit skills' logic INLINE by reading their SKILL.md files
(`skills/CJ_doc_audit/SKILL.md`, `skills/CJ_test_audit/SKILL.md`; resolve
repo-local `skills/` first, then `~/.claude/skills/`). Standalone interactive
runs MAY dispatch them via the Skill tool instead. Either way the report
shapes below are identical. In a repo where the spec engines are unreachable,
each audit reports its engine finding (per its SKILL.md Step 1) — never a
crash.

### 8.6a — Update `spec/test-spec-custom.md` (the units overlay)

**Deterministic obligation — ALWAYS runs (even under `DEFER_SYNC`).** Every new
`tests/*.test.sh` THIS work-item added MUST gain a `units:` row (source
`scripts/test.sh`, anchor the literal runner path) — `validate.sh` Check 24
hard-fails the PR otherwise; a renamed/removed surface gets its row
fixed/dropped. This is a mechanical add keyed off the new/renamed test path: it
is fast, model-free, and always runs so the deterministic per-PR gate stays
green. In a repo with no overlay and no repo-declared units, record `none` (do
not invent an overlay).

**Agent-judged amendment sweep — SKIPPED when `DEFER_SYNC = true`.** The SLOW
part — re-reading the whole diff to judge which EXISTING `units:` rows need
amending for the semantic changes this work-item made — runs ONLY when
`DEFER_SYNC = false` (standalone `/CJ_qa-work-item`). When `DEFER_SYNC = true`
(an orchestrated build), SKIP it; the on-demand `/CJ_test_audit` catches any
un-amended overlay drift and files the `audit-drift` issue. Report one line
(`sweep:deferred` when the amendment sweep was skipped):

```
spec-update: test-spec-custom <added: ids | none>; sweep:<ran|deferred>
```

### 8.6b — Update `spec/doc-spec-custom.md` (the doc overlay)

Symmetric, with the same `DEFER_SYNC` split. **Deterministic (always):** a new
repo-specific root/spec doc THIS work-item added gets an overlay row
(`section: custom`); a removed doc gets its row dropped — the doc-spec on-disk
check hard-fails the PR otherwise. General docs never go here (the general file
is the seed — never edited in place). **Agent-judged sweep (skipped under
`DEFER_SYNC = true`):** the semantic re-read for amendments runs only standalone;
under an orchestrated build it defers to the on-demand `/CJ_doc_audit`. Report one
line:

```
spec-update: doc-spec-custom <added: paths | none>; sweep:<ran|deferred>
```

### 8.6c — Run `/CJ_doc_audit` (inline in subagent context)

**Deferral guard.** If `DEFER_AUDIT = true` (from Step 8.6.0): SKIP this
sub-step entirely. The agent-judged audit runs on-demand off the build path.
Do not run the engine, do not judge any stage, do not capture a report. Proceed
to 8.6d (which is also skipped) and then to the Extended RESULT contract, where
the deferred path sets `AUDITS=deferred` and emits NO `AUDIT_FINDINGS` block.

Otherwise (`DEFER_AUDIT = false` — standalone run):

Execute the doc audit per `skills/CJ_doc_audit/SKILL.md` — all three stages
(Stage 1 is one `doc-spec.sh --check-on-disk` engine call; Stages 2+3 run
INLINE per the skill's stage protocols — the nested-subagent wall means no
fresh-context dispatch here; label their headers `(agent-judged, inline)`).
Capture its full per-stage report (the `DOC_AUDIT:` / `FINDINGS=` /
`STAGE1_FINDINGS=` / `STAGE2_FINDINGS=` / `STAGE3_FINDINGS=` /
`DOCS_AUDITED=` / `seeded:` headline + the three `--- stage N ---` sections).

### 8.6d — Run `/CJ_test_audit` (inline in subagent context)

**Deferral guard.** If `DEFER_AUDIT = true` (from Step 8.6.0): SKIP this
sub-step entirely (the same as 8.6c). The agent-judged audit runs on-demand off
the build path. Proceed to the Extended RESULT
contract's deferred path.

Otherwise (`DEFER_AUDIT = false` — standalone run):

Execute the test audit per `skills/CJ_test_audit/SKILL.md` — all three stages
(Stage 1 is the existing `test-spec.sh --validate` + `--check-coverage`
engine calls; Stages 2+3 run INLINE per the skill's stage protocols; label
their headers `(agent-judged, inline)`). Capture its full per-stage report
(the `TEST_AUDIT:` / `FINDINGS=` / `STAGE1_FINDINGS=` / `STAGE2_FINDINGS=` /
`STAGE3_FINDINGS=` / `UNITS_AUDITED=` / `seeded:` headline + the three
`--- stage N ---` sections). For the `suite-green` rule, THIS QA run's own
smoke/E2E results are the freshest evidence — cite them.

### Extended RESULT contract

The RESULT line this skill returns to its caller extends with the `AUDITS=`
field. Its shape — and whether an `AUDIT_FINDINGS` block follows — depends on
`DEFER_AUDIT` (Step 8.6.0).

#### Deferred path (`DEFER_AUDIT = true`)

When an orchestrated build defers, 8.6a/8.6b ran their DETERMINISTIC half only
(new-surface `units:`/overlay rows added inline so the per-PR gate stays green);
their agent-judged AMENDMENT sweep was skipped via `DEFER_SYNC`, and 8.6c/8.6d
were skipped via `DEFER_AUDIT`. The RESULT's `AUDITS=` field reads the literal
`deferred`, carrying only the deterministic spec-update summary from 8.6a/8.6b:

```
RESULT: SMOKE=<...>; E2E=<...>; PHASE2_GATES=<...>; AUDITS=deferred,spec_updates:<summary>
```

(for defect/task the existing per-type RESULT shape gains the same trailing
`AUDITS=deferred,spec_updates:<summary>` field; `<summary>` reflects only the
deterministic adds, since the amendment sweep deferred). **Emit NO
`AUDIT_FINDINGS` block** — the agent-judged audit + the agentic overlay sweep both
run on-demand off the build path. Append one journal entry recording the
skip:

```
- {YYYY-MM-DD} [qa-audit] AUDITS=deferred,spec_updates:<...> (Step 8.6a/8.6b: deterministic new-surface rows added inline; the agent-judged amendment sweep SKIPPED via DEFER_SYNC + 8.6c/8.6d SKIPPED via DEFER_AUDIT — the agentic doc/test sync + audit run on-demand off the build path)
```

Then continue to Step 9 (transition criteria UNCHANGED — the deferral does not
affect the test-green gate transition). Skip the rest of this Extended RESULT
contract section (the inline `AUDIT_FINDINGS` shape below applies only to the
standalone path).

#### Inline path (`DEFER_AUDIT = false` — standalone)

The RESULT line extends with the full `AUDITS=` field:

```
RESULT: SMOKE=<...>; E2E=<...>; PHASE2_GATES=<...>; AUDITS=doc:<ok|findings:n>,test:<ok|findings:n>,spec_updates:<summary>
```

(for defect/task the existing per-type RESULT shape gains the same trailing
`AUDITS=` field). `doc:`/`test:` carry each audit's status — `ok` or
`findings:<n>` from its `FINDINGS=` line; `spec_updates:` is a compact
summary of 8.6a/8.6b (e.g. `test-spec-custom+3,doc-spec-custom:none`).

Immediately after the RESULT line, emit the fenced report block for the operator
to read at the end of this standalone run. This is the **full audit
report**, not a headline digest — the operator reads the audit evidence
directly without digging into raw output (operator decision
2026-06-12, at this gate's first live firing). It carries, in order: the two
spec-update lines, then EACH audit's complete PER-STAGE report — the headline
(`DOC_AUDIT:`/`TEST_AUDIT:` + `FINDINGS=` + the `STAGE1_FINDINGS=`/
`STAGE2_FINDINGS=`/`STAGE3_FINDINGS=` trio + `DOCS_AUDITED=`/
`UNITS_AUDITED=` + `seeded:`), then its three `--- stage N ---` sections (a
skipped stage prints its header + one `skipped: <reason>` line):

````
```AUDIT_FINDINGS
spec-update: test-spec-custom <added: ids | changed: ids | none — one-line why>
spec-update: doc-spec-custom <added: paths | changed: paths | none — one-line why>
--- doc audit ---
DOC_AUDIT: <ok|findings>
FINDINGS=<n>
STAGE1_FINDINGS=<n>
STAGE2_FINDINGS=<n>
STAGE3_FINDINGS=<n>
DOCS_AUDITED=<n>
seeded: <yes|no>
--- stage 1: deterministic conformance (engine) ---
<the doc-spec.sh --check-on-disk output verbatim (check:/FINDING: stage1/
 lines + CHECKS_RUN=/FINDINGS= tail); plus any stage1/engine|seed|registry
 pre-stage FINDING lines>
--- stage 2: requirement compliance (agent-judged, inline) ---
<per-doc verdicts: `<path>: satisfies | missing-requirement (soft — no
 requirement: declared) | n/a — <why> | FINDING: stage2/<path> — clause
 '<clause>' not met: <evidence>`>
--- stage 3: implementation drift (agent-judged, inline) ---
<ground-truth summary line, then per-doc verdicts: `<path>: no-drift |
 FINDING: stage3/<path> — <named delta>`>
--- test audit ---
TEST_AUDIT: <ok|findings>
FINDINGS=<n>
STAGE1_FINDINGS=<n>
STAGE2_FINDINGS=<n>
STAGE3_FINDINGS=<n>
UNITS_AUDITED=<n>
BEHAVIORS_AUDITED=<n>
seeded: <yes|no>
--- stage 1: deterministic conformance (engine) ---
<the test-spec.sh --validate + --check-coverage output verbatim (or the
 units-inactive / behavior-inactive notes); plus any stage1/ pre-stage FINDING lines>
--- stage 2: requirement compliance (agent-judged, inline) ---
<per-rule + per-unit + per-behavior verdicts with cited evidence: `<id>: satisfies —
 <evidence> | behavior:<id>: faithful — <evidence> | n/a — <why> |
 FINDING: stage2/<id> — <detail> | FINDING: stage2/behavior:<id> — <detail>`>
--- stage 3: implementation drift (agent-judged, inline) ---
<ground-truth summary line, then `<surface|unit-id>: no-drift | FINDING:
 stage3/<id> — <named delta>`>
```
````

Append one journal entry to the tracker recording the inline block ran:

```
- {YYYY-MM-DD} [qa-audit] AUDITS=doc:<...>,test:<...>,spec_updates:<...> (Step 8.6a-d; findings ride the green RESULT — standalone run; the operator reviews them)
```

Then continue to Step 9 — Step 9's transition criteria are UNCHANGED (audit
findings do not block the test-green gate transition).

## Step 9: Transition Phase 2 Gates / Record [qa-pass] (per type, if green)

### Step 9.0: Execution receipt + fail-closed verdict (user-story — S000093)

For user-stories, BEFORE transitioning any gate: compute the **fail-closed
verdict** and write the **execution receipt** (the durable, SHA-anchored record
Step 3 re-validates against). Defect/task skip this step (no receipt, no qa-owned
gates — unchanged behavior).

**Fail-closed verdict.** The run reads GREEN only if ALL hold: `SMOKE_VERDICT =
green`, AND `E2E_VERDICT = green` (or there are genuinely no E2E rows after
filtering — the existing vacuous-green paths below), AND every acceptance
criterion has at least one passing row (`ac_ids_uncovered` is empty). Otherwise
the run reads **RED**. A work-item with **no execution receipt** (artifacts
present but never run — AC4) is RED, never green-by-absence: green requires a
receipt this run produces (AC3). Never infer green from a missing or incomplete
receipt.

**Write the receipt.** Write (overwrite-per-phase, not append) a `receipts.qa`
block into the work-item **tracker's YAML frontmatter** (the no-ripple home; the
`tracker-user-story.md` template documents the schema as a commented `# receipts:`
reference). Adopt work-copilot's locked `receipts.qa` schema
(`work-copilot/prompts/qa.prompt.md` §"Receipt schema") PLUS a `commit` field for
the SHA-anchoring Step 3 needs:

```yaml
receipts:
  qa:
    phase: 3
    commit: "<git rev-parse HEAD>"          # S000093: the SHA this receipt vouches for
    completed_at: "<ISO-8601 UTC>"
    test_rows_run: <int>                     # smoke + E2E rows actually executed this run
    ac_ids_covered: [<AC ids with a passing row>]
    ac_ids_uncovered: [<AC ids with no passing row>]
    diff_audit:
      changed_files_without_tests: [<paths>]
    journal_entries: [<the [qa-*] lines written this run>]
    ready_for_ship: <true|false>             # true iff GREEN per the fail-closed verdict
    next_legal: [<phase names>]
```

When `E2E_REVALIDATE = false` (Step 7 reused the receipt's E2E verdict), refresh
`completed_at` + `commit` but keep the reused E2E rows reflected in
`test_rows_run` / `ac_ids_covered`.

**Idempotent writes (AC5).** Key the gate transition + the `[qa-pass]` append to
the Step 6.5 run-start marker (`QA_RUN_ID` / `QA_RUN_COMMIT`): do them once per
marker. If a `[qa-pass]` for the current `QA_RUN_COMMIT` already exists below the
latest marker, refresh the receipt's `completed_at` but do NOT re-transition the
gates or append a duplicate `[qa-pass]`.

Transition the per-type gates below ONLY when green:

- **user-story:** the Step 9.0 fail-closed verdict is GREEN (`SMOKE_VERDICT =
  green` AND `E2E_VERDICT = green` (or no E2E rows after filtering) AND
  `ac_ids_uncovered` empty AND a receipt was written this run).
- **defect / task:** `SMOKE_VERDICT = green` from the test-plan rows (no receipt,
  no qa-owned gates — unchanged behavior).

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
`/CJ_implement-from-spec` and were already green per Step 2's boundary check.

### Step 9.defect / Step 9.task

Defect and task templates have no qa-owned Phase 2 gates. Do NOT modify
the Phase 2 Gates block.

The Phase 3 `Test-plan verified` gate (defect) / `Test-plan verified (all
scenarios passing)` gate (task) is the verification-state recipient, but
this skill does not transition Phase 3 gates in v1 — those are marked at
`/ship` time or by `/CJ_personal-workflow check --update`'s post-merge
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

If E2E was empty because ALL E2E rows were post-ship (T000027 — filtered
out at Step 4.user-story → Post-ship E2E filter):
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (user-story): green smoke + {N} E2E row(s) deferred to post-merge (all post-ship). Phase 2 gates transitioned; post-ship ACs awaiting post-merge verification (see [qa-e2e-deferred] entries above).
```

If smoke was empty (E2E only, green):
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (user-story): no smoke rows + green E2E. Phase 2 gates transitioned.
```

If both smoke and E2E rows are empty (only placeholder rows): Step 4's edge-case
HALT fires BEFORE reaching Step 9 — no `[qa-pass]` entry is written. The
tracker receives a `[qa-refused]` entry instead. This template intentionally
has no entry shape here; the refuse-RESULT path returns
`SMOKE=red; E2E=red; PHASE2_GATES=partial` and the orchestrator halts at gate.

For defect:
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (defect): green smoke from test-plan rows ({N} rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
```

For task:
```
- {YYYY-MM-DD} [qa-pass] {WORK_ITEM_ID} (task): green smoke from test-plan rows ({N} rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
```

## Step 10: Boundary Check at End (Premise 1.3)

Run `/CJ_personal-workflow check "$WORK_ITEM_DIR"` (Tier 1 Directory Mode).

**If the result contains no `[MISSING]` or `[DRIFT]` findings:** continue to
Step 11.

**If the result contains violations** (the QA writes broke compliance):

AskUserQuestion:

> /CJ_personal-workflow check failed after QA writes:
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
Audits:   doc:{ok|findings:n}, test:{ok|findings:n}, spec_updates:{summary}   (Step 8.6 — findings ride green; standalone: the operator reviews)
Deferred: {N_DEFERRED} (post-ship: {N_POST_SHIP}, parent-inline-cap: {N_CAP})
Phase 2:  {gates transitioned | unchanged}

Tracker:  {TRACKER}
Next:
  /CJ_personal-workflow check {WORK_ITEM_DIR}    # verify
  /ship                                        # if all Phase 2 green (user-story) or commit gate satisfied (defect/task)
```

The `Deferred:` line is omitted if `N_DEFERRED == 0` (no post-ship rows
and no parent-inline cap deferrals — the common case). When non-zero, it
makes post-ship rows visible to the user so they remember to verify
those ACs after merge.

When the Step 8.6 audits were skipped (`DEFER_AUDIT = true` — an
orchestrator-driven run), the `Audits:` line reads
`deferred, spec_updates:{summary}   (8.6c/8.6d skipped via DEFER_AUDIT — the
agent-judged audit runs on-demand off the build path; 8.6a/8.6b ran inline)` instead of the
per-audit `doc:`/`test:` status. The standalone (non-deferred) run prints
the per-audit status shape shown above.

Last line in the chat is the tracker path, formatted for copy-paste.

---

## Error Handling

See [SKILL.md](SKILL.md)'s Error Handling table. All errors are
non-recoverable (skill exits cleanly); the user re-runs after fixing the
underlying issue.

## Idempotency Contract (Premise 1.1)

This skill is idempotent in its WRITES, and re-verifies rather than trusting a
stale green (S000093). Behaviors:

1. **Gates already checked** (Step 3 — a re-QA / resume): re-validate; do NOT
   NO-OP on a date-keyed `[qa-pass]`. Re-run the smoke rows and read the
   `receipts.qa` execution receipt; re-run the expensive E2E subagent ONLY when
   the receipt does not vouch for HEAD (missing / incomplete / stale-SHA). The
   Step 6.5 run-start marker makes the WRITES idempotent — a repeated resume on
   the same `QA_RUN_COMMIT` adds no duplicate gate transition and no journal
   thrash (AC5).
2. **Stale gate state** (Step 3): gates checked but no receipt / no `[qa-pass]`
   audit trail. Re-run smoke + E2E to re-establish ground truth.
3. **Partial-run recovery** (Step 3): one gate checked, other unchecked.
   Re-run from Step 4; gate transitions in Step 9 reset to consistent state.

No automatic rollback on smoke or E2E failure. Tracker journal records what
was tried and the verdict; gates stay in their pre-run state if QA didn't
complete green.

## Boundary Validation Contract (Premise 1.3)

`/CJ_personal-workflow check` runs at:

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
- **Entry format (D000018 R6 mitigation):** every `[qa-e2e]` entry MUST
  use the exact shape `[qa-e2e] E# (AC-...): verdict — summary`. The
  literal ` (` after the row number is the Step 8 aggregator's anchor;
  without it, `E1` would match `E10`, `E11`, etc. The aggregator regex
  is `\[qa-e2e\] (E[0-9]+) \(` so the trailing ` (` is mandatory.
- **Tool surface (re-probed 2026-05-11):** Read, Bash, Grep, Glob, Skill.
  AskUserQuestion and Agent are NOT in the subagent's deferred-tools list;
  rows requiring those are partitioned by Step 4.5 into parent-inline
  (Step 7.5) instead. Skill-invoking rows are subagent-eligible — the
  subagent has the Skill tool and Step 7's prompt explicitly grants
  permission.

The subagent's filesystem boundary is documented but not enforced —
verification relies on the prompt instruction. If the subagent violates
the contract (e.g., modifies source files), the user notices via git diff
on the next commit.

## Parent-Inline E2E Contract (D000018)

Step 7.5 is the parent-orchestrator counterpart to Step 7 for rows the
subagent cannot handle (interactive / recursive). Contract:

- Uses the parent's full toolbelt: Skill + AskUserQuestion + Agent.
- Per-row journal entry shape is **identical** to subagent entries except
  for a trailing `[parent-inline]` source tag. The literal ` (` after the
  row number is mandatory (Step 8's aggregator regex `\[qa-e2e\] (E[0-9]+) \(`
  anchors on it — D000018 R6 mitigation). Step 8 aggregates both sources
  by row number; the tag is for audit, not for verdict math.
- Capped at 5 rows per run (R3 mitigation). Surplus rows are recorded as
  `ambiguous — deferred to manual (parent-inline cap reached at 5 rows)`
  so the aggregate verdict is visible and accurate. Deferred entries also
  follow the `E# (AC-...): ambiguous — ...` shape with the trailing ` (`
  anchor so the aggregator scopes them correctly.
- Soft 5-minute per-row wall-clock cap. The parent doesn't kill the row
  (no separate process), but rows exceeding the soft cap are marked
  ambiguous so a runaway row doesn't block the whole run.
- Smoke-red short-circuit (Step 6) still gates parent-inline execution.
  Step 7.5 runs only if Step 6 didn't abort.
- **Run-scoping (D000018 R5 mitigation):** Step 6.5 writes a
  `[qa-e2e-run-start] RUN_ID=...` marker before any `[qa-e2e]` entry.
  Step 8 only aggregates entries appearing AFTER the latest marker. This
  prevents prior-run entries (including pre-D000018 entries without source
  tags) from polluting the verdict on re-runs.

## Post-Ship E2E Filter Contract (T000027)

Step 4.user-story → Post-ship E2E filter is the v1 narrow-scope landing
of T000027 (pre-ship vs post-ship AC categorization). Contract:

- Trigger: row's Tag column contains the literal token `post-ship`
  (case-sensitive, word-boundary anchored). Combinable with other tag
  values (e.g., `core post-ship`, `post-ship usability`).
- Filter site: applied AFTER placeholder filtering and BEFORE Step 4.5's
  tool-need classifier. Post-ship rows never enter the subagent /
  parent-inline partition. The post-filter `E2E_ROWS` is what Step 4.5
  classifies.
- Audit entry: each post-ship row gets a `[qa-e2e-deferred]` journal
  entry naming the row + its AC + the reason ('post-ship — verification
  deferred to post-merge'). Entries are written BEFORE the Step 6.5
  run-start marker so Step 8's aggregator does NOT include them in
  `E2E_VERDICT` math.
- Verdict impact: post-ship rows do NOT contribute to `E2E_VERDICT`.
  They are tracked only via `[qa-e2e-deferred]` entries. Step 8's
  `[qa-e2e-summary]`'s `{N_DEFERRED}` count includes them alongside
  parent-inline-cap deferrals — the two shapes are unioned in the
  count because both represent E2E rows that exist but did not run
  pre-ship.
- Gate transition: if smoke is green AND the post-filter `E2E_ROWS` is
  empty (all E2E rows were post-ship), Phase 2 QA-owned gates transition
  on smoke-green alone — the `[qa-pass]` entry uses the "all post-ship"
  variant to make the partial verification state explicit. If the
  post-filter `E2E_ROWS` is non-empty, the normal subagent + parent-inline
  flow runs; the `[qa-pass]` shape depends on the verdict of the
  non-post-ship rows.
- Type scope: user-story only. Defect/task have no E2E phase in v1; the
  filter is a no-op for those types.
- Out of scope for v1 (deferred to follow-up): (c) dedicated Phase 3
  tracker gate `Post-ship ACs verified`; (d) `/CJ_personal-workflow check
  --update`'s post-merge inference to mark that gate from
  `[qa-e2e-deferred]` + post-`gh workflow run` journal entries. The TODO
  body (TODOS.md:108) explicitly recommends shipping (a)+(b) in v1 and
  deferring (c)+(d).

## Spec Deviations

The S000019 SPEC mentions a separate `## QA Run` section consolidating
findings (AC-13, observability). This v1 implementation uses
`## Journal` entries with `[qa-smoke]`, `[qa-e2e]`, `[qa-pass]`, and
sibling prefixes instead. Rationale: a separate section would generate
`[EXTRA]` advisory flags from `/CJ_personal-workflow check` Step 16 every
QA'd work item; the journal-with-prefix approach satisfies the
underlying motivation (grep-friendly output: `grep '\[qa-' TRACKER.md`)
without polluting the section structure. If grep-friendliness proves
insufficient in practice, a future iteration can lift QA findings into a
dedicated section by extending the `tracker-user-story.md` template.

The E2E execution surface uses a two-source model (Step 7 subagent + Step
7.5 parent-inline) introduced by D000018 to fix silent degradation to
structural inspection on skill-invoking / interactive / recursive rows.
The classifier in Step 4.5 partitions rows by tool-need; the aggregator in
Step 8 reunifies them. Prior to D000018, every E2E row went to the
subagent regardless of capability fit, which caused recurring
`ambiguous via structural inspection` outcomes across S000027, S000028,
S000022, S000020, and S000030.

D000018 also introduces a `[qa-e2e-run-start] RUN_ID=...` marker written
at Step 6.5 that scopes Step 8's verdict aggregation to entries from the
current run only. The marker is a journal entry like any other; pre-fix
trackers without the marker are still readable but the aggregator skips
them (no marker found → no entries to aggregate → vacuous verdict; re-run
QA writes a fresh marker and the aggregator picks up the new entries).
Row-number matching uses the regex `\[qa-e2e\] (E[0-9]+) \(` with the
trailing ` (` as anchor, preventing `E1` from absorbing `E10`'s entry on
TEST-SPECs with ≥10 E2E rows.
