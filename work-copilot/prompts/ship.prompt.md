---
mode: agent
description: "PR-description synthesis for a CJ_company-workflow work item — runs /validate first, reads tracker + PRD/RCA + existing PR-DESCRIPTION.md template (defect/task), synthesizes a clipboard-ready PR description from receipts.implement.commits_since_scaffold + receipts.qa.ac_ids_covered + tracker journal, prints to chat, optionally writes <work-item>/PR-DESCRIPTION.md, runs the Working-Tree Rule paste pattern (warn-and-write, not hard-stop), and writes a receipts.ship block with pr_opened: false."
tools: ['codebase', 'search', 'searchResults', 'editFiles']
---

# /wc-ship

PR-description synthesis for a CJ_company-workflow work item. Reads the
tracker (parses `receipts.qa` + `receipts.implement` + `## Journal`), the
type-appropriate primary artifact (PRD for user-story, RCA for defect,
TRACKER acceptance criteria for task), and the existing `PR-DESCRIPTION.md`
template (defect/task only — user-stories ship via task children).
Synthesizes a clipboard-ready PR description, prints it to chat, optionally
writes it to `<work-item>/PR-DESCRIPTION.md`, runs the Working-Tree Rule
paste pattern (warn-and-write, not hard-stop), and writes a `receipts.ship`
block with `pr_opened: false`.

This prompt is **build #5 of the work-copilot pipeline**. The `receipts.ship`
schema below conforms to the contract locked by `/wc-qa` (S000030) /
`/wc-implement` (S000031) / `/wc-scaffold` (S000032) / `/wc-investigate`
(S000033) — same field shapes, same YAML-edit pattern (read whole, parse,
merge, write whole). Downstream `/wc-pipeline` (S000035) consumes
`receipts.ship.pr_opened` for the "ship printed but PR not opened" drift
rule. If you change the schema fields, update `/wc-pipeline` in the same PR.

`/wc-ship` is the **only receipt-writing prompt with a warn-and-write
Working-Tree Rule** (not hard-stop). Reasoning: the synthesized PR
description is a clipboard-paste artifact useful even with an unpushed
working tree; the warning surfaces the risk but does not block the receipt
write. The user opens the PR manually on GitHub afterwards and flips
`receipts.ship.pr_opened: true` + fills `receipts.ship.pr_url` — the
`pr_opened` flag (NOT `pr_url`) is the canonical truth for the drift rule.

## Usage

```
/wc-ship <work-item-path>
```

- `<work-item-path>` is required — directory containing the tracker (e.g.
  `work-items/features/F000015_pipeline/S000034_wc_ship/`).
- If `<work-item-path>` is omitted: print the usage block above and stop.

## Bundle paths (relative to repo root)

- Manifest: `.github/work-copilot/copilot-artifact-manifests.json`
- Templates: `.github/work-copilot/templates/`
- Validate prompt (precedent): `.github/prompts/validate.prompt.md`
- QA prompt (schema source): `.github/prompts/qa.prompt.md`
- Implement prompt (schema source): `.github/prompts/implement.prompt.md`

**Anti-hallucination rule:** Use your file-read tool (`codebase`) to Read
these files when you need them. Do NOT recall their contents from memory.
The whole point of receipts is verifying real files against real schemas —
hallucinated rules defeat it.

## Mode

**Walkthrough mode only.** This prompt does NOT have an `--auto` flag.
Copilot has no AskUserQuestion tool and no shell — the file write
(`PR-DESCRIPTION.md`) and the receipt write (`receipts.ship` in the tracker)
are explicit `editFiles` calls. The Working-Tree Rule paste pattern asks for
`git status --porcelain` and prints a warning if dirty, but does NOT
hard-stop.

## Steps

### 1. Pre-flight /validate gate

Invoke `/validate <work-item-path>` first. If the output contains any
`[MISSING]`, `[DRIFT]`, or `VIOLATION` line, abort with:

```
/wc-ship aborted: /validate found structural issues. Fix those first, then re-invoke /wc-ship.
```

