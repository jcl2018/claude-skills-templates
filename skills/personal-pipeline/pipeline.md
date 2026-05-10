# /personal-pipeline — Orchestration

Single-keystroke orchestrator over `/scaffold-work-item` → `/implement-from-spec`
→ `/qa-work-item`. Each phase runs in a fresh-context Agent subagent with
file-only handoff and independent inter-step quality gates. AUQs are
pre-collected at the orchestrator (subagents have no AskUserQuestion tool in
Claude Code 2.1.91 — see S000026 spike findings).

This file is the step-by-step logic invoked from [SKILL.md](SKILL.md). Read
SKILL.md first for path resolution, error handling, and usage; then follow the
steps below.

---

## Subagent Return Contract (universal)

Every subagent's final assistant message MUST contain a line of the form
`RESULT: <KEY>=<value>` (one or more KV pairs, semicolon-separated). The
orchestrator parses with **lenient matching** to tolerate the markdown wrapping
S000026 spike found subagents do 60% of trials:

```bash
# Lenient RESULT-line parser. Strips:
#   - leading whitespace
#   - markdown blockquote prefixes (`> `)
#   - markdown code fences (``` and ~~~)
# Then matches the LAST line containing RESULT: <KEY>=<value> in the output.
parse_result() {
  local output="$1"
  echo "$output" \
    | grep -E 'RESULT: [A-Z_]+=' \
    | tail -1 \
    | sed -E 's/^[[:space:]>]*//;s/```//g;s/~~~//g'
}
```

If `parse_result` returns empty, the subagent did not emit a RESULT line at
all → halt with `[subagent-crash]` journal entry, end_state = `subagent_crashed`.

Per-phase RESULT keys:

- Phase 1: `RESULT: WORK_ITEM_DIR=<absolute_path>`
- Phase 2: `RESULT: STATUS=<green|halted>; FILES_CHANGED=<n>` (optional: `; ESCALATION_NEEDED=<reason>` if pre-scan missed a fork)
- Phase 3: `RESULT: SMOKE=<green|red>; E2E=<green|red|ambiguous>; PHASE2_GATES=<green|partial|red>`

---

## Step 1: Validate Input

Parse the user's argument:

```bash
DESIGN_DOC="$1"
[ -n "$DESIGN_DOC" ] || { echo "Error: design-doc path required"; exit 1; }
[ -f "$DESIGN_DOC" ] || { echo "Error: design doc not found at $DESIGN_DOC"; exit 1; }

# Must be under ~/.gstack/projects/ (the canonical /office-hours output location)
case "$DESIGN_DOC" in
  "$HOME/.gstack/projects/"*) ;;
  *) echo "Error: design doc must be under ~/.gstack/projects/ (got: $DESIGN_DOC)"; exit 1 ;;
esac
```

Refuse on multiple positional args (one design doc per run).

Capture an absolute path: `DESIGN_DOC=$(realpath "$DESIGN_DOC")`.

Generate a run ID: `RUN_ID=$(date +%Y%m%d-%H%M%S)-$$`.

## Step 2: Pre-Scaffold Idempotency Check

Read the source design doc. Search for footer line matching the regex:

```
^\*\*Status: SCAFFOLDED → `?(.+?)`?(?:\*\*)? on .*$
```

(`/scaffold-work-item` Step 12 writes this footer in the form
`**Status: SCAFFOLDED → \`<path>\` on YYYY-MM-DD-HH-MM-SS**`.)

Branch on the result:

### Branch (a): footer found, path exists, check green

If the captured `<path>` exists AND `/personal-workflow check "$path"`
returns no `[MISSING]`/`[DRIFT]` findings:
- Set `WORK_ITEM_DIR="$path"`. Skip Phase 1. Continue to Step 4 (post-scaffold gate runs anyway as defense-in-depth) → **then continue to Step 5**.
- Journal entry to that work-item's tracker: `[orchestrator] pre-scaffold check: branch (a) — reusing existing work-item dir at $path; Phase 1 skipped.`

