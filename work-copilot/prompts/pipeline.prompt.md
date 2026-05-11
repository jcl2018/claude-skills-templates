---
mode: agent
description: "Status compiler / drift math for a CJ_company-workflow work item or design-doc — read-only diagnostic. Parses receipts.{investigate,scaffold,implement,qa,ship} from tracker frontmatter (work-item mode) or receipts.investigate from design-doc frontmatter (design-doc mode), reads .git/HEAD via the codebase tool (no shell), computes 5 drift rules (Missing / Stale / Coverage holes / Diff audit / Ship-not-opened) plus Next Legal, prints a single fixed-format status block. Zero file writes."
tools: ['codebase', 'search', 'searchResults']
---

# /wc-pipeline

Read-only **status compiler** over CJ_company-workflow phase receipts. Reads
receipts from a work-item tracker (full multi-phase drift math) or from a
`/wc-investigate` design-doc (frontmatter state report), reads `.git/HEAD` via
the `codebase` tool, computes drift math (5 rules), and prints a single
fixed-format status block. Performs **zero file writes** — the `tools:` array
above intentionally omits any write capability to encode read-only at the
harness level.

This prompt is **build #6 (final) of the work-copilot pipeline**. It is the
**capstone** — it consumes the receipt schemas locked by `/wc-qa` (S000030),
`/wc-implement` (S000031), `/wc-scaffold` (S000032), `/wc-investigate` (S000033),
and `/wc-ship` (S000034). It does NOT lock its own schema (no `receipts.pipeline`
exists — `/wc-pipeline` is a printer, not a writer).

## Usage

```
/wc-pipeline <path>
```

- `<path>` is required — either:
  - A work-item directory (e.g. `work-items/features/F000015_pipeline/S000030_wc_qa/`) — **work-item mode**.
  - A design-doc file under `.github/work-copilot/designs/<slug>-design-<datetime>.md` — **design-doc mode**.
- If `<path>` is omitted: print the usage block above and stop.

The prompt auto-detects the input mode by inspecting the target file's
frontmatter (see step 1 below). No flag needed.

## Bundle paths (relative to repo root)

- Manifest: `.github/work-copilot/copilot-artifact-manifests.json`
- Templates: `.github/work-copilot/templates/`
- Designs (default location): `.github/work-copilot/designs/`
- Validate prompt (precedent): `.github/prompts/validate.prompt.md`
- QA prompt (schema source): `.github/prompts/qa.prompt.md`
- Implement prompt (schema source): `.github/prompts/implement.prompt.md`
- Scaffold prompt (schema source): `.github/prompts/scaffold.prompt.md`
- Investigate prompt (schema source): `.github/prompts/investigate.prompt.md`
- Ship prompt (schema source): `.github/prompts/ship.prompt.md`

**Anti-hallucination rule:** Use your file-read tool (`codebase`) to Read these
files when you need them. Do NOT recall their contents from memory. The whole
point of receipts is verifying real files against real schemas — hallucinated
rules defeat it.

## Mode

**Read-only diagnostic.** This prompt does NOT have a walkthrough conversation,
does NOT prompt for user-paste input, and does NOT have an `--auto` flag — it
just reads files and prints. The `tools:` array intentionally omits write
capability so the harness itself prevents accidental writes from a diagnostic
call.

This is the **only** work-copilot prompt without write capability in its tools array.
The status compiler MUST be a printer, not a macro. Mutations belong to the
upstream phase commands (`/wc-investigate`, `/wc-scaffold`, `/wc-implement`,
`/wc-qa`, `/wc-ship`).

## Steps

### 1. Identify input mode — work-item OR design-doc

Read the target file at `<path>` via `codebase`.

