---
name: CJ_document-release
description: "Workbench wrapper around upstream /document-release. Adds a --docs <comma-list> subset flag for per-invocation doc filtering (best-effort, documentation-only), a halt-on-red contract that emits [doc-sync-red] on upstream failure, and an auto-commit step gated by a conservative doc-only whitelist (non-whitelist writes HALT with [doc-sync-non-doc-write]). Invoked inline by the 3 cj_goal orchestrators (CJ_goal_feature / CJ_goal_defect / CJ_goal_todo_fix) at Step 5.5 — between QA pass and /ship — so doc updates fold into the same code PR. F000036 closes the F000028+F000029 marker-AUQ drift window for orchestrator-driven paths; F000029's marker-AUQ stays as fallback for non-orchestrator paths."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Skill
---

## Preamble

Check for collection updates (silent if none, banner if newer):

```bash
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: print `Error: /CJ_document-release requires a git repository.` and stop.

## Overview

`/CJ_document-release` is a thin workbench wrapper around upstream gstack
`/document-release`. It adds three workbench-specific concerns that the
orchestrator family needs:

1. **`--docs <comma-list>` per-invocation doc subset.** Operator can scope an
   invocation to a subset of doc categories (e.g. `--docs README` or
   `--docs README,CHANGELOG`). The subset is a documentation-only signal to
   `/document-release` via the project-context block; it is best-effort, not
   enforced (the workbench skill does NOT reach into upstream to gate which
   audits fire). Case-insensitive parsing; whitespace trimmed; unknown values
   warn-and-skip; empty subset = full audit; the literal `all` is an explicit
   no-filter token.

2. **Halt-on-red contract.** If `/document-release` returns non-green (audit
   error, mid-write failure, hard-abort), the wrapper emits `[doc-sync-red]`
   to the caller (an orchestrator) and exits non-green. The orchestrator HALTs
   with `halt class = halted_at_doc_sync`. This is a hard halt, not a warning.

3. **Doc-only auto-commit (whitelist gate).** After a green `/document-release`,
   the wrapper inspects the working tree and auto-commits doc-only changes so
   `/ship` (the next pipeline step) sees a clean tree. The whitelist is loaded
   from `cj-document-release.json` at the repo root (F000037 strict-required):

   ```json
   {
     "schema_version": 1,
     "whitelist_patterns": ["README.md", "doc/**/*.md", ...],
     "categories": { "readme": ["README.md"], ... }
   }
   ```

   If any non-whitelist file is dirty after `/document-release` runs, the
   wrapper refuses to auto-commit and HALTs with `[doc-sync-non-doc-write]`
   (halt class `halted_at_doc_sync_non_doc_write`). Stealth code edits via the
   doc-sync surface are a serious surface; the conservative whitelist closes
   that door without an operator-override. If `cj-document-release.json` is
   missing/invalid/schema_version-unsupported, the wrapper HALTs with
   `[doc-sync-no-config]` BEFORE any audit runs.

The orchestrator invocation shape:

```
(orchestrator session)
       │
       ▼
... QA passes green (Step 5) ...
       │
       ▼
Skill(CJ_document-release)         ← THIS SKILL (no --docs in v1 orchestrator wiring)
       │
       ├── arg parse: --docs <list>
       ├── branch + clean-tree gate
       ├── project-context block (doc-only signal)
       ├── Skill(/document-release) ─→ upstream gstack (NOT MODIFIED)
       ├── halt-on-red [doc-sync-red] (RESULT=red)
       ├── auto-commit doc-only (whitelist gate) [doc-sync-non-doc-write]
       └── success summary (RESULT=green or RESULT=green-noop)
       │
       ▼
/ship (Step 6)                     ← clean-tree precondition NOW satisfied
       │
       ▼