### Branch (b): footer found, path missing

If the captured `<path>` does NOT exist on disk:
- Halt. AskUserQuestion:

  > Halt: design doc claims `SCAFFOLDED → <path>` but the directory does not exist.
  >
  > Options:
  > - Re-scaffold (remove the footer; orchestrator re-runs Phase 1 cleanly)
  > - Restore the dir manually and re-run the orchestrator
  > - Abort

- On Re-scaffold: strip the footer line from the design doc; restart from Step 2.
- On Restore: print "Restore the dir at <path>, then re-run /personal-pipeline."; exit non-zero.
- On Abort: end_state = `user_aborted`; write telemetry; exit.

### Branch (c): footer absent, but a tracker references the design doc

If no footer AND grep finds a tracker referencing this design doc:

```bash
# Run from repo root so the relative globs expand correctly even when the
# user invokes /personal-pipeline from a subdirectory.
_REPO_ROOT=$(git rev-parse --show-toplevel) || exit 0
DUP=$(find "$_REPO_ROOT/work-items" -name "TRACKER.md" 2>/dev/null \
        | xargs grep -lE "$(printf '%s\n' "$DESIGN_DOC" | sed 's/[^a-zA-Z0-9_/-]/./g')" 2>/dev/null \
        | head -5)
```

(`find` recurses through any feature/child nesting depth; the cwd-independent
form prevents Branch (c) from misfiring when invoked from a subdir.)

If `DUP` is non-empty:
- Halt. AskUserQuestion:

  > Halt: scaffold appears to have crashed between its Step 9 boundary check and Step 12 footer-write. Partial dir(s) reference this design doc:
  >   <list of $DUP paths>
  >
  > Options:
  > - Delete partial dir(s) and re-run
  > - Hand-write the footer (`**Status: SCAFFOLDED → ...**`) pointing to one of them, then re-run
  > - Abort

- This branch is the orchestrator-level catch for the TODOS.md:26 idempotency hole in `/scaffold-work-item`. If we proceeded to Phase 1, scaffold would write a duplicate dir.

### Branch (d): footer absent, no tracker references

Clean slate. Proceed to Step 3 (Phase 1 dispatch).

## Step 3: Phase 1 — Scaffold Subagent

Spawn an Agent subagent with `subagent_type: general-purpose` and a structured
prompt (stable preamble first, variable tail last for cache friendliness):

```
ROLE: scaffold runner.
TASK: invoke /scaffold-work-item with the design-doc path provided below.
RETURN CONTRACT: end your final assistant message with a line in this exact form:
  RESULT: WORK_ITEM_DIR=<absolute_path>
The line must be on its own. No prose after it.

If /scaffold-work-item asks for AUQs you cannot answer mechanically (slug,
component selection, type when ambiguous), accept the recommended default for
mechanical AUQs (slug-from-title, component-from-existing, type-from-branch).
For sensitive-surface AUQs (catalog/manifest/validator changes), DO NOT
auto-accept — emit `RESULT: STATUS=halted; ESCALATION_NEEDED=<reason>` and
exit. The orchestrator will re-AUQ the human.

DESIGN_DOC: <DESIGN_DOC absolute path>
```

Capture stdout/stderr to `SCAFFOLD_OUTPUT`. Parse with `parse_result`. Branch:

- `WORK_ITEM_DIR=<path>`: set `WORK_ITEM_DIR="$path"`. Continue to Step 4.
- `STATUS=halted; ESCALATION_NEEDED=<reason>`: orchestrator AskUserQuestions the user with the reason; on user-resolves, re-dispatch Phase 1 with the answer threaded into the prompt tail.
- empty / no RESULT line: halt with `[subagent-crash]` journal entry; end_state = `subagent_crashed`.

## Step 4: Post-Scaffold Gate

The orchestrator runs these checks (NOT the subagent):