- If `<path>` is a directory: locate the `*_TRACKER.md` file inside (any file
  whose name ends in `_TRACKER.md` or equals `TRACKER.md` after stripping the
  ID prefix). If no tracker file exists, abort with:

  ```
  /wc-pipeline aborted: <path> is not a work-item directory (no *_TRACKER.md found) and does not look like a design-doc path. Provide either a work-item dir or a .github/work-copilot/designs/*.md file.
  ```

  Then parse the tracker file's YAML frontmatter (between `---` markers). If
  the frontmatter contains a `## Lifecycle` section in the body OR the
  frontmatter has a `type:` field naming one of `feature` / `user-story` /
  `task` / `defect` / `review`: **work-item mode**.

- If `<path>` is a file: read it directly. If the file path matches the pattern
  `.github/work-copilot/designs/<slug>-design-<datetime>.md` OR the frontmatter
  contains a `generated_by: /wc-investigate` field: **design-doc mode**.

- **If YAML parse fails (either mode):** abort with:

  ```
  /wc-pipeline aborted: frontmatter could not be parsed at <path> — fix manually before re-invoking.
  ```

  Do NOT proceed to drift math.

Mode-discriminator rule (per AC-2): the file has a `## Lifecycle` section →
tracker (work-item mode); the file is under `.github/work-copilot/designs/`
OR has `generated_by: /wc-investigate` → design-doc mode. If both signals are
absent, abort with the same "not a work-item directory" message above.

Capture the work-item ID from the tracker filename (e.g., `S000035` from
`S000035_TRACKER.md`) as `<WORK_ITEM_ID>` in work-item mode. In design-doc
mode, capture the slug from the filename (e.g., `webhook-retry-queue` from
`webhook-retry-queue-design-20260511-095218.md`) as `<DESIGN_SLUG>`.

### 2. Read receipts

#### 2.work-item — read all 5 receipt blocks

From the parsed tracker frontmatter, read these receipts (all may be missing —
the prompt is resilient to each absence; missing receipts feed the Missing
drift rule in step 4):

- `<receipts_investigate>` = `receipts.investigate` (or `null` if missing)
- `<receipts_scaffold>` = `receipts.scaffold` (or `null` if missing)
- `<receipts_implement>` = `receipts.implement` (or `null` if missing)
- `<receipts_qa>` = `receipts.qa` (or `null` if missing)
- `<receipts_ship>` = `receipts.ship` (or `null` if missing)

For each present receipt, capture its `completed_at` timestamp (string, ISO-8601
UTC). The `completed_at` will appear in the status block per phase.

#### 2.design-doc — read receipts.investigate only

From the parsed design-doc frontmatter, read these fields:

- `<status>` = `status:` (typical values: `DRAFT`, `APPROVED`, `SCAFFOLDED`)
- `<work_item_type>` = `work_item_type:` (one of feature/user-story/task/defect/review)
- `<scaffolded_to>` = `scaffolded_to:` (path to scaffolded work-item dir, or `null`)
- `<receipts_investigate>` = `receipts.investigate`

In design-doc mode, only `receipts.investigate` exists (no tracker → no
scaffold/implement/qa/ship receipts yet). The drift math in step 4 is
simplified: report design-doc state + next legal.

### 3. Read .git/HEAD via the codebase tool — extract current SHA

Read the file `<repo-root>/.git/HEAD` via the `codebase` tool. This is a plain
file read — no shell needed. Per AC-4, `.git/HEAD` has two possible shapes:

1. **Symbolic ref form** (typical when on a branch): the file contents are a
   single line `ref: refs/heads/<branch-name>\n`. In this case, read the
   referenced file at `<repo-root>/.git/refs/heads/<branch-name>` via the
   `codebase` tool — the content is a 40-character hex SHA on a single line.

2. **Detached HEAD form** (less typical): the file contents are a 40-character
   hex SHA directly on a single line (no `ref:` prefix).

Capture the SHA as `<current_sha>` (40-character hex, lowercase). If the read
fails (`.git/HEAD` not found via `codebase`, or the symbolic ref points at a
missing file), record `<current_sha> = null` and proceed — the Stale rule
(step 4.stale) gracefully degrades to "stale check unavailable (.git/HEAD
unreadable)".

