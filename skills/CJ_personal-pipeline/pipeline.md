# /CJ_personal-pipeline — Orchestration

Single-keystroke orchestrator over `/CJ_scaffold-work-item` → `/CJ_implement-from-spec`
→ `/CJ_qa-work-item`. Each phase runs in a fresh-context Agent subagent with
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

## Auto Mode Overlay

The orchestrator runs in auto-decision mode unconditionally. This section
defines the 6 principles, the per-gate classification table, the two halt
categories, and the `$DECISION_LOG` schema that govern every run.

### The 6 principles

Direct port of `/autoplan`'s 6 principles with one substitution: P6 becomes
halt-on-doubt instead of bias-toward-action, reflecting the higher blast
radius of code-mutating pipeline vs plan-review.

1. **Choose completeness** — pick the option that covers more edge cases / acceptance criteria.
2. **Boil lakes (in-blast-radius)** — auto-approve in-radius expansions < 5 files, no new infra.
3. **Pragmatic** — between two approaches that fix the same thing, pick the cleaner one.
4. **DRY** — duplicates existing functionality? Pick reuse.
5. **Explicit over clever** — 10-line obvious > 200-line abstraction.
6. **Bias toward halt-on-doubt** *(REPLACED P6)* — when uncertain, halt and surface at final gate, do not auto-approve.

### Decision classification

- **Mechanical** — auto-decide silently, log to `$DECISION_LOG` with class `mechanical`, count only at Step 8.5.
- **Taste** — auto-decide with recommendation, log with class `taste`, surface at Step 8.5 with reasoning.
- **User Challenge — Approve-with-surfacing** — auto-pick "approve" forward (so the implement subagent can proceed), log with class `user_challenge_approved`, surface at Step 8.5 with full context. If user rejects at 8.5, `end_state=user_aborted`; user reverts manually (`git restore`).
- **User Challenge — Halt-at-Gate** — log with class `user_challenge_halt` for audit, then halt at the originating step. Step 8.5 never fires for these runs.

### Per-gate classification table

| Gate | Dominating principles | Auto-mode classification | Halts pipeline? |
|---|---|---|---|
| Step 2 branch (b) — footer present, path missing | P6 | User Challenge — Halt-at-Gate (recommend "Re-scaffold") | yes — never reaches 8.5 |
| Step 2 branch (c) — footer absent, path present | P6 | User Challenge — Halt-at-Gate (recommend "Halt for manual cleanup") | yes — never reaches 8.5 |
| Step 4 scaffold-shape (single-story, check green) | P5 + P3 | Mechanical (Approve, silent) | no |
| Step 4 scaffold-shape (feature with children) | (existing pipeline halts before AUQ at sub-step 3 with `end_state=green`) | n/a — multi-story branch already handles | yes |
| Step 5.2 sensitive-surface | P6 + safety contract | User Challenge — Approve-with-surfacing (auto-pick approve, log, surface at 8.5) | no |
| Step 5.2 taste-fork | P5 + P1 | Taste (auto-pick per P3, surface at 8.5) | no |
| Step 5.3 ESCALATION_NEEDED — first occurrence | (existing one-retry per Step 5.3 below fires first) | retry once silently | no (yet) |
| Step 5.3 ESCALATION_NEEDED — retry also failed | P6 | User Challenge — Halt-at-Gate (recommend abort) | yes — never reaches 8.5 |
| Step 6 post-implement validate.sh red | P6 | User Challenge — Halt-at-Gate (recommend abort) | yes — never reaches 8.5 |
| Step 8 post-QA red | P6 | User Challenge — Halt-at-Gate (recommend abort) | yes — never reaches 8.5 |
| Step 8.5 + 9.2 with `$SUPPRESS_FINAL_GATE` set | (wrapper-contract) | Suppressed — AUQ skipped; decisions still logged, telemetry still written; wrapper consumes via `$GSTACK_PIPELINE_DECISION_LOG_PATH` | no |
| Step 9 sunset checkpoint | (always-AUQ by design — when not suppressed) | Always interactive in standalone runs; suppressed in wrapper-invoked runs | no |

### Two halt categories — distinct logging contracts

1. **Halt-regardless** (do NOT log to `$DECISION_LOG`; not a "decision" the orchestrator made):
   - Boundary check red — `/CJ_personal-workflow check` at Steps 2(a)/4/6/8 red is a hard halt. Tracker journal + telemetry only; `end_state=halted_at_gate`.
   - Subagent crash — empty/no RESULT line. Tracker journal + telemetry only; `[subagent-crash]` entry; `end_state=subagent_crashed`.

2. **Halt-at-Gate User Challenge** (DO log to `$DECISION_LOG` with class `user_challenge_halt` for audit, then halt):
   - Step 2 b/c partial-write recovery
   - Step 5.3 ESCALATION_NEEDED retry-also-failed
   - Step 6 post-implement validate.sh red
   - Step 8 post-QA red