1. **Footer write-back confirm.** Re-read `$DESIGN_DOC`. Confirm the footer is now present and matches `WORK_ITEM_DIR`. If absent, halt with `[gate-red]` (partial-write halt — scaffold's Step 12 didn't run cleanly).
2. **`/personal-workflow check "$WORK_ITEM_DIR"`** in Tier 1 Directory Mode. Refuse on red. (Defense-in-depth: scaffold's own Step 9 check should already have run, but the orchestrator does not trust upstream skill self-checks.)
3. **Multi-story feature halt.** If `$WORK_ITEM_DIR` is a feature with ≥1 user-story child dir:
   ```
   Halt (v1 scope): feature-shaped work-item with N children.
   Invoke /implement-from-spec + /qa-work-item per child manually:
     /implement-from-spec <child_1>
     /qa-work-item <child_1>
     /implement-from-spec <child_2>
     /qa-work-item <child_2>
     ...
   ```
   end_state = `green` (the orchestrator did its job up to scaffold; multi-story v2 is deferred).
4. **AskUserQuestion: confirm shape.** Show the scaffolded dir + artifact list. Options: Approve / Reject (re-scaffold) / Abort.

On Approve: continue to Step 5.

## Step 5: Phase 2 — Implement Subagent (with PRE-COLLECTED AUQs)

This step has two sub-steps locked by the S000026 spike: orchestrator-side
SPEC pre-scan + human AUQ collection BEFORE subagent dispatch (subagents
have no AskUserQuestion tool to call).

### 5.1 SPEC pre-scan (orchestrator)

Locate the SPEC artifact:

```bash
# Parens are required: POSIX `find` -o has lower precedence than implicit -a,
# so without grouping the second predicate ignores -maxdepth and recurses
# into nested user-story dirs (picking up a child's SPEC.md by mistake).
SPEC=$(find "$WORK_ITEM_DIR" -maxdepth 1 \( -name "*_SPEC.md" -o -name "SPEC.md" \) 2>/dev/null | head -1)
```

If `SPEC` is empty (defect/task work-items have no SPEC), skip pre-scan; the
implement subagent's per-type read covers the equivalent (test-plan rows for
defect/task have no embedded sensitive-surface fork the way SPEC does).

Otherwise, scan the SPEC for two AUQ triggers:

**Sensitive-surface paths** (in `### Components Affected` table or `## Files`):

```bash
SENSITIVE_PATHS=$(grep -E '(skills-catalog\.json|personal-artifact-manifests\.json|company-artifact-manifests\.json|templates/(personal|company)-workflow/|scripts/(validate|test|test-deploy)\.sh|\.git/hooks/)' "$SPEC" || true)
```

**Taste-fork rows** in `## Tradeoffs` table where the `Chosen` column has
multiple plausible values OR is `TBD`/`{...}`/empty:

```bash
TASTE_FORKS=$(awk '/^## Tradeoffs/,/^## /' "$SPEC" \
  | grep -E '^\| ' \
  | awk -F'|' 'NR>2 && (/TBD|\{|^\| *\| */) {print}')
```

### 5.2 Pre-collect AUQs (orchestrator → human)

For each sensitive-surface path found, AskUserQuestion:

> SPEC names sensitive surface(s):
>   <path>
> Sensitive surfaces affect catalog wiring, structural contracts, or validators.
>
> Options:
> - Approve and continue
> - Cancel — revise SPEC first
> - Cancel — handle by hand outside /personal-pipeline

For each taste fork, AskUserQuestion presenting the row's alternatives.

Collect all answers into `PRE_COLLECTED_AUQS` (a structured map: path/decision → user-answer).

If user cancels any AUQ: end_state = `user_aborted`; write telemetry; exit.

### 5.3 Dispatch implement subagent (with answers threaded)

Spawn an Agent subagent:

