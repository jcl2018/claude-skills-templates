# /CJ_implement-from-spec — Implementation Orchestration

Implement a CJ_personal-workflow work-item per its input artifacts: read handoff
docs (per type), plan against the architecture, write code via Read/Edit/Write
tools, update the tracker journal, transition Phase 2 implementer-owned gates.

This file is the step-by-step logic invoked from [SKILL.md](SKILL.md). Read
SKILL.md first for path resolution, error handling, and usage; then follow
the steps below.

---

## Step 1: Validate Input + Type Dispatch

Parse the user's argument:

- The first positional argument is `<work-item-dir>` (any type accepted; type-dispatch resolves the path).
- If `--auto` appears in arguments, set `AUTO_MODE=true`. Default `false`.

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

**Type dispatch table** — per-type input artifacts the implementer reads:

| Type | Required input artifacts | Plan source |
|---|---|---|
| `user-story` | `*_SPEC.md` + `*_DESIGN.md` (this story's) | SPEC's Components Affected + Data Flow |
| `defect` | `*_RCA.md` + `*_test-plan.md` + `*_TRACKER.md` | RCA's Affected Components + Fix Description; test-plan rows define post-fix behavior |
| `task` | `*_TRACKER.md` + `*_test-plan.md` | Tracker's Acceptance Criteria + Todos; test-plan rows define expected behavior |
| `feature` | (delegates to a child user-story) | (see feature-dispatch below) |

**Feature dispatch:** if type is `feature`, list child user-story / defect / task
directories (subdirectories containing `*_TRACKER.md`), then AskUserQuestion:

> {feature_id} is a feature. Which child work-item should I implement?
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

Locate the per-type required input artifacts:

```bash
case "$TYPE" in
  user-story|userstory)
    SPEC=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "*_SPEC.md" -o -name "SPEC.md" 2>/dev/null | head -1)
    DESIGN=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "*_DESIGN.md" -o -name "DESIGN.md" 2>/dev/null | head -1)
    [ -z "$SPEC" ] && { echo "Error: SPEC.md not found in $WORK_ITEM_DIR (required for type user-story)"; exit 1; }
    [ -z "$DESIGN" ] && { echo "Error: DESIGN.md not found in $WORK_ITEM_DIR (required for type user-story)"; exit 1; }
    ;;
  defect)
    RCA=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "*_RCA.md" -o -name "RCA.md" 2>/dev/null | head -1)
    TEST_PLAN=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "*_test-plan.md" -o -name "test-plan.md" 2>/dev/null | head -1)
    [ -z "$RCA" ] && { echo "Error: RCA.md not found in $WORK_ITEM_DIR (required for type defect)"; exit 1; }
    [ -z "$TEST_PLAN" ] && { echo "Error: test-plan.md not found in $WORK_ITEM_DIR (required for type defect)"; exit 1; }
    ;;
  task)
    TEST_PLAN=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "*_test-plan.md" -o -name "test-plan.md" 2>/dev/null | head -1)
    [ -z "$TEST_PLAN" ] && { echo "Error: test-plan.md not found in $WORK_ITEM_DIR (required for type task)"; exit 1; }
    ;;
esac
```

For backwards compatibility with the v1.10.0 user-story-only path, this skill
historically used the variable name `USER_STORY_DIR`. Treat it as an alias for
`WORK_ITEM_DIR` in any code path that still references it.

Capture the work-item ID from the tracker filename (e.g., `S000018` from
`S000018_TRACKER.md`) → `WORK_ITEM_ID`.

## Step 2: Boundary Check at Start (Premise 1.3)

Run `/CJ_personal-workflow check` on the work-item directory. Implementation work
should only start on a fully-tracked work-item (Phase 1 green) with structural
compliance.

**Phase 1 gates are per-type** (from `tracker-{type}.md` template):

- `tracker-user-story.md`: `/office-hours design referenced`, `Working branch created`, `DESIGN + SPEC + TEST-SPEC scaffolded`, `Acceptance criteria defined`, `Tasks broken down`
- `tracker-defect.md`: read the template's `### Phase 1: Track` Gates block; common gates include `RCA + test-plan scaffolded`, `Working branch created`, `Reproduction confirmed`
- `tracker-task.md`: read the template's `### Phase 1: Track` Gates block; common gates include `test-plan scaffolded`, `Working branch created`, `Acceptance criteria defined`
- `tracker-feature.md`: not applicable (features delegate to a child via Step 1)

Read the TRACKER's `## Lifecycle` → `### Phase 1: Track` → `**Gates:**` block.
Match each `- [x]` / `- [ ]` line by gate label substring. If ANY Phase 1 gate
is unchecked:

```
Error: Phase 1 incomplete; resolve before implementing.
Unchecked Phase 1 gates:
  - {gate_label_1}
  - {gate_label_2}
```

Stop. The user must either run `/CJ_scaffold-work-item` (if structural drift) or
manually verify Phase 1 work before re-running.

Also run `/CJ_personal-workflow check "$WORK_ITEM_DIR"` (Tier 1 Directory Mode)
and capture the result. If the output contains `[MISSING]` or `[DRIFT]`
findings:

```
Error: work-item dir has structural issues; refusing to implement.
{summary of violations}
```

Stop. Resolve drift first.

## Step 3: Idempotency Check (Premise 1.1)

Implementation idempotency uses two signals: Phase 2 implementer-owned gates
checked AND a `[impl-pass]` journal entry exists.

Phase 2 implementer-owned gates (this skill's responsibility):

- `Todos section reflects remaining work`
- `Files section updated with changed files`

Phase 2 QA-owned gates (NOT this skill's responsibility — `/CJ_qa-work-item` marks them):

- `Acceptance criteria verified met`
- `Smoke tests pass`

If both implementer-owned gates are CHECKED AND the most recent journal entry
matching `[impl-pass]` is dated today (or matches the current `git rev-parse HEAD`):

```
INFO: {WORK_ITEM_ID} already implemented; nothing to do.
```

Exit 0 (NO-OP).

If the implementer-owned gates are checked but no `[impl-pass]` audit trail
exists, treat as **stale state** — re-run implementation to re-establish
ground truth. Cheaper to re-verify than to assume hand-edits are correct.

If only one implementer-owned gate is checked: treat as **partial-run
recovery** — re-run from Step 4. The implementation will overwrite or
complement existing work; the boundary check at end (Step 11) catches drift.

## Step 4: Read Context (per type)

Read input artifacts per the type dispatched in Step 1. The "primary" artifact
defines what to build; the rest provide context.

### Step 4.user-story (existing path)

1. **SPEC.md** — the implementation contract (primary). Extract:
   - `## Problem Statement` — the why.
   - `## Mental Model` — visual map of input → output.
   - `## Requirements` → `### P0 (Must-Have)` table — what MUST be implemented.
   - `## Acceptance Criteria` — Given/When/Then blocks per P0 story.
   - `## Architecture` — ASCII diagram + Components Affected table + Data Flow.
   - `## Tradeoffs` — decisions made during design (record as `[impl-decision]` carry-over).
   - `## Open Questions` — unresolved items; if any are blockers, AUQ to resolve.

2. **DESIGN.md (this user-story's)** — context stub; usually points at parent feature.

3. **DESIGN.md (parent feature's)** — read if the user-story DESIGN.md references it (typical for atomic stories scaffolded under a feature).

4. **TRACKER.md** — for journal context; if prior journal entries name decisions
   relevant to this implementation, surface them in your plan.

### Step 4.defect

1. **RCA.md** — the bug-shape contract (primary). Extract:
   - `## Symptom` — observed behavior.
   - `## Root Cause` — the WHY (one statement). This is what the fix must address.
   - `## Affected Components` — table mapping component → file/module → impact. Use this as the equivalent of SPEC's Components Affected for planning.
   - `## Fix Description` — human-readable approach. Implementation should match this approach.
   - `## Regression Risk` — areas that might break; informs sensitive-surface check + test coverage focus.

2. **test-plan.md** — defines post-fix behavior (acts as de-facto SPEC for defects). Extract:
   - `## Scope` — what the fix changes.
   - `## Regression Test Cases` table — rows describe correct post-fix behavior. Each row's Expected Result is what the implementation must produce.
   - `## Verification Steps` — checklist used during QA (forward to /CJ_qa-work-item).

3. **TRACKER.md** — Acceptance Criteria (defect-shape, "behavior X is restored") + journal context.

The **Fix Description** in RCA + the **Regression Test Cases** table in test-plan
together replace the user-story SPEC's Architecture + Acceptance Criteria. Plan
the implementation to make every test-plan row's Expected Result match.

### Step 4.task

1. **TRACKER.md** — Acceptance Criteria + Todos (primary "what to build").
2. **test-plan.md** — Regression Test Cases define expected behavior (acts as the
   AC verification rubric for tasks).

Tasks are smaller-scope than user-stories; the TRACKER's Acceptance Criteria
section IS the spec. No separate SPEC/DESIGN docs.

### Step 4.feature

(Unreachable — feature dispatch in Step 1 delegates to a child user-story / defect / task.)

If any required input artifact's frontmatter is missing required fields, or the
body lacks required sections per the matching template, surface an Input Gap
(Step 5).

## Step 5: Input Artifact Gap Check (per type) (P1 AC-11)

Scan the per-type primary input artifact(s) for gaps that would compromise
implementation. Apply the appropriate sub-check per type:

### Step 5.user-story
1. **Unresolved placeholders** in SPEC.md body: any `{[A-Z_]+}` or `{lowercase_with_underscores}` patterns — e.g., `{ITEM_NAME}`, `{component}`, `{TBD}`. These mean `/CJ_scaffold-work-item` left placeholders the author didn't fill in.
2. **Missing required sections:** doc-SPEC template requires Problem Statement, Mental Model, Requirements, Acceptance Criteria, Architecture, Tradeoffs, Open Questions. If any is missing, that's a structural gap.
3. **Empty P0 requirements:** the `### P0 (Must-Have)` table has no rows beyond the header. Implementation has nothing to implement.

### Step 5.defect
1. **Unresolved placeholders** in RCA.md or test-plan.md (same `{...}` regex).
2. **RCA missing required sections:** Symptom, Reproduction Steps, Investigation Trail, Root Cause, Affected Components, Fix Description, Regression Risk.
3. **test-plan missing required sections:** Scope, Regression Test Cases, Verification Steps, Environments Tested.
4. **Empty Regression Test Cases:** test-plan's table has no rows beyond the header. Defect implementation has no behavior contract.
5. **Root Cause unfilled:** the `**Root cause:** {statement}` line still has `{statement}` literal — the RCA wasn't completed.

### Step 5.task
1. **Unresolved placeholders** in TRACKER.md Acceptance Criteria / Todos sections, or in test-plan.md.
2. **Empty Acceptance Criteria** in TRACKER (no `- [ ]` rows beyond placeholder).
3. **test-plan missing required sections** (same as defect).

If gaps are found, format the message per type:

```
{Type} input gap detected in {primary artifact path}:
  - {gap 1}
  - {gap 2}

Fill these before implementing. Stopping.
```

Stop. Do not proceed to planning. The user must edit the artifact and re-run.

If no gaps: continue to Step 6.

## Step 6: Plan Implementation (per type)

Build the implementation plan from the type-appropriate plan source (per the
Step 1 type dispatch table).

### 6.1 Components Affected (per type)

**For user-stories:** parse SPEC's `### Components Affected` table. Columns: Component, Repo, Change Type (New / Modified / Removed), Description. For each row, identify the file path / directory, note change type, note path-shape constraints from the SPEC.

**For defects:** parse RCA's `## Affected Components` table. Columns: Component, File/Module, Impact. Each affected component is a candidate Change Type=Modified target; the RCA's `## Fix Description` text states what each change does. Cross-reference test-plan's `## Scope` to confirm the affected file set.

**For tasks:** parse TRACKER's `## Files` section (if pre-populated by the task author) and `## Todos` section. Each todo names a concrete change; the file targets come from the Files section or are inferred from todo prose. test-plan's `## Scope` may also list affected files.

### 6.2 Data Flow / Sequence (per type)

**For user-stories:** parse SPEC's `### Data Flow` numbered list. This is the ordered sequence of operations the implementation should perform. Map each step to specific code operations (function additions, edits, removals).

**For defects:** the RCA's `## Fix Description` paragraph names the approach. Convert into 2-5 ordered code operations needed to achieve it. test-plan's Regression Test Cases describe what the post-fix behavior must look like; use them as verification rubric, not as a sequence specification.

**For tasks:** TRACKER's `## Todos` section IS the ordered sequence (each `- [ ]` is one step). Implementation closes them in order.

### 6.3 Tradeoffs

**For user-stories:** parse SPEC's `## Tradeoffs` table. The **Chosen** column is the authoritative choice. Carry the decision into the implementation; record it later as a `[impl-decision]` journal entry citing the SPEC tradeoff source.

**For defects:** RCA has no Tradeoffs section by template. If the implementer faces a choice not addressed by RCA + test-plan (e.g., two equivalent ways to fix the bug), pick the simpler one and record as `[impl-decision]` with rationale; surface the choice in the propose-and-confirm preview.

**For tasks:** same as defects — no template Tradeoffs section. Implementer judgment + journal entry.

### 6.4 Detect Sensitive Surface

Scan the Components Affected table (or the per-type equivalent — RCA's Affected
Components table for defects, TRACKER's Files section for tasks) for these
path patterns. If ANY entry matches:

- `skills-catalog.json` (any depth)
- `personal-artifact-manifests.json` or `company-artifact-manifests.json`
- `templates/CJ_personal-workflow/*` or `templates/CJ_company-workflow/*` (template files are part of structural contracts)
- `scripts/validate.sh` or `scripts/test.sh` or `scripts/test-deploy.sh` (validators)
- `.git/hooks/*` (git hook surface)

Set `SENSITIVE=true`. Otherwise `SENSITIVE=false`. Sensitive-surface changes
trigger a mandatory AUQ in Step 7 regardless of `--auto`.

### 6.5 Detect Triviality

Compute `FILES_TOUCHED` from the per-type Components Affected source (count
rows, but exclude TRACKER.md — every implementation modifies the tracker).

A change is **trivial** if ALL of these hold:
- `FILES_TOUCHED ≤ 2`
- `SENSITIVE = false`
- The input artifact has no unresolved Open Questions / pending decisions (Step 4 confirmed this)
- No tradeoff with multiple "live" alternatives (the Chosen column always
  picked one — for defect/task with no Tradeoffs section, this clause is vacuously true)

Set `TRIVIAL=true` accordingly.

### 6.6 Mode Resolution

Resolve the operating mode:

- If `--auto` was passed AND `TRIVIAL=true` AND `SENSITIVE=false`: `MODE=auto`
- Otherwise: `MODE=propose`

`--auto` is overridden by the safety check: a user passing `--auto` on a
sensitive-surface or non-trivial SPEC silently falls back to `MODE=propose`.
The override is logged in the tracker journal (`[impl-finding] --auto demoted to propose:
sensitive-surface change` or similar).

## Step 7: Sensitive Surface AUQ (P0 AC-8)

If `SENSITIVE=true`:

AskUserQuestion (always — even in `--auto`):

> {WORK_ITEM_ID}'s SPEC modifies sensitive surface(s):
>   {list each matching path}
>
> Sensitive surfaces affect catalog wiring, structural contracts, or validators.
> Mistakes here cascade to every other skill / work item.
>
> Options:
> - Approve and continue (recommended once you've reviewed the SPEC)
> - Cancel — I want to revise the SPEC first
> - Cancel — I'll do this by hand outside /CJ_implement-from-spec

If approved: continue to Step 8 (or Step 9 if `MODE=auto`).

If cancelled: print "Aborted: sensitive surface change declined." and stop.

If `SENSITIVE=false`: skip Step 7 silently.

## Step 8: Propose-and-Confirm Preview (P0 AC-9; skipped if MODE=auto)

If `MODE=auto`: skip to Step 9.

Otherwise, write a preview of the proposed changes to chat. Format:

```
PROPOSED IMPLEMENTATION: {WORK_ITEM_ID}

Summary:
  {1-2 sentence summary of what the implementation does}

Files to change ({N}):
  [NEW]      {path 1}    {one-line description}
  [MODIFIED] {path 2}    {one-line description, what changes}
  [REMOVED]  {path 3}    {one-line description}

Per-file diff highlights:
  {path 1}:
    + {brief outline of what gets added — function names, key constants, etc.}
  {path 2}:
    ~ {brief outline of what changes}

Tracker updates:
  - Journal: {N} new entries ([impl-decision], [impl], etc.)
  - Phase 2 gates: 'Todos section reflects remaining work', 'Files section updated' will transition on green
```

Then AskUserQuestion:

> Apply this implementation?
>
> Options:
> - Apply (recommended if the plan matches what you expect)
> - Modify — let me adjust the plan first (I'll output revisions to the SPEC, you re-run after editing)
> - Cancel

If Apply: continue to Step 9.

If Modify: print specific points the user might want to revise (e.g., "the SPEC says
'Various source files' — consider naming them explicitly in Components Affected").
Stop. The user edits the SPEC and re-runs.

If Cancel: print "Aborted: user cancelled at preview." and stop.

## Step 9: Write Code

Execute the planned changes via Read / Edit / Write tools.

For each row in Components Affected:

1. **NEW file:** use `Write` tool with the full file content.
2. **MODIFIED file:** use `Read` to load current content, plan the edit, then
   use `Edit` (preferred — partial change) or `Write` (full rewrite if substantial
   restructuring). Prefer `Edit` for surgical changes.
3. **REMOVED file:** use `Bash` with `git rm <path>` — never `rm` directly. Stage
   the deletion through git so it's part of the commit.

For each Edit, follow the SPEC's stated approach:
- If SPEC has Tradeoffs naming a Chosen approach, implement that approach.
- If SPEC has Open Questions noted as resolved during this run (via Step 5),
  cite them in the journal.
- If SPEC has tests or `## Acceptance Criteria` blocks, the implementation must
  match the Given/When/Then contract. (The actual verification is `/CJ_qa-work-item`'s
  job, not this skill's.)

**Code style:** mirror existing repo conventions. Read 2-3 adjacent files in the
target dir first to learn naming, formatting, and idiom patterns before writing
new code. The user's saved feedback often expresses style preferences; honor
them when CLAUDE.md or recent commits document them.

**Atomicity within Step 9:** write all files in this step before mutating the
tracker (Step 10). If a write fails partway through, the tracker still reflects
"not yet implemented" — the next run resumes safely (partial-run recovery, Step 3).

**Post-write executable-bit fix (T000022 / TODOS:97 / D000017 follow-up).**
After writing all files in this step, ensure newly-written shell scripts have
the executable bit set. The `Write` tool lands files at mode 644 by default —
without this fix, `.sh` files ship non-executable and downstream consumers
(skills-deploy install smoke checks, test-plan rows asserting "executable bit
set", `/ship` Step 9 pre-landing review) flag the discrepancy. On D000017
(PR #84) the implement subagent shipped `skills/CJ_suggest/scripts/suggest.sh`
at mode 644; `/ship` Step 9 caught it as a `[LOW] AUTO-FIX` and `chmod +x`d
the file pre-commit. The implement subagent should have done that itself —
that is what this step fixes.

For each file written or modified in this step, apply `chmod +x` if the path
matches the shell-script heuristic:

- `*.sh` (POSIX shell scripts)
- `*.bash` (bash scripts)
- No-extension files whose first line begins with the `#!` shebang marker
  (e.g. `#!/usr/bin/env bash`, `#!/bin/sh`, `#!/usr/bin/env python3` — any
  shebang script regardless of interpreter)

Reference snippet (run once after the Step 9 write loop completes; the
orchestrator-model substitutes the actual written-file list for `$WRITTEN_FILES`):

```bash
for _f in $WRITTEN_FILES; do
  case "$_f" in
    *.sh|*.bash)
      chmod +x "$_f"
      ;;
    *)
      # No-extension file with a shebang first line: still executable code.
      if [ -f "$_f" ] && [ -z "${_f##*.*}" = "" ] && head -c2 "$_f" 2>/dev/null | grep -q '^#!'; then
        chmod +x "$_f"
      elif [ -f "$_f" ] && ! printf '%s' "$_f" | grep -q '\.'; then
        # Extension-less file: check shebang heuristic
        if head -c2 "$_f" 2>/dev/null | grep -q '^#!'; then
          chmod +x "$_f"
        fi
      fi
      ;;
  esac
done
```

Edits that touch existing executable files preserve the bit (Edit doesn't
reset mode); the heuristic targets the NEW-file write path where mode 644
is the default. Pre-existing non-executable shell scripts under the modified
set will gain the bit as a beneficial side-effect — acceptable per D000017
rationale (a `.sh` file that is not executable is almost certainly a bug).

Belt-and-suspenders verification at Step 11 boundary block is advisory in v1
(any miss would surface at `/ship` Step 9 pre-landing review, which is the
current safety net) — record-keeping only; no enforcement.

## Step 10: Update Tracker

Append journal entries to the TRACKER's `## Journal` section. Use these prefixes:

| Prefix | When to use |
|---|---|
| `[impl-decision]` | A design choice made during implementation (carrying SPEC tradeoffs forward, picking between two equivalent code patterns, etc.) |
| `[impl-finding]` | A non-obvious thing discovered while implementing (existing code already covers something, missing dependency, surprising edge case) |
| `[impl]` | The implementation step itself: "Wrote N files, edited M files, etc." |
| `[impl-auto]` | If `MODE=auto`: include alongside `[impl]` to mark the auto-mode run |
| `[impl-pass]` | Final success marker. Used by Step 3's idempotency check on subsequent runs. Format: `[impl-pass] {WORK_ITEM_ID}: implementation complete. Phase 2 implementer-owned gates transitioned.` |

Add at least one `[impl]` entry summarizing the run. Examples:

```
- {YYYY-MM-DD} [impl-decision] Chose Edit over Write for skills-catalog.json — preserves jq formatting; rejected the Write-the-whole-file approach because catalog has 5+ unrelated entries
- {YYYY-MM-DD} [impl-finding] SPEC's Components Affected listed "Various source files (per user-story)"; treated as the user-story-specific paths in Step 6.1, not as a wildcard scope
- {YYYY-MM-DD} [impl] Wrote 3 files (SKILL.md, implement.md, fixtures/README.md); modified 1 (skills-catalog.json). 4 journal entries added.
- {YYYY-MM-DD} [impl-auto] Auto-mode run; --auto allowed (1 file touched, no sensitive surface)
- {YYYY-MM-DD} [impl-pass] {WORK_ITEM_ID}: implementation complete. Phase 2 implementer-owned gates transitioned.
```

Update the TRACKER's `## Files` section to list every changed file. Use the
existing format (one bullet per file, with NEW / modified / removed annotation
matching the SPEC's Components Affected table).

Update the TRACKER's `## Todos` section to reflect remaining work — typically:
- Mark off items the implementation closes (`- [x]`).
- Add follow-ups discovered during implementation (`- [ ] (Deferred) X`).

Edit the TRACKER's `## Lifecycle` → `### Phase 2: Implement` → `**Gates:**` block
per the work-item type:

**For user-stories** — find these lines and change `[ ]` to `[x]`:

```
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files
```

Do NOT touch the QA-owned gates (`Acceptance criteria verified met`, `Smoke tests pass`) — those are owned by `/CJ_qa-work-item` and will be marked when QA passes.

**For defects** — find these lines and change `[ ]` to `[x]`:

```
- [ ] RCA doc updated
- [ ] Todos section reflects remaining work (no stale items)
```

Do NOT touch `Fix committed` — that is a user-owned commit gate (the user or `/ship` marks it after the actual git commit). Defect Phase 2 has no qa-owned gates per template; defect verification happens at Phase 3's `Test-plan verified` gate.

**For tasks** — find these lines and change `[ ]` to `[x]`:

```
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files
```

Do NOT touch `Core changes committed (>=1 commit SHA in Log)` — that is a user-owned commit gate. Task Phase 2 has no qa-owned gates per template.

**For features** — not applicable (Step 1 dispatch delegates features to a child work-item).

If the work-item's type does not match any of the above (defensive guard against future type additions), surface a journal entry:

```
- {YYYY-MM-DD} [impl-finding] type "{type}" has no per-type Phase 2 gate transition rule defined; gates left as-is. Extend implement.md Step 10 if this type should auto-mark gates.
```

## Step 11: Boundary Check at End (Premise 1.3)

Run `/CJ_personal-workflow check "$WORK_ITEM_DIR"` (Tier 1 Directory Mode).

**If the result contains no `[MISSING]` or `[DRIFT]` findings:** continue to
Step 12.

**If the result contains violations** (the implementation broke compliance):

AskUserQuestion:

> /CJ_personal-workflow check failed after implementation:
>   {summary of violations}
>
> Options:
> - Surface and exit (recommended — manual repair is safer)
> - Show full check output and continue (the violations may be advisory or pre-existing)
> - Abort

Default: surface and exit.

`[EXTRA]` advisory flags do not count as violations; only `MISSING` and `DRIFT`.

## Step 12: Print Summary and Exit

Print a tight summary in the chat:

```
IMPLEMENT COMPLETE: {WORK_ITEM_ID}

Mode:     {auto | propose}
Files:    {N} written, {M} modified, {K} removed
Tracker:  {J} journal entries, Phase 2 implementer-owned gates → green
Sensitive: {none | listed paths confirmed}

Tracker:  {TRACKER}
Next:
  /CJ_qa-work-item {WORK_ITEM_DIR}        # verify implementation; transitions Phase 2 (user-story) or records [qa-pass] (defect/task)
```

Last line in the chat is the next-skill invocation, formatted for copy-paste.

---

## Error Handling

See [SKILL.md](SKILL.md)'s Error Handling table. All errors are non-recoverable
(skill exits cleanly); the user re-runs after fixing the underlying issue.

## Idempotency Contract (Premise 1.1)

This skill is idempotent. Three behaviors:

1. **Already implemented** (Step 3): both implementer-owned gates checked AND a
   `[impl-pass]` journal entry exists today/at-current-commit. NO-OP, exit clean.
2. **Stale gate state** (Step 3): gates checked but no `[impl-pass]` audit trail.
   Re-run implementation to re-establish ground truth.
3. **Partial-run recovery** (Step 3): one implementer-owned gate checked, other
   unchecked. Re-run from Step 4; gate transitions in Step 10 will reset to
   consistent state.

No automatic rollback on partial implementation failure. Tracker journal
records what was attempted; re-run is safe and resumes from the first
incomplete file write.

## Boundary Validation Contract (Premise 1.3)

`/CJ_personal-workflow check` runs at:

- **Step 2 (start):** on `WORK_ITEM_DIR` — gates input drift, refuses on
  Phase 1 gate gaps or structural drift.
- **Step 11 (end):** on `WORK_ITEM_DIR` after writes — catches self-inflicted
  compliance breaks.

Both invocations use Tier 1 Directory Mode. Blocking violations are `MISSING`
and `DRIFT`; `EXTRA` and `INFO` are advisory.

## Phase 2 Gate Ownership (per type)

Phase 2 gate ownership differs per work-item type. Each tracker template
defines its own Phase 2 gates; this skill marks the implementer-owned subset,
`/CJ_qa-work-item` marks the qa-owned subset (where present), and commit-driven
gates remain user/`ship`-owned.

### user-story (`tracker-user-story.md`)

| Gate | Owner | Boundary check role |
|---|---|---|
| `Acceptance criteria verified met` | /CJ_qa-work-item (qa.md Step 9) | Untouched by /CJ_implement-from-spec |
| `Smoke tests pass` | /CJ_qa-work-item (qa.md Step 9) | Untouched by /CJ_implement-from-spec |
| `Todos section reflects remaining work` | /CJ_implement-from-spec (Step 10) | Marked CHECKED on green |
| `Files section updated with changed files` | /CJ_implement-from-spec (Step 10) | Marked CHECKED on green |

### defect (`tracker-defect.md`)

| Gate | Owner | Boundary check role |
|---|---|---|
| `Fix committed` | user / `/ship` (commit gate) | Untouched by /CJ_implement-from-spec; marked when actual git commit lands |
| `RCA doc updated` | /CJ_implement-from-spec (Step 10) | Marked CHECKED on green |
| `Todos section reflects remaining work` | /CJ_implement-from-spec (Step 10) | Marked CHECKED on green |

Defect Phase 2 has no qa-owned gates per template. Verification lands at the
Phase 3 `Test-plan verified` gate (driven by `/ship`-time CI verification or
`/CJ_personal-workflow check --update`'s post-merge inference).

### task (`tracker-task.md`)

| Gate | Owner | Boundary check role |
|---|---|---|
| `Core changes committed (>=1 commit SHA in Log)` | user / `/ship` (commit gate) | Untouched by /CJ_implement-from-spec |
| `Todos section reflects remaining work` | /CJ_implement-from-spec (Step 10) | Marked CHECKED on green |
| `Files section updated with changed files` | /CJ_implement-from-spec (Step 10) | Marked CHECKED on green |

Task Phase 2 has no qa-owned gates per template. Same Phase 3 verification
shape as defects.

### feature (`tracker-feature.md`)

Not applicable — features delegate to a child user-story / defect / task via
the Step 1 type dispatch. The chosen child's per-type rules apply.

The /CJ_implement-from-spec skill makes the work-item Phase-2-ready by completing
its work and marking its tracker-content gates per the type's template.
`/CJ_qa-work-item` then verifies the implementation (and marks the qa-owned gates
for user-stories, or records `[qa-pass]` for defect/task). Together they
transition the work-item from Phase 1 → Phase 2 → Phase 3 ready.

## Mode and Safety Override

`--auto` is honored only when the change is trivial AND non-sensitive. The
check is conservative:

- Trivial means ≤ 2 files touched, no sensitive surface, no SPEC tradeoff
  with active alternatives.
- The skill silently demotes `--auto` to `MODE=propose` if any criterion
  fails. The demotion is logged as `[impl-finding]` in the journal so the
  user can see why their `--auto` flag didn't take effect.

This override is non-negotiable in v1: there is no `--really-auto` or
`--force` escape hatch. Sensitive-surface mistakes cascade through the rest
of the workbench (every skill that depends on `skills-catalog.json` or
manifests).