If `/validate` says `VALID` or `SUMMARY: 0 violations`: continue.

### 2. Read tracker frontmatter — extract `type:` + receipts

Read the tracker file via `codebase` (find the `*_TRACKER.md` file in
`<work-item-path>`). Parse the YAML frontmatter.

- **If YAML parse fails:** abort with
  `/wc-ship aborted: tracker frontmatter could not be parsed — fix manually before re-invoking.`
  Do NOT attempt a partial-edit recovery. Do NOT write journal entries.
- **If the `type:` field is missing or empty:** abort with
  `/wc-ship aborted: tracker type field is missing or unrecognized; fix it before re-invoking.`
- **If `type:` is not one of `feature` / `user-story` / `task` / `defect` / `review`:** abort with the same message.

Capture the work-item ID from the tracker filename (e.g., `S000034` from
`S000034_TRACKER.md`) as `<WORK_ITEM_ID>`.

Read these receipts from the parsed frontmatter (all may be missing — the
prompt is resilient to each absence):

- `<receipts_qa>` = `receipts.qa` (or `null` if missing)
- `<receipts_implement>` = `receipts.implement` (or `null` if missing)
- `<receipts_scaffold>` = `receipts.scaffold` (or `null` if missing)

Resilience — if **both** `receipts.qa` and `receipts.implement` are absent,
abort with:

```
/wc-ship aborted: tracker has no receipts.qa and no receipts.implement. PR description synthesis requires at least one of these. Run /wc-implement and /wc-qa first.
```

If only one is present, continue — the missing receipt's sections of the PR
description will be marked "Not available" so the user can fill them
manually.

### 3. Per-type input dispatch

Read the type-appropriate primary input artifact via `codebase`:

| Tracker `type:` | Primary artifact | PR-DESCRIPTION template |
|------|------------------|-------------------------|
| `user-story` | `PRD.md` (or `SPEC.md` if mirrored) | (none — user-stories ship via task children; no PR-DESCRIPTION template by manifest) |
| `defect` | `RCA.md` | `PR-DESCRIPTION.md` (manifest-required) |
| `task` | `TRACKER.md` `## Acceptance Criteria` | `PR-DESCRIPTION.md` (manifest-required) |
| `feature` | (delegate — see step 3.feature below) | — |
| `review` | (degenerate — see step 3.review below) | — |

**Filename-matching tolerance:** strip ID prefixes (`^[A-Z][0-9]+_`) when
locating these files in the work-item directory. If the type's primary
artifact is missing, abort with:

```
/wc-ship aborted: required input artifact <name> missing for type <type>; fix it before re-invoking.
```

For `defect` and `task`: if `PR-DESCRIPTION.md` is missing in the work-item
directory, print a warning and continue with template-less synthesis:

```
Note: PR-DESCRIPTION.md template not found in <work-item-path>. Synthesizing without template scaffold — the description will still include all 5 sections (summary, what changed, ACs verified, open risks, tracker link).
```

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

   /wc-ship synthesizes a PR description per shipped child. Which child should I synthesize now? (reply with the number or the child ID; reply "all" to synthesize one description per child)
   ```

3. Wait for the user's reply. Re-invoke `/wc-ship` on the picked child's
   path (or loop over all children if the user replied "all"). Do NOT write
   `receipts.ship` on the feature tracker itself — feature trackers
   coordinate; children carry their own receipts.

#### 3.review — degenerate path

If `type: review`:

1. Read the review-notes file.
2. Synthesize a PR description that summarizes the review action taken
   (single-paragraph "Summary" + one-line "What changed" derived from
   journal entries; ACs / commits / risks sections may be empty arrays in
   the receipt).
3. Continue to step 4 with the degenerate shape (some receipt arrays will
   be empty — `/wc-pipeline` tolerates this).

### 4. Synthesize PR description

Build the PR description from the inputs read in steps 2-3. The synthesized
text MUST contain these 5 sections (per AC-3):

```
# <one-line summary derived from tracker title>