```
ROLE: implementation runner.
TASK: invoke /implement-from-spec with the work-item dir provided below in
auto mode (do NOT call AskUserQuestion — your tool environment does not have
it; AUQs have been pre-collected for you and are threaded below).

PRE-COLLECTED AUQ ANSWERS:
  <each path/decision → answer line, one per line>

RETURN CONTRACT: end your final assistant message with a line in this exact form:
  RESULT: STATUS=<green|halted>; FILES_CHANGED=<n>
If you encounter a sensitive-surface or taste-fork that was NOT pre-answered
above, halt instead of guessing:
  RESULT: STATUS=halted; ESCALATION_NEEDED=<reason>
The line must be on its own. No prose after it.

WORK_ITEM_DIR: <absolute path>
```

Capture output, parse with `parse_result`, branch:

- `STATUS=green; FILES_CHANGED=<n>`: continue to Step 6.
- `STATUS=halted; ESCALATION_NEEDED=<reason>`: orchestrator AskUserQuestions the human; threads answer; re-dispatches Phase 2 once. If the second dispatch also escalates, halt with `[gate-red]`.
- empty / no RESULT: halt with `[subagent-crash]`.

## Step 6: Post-Implement Gate

Orchestrator runs (NOT the subagent):

1. **`/personal-workflow check "$WORK_ITEM_DIR"`** — refuse on red.
2. **`scripts/validate.sh`** — capture stdout+stderr; on exit != 0, write the failure to the tracker journal as:
   ```
   [gate-red] post-implement validate.sh failed (exit $E):
   <first 20 lines of output>
   ```
   AskUserQuestion:

   > Post-implement gate red. validate.sh failed.
   >
   > Options:
   > - Abort (recommended — review the journal, fix manually)
   > - Re-dispatch Phase 2 with a "fix this" prompt prepended (one retry)
   > - Override and continue (NOT recommended; the catalog or template structure may be broken)

   Default: abort.

`scripts/test.sh` is intentionally NOT run in v1 (slow; revisit in v2).

## Step 7: Phase 3 — QA Subagent

Spawn an Agent subagent:

```
ROLE: QA runner.
TASK: invoke /qa-work-item with the work-item dir provided below.

RETURN CONTRACT: end your final assistant message with a line in this exact form:
  RESULT: SMOKE=<green|red>; E2E=<green|red|ambiguous>; PHASE2_GATES=<green|partial|red>
The line must be on its own. No prose after it.

WORK_ITEM_DIR: <absolute path>
```

`/qa-work-item` already dispatches its own QA-engineer subagent internally
(for E2E on user-stories) — that's a subagent inside our subagent. The 5-min
cap from `/qa-work-item`'s qa.md applies; the orchestrator gives the outer
subagent up to ~10 min wall-clock to complete (smoke + E2E together).

Parse with `parse_result`. Branch:

- `SMOKE=green; E2E=green; PHASE2_GATES=green`: continue to Step 8 (gate green path).
- Any red/ambiguous: halt with detailed message; orchestrator AUQs the human with the specific findings.
- empty / no RESULT: halt with `[subagent-crash]`.

## Step 8: Post-QA Gate

Orchestrator parses tracker journal entries written by `/qa-work-item`:

```bash
SMOKE_LINE=$(grep '\[qa-smoke-summary\]' "$TRACKER" | tail -1)
QA_PASS_LINE=$(grep '\[qa-pass\]' "$TRACKER" | tail -1)
```

If both lines exist and indicate green: gate passes silently. Continue to Step 9.

If smoke summary is red OR no `[qa-pass]` entry exists today: gate red.
AskUserQuestion:

> Post-QA gate found:
>   <relevant findings from tracker>
>
> Options:
> - Abort (default — review tracker, fix, re-invoke)
> - Mark as known issue and proceed (writes [qa-known-issue] entry; gates do NOT transition; end_state = halted_at_gate)

Default: abort.

## Step 9: Final Summary + Telemetry Write + Sunset Check

### 9.1 Write telemetry

