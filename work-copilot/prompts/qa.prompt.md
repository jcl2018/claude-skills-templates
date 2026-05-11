---
mode: agent
description: "QA walkthrough for a CJ_company-workflow work item — runs the test-row checklist, cross-references AC coverage, audits diff since last [qa-*] entry, enforces the Working-Tree Rule, and writes a receipts.qa block into the tracker."
tools: ['codebase', 'search', 'searchResults', 'findTestFiles', 'editFiles']
---

# /wc-qa

QA-time walkthrough for a CJ_company-workflow work item. Reads `test-plan.md`
(defect/task) or `TEST-SPEC.md` (user-story), cross-references acceptance
criteria with test-row coverage, audits files changed since the last
`[qa-*]` journal entry, enforces the Working-Tree Rule, and writes a
`receipts.qa` block into the tracker's YAML frontmatter.

This prompt is **build #1 of the work-copilot pipeline** and locks the
`receipts.qa` schema that downstream phase commands (`/wc-implement`,
`/wc-scaffold`, `/wc-investigate`, `/wc-ship`, `/wc-pipeline`) consume.
If you change the schema fields, update the downstream prompts in the same
PR.

## Usage

```
/wc-qa <work-item-path>
```

- `<work-item-path>` is required — directory containing the tracker (e.g.
  `work-items/features/F000015_pipeline/S000030_wc_qa/`).
- If `<work-item-path>` is omitted: print the usage block above and stop.

## Bundle paths (relative to repo root)

- Manifest: `.github/work-copilot/copilot-artifact-manifests.json`
- Templates: `.github/work-copilot/templates/`
- Validate prompt (precedent): `.github/prompts/validate.prompt.md`

**Anti-hallucination rule:** Use your file-read tool (`codebase`) to Read these
files. Do NOT recall their contents from memory. The whole point of receipts
is verifying real files against real schemas — hallucinated rules defeat it.

## Steps

### 1. Pre-flight /validate gate

Invoke `/validate <work-item-path>` first. If the output contains any
`[MISSING]`, `[DRIFT]`, or `VIOLATION` line, abort with:

```
/wc-qa aborted: /validate found structural issues. Fix those first, then re-invoke /wc-qa.
```

If `/validate` says `VALID` or `SUMMARY: 0 violations`: continue.

### 2. Read test rows (per type)

Read the tracker's `type` field from frontmatter. Then:

| Type | File to read | Section |
|------|-------------|---------|
| `user-story` | `TEST-SPEC.md` (strip ID prefix when matching filename) | `## Smoke Tests` + `## E2E Tests` |
| `defect` | `test-plan.md` | `## Regression Test Cases` |
| `task` | `test-plan.md` | `## Regression Test Cases` |
| `feature` | (delegate) — print "Features delegate QA to child user-stories. Run /wc-qa on each child path." and stop |
| `review` | (no test rows; skip to step 3) | — |

Parse the test-row table. Print each row as a numbered checklist:

```
Test rows for {WORK_ITEM_ID}:
  1. [S1] {row description} → {expected outcome}
  2. [S2] ...
  ...
```

### 3. Read PRD/SPEC/RCA — extract AC IDs

Read the matching primary artifact for the type:

| Type | Primary artifact | AC source |
|------|-----------------|-----------|
| `user-story` | `PRD.md` (or `SPEC.md` if mirrored) | `## Acceptance Criteria` section — extract `### Story #N` blocks; if numbered headers absent, extract `AC-N` literals from the body |
| `defect` | `RCA.md` | Extract `AC-N` literals from the body; if none, fall back to test-plan row IDs |
| `task` | `TRACKER.md` `## Acceptance Criteria` | Use checkbox-row indices as AC IDs (AC-1, AC-2, ... in document order) |

Cross-reference each AC ID with the test rows from step 2 (match by AC column
in the test-row table, or by AC-N substring in the row description). Build
two lists:

- `ac_ids_covered`: ACs that map to at least one test row
- `ac_ids_uncovered`: ACs that have NO test row

