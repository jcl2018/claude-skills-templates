# /implement-from-spec — Implementation Orchestration

Implement a user-story per its SPEC.md: read handoff docs, plan against the
architecture, write code via Read/Edit/Write tools, update the tracker journal,
transition Phase 2 implementer-owned gates.

This file is the step-by-step logic invoked from [SKILL.md](SKILL.md). Read
SKILL.md first for path resolution, error handling, and usage; then follow
the steps below.

---

## Step 1: Validate Input

Parse the user's argument:

- The first positional argument is `<user-story-dir>`.
- If `--auto` appears in arguments, set `AUTO_MODE=true`. Default `false`.

Verify the directory exists and is a work-item directory:

```bash
[ -d "$USER_STORY_DIR" ] || { echo "Error: user-story dir not found at $USER_STORY_DIR"; exit 1; }
TRACKER=$(find "$USER_STORY_DIR" -maxdepth 1 -name "*_TRACKER.md" -o -name "TRACKER.md" 2>/dev/null | head -1)
[ -z "$TRACKER" ] && { echo "Error: $USER_STORY_DIR is not a work-item directory (no TRACKER.md)"; exit 1; }
```

Read the tracker's frontmatter `type` field. Apply Type Spelling normalization
(per `personal-workflow/check.md` Normalization Rules: hyphens removed for
comparison; "user-story" and "userstory" both normalize to "userstory").

**If type is `feature`:** the user passed a feature dir by mistake. List child
user-story directories (subdirectories containing `*_TRACKER.md`), then
AskUserQuestion:

> {feature_id} is a feature, not a user-story. Which child should I implement?
>
> Options:
> - {S_ID_1}_{slug_1}
> - {S_ID_2}_{slug_2}
> - ...
> - Cancel

If the user picks a child, set `USER_STORY_DIR` to that child path and
re-resolve `TRACKER`. If cancel: print "Aborted." and stop.

**If type is anything other than `user-story`:** print
`Error: /implement-from-spec operates on user-story dirs only; got "{type}"` and
stop.

Locate SPEC.md in the dir:

```bash
SPEC=$(find "$USER_STORY_DIR" -maxdepth 1 -name "*_SPEC.md" -o -name "SPEC.md" 2>/dev/null | head -1)
[ -z "$SPEC" ] && { echo "Error: SPEC.md not found in $USER_STORY_DIR"; exit 1; }
```

Capture the work-item ID from the tracker filename (e.g., `S000018` from
`S000018_TRACKER.md`) → `WORK_ITEM_ID`.

## Step 2: Boundary Check at Start (Premise 1.3)

Run `/personal-workflow check` on the user-story directory. Implementation work
should only start on a fully-tracked user-story (Phase 1 green) with structural
compliance.

**Phase 1 gates** (from `tracker-user-story.md`):

- `/office-hours design referenced`
- `Working branch created (\`branch\` field populated)`
- `DESIGN + SPEC + TEST-SPEC scaffolded`
- `Acceptance criteria defined`
- `Tasks broken down`

Read the TRACKER's `## Lifecycle` → `### Phase 1: Track` → `**Gates:**` block.
Match each `- [x]` / `- [ ]` line by gate label substring. If ANY Phase 1 gate
is unchecked:

```
Error: Phase 1 incomplete; resolve before implementing.
Unchecked Phase 1 gates:
  - {gate_label_1}
  - {gate_label_2}
```

Stop. The user must either run `/scaffold-work-item` (if structural drift) or
manually verify Phase 1 work before re-running.

Also run `/personal-workflow check "$USER_STORY_DIR"` (Tier 1 Directory Mode)
and capture the result. If the output contains `[MISSING]` or `[DRIFT]`
findings:

```
Error: user-story dir has structural issues; refusing to implement.
{summary of violations}
```

Stop. Resolve drift first.

## Step 3: Idempotency Check (Premise 1.1)

Implementation idempotency uses two signals: Phase 2 implementer-owned gates
checked AND a `[impl-pass]` journal entry exists.

