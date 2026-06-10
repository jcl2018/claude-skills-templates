---
name: CJ_document-release
description: "Workbench wrapper around upstream /document-release. Reads the spec/doc-spec.md registry (resolved spec/-then-root; self-bootstraps it from the portable Common seed if missing; stub-scaffolds any missing declared doc), adds a --docs <comma-list> subset flag for per-invocation doc filtering (best-effort, documentation-only), a halt-on-red contract that emits [doc-sync-red] on upstream failure, and an auto-commit step gated by a doc-only whitelist DERIVED from the doc-spec.md registry (non-whitelist writes HALT with [doc-sync-non-doc-write]). A missing/invalid registry HALTs with [doc-sync-no-config] BEFORE any audit. Invoked inline by the 3 cj_goal orchestrators (CJ_goal_feature / CJ_goal_defect / CJ_goal_todo_fix) at Step 5.5 — between QA pass and /ship — so doc updates fold into the same code PR rather than chasing them post-merge."
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
_UC="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/skills-update-check"
[ -x "$_UC" ] && "$_UC" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: print `Error: /CJ_document-release requires a git repository.` and stop.

## Overview

> Canonical convention home: the doc contract this skill enforces — what docs the
> repo carries, what each is for, and the human-doc rules — lives in the root
> `doc-spec.md` (both human prose and a machine `yaml` registry). The mechanism
> reference (how it is parsed, enforced, and self-healed) lives in
> `docs/architecture.md` `## The doc-spec.md contract + /CJ_document-release`.

`/CJ_document-release` is a thin workbench wrapper around upstream gstack
`/document-release`. It adds four workbench-specific concerns the orchestrator
family needs:

1. **Reads + self-heals the `doc-spec.md` contract.** The `spec/doc-spec.md` (resolved spec/-then-root)
   declares the repo's docs (a fenced `yaml` registry parsed by
   `scripts/doc-spec.sh`). If `doc-spec.md` is **missing**, the wrapper
   self-bootstraps it from the portable Common seed and commits it. For each
   **declared doc that is missing**, it stub-scaffolds a skeleton (title + a
   section skeleton + a `<!-- TODO: fill in -->` marker) and commits it. Both are
   idempotent — a re-run never writes a second copy.

   **Tier logic (the general/custom contract).** `section: common` (general)
   docs are the portable contract and are **REQUIRED** — every adopting repo
   carries them: the portable seed declares all of them on self-bootstrap, and
   the stub-scaffold step creates any missing one. `section: custom` docs are
   per-repo additions — declared and carried by the repo that wants them, never
   required anywhere else. The Step 6.7 audit surfaces a repo registry that
   omits a general-contract doc as an advisory `stale:` verdict (see 6.7.3b) —
   advisory, never a halt.

2. **`--docs <comma-list>` per-invocation doc subset.** Operator can scope an
   invocation to a subset of declared docs (e.g. `--docs README` or
   `--docs README,CHANGELOG`). The subset is a documentation-only signal to
   `/document-release` via the project-context block; it is best-effort, not
   enforced. Case-insensitive parsing; whitespace trimmed; empty subset = full
   audit; the literal `all` is an explicit no-filter token.

3. **Halt-on-red contract.** If `/document-release` returns non-green (audit
   error, mid-write failure, hard-abort), the wrapper emits `[doc-sync-red]` to
   the caller (an orchestrator) and exits non-green. The orchestrator HALTs with
   `halt class = halted_at_doc_sync`. This is a hard halt, not a warning.

4. **Doc-only auto-commit (derived whitelist gate).** After a green
   `/document-release`, the wrapper auto-commits doc-only changes so `/ship` sees
   a clean tree. The whitelist is **derived from the `doc-spec.md` registry**
   (`scripts/doc-spec.sh --expand-whitelist` = every declared `path` +
   `doc-spec.md` + every `docs/**/*.md`). If any non-whitelist file is dirty after
   `/document-release` runs, the wrapper refuses to auto-commit and HALTs with
   `[doc-sync-non-doc-write]`. If `doc-spec.md` is missing/invalid, the wrapper
   HALTs with `[doc-sync-no-config]` BEFORE any audit runs.

The orchestrator invocation shape:

```
(orchestrator session)
       |
       v
... QA passes green (Step 5) ...
       |
       v
Skill(CJ_document-release)         <- THIS SKILL (no --docs in v1 orchestrator wiring)
       |
       |-- read doc-spec.md (self-bootstrap from seed if missing)
       |-- stub-scaffold any missing declared doc
       |-- arg parse: --docs <list>
       |-- branch + clean-tree gate
       |-- project-context block (doc-only signal)
       |-- Skill(/document-release) -> upstream gstack (NOT MODIFIED)
       |-- halt-on-red [doc-sync-red] (RESULT=red)
       |-- auto-commit doc-only (derived whitelist gate) [doc-sync-non-doc-write]
       |-- registered-doc audit (advisory; + no-ref check for human-docs)
       `-- success summary (RESULT=green or RESULT=green-noop)
       |
       v
/ship (Step 6)                     <- clean-tree precondition NOW satisfied
       |
       v
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
(`--docs README,UNKNOWN_DOC` audits README only and prints a one-line warn for
`UNKNOWN_DOC`). Empty subset (no flag, or `--docs ""`) is a full audit.

## Step 0.5: Resolve the doc-spec helper + read/self-heal the contract

Before any audit runs, resolve the `doc-spec.sh` helper, then read the
`doc-spec.md` registry. The helper reads `doc-spec.md` via `git rev-parse
--show-toplevel`, so a `_cj-shared`-resolved helper still parses THIS repo's
registry — never the workbench's.

```bash
# Resolve the doc-spec helper: (1) repo-local first (workbench self-dev or a repo
# that vendors scripts/), then (2) the deployed _cj-shared home (a consumer repo
# where the helper lives ONLY in the installed workbench). 2-tier resolution:
# repo-local -> _cj-shared (no .source / manifest reach-back).
_DS_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_DS_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_DS_HELPER=""
if [ -n "$_DS_REPO_ROOT" ] && [ -x "$_DS_REPO_ROOT/scripts/doc-spec.sh" ]; then
  _DS_HELPER="$_DS_REPO_ROOT/scripts/doc-spec.sh"
elif [ -x "$_DS_SHARED/doc-spec.sh" ]; then
  _DS_HELPER="$_DS_SHARED/doc-spec.sh"
fi
if [ -z "$_DS_HELPER" ]; then
  echo "[doc-sync-no-config] doc-spec.sh unreachable (repo-local scripts/ + deployed _cj-shared both absent)"
  echo "RESULT: red; HALT_MARKER=[doc-sync-no-config]"
  echo "next_action=restore scripts/doc-spec.sh in this repo, or re-run 'skills-deploy install' to refresh the deployed _cj-shared home; re-run /CJ_document-release"
  echo "resume_cmd=/CJ_document-release${DOCS_SUBSET:+ --docs $DOCS_SUBSET}"
  echo "pr_url=N/A"
  exit 1
fi
```

### Self-bootstrap a missing doc-spec.md

If `doc-spec.md` does not exist at EITHER `spec/doc-spec.md` (this repo's
relocated home) OR the repo root, scaffold it from the portable Common seed
(`doc-spec.sh --seed`) and commit it. This is the duty that replaces a separate
repo-init step — a fresh repo adopts the contract with no manual step. The
READ/guard probes spec/-then-root so a repo that already carries
`spec/doc-spec.md` is NOT treated as missing (no spurious duplicate root file);
the WRITE target for a genuinely-missing-everywhere file stays root-style
(consumer convention — the seed is root-style by construction):

Write the seed to a temp file, verify it is non-empty AND passes `--validate`,
THEN move it into place. This guards against a `--seed` failure ever redirecting
a halt string (or an empty stream) into `doc-spec.md` and corrupting it:

```bash
# Guard: present if EITHER spec/doc-spec.md OR root doc-spec.md exists.
if [ ! -f "$_DS_REPO_ROOT/spec/doc-spec.md" ] && [ ! -f "$_DS_REPO_ROOT/doc-spec.md" ]; then
  _DS_TMPD=$(mktemp -d)
  if bash "$_DS_HELPER" --seed > "$_DS_TMPD/doc-spec.md" 2>/dev/null \
     && [ -s "$_DS_TMPD/doc-spec.md" ] \
     && REPO_ROOT="$_DS_TMPD" bash "$_DS_HELPER" --validate >/dev/null 2>&1; then
    mv "$_DS_TMPD/doc-spec.md" "$_DS_REPO_ROOT/doc-spec.md"
    rm -rf "$_DS_TMPD"
    git -C "$_DS_REPO_ROOT" add doc-spec.md
    git -C "$_DS_REPO_ROOT" commit -m "docs: self-bootstrap doc-spec.md from the portable Common seed" >/dev/null 2>&1 || true
    echo "CJ_document-release: scaffolded doc-spec.md from the portable Common seed."
  else
    rm -rf "$_DS_TMPD"
    echo "[doc-sync-no-config] self-bootstrap failed: doc-spec.sh --seed did not emit a valid doc-spec.md"
    echo "RESULT: red; HALT_MARKER=[doc-sync-no-config]"
    echo "next_action=check scripts/doc-spec.sh --seed + templates/doc-spec-common.md; re-run /CJ_document-release"
    echo "resume_cmd=/CJ_document-release${DOCS_SUBSET:+ --docs $DOCS_SUBSET}"
    echo "pr_url=N/A"
    exit 1
  fi
fi
```

### Validate the registry (strict)

Validate the registry via the helper. The helper exits 1 + emits
`[doc-sync-no-config] <reason>` when the registry is missing / has no `yaml`
block / schema_version-unsupported / an entry missing required fields / an
audit_class outside the closed enum. The wrapper HALTs immediately on non-zero
exit — no fallback:

```bash
CONFIG_OUT=$(bash "$_DS_HELPER" --validate 2>&1)
CONFIG_RC=$?
if [ "$CONFIG_RC" -ne 0 ]; then
  echo "$CONFIG_OUT"
  echo "RESULT: red; HALT_MARKER=[doc-sync-no-config]"
  echo "next_action=repair spec/doc-spec.md's yaml registry; re-run /CJ_document-release"
  echo "resume_cmd=/CJ_document-release${DOCS_SUBSET:+ --docs $DOCS_SUBSET}"
  echo "pr_url=N/A"
  exit 1
fi
```

### Stub-scaffold missing declared docs

For each declared doc that is missing from disk, write a stub (title + a section
skeleton its `audit_class` implies + a `<!-- TODO: fill in -->` marker) and
commit it. Idempotent: only missing docs are written, so a re-run is a NO-OP and
never produces a second stub. Record each stubbed doc in the audit as `stub —
needs content`:

```bash
_STUBBED=""
while IFS= read -r _decl; do
  [ -n "$_decl" ] || continue
  if [ ! -f "$_DS_REPO_ROOT/$_decl" ]; then
    mkdir -p "$_DS_REPO_ROOT/$(dirname "$_decl")"
    {
      echo "# $(basename "$_decl" .md)"
      echo ""
      echo "<!-- TODO: fill in -->"
      echo ""
      echo "This doc is declared in doc-spec.md but has not been written yet."
    } > "$_DS_REPO_ROOT/$_decl"
    git -C "$_DS_REPO_ROOT" add "$_decl"
    _STUBBED="$_STUBBED $_decl"
  fi
done < <(bash "$_DS_HELPER" --list-declared)
if [ -n "$_STUBBED" ]; then
  git -C "$_DS_REPO_ROOT" commit -m "docs: stub-scaffold missing declared docs ($_STUBBED)" >/dev/null 2>&1 || true
  echo "CJ_document-release: stub-scaffolded missing declared docs:$_STUBBED (audit: stub — needs content)"
fi
```

**Stub shape for the generated views.** When stub-scaffolding a missing
`docs/doc-general.md` / `docs/doc-custom.md`, prefer REAL content over the plain
stub above: render the table via `doc-spec.sh --render general|custom` so the
view is born satisfying its "kept matching the registry" requirement; fall back
to the plain stub only if `--render` fails. The header must be PORTABLE — e.g.
`<!-- generated from the doc-spec registry — re-render via doc-spec.sh --render general|custom -->`
— NOT a workbench header naming `spec/doc-spec.md` +
`scripts/generate-doc-views.sh` (those paths do not exist in a root-style
consumer repo). The third generated view, `docs/test-pipeline.md`, follows the
same preference when a test-pipeline registry + parser are adoptable: render it
via `test-pipeline.sh --render` (repo-local `scripts/` then `_cj-shared`); when
the parser or its registry is absent (the common consumer posture), fall back
to the plain stub — there the doc is hand-maintained and the mechanism-neutral
seed requirement is satisfied without generation.