The distinction: halt-regardless is a structural/integrity failure (not a decision the orchestrator made). Halt-at-Gate is a decision (recommend abort) the user could override but won't, so the run halts. Logged so 8.5 reviewers of *prior* runs can audit what halted them.

### `$DECISION_LOG` schema

Single shared file (consistent with `~/.gstack/analytics/CJ_CJ_personal-pipeline.jsonl` telemetry):

```
~/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl
```

Path is computed once at Step 1 and stored as `$DECISION_LOG`; any later
Bash block re-derives it from the constant string (no shell-variable
persistence assumed across Bash calls — model carries the literal path).

One line per decision (jq-emitted, JSON-safe):

```json
{"run_id":"20260510-093015-12345","step":"5.2","gate_id":"sensitive-surface-catalog","classification":"user_challenge_approved","decision":"approve","recommendation":"approve","reasoning":"in-blast-radius catalog wiring; SPEC matches existing pattern","context_missing":"none flagged","files_affected":["skills-catalog.json","README.md"],"ts":"2026-05-10T09:32:11Z"}
```

Classification values: `mechanical`, `taste`, `user_challenge_approved`,
`user_challenge_halt`.

Append via jq for JSON-safe escaping:

```bash
jq -nc \
  --arg run_id "$RUN_ID" \
  --arg step "5.2" \
  --arg gate_id "sensitive-surface-catalog" \
  --arg classification "user_challenge_approved" \
  --arg decision "approve" \
  --arg recommendation "approve" \
  --arg reasoning "in-blast-radius catalog wiring" \
  --arg context_missing "none flagged" \
  --argjson files_affected '["skills-catalog.json","README.md"]' \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{run_id:$run_id,step:$step,gate_id:$gate_id,classification:$classification,decision:$decision,recommendation:$recommendation,reasoning:$reasoning,context_missing:$context_missing,files_affected:$files_affected,ts:$ts}' \
  >> "$DECISION_LOG"
```

---

## Step 1: Validate Input

Parse the user's argument:

```bash
# --auto and --manual are accepted and silently discarded for backwards
# compatibility with pre-v1.16.0 invocations. The orchestrator runs in
# auto-decision mode unconditionally; there is no manual code path.
# --suppress-final-gate is a wrapper-contract flag: when set, Step 8.5 and
# Step 9.2's AUQs are suppressed (decision log still written, telemetry still
# written). Used by /CJ_ship-feature and any future wrapper consuming this
# pipeline as a subagent. See "Suppression Contract" below.
SUPPRESS_FINAL_GATE=""
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --auto|--manual) ;;  # accept and discard for backwards compat
    --suppress-final-gate) SUPPRESS_FINAL_GATE=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
DESIGN_DOC="${ARGS[0]:-}"

[ -n "$DESIGN_DOC" ] || { echo "Error: design-doc path required"; exit 1; }
[ -f "$DESIGN_DOC" ] || { echo "Error: design doc not found at $DESIGN_DOC"; exit 1; }

# Must be under ~/.gstack/projects/ (the canonical /office-hours output location)
case "$DESIGN_DOC" in
  "$HOME/.gstack/projects/"*) ;;
  *) echo "Error: design doc must be under ~/.gstack/projects/ (got: $DESIGN_DOC)"; exit 1 ;;
esac

# Refuse on multiple positional args (one design doc per run)
[ "${#ARGS[@]}" -le 1 ] || { echo "Error: only one design-doc path accepted"; exit 1; }
```

Capture an absolute path: `DESIGN_DOC=$(realpath "$DESIGN_DOC")`.

Generate a run ID: `RUN_ID=$(date +%Y%m%d-%H%M%S)-$$`.

Initialize the decision log path. Default location is workbench-flat under
`~/.gstack/analytics/`; a wrapper invoking with `--suppress-final-gate` may
override via `GSTACK_PIPELINE_DECISION_LOG_PATH` to consume the log itself:

```bash
if [ -n "$GSTACK_PIPELINE_DECISION_LOG_PATH" ]; then
  DECISION_LOG="$GSTACK_PIPELINE_DECISION_LOG_PATH"
  mkdir -p "$(dirname "$DECISION_LOG")"
else
  DECISION_LOG="$HOME/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl"
  mkdir -p "$HOME/.gstack/analytics"
fi

# Soft-warning: --suppress-final-gate without a custom log path means
# suppressed-gate decisions will be co-mingled in the standalone log.
# Step 8.5's run_id filter still isolates the current run, so the run
# itself is unaffected — but future audit greps for the standalone log
# will see entries from wrapper-invoked runs interleaved. Wrappers should
# always pair the flag with GSTACK_PIPELINE_DECISION_LOG_PATH pointing
# at a per-run file (e.g. /tmp/cj-<wrapper>-$RUN_ID-decisions.jsonl).
if [ -n "$SUPPRESS_FINAL_GATE" ] && [ -z "$GSTACK_PIPELINE_DECISION_LOG_PATH" ]; then
  echo "warning: --suppress-final-gate set without GSTACK_PIPELINE_DECISION_LOG_PATH; suppressed-gate decisions will be co-mingled in the standalone log ($DECISION_LOG). Future audit greps will see them. Set GSTACK_PIPELINE_DECISION_LOG_PATH to redirect." >&2
fi
```

