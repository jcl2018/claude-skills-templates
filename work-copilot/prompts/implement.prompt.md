---
mode: agent
description: "Implement-from-spec walkthrough for a CJ_company-workflow work item — per-type input dispatch over 5 tracker types (user-story, defect, task, feature, review), propose-confirm-edit-reconfirm cadence, user-paste git capture, Working-Tree Rule hard-stop, and a receipts.implement block written to the tracker frontmatter."
tools: ['codebase', 'search', 'searchResults', 'findTestFiles', 'editFiles']
---

# /wc-implement

Implement-time walkthrough for a CJ_company-workflow work item. Reads the right
input artifacts per tracker `type:` (user-story, defect, task, feature, review),
proposes a plan in chat, edits code with explicit user confirmation between
chunks, captures git metadata via user-paste, enforces the Working-Tree Rule,
and writes a `receipts.implement` block into the tracker's YAML frontmatter.

This prompt is **build #2 of the work-copilot pipeline**. The `receipts.implement`
schema below conforms to the contract locked by `/wc-qa` (S000030) — same field
shapes, same YAML-edit pattern (read whole, parse, merge, write whole),
same user-paste git capture, same Working-Tree Rule. Downstream prompts
(`/wc-scaffold`, `/wc-investigate`, `/wc-ship`, `/wc-pipeline`) consume this
schema. If you change the schema fields, update the downstream prompts in the
same PR.

## Usage

```
/wc-implement <work-item-path>
```

- `<work-item-path>` is required — directory containing the tracker (e.g.
  `work-items/features/F000015_pipeline/S000031_wc_implement/`).
- If `<work-item-path>` is omitted: print the usage block above and stop.

## Bundle paths (relative to repo root)

- Manifest: `.github/work-copilot/copilot-artifact-manifests.json`
- Templates: `.github/work-copilot/templates/`
- Validate prompt (precedent): `.github/prompts/validate.prompt.md`
- QA prompt (schema source): `.github/prompts/qa.prompt.md`

**Anti-hallucination rule:** Use your file-read tool (`codebase`) to Read these
files when you need them. Do NOT recall their contents from memory. The whole
point of receipts is verifying real files against real schemas — hallucinated
rules defeat it.

## Mode

**Walkthrough mode only.** This prompt does NOT have an `--auto` flag.
Copilot has no AskUserQuestion tool and no shell — every code edit must be
explicitly proposed in chat and confirmed by the user before `editFiles` runs.
The parent `/CJ_implement-from-spec` (Claude side) has `--auto` for trivial
changes; we deliberately omit it here. V2 candidate.

## Steps

### 1. Pre-flight /validate gate

Invoke `/validate <work-item-path>` first. If the output contains any
`[MISSING]`, `[DRIFT]`, or `VIOLATION` line, abort with:

```
/wc-implement aborted: /validate found structural issues. Fix those first, then re-invoke /wc-implement.
```

If `/validate` says `VALID` or `SUMMARY: 0 violations`: continue.

### 2. Read tracker frontmatter — extract `type:`

Read the tracker file via `codebase` (find the `*_TRACKER.md` file in
`<work-item-path>`). Parse the YAML frontmatter.

- **If YAML parse fails:** abort with
  `/wc-implement aborted: tracker frontmatter could not be parsed — fix manually before re-invoking.`
  Do NOT attempt a partial-edit recovery. Do NOT write journal entries.
- **If the `type:` field is missing or empty:** abort with
  `/wc-implement aborted: tracker type field is missing or unrecognized; fix it before re-invoking.`
- **If `type:` is not one of `feature` / `user-story` / `task` / `defect` / `review`:** abort with the same message.

Capture the work-item ID from the tracker filename (e.g., `S000031` from
`S000031_TRACKER.md`) as `<WORK_ITEM_ID>`.

### 3. Per-type input dispatch

Read the type-appropriate input artifacts via `codebase`:

| Tracker `type:` | Input artifacts to read | Plan source |
|------|-------------------------|-------------|
| `user-story` | `PRD.md` (or `SPEC.md` if mirrored) + `ARCHITECTURE.md` (or `DESIGN.md`) + `TEST-SPEC.md` | PRD/SPEC's Components Affected + Data Flow |
| `defect` | `RCA.md` + `test-plan.md` | RCA's Affected Components + Fix Description; test-plan rows define post-fix behavior |
| `task` | `TRACKER.md` + `test-plan.md` | TRACKER's Acceptance Criteria + Todos; test-plan rows define expected behavior |
| `feature` | feature-summary + DESIGN + milestones | (delegate — see step 3.feature below) |
| `review` | `review-notes.md` (or equivalent) | (degenerate — see step 3.review below) |

**Filename-matching tolerance:** strip ID prefixes (`^[A-Z][0-9]+_`) when
locating these files in the work-item directory. If a required artifact for
the dispatched type is missing, abort with
`/wc-implement aborted: required input artifact <name> missing for type <type>; fix it before re-invoking.`

#### 3.feature — delegation

If `type: feature`:

1. List child user-story / defect / task / review subdirectories (any
   subdirectory containing `*_TRACKER.md`).
2. Print to chat:

   ```
   <WORK_ITEM_ID> is a feature with N child work-items:
     1. <CHILD_ID_1>_<slug> (<child_type_1>)
     2. <CHILD_ID_2>_<slug> (<child_type_2>)
     ...

   Which child should I implement now? (reply with the number or the child ID)
   ```

3. Wait for the user's reply. Re-invoke `/wc-implement` on the picked child's
   path. Do NOT write `receipts.implement` on the feature tracker itself —
   feature trackers coordinate; children carry their own receipts.

#### 3.review — degenerate path

If `type: review`:

1. Read the review-notes file (or whatever artifact the review work-item carries).
2. Walk through the review-notes with the user — read sections, ask what action
   was taken, capture a 1-line summary.
3. Skip steps 4 (walkthrough plan) and 9 (`editFiles`) — review work-items
   typically have no code edits. Go directly to step 5 (git capture) and step 8
   (receipt write) using the degenerate shape (empty arrays):

   ```yaml
   receipts:
     implement:
       phase: 2
       completed_at: "<ISO>"
       latest_sha_at_implement: "<40-char SHA>"
       commits_since_scaffold: []
       files_touched: []
       ac_ids_targeted: []
       open_risks:
         - "<one-line: what was reviewed and what action was taken>"
       next_legal: [qa]
   ```

   `/wc-pipeline` tolerates these empty arrays as a valid completion state.

### 4. Walkthrough — propose plan, confirm, edit, re-confirm

For non-`review` types: cross-reference inputs and propose a plan in chat.

1. Print a plan summary:

   ```
   Proposed implementation for <WORK_ITEM_ID> (type: <type>):

   Files to change (N):
     [NEW]      <path 1>    <one-line description>
     [MODIFIED] <path 2>    <one-line description>
     [REMOVED]  <path 3>    <one-line description>

   ACs targeted: AC-N, AC-M, ...

   Approach (per the input artifact's "Chosen" tradeoff column where applicable):
     <2-3 line summary of how the changes map to the SPEC/RCA/TRACKER's plan>

   Confirm to proceed (reply "ok" or describe a revision).
   ```

2. **Wait for user confirmation.** If the user requests a revision, revise the
   plan and re-prompt. Do NOT call `editFiles` until the user confirms.

3. **Edit chunking heuristic:** make one logical change per `editFiles` cycle.
   "One logical change" = one file, OR one function across files, OR one
   cohesive refactor. If unsure, ASK the user how to chunk.

4. After each `editFiles` call, summarize the diff in chat and re-confirm:

   ```
   Applied: <one-line diff summary>. Continue with the next chunk? (ok / revise / stop)
   ```

   Repeat until all planned edits are applied or the user says stop.

5. Track the set of files actually edited as `<files_touched>` — a list of
   paths (relative to repo root). This drives the diff audit and Working-Tree
   Rule paste prompts.