## What changed

<list of commit one-liners from receipts.implement.commits_since_scaffold>
- If receipts.implement.commits_since_scaffold is empty or absent: "No commits recorded in receipts.implement.commits_since_scaffold."

## ACs verified

<list of AC IDs from receipts.qa.ac_ids_covered>
- For each AC ID: include the AC description from the primary artifact (PRD/RCA/TRACKER) if available.
- If receipts.qa is absent: "No QA receipt found — ACs not yet verified."
- If receipts.qa.ac_ids_uncovered is non-empty: include "Uncovered ACs (no test row): <list>" as a sub-section under ACs verified.

## Open risks

<list of strings from receipts.implement.open_risks>
- If receipts.implement.open_risks is empty: "No open risks recorded."
- If receipts.implement is absent: "No implement receipt found — open risks not recorded."

## Tracker

[<WORK_ITEM_ID>](<work-item-path>/<WORK_ITEM_ID>_TRACKER.md)
```

**Synthesis rules:**

- The **one-line summary** is derived from the tracker's frontmatter `title:`
  field. If absent, fall back to a kebab-case-titlecase of the directory
  basename.
- **Tone:** factual, terse, no marketing copy. Mirror the journal entries'
  voice (which are written in past tense, declarative).
- **Inputs_read tracking:** capture the list of files used for synthesis as
  `<pr_description_synthesized_from>`. The list is:
  - The tracker path (always).
  - The primary input artifact path (PRD/RCA/TRACKER, per type) — but for
    `task`, the source is the same tracker, so it appears once.
  - The PR-DESCRIPTION.md template path, if present.
  - The literal string `commits <sha_start>..<sha_end>` derived from
    `receipts.implement.commits_since_scaffold` (first and last entries),
    or `commits []` if the list is empty.

### 5. Print PR description to chat — clipboard-paste artifact

Print the synthesized PR description to chat exactly as a markdown block,
ready for clipboard paste. Frame it with separator lines so the user can
visually grab the block:

```
=== PR DESCRIPTION (copy to clipboard) ===

<synthesized PR description from step 4>

=== END PR DESCRIPTION ===
```

The framing is part of the output contract — `/wc-pipeline` does not parse
chat output, but downstream tooling (or future skills) may grep for the
sentinels.

### 6. Optionally write <work-item-path>/PR-DESCRIPTION.md

Ask the user in chat:

```
Write the synthesized description to <work-item-path>/PR-DESCRIPTION.md? (reply "yes" to write [recommended — useful history artifact], "no" for chat-only)
```

Wait for the user's reply.

- If "yes" (default behavior): write the synthesized PR description (without
  the framing sentinels) to `<work-item-path>/PR-DESCRIPTION.md` via
  `editFiles`. Overwrite if it exists.

  **Note:** for `defect` and `task` types, this file may already exist as
  the template scaffolded by `/wc-scaffold`. The synthesized content
  overwrites the template — that is intentional. The template was a
  scaffold for the author to fill in; `/wc-ship` produces the filled
  artifact.

- If "no": skip the file write; the chat block is the only artifact.

Capture whether the file was written as `<pr_description_file_written>`
(bool) for the receipt.

### 7. Working-Tree Rule — warn-and-write (NOT hard-stop)

Compute `<files_touched>` = union of:
- `receipts.implement.files_touched` (if present)
- The work-item directory itself (`<work-item-path>`)
- `<work-item-path>/PR-DESCRIPTION.md` (if step 6 wrote it)

Ask the user:

```
Please run this command and paste the output:

  git status --porcelain -- <files_touched>

(One file per line; if all clean, paste an empty block.)
```

Substitute `<files_touched>` with the list above (space-separated). Parse
the paste.

**If the paste is empty (all committed):** continue to step 8 silently. No
warning needed.

**If ANY non-blank line is present (uncommitted entries):** print a warning
AND PROCEED (do NOT abort, do NOT hard-stop):

```
Warning: PR description was synthesized from an unpushed working tree.