**Why this works without shell:** the `codebase` tool can read any file the
agent has read access to, including dotfiles under `.git/`. `git log` is NOT
available (it requires shell); the binary stale signal (HEAD matches OR moved)
is the only available comparison.

### 4. Drift math — 5 rules + design-doc shape

#### 4.work-item — full 5-rule drift math

Apply each rule below to the receipts read in step 2.work-item.

##### 4.missing — receipt absence

For each receipt in `[scaffold, implement, qa, ship]` that is `null` (absent
from frontmatter):

- Mark the phase as `? <phase> (not yet run)` in the status block.

`investigate` is excluded from the Missing check — it is the root of the chain
and may legitimately be absent in trackers that were hand-authored without
going through `/wc-investigate`. (V1 design — hand-authored trackers are a
valid path; see scaffold.prompt.md "Hand-authored design-doc fallback".)

If `receipts.scaffold` is also absent, the chain has no root; tag the missing
line with `(chain broken — no scaffold receipt; re-scaffold via /wc-scaffold or hand-author a receipts.scaffold block)`.

##### 4.stale — binary HEAD compare (per AC-6)

This is the load-bearing tradeoff for /wc-pipeline. The check is **binary** —
HEAD matches `receipts.implement.latest_sha_at_implement` OR it has moved.
**No commit count.** Counting commits would require `git log`, which requires
shell, which Copilot does not have.

- If `receipts.implement` is absent: skip the stale check entirely (no SHA to
  compare against; the Missing rule already flagged implement).
- If `<current_sha>` is `null` (step 3 failed): print
  `STALE: stale check unavailable (.git/HEAD unreadable)` and continue.
- If `<current_sha> == receipts.implement.latest_sha_at_implement` (string
  equality, case-insensitive 40-char hex compare):

  ```
  STALE: HEAD matches receipts.implement.latest_sha_at_implement — no drift.
  ```

- Otherwise (SHAs differ):

  ```
  STALE: HEAD has moved past receipts.implement.latest_sha_at_implement — code/doc desync possible; re-run /wc-implement to refresh the receipt.
         For exact count, run: git log <receipts.implement.latest_sha_at_implement>..HEAD --oneline | wc -l
  ```