6. Track the set of AC IDs covered by these edits as `<ac_ids_targeted>` —
   match the AC IDs read in step 3 against the planned changes (an edit
   "targets" an AC if the change directly addresses that AC's contract).

### 5. User-paste — git rev-parse HEAD

Ask the user to paste the current commit SHA:

```
Please run this command and paste the output:

  git rev-parse HEAD

(One 40-character hex SHA on a single line.)
```

Parse the paste. Validate it's a 40-character lowercase hex string. If
malformed, re-prompt once:

```
The pasted output doesn't look like a SHA. Please re-run `git rev-parse HEAD` and paste the single 40-character hex line.
```

After one retry, accept what was pasted if it looks SHA-shaped. Capture as
`<latest_sha_at_implement>`.

### 6. User-paste — git log since scaffold

Determine `<scaffold_sha>`:

1. Read `receipts.scaffold.latest_sha_at_scaffold` from the tracker frontmatter
   (if present).
2. **First-run fallback:** if `receipts.scaffold` is absent (e.g., this
   work-item was hand-authored, not scaffolded via `/wc-scaffold`), prompt the
   user:

   ```
   No receipts.scaffold found. Please paste the SHA from when this work-item was scaffolded (or paste the SHA where Phase 1 was last committed):
   ```

   Treat the paste as `<scaffold_sha>`.

Then ask for the commit log:

```
Please run this command and paste the output:

  git log --oneline <scaffold_sha>..HEAD

(One commit per line, format "<short_sha> <subject>". If empty: paste an empty block — that means no commits since scaffold.)
```

Parse the paste — each non-empty line is a commit. Extract the short SHAs
(first whitespace-delimited token per line). Capture as
`<commits_since_scaffold>` (list of SHAs).

If the paste looks empty or malformed and the user said there were commits,
re-prompt once. After one retry, accept what was pasted (treat as empty if
still empty).

### 7. Working-Tree Rule — hard-stop

Ask the user:

```
Please run this command and paste the output:

  git status --porcelain -- <files_touched>

(One file per line; if all clean, paste an empty block.)
```

Substitute `<files_touched>` with the list from step 4 (space-separated).
Parse the paste. **Each non-blank line is an uncommitted change.** If ANY
non-blank line is present, hard-stop:

```
Please commit those files first and re-invoke /wc-implement; I'll wait.

Uncommitted entries:
  <pasted lines verbatim>
```

Do NOT write `receipts.implement`. Do NOT write journal entries. Stop.

If the paste is empty (all committed): continue.

### 8. Compute open_risks + next_legal

Capture `<open_risks>` as a list of one-line strings. Sources, in order:

1. Open Questions from the input artifact (SPEC/PRD `## Open Questions` or
   RCA `## Regression Risk`) that the implementation did not resolve.
2. Edge cases the user surfaced during the walkthrough that weren't fully
   addressed.
3. Deferred follow-ups (`(Deferred)` items added to TRACKER `## Todos`).

If none: `<open_risks>: []`.

`<next_legal>` is always `[qa]` for non-review types. For `review` type, also
`[qa]` (the degenerate path still expects /wc-qa to walk through and confirm).

### 9. Receipt write — read whole tracker, parse YAML, merge, write whole

This is the **YAML-edit pattern** used across all work-copilot prompts
(precedent: `validate.prompt.md`, `qa.prompt.md`). Do NOT attempt a surgical
line-level edit on the frontmatter — Copilot's `editFiles` is unreliable for
that shape.

1. Read the entire tracker file via `codebase`.
2. Split into frontmatter (between `---` markers) and body.
3. Parse the frontmatter as YAML.
   - **If YAML parse fails:** abort with
     `/wc-implement aborted: tracker frontmatter could not be parsed — fix manually before re-invoking.`
     Do NOT attempt a partial-edit recovery. Do NOT write journal entries.
4. Build the new `receipts.implement` block (overwrite any existing one —
   receipts are overwrite-per-phase, not append-only):

   ```yaml
   receipts:
     implement:
       phase: 2
       completed_at: "<ISO-8601 timestamp, e.g. 2026-05-11T15:42:08Z>"
       latest_sha_at_implement: "<40-char SHA from step 5>"
       commits_since_scaffold: [<list of SHAs from step 6>]
       files_touched: [<list of paths from step 4>]
       ac_ids_targeted: [<list of AC IDs from step 4>]
       open_risks: [<list of one-line strings from step 8>]
       next_legal: [qa]
   ```

5. Append a one-line journal entry to the body's `## Journal` section:

   ```
   - <ISO date> [impl-pass] <WORK_ITEM_ID>: implementation complete; N files touched; M ACs targeted.
   ```

6. Serialize: `---\n<merged YAML>\n---\n<body with new journal entry>`.
7. Write the whole tracker back via `editFiles`.

### 10. Print summary

Print exactly:

```
/wc-implement complete: N files touched; M ACs targeted; next /wc-qa <work-item-path>.
```

Replace `N`, `M`, and `<work-item-path>` with actual values.

## Receipt schema (locked — downstream prompts depend on this)

```yaml
receipts:
  implement:
    phase: 2                          # always 2 for implement (Phase 2 in the lifecycle)
    completed_at: <ISO-8601 UTC>      # when this /wc-implement run finished
    latest_sha_at_implement: <SHA>    # 40-char hex; from user-paste of `git rev-parse HEAD`
    commits_since_scaffold:           # list of short SHAs from `git log <scaffold_sha>..HEAD`
      - <short SHA>
    files_touched:                    # list of paths edited during this run (relative to repo root)
      - <path>
    ac_ids_targeted: [<string>, ...]  # AC IDs the edits address (e.g., "AC-1", "AC-3")
    open_risks: [<string>, ...]       # one-line risk/followup strings; may be empty
    next_legal: [<string>, ...]       # phase names the user can legally invoke next; always includes "qa"
```

**Degenerate review-type shape:** `files_touched: []`, `commits_since_scaffold: []`,
`ac_ids_targeted: []`, `open_risks: ["<one-line summary>"]`, `next_legal: [qa]`.
This is a valid completion state — `/wc-pipeline` must tolerate it.

**Schema contract:** these field names and shapes are stable. If you need a
new field, add it; do not rename or remove existing ones without bumping the
schema version (which would require a coordinated update across all six
work-copilot prompts).

## Output contract (do not deviate)

Status tags are the grep-able surface. Match exactly:

| Tag | Meaning |
|-----|---------|
| `[impl-pass]` | Implementation complete; journal entry written |
| `/wc-implement complete:` | One-line summary on success |
| `/wc-implement aborted:` | Hard-stop (validate fail, YAML parse fail, malformed type, missing artifact, etc.) |

Do not invent new tags or restructure the receipt block.

## Parity check

The journal-entry shape and the `receipts.implement` schema fields are the
acceptance contract. `/wc-qa` (S000030) and `/wc-pipeline` (S000035) read
these. If you change either, downstream prompts will print stale diagnostics.
Keep the schema locked unless you're coordinating a downstream update across
all six work-copilot prompts.
