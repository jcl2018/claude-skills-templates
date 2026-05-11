---
mode: agent
description: "Scaffold a CJ_company-workflow work-item directory tree from a /wc-investigate design doc (or a hand-authored stub with the required frontmatter). Reads design-doc frontmatter for idempotency + design-doc-required invariant, reads the manifest + templates, picks next ID per type, writes per-type artifact set, calls /validate, copies receipts.investigate into the new tracker, writes receipts.scaffold with pending_commit: true, and flips the source design-doc's status: SCAFFOLDED."
tools: ['codebase', 'search', 'searchResults', 'editFiles']
---

# /wc-scaffold

Scaffold a CJ_company-workflow work-item directory tree from a `/wc-investigate`
design doc (or a hand-authored stub that carries the required frontmatter).
Reads the design-doc frontmatter (idempotency + design-doc-required invariant),
reads the manifest + templates, picks the next work-item ID per type, writes
the per-type artifact set with template fields populated from the design doc,
calls `/validate` on the new directory, copies `receipts.investigate` from the
design-doc into the new tracker (lineage), writes a `receipts.scaffold` block
with `pending_commit: true`, and updates the source design-doc's frontmatter
`status: SCAFFOLDED` + `scaffolded_to: <new-dir>`.

This prompt is **build #3 of the work-copilot pipeline**. The `receipts.scaffold`
schema below conforms to the contract locked by `/wc-qa` (S000030) and
`/wc-implement` (S000031) — same field shapes, same YAML-edit pattern
(read whole, parse, merge, write whole), same design-doc-required invariant
that roots `/wc-pipeline`'s drift-math chain. Downstream prompts
(`/wc-investigate`, `/wc-ship`, `/wc-pipeline`) consume this schema. If you
change the schema fields, update the downstream prompts in the same PR.

## Usage

```
/wc-scaffold <design-doc-path>
```

- `<design-doc-path>` is required — path to a design-doc file with the required
  frontmatter (typically under `.github/work-copilot/designs/<slug>.md`, but
  any path is accepted).
- If `<design-doc-path>` is omitted: print the usage block above and stop.

## Bundle paths (relative to repo root)

- Manifest: `.github/work-copilot/copilot-artifact-manifests.json`
- Templates: `.github/work-copilot/templates/`
- Designs (default location): `.github/work-copilot/designs/`
- Validate prompt (precedent): `.github/prompts/validate.prompt.md`
- QA prompt (schema source): `.github/prompts/qa.prompt.md`
- Implement prompt (schema source): `.github/prompts/implement.prompt.md`

**Anti-hallucination rule:** Use your file-read tool (`codebase`) to Read these
files when you need them. Do NOT recall their contents from memory. The whole
point of receipts is verifying real files against real schemas — hallucinated
rules defeat it.

## Mode

**Walkthrough mode only.** This prompt does NOT have an `--auto` flag. Copilot
has no AskUserQuestion tool and no shell — every file write must be explicitly
proposed in chat (the directory tree and the receipt writes) and the user must
confirm before `editFiles` runs. The parent `/CJ_scaffold-work-item` (Claude
side) has propose-and-confirm with a richer AUQ surface; we mirror the spirit
here with plain-chat confirmation.

## Steps

### 1. Read design-doc frontmatter — idempotency + invariant check

Read the design-doc file at `<design-doc-path>` via `codebase`. Parse the YAML
frontmatter (between `---` markers).

- **If YAML parse fails:** abort with
  `/wc-scaffold aborted: design-doc frontmatter could not be parsed — fix manually before re-invoking.`
  Do NOT attempt a partial-edit recovery.

**Design-doc-required invariant** — the design-doc MUST carry these three
frontmatter fields. If ANY is missing, abort:

- `status:` — must be present (typical values: `APPROVED`, `SCAFFOLDED`).
- `work_item_type:` — must be one of `feature` / `user-story` / `task` / `defect` / `review`.
- `receipts.investigate:` — must be present as a YAML map (even if hand-authored with a minimal shape like `{ outputs: { proposed_type: <type>, scope_summary: "hand-authored" } }`).

If any of the three is missing or empty, abort with:

```
/wc-scaffold aborted: design doc is missing required frontmatter (status, work_item_type, receipts.investigate); hand-author or re-run /wc-investigate.
```