Decisions are appended (run_id-tagged); no per-run init / truncation. Step 8.5
filters by `run_id` to scope to this run.

## Step 2: Pre-Scaffold Idempotency Check

Read the source design doc. Search for footer line matching the regex:

```
^\*\*Status: SCAFFOLDED → `?(.+?)`?(?:\*\*)? on .*$
```

(`/CJ_scaffold-work-item` Step 12 writes this footer in the form
`**Status: SCAFFOLDED → \`<path>\` on YYYY-MM-DD-HH-MM-SS**`.)

Branch on the result:

### Branch (a): footer found, path exists, check green

If the captured `<path>` exists AND `/CJ_personal-workflow check "$path"`
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
- On Restore: print "Restore the dir at <path>, then re-run /CJ_personal-pipeline."; exit non-zero.
- On Abort: end_state = `user_aborted`; write telemetry; exit.

Classify as **User Challenge — Halt-at-Gate** (recommend Re-scaffold per P6). Log a `user_challenge_halt` line to `$DECISION_LOG` with `step:"2b"`, `gate_id:"partial-write-footer-no-path"`, `recommendation:"re-scaffold"`, then halt with `[gate-red]` and `end_state=halted_at_gate`. Partial-write recovery is never auto-decided — these states require manual cleanup.

### Branch (c): footer absent, but a tracker references the design doc

If no footer AND grep finds a tracker referencing this design doc:

```bash
# Run from repo root so the relative globs expand correctly even when the
# user invokes /CJ_personal-pipeline from a subdirectory.
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

- This branch is the orchestrator-level catch for the TODOS.md:26 idempotency hole in `/CJ_scaffold-work-item`. If we proceeded to Phase 1, scaffold would write a duplicate dir.

Classify as **User Challenge — Halt-at-Gate** (recommend "Halt for manual cleanup" per P6). Log a `user_challenge_halt` line to `$DECISION_LOG` with `step:"2c"`, `gate_id:"partial-write-no-footer"`, `recommendation:"halt-for-manual-cleanup"`, then halt with `[gate-red]` and `end_state=halted_at_gate`. Same rationale as branch (b): partial-write recovery requires manual cleanup.

### Branch (d): footer absent, no tracker references

Clean slate. Proceed to Step 3 (Phase 1 dispatch).

## Step 3: Phase 1 — Scaffold Subagent

Spawn an Agent subagent with `subagent_type: general-purpose` and a structured
prompt (stable preamble first, variable tail last for cache friendliness):

```
ROLE: scaffold runner.
TASK: invoke /CJ_scaffold-work-item with the design-doc path provided below.
RETURN CONTRACT: end your final assistant message with a line in this exact form:
  RESULT: WORK_ITEM_DIR=<absolute_path>
The line must be on its own. No prose after it.