Phase 2 implementer-owned gates (this skill's responsibility):

- `Todos section reflects remaining work`
- `Files section updated with changed files`

Phase 2 QA-owned gates (NOT this skill's responsibility — `/qa-work-item` marks them):

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

## Step 4: Read Context

Read in this order (primary first, context after):

1. **SPEC.md** — the implementation contract. Extract:
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

If the SPEC frontmatter is missing required fields, or the SPEC body lacks
required sections per `templates/personal-workflow/doc-SPEC.md`, surface a SPEC
gap (Step 5).

## Step 5: SPEC Gap Check (P1 AC-11)

Scan the SPEC for gaps that would compromise implementation:

1. **Unresolved placeholders:** any `{[A-Z_]+}` or `{lowercase_with_underscores}` patterns
   in the SPEC body (frontmatter and YAML keys aside) — e.g., `{ITEM_NAME}`,
   `{component}`, `{TBD}`. These mean `/scaffold-work-item` left placeholders the
   author didn't fill in.

2. **Missing required sections:** the doc-SPEC template requires Problem Statement,
   Mental Model, Requirements, Acceptance Criteria, Architecture, Tradeoffs, Open
   Questions. If any is missing, that's a structural gap.

3. **Empty P0 requirements:** the `### P0 (Must-Have)` table has no rows beyond the
   header. Implementation has nothing to implement.

If gaps are found:

```
SPEC gap detected in {SPEC path}:
  - {gap 1: e.g., placeholder {ITEM_NAME} on line 47}
  - {gap 2: e.g., missing section "Open Questions"}
  - {gap 3: e.g., P0 requirements table is empty}

Fill these before implementing. Stopping.
```

Stop. Do not proceed to planning. The user must edit the SPEC and re-run.

If no gaps: continue to Step 6.

## Step 6: Plan Implementation

Build the implementation plan from SPEC's Architecture section.

### 6.1 Components Affected

Parse the `### Components Affected` table. Each row has Component, Repo, Change
Type (New / Modified / Removed), and Description. For each row:

- Identify the file path or directory the row references
- Note the change type (NEW = new file, MODIFIED = edit existing, REMOVED = delete)
- Note any path-shape constraints from the SPEC (e.g., "skills/{name}/SKILL.md")

### 6.2 Data Flow

Parse the `### Data Flow` numbered list. This is the ordered sequence of
operations the implementation should perform. Map each step to specific code
operations (function additions, edits, removals).

### 6.3 Tradeoffs

For each row in the SPEC's `## Tradeoffs` table, the **Chosen** column is the
authoritative choice. Carry the decision into the implementation; record it
later as a `[impl-decision]` journal entry citing the SPEC tradeoff source.

### 6.4 Detect Sensitive Surface

Scan the Components Affected table for these path patterns. If ANY row's
Component column matches:

- `skills-catalog.json` (any depth)
- `personal-artifact-manifests.json` or `company-artifact-manifests.json`
- `templates/personal-workflow/*` or `templates/company-workflow/*` (template files are part of structural contracts)
- `scripts/validate.sh` or `scripts/test.sh` or `scripts/test-deploy.sh` (validators)
- `.git/hooks/*` (git hook surface)

Set `SENSITIVE=true`. Otherwise `SENSITIVE=false`. Sensitive-surface changes
trigger a mandatory AUQ in Step 7 regardless of `--auto`.

### 6.5 Detect Triviality

Compute `FILES_TOUCHED` from the Components Affected table (count rows, but
exclude the TRACKER.md row — every implementation modifies the tracker).

A change is **trivial** if ALL of these hold:
- `FILES_TOUCHED ≤ 2`
- `SENSITIVE = false`
- The SPEC has no unresolved Open Questions (Step 4 confirmed this)
- No tradeoff with multiple "live" alternatives (the Chosen column always
  picked one)

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
> - Cancel — I'll do this by hand outside /implement-from-spec

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
  match the Given/When/Then contract. (The actual verification is `/qa-work-item`'s
  job, not this skill's.)

**Code style:** mirror existing repo conventions. Read 2-3 adjacent files in the
target dir first to learn naming, formatting, and idiom patterns before writing
new code. The user's saved feedback often expresses style preferences; honor
them when CLAUDE.md or recent commits document them.

**Atomicity within Step 9:** write all files in this step before mutating the
tracker (Step 10). If a write fails partway through, the tracker still reflects
"not yet implemented" — the next run resumes safely (partial-run recovery, Step 3).

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

Edit the TRACKER's `## Lifecycle` → `### Phase 2: Implement` → `**Gates:**` block.
Find the lines:

```
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files
```

Change `[ ]` to `[x]` on those two specific gates. Do NOT touch the QA-owned gates
(`Acceptance criteria verified met`, `Smoke tests pass`) — those are owned by
`/qa-work-item` and will be marked when QA passes.

## Step 11: Boundary Check at End (Premise 1.3)

Run `/personal-workflow check "$USER_STORY_DIR"` (Tier 1 Directory Mode).

**If the result contains no `[MISSING]` or `[DRIFT]` findings:** continue to
Step 12.

**If the result contains violations** (the implementation broke compliance):

AskUserQuestion:

> /personal-workflow check failed after implementation:
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
  /qa-work-item {USER_STORY_DIR}        # gate Phase 2 → Phase 3
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

`/personal-workflow check` runs at:

- **Step 2 (start):** on `USER_STORY_DIR` — gates input drift, refuses on
  Phase 1 gate gaps or structural drift.
- **Step 11 (end):** on `USER_STORY_DIR` after writes — catches self-inflicted
  compliance breaks.

Both invocations use Tier 1 Directory Mode. Blocking violations are `MISSING`
and `DRIFT`; `EXTRA` and `INFO` are advisory.

## Phase 2 Gate Ownership

Phase 2 of `tracker-user-story.md` has four gates split between two skills:

| Gate | Owner | Boundary check role |
|---|---|---|
| `Acceptance criteria verified met` | /qa-work-item (Step 9) | Untouched by /implement-from-spec |
| `Smoke tests pass` | /qa-work-item (Step 9) | Untouched by /implement-from-spec |
| `Todos section reflects remaining work` | /implement-from-spec (this skill, Step 10) | Marked CHECKED on green |
| `Files section updated with changed files` | /implement-from-spec (this skill, Step 10) | Marked CHECKED on green |

The /implement-from-spec skill makes the user-story Phase-2-ready by completing
its work and marking its two gates. /qa-work-item then verifies the
implementation and marks the remaining two gates. Together they transition the
user-story from Phase 1 → Phase 2 → Phase 3 ready.

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