Uncommitted entries:
  <pasted lines verbatim>

Note: PR description was synthesized from an unpushed working tree; verify before opening PR. The receipts.ship block will still be written. After committing and pushing, you may re-invoke /wc-ship to refresh the synthesis (it is idempotent — overwrites prior receipts.ship).
```

Continue to step 8. Do NOT abort.

This is the **only** receipt-writing prompt in the work-copilot bundle with
a warn-and-write Working-Tree Rule (per F000015 DESIGN big decision #5).
The other prompts (`/wc-implement`, `/wc-qa`) hard-stop because their
receipts encode commit-state truth; `/wc-ship`'s receipt encodes synthesis
truth, which is useful even when the tree is dirty.

### 8. Receipt write — read whole tracker, parse YAML, merge, write whole

This is the **YAML-edit pattern** used across all work-copilot prompts
(precedent: `validate.prompt.md`, `qa.prompt.md`, `implement.prompt.md`,
`scaffold.prompt.md`). Do NOT attempt a surgical line-level edit on the
frontmatter — Copilot's `editFiles` is unreliable for that shape.

1. Read the entire tracker file via `codebase`.
2. Split into frontmatter (between `---` markers) and body.
3. Parse the frontmatter as YAML.
   - **If YAML parse fails:** abort with
     `/wc-ship aborted: tracker frontmatter could not be parsed — fix manually before re-invoking.`
     Do NOT attempt a partial-edit recovery. Do NOT write journal entries.
4. Build the new `receipts.ship` block (overwrite any existing one —
   receipts are overwrite-per-phase, not append-only):

```yaml
receipts:
  ship:
    phase: 4
    completed_at: "<ISO-8601 timestamp, e.g. 2026-05-11T15:42:08Z>"
    pr_description_synthesized_from: [<list of inputs from step 4>]
    pr_description_file_written: <true|false>
    pr_url: null
    pr_opened: false
    next_legal: [merge]
```

**Field semantics:**

- `phase: 4` — always 4 for ship (Phase 4 in the lifecycle).
- `pr_description_synthesized_from` — list of input file paths and the commit
  range; the order is `[TRACKER.md, PRD.md or RCA.md, "commits <sha_start>..<sha_end>"]`.
- `pr_description_file_written` — true iff step 6 wrote
  `<work-item-path>/PR-DESCRIPTION.md`.
- `pr_url: null` — `/wc-ship` does not open PRs (no shell, no API access).
  The user fills this manually after opening on GitHub.
- `pr_opened: false` — the canonical truth for `/wc-pipeline`'s "ship
  printed but PR not opened" drift rule. NOT derived from `pr_url`. The
  user flips this manually after opening on GitHub.
- `next_legal: [merge]` — ship's only legal write-phase successor is merge.
  `/wc-pipeline` is always legal (read-only) but is not listed in
  `next_legal`.

5. Append a one-line journal entry to the body's `## Journal` section:

```
- <ISO date> [ship-pass] <WORK_ITEM_ID>: PR description synthesized; pr_opened: false (awaiting user manual open).
```

6. Serialize: `---\n<merged YAML>\n---\n<body with new journal entry>`.
7. Write the whole tracker back via `editFiles`.

### 9. Print post-ship instructions + summary

Print exactly (per AC-7):

```
After opening the PR on GitHub, edit this tracker's receipts.ship: flip pr_opened: true and fill pr_url with the PR URL.

/wc-ship complete: PR description synthesized; pr_description_file_written=<bool>; receipts.ship written with pr_opened: false; next: open PR manually on GitHub, then /wc-pipeline <work-item-path> to verify ship state.
```

Replace `<bool>` and `<work-item-path>` with actual values.

The chat output ends with `/wc-pipeline <work-item-path>` as the suggested
next step — `/wc-pipeline` will detect ship-printed-but-not-opened drift
24h after the receipts.ship was written if the user forgets to flip
`pr_opened: true`.

## Receipt schema (locked — downstream prompts depend on this)