PR includes BOTH code + doc commits
```

## Usage

```
/CJ_document-release                                 # full audit
/CJ_document-release --docs README                   # README-only filter
/CJ_document-release --docs README,CHANGELOG         # multi-doc filter
/CJ_document-release --docs all                      # explicit full-audit token
```

`--docs` parsing is case-insensitive (`--docs readme`, `--docs README`, and
`--docs Readme` are equivalent). Whitespace inside the comma list is trimmed
(`--docs "README, CHANGELOG"` is accepted). Unknown values warn-and-skip
(`--docs README,UNKNOWN_DOC` audits README only and prints a one-line warn
for `UNKNOWN_DOC`). Empty subset (no flag, or `--docs ""`) is a full audit.

## Step 0.5: Read config (F000037 strict-required)

Before any audit runs, validate the per-repo config at `cj-document-release.json`
via the helper script. The helper exits 1 + emits `[doc-sync-no-config] <reason>`
when the file is missing / invalid JSON / schema_version-unsupported / required
fields missing. The wrapper HALTs immediately on non-zero exit — no fallback to
hardcoded defaults.

```bash
CONFIG_OUT=$(bash scripts/cj-document-release-config.sh --validate 2>&1)
CONFIG_RC=$?
if [ "$CONFIG_RC" -ne 0 ]; then
  # Helper already emitted [doc-sync-no-config] <reason>; pass it through
  # verbatim so the orchestrator's halt-class detector matches.
  echo "$CONFIG_OUT"
  echo "RESULT: red; HALT_MARKER=[doc-sync-no-config]"
  echo "next_action=author or repair cj-document-release.json at repo root; copy the workbench's seed JSON as a starting point; re-run /CJ_document-release"
  echo "resume_cmd=/CJ_document-release${DOCS_SUBSET:+ --docs $DOCS_SUBSET}"
  echo "pr_url=N/A"
  exit 1
fi
```

The helper supports four subcommands the rest of this skill consumes:

- `--parse` — pretty-print the JSON (debug/inspection).
- `--expand-whitelist` — emit the expanded whitelist file list (globs resolved
  against the working tree; sorted, unique). Step 2 + Step 6 use this.
- `--resolve <token>` — emit the file list for one category. Step 4 uses this
  when `--docs <token>` is set.
- `--validate` — exit 0 if schema is OK; exit 1 + halt-emit otherwise.

## Step 1: Parse arguments

Parse the optional `--docs <comma-list>` flag (case-insensitive; whitespace
trimmed; resolved against the config's `categories` map at Step 4):

```bash
DOCS_RAW=""
ARGS=()
i=1
while [ $i -le $# ]; do
  arg="${!i}"
  case "$arg" in
    --docs)
      i=$((i+1))
      DOCS_RAW="${!i}"
      ;;
    --docs=*)
      DOCS_RAW="${arg#--docs=}"
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
  i=$((i+1))
done

# Normalize: lowercase + strip whitespace + dedupe
DOCS_SUBSET=""
if [ -n "$DOCS_RAW" ]; then
  DOCS_SUBSET=$(printf '%s' "$DOCS_RAW" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -d ' \t' \
    | tr ',' '\n' \
    | grep -v '^$' \
    | sort -u \
    | paste -sd ',' -)
fi

# 'all' is the explicit no-filter token
if [ "$DOCS_SUBSET" = "all" ]; then
  DOCS_SUBSET=""
fi
```

The set of known `--docs` tokens is no longer hardcoded — it is whatever the
repo's `cj-document-release.json` declares under `categories` (F000037
strict-required). Step 4 resolves each requested token via
`bash scripts/cj-document-release-config.sh --resolve <token>`; tokens NOT
declared in `categories` cause the helper to exit 1 with `[doc-sync-no-config]`,
which the wrapper passes through verbatim. The workbench's bundled JSON seeds
the F000036-compat set (`readme`, `changelog`, `claude`, `architecture`,
`philosophy`, `skill-catalog`) so day-1 behavior is unchanged; other repos
adopting `/CJ_document-release` declare their own categories. Upstream
`/document-release` still decides what to actually audit — the filter is
best-effort communication of operator intent via the project-context block.

## Step 2: Branch + clean-tree gate

Upstream `/document-release` refuses on the base branch (it hard-aborts on
main with "You're on the base branch. Run from a feature branch."). Mirror
that refusal here as a pre-flight check so the wrapper fails fast rather than
spending a Skill call:

```bash
_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
case "$_BRANCH" in
  main|master|trunk|develop|base)
    echo "CJ_document-release: refuses on the base branch '$_BRANCH' — /document-release hard-aborts on main. Run from a feature branch."
    echo "RESULT: red; HALT_MARKER=[doc-sync-red]; reason=refuses on the base branch"
    exit 1
    ;;
