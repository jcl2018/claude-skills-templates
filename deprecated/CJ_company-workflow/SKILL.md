---
name: CJ_company-workflow
description: "Company work item specification with structural validation. Validates tracker files and work item directories against company templates and company-artifact-manifests.json. Templates are the single source of truth for structural rules."
version: 5.0.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

## Getting Started

For the complete doc-driven development workflow (generating docs, scaffolding
conventions, installation), see [WORKFLOW.md](WORKFLOW.md).

This skill provides the `validate` command. WORKFLOW.md provides everything else.

## Preamble

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_company-workflow requires a git repository." and stop.

## Overview

Company work item specification skill. Enforces the company's formal work item
standard: structural validation derived directly from the templates in
`templates/CJ_company-workflow/`, artifact completeness via
`company-artifact-manifests.json`, and frontmatter compliance against templates.

This skill is independent from the workbench's personal-dev templates and from
`/docs check`. It owns its own templates, manifest, reference guides, and
validation logic.

**Templates are the single source of truth.** The validator derives every
structural rule (required frontmatter, required sections, section order,
lifecycle phases, minimum checkbox count) by parsing the matching template at
runtime. There is no separate `contract.json` to drift from the templates.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This ensures the skill
works both in the workbench repo and on company machines where it's deployed
via `skills-deploy`.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""
_TMPL_DIR=""

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_company-workflow/company-artifact-manifests.json" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_company-workflow"
  _TMPL_DIR="$_REPO_ROOT/templates/CJ_company-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_company-workflow/company-artifact-manifests.json" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_company-workflow"
  _TMPL_DIR="$HOME/.claude/templates/CJ_company-workflow"
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: Could not find CJ_company-workflow skill assets."
  echo "Checked: $_REPO_ROOT/skills/CJ_company-workflow/ and ~/.claude/skills/CJ_company-workflow/"
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "TMPL_DIR: $_TMPL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: CJ_company-workflow skill assets not found.
Run `skills-deploy install` or check the repo structure." and stop.

## Knowledge Resolution

After Path Resolution, the skill resolves an OPTIONAL external knowledge
directory via the `AI_KNOWLEDGE_DIR` environment variable. When set to a
valid directory, downstream features (always-on loading, on-demand matching —
see F000003 user-story S000005, originally tracked under F000004 before the
2026-04-24 one-feature-per-skill consolidation) consume its contents. When
unset or invalid, the skill still functions; only knowledge features are
disabled.

```bash
_KNOWLEDGE_DIR=""
# Sanitize for safe display in warnings: strip control chars, truncate long paths.
# The filesystem tests below use the RAW value; only warning output uses the clean form.
# This preserves the "exactly one warning line" contract even if the env var contains
# newlines, terminal escape sequences, or other hostile content.
_AKD_DISPLAY=$(printf '%s' "${AI_KNOWLEDGE_DIR:-}" | tr -d '[:cntrl:]')
if [ ${#_AKD_DISPLAY} -gt 200 ]; then
  _AKD_DISPLAY="${_AKD_DISPLAY:0:200}..."
fi
if [ -z "${AI_KNOWLEDGE_DIR:-}" ]; then
  echo "Warning: AI_KNOWLEDGE_DIR not set — knowledge features disabled. See WORKFLOW.md." >&2
elif [ ! -e "$AI_KNOWLEDGE_DIR" ]; then
  echo "Warning: AI_KNOWLEDGE_DIR=\"$_AKD_DISPLAY\" not found — knowledge features disabled." >&2
elif [ ! -d "$AI_KNOWLEDGE_DIR" ]; then
  echo "Warning: AI_KNOWLEDGE_DIR=\"$_AKD_DISPLAY\" is not a directory — knowledge features disabled." >&2
else
  _KNOWLEDGE_DIR="$AI_KNOWLEDGE_DIR"
fi
```

Behavior contract:
- The warning is written to **stderr**; exit code is unchanged (0 on success).
- `$_KNOWLEDGE_DIR` is an **empty string** on failure; downstream blocks guard
  with `[ -n "$_KNOWLEDGE_DIR" ]` before enumerating categories.
- The warning fires every invocation when the variable is missing or bad.
  This is intentional — it nudges configuration rather than silently losing
  the feature. Suppression is deliberately out of scope in v1.
- Resolution runs **after** Path Resolution so the skill's own discovery
  cannot fail because of a user-configured knowledge dir.