```yaml
receipts:
  ship:
    phase: 4                                       # always 4 for ship (Phase 4 in the lifecycle)
    completed_at: <ISO-8601 UTC>                   # when this /wc-ship run finished
    pr_description_synthesized_from: [<string>, ...] # list of input files + commit range
    pr_description_file_written: <bool>            # true iff PR-DESCRIPTION.md was written
    pr_url: <string|null>                          # null until the user pastes the PR URL after manual open
    pr_opened: <bool>                              # false until the user manually flips after opening on GitHub
    next_legal: [<string>, ...]                    # phase names the user can legally invoke next; for ship always ["merge"]
```

**`pr_opened` is the canonical truth, NOT `pr_url`.** A user could paste a
URL into `pr_url` and forget to flip `pr_opened`, or vice versa. The flag
is the unambiguous gate. `/wc-pipeline`'s drift rule reads `pr_opened`,
not `pr_url`.

**Schema contract:** these field names and shapes are stable. If you need a
new field, add it; do not rename or remove existing ones without bumping
the schema version (which would require a coordinated update across all
six work-copilot prompts).

## Output contract (do not deviate)

Status tags are the grep-able surface. Match exactly:

| Tag | Meaning |
|-----|---------|
| `=== PR DESCRIPTION (copy to clipboard) ===` | Start sentinel for the clipboard block |
| `=== END PR DESCRIPTION ===` | End sentinel for the clipboard block |
| `[ship-pass]` | Receipts.ship written; journal entry appended |
| `Warning: PR description was synthesized from an unpushed working tree.` | Working-Tree Rule warn (not hard-stop) |
| `After opening the PR on GitHub` | Post-ship instruction (reminds user to flip pr_opened) |
| `/wc-ship complete:` | One-line summary on success |
| `/wc-ship aborted:` | Hard-stop (validate fail, YAML parse fail, missing receipts, missing primary artifact, etc.) |

Do not invent new tags or restructure the receipt block.

## Parity check

The journal-entry shape and the `receipts.ship` schema fields are the
acceptance contract. `/wc-pipeline` (S000035) reads `receipts.ship.pr_opened`
for the "ship printed but PR not opened" drift rule. If you change the
schema, `/wc-pipeline` will print stale diagnostics. Keep the schema locked
unless you're coordinating a downstream update across all six work-copilot
prompts.

## Known limitations (V1)

- **No auto-push / auto-open PR:** Copilot has no shell and no GitHub API
  access. The user opens the PR manually on GitHub and flips
  `pr_opened: true` afterwards. V2 candidate: if Copilot gains shell
  access, fold this into `/wc-ship` itself.
- **No multi-commit summarization:** V1 lists all commit one-liners from
  `receipts.implement.commits_since_scaffold`. Work-items with 20+ commits
  may produce verbose descriptions. Acceptable in V1; user can edit the
  clipboard-pasted text before opening the PR. V2 candidate: summarize
  mode (group by theme, drop trivial commits).
- **No stale-PRD detection:** `/wc-ship` synthesizes against whatever
  PRD/RCA is present in the work-item dir. If the PRD was edited long
  before `receipts.implement.commits_since_scaffold`, the synthesis may
  not reflect the actual shipped changes. `/wc-pipeline` (S000035) handles
  staleness detection — `/wc-ship` just synthesizes.
- **`user-story` ship is an edge case:** the V1 spec says user-stories
  ship via task children. If you invoke `/wc-ship` on a standalone
  user-story (no task children), the synthesis still works but uses the
  PRD's AC structure rather than a PR-DESCRIPTION.md template (which
  user-stories don't have per manifest). The output is still a valid PR
  description.
- **Idempotency:** re-running `/wc-ship` overwrites the prior
  `receipts.ship` block and re-synthesizes from current receipts. Useful
  after a fix-up commit lands and `receipts.implement.commits_since_scaffold`
  has new entries. The user should re-paste `git status --porcelain` each
  run (Working-Tree Rule is per-invocation, not cached).