esac
```

Clean-tree gate: `/document-release` itself writes doc files. The wrapper
refuses if the working tree already has uncommitted NON-DOC changes (those
must commit first; doc-only dirtiness is OK because the wrapper will
auto-commit it later). The doc-only set is derived from the helper-expanded
whitelist (F000037), not a hardcoded regex:

```bash
# Build doc-only file set from the config's whitelist_patterns (F000037).
DOC_WHITELIST_SET=$(bash scripts/cj-document-release-config.sh --expand-whitelist)

# Inspect uncommitted files; refuse if any are NOT in the whitelist set.
DIRTY_FILES=$(git status --porcelain 2>/dev/null | awk '{print $2}')
NON_DOC_DIRTY=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if ! printf '%s\n' "$DOC_WHITELIST_SET" | grep -qFx "$f"; then
    NON_DOC_DIRTY="$NON_DOC_DIRTY$f"$'\n'
  fi
done <<< "$DIRTY_FILES"
NON_DOC_DIRTY=$(printf '%s' "$NON_DOC_DIRTY" | head -5)

if [ -n "$NON_DOC_DIRTY" ]; then
  echo "CJ_document-release: Working tree has uncommitted non-doc changes — refusing to run /document-release on top of them."
  echo "Non-doc dirty files (first 5):"
  echo "$NON_DOC_DIRTY"
  echo "Recovery: commit or stash the non-doc changes first; then re-run /CJ_document-release."
  echo "RESULT: red; HALT_MARKER=[doc-sync-red]; reason=non-doc dirty tree pre-run"
  exit 1
fi
```

## Step 3: Build the project-context block

The block is a documentation-only signal to `/document-release` that this run
is filtered (or unfiltered). Upstream may honor the filter or audit
everything — both outcomes are fine; the wrapper auto-commits whatever
upstream produces (gated by the whitelist).

When `--docs <token>` is set, the wrapper resolves each token to a concrete
file list via `bash scripts/cj-document-release-config.sh --resolve <token>`.
A token NOT declared in the JSON's `categories` map causes the helper to exit
1 with `[doc-sync-no-config]` — the wrapper passes that through verbatim
(F000037 strict-required posture; no warn-and-skip fallback for unknown
tokens).

```bash
AUDIT_FILES=""
if [ -n "$DOCS_SUBSET" ]; then
  # Resolve each comma-separated token via the helper.
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    RESOLVED=$(bash scripts/cj-document-release-config.sh --resolve "$token" 2>&1)
    RC=$?
    if [ "$RC" -ne 0 ]; then
      echo "$RESOLVED"
      echo "RESULT: red; HALT_MARKER=[doc-sync-no-config]"
      echo "next_action=declare token '$token' in cj-document-release.json categories, or use a different --docs token"
      echo "resume_cmd=/CJ_document-release --docs $DOCS_SUBSET"
      echo "pr_url=N/A"
      exit 1
    fi
    AUDIT_FILES="$AUDIT_FILES$RESOLVED"$'\n'
  done < <(printf '%s' "$DOCS_SUBSET" | tr ',' '\n')
  AUDIT_FILES=$(printf '%s' "$AUDIT_FILES" | sort -u | grep -v '^$' || true)
  CONTEXT_BLOCK="CJ_document-release: running with --docs filter = '$DOCS_SUBSET'.
This invocation should audit only the following files (resolved via cj-document-release.json):
$AUDIT_FILES
The filter is best-effort communication of operator intent — upstream behavior
is authoritative."
else
  CONTEXT_BLOCK="CJ_document-release: running with no --docs filter (full audit)."
fi
```

## Step 4: Invoke upstream /document-release via the Skill tool

Invoke `Skill(skill="document-release")` with the project-context block as
guidance. The wrapper does NOT pass any flags to upstream (`--docs` is
documentation-only and not an upstream-supported flag):

```
Skill: document-release
  (project-context block from Step 3)