**TODOS.md dual-creation (convergent, not conflicting).** TODOS-reading skills
lazy-create `TODOS.md` on first use; this stub-scaffold also creates it when it
is declared-but-missing. The two paths are convergent: whichever runs first
creates a minimal parseable skeleton, and the other no-ops because the file
exists.

The helper supports these subcommands the rest of this skill consumes:

- `--validate` — exit 0 + print `OK schema_version=<n>` if the registry is valid;
  exit 1 + halt-emit otherwise.
- `--list-declared` — emit every declared `path` (sorted, unique).
- `--list-human-docs` — emit only the `audit_class: human-doc` paths (used by the
  no-work-item-ref audit check).
- `--list-front-table-docs` — emit only the paths flagged `front_table: required`
  (consumed by `validate.sh` Check 20; not used directly by this skill).
- `--expand-whitelist` — emit the doc-only auto-commit whitelist (every declared
  `path` + `doc-spec.md` + every `docs/**/*.md`). Step 2 + Step 6 use this.
- `--seed` — emit the portable Common-section seed (used by the self-bootstrap).

## Step 1: Parse arguments

Parse the optional `--docs <comma-list>` flag (case-insensitive; whitespace
trimmed; resolved against the registry's declared paths at Step 4):

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

The set of known `--docs` tokens is the basename (or path) of any doc the
`doc-spec.md` registry declares. Step 4 resolves each requested token against the
declared set; a token matching no declared doc is warn-and-skipped (the full
audit still runs). The registry seeds with this repo's docs (README, CHANGELOG,
CLAUDE.md, docs/philosophy.md, docs/workflow.md, docs/architecture.md, …); other
repos adopting `/CJ_document-release` declare their own. Upstream
`/document-release` still decides what to actually audit — the filter is
best-effort communication of operator intent via the project-context block.

## Step 2: Branch + clean-tree gate

Upstream `/document-release` refuses on the base branch (it hard-aborts on main
with "You're on the base branch. Run from a feature branch."). Mirror that
refusal here as a pre-flight check so the wrapper fails fast rather than spending
a Skill call:

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

Clean-tree gate: `/document-release` itself writes doc files. The wrapper refuses
if the working tree already has uncommitted NON-DOC changes (those must commit
first; doc-only dirtiness is OK because the wrapper will auto-commit it later).
The doc-only set is the helper-derived whitelist, not a hardcoded regex:

```bash
# Re-resolve the doc-spec helper (shell vars do NOT persist across bash blocks):
# repo-local first, else the deployed _cj-shared home.
_DS_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_DS_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_DS_HELPER="$_DS_REPO_ROOT/scripts/doc-spec.sh"
[ -x "$_DS_HELPER" ] || _DS_HELPER="$_DS_SHARED/doc-spec.sh"

# Build doc-only file set from the registry-derived whitelist.
DOC_WHITELIST_SET=$(bash "$_DS_HELPER" --expand-whitelist)

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

The block is a documentation-only signal to `/document-release` that this run is
filtered (or unfiltered). Upstream may honor the filter or audit everything —
both outcomes are fine; the wrapper auto-commits whatever upstream produces
(gated by the whitelist).

When `--docs <token>` is set, resolve each token against the registry's declared
docs (`doc-spec.sh --list-declared`): a token that matches a declared doc's
basename (or full path) is kept; a token matching nothing is warn-and-skipped:

```bash
AUDIT_FILES=""
if [ -n "$DOCS_SUBSET" ]; then
  _DS_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  _DS_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
  _DS_HELPER="$_DS_REPO_ROOT/scripts/doc-spec.sh"
  [ -x "$_DS_HELPER" ] || _DS_HELPER="$_DS_SHARED/doc-spec.sh"
  _DECLARED=$(bash "$_DS_HELPER" --list-declared)
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    # Match a declared doc by full path OR basename (case-insensitive token).
    _hit=$(printf '%s\n' "$_DECLARED" | awk -v t="$token" 'BEGIN{IGNORECASE=1} {b=$0; sub(/.*\//,"",b); sub(/\.md$/,"",b); fp=$0; sub(/\.md$/,"",fp); if (tolower(b)==tolower(t) || tolower(fp)==tolower(t) || tolower($0)==tolower(t)) print $0}')
    if [ -z "$_hit" ]; then
      echo "CJ_document-release: warn — --docs token '$token' matches no declared doc; skipping it."
      continue
    fi
    AUDIT_FILES="$AUDIT_FILES$_hit"$'\n'
  done < <(printf '%s' "$DOCS_SUBSET" | tr ',' '\n')
  AUDIT_FILES=$(printf '%s' "$AUDIT_FILES" | sort -u | grep -v '^$' || true)
  CONTEXT_BLOCK="CJ_document-release: running with --docs filter = '$DOCS_SUBSET'.