```bash
mkdir -p ~/.gstack/analytics
TELEMETRY=~/.gstack/analytics/personal-pipeline.jsonl
# Use jq for JSON-safe escaping. Paths with quotes / special chars / multibyte
# bust raw shell-interpolated JSON; jq -nc + --arg is the contract-preserving
# form. Falls back to a sanitized echo if jq is missing (shouldn't happen
# in this workbench — jq is a declared dependency).
if command -v jq >/dev/null 2>&1; then
  jq -nc --arg run_id "$RUN_ID" --arg design_doc "$DESIGN_DOC" --arg end_state "$END_STATE" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{run_id:$run_id,design_doc:$design_doc,end_state:$end_state,ts:$ts}' >> "$TELEMETRY"
else
  # Fallback: strip backslashes + double-quotes from the design-doc path.
  # Lossy but never produces invalid JSON.
  _SAFE_DOC=$(printf '%s' "$DESIGN_DOC" | tr -d '\\"')
  echo "{\"run_id\":\"$RUN_ID\",\"design_doc\":\"$_SAFE_DOC\",\"end_state\":\"$END_STATE\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$TELEMETRY"
fi
```

`$END_STATE` is one of `green`, `halted_at_gate`, `user_aborted`,
`subagent_crashed`. Set throughout the orchestration; default `green` if all
phases passed and gate(s) didn't halt.

### 9.2 Sunset check (on 6th invocation)

```bash
INVOCATION_COUNT=$(wc -l < "$TELEMETRY" | tr -d ' ')
# Fire on invocation 6, then every 5 thereafter (11, 16, 21, ...). Without the
# modulo gate, the AUQ surfaces on every run from 6+ — far too noisy.
if [ "$INVOCATION_COUNT" -ge 6 ] && [ $(( (INVOCATION_COUNT - 6) % 5 )) -eq 0 ]; then
  PRIOR_5=$(tail -6 "$TELEMETRY" | head -5)  # the 5 immediately before this run
  HALT_COUNT=$(echo "$PRIOR_5" | grep -c '"end_state":"halted_at_gate"')
  if [ "$HALT_COUNT" -ge 3 ]; then
    SUNSET_REC="DELETE"
  else
    SUNSET_REC="KEEP"
  fi
  # AskUserQuestion: show prior 5 runs + recommendation; user picks keep/delete
fi
```

AskUserQuestion (only if `INVOCATION_COUNT >= 6`):

> /personal-pipeline sunset checkpoint (invocation $INVOCATION_COUNT). Prior 5 runs:
> <human-readable summary of $PRIOR_5>
>
> Trip-wire: $HALT_COUNT/5 ended in halted_at_gate. Recommendation: $SUNSET_REC.
>
> Options:
> - Keep (skill stays as-is; checkpoint will recur every 5 invocations)
> - Delete (recommended if $HALT_COUNT ≥ 3; otherwise honest opt-out)

On Delete: print instructions to delete the skill (`rm -rf skills/personal-pipeline/`,
strike the catalog entry, `skills-deploy install`). The orchestrator does
NOT auto-delete — destructive actions require explicit user execution.

### 9.3 Print summary

```
PIPELINE COMPLETE: end_state=$END_STATE

Run ID:    $RUN_ID
Design:    $DESIGN_DOC
Work item: $WORK_ITEM_DIR
Files:     <FILES_CHANGED from Phase 2>
Smoke:     <SMOKE from Phase 3>
E2E:       <E2E from Phase 3>

Tracker:   $WORK_ITEM_DIR/$TRACKER_FILENAME
Telemetry: $TELEMETRY (line $INVOCATION_COUNT)

Next:
  /ship                                # if end_state=green and Phase 2 gates green
```

---

## Error/Abort Contract