Print uncovered ACs explicitly:

```
Uncovered ACs (no test row):
  - AC-3
  - AC-7
```

If `ac_ids_uncovered` is non-empty, this will land in `receipts.qa.ac_ids_uncovered`
and force `ready_for_ship: false` at the end.

### 4. Diff audit — user-paste git log

Determine the baseline timestamp for the diff audit:

1. Search the tracker's `## Journal` section for the **most recent** entry
   whose tag starts with `[qa-` (e.g., `[qa-pass]`, `[qa-fail]`,
   `[smoke-pass]`, `[smoke-fail]`).
   - If found: parse its ISO date prefix as `<baseline_iso>`.
2. **First-run fallback:** if no `[qa-*]` entry exists, read
   `receipts.scaffold.completed_at` from the tracker's frontmatter and use
   that as `<baseline_iso>`. (If `receipts.scaffold` is also missing, abort
   with: `/wc-qa aborted: no [qa-*] journal entry and no receipts.scaffold; re-scaffold via /wc-scaffold or hand-author a receipts.scaffold block first.`)

Ask the user to paste the diff:

```
Please run this command and paste the output:

  git log --name-only --since='<baseline_iso>' --pretty=format:''

(If output is empty: paste an empty block — that means no commits since the baseline.)
```

Parse the paste — each non-empty line is a changed file path. Deduplicate.

Cross-reference with test-plan rows: for each changed file, check whether
any test row (Script/Command column or Steps column) names the file. Build:

- `diff_audit.changed_files_without_tests`: files in the paste with no
  matching test row.

If a paste looks empty or malformed (no path-shaped lines and the user said
there were commits), print:

```
The pasted output looks empty or malformed. Please re-run the command and paste again, or paste an empty block to confirm no commits since <baseline_iso>.
```

…and re-prompt once. After one retry, accept what was pasted (treat as empty
if still empty).

### 5. Working-Tree Rule — hard-stop

Compute `<files_touched>` = union of (test-row Script/Command file paths) ∪
(diff-audit changed files). Ask the user:

```
Please run this command and paste the output:

  git status --porcelain -- <files_touched>

(One file per line; if all clean, paste an empty block.)
```

Parse the paste. **Each non-blank line is an uncommitted change.** If ANY
non-blank line is present, hard-stop:

```
Please commit those files first and re-invoke /wc-qa; I'll wait.

Uncommitted entries:
  {pasted lines verbatim}
```

Do NOT write receipts.qa. Do NOT write journal entries. Stop.

If the paste is empty (all committed): continue.

### 6. Walk the checklist

Walk each numbered test row from step 2 in order. For each row, ask:

```
Row {N} — {description}
Expected: {expected outcome}

Pass / Fail / Skip? (please reply pass | fail: <reason> | skip: <reason>)
```

Capture replies. Build:

- `test_rows_run`: total rows asked
- `journal_entries`: one line per row in the format:
  - `[smoke-pass] {row_id} ({AC-N}): {description}` for pass
  - `[qa-fail: <reason>] {row_id} ({AC-N}): {description}` for fail
  - `[smoke-skip: <reason>] {row_id} ({AC-N}): {description}` for skip

### 7. Decide ready_for_ship

`ready_for_ship` is `true` IFF all of the following hold:

- Every test row in step 6 was pass (no fail, no skip)
- `ac_ids_uncovered` is empty
- `diff_audit.changed_files_without_tests` is empty

Otherwise `ready_for_ship` is `false`. Capture blockers as a list of strings
for the summary.

Compute `next_legal`: phases the user can legally invoke next.

- If `ready_for_ship: true` → `next_legal: [ship, pipeline]`
- If `ready_for_ship: false` and any test row was fail → `next_legal: [implement, qa, pipeline]`
- If `ready_for_ship: false` due to uncovered ACs only → `next_legal: [implement, qa, pipeline]`
- Always include `pipeline` (read-only; always legal).

### 8. Receipt write — read whole tracker, parse YAML, merge, write whole