This invocation should audit only the following files (resolved via doc-spec.md):
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

**Step 4→5 boundary — two failure modes, one marker.** A failure can surface
HERE in two distinct ways, and BOTH route to the Step 5 `[doc-sync-red]` halt:

1. **Resolution failure** — `Skill(document-release)` cannot be resolved at all
   (the upstream gstack `/document-release` skill is not installed on this
   machine). This is a Step-4 resolution failure, not a Step-5 audit verdict.
2. **Non-green return** — the skill resolved and ran but returned non-green
   (audit error, mid-write failure, hard-abort, crashed, exceeded budget).

The wrapper does NOT add a programmatic skill-presence probe (a probe risks a new
false-halt class). Instead, in EITHER case it falls through to Step 5, whose
`[doc-sync-red]` message names **"gstack `/document-release` not installed"** as a
possible cause alongside the doc-error cause — so the operator gets the actionable
hint for the resolution-failure mode too, not only the non-green mode.

## Step 5: Halt-on-red ([doc-sync-red])

If the Step 4 invocation failed to RESOLVE (gstack `/document-release` not
installed) OR upstream returned non-green (audit error, mid-write failure,
hard-abort, crashed, exceeded budget): emit a halt marker and exit RESULT=red.
The message names both possible causes so it covers the Step-4 resolution-failure
mode and the Step-5 non-green mode:

```bash
echo "CJ_document-release: upstream /document-release did not return green (it either could not be resolved or returned non-green); halting."
echo "Possible causes: gstack /document-release not installed; or a doc audit error in /document-release."
echo "RESULT: red; HALT_MARKER=[doc-sync-red]"
echo "next_action=confirm gstack /document-release is installed, OR inspect its output and fix doc errors; then re-run /CJ_document-release"
echo "resume_cmd=/CJ_document-release${DOCS_SUBSET:+ --docs $DOCS_SUBSET}"
echo "pr_url=N/A"
exit 1
```

## Step 6: Auto-commit doc-only (derived whitelist gate; [doc-sync-non-doc-write])

After a green `/document-release`, inspect the working tree. If any dirty file is
OUTSIDE the doc-only whitelist, refuse to auto-commit and HALT — this is the
upstream-misbehaved case (or an unexpected stealth-write surface). The whitelist
set comes from `bash "$_DS_HELPER" --expand-whitelist` (reuses Step 2's
expansion):

```bash
# Re-resolve the doc-spec helper (shell vars do NOT persist across bash blocks):
# repo-local first, else the deployed _cj-shared home.
_DS_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_DS_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_DS_HELPER="$_DS_REPO_ROOT/scripts/doc-spec.sh"
[ -x "$_DS_HELPER" ] || _DS_HELPER="$_DS_SHARED/doc-spec.sh"

DOC_WHITELIST_SET=$(bash "$_DS_HELPER" --expand-whitelist)
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

## Step 6.7: Registered-doc requirements audit (ADVISORY — never halts)

This step runs on the GREEN / green-noop TAIL of Step 6 — only after the
auto-commit RESULT line has printed (so it is on the non-exiting path; Step 6's
`[doc-sync-non-doc-write]` / `[doc-sync-red]` halts have already exited before
control reaches here). It is **strictly advisory**: it emits one verdict per
registered doc and NEVER halts, exits non-green, or blocks `/ship`. A
`missing-requirement` verdict is a soft finding, not a halt.

This is the **producer** for the workbench's PR-body audit subheadings — see
`docs/architecture.md` `## The doc-spec.md contract + /CJ_document-release`. The
agent running the wrapper performs the judgment; the deliverable is a grep-able
block written to BOTH the wrapper RESULT and a gitignored scratch file the
orchestrator surfaces post-`/ship`.