**Idempotency NO-OP** — if the design-doc's frontmatter has BOTH:

- `status: SCAFFOLDED`
- `scaffolded_to: <path>` where `<path>` points to an existing directory (verify via `codebase` — read any file under that path; if the directory has at least one file, treat as existing)

then print:

```
Already scaffolded at <path>; nothing to do.
```

…and stop. Do NOT write anything. Do NOT call `/validate`.

If `status: SCAFFOLDED` is set but `scaffolded_to:` is missing or points to a
non-existent directory, treat it as **stale state** — continue with the full
scaffold flow (re-establish ground truth). Log this in the eventual journal
entry.

If `status:` is anything other than `SCAFFOLDED` (e.g., `APPROVED`, `DRAFT`),
continue with the full scaffold flow.

Capture from frontmatter:

- `<work_item_type>` from `work_item_type:` (one of feature/user-story/task/defect/review)
- `<design_doc_path>` = `<design-doc-path>` (the path the user invoked with)
- `<receipts_investigate>` = the full `receipts.investigate` YAML map (preserved verbatim for lineage copy in step 6)
- `<design_title>` from `title:` (fallback: filename without extension)
- `<design_slug>` — best-effort short slug for the new work-item directory name. Prefer a `slug:` frontmatter field; fall back to a kebab-case version of `title:`; final fallback: filename basename without `.md`. Limit to ~30 chars, alphanumeric + underscore.

### 2. Read manifest + templates

Read `.github/work-copilot/copilot-artifact-manifests.json` via `codebase`.
Locate the entry for `types.<work_item_type>`. If missing:

```
/wc-scaffold aborted: manifest has no entry for type "<work_item_type>". Fix the design-doc work_item_type or extend the manifest.
```

For each entry in the manifest's `required` array for this type, read the
matching template file from `.github/work-copilot/templates/<template>`. Cache
the template content for step 4.

The per-type artifact set is **manifest-driven** — do not hard-code it. As of
v1 of the manifest, the shape is:

| Type | Required artifacts |
|------|--------------------|
| `feature` | tracker (`tracker-feature.md` → `TRACKER.md`), feature-summary, design (`doc-DESIGN.md` → `DESIGN.md`), milestones |
| `user-story` | tracker (`tracker-user-story.md` → `TRACKER.md`), prd (`doc-PRD.md` → `PRD.md`), architecture, test-spec, milestones |
| `task` | tracker (`tracker-task.md` → `TRACKER.md`), test-plan, pr-description |
| `defect` | tracker (`tracker-defect.md` → `TRACKER.md`), rca, test-plan, pr-description |
| `review` | tracker (`tracker-review.md` → `TRACKER.md`), review-notes |

If the manifest evolves, the prompt picks up the new shape automatically — read
the manifest at runtime; do not memoize the table above.

### 3. ID picker — grep `work-items/` for highest existing ID per type

Determine the ID prefix from `<work_item_type>`:

| Type | Prefix |
|------|--------|
| `feature` | `F` |
| `user-story` | `S` |
| `task` | `T` |
| `defect` | `D` |
| `review` | `R` |

Use the `search` tool (or `searchResults` over `codebase`) to find the highest
existing ID of this prefix under `work-items/`. Pattern: search for filenames
matching `^<PREFIX>\d{6}_` across the repo (look in tracker filenames and
directory names). Examples of valid matches: `F000015_TRACKER.md`,
`S000032_wc_scaffold/`, `T000019_some_task/`.

Extract the numeric portion; pick the max; increment by 1; zero-pad to 6
digits. Result: `<NEW_ID>` (e.g., `S000036`).

**Known limitation (V1):** ID picker is local-only — it does not consult open
PRs (no `gh pr list` access; Copilot has no shell). Two parallel worktrees
could pick the same `<NEW_ID>` and collide at PR-merge time. Mitigation: run
`/wc-pipeline` post-scaffold to surface drift, and watch for the upstream
queue-collision detection (Claude-side `scripts/check-version-queue.sh`).
V2 candidate: user-paste pattern for `gh pr list`.

Capture:

- `<NEW_ID>` — the picked ID
- `<NEW_DIR>` — the new work-item directory path. Default shape:
  - `feature` → `work-items/features/<comp>/<NEW_ID>_<design_slug>/` where `<comp>` is best-effort from the design-doc (frontmatter `component:` if present; otherwise the user is asked in chat to confirm a component slug).
  - `user-story` / `task` / `defect` / `review` → if the design-doc carries `parent: <PARENT_FEATURE_ID>` AND a parent feature directory exists under `work-items/features/<comp>/<PARENT_FEATURE_ID>_*/`, nest under it: `work-items/features/<comp>/<PARENT_FEATURE_ID>_*/​<NEW_ID>_<design_slug>/`. Otherwise put it at the top level for the type: `work-items/user-stories/<NEW_ID>_<design_slug>/`, `work-items/tasks/<NEW_ID>_<design_slug>/`, `work-items/defects/<NEW_ID>_<design_slug>/`, `work-items/reviews/<NEW_ID>_<design_slug>/`.

If the path shape is ambiguous (e.g., multiple feature directories match the
`parent:` hint), print the candidates and ask the user in chat:

```
Multiple possible parent feature directories for <PARENT_FEATURE_ID>:
  1. <candidate path 1>
  2. <candidate path 2>

Which should I nest <NEW_ID> under? (reply with the number)
```

Wait for the reply before proceeding.

### 4. Propose-and-confirm — print the planned tree

Print the planned directory tree in chat. Format:

```
Proposed scaffold for <NEW_ID> (type: <work_item_type>):

Directory: <NEW_DIR>
Files (N):
  [NEW] <NEW_DIR><NEW_ID>_TRACKER.md       (from tracker-<work_item_type>.md)
  [NEW] <NEW_DIR><NEW_ID>_<other-artifact>.md   (from <doc-template>.md)
  ...

Source design-doc: <design-doc-path>
After write:
  - /validate <NEW_DIR>  (gate)
  - copy receipts.investigate into new tracker
  - write receipts.scaffold (pending_commit: true)
  - update <design-doc-path> frontmatter: status: SCAFFOLDED, scaffolded_to: <NEW_DIR>

Confirm to proceed (reply "ok" or describe a revision).
```

**Wait for user confirmation.** If the user requests a revision (different ID,
different slug, different parent, different component), revise the plan and
re-prompt. Do NOT call `editFiles` until the user confirms.

### 5. Write the directory tree

For each artifact in the manifest's `required` list (cached in step 2):

1. Read the template content (cached).
2. Substitute placeholder fields with values derived from the design-doc:
   - `{<TYPE>_NAME}` / `{STORY_NAME}` / `{FEATURE_NAME}` / `{TASK_NAME}` / `{DEFECT_NAME}` / `{TITLE}` → design-doc `title:` (or `<design_slug>` titlecase as fallback)
   - `{<TYPE>_ID}` / `{STORY_ID}` / `{FEATURE_ID}` / `{TASK_ID}` / `{DEFECT_ID}` / `{ID}` → `<NEW_ID>`
   - `{YYYY-MM-DD}` / `{DATE}` → today's ISO date (UTC, YYYY-MM-DD)
   - `{REPO_PATH}` → the repo root (best-effort; can be left as `{REPO_PATH}` if unknown — `/validate` only checks the field is present, not the value)
   - `{BRANCH_NAME}` / `{BRANCH}` → the current branch (ask user via paste pattern in step 5.5 if needed, OR leave as placeholder — see step 5.5)
   - `{PARENT_ID}` → design-doc `parent:` value, if present; otherwise leave empty string
   - `{JIRA_OR_TFS_URL}` / `{TICKET_URL}` etc. → leave as empty string (`""`) — these are nice-to-haves; the user fills later.
   - Body-level placeholders (`{criterion}`, `{todo}`, etc.) — leave the
     template's prose intact for the user to fill in implement phase. Do NOT
     try to synthesize acceptance criteria from the design-doc — that's
     `/wc-implement`'s job at the SPEC/PRD writing step (if you want a richer
     fill-in pass, run /wc-investigate v2 against the same design-doc).
3. Build the artifact's file path: `<NEW_DIR><NEW_ID>_<artifact-filename>`
   (e.g., `<NEW_DIR>S000036_TRACKER.md`).
4. Write the file via `editFiles`.

After all artifacts are written, summarize in chat:

```
Wrote N files under <NEW_DIR>:
  - <file 1>
  - <file 2>
  ...
```