This is the **YAML-edit pattern** used across all work-copilot prompts
(precedent: `validate.prompt.md`). Do NOT attempt a surgical line-level edit
on the frontmatter — Copilot's `editFiles` is unreliable for that shape.

1. Read the entire tracker file via `codebase`.
2. Split into frontmatter (between `---` markers) and body.
3. Parse the frontmatter as YAML.
   - **If YAML parse fails:** abort with `/wc-qa aborted: tracker frontmatter could not be parsed — fix manually before re-invoking.` Do NOT attempt a partial-edit recovery. Do NOT write journal entries.
4. Build the new `receipts.qa` block (overwrite any existing one — receipts
   are overwrite-per-phase, not append-only):

```yaml
receipts:
  qa:
    phase: 3
    completed_at: "<ISO-8601 timestamp, e.g. 2026-05-11T15:42:08Z>"
    test_rows_run: <int>
    ac_ids_covered: [<list of AC IDs>]
    ac_ids_uncovered: [<list of AC IDs>]
    diff_audit:
      changed_files_without_tests: [<list of file paths>]
    journal_entries: [<list of journal lines written in step 6>]
    ready_for_ship: <true|false>
    next_legal: [<list of phase names>]
```

5. Append the per-row journal entries from step 6 to the body's `## Journal`
   section (one bullet per entry, prefixed with the ISO date).
6. Serialize: `---\n<merged YAML>\n---\n<body with new journal entries>`.
7. Write the whole tracker back via `editFiles`.

### 9. Print READY_FOR_SHIP line

Print exactly one of:

```
READY_FOR_SHIP: yes
```

or

```
READY_FOR_SHIP: no
Blockers:
  - <blocker 1>
  - <blocker 2>
```

Then a one-line summary (P2 / nice-to-have):

```
/wc-qa complete: {N_pass}/{N_total} rows passed; {U} ACs uncovered; {D} files changed without tests; ready_for_ship={true|false}.
```

## Receipt schema (locked — downstream prompts depend on this)

```yaml
receipts:
  qa:
    phase: 3                          # always 3 for qa (Phase 3 in the lifecycle)
    completed_at: <ISO-8601 UTC>      # when this /wc-qa run finished
    test_rows_run: <int>              # count of rows walked in step 6
    ac_ids_covered: [<string>, ...]   # ACs with at least one test row
    ac_ids_uncovered: [<string>, ...] # ACs with no test row
    diff_audit:
      changed_files_without_tests:    # files in git log paste with no matching test row
        - <path>
    journal_entries: [<string>, ...]  # the journal lines written in step 6, in order
    ready_for_ship: <bool>            # true iff: all rows pass AND ac_ids_uncovered=[] AND changed_files_without_tests=[]
    next_legal: [<string>, ...]       # phase names the user can legally invoke next
```

**Schema contract:** these field names and shapes are stable. If you need a
new field, add it; do not rename or remove existing ones without bumping the
schema version (which would require a coordinated update across all six
work-copilot prompts).

## Output contract (do not deviate)

Status tags are the grep-able surface. Match exactly:

| Tag | Meaning |
|-----|---------|
| `[smoke-pass]` | Test row passed |
| `[qa-fail: <reason>]` | Test row failed |
| `[smoke-skip: <reason>]` | Test row skipped |
| `READY_FOR_SHIP: yes` | All gates green |
| `READY_FOR_SHIP: no` | At least one blocker; list follows |
| `/wc-qa complete:` | One-line summary |
| `/wc-qa aborted:` | Hard-stop (validate fail, YAML parse fail, missing scaffold receipt, etc.) |

Do not invent new tags or restructure the receipt block.

## Parity check

The journal-entry shapes and the `receipts.qa` schema fields are the
acceptance contract. `/wc-pipeline` (status compiler) reads these. If you
change either, `/wc-pipeline` will print stale diagnostics. Keep the schema
locked unless you're coordinating a downstream update across all six
work-copilot prompts.