**What "registered docs" means.** Two sets, both enumerated dynamically (no
hardcoded counts):

1. **The registry docs** — every entry in the `doc-spec.md` registry, each
   carrying a `requirement:` value.
2. **The routable skill MDs** — every skill enumerated by the
   `!= "deprecated"` selector; each skill's requirement is its optional
   `doc_requirement` in `skills-catalog.json`, else the **shared default
   skill-MD requirement**.

### 6.7.1 — Parse the registry requirements

Parse the `doc-spec.md` registry (the same block the helper reads). For each
declared doc, capture BOTH its `path:` value AND its `requirement:` child value.
The `requirement:` value MAY wrap across a continuation line, so read the FULL
value:

```bash
_DS_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
# Resolve spec/-then-root (the registry moved into spec/; root is the fallback).
_DS_REG="$_DS_REPO_ROOT/spec/doc-spec.md"
[ -f "$_DS_REG" ] || _DS_REG="$_DS_REPO_ROOT/doc-spec.md"
# Extract the yaml registry block and walk path + requirement pairs.
awk '
  /^```yaml/ { if (!seen) { f=1; seen=1; next } }
  /^```/     { if (f) { f=0 } }
  f          { print }
' "$_DS_REG"
```

For each captured `(path, requirement)` pair: the registered doc is `path`, and
its declared requirement is the full `requirement:` string. A `human-doc` entry
ALSO gets the no-work-item-ref check below.

### 6.7.2 — Enumerate the skill MDs + their requirements

Enumerate routable skills with the `!= "deprecated"` selector, and read each
skill's optional `doc_requirement` (absent => the shared default).

**Non-workbench guard.** This half of the audit reads `skills-catalog.json`,
which exists only in the workbench (and any repo that ships its own skill
catalog). In a consumer repo with no catalog, skip the skill-MD enumeration
cleanly — one note, no `jq: Could not open file` stderr — and set
`CATALOG_PRESENT=false` so 6.7.4 skips the cj_goal scratch-file write too. The
registry-doc audit (6.7.1) and the human-doc no-work-item-ID lint (6.7.3) are
catalog-independent and STILL run. The `$(…)`-capture idiom is preserved (and the
`jq` reads are `|| true`-guarded), so no `set -e` abort is introduced:

```bash
_CATALOG="$_DS_REPO_ROOT/skills-catalog.json"
if [ ! -f "$_CATALOG" ]; then
  CATALOG_PRESENT=false
  echo "CJ_document-release: no skills-catalog.json — non-workbench mode; skipping the skill-MD audit half (registry-doc audit still runs)."
else
  CATALOG_PRESENT=true
  SKILL_NAMES=$(jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' "$_CATALOG" 2>/dev/null || true)

  SHARED_DEFAULT="The SKILL.md frontmatter \`description\` and the documented behavior/steps match the skill's current implementation; the skill's USAGE.md is current."

  for _name in $SKILL_NAMES; do
    _req=$(jq -r --arg n "$_name" '.[] | select(.name==$n) | .doc_requirement // empty' "$_CATALOG" 2>/dev/null || true)
    [ -z "$_req" ] && _req="$SHARED_DEFAULT"
    # registered doc = skills/$_name/SKILL.md ; requirement = $_req
  done
fi
```

### 6.7.3 — Judge each registered doc (+ no-work-item-ref check for human-docs)

Determine the diff base (the merge-base of the branch against the default
branch). For EACH registered doc, the agent reads the doc + its requirement + the
run's `git diff <base>...HEAD` and assigns ONE verdict:

- `up-to-date` — satisfies its requirement given what this run changed.
- `stale: <one-line why>` — no longer satisfies its requirement.
- `missing-requirement` — the registered doc has NO declared requirement. Soft;
  never a halt.
- `n/a` — registered but out of scope for this run's judgment.

For every `audit_class: human-doc` registered doc, ALSO run the
no-work-item-ref check: grep the doc for `[FSTD][0-9]{6}`; any hit forces the
verdict `stale: contains work-item refs` (the advisory mirror of the hard
`validate.sh` Check 19):