```

Capture the upstream verdict. The Skill tool returns once `/document-release`
finishes; the wrapper reads the result as green or red.

## Step 5: Halt-on-red ([doc-sync-red])

If upstream returned non-green (audit error, mid-write failure, hard-abort,
crashed, exceeded budget): emit a halt marker and exit RESULT=red:

```bash
# Pseudocode: the Skill-tool result is interpreted by the orchestrator/agent.
# When upstream returns non-green:
echo "CJ_document-release: upstream /document-release returned non-green; halting."
echo "RESULT: red; HALT_MARKER=[doc-sync-red]"
echo "next_action=inspect /document-release output; fix doc errors; re-run /CJ_document-release"
echo "resume_cmd=/CJ_document-release${DOCS_SUBSET:+ --docs $DOCS_SUBSET}"
echo "pr_url=N/A"
exit 1
```

## Step 6: Auto-commit doc-only (whitelist gate; [doc-sync-non-doc-write])

After a green `/document-release`, inspect the working tree. If any dirty
file is OUTSIDE the doc-only whitelist, refuse to auto-commit and HALT — this
is the upstream-misbehaved case (or an unexpected stealth-write surface).
The whitelist set comes from `bash scripts/cj-document-release-config.sh
--expand-whitelist` (F000037; reuses Step 2's expansion):

```bash
DOC_WHITELIST_SET=$(bash scripts/cj-document-release-config.sh --expand-whitelist)
DIRTY=$(git status --porcelain 2>/dev/null | awk '{print $2}' | grep -v '^$')

DOC_DIRTY=""
NON_DOC_DIRTY=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if printf '%s\n' "$DOC_WHITELIST_SET" | grep -qFx "$f"; then
    DOC_DIRTY="$DOC_DIRTY$f"$'\n'
  else
    NON_DOC_DIRTY="$NON_DOC_DIRTY$f"$'\n'
  fi
done <<< "$DIRTY"
DOC_DIRTY=$(printf '%s' "$DOC_DIRTY" | grep -v '^$' || true)
NON_DOC_DIRTY=$(printf '%s' "$NON_DOC_DIRTY" | grep -v '^$' || true)

if [ -n "$NON_DOC_DIRTY" ]; then
  echo "CJ_document-release: upstream wrote files outside the doc-only whitelist — refusing to auto-commit."
  echo "Non-doc dirty files:"
  echo "$NON_DOC_DIRTY"
  echo "RESULT: red; HALT_MARKER=[doc-sync-non-doc-write]"
  echo "next_action=inspect uncommitted non-doc files; revert if unexpected; re-run /CJ_document-release"
  echo "resume_cmd=/CJ_document-release${DOCS_SUBSET:+ --docs $DOCS_SUBSET}"
  echo "pr_url=N/A"
  echo "non_doc_files=$(printf '%s' "$NON_DOC_DIRTY" | tr '\n' ',' | sed 's/,$//')"
  exit 1
fi

# Green path: doc-only changes (or none)
if [ -n "$DOC_DIRTY" ]; then
  printf '%s\n' "$DOC_DIRTY" | xargs git add
  git commit -m "docs: post-build sync via CJ_document-release${DOCS_SUBSET:+ (--docs $DOCS_SUBSET)}"
  COMMIT_SHA=$(git rev-parse --short HEAD)
  echo "CJ_document-release: committed doc-only changes at $COMMIT_SHA"
  echo "RESULT: green; doc_commit=$COMMIT_SHA; filtered=${DOCS_SUBSET:-full}"
else
  echo "CJ_document-release: no doc changes needed (green-noop)"
  echo "RESULT: green-noop; doc_commit=none; filtered=${DOCS_SUBSET:-full}"