See [WORKFLOW.md §Knowledge Configuration](WORKFLOW.md#knowledge-configuration)
for setup instructions, the layout convention, and the `.knowledge.yml` schema.

## Knowledge Helpers

Four shared bash helper functions used by every Knowledge block below
(Loading, On-Demand Matching, Diagnostic). The canonical implementation
lives in `bin/knowledge-helpers.sh` — a sourceable file, not inline.

**Runtime note:** Each `## Knowledge ...` code block in SKILL.md runs as its
own Bash tool invocation — functions defined in one block don't persist to
the next. So every block independently sources `bin/knowledge-helpers.sh`
using the same 2-level fallback chain as Path Resolution (workbench repo
first, deployed `~/.claude/` second). One canonical definition, sourced from
multiple invocations — no inline duplication, no drift tripwire needed.

**Helper contract:**

| Function | Input | Output | Behavior |
|---|---|---|---|
| `parse_knowledge_yml(path)` | path to `.knowledge.yml` | `always` \| `on-demand` \| empty | Returns the surface value. Empty on missing file, unknown surface, or malformed yml. Tolerates: `surface: always`, `surface: "always"` (double-quoted), `surface: always # comment` (inline comment), CRLF line endings, UTF-8 BOM, trailing whitespace. Single-quoted values (`surface: 'always'`) are NOT supported — rejected as malformed. |
| `parse_knowledge_triggers(path)` | path to `.knowledge.yml` | newline-separated triggers (quotes stripped) | Parses the `triggers:` list. Supports inline flow form (`triggers: [a, "b c", 'd']`) and block form (`triggers:\n  - a\n  - "b c"`). Quotes (single or double) stripped on output; empty list or missing key returns empty. |
| `list_categories(root)` | knowledge dir absolute path | newline-separated absolute paths to immediate subdirs | Skips hidden dirs. Lex-sorted under `LC_ALL=C` for locale-independent determinism. |
| `list_md_files(category)` | category absolute path | newline-separated absolute paths to `*.md` files | Recursive. Lex-sorted under `LC_ALL=C`. |

```bash
# Resolve and source the canonical helpers. Each Knowledge block below uses
# the same pattern — paste verbatim into any block that needs the helpers.
_RR=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$_RR" ] && [ -f "$_RR/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
  . "$_RR/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
elif [ -f "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
  . "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
fi
```

## Knowledge Loading

After Knowledge Resolution sets `$_KNOWLEDGE_DIR` and the helpers contract is
established, this block enumerates always-on knowledge categories and emits
absolute paths under `## Always-On Knowledge`. Claude is instructed to Read
every listed path before answering.

**Preconditions enforced in order** (all fail-closed):

1. Must be in a git repo (used for `_REPO_ROOT` to resolve the canonical helpers).
2. `$AI_KNOWLEDGE_DISABLE` must be unset (one-shot escape hatch — use when
   debugging a bad knowledge file without unsetting the env var).
3. `$_KNOWLEDGE_DIR` must be non-empty (S000004 owns the unset/invalid warnings).
4. Total emitted content must be ≤ 500 paths AND ≤ 100KB. Either cap tripped
   → hard-fail warning, no loading (better loud failure than silent context
   blowup).

Cross-context isolation is the user's responsibility: scope `$AI_KNOWLEDGE_DIR`
per shell (don't export it globally if you have multiple clients), or use
`AI_KNOWLEDGE_DISABLE=1` for one-shot bypass.

When all preconditions pass, enumerate categories via `list_categories`. For
each category with `surface: always`, emit every `*.md` file path (recursive,
lex-sorted). `surface: on-demand` categories are not emitted here — they're
handled by the `## On-Demand Matching` section below.

**Malformed yml** (any non-empty yml that doesn't parse as the supported subset)
emits a one-line stderr warning naming the file and skips the category; sibling
categories are unaffected.

**Missing yml** is a silent skip (legitimate "in progress" state, not an error).

```bash
(
  # Fail-closed: not in a git repo
  _REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
  [ -z "$_REPO_ROOT" ] && exit 0

  # Escape hatch: one-shot disable. Accept only explicit truthy values (1/true/yes).
  # Other non-empty values like "false" or "0" leave loading enabled — matches
  # user intuition better than "any non-empty string = disable".
  case "${AI_KNOWLEDGE_DISABLE:-}" in
    1|true|TRUE|True|yes|YES|Yes|on|ON) exit 0 ;;
  esac

  # Re-resolve env var (same semantics as S000004 — no warnings, S000004 owns them)
  _KDIR=""
  if [ -n "${AI_KNOWLEDGE_DIR:-}" ] && [ -d "$AI_KNOWLEDGE_DIR" ]; then
    _KDIR="$AI_KNOWLEDGE_DIR"
  fi
  [ -z "$_KDIR" ] && exit 0

  # Source canonical helpers from bin/knowledge-helpers.sh (see ## Knowledge Helpers)
  if [ -f "$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
    . "$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
  elif [ -f "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
    . "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
  else
    echo "[knowledge] helpers not found at \$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh or ~/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh — knowledge loading disabled" >&2
    exit 0
  fi

  # Enumerate categories and collect always-on paths
  _PATH_CAP=500
  _BYTE_CAP=102400
  _path_count=0
  _byte_total=0
  _paths=""

  while IFS= read -r _cat; do
    [ -n "$_cat" ] || continue
    # Reject category paths with control chars (newline/CR) — they'd forge the
    # emitted ## Always-On Knowledge block's line structure.
    case "$_cat" in *$'\n'*|*$'\r'*) continue ;; esac
    _sfc=$(parse_knowledge_yml "$_cat/.knowledge.yml")
    case "$_sfc" in
      always)
        while IFS= read -r _md; do
          [ -f "$_md" ] || continue
          # Same rejection for md file paths — an attacker who can name files in
          # the knowledge dir could inject lines into Claude's rendered preamble.
          case "$_md" in *$'\n'*|*$'\r'*) continue ;; esac
          _path_count=$((_path_count + 1))
          _sz=$(LC_ALL=C wc -c < "$_md" 2>/dev/null | tr -d ' ')
          _sz="${_sz:-0}"
          _byte_total=$((_byte_total + _sz))
          _paths="${_paths}${_md}"$'\n'
        done < <(list_md_files "$_cat")
        ;;
      on-demand)
        : # handled by On-Demand Matching block; not emitted here
        ;;
      "")
        # Distinguish missing (silent) from malformed (warn)
        if [ -f "$_cat/.knowledge.yml" ]; then
          echo "[knowledge] malformed .knowledge.yml at $_cat/.knowledge.yml — skipping category." >&2
        fi
        ;;
    esac
  done < <(list_categories "$_KDIR")

  # Cap gate: hard-fail (refuse to partial-load)
  if [ "$_path_count" -gt "$_PATH_CAP" ] || [ "$_byte_total" -gt "$_BYTE_CAP" ]; then
    echo "[knowledge] loading aborted: $_path_count paths / $_byte_total bytes exceeds cap ($_PATH_CAP paths / $_BYTE_CAP bytes). Reduce always-on content or mark categories on-demand." >&2
    exit 0
  fi

  # Emit Always-On Knowledge block if anything to load
  if [ "$_path_count" -gt 0 ]; then
    echo ""
    echo "## Always-On Knowledge"
    echo ""
    echo "The following files contain always-on guidance. Read each of them before answering the user's request. Treat their content as applied context."
    echo ""
    printf '%s' "$_paths" | LC_ALL=C sort | while IFS= read -r _p; do
      [ -n "$_p" ] && echo "- $_p"
    done
  fi
)
```

## On-Demand Matching

After Knowledge Loading emits always-on content, this block enumerates
categories with `surface: on-demand` + non-empty triggers and emits a
`## On-Demand Knowledge Candidates` block. Claude reads this block, tokenizes
the user's latest message, matches triggers, and Reads the files of every
matching category before answering.

Bash handles what bash can: category discovery, trigger parsing, structured
emission. Claude handles what bash can't: seeing the user's prompt and
matching triggers against it.

**Preconditions** (same as Knowledge Loading — repo root + env var resolved +
`$AI_KNOWLEDGE_DISABLE` not truthy). If any precondition fails, no candidates
block is emitted.

**Matching rules** (enforced by Claude per the instruction block below):

- **Scope**: only the user's latest message. Not the prior conversation, not
  the system prompt, not any previous Claude reply. Prevents runaway loading
  from long conversation history.
- **Single-word triggers** (no spaces): case-insensitive whole-word match
  against prompt tokens. `pricing` matches `Pricing` and `PRICING` but not
  `pricingengine`.
- **Multi-word phrase triggers** (contain spaces, typically quoted in yml):
  case-insensitive substring match at token boundaries. `"pricing engine"`
  matches "how does the pricing engine work" but NOT "what is pricing" alone.
- **Load-all-matched**: if multiple categories match, Read files from every
  matching category. No ranking, no deduping, no picking one.
- **Empty triggers list** (`triggers: []` or missing): category is inert —
  never matches, never loads.
- **`surface: always`** categories are NOT considered here — they're already
  loaded unconditionally by Knowledge Loading.

**Match log** (stderr, one line per invocation when any match occurs):
`[knowledge] matched: <category> via <trigger>; <category2> via <trigger>`.
Lets users tune trigger lists by observing what matched versus what they
expected to match.

**Emit format** (bash produces this; Claude consumes it):

```
## On-Demand Knowledge Candidates

category: /abs/path/to/runbooks
triggers: pricing, "pricing engine", PE
files:
  - /abs/path/to/runbooks/overview.md
  - /abs/path/to/runbooks/engine.md

category: /abs/path/to/security
triggers: auth, OAuth
files:
  - /abs/path/to/security/tokens.md
```

**Claude-facing instructions** — must be followed verbatim:

After the `## On-Demand Knowledge Candidates` block:

1. Tokenize the user's most recent message (not prior turns). Split on
   whitespace and common punctuation. Fold to lowercase for comparison.
2. For each category entry in the block:
   - For each trigger in that category's `triggers:` list:
     - If the trigger contains no spaces: check whether a case-insensitive
       whole-word match against any prompt token succeeds.
     - If the trigger contains spaces (was quoted in yml): check whether
       the case-folded prompt contains the case-folded trigger phrase at
       token boundaries (i.e., preceded and followed by whitespace or
       punctuation, or at string edges).
   - If any trigger matches, the category matches.
3. For every matching category, use the Read tool to Read every file listed
   under that category's `files:` list, before answering the user's request.
4. Emit exactly one stderr line naming every match:
   `[knowledge] matched: <category> via <trigger>; <category2> via <trigger>`.
   Use the first trigger that matched per category. Omit the line if no
   category matched.

```bash
(
  # Preconditions: share the same fail-closed gates as Knowledge Loading.
  _REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
  [ -z "$_REPO_ROOT" ] && exit 0
  case "${AI_KNOWLEDGE_DISABLE:-}" in
    1|true|TRUE|True|yes|YES|Yes|on|ON) exit 0 ;;
  esac
  _KDIR=""
  if [ -n "${AI_KNOWLEDGE_DIR:-}" ] && [ -d "$AI_KNOWLEDGE_DIR" ]; then
    _KDIR="$AI_KNOWLEDGE_DIR"
  fi
  [ -z "$_KDIR" ] && exit 0

  # Source canonical helpers from bin/knowledge-helpers.sh (see ## Knowledge Helpers)
  if [ -f "$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
    . "$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
  elif [ -f "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
    . "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
  else
    echo "[knowledge] helpers not found at \$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh or ~/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh — on-demand matching disabled" >&2
    exit 0
  fi

  # Collect on-demand categories with non-empty triggers + at least one md file.
  # Skip control-char category paths (same rejection as Knowledge Loading).
  _first=1
  while IFS= read -r _cat; do
    [ -n "$_cat" ] || continue
    case "$_cat" in *$'\n'*|*$'\r'*) continue ;; esac
    _sfc=$(parse_knowledge_yml "$_cat/.knowledge.yml")
    [ "$_sfc" = "on-demand" ] || continue
    # Parse triggers
    _trigs=$(parse_knowledge_triggers "$_cat/.knowledge.yml")
    [ -n "$_trigs" ] || continue
    # Enumerate md files
    _files=""
    _fcount=0
    while IFS= read -r _md; do
      [ -f "$_md" ] || continue
      case "$_md" in *$'\n'*|*$'\r'*) continue ;; esac
      _files="${_files}  - ${_md}"$'\n'
      _fcount=$((_fcount + 1))
    done < <(list_md_files "$_cat")
    [ "$_fcount" -gt 0 ] || continue

    # Emit header once, on first emitted candidate
    if [ "$_first" = "1" ]; then
      echo ""
      echo "## On-Demand Knowledge Candidates"
      echo ""
      echo "For each candidate below, tokenize the user's latest message, match every trigger against the prompt (case-insensitive whole-word for single tokens; case-insensitive phrase at token boundaries for multi-word phrases), and if any trigger matches, use the Read tool to Read every file listed under that candidate's files: list before answering. Log matches to stderr as [knowledge] matched: <category> via <trigger>; <category2> via <trigger> (one line per invocation, omit if zero matches). Consider only the user's most recent message — not prior turns."
      echo ""
      _first=0
    fi
    # Format triggers as comma-separated (quote phrases with spaces for readability)
    _trig_csv=$(printf '%s\n' "$_trigs" | LC_ALL=C awk 'BEGIN{ORS=""} NR>1{print ", "} /[[:space:]]/{printf "\"%s\"", $0; next} {print $0}')
    echo "category: $_cat"
    echo "triggers: $_trig_csv"
    echo "files:"
    printf '%s' "$_files"
    echo ""
  done < <(list_categories "$_KDIR")
)
```

## Diagnostic: knowledge-doctor

When the user runs `/CJ_company-workflow knowledge-doctor`, execute the bash
block below and print its output. It surfaces the exact state of every
precondition and every category so the user can diagnose setup issues without
writing an E2E canary.

**Sample output (all preconditions pass):**

```
AI_KNOWLEDGE_DIR: /Users/chjiang/knowledge (exists)
repo_root: /Users/chjiang/Documents/projects/claude-skills-templates
disable env var: not set
categories:
  coding      surface=always     files=3    bytes=8.2KB    loads=yes
  runbooks    surface=on-demand  files=5    bytes=12.1KB   loads=on-match (triggers: pricing, "pricing engine")
  staging     surface=on-demand  files=2    bytes=1.4KB    loads=no (empty triggers)
  notes       surface=(missing yml)         loads=no
  broken      surface=(malformed yml)       loads=no (warning)
cap status: 3/500 paths, 8.2KB/100KB bytes
result: loading enabled; 3 paths will be emitted to Claude
```

```bash
(
  _REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "(not in git)")
  echo "repo_root: $_REPO_ROOT"

  if [ -z "${AI_KNOWLEDGE_DIR:-}" ]; then
    echo "AI_KNOWLEDGE_DIR: (unset)"
    echo "result: loading disabled — run: export AI_KNOWLEDGE_DIR=\$HOME/knowledge"
    exit 0
  elif [ ! -e "$AI_KNOWLEDGE_DIR" ]; then
    echo "AI_KNOWLEDGE_DIR: $AI_KNOWLEDGE_DIR (does not exist)"
    echo "result: loading disabled — create the dir or fix the path"
    exit 0
  elif [ ! -d "$AI_KNOWLEDGE_DIR" ]; then
    echo "AI_KNOWLEDGE_DIR: $AI_KNOWLEDGE_DIR (not a directory)"
    echo "result: loading disabled — point env var at a directory"
    exit 0
  else
    echo "AI_KNOWLEDGE_DIR: $AI_KNOWLEDGE_DIR (exists)"
  fi

  _DISABLE_DISPLAY=$(printf '%s' "${AI_KNOWLEDGE_DISABLE:-}" | LC_ALL=C tr -d '[:cntrl:]')
  [ ${#_DISABLE_DISPLAY} -gt 64 ] && _DISABLE_DISPLAY="${_DISABLE_DISPLAY:0:64}..."
  # Same truthy-value policy as Loading block
  case "${AI_KNOWLEDGE_DISABLE:-}" in
    1|true|TRUE|True|yes|YES|Yes|on|ON)
      echo "disable env var: AI_KNOWLEDGE_DISABLE=$_DISABLE_DISPLAY (set — all loading suppressed)"
      echo "result: loading disabled by AI_KNOWLEDGE_DISABLE"
      exit 0
      ;;
    '')
      echo "disable env var: not set"
      ;;
    *)
      echo "disable env var: AI_KNOWLEDGE_DISABLE=$_DISABLE_DISPLAY (non-truthy, ignored)"
      ;;
  esac

  # Source canonical helpers from bin/knowledge-helpers.sh (see ## Knowledge Helpers)
  if [ -n "$_REPO_ROOT" ] && [ "$_REPO_ROOT" != "(not in git)" ] && [ -f "$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
    . "$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
  elif [ -f "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
    . "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
  else
    echo "result: knowledge-doctor disabled — helpers not found at \$_REPO_ROOT/skills/CJ_company-workflow/bin/knowledge-helpers.sh or ~/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
    exit 0
  fi

  echo "categories:"
  _total_paths=0
  _total_bytes=0
  while IFS= read -r _cat; do
    [ -n "$_cat" ] || continue
    _cname=$(basename "$_cat")
    if [ -f "$_cat/.knowledge.yml" ]; then
      _sfc=$(parse_knowledge_yml "$_cat/.knowledge.yml")
      if [ -z "$_sfc" ]; then
        printf "  %-12s surface=(malformed yml)       loads=no (warning)\n" "$_cname"
        continue
      fi
    else
      printf "  %-12s surface=(missing yml)         loads=no\n" "$_cname"
      continue
    fi
    _fcount=0
    _bcount=0
    while IFS= read -r _md; do
      [ -f "$_md" ] || continue
      _fcount=$((_fcount + 1))
      _sz=$(LC_ALL=C wc -c < "$_md" 2>/dev/null | tr -d ' ')
      _sz="${_sz:-0}"
      _bcount=$((_bcount + _sz))
    done < <(list_md_files "$_cat")
    _hk=$(awk "BEGIN { printf \"%.1f\", $_bcount / 1024 }")
    case "$_sfc" in
      always)
        _total_paths=$((_total_paths + _fcount))
        _total_bytes=$((_total_bytes + _bcount))
        printf "  %-12s surface=always     files=%-4d bytes=%sKB   loads=yes\n" "$_cname" "$_fcount" "$_hk"
        ;;
      on-demand)
        # c3: parse triggers to distinguish loadable (on-match) vs inert (empty triggers)
        _trigs=$(parse_knowledge_triggers "$_cat/.knowledge.yml")
        if [ -z "$_trigs" ]; then
          printf "  %-12s surface=on-demand  files=%-4d bytes=%sKB   loads=no (empty triggers)\n" "$_cname" "$_fcount" "$_hk"
        else
          _trig_csv=$(printf '%s\n' "$_trigs" | LC_ALL=C awk 'BEGIN{ORS=""} NR>1{print ", "} /[[:space:]]/{printf "\"%s\"", $0; next} {print $0}')
          printf "  %-12s surface=on-demand  files=%-4d bytes=%sKB   loads=on-match (triggers: %s)\n" "$_cname" "$_fcount" "$_hk" "$_trig_csv"
        fi
        ;;
    esac
  done < <(list_categories "$AI_KNOWLEDGE_DIR")

  _hk_tot=$(awk "BEGIN { printf \"%.1f\", $_total_bytes / 1024 }")
  echo "cap status: $_total_paths/500 paths, ${_hk_tot}KB/100KB bytes"
  if [ "$_total_paths" -gt 500 ] || [ "$_total_bytes" -gt 102400 ]; then
    echo "result: loading disabled — cap exceeded. Reduce always-on content."
  elif [ "$_total_paths" -eq 0 ]; then
    echo "result: loading enabled but no always-on categories to load"
  else
    echo "result: loading enabled; $_total_paths paths will be emitted to Claude"
  fi
)
```

## Template Registry

This skill reads `template-registry.json` at the repo root to discover its
template set. The registry declares all template sets with their paths, types,
and validation contracts.

```bash
_REGISTRY="$_REPO_ROOT/template-registry.json"
if [ -f "$_REGISTRY" ]; then
  echo "REGISTRY: $_REGISTRY"
else
  echo "NO_REGISTRY"
fi
```

If `NO_REGISTRY`: the skill can still function using `_TMPL_DIR` from path
resolution. The registry is metadata, not a runtime dependency.

## Template-Derived Rules

Every structural rule the validator enforces comes from parsing the matching
template at runtime. The derivation contract:

| Rule | Derivation |
|---|---|
| Required frontmatter fields | All keys present in the template's YAML frontmatter |
| Required sections | All `## ` headers in the template, in document order |
| Expected section order | The template's `##` header order |
| Required lifecycle phases | All `### Phase N: {name}` headers in the template's `## Lifecycle` section |
| Minimum checkbox count | Count of `- [ ]` and `- [x]` patterns inside the template's `## Lifecycle` section |
| Optional sections (per type) | Inferred structurally — if the per-type template includes the section, it's required for that type; if absent, it's not allowed (extras flagged as advisory `[EXTRA]`) |
| Unresolved placeholder detection | Scan the instance's frontmatter values for `\{[A-Z_]+\}` patterns — these indicate the scaffolder didn't substitute a placeholder |

When the template changes, the validator's expectations change automatically.
When a new section, phase, or gate is added to a template, instances that
predate the change are flagged. There is no separate spec to keep in sync.

## Command: validate

One command with two modes. Pass a file path for structural validation. Pass a
directory path for artifact completeness validation.

### Usage

```
/CJ_company-workflow validate <path>
```

If `<path>` is a file: run **File Mode**.
If `<path>` is a directory: run **Directory Mode**.

---

### File Mode

Validates a single tracker file against its template-derived rules.

#### Steps

1. Read the target file and parse its YAML frontmatter (between `---` markers).
   If frontmatter cannot be parsed: `VIOLATION: could not parse YAML frontmatter in {path}` and stop.

2. If the file does not contain a `## Lifecycle` section, warn:
   `Warning: {path} does not look like a tracker file. File-mode validation only validates trackers — for doc artifacts (PRD, RCA, test-plan, etc.), use Directory Mode on the parent directory.`
   Then stop (do not produce false positives by validating a doc against a tracker template).

3. Read the `type` field from frontmatter. Normalize spelling: `userstory` and
   `user-story` both normalize to `user-story`. Verify type is one of
   `feature`, `defect`, `task`, `user-story`, `review`. If unknown:
   `VIOLATION: unknown type "{value}" in {path}` and stop.

4. Resolve the matching template at `$_TMPL_DIR/tracker-{type}.md` via the
   2-level fallback chain. If the template cannot be found:
   `Error: template tracker-{type}.md not found at {_TMPL_DIR} or ~/.claude/templates/CJ_company-workflow/. Run skills-deploy install.` and stop.

5. Parse the template:
   - Frontmatter keys → `required_fields`
   - `##` headers in document order → `expected_sections`
   - `### Phase N:` headers in document order under the template's Lifecycle section → `required_phases`
   - Count of `- [ ]` and `- [x]` patterns inside the template's Lifecycle section → `min_checkboxes`

6. Parse the instance:
   - Frontmatter keys → `present_fields`
   - `##` headers in document order → `present_sections`
   - `### Phase N:` headers under the instance's Lifecycle section → `present_phases`
   - Count of `- [ ]` and `- [x]` patterns inside the instance's Lifecycle section → `present_checkbox_count`

7. Compare and emit violations:

   **Frontmatter:**
   - For each field in `required_fields`: if missing from `present_fields` → `VIOLATION: missing required field "{field}" in {path}`
   - For each frontmatter value in the instance: scan for `\{[A-Z_]+\}` placeholder patterns. If found → `VIOLATION: unresolved placeholder "{placeholder}" in frontmatter of {path}`

   **Sections:**
   - For each section in `expected_sections`: if missing from `present_sections` → `VIOLATION: missing section "{section}" in {path}`
   - For each section in `present_sections` not in `expected_sections` → `[EXTRA] unexpected section "{section}" in {path}` (advisory only, not a hard violation)
   - Filter `expected_sections` to only sections actually present in the instance, then assert `present_sections` matches that filtered list in order. If not → `VIOLATION: section order mismatch — "{section}" appears before "{other}" in {path}`

   **Lifecycle:**
   - For each phase in `required_phases`: if not in `present_phases` → `VIOLATION: missing phase "{phase}" in {path}`
   - If `present_checkbox_count` < `min_checkboxes` → `VIOLATION: lifecycle has {N} checkboxes, minimum is {min} (per template) in {path}`

8. Report results:
   - Exit 0 if no violations: `VALID: {path}`
   - Exit 1 if any violations: print each to stderr, then a summary

---

### Directory Mode

Validates an entire work item directory for artifact completeness, frontmatter
compliance, and lifecycle structure. Validates the **immediate directory only**
(no recursive descent into child directories). To validate a feature and its
children, run validate on each directory separately.

#### Filename Matching Rule

Strip the leading ID prefix (regex `^[A-Z]\d+_`) to get the canonical filename,
then compare against the manifest's `filename` field. Examples:
- `S000003_PRD.md` -> strip `S000003_` -> `PRD.md` (matches manifest)
- `F000003_TRACKER.md` -> strip `F000003_` -> `TRACKER.md` (matches manifest)
- `T000002_test-plan.md` -> strip `T000002_` -> `test-plan.md` (matches manifest)

#### Per-Artifact Validation

For each required artifact in the manifest, after locating the file, validate
its frontmatter against ITS template (looked up from the manifest's `template`
field):

1. Resolve the template file from `$_TMPL_DIR/{template}` (using the 2-level
   fallback chain from Path Resolution)
2. Parse the template's YAML frontmatter to extract its key names
3. Parse the artifact's YAML frontmatter
4. For each key present in the template's frontmatter: check that the same key
   exists in the artifact. Comparison is key-presence only (values contain
   placeholders in templates).
   - Missing key: `[DRIFT] {artifact} — missing required field "{field}"`
5. Check for unresolved placeholders: scan frontmatter values for `\{[A-Z_]+\}` patterns.
   If found: `[DRIFT] {artifact} — unresolved placeholder "{placeholder}" in frontmatter`

For tracker artifacts (the file matching `TRACKER.md`), additionally apply the
full File Mode validation flow above (sections, lifecycle, phases, checkboxes).

#### Directory Mode Error Handling

- No TRACKER.md found: `"Error: no TRACKER.md found in {directory}. Not a work item directory."`
- company-artifact-manifests.json missing: `"Error: company-artifact-manifests.json not found at {path}. Run skills-deploy install or check skill structure."`
- Template file missing: `"Warning: template {filename} not found at {path}. Skipping frontmatter validation for {artifact}."`

#### Steps

Path Resolution runs first (same as file mode). `$_SKILL_DIR` and `$_TMPL_DIR`
are available for config and template lookup throughout directory mode.

1. **Locate TRACKER.md** — Find files matching `*_TRACKER.md` or `TRACKER.md` in
   the directory. If multiple matches, use the first one alphabetically.

2. **Read type** — Parse frontmatter `type` field. Normalize spelling:
   `userstory` and `user-story` are both accepted (normalized to `user-story`).
   Verify type is one of the 5 known types (feature, defect, task, user-story,
   review). If unknown:
   `[WARN] — type "{value}" not recognized`

3. **Load manifest** — Read `$_SKILL_DIR/company-artifact-manifests.json`. Find
   the type entry in the `types` object.

4. **Check artifact completeness** — For each required artifact in the manifest:
   - List all `.md` files in the directory
   - Match files using the Filename Matching Rule above
   - If missing: `[MISSING] {artifact} — required artifact not found`
   - If found: validate frontmatter using Per-Artifact Validation above
     (including placeholder detection)

5. **Check tracker structure** — Apply File Mode steps 5-7 to the TRACKER.md
   file (template-derived sections, phases, and checkbox count). Same violation
   messages as File Mode, but emitted under the directory report's `LIFECYCLE:`
   block.

6. **Report** — Emit structured output:
   ```
   COMPANY-WORKFLOW VALIDATE: {directory}
     Type: {type}
     ARTIFACTS:
       [PASS]    TRACKER.md — all required fields present
       [PASS]    PRD.md — all required fields and sections present
       [MISSING] test-plan.md — required artifact not found
       [DRIFT]   ARCHITECTURE.md — missing required field "repo"
     LIFECYCLE:
       [PASS]    4 phases present, 12 checkboxes (min 12 per template)
     SUMMARY: 4 artifacts checked, 1 missing, 1 drift
   ```

## Reference Guides

Generation guides for AI doc creation live at `$_SKILL_DIR/reference/`:

| Guide | Purpose |
|---|---|
| guide-general.md | General generation instructions |
| guide-prd.md | PRD generation from user input |
| guide-architecture.md | Architecture doc generation |
| guide-test-spec.md | Test spec generation |
| guide-rca.md | Root cause analysis generation |
| guide-task.md | Task doc generation |
| guide-review-notes.md | Review notes generation |

## Philosophy

Design rationale for the lifecycle system lives at `$_SKILL_DIR/philosophy/`:

| Doc | Purpose |
|---|---|
| rationale-PRD.md | Why the PRD structure works this way |
| rationale-ARCHITECTURE.md | Why the architecture doc is structured this way |
| rationale-TEST-SPEC.md | Why the two-tier test model |

## Fixtures

Validation test fixtures live at `$_SKILL_DIR/fixtures/`:

### File Mode Fixtures

| Fixture | What it tests |
|---|---|
| invalid-bad-frontmatter.md | Missing or malformed YAML frontmatter |
| invalid-missing-lifecycle.md | Tracker without Lifecycle section |
| invalid-wrong-order.md | Sections in wrong order |

### Directory Mode Fixtures

| Fixture | What it tests |
|---|---|
| valid-feature-dir/ | Complete feature with all 3 required artifacts (tracker + feature-summary + milestones) |
| invalid-missing-artifact-dir/ | Feature with only TRACKER.md — should produce [MISSING] for feature-summary and milestones |

Use these to verify the `validate` command catches violations correctly.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_company-workflow requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_company-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| Target file not found | "Error: file not found: {path}" | Check the path |
| Unparseable frontmatter | "VIOLATION: could not parse YAML frontmatter in {path}" | Fix the frontmatter |
| Template not found | "Error: template tracker-{type}.md not found." | Run `skills-deploy install` or check template deployment |
| Unknown type | "VIOLATION: unknown type \"{value}\" in {path}" | Fix the `type` field |
| Not a tracker | "Warning: {path} does not look like a tracker file." | Use Directory Mode for doc artifacts |
| No TRACKER.md in directory | "Error: no TRACKER.md found in {directory}. Not a work item directory." | Check the path |
| Manifest missing | "Error: company-artifact-manifests.json not found." | Reinstall skill |