The `For exact count, run:` line is the **user-paste-as-documentation** pattern
(per AC-14 / DESIGN big decision #1). The prompt cannot compute the count
itself, but it tells the user the exact command they can paste into their own
terminal for a number.

##### 4.coverage — uncovered ACs (per AC-7)

- If `receipts.qa` is absent: skip the coverage check (Missing rule already
  flagged qa).
- If `receipts.qa.ac_ids_uncovered` is empty (`[]`): print
  `COVERAGE: no uncovered ACs.`
- If `receipts.qa.ac_ids_uncovered` is non-empty: print one line per uncovered
  AC ID:

  ```
  COVERAGE:
    - <AC-ID> has no test row; re-enter /wc-implement or add row to TEST-SPEC.
    - <AC-ID> has no test row; re-enter /wc-implement or add row to TEST-SPEC.
    ...
  ```

##### 4.diff-audit — changed files without test coverage (per AC-8)

- If `receipts.qa` is absent: skip the diff audit (Missing rule already flagged
  qa).
- If `receipts.qa.diff_audit.changed_files_without_tests` is empty (`[]`):
  print `DIFF AUDIT: no changed files without test coverage.`
- If `receipts.qa.diff_audit.changed_files_without_tests` is non-empty: print
  one line per file path:

  ```
  DIFF AUDIT:
    - <file path> changed since last [qa-*] entry — has no checklist coverage; /wc-qa re-entry recommended.
    - <file path> changed since last [qa-*] entry — has no checklist coverage; /wc-qa re-entry recommended.
    ...
  ```

##### 4.ship-not-opened — pr_opened false + 24h timeout (per AC-9)

This rule keys on `receipts.ship.pr_opened` (NOT `receipts.ship.pr_url`).
Reasoning: the user could paste a URL into `pr_url` and forget to flip
`pr_opened`, or vice versa. `pr_opened` is the canonical truth (per S000034 /
ship.prompt.md schema contract).

- If `receipts.ship` is absent: skip the rule (Missing rule already flagged
  ship).
- If `receipts.ship.pr_opened == true`: print `SHIP-NOT-OPENED: n/a (pr_opened == true).`
- If `receipts.ship.pr_opened == false` AND `receipts.ship.completed_at` is
  within the last 24 hours from now (compare ISO-8601 timestamps): print
  `SHIP-NOT-OPENED: n/a (within 24h grace window).`
- If `receipts.ship.pr_opened == false` AND `receipts.ship.completed_at` is
  older than 24 hours from now:

  ```
  SHIP-NOT-OPENED: /wc-ship printed a PR description but no PR was opened yet (completed_at: <ts>, >24h ago) — re-run /wc-ship or open PR manually on GitHub and flip receipts.ship.pr_opened: true.
  ```

The 24-hour threshold is hardcoded in V1 (per DESIGN big decision #3). V2
candidate: env var or per-repo config.

**Tolerating review-type degenerate receipts** (per AC-12): when the tracker's
`type: review`, the upstream `/wc-implement` (S000031) writes `receipts.implement`
with empty arrays (`files_touched: []`, `commits_since_scaffold: []`,
`ac_ids_targeted: []`, `open_risks: ["<one-line summary>"]`). These empty
arrays are a **valid completion state**, NOT drift. The drift rules above
naturally produce no output on empty arrays (the coverage and diff-audit checks
are gated on non-empty arrays; the stale check still applies but only if
`receipts.implement.latest_sha_at_implement` is set). Print the review
work-item's implement phase as ✓ in the status block (not ✗), even though the
arrays are empty.

##### 4.next-legal — union of receipts' next_legal minus completed phases (per AC-10)

Compute the set:

```
ALL_NEXT_LEGAL = union of receipts.{investigate,scaffold,implement,qa,ship}.next_legal (per receipt present)
COMPLETED_PHASES = { phase name | receipts.<phase> is non-null AND no drift signal blocks it }
NEXT_LEGAL = ALL_NEXT_LEGAL minus COMPLETED_PHASES
```

Special cases:

- If all 5 receipts are present AND no drift signals fire: `NEXT_LEGAL = []`
  (the work-item is done; print `NEXT LEGAL: (none — work-item complete)`).
- If `receipts.ship.pr_opened == false` AND >24h: `NEXT_LEGAL` always
  includes `ship` even if it appears completed (the ship-not-opened drift
  signal forces a re-run / manual open).
- If the Stale rule fired: `NEXT_LEGAL` always includes `implement` (code/doc
  desync forces re-implement to refresh the receipt).
- If the Coverage or Diff Audit rules fired: `NEXT_LEGAL` always includes
  `qa` (uncovered ACs / unaudited files force a /wc-qa re-entry).

Print:

```
NEXT LEGAL: <comma-separated phase names> OR (none — work-item complete)
```

`/wc-pipeline` itself is always legal (it's read-only) but is NOT listed in
`NEXT LEGAL` — that field enumerates write-phase successors only.

#### 4.design-doc — frontmatter state report (no drift math)

Design-docs don't have a tracker yet, so the multi-phase drift math doesn't
apply. Instead, report the design-doc's state:

- **`status: DRAFT`** — investigate not yet complete (or aborted). Print
  `DESIGN-DOC STATE: DRAFT (in-progress investigation; receipts.investigate present)`.
- **`status: APPROVED`** — investigate complete, awaiting scaffold. Print
  `DESIGN-DOC STATE: APPROVED (awaiting /wc-scaffold)`.
- **`status: SCAFFOLDED`** — already scaffolded. Print
  `DESIGN-DOC STATE: SCAFFOLDED → <scaffolded_to>`.
  - **If `scaffolded_to` points at a non-existent dir** (read any file under
    that path via codebase; if the directory has no readable files, treat as
    missing): print
    `DESIGN-DOC STATE: SCAFFOLDED → <scaffolded_to> (NOT FOUND — work-item may have been moved or deleted; re-run /wc-scaffold OR fix the link)`.
    (Per SPEC Open Questions #2; confirmed during exercise.)

`NEXT LEGAL` in design-doc mode is computed from `receipts.investigate.next_legal`
alone:

- `DRAFT`: `NEXT LEGAL: investigate (continue or abort)`. (V1 has no "resume
  investigation" path; the user re-invokes `/wc-investigate` on the same topic;
  collision-avoidance suffix `-2` applies if needed.)
- `APPROVED`: `NEXT LEGAL: scaffold`.
- `SCAFFOLDED` (and `scaffolded_to` exists): `NEXT LEGAL: pipeline <scaffolded_to>`
  (i.e., switch to work-item mode on the scaffolded path for full drift math).
- `SCAFFOLDED` (and `scaffolded_to` missing or stale): `NEXT LEGAL: scaffold`
  (re-scaffold to fix the link).

### 5. Print status block

Print one fixed-format status block per AC-11. Two shapes — work-item mode and
design-doc mode.

#### 5.work-item — full block

```
WORK-ITEM: <WORK_ITEM_ID>_<slug>
──────────────────────────────────
<phase symbol> investigate    (<completed_at OR "not yet run">)
<phase symbol> scaffold       (<completed_at OR "not yet run">)
<phase symbol> implement      (<completed_at OR "not yet run">) HEAD: <latest_sha_at_implement[:7] OR "—"> → current: <current_sha[:7] OR "—"> (<MATCHES|MOVED|—>)
<phase symbol> qa             (<completed_at OR "not yet run">) <one-line coverage/diff summary OR "">
<phase symbol> ship           (<completed_at OR "not yet run">) <"pr_opened: true|false">
──────────────────────────────────
STALE: <stale-message OR "no drift">
       For exact count, run: git log <sha>..HEAD --oneline | wc -l
       (only included when STALE fired)
COVERAGE: <coverage holes lines OR "no uncovered ACs">
DIFF AUDIT: <changed-without-tests lines OR "no changed files without test coverage">
SHIP-NOT-OPENED: <message OR "n/a (...)">
──────────────────────────────────
NEXT LEGAL: <comma-separated phases OR "(none — work-item complete)">

/wc-pipeline summary: <N>/5 phases complete; <D> drift signals; next /wc-<phase> (or "complete").
```

**Phase symbol mapping** (per AC-11):

- `✓` (check mark) — receipt present AND no drift signal blocks the phase.
- `✗` (X mark) — receipt present BUT a drift signal blocks it (coverage holes,
  diff audit, stale, ship-not-opened).
- `?` (question mark) — receipt absent (phase not yet run).

The `<slug>` portion of the WORK-ITEM header is derived from the work-item
directory basename (e.g., `S000035_wc_pipeline` → `wc_pipeline`). If the
directory basename doesn't follow the `<ID>_<slug>` shape (e.g.,
`work-items/features/F000004_work_copilot/`), fall back to the directory
basename verbatim.

The final `/wc-pipeline summary:` line (per AC-15) is the one-line scan
signal. `<N>/5` counts non-null receipts (out of investigate/scaffold/implement/
qa/ship = 5 total). `<D>` counts fired drift signals (Stale, Coverage, Diff
Audit, Ship-not-opened — Missing is NOT counted; it's the absence). `<phase>`
is the first item from NEXT LEGAL, or "complete" if NEXT LEGAL is empty.

#### 5.design-doc — frontmatter state block

```
DESIGN-DOC: <DESIGN_SLUG>
──────────────────────────────────
✓ investigate    (<completed_at>)
? scaffold       (not yet run)
? implement      (not yet run)
? qa             (not yet run)
? ship           (not yet run)
──────────────────────────────────
DESIGN-DOC STATE: <DRAFT|APPROVED|SCAFFOLDED → <path>|SCAFFOLDED → <path> (NOT FOUND)>
──────────────────────────────────
NEXT LEGAL: <see step 4.design-doc>

/wc-pipeline summary: 1/5 phases complete; design-doc <status>; next /wc-<phase>.
```

In design-doc mode, `<N>/5` is always `1/5` (only investigate is present) for
`DRAFT` / `APPROVED`. For `SCAFFOLDED`, the user should re-invoke
`/wc-pipeline` on the `scaffolded_to` path for the full multi-phase block.

### 6. Schema-mismatch resilience (per AC-13)

If a receipt has a recognizable shape mismatch (e.g.,
`receipts.implement.latest_sha_at_implement` is set but is not a 40-character
hex string; `receipts.qa.ac_ids_uncovered` is set but is not a list; etc.),
print:

```
receipt schema mismatch in receipts.<phase> at <field> — upgrade /wc-pipeline or fix manually.
```

…and continue. Print the rest of the status block for other phases (partial
output is better than no output). The phase with the mismatch is shown with
the `✗` symbol and a parenthesized `(schema mismatch)` annotation.

V1 does NOT support versioned schema headers. If a future receipt schema
drifts incompatibly, the user upgrades `/wc-pipeline` (a coordinated PR across
all six work-copilot prompts) or hand-fixes the receipt.

## Receipt schema (READS — does not write)

`/wc-pipeline` reads but does not write. The schemas below are the contract
locked by S000030–S000034. If any field shape changes upstream, this prompt
must be updated in the same PR (see "Parity check" below).

```yaml
# Written by /wc-investigate (S000033) — in design-doc frontmatter
receipts:
  investigate:
    phase: 0
    completed_at: <ISO-8601 UTC>
    design_doc: <string>
    inputs_read: [<path>, ...]
    outputs:
      proposed_type: <string>
      scope_summary: <string>
    next_legal: [<string>, ...]

# Written by /wc-scaffold (S000032) — in tracker frontmatter
receipts:
  scaffold:
    phase: 1
    completed_at: <ISO-8601 UTC>
    work_item_id: <string>
    work_item_dir: <string>
    artifacts_written: [<path>, ...]
    validate_result: <string>
    pending_commit: <bool>
    next_legal: [<string>, ...]

# Written by /wc-implement (S000031) — in tracker frontmatter
receipts:
  implement:
    phase: 2
    completed_at: <ISO-8601 UTC>
    latest_sha_at_implement: <40-char SHA>
    commits_since_scaffold: [<short SHA>, ...]
    files_touched: [<path>, ...]
    ac_ids_targeted: [<string>, ...]
    open_risks: [<string>, ...]
    next_legal: [<string>, ...]

# Written by /wc-qa (S000030) — in tracker frontmatter
receipts:
  qa:
    phase: 3
    completed_at: <ISO-8601 UTC>
    test_rows_run: <int>
    ac_ids_covered: [<string>, ...]
    ac_ids_uncovered: [<string>, ...]
    diff_audit:
      changed_files_without_tests: [<path>, ...]
    journal_entries: [<string>, ...]
    ready_for_ship: <bool>
    next_legal: [<string>, ...]

# Written by /wc-ship (S000034) — in tracker frontmatter
receipts:
  ship:
    phase: 4
    completed_at: <ISO-8601 UTC>
    pr_description_synthesized_from: [<string>, ...]
    pr_description_file_written: <bool>
    pr_url: <string|null>
    pr_opened: <bool>
    next_legal: [<string>, ...]
```

**`pr_opened` is the canonical truth, NOT `pr_url`** (per S000034 schema
contract). The Ship-not-opened drift rule reads `pr_opened`.

**Review-type degenerate shape** (per S000031): `receipts.implement` with
empty `files_touched`, `commits_since_scaffold`, `ac_ids_targeted` is a valid
completion state for `type: review` work-items. `/wc-pipeline` tolerates these
empty arrays — they do NOT fire the Coverage or Diff Audit rules (those are
gated on the qa receipt's arrays, not implement's).

## Output contract (do not deviate)

Status tags are the grep-able surface. Match exactly:

| Tag | Meaning |
|-----|---------|
| `WORK-ITEM:` | Status block header in work-item mode |
| `DESIGN-DOC:` | Status block header in design-doc mode |
| `STALE:` | Stale rule output line |
| `COVERAGE:` | Coverage rule output line |
| `DIFF AUDIT:` | Diff audit rule output line |
| `SHIP-NOT-OPENED:` | Ship-not-opened rule output line |
| `NEXT LEGAL:` | Next legal phases line |
| `DESIGN-DOC STATE:` | Design-doc state line (design-doc mode only) |
| `/wc-pipeline summary:` | Final one-line summary |
| `/wc-pipeline aborted:` | Hard-stop (frontmatter parse fail, not a work-item dir, etc.) |
| `receipt schema mismatch in receipts.<phase>` | Schema-mismatch resilience line (AC-13) |
| `For exact count, run: git log` | User-paste-as-documentation hint (only after STALE fires) |

Do not invent new tags, restructure the status block, or attempt to write
receipts (`/wc-pipeline` has no write tool — any attempted write fails at
the harness level).

## Parity check

`/wc-pipeline` reads the schemas locked by S000030–S000034. If any upstream
schema field is renamed, removed, or shape-changed, this prompt will print
stale diagnostics. Keep the prompt updated in the SAME PR as the upstream
schema change (a coordinated update across all six work-copilot prompts).

Specific dependencies:

- `receipts.investigate.next_legal` — drives design-doc mode's NEXT LEGAL.
- `receipts.scaffold` presence/absence — Missing rule + chain-root check.
- `receipts.implement.latest_sha_at_implement` — Stale rule input.
- `receipts.implement.files_touched`, `commits_since_scaffold`, `ac_ids_targeted` —
  emptiness tolerated for `type: review`.
- `receipts.qa.ac_ids_uncovered` — Coverage rule input.
- `receipts.qa.diff_audit.changed_files_without_tests` — Diff audit rule input.
- `receipts.ship.pr_opened` — Ship-not-opened rule input (canonical, NOT
  `pr_url`).
- `receipts.ship.completed_at` — Ship-not-opened 24h threshold input.

## Known limitations (V1)

- **Binary stale check only** (no commit count): `git log` requires shell;
  `/wc-pipeline` reads `.git/HEAD` via `codebase` (string compare). The user
  can paste `git log <sha>..HEAD --oneline | wc -l` themselves for a count —
  the prompt prints the exact command as a hint when STALE fires.
- **24h ship-not-opened threshold is hardcoded.** V2 candidate: env var or
  per-repo config.
- **No multi-work-item rollup.** V1 prints one status block per invocation. A
  feature with 6 children needs 6 separate `/wc-pipeline` calls; V2 candidate
  for cross-work-item / cross-feature rollup reports.
- **No trend tracking** (drift over time). V2 candidate.
- **No color codes** in the ASCII status block. V1 plain text only; Copilot
  Chat renders markdown but color may not work consistently. V2 candidate.
- **No "resume investigation" path** in design-doc mode for `status: DRAFT` —
  V1 re-invokes `/wc-investigate` on the same topic; collision-avoidance suffix
  `-2` applies if needed. V2 candidate: detect partial draft and offer resume
  (per S000033 SPEC #11).
- **Schema-version mismatch** (AC-13) emits a clean error message and continues
  with partial output. V2 candidate: versioned schema header for graceful
  multi-version support.