fi
```

## Step 7: Success summary

Print a single-line success summary the orchestrator can grep:

```
CJ_document-release: <green|green-noop> / /document-release: green / commit: <sha-or-none> / filtered: <subset-or-full>
```

The orchestrator's Step 5.5 reads:
- `RESULT: green` → continue to `/ship`. Doc commit was made; `/ship` opens
  one PR containing both code + doc updates.
- `RESULT: green-noop` → continue to `/ship`. No doc commit needed; `/ship`
  opens a code-only PR.
- `RESULT: red` → HALT with the corresponding marker. The orchestrator
  writes a journal entry and exits with the halt class.

## Halt-marker shape (machine-readable, mirrors F000027 family contract)

```
RESULT: red; HALT_MARKER=[doc-sync-red]
next_action=<one-line>
resume_cmd=/CJ_document-release [--docs <same-subset>]
pr_url=N/A
raw_output_path=<path-from-document-release-or-N/A>
```

```
RESULT: red; HALT_MARKER=[doc-sync-non-doc-write]
next_action=inspect uncommitted non-doc files; revert if unexpected; re-run
resume_cmd=/CJ_document-release [--docs <same-subset>]
pr_url=N/A
non_doc_files=<comma-separated list from git status>
```

## Cron / `--quiet` interaction

Halt-on-red is a hard halt regardless of caller mode. `/CJ_goal_todo_fix
--quiet` (cron) suppresses Phase 3 summary AUQs + start-of-run banners; it
does NOT suppress the `[doc-sync-red]` or `[doc-sync-non-doc-write]` halt
contracts. The cron operator reads the halt journal at their convenience;
silently swallowing doc-sync failures would defeat the purpose.

## Error Handling

| Error | Marker | Recovery |
|-------|--------|----------|
| Not a git repo | (no marker — usage halt) | Run inside a repo |
| `cj-document-release.json` missing / invalid JSON / schema_version unsupported / required fields missing (F000037 strict-required) | `[doc-sync-no-config]` | Author or repair `cj-document-release.json` at repo root; copy the workbench's seed JSON as a starting point; re-run |
| On main / base branch (refuses on the base branch) | `[doc-sync-red]` | Run from a feature branch |
| Working tree has uncommitted non-doc changes (pre-run) | `[doc-sync-red]` | Commit or stash non-doc changes; re-run |
| Upstream `/document-release` returned non-green | `[doc-sync-red]` | Inspect upstream output; fix doc errors; re-run |
| Upstream wrote files outside the doc-only whitelist | `[doc-sync-non-doc-write]` | Inspect uncommitted non-doc files; revert if unexpected; re-run |
| `--docs UNKNOWN_VALUE` (token not declared in `categories`) | `[doc-sync-no-config]` | Declare the token in `cj-document-release.json` under `categories`, or use a known token (whatever the repo's JSON declares) |

## Notes

- **First workbench skill with the "thin wrapper around an upstream gstack
  skill" shape.** `/CJ_document-release` calls `/document-release` via the
  Skill tool, adding workbench-specific concerns (per-doc filtering, halt
  taxonomy, auto-commit doc-only) without touching upstream. Future wrappers
  (`/CJ_ship`? `/CJ_review`?) can use this as a template.
- **Project-context block is documentation-only, not programmatic.** The
  block tells `/document-release` "this run is filtered to <subset>; audit
  ONLY those categories and skip the rest." If upstream honors the request,
  filtering works; if upstream audits everything anyway, CJ_document-release
  still auto-commits whatever the upstream skill produced (gated by the
  whitelist). Best-effort filter, not enforced filter.
- **Conservative doc-only whitelist is intentional.** Stealth code edits via
  the doc-sync surface would be a serious integrity surface; the whitelist
  closes that door without an operator-override. Extending the whitelist is
  a follow-up if a real-world false-positive surfaces in dogfood.
- **Coexistence with F000029, not replacement.** F000029's marker-AUQ stays
  installed and fires on next-session for non-orchestrator paths (raw
  `git push`, manual `/ship`). The two mechanisms layer; F000036 fires
  inline in orchestrator paths, F000029 fires on next-session for
  non-orchestrator paths.
- **No upstream `/document-release` modification.** All workbench-specific
  logic (filter, halt-on-red, auto-commit-doc-only) lives in this wrapper.
  This mirrors the F000034 precedent (no upstream modification).