#### 5.5. User-paste — git branch (optional)

If any template carries `{BRANCH_NAME}` or `{BRANCH}` and the user wants the
field populated rather than left as a placeholder, ask:

```
Please run this command and paste the output (or paste an empty block to keep {BRANCH_NAME} as a placeholder):

  git rev-parse --abbrev-ref HEAD
```

If the paste is a non-empty single line, substitute it into the relevant
templates and re-write the affected files. If empty, leave the placeholder
intact — `/validate` checks the key is present, not its value.

### 6. /validate gate

Invoke `/validate <NEW_DIR>` via prompt-chaining (or by reading the
`validate.prompt.md` contract and executing the equivalent Directory-Mode
checks inline if prompt-chaining is unavailable).

Parse the output. **If the output contains any `[MISSING]`, `[DRIFT]`, or
`VIOLATION` line:**

```
/wc-scaffold aborted: /validate found structural issues after scaffold.

<full /validate output>

The new directory is at <NEW_DIR> but the design-doc was NOT marked SCAFFOLDED. Fix the scaffolded artifacts (or delete the directory) and re-invoke /wc-scaffold.
```

Stop. Do NOT mark the design-doc SCAFFOLDED. Do NOT write `receipts.scaffold`.

If `/validate` says `VALID` or the `SUMMARY:` line reports `0 missing, 0 drift`:
continue.

### 7. Copy `receipts.investigate` into the new tracker — lineage

Locate the new tracker: the file at
`<NEW_DIR><NEW_ID>_TRACKER.md` (the artifact whose manifest entry is `tracker`).

Apply the **YAML-edit pattern** (read whole, parse, merge, write whole — same
as `qa.prompt.md` / `implement.prompt.md`):

1. Read the entire tracker file via `codebase`.
2. Split into frontmatter (between `---` markers) and body.
3. Parse the frontmatter as YAML.
   - **If YAML parse fails:** abort with
     `/wc-scaffold aborted: tracker frontmatter could not be parsed after write — fix manually before re-invoking.`
4. Merge in `receipts.investigate = <receipts_investigate>` (the verbatim map
   from step 1). Preserve all existing fields.

```yaml
receipts:
  investigate:
    # ... verbatim copy of design-doc's receipts.investigate map ...
```

5. Hold the merged YAML in memory — step 8 will add `receipts.scaffold` and
   the body's journal entry in the same write pass.

### 8. Write `receipts.scaffold` block + journal entry — single tracker write

Continue editing the same in-memory tracker representation from step 7.

1. Build the new `receipts.scaffold` block (overwrite any existing one —
   receipts are overwrite-per-phase, not append-only):

```yaml
receipts:
  scaffold:
    phase: 1
    completed_at: "<ISO-8601 timestamp, e.g. 2026-05-11T15:42:08Z>"
    work_item_id: "<NEW_ID>"
    work_item_dir: "<NEW_DIR>"
    artifacts_written: [<list of relative paths from step 5>]
    validate_result: "PASS"
    pending_commit: true
    next_legal: ["implement"]
```

The `pending_commit: true` flag flips to `false` on first `/wc-implement` run
when the user confirms via paste that the scaffold commit has landed
(see `implement.prompt.md` step 6 — the receipt is read at scaffold-SHA-time).