If /CJ_scaffold-work-item asks for AUQs you cannot answer mechanically (slug,
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
2. **`/CJ_personal-workflow check "$WORK_ITEM_DIR"`** in Tier 1 Directory Mode. Refuse on red. (Defense-in-depth: scaffold's own Step 9 check should already have run, but the orchestrator does not trust upstream skill self-checks.)
3. **Multi-story feature halt.** If `$WORK_ITEM_DIR` is a feature with ≥1 user-story child dir:
   ```
   Halt (v1 scope): feature-shaped work-item with N children.
   Invoke /CJ_implement-from-spec + /CJ_qa-work-item per child manually:
     /CJ_implement-from-spec <child_1>
     /CJ_qa-work-item <child_1>
     /CJ_implement-from-spec <child_2>
     /CJ_qa-work-item <child_2>
     ...
   ```
   end_state = `green` (the orchestrator did its job up to scaffold; multi-story v2 is deferred).
4. **Confirm scaffold shape.** Show the scaffolded dir + artifact list. The AUQ prompt block (Approve / Reject (re-scaffold) / Abort) is preserved unconditionally for use only when the auto-classification rules below cannot resolve — but in v1 the rules cover every reachable case.

Auto-classification rules (always applied):
- If `/CJ_personal-workflow check` was green at sub-step 2 AND the work-item is single-story shape: classify as **Mechanical** (Approve). Log `mechanical` line to `$DECISION_LOG` with `step:"4"`, `gate_id:"scaffold-shape-confirm"`, `decision:"approve"`. Continue silently to Step 5.
- If multi-story feature: sub-step 3 already halts with `end_state=green` before reaching this gate — no action needed.
- Reject path is unreachable: boundary check at sub-step 2 would have already halted on drift, which is `halt-regardless`, not auto-decided.

On Approve (whether classified mechanical or human-resolved fallback): continue to Step 5.

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

### 5.2 Pre-collect AUQs (orchestrator → auto-classification)

The AUQ prompt blocks below are preserved unconditionally for use only when the auto-classification rules cannot resolve a fork — but in v1 the rules cover every reachable case. The orchestrator never actually surfaces these AUQs at Step 5.2; it auto-decides and continues, then surfaces the picks at Step 8.5.

For each sensitive-surface path, the preserved AUQ shape is:

> SPEC names sensitive surface(s):
>   <path>
> Sensitive surfaces affect catalog wiring, structural contracts, or validators.
>
> Options:
> - Approve and continue
> - Cancel — revise SPEC first
> - Cancel — handle by hand outside /CJ_personal-pipeline

For each taste fork, the preserved AUQ shape presents the row's alternatives.

Auto-classification rules (always applied):

For each sensitive-surface path: classify as **User Challenge — Approve-with-surfacing**. Auto-pick "approve" forward (so the implement subagent can proceed in 5.3); thread "approve" into `PRE_COLLECTED_AUQS`; log a `user_challenge_approved` line to `$DECISION_LOG` with `step:"5.2"`, `gate_id:"sensitive-surface-<surface-family>"` (catalog/manifest/validator/template/git-hook), `decision:"approve"`, `recommendation:"approve"`, `reasoning` summarizing the SPEC's Components Affected entry, `files_affected` array from the SPEC. Step 8.5 surfaces this for confirmation. v1 ships the simple rule (always approve, always surface); validate.sh-without-TODOS-entry carve-out is deferred (Open Q4 of source design).

For each taste fork: classify as **Taste**. Auto-pick per P3 (cleaner option from the row's Chosen column; fall back to first listed value if Chosen is `TBD`/`{...}`); thread the chosen answer into `PRE_COLLECTED_AUQS`; log a `taste` line to `$DECISION_LOG` with `step:"5.2"`, `gate_id:"taste-fork-<row-name>"`, `decision:"<chosen>"`, `reasoning` from the row's Why column. Surface at 8.5.

The orchestrator does NOT cancel on its own at Step 5.2 — it auto-decides and continues. The user reviews the decisions at Step 8.5 and may Abort there.

### 5.3 Dispatch implement subagent (with answers threaded)

Spawn an Agent subagent:

```
ROLE: implementation runner.
TASK: invoke /CJ_implement-from-spec with the work-item dir provided below in
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
- `STATUS=halted; ESCALATION_NEEDED=<reason>`: the orchestrator one-retry fires silently first (re-dispatch Phase 2 once with the escalation reason as context). If the retry succeeds → continue. If the retry also escalates → classify as **User Challenge — Halt-at-Gate** (recommend abort per P6). Log a `user_challenge_halt` line to `$DECISION_LOG` with `step:"5.3"`, `gate_id:"escalation-needed-retry-failed"`, `recommendation:"abort"`, `reasoning` from the escalation reason, then halt with `[gate-red]` and `end_state=halted_at_gate`. The orchestrator does NOT auto-decide a sensitive surface the pre-scan missed — bias toward halt-on-doubt.
- empty / no RESULT: halt with `[subagent-crash]`.

## Step 6: Post-Implement Gate

Orchestrator runs (NOT the subagent):

1. **`/CJ_personal-workflow check "$WORK_ITEM_DIR"`** — refuse on red.
2. **`scripts/validate.sh`** — capture stdout+stderr; on exit != 0, write the failure to the tracker journal as:
   ```
   [gate-red] post-implement validate.sh failed (exit $E):
   <first 20 lines of output>
   ```
   The preserved AUQ shape (kept for reference; never surfaced unconditionally — auto-classification handles it):

   > Post-implement gate red. validate.sh failed.
   >
   > Options:
   > - Abort (recommended — review the journal, fix manually)
   > - Re-dispatch Phase 2 with a "fix this" prompt prepended (one retry)
   > - Override and continue (NOT recommended; the catalog or template structure may be broken)

   Auto-classify as **User Challenge — Halt-at-Gate** (recommend abort per P6). Log a `user_challenge_halt` line to `$DECISION_LOG` with `step:"6"`, `gate_id:"post-implement-validate-red"`, `recommendation:"abort"`, `reasoning` summarizing the validate.sh first-20-lines failure, then halt with `[gate-red]` and `end_state=halted_at_gate`. The orchestrator does NOT auto-override a structural validation failure.

`scripts/test.sh` is intentionally NOT run in v1 (slow; revisit in v2).

## Step 7: Phase 3 — QA Subagent

Spawn an Agent subagent:

```
ROLE: QA runner.
TASK: invoke /CJ_qa-work-item with the work-item dir provided below.

RETURN CONTRACT: end your final assistant message with a line in this exact form:
  RESULT: SMOKE=<green|red>; E2E=<green|red|ambiguous>; PHASE2_GATES=<green|partial|red>
The line must be on its own. No prose after it.

WORK_ITEM_DIR: <absolute path>
```

`/CJ_qa-work-item` already dispatches its own QA-engineer subagent internally
(for E2E on user-stories) — that's a subagent inside our subagent. The 5-min
cap from `/CJ_qa-work-item`'s qa.md applies; the orchestrator gives the outer
subagent up to ~10 min wall-clock to complete (smoke + E2E together).

Parse with `parse_result`. Branch:

- `SMOKE=green; E2E=green; PHASE2_GATES=green`: continue to Step 8 (gate green path).
- Any red/ambiguous: classify as **User Challenge — Halt-at-Gate** (see Step 8 for the full classification + log line); halt with `[gate-red]` and `end_state=halted_at_gate`. Step 8.5 never fires for these runs.
- empty / no RESULT: halt with `[subagent-crash]`; halt-regardless category (do NOT log to `$DECISION_LOG`); `end_state=subagent_crashed`.

## Step 8: Post-QA Gate

Orchestrator parses tracker journal entries written by `/CJ_qa-work-item`:

```bash
SMOKE_LINE=$(grep '\[qa-smoke-summary\]' "$TRACKER" | tail -1)
QA_PASS_LINE=$(grep '\[qa-pass\]' "$TRACKER" | tail -1)
```

If both lines exist and indicate green: gate passes silently. Continue to Step 9.

If smoke summary is red OR no `[qa-pass]` entry exists today: gate red. The preserved AUQ shape (kept for reference; auto-classification handles it):

> Post-QA gate found:
>   <relevant findings from tracker>
>
> Options:
> - Abort (default — review tracker, fix, re-invoke)
> - Mark as known issue and proceed (writes [qa-known-issue] entry; gates do NOT transition; end_state = halted_at_gate)

Auto-classify as **User Challenge — Halt-at-Gate** (recommend abort per P6). Log a `user_challenge_halt` line to `$DECISION_LOG` with `step:"8"`, `gate_id:"post-qa-red"`, `recommendation:"abort"`, `reasoning` summarizing the relevant tracker findings, then halt with `[gate-red]` and `end_state=halted_at_gate`. The orchestrator does NOT auto-override QA red — surface QA failures for human judgment.

## Step 8.5: Final Approval Gate

Step 8.5 always fires subject to (a) the empty-state short-circuit at 8.5.2 (no Taste, no User-Challenge-Approved decisions → silent pass), (b) the two halt-categories carve-out (this step is unreachable when `end_state ∈ {halted_at_gate, subagent_crashed}` — earlier halt routing skips here entirely), and (c) the **suppression contract**: when `$SUPPRESS_FINAL_GATE` is set, 8.5 skips its AUQ entirely (wrapper consumes the decision log). The orchestrator has AUQ available (SKILL.md `allowed-tools` includes AskUserQuestion); this step runs at the orchestrator level, not in a subagent.

### 8.5.1 Filter `$DECISION_LOG` to this run

```bash
DECISIONS_THIS_RUN=$(jq -c "select(.run_id == \"$RUN_ID\")" "$DECISION_LOG" 2>/dev/null || true)
COUNT_MECHANICAL=$(echo "$DECISIONS_THIS_RUN" | jq -s 'map(select(.classification == "mechanical")) | length' 2>/dev/null || echo 0)
COUNT_TASTE=$(echo "$DECISIONS_THIS_RUN" | jq -s 'map(select(.classification == "taste")) | length' 2>/dev/null || echo 0)
COUNT_UC_APPROVED=$(echo "$DECISIONS_THIS_RUN" | jq -s 'map(select(.classification == "user_challenge_approved")) | length' 2>/dev/null || echo 0)
```

### 8.5.1b Suppression contract — wrapper-invoked path

If `$SUPPRESS_FINAL_GATE` is non-empty (set via the `--suppress-final-gate` flag at Step 1), the orchestrator-model takes the suppression path:

**Decide which tracker journal entry to write** based on counts:

- If `COUNT_TASTE == 0` AND `COUNT_UC_APPROVED == 0` (only Mechanical decisions, or zero total): write `[auto-pipeline-clean]` to the work-item tracker journal (matches 8.5.2's standalone semantics — downstream tooling that greps for this marker stays consistent).
- Otherwise: write `[auto-final-gate-suppressed] $COUNT_MECHANICAL mechanical, $COUNT_TASTE taste, $COUNT_UC_APPROVED user-challenge-approved; decisions at $DECISION_LOG` to the work-item tracker journal.

In both cases the journal-write path is the SAME tracker journal already written to elsewhere in pipeline.md (Step 2(a) re-use journal, Step 4 multi-story halt, Step 8.5.4 approval) — the orchestrator-model resolves the path from the work-item dir (`$WORK_ITEM_DIR/<TRACKER>.md` — the same shape used in Step 9.3's `Tracker:` summary line). No new variable.

**Then set END_STATE.** Set `END_STATE=green` and **carry this value forward** to Step 9.1's telemetry write — bash variables don't persist across orchestrator-model Bash calls, so the model must remember "I set END_STATE=green at 8.5.1b" as prose state, then thread that literal into Step 9.1's `jq --arg end_state` invocation. If unsure, re-derive from observable state: no halt journal entries earlier in this run → green.

**Then skip 8.5.2, 8.5.3, 8.5.4 entirely** and proceed directly to Step 9.

The wrapper that set the flag (e.g. `/CJ_ship-feature`) is consuming
`$DECISION_LOG` itself and will surface the relevant decisions (typically as
part of `/ship`'s diff review, since the decisions are visible in the diff).

### 8.5.2 Empty-state short-circuit

If `COUNT_TASTE == 0` AND `COUNT_UC_APPROVED == 0` (only Mechanical decisions accumulated): write `[auto-pipeline-clean]` to the work-item tracker journal and short-circuit to Step 9 without surfacing an AUQ. The auto run was genuinely uneventful; nothing for the user to confirm.

### 8.5.3 Render gstack-format AUQ

Otherwise, render the summary AUQ. Render Taste decisions inline; render User-Challenge-Approved with the full context block. Pros/Cons must be ≥40 chars per bullet. Net line closes the decision.

```
D-AUTO-FINAL — Confirm auto-mode decisions
Project/branch: <repo>/<$_BRANCH> | Run: $RUN_ID
ELI10: I made $((COUNT_TASTE + COUNT_UC_APPROVED)) close-call decisions while
running your pipeline. The $COUNT_MECHANICAL Mechanical ones were obvious and
silent. The $COUNT_TASTE Taste and $COUNT_UC_APPROVED User-Challenge-Approved
decisions below are the close calls I'd like you to confirm before you /ship.
Each User Challenge auto-picked "approve" and threaded that answer to the
implement subagent — files were already written. If any of these picks was
wrong, you Abort here and I print the exact file list for you to revert by
hand.
Stakes if we pick wrong: Approve = you live with the auto-picks (revert later
via /ship review or normal git workflow). Abort = you revert now and re-run
manually; ~3-5 min lost.

Recommendation: Approve (recommended) — all $COUNT_UC_APPROVED User Challenges
were auto-picked "approve" with reasoning; reversible by `git restore` on the
affected files if you disagree.
Note: options differ in kind, not coverage — no completeness score.

Decision summary:
- $COUNT_MECHANICAL mechanical (silent, logged; expand on request)
- $COUNT_TASTE taste:
    [for each row from $DECISIONS_THIS_RUN where classification=="taste":
     Gate <step.gate_id> | Pick: <decision> | Reasoning: <reasoning>]
- $COUNT_UC_APPROVED user_challenge_approved:
    [for each row from $DECISIONS_THIS_RUN where classification=="user_challenge_approved":
     Gate <step.gate_id>
     Pick: approve
     Files: <files_affected joined>
     What we approved: <one-liner from reasoning>
     Why approve looked right: <reasoning>
     Context we could be missing: <context_missing>
     If we're wrong, cost is: revert listed files via `git restore`]

Log: $DECISION_LOG (filter run_id=$RUN_ID)

A) Approve all auto-decisions (recommended)
  ✅ Pipeline ends green, ready for /ship review with full audit trail
  ✅ Every User Challenge has a logged file list — easy to spot-revert later
  ❌ You commit to $COUNT_UC_APPROVED sensitive-surface picks at once instead of one-by-one

B) Abort + show what to revert
  ✅ Prints per-decision files_affected list grouped by gate for easy revert
  ✅ Pipeline state preserved — no programmatic rollback gone wrong
  ❌ Manual revert + re-run loses ~3-5 minutes vs surgical "reject this one"

Net: Approve when you trust the reasoning summaries; Abort when any one User
Challenge surfaces a context the orchestrator clearly didn't have.
```

### 8.5.4 Branch on user response

- **On Approve:** write `[auto-final-gate-approved]` to the work-item tracker journal; set `$END_STATE=green`; continue to Step 9.
- **On Abort:** group `$DECISIONS_THIS_RUN` by `gate_id` and print files_affected per group:
  ```
  Files to revert (grouped by decision):
    Decision: sensitive-surface-catalog (Step 5.2)
      - skills-catalog.json
      - README.md
    Decision: taste-fork-<row-name> (Step 5.2)
      - <files>
    ...
  Run `git status` to see all modified files; `git restore <file>` per decision
  to revert. Pipeline state (work-item tracker) preserved.
  ```
  Set `$END_STATE=user_aborted`; write telemetry; exit. The orchestrator does NOT auto-revert — the user runs `git restore` themselves.

v1 deliberately drops "Reject specific decisions" — programmatic rollback across mid-pipeline subagent edits is fragile.

## Step 9: Final Summary + Telemetry Write + Sunset Check

### 9.1 Write telemetry

```bash
mkdir -p ~/.gstack/analytics
TELEMETRY=~/.gstack/analytics/CJ_CJ_personal-pipeline.jsonl
# Use jq for JSON-safe escaping. Paths with quotes / special chars / multibyte
# bust raw shell-interpolated JSON; jq -nc + --arg is the contract-preserving
# form. Falls back to a sanitized echo if jq is missing (shouldn't happen
# in this workbench — jq is a declared dependency).
if [ -n "$SUPPRESS_FINAL_GATE" ]; then _MODE="auto-suppressed"; else _MODE="auto"; fi
if command -v jq >/dev/null 2>&1; then
  jq -nc --arg run_id "$RUN_ID" --arg design_doc "$DESIGN_DOC" --arg end_state "$END_STATE" --arg mode "$_MODE" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{run_id:$run_id,design_doc:$design_doc,end_state:$end_state,mode:$mode,ts:$ts}' >> "$TELEMETRY"
else
  # Fallback: strip backslashes + double-quotes from the design-doc path.
  # Lossy but never produces invalid JSON.
  _SAFE_DOC=$(printf '%s' "$DESIGN_DOC" | tr -d '\\"')
  echo "{\"run_id\":\"$RUN_ID\",\"design_doc\":\"$_SAFE_DOC\",\"end_state\":\"$END_STATE\",\"mode\":\"$_MODE\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$TELEMETRY"
fi
```

`$END_STATE` is one of `green`, `halted_at_gate`, `user_aborted`,
`subagent_crashed`. Set throughout the orchestration; default `green` if all
phases passed and gate(s) didn't halt.

The `mode` field emits the literal `"auto"` (the orchestrator runs in
auto-decision mode unconditionally; field deletion deferred to v1.17.0 per
TODOS.md follow-up). Sunset trip-wire (Step 9.2) counts all runs pooled.

### 9.2 Sunset check (on 6th invocation)

When `$SUPPRESS_FINAL_GATE` is set, the wrapper owns sunset cadence — pipeline
still computes `INVOCATION_COUNT` (Step 9.1 wrote the telemetry line, so counts
stay accurate), but **the AUQ does not surface**. Telemetry write is unchanged
between standalone and wrapper-invoked runs.

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
fi
```

**STOP**: if `$SUPPRESS_FINAL_GATE` is non-empty, do NOT render the AskUserQuestion below. Proceed directly to Step 9.3. (The suppression directive is prose-only — bash variables don't persist across orchestrator-model Bash calls, so the model carries the suppression flag as prose state from Step 1.)

AskUserQuestion (only if `INVOCATION_COUNT >= 6` AND `$SUPPRESS_FINAL_GATE` is empty):

> /CJ_personal-pipeline sunset checkpoint (invocation $INVOCATION_COUNT). Prior 5 runs:
> <human-readable summary of $PRIOR_5>
>
> Trip-wire: $HALT_COUNT/5 ended in halted_at_gate. Recommendation: $SUNSET_REC.
>
> Options:
> - Keep (skill stays as-is; checkpoint will recur every 5 invocations)
> - Delete (recommended if $HALT_COUNT ≥ 3; otherwise honest opt-out)

On Delete: print instructions to delete the skill (`rm -rf skills/CJ_personal-pipeline/`,
strike the catalog entry, `skills-deploy install`). The orchestrator does
NOT auto-delete — destructive actions require explicit user execution.

### 9.3 Print summary

```
PIPELINE COMPLETE: end_state=$END_STATE  mode=$_MODE

Run ID:    $RUN_ID
Design:    $DESIGN_DOC
Work item: $WORK_ITEM_DIR
Files:     <FILES_CHANGED from Phase 2>
Smoke:     <SMOKE from Phase 3>
E2E:       <E2E from Phase 3>

Tracker:   $WORK_ITEM_DIR/$TRACKER_FILENAME
Telemetry: $TELEMETRY (line $INVOCATION_COUNT)
Decisions: $DECISION_LOG (filter run_id=$RUN_ID)

Next:
  /ship                                # if end_state=green and Phase 2 gates green
  /qa                                  # if work-item touched a web app — visual / E2E polish
```

---

## Error/Abort Contract

- **Idempotent.** Re-running on the same design doc resumes from the first incomplete phase via the Step 2 pre-scaffold check. Branch (a) on a fully-good prior run is a NO-OP path through Phase 1; Phase 2/3 will detect via Step 3 idempotency in their respective skills.
- **Halt-on-red, no rollback.** On any subagent crash or gate red without override: write `[gate-red]`/`[subagent-crash]` to tracker journal, append telemetry with appropriate end_state, exit non-zero.
- **Resume:** user re-invokes orchestrator OR invokes the next individual skill manually. The pre-scaffold check (Step 2) handles the resumption boundary.
- **Concurrent invocation:** documented as accepted risk in v1 (per F000014_DESIGN). Two parallel runs on different design docs may race on `work-items/` ID generation. If a real collision happens, file follow-up.
- **Cancel (Ctrl-C):** kills orchestrator; subagent state is whatever was last written to disk. Re-invoke to resume.

## Decision Gates (AskUserQuestion)

The orchestrator only surfaces AUQs at:
- **Step 8.5 — final approval gate** (skipped if empty-state — i.e. no Taste and no User-Challenge-Approved decisions logged this run; ALSO skipped when `$SUPPRESS_FINAL_GATE` is set — see Suppression Contract below)
- **Step 9 — sunset checkpoint on the 6th invocation, then every 5 thereafter** (always-AUQ in standalone runs; SUPPRESSED when `$SUPPRESS_FINAL_GATE` is set)

All other gates (Step 2 branch (b/c), Step 4 confirm scaffold shape, Step 5.2 sensitive-surface / taste-fork pre-collection, Step 5.3 ESCALATION_NEEDED, Step 6 post-implement red, Step 8 post-QA red) are auto-decided per the classification table in `## Auto Mode Overlay` and do NOT surface an AUQ at the originating step. Halt-at-Gate decisions halt the pipeline (write telemetry, exit) without surfacing anything; Mechanical decisions are silent; Taste and User-Challenge-Approved decisions accumulate in `$DECISION_LOG` and surface together at Step 8.5.

Subagents NEVER call AUQ (the tool is unreachable in their context per S000026
spike). Any decision a subagent might want to make is either pre-collected at
the orchestrator (Step 5.2) or escalated via `RESULT: ESCALATION_NEEDED=...`
(Step 5.3).

### Suppression Contract (wrapper-invoked path)

When `/CJ_personal-pipeline` is invoked with `--suppress-final-gate` (typically by a wrapper skill like `/CJ_ship-feature` that runs the pipeline as an Agent subagent and consumes the decision log itself):

- Step 8.5's AUQ is skipped. Tracker journal records `[auto-pipeline-clean]` (empty-state: zero Taste, zero User-Challenge-Approved — matches 8.5.2's standalone semantics) OR `[auto-final-gate-suppressed] N mechanical, M taste, K user-challenge-approved; decisions at $DECISION_LOG` (non-empty). `END_STATE=green` (provided no halt fired earlier).
- Step 9.2's sunset-checkpoint AUQ is skipped; telemetry write (Step 9.1) is unchanged so counts stay accurate; wrapper owns sunset cadence.
- Decision log path defaults to standalone unless the caller also sets `GSTACK_PIPELINE_DECISION_LOG_PATH` to override. The pair is the wrapper contract; using the flag without the env var emits a stderr warning at Step 1 and is supported but not recommended (would mingle suppressed decisions with standalone-run history).
- Rationale: subagents cannot reach AskUserQuestion (S000026 spike); a Step 8.5 or 9.2 AUQ from inside a wrapper-dispatched subagent would silently fail. The flag makes that unreachability explicit and lets the wrapper handle decision surfacing itself (typically via `/ship`'s diff review).

---

## Idempotency Contract (Premise 1.1)

This skill is idempotent at the orchestrator level. The 4 branches in Step 2
cover the recovery space:

1. **Branch (a)** — already scaffolded, re-runnable. Phase 1 is skipped; Phase 2/3 inherit their own skills' idempotency contracts.
2. **Branch (b)** — partial state (footer present but path gone). Auto-classified as User Challenge — Halt-at-Gate (recommend Re-scaffold per P6); orchestrator logs the decision, writes `[gate-red]`, and exits with `end_state=halted_at_gate`. Manual cleanup required.
3. **Branch (c)** — partial state (path present but footer gone). Auto-classified as User Challenge — Halt-at-Gate (recommend Halt-for-manual-cleanup per P6); same exit contract as branch (b).
4. **Branch (d)** — clean slate. Full pipeline runs.

No automatic rollback on subagent crash. Tracker journal records what was attempted; re-run resumes from first incomplete phase.

## Boundary Validation Contract (Premise 1.3)

`/CJ_personal-workflow check` runs at:

- **Step 2 branch (a)** — verifies the existing-and-reused dir is structurally clean.
- **Step 4** — post-scaffold (defense-in-depth; not trusting scaffold's self-check).
- **Step 6** — post-implement.
- **Step 8** — implicitly via parsing tracker journal (CJ_qa-work-item runs check internally).

All `MISSING`/`DRIFT` findings are blocking; `EXTRA`/`INFO` are advisory.

## Sensitive-Surface Pre-Scan Reference

The Step 5.1 regex matches these surface families:

| Surface | Path pattern | Why sensitive |
|---|---|---|
| Catalog | `skills-catalog.json` | Drives validation, deploy, and skill discovery; mistakes cascade |
| Manifests | `personal-artifact-manifests.json` / `company-artifact-manifests.json` | Source-of-truth for required artifacts; drives /CJ_personal-workflow check |
| Templates | `templates/CJ_personal-workflow/*` / `templates/CJ_company-workflow/*` | Source-of-truth for required sections + frontmatter |
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