```bash
_DS_HELPER="$_DS_REPO_ROOT/scripts/doc-spec.sh"
[ -x "$_DS_HELPER" ] || _DS_HELPER="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/doc-spec.sh"
for _hd in $(bash "$_DS_HELPER" --list-human-docs); do
  if grep -qE '[FSTD][0-9]{6}' "$_DS_REPO_ROOT/$_hd" 2>/dev/null; then
    echo "  $_hd: stale — contains work-item refs"
  fi
done
```

**View freshness (consumer repos) is judged mechanically.** The workbench keeps
the generated views in sync via `scripts/generate-doc-views.sh` + a CI drift
check, but those are workbench-local and do NOT travel. In a consumer repo, judge
the verdict for `docs/doc-general.md` / `docs/doc-custom.md` MECHANICALLY: diff
each view's table against fresh `doc-spec.sh --render general|custom` output
(the helper travels via `_cj-shared`); a mismatch ⇒ `stale: view out of sync
with the registry`. The pass MAY re-render them directly — both paths are
inside the registry-derived auto-commit whitelist. `docs/test-pipeline.md` gets
the same mechanical treatment ONLY where a test-pipeline registry + parser are
present (diff against fresh `test-pipeline.sh --render` output); where they are
absent (consumer hand-maintained copy), it is judged like any other prose doc
against its mechanism-neutral requirement — never flagged stale merely for not
being generated.

### 6.7.3b — General-contract coverage check (advisory missing-general-doc rule)

The general contract (the portable seed) declares the `section: common` docs
every adopting repo is REQUIRED to carry. When the REPO's registry omits one of
them, surface the gap as part of the **contract file's own verdict line** (the
registry entry whose basename is `doc-spec.md`):

```
stale: registry missing general-contract doc(s): <paths>
```

Because this is a `stale` verdict on a registered doc, it naturally suppresses
the `Registered-doc requirements: all current` positive line — intended and
honest. It is **ADVISORY, never a halt**: no exit, no halt marker, no
RESULT=red.

**Enumerating the general set.** Do NOT hand-parse the seed yaml, and do NOT
use `--list-declared` (it would silently over-enumerate if the seed ever
regains a `section: custom` entry). Write the seed to a temp file and reuse
the parser — render the general section and take the first table column:

```bash
_GC_TMP=$(mktemp -d)
bash "$_DS_HELPER" --seed > "$_GC_TMP/doc-spec.md" 2>/dev/null || true
_GENERAL_SET=$(DOC_SPEC_PATH="$_GC_TMP/doc-spec.md" bash "$_DS_HELPER" --render general 2>/dev/null \
  | awk -F'|' 'NR>2 {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
rm -rf "$_GC_TMP"

_DECLARED=$(bash "$_DS_HELPER" --list-declared)
_MISSING_GC=""
for _gc in $_GENERAL_SET; do
  printf '%s\n' "$_DECLARED" | grep -qFx "$_gc" && continue
  # Path equivalence: the seed declares the contract file root-style
  # (doc-spec.md); ANY declared path whose basename is doc-spec.md SATISFIES
  # that entry (e.g. spec/doc-spec.md) — mirroring the helper's own
  # spec/-then-root resolution. Without this rule the workbench itself would
  # false-positive on every run.
  if [ "$_gc" = "doc-spec.md" ] \
     && printf '%s\n' "$_DECLARED" | awk -F/ '{print $NF}' | grep -qFx 'doc-spec.md'; then
    continue
  fi
  _MISSING_GC="$_MISSING_GC $_gc"
done
# Non-empty _MISSING_GC => the contract file's verdict line becomes:
#   stale: registry missing general-contract doc(s):$_MISSING_GC
```

### 6.7.4 — Emit the block (RESULT + scratch file)

Compose the grep-able block and always write it to the wrapper RESULT (stdout).
In WORKBENCH mode (`CATALOG_PRESENT=true`), ALSO write it to the gitignored
scratch file `"$_DS_REPO_ROOT/.cj-goal-feature/registered-doc-verdicts.md"` that
the cj_goal orchestrator surfaces post-`/ship`. Emit the positive line
`Registered-doc requirements: all current` ONLY when EVERY verdict is
`up-to-date`.

**Non-workbench scratch-write skip.** The `.cj-goal-feature/` scratch file ONLY
feeds the cj_goal orchestrator's PR-body surfacing, which does not exist when the
skill runs standalone — and in a consumer repo `.cj-goal-feature/` is NOT
gitignored, so writing it would leave a stray untracked artifact. So when
`CATALOG_PRESENT=false` (set in 6.7.2), emit the block to stdout only and skip the
scratch write:

```bash
{
  echo "### Registered-doc requirements"
  printf '%s\n' "$VERDICT_BODY"
  if [ "$ALL_UP_TO_DATE" = "true" ]; then
    echo "Registered-doc requirements: all current"
  fi
} > /tmp/cj-docrel-verdicts.$$ 2>/dev/null || true
cat /tmp/cj-docrel-verdicts.$$ 2>/dev/null || true

if [ "${CATALOG_PRESENT:-true}" = "true" ]; then
  _VERDICT_DIR="$_DS_REPO_ROOT/.cj-goal-feature"
  mkdir -p "$_VERDICT_DIR"
  _VERDICT_FILE="$_VERDICT_DIR/registered-doc-verdicts.md"
  cp /tmp/cj-docrel-verdicts.$$ "$_VERDICT_FILE" 2>/dev/null || true
fi
rm -f /tmp/cj-docrel-verdicts.$$ 2>/dev/null || true
```

The block is ADVISORY: control falls straight through to Step 7. No exit, no halt
marker, no RESULT=red is emitted by this step under any verdict.

## Step 7: Success summary

Print a single-line success summary the orchestrator can grep:

```
CJ_document-release: <green|green-noop> / /document-release: green / commit: <sha-or-none> / filtered: <subset-or-full>
```

The orchestrator's Step 5.5 reads:
- `RESULT: green` → continue to `/ship`. Doc commit was made; `/ship` opens one
  PR containing both code + doc updates.
- `RESULT: green-noop` → continue to `/ship`. No doc commit needed.
- `RESULT: red` → HALT with the corresponding marker.

## Halt-marker shape (machine-readable)

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

Halt-on-red is a hard halt regardless of caller mode. `/CJ_goal_todo_fix --quiet`
(cron) suppresses Phase 3 summary AUQs + start-of-run banners; it does NOT
suppress the `[doc-sync-red]` or `[doc-sync-non-doc-write]` halt contracts.

## Error Handling

| Error | Marker | Recovery |
|-------|--------|----------|
| Not a git repo | (no marker — usage halt) | Run inside a repo |
| `doc-spec.md` missing / no yaml registry / schema_version unsupported / entry missing required fields / audit_class outside enum | `[doc-sync-no-config]` | Repair `spec/doc-spec.md`'s yaml registry (or let the self-bootstrap recreate it from the Common seed); re-run |
| `doc-spec.sh` helper unreachable | `[doc-sync-no-config]` | Restore `scripts/doc-spec.sh`, or re-run `skills-deploy install` to refresh the deployed `_cj-shared` home; re-run |
| On main / base branch (refuses on the base branch) | `[doc-sync-red]` | Run from a feature branch |
| Working tree has uncommitted non-doc changes (pre-run) | `[doc-sync-red]` | Commit or stash non-doc changes; re-run |
| Upstream `/document-release` did not return green — either it could not be resolved (gstack `/document-release` not installed) or it returned non-green (audit error) | `[doc-sync-red]` | Confirm gstack `/document-release` is installed; OR inspect its output and fix doc errors; re-run |
| Upstream wrote files outside the doc-only whitelist | `[doc-sync-non-doc-write]` | Inspect uncommitted non-doc files; revert if unexpected; re-run |
| `--docs UNKNOWN_VALUE` (token matches no declared doc) | (no halt — warn-and-skip) | Use a token that matches a doc declared in `doc-spec.md` |

## Notes

- **Wrapper around an upstream gstack skill.** `/CJ_document-release` calls
  `/document-release` via the Skill tool, adding workbench-specific concerns
  (doc-spec.md self-heal, per-doc filtering, halt taxonomy, auto-commit doc-only)
  without touching upstream.
- **Project-context block is documentation-only, not programmatic.** Best-effort
  filter, not enforced filter — the wrapper auto-commits whatever upstream
  produces, gated by the derived whitelist.
- **The doc-only whitelist is DERIVED from the registry, never hand-maintained.**
  Deleting a doc from the registry removes it from the whitelist automatically;
  there is no second list to keep in sync.
- **No upstream `/document-release` modification.** All workbench-specific logic
  lives in this wrapper.
