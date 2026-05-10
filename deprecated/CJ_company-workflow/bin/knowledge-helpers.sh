# shellcheck shell=bash
# Canonical knowledge helpers for /CJ_company-workflow knowledge features.
# Source this file from any Bash block that needs knowledge parsing or
# enumeration; do not duplicate the definitions inline.
#
# Resolution from a sourcing block (paste-ready):
#   _RR=$(git rev-parse --show-toplevel 2>/dev/null)
#   if [ -n "$_RR" ] && [ -f "$_RR/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
#     . "$_RR/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
#   elif [ -f "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh" ]; then
#     . "$HOME/.claude/skills/CJ_company-workflow/bin/knowledge-helpers.sh"
#   else
#     echo "[knowledge] helpers not found — knowledge features disabled" >&2
#     exit 0
#   fi
#
# All output is locale-independent (LC_ALL=C). Hidden files/dirs are skipped.
# Symlinks are followed at the root level (find -H), per the original
# AI_KNOWLEDGE_DIR-may-be-a-symlink contract.

# parse_knowledge_yml(path) → always | on-demand | empty
# Empty on missing file, unknown surface, or malformed yml. Tolerates:
# - Bare or double-quoted values (`surface: always`, `surface: "always"`)
# - Inline comments (`surface: always # house style`)
# - CRLF line endings, UTF-8 BOM, trailing whitespace
# Single-quoted values are NOT supported (rejected as malformed).
# Strict root-key validation: any non-{surface,triggers} root key = malformed.
parse_knowledge_yml() {
  local path="$1"
  [ -f "$path" ] || { printf ''; return; }
  local surface
  surface=$(LC_ALL=C awk '
    NR == 1 {
      if (substr($0, 1, 3) == sprintf("%c%c%c", 239, 187, 191)) $0 = substr($0, 4)
    }
    { sub(/\r$/, ""); sub(/#.*$/, "") }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*surface[[:space:]]*:/ {
      val = $0
      sub(/^[[:space:]]*surface[[:space:]]*:[[:space:]]*/, "", val)
      sub(/[[:space:]]*$/, "", val)
      if (substr(val, 1, 1) == "\"" && substr(val, length(val), 1) == "\"")
        val = substr(val, 2, length(val)-2)
      surface_val = val
      next
    }
    /^[[:space:]]*triggers[[:space:]]*:/ { next }
    /^[[:space:]]+-/ { next }
    { malformed = 1; exit }
    END {
      if (malformed) { print ""; exit }
      print surface_val
    }
  ' "$path" 2>/dev/null)
  case "$surface" in
    always|on-demand) printf '%s' "$surface" ;;
    *) printf '' ;;
  esac
}

# parse_knowledge_triggers(path) → newline-separated triggers (quotes stripped)
# Supports inline flow form (`triggers: [a, "b c", 'd']`) and block form
# (`triggers:\n  - a\n  - "b c"`). Quotes (single or double) stripped on output.
# Empty list, missing key, or malformed yml returns empty.
parse_knowledge_triggers() {
  local path="$1"
  [ -f "$path" ] || return 0
  LC_ALL=C awk '
    NR == 1 {
      if (substr($0, 1, 3) == sprintf("%c%c%c", 239, 187, 191)) $0 = substr($0, 4)
    }
    { sub(/\r$/, ""); sub(/#.*$/, "") }
    /^[[:space:]]*$/ { next }
    # Inline flow form: triggers: [...]
    /^[[:space:]]*triggers[[:space:]]*:[[:space:]]*\[/ {
      val = $0
      sub(/^[[:space:]]*triggers[[:space:]]*:[[:space:]]*\[/, "", val)
      sub(/\].*$/, "", val)
      n = split(val, items, ",")
      for (i = 1; i <= n; i++) {
        t = items[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
        if (substr(t, 1, 1) == "\"" && substr(t, length(t), 1) == "\"")
          t = substr(t, 2, length(t) - 2)
        else if (substr(t, 1, 1) == "'"'"'" && substr(t, length(t), 1) == "'"'"'")
          t = substr(t, 2, length(t) - 2)
        if (t != "") print t
      }
      in_triggers = 0
      next
    }
    # Block form header: triggers:
    /^[[:space:]]*triggers[[:space:]]*:[[:space:]]*$/ {
      in_triggers = 1
      next
    }
    # Block form item
    in_triggers && /^[[:space:]]+-[[:space:]]*/ {
      t = $0
      sub(/^[[:space:]]+-[[:space:]]*/, "", t)
      sub(/[[:space:]]*$/, "", t)
      if (substr(t, 1, 1) == "\"" && substr(t, length(t), 1) == "\"")
        t = substr(t, 2, length(t) - 2)
      else if (substr(t, 1, 1) == "'"'"'" && substr(t, length(t), 1) == "'"'"'")
        t = substr(t, 2, length(t) - 2)
      if (t != "") print t
      next
    }
    /^[[:space:]]*surface[[:space:]]*:/ { in_triggers = 0; next }
    /^[^[:space:]]/ { exit }
  ' "$path" 2>/dev/null
}

# list_categories(root) → newline-separated absolute paths to immediate subdirs.
# Skips hidden dirs. Lex-sorted (LC_ALL=C). Uses find -H so a symlinked root
# (common when AI_KNOWLEDGE_DIR is itself a symlink from a dotfile manager /
# iCloud) still descends.
list_categories() {
  local root="$1"
  [ -d "$root" ] || return 0
  LC_ALL=C find -H "$root" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | LC_ALL=C sort
}

# list_md_files(category) → newline-separated absolute paths to *.md files
# under the category, recursively, lex-sorted (LC_ALL=C). Skips hidden dirs,
# so .hidden/draft.md inside a category isn't emitted.
list_md_files() {
  local category="$1"
  [ -d "$category" ] || return 0
  LC_ALL=C find -H "$category" -type f -name '*.md' ! -path '*/.*' 2>/dev/null | LC_ALL=C sort
}