- **Idempotent.** Re-running on the same design doc resumes from the first incomplete phase via the Step 2 pre-scaffold check. Branch (a) on a fully-good prior run is a NO-OP path through Phase 1; Phase 2/3 will detect via Step 3 idempotency in their respective skills.
- **Halt-on-red, no rollback.** On any subagent crash or gate red without override: write `[gate-red]`/`[subagent-crash]` to tracker journal, append telemetry with appropriate end_state, exit non-zero.
- **Resume:** user re-invokes orchestrator OR invokes the next individual skill manually. The pre-scaffold check (Step 2) handles the resumption boundary.
- **Concurrent invocation:** documented as accepted risk in v1 (per F000014_DESIGN). Two parallel runs on different design docs may race on `work-items/` ID generation. If a real collision happens, file follow-up.
- **Cancel (Ctrl-C):** kills orchestrator; subagent state is whatever was last written to disk. Re-invoke to resume.

## Decision Gates (AskUserQuestion)

The orchestrator AUQs at:
- Step 2 branch (b/c) — partial-write recovery
- Step 4 — confirm scaffold shape
- Step 5.2 — pre-collected AUQs (sensitive surface, taste forks) before Phase 2 dispatch
- Step 5.3 escalation — Phase 2 subagent flagged ESCALATION_NEEDED
- Step 6 — post-implement gate red
- Step 8 — post-QA gate red/ambiguous
- Step 9 — sunset checkpoint on 6th invocation

Subagents NEVER call AUQ (the tool is unreachable in their context per S000026
spike). Any decision a subagent might want to make is either pre-collected at
the orchestrator (Step 5.2) or escalated via `RESULT: ESCALATION_NEEDED=...`
(Step 5.3).

---

## Idempotency Contract (Premise 1.1)

This skill is idempotent at the orchestrator level. The 4 branches in Step 2
cover the recovery space:

1. **Branch (a)** — already scaffolded, re-runnable. Phase 1 is skipped; Phase 2/3 inherit their own skills' idempotency contracts.
2. **Branch (b)** — partial state (footer present but path gone). Halt with manual-cleanup AUQ.
3. **Branch (c)** — partial state (path present but footer gone). Halt with manual-cleanup AUQ.
4. **Branch (d)** — clean slate. Full pipeline runs.

No automatic rollback on subagent crash. Tracker journal records what was attempted; re-run resumes from first incomplete phase.

## Boundary Validation Contract (Premise 1.3)

`/personal-workflow check` runs at:

- **Step 2 branch (a)** — verifies the existing-and-reused dir is structurally clean.
- **Step 4** — post-scaffold (defense-in-depth; not trusting scaffold's self-check).
- **Step 6** — post-implement.
- **Step 8** — implicitly via parsing tracker journal (qa-work-item runs check internally).

All `MISSING`/`DRIFT` findings are blocking; `EXTRA`/`INFO` are advisory.

## Sensitive-Surface Pre-Scan Reference

The Step 5.1 regex matches these surface families:

| Surface | Path pattern | Why sensitive |
|---|---|---|
| Catalog | `skills-catalog.json` | Drives validation, deploy, and skill discovery; mistakes cascade |
| Manifests | `personal-artifact-manifests.json` / `company-artifact-manifests.json` | Source-of-truth for required artifacts; drives /personal-workflow check |
| Templates | `templates/personal-workflow/*` / `templates/company-workflow/*` | Source-of-truth for required sections + frontmatter |
| Validators | `scripts/validate.sh` / `scripts/test.sh` / `scripts/test-deploy.sh` | Gate-keeper logic; subtle changes here can mask drift |
| Git hooks | `.git/hooks/*` | Local enforcement layer; sandbox escape risk |

Extending the surface list: add a new alternation to the `grep -E` pattern in
Step 5.1, then add a row here for documentation. Keep this list narrow —
broadening it just adds AUQ noise.

## Token Budgets

Per F000014_DESIGN success criteria:
- Each subagent prompt under 500 tokens
- Each subagent return under 200 tokens
- Orchestrator's own context stays under ~5K tokens across all phases

Verify on first real run by inspecting the dispatched prompts (Agent tool
results contain the prompt as part of the call surface) and counting tokens
roughly (`wc -w` is a good enough approximation for budget checking).