`next_legal: ["implement"]` — scaffold's only legal successor is implement.
`/wc-pipeline` is always legal (it's read-only) but is not listed in
`next_legal` (which enumerates write-phase successors only).

2. Append a one-line journal entry to the body's `## Journal` section:

```
- <ISO date> [scaffold-pass] <NEW_ID>: scaffolded from <design-doc-path>; N artifacts written; /validate PASS.
```

3. Serialize: `---\n<merged YAML>\n---\n<body with new journal entry>`.
4. Write the whole tracker back via `editFiles`.

### 9. Update source design-doc — flip status, set scaffolded_to

Apply the **YAML-edit pattern** to the source design-doc at `<design-doc-path>`:

1. Read the entire design-doc file via `codebase`.
2. Split into frontmatter and body.
3. Parse the frontmatter as YAML.
   - **If YAML parse fails:** abort with
     `/wc-scaffold aborted: design-doc frontmatter could not be re-parsed for status update — fix manually. The new work-item dir at <NEW_DIR> is valid and has receipts.scaffold; you may continue with /wc-implement, but re-invocations of /wc-scaffold will not be idempotent until the design-doc status is fixed.`
4. Merge in:
   - `status: SCAFFOLDED`
   - `scaffolded_to: <NEW_DIR>`

   Preserve ALL other frontmatter fields verbatim (do not modify `title`,
   `created`, `receipts.investigate`, etc.).

5. Serialize: `---\n<merged YAML>\n---\n<body unchanged>`.
6. Write the whole design-doc back via `editFiles`.

### 10. Print summary

Print exactly:

```
/wc-scaffold complete: <NEW_ID> at <NEW_DIR>; <N> artifacts written; next /wc-implement <NEW_DIR>.
```

Replace `<NEW_ID>`, `<NEW_DIR>`, and `<N>` with actual values.

## Receipt schema (locked — downstream prompts depend on this)

```yaml
receipts:
  scaffold:
    phase: 1                          # always 1 for scaffold (Phase 1 in the lifecycle)
    completed_at: <ISO-8601 UTC>      # when this /wc-scaffold run finished
    work_item_id: <string>            # the picked NEW_ID (e.g., "S000036")
    work_item_dir: <string>           # the new directory path (relative to repo root)
    artifacts_written:                # list of relative paths to each written artifact
      - <path>
    validate_result: <string>         # "PASS" iff /validate reported no MISSING/DRIFT/VIOLATION
    pending_commit: <bool>            # true at scaffold time; flips to false on first /wc-implement run
    next_legal: [<string>, ...]       # phase names the user can legally invoke next; for scaffold always ["implement"]
```

**Lineage:** `receipts.investigate` is ALSO present in the new tracker's
frontmatter, copied verbatim from the source design-doc by step 7. This roots
`/wc-pipeline`'s drift-math chain back to the design-doc. Without it, the
chain has no starting node.

**Schema contract:** these field names and shapes are stable. If you need a
new field, add it; do not rename or remove existing ones without bumping the
schema version (which would require a coordinated update across all six
work-copilot prompts).

## Output contract (do not deviate)

Status tags are the grep-able surface. Match exactly:

| Tag | Meaning |
|-----|---------|
| `[scaffold-pass]` | Scaffold complete; journal entry written |
| `/wc-scaffold complete:` | One-line summary on success |
| `/wc-scaffold aborted:` | Hard-stop (validate fail, YAML parse fail, missing required frontmatter, etc.) |
| `Already scaffolded at <path>; nothing to do.` | Idempotency NO-OP message |

Do not invent new tags or restructure the receipt block.

## Parity check

The journal-entry shape and the `receipts.scaffold` schema fields are the
acceptance contract. `/wc-implement` (S000031), `/wc-qa` (S000030), and
`/wc-pipeline` (S000035) read these. If you change either, downstream prompts
will print stale diagnostics. Keep the schema locked unless you're
coordinating a downstream update across all six work-copilot prompts.

## Known limitations (V1)

- **PR-claim collision detection:** the ID picker is local-only — no `gh pr list`
  access (Copilot has no shell). Two parallel worktrees could pick the same
  `<NEW_ID>`. Mitigation: run `/wc-pipeline` post-scaffold to surface drift.
  V2 candidate: user-paste pattern for `gh pr list`.
- **Multi-story decomposition:** if the design-doc recommends decomposing a
  feature into multiple child user-stories, V1 scaffolds the feature only;
  the user re-invokes `/wc-scaffold` against follow-up design-docs (or
  hand-authored stubs with `receipts.investigate`) for each child. V2
  candidate: in-chat prompt for child slugs and a multi-pass scaffold.
- **Cross-repo scaffold:** V1 is single-repo only. The new directory always
  lands under `work-items/` in the current repo.
- **Hand-authored design-doc fallback:** the design-doc-required invariant
  accepts hand-authored stubs (no need to run `/wc-investigate` first) as long
  as the frontmatter carries `status: APPROVED`, `work_item_type: <type>`,
  and a minimal `receipts.investigate` block. Recommended minimal stub:

  ```yaml
  ---
  status: APPROVED
  work_item_type: user-story
  title: "<short title>"
  receipts:
    investigate:
      outputs:
        proposed_type: user-story
        scope_summary: "hand-authored"
  ---
  ```
