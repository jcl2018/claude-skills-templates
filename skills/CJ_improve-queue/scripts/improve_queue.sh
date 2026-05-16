#!/usr/bin/env bash
# improve_queue.sh — Phase 1 (S000048): /CJ_improve-queue evaluate <url> envelope.
#
# Three sub-commands:
#   evaluate <url>          One-shot orchestrator entry. Emits HANDOFF block on stdout;
#                           orchestrator parses, dispatches Agent, captures verdict,
#                           pipes back into `apply`. (NOTE: bash cannot reach Agent
#                           directly — re-invocation contract per /CJ_goal_todo_fix's pattern.)
#   evaluate-prepare <url>  Subset of evaluate: preflight + canonicalize + emit HANDOFF,
#                           then exit 0. Useful in isolation for orchestrator testing.
#   apply                   Read verdict JSON from stdin, append (or NO-OP) a draft
#                           TODOS.md row.
#
# Optional flags:
#   --allow-untrusted-source   Skip the source-domain allowlist gate.
#
# Test hook:
#   CJ_IMPROVE_QUEUE_VERDICT_FILE=<path>   In `evaluate`, skip HANDOFF/Agent step and
#                                           read verdict from the named file (test fixture
#                                           injection). Mirrors the subagent boundary.
#
# Owns: I/O (stdin/stdout), URL canonicalization, allowlist gate, preflight (Darwin +
#       dirty TODOS.md), signature, idempotency probe, mkdir-based write-lock, atomic
#       mv, heading-regex post-write validation, backup rotation.
# Does NOT own: WebFetch, reasoning. That's the subagent's job (called by SKILL.md
#               orchestrator prose).
#
# See: skills/CJ_improve-queue/SKILL.md (orchestrator), S000048_SPEC.md (acceptance).

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

TMP_BASE="/tmp/cj-improve-queue"
LOCK_DIR="/tmp/cj-improve-queue-lock"
BACKUP_RETAIN=5
LOCK_RETRIES=3
LOCK_SLEEP_SEC="0.5"

# Default allowlist (trusted Anthropic surfaces). Hosts compared post-canonicalization
# (lowercased, www-stripped, default-port-dropped). The github.com entry covers
# the entire host; subagent prompt can narrow to anthropics/* if needed.
ALLOWLIST_HOSTS=(
  "docs.anthropic.com"
  "anthropic.com"
  "claude.com"
  "github.com"
)

# Query parameter prefixes/exact names stripped during canonicalization.
# Match if name starts with utm_, mc_, or equals one of the explicit entries.
STRIP_PARAM_PREFIXES=("utm_" "mc_")
STRIP_PARAM_NAMES=("source" "ref" "fbclid" "gclid")

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------

log_err() {
  printf '[CJ_improve-queue] %s\n' "$*" >&2
}

# ---------------------------------------------------------------------------
# Preflight gates
# ---------------------------------------------------------------------------

# Darwin-only gate. Bail loudly on non-macOS.
check_darwin() {
  if [ "$(uname -s 2>/dev/null || echo unknown)" != "Darwin" ]; then
    log_err "macOS-only skill (uname -s = Darwin required); current OS: $(uname -s 2>/dev/null || echo unknown)"
    exit 1
  fi
}

# Repo root from current dir (caller must invoke from inside the workbench).
repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || {
    log_err "not in a git repository; refusing to run"
    exit 1
  }
}

# TODOS.md must be clean (no uncommitted changes).
check_todos_clean() {
  local root
  root="$1"
  local porcelain
  porcelain=$(git -C "$root" status --porcelain TODOS.md 2>/dev/null || true)
  if [ -n "$porcelain" ]; then
    log_err "TODOS.md has uncommitted changes — commit or stash before retry"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# URL canonicalization
# ---------------------------------------------------------------------------
#
# Rules:
#   - scheme: lowercase (https stays https; http stays http)
#   - host: lowercase, strip leading "www."
#   - port: drop :443 for https, :80 for http (default)
#   - path: strip trailing slash on path leaf (but preserve "/" as full path)
#   - query: drop params whose name starts with utm_/mc_ or matches source/ref/fbclid/gclid;
#            preserve remaining params in original order (POSIX `&` separator)
#   - fragment: strip entirely
#   - percent-encoding: uppercase hex digits in %XX sequences
#
# Implemented in pure POSIX awk + sed (no python/perl dependency).

canonicalize_url() {
  local raw="$1"
  awk -v u="$raw" -v prefixes="${STRIP_PARAM_PREFIXES[*]}" -v names="${STRIP_PARAM_NAMES[*]}" '
    BEGIN {
      url = u

      # Strip fragment.
      i = index(url, "#")
      if (i > 0) url = substr(url, 1, i - 1)

      # Split scheme://rest.
      i = index(url, "://")
      if (i == 0) { print url; exit }
      scheme = tolower(substr(url, 1, i - 1))
      rest = substr(url, i + 3)

      # Split off path/query at first "/" or "?".
      hostport = rest
      path = ""
      query = ""
      sp = index(rest, "/")
      sq = index(rest, "?")
      cut = 0
      if (sp > 0 && (sq == 0 || sp < sq)) {
        cut = sp
      } else if (sq > 0) {
        cut = sq
      }
      if (cut > 0) {
        hostport = substr(rest, 1, cut - 1)
        tail = substr(rest, cut)
        qpos = index(tail, "?")
        if (qpos > 0) {
          path = substr(tail, 1, qpos - 1)
          query = substr(tail, qpos + 1)
        } else {
          path = tail
        }
      }

      # Host + port split.
      cp = index(hostport, ":")
      if (cp > 0) {
        host = substr(hostport, 1, cp - 1)
        port = substr(hostport, cp + 1)
      } else {
        host = hostport
        port = ""
      }

      # Lowercase host; strip leading www.
      host = tolower(host)
      sub(/^www\./, "", host)

      # Drop default ports.
      if ((scheme == "https" && port == "443") || (scheme == "http" && port == "80")) {
        port = ""
      }

      # Path: strip trailing slash unless path is exactly "/".
      if (path == "" ) path = ""
      else if (path == "/") path = ""
      else if (length(path) > 1 && substr(path, length(path), 1) == "/") {
        path = substr(path, 1, length(path) - 1)
      }

      # Percent-encoding uppercase: walk and uppercase hex pairs after %.
      out = ""
      n = length(path)
      i = 1
      while (i <= n) {
        c = substr(path, i, 1)
        if (c == "%" && i + 2 <= n) {
          hex = substr(path, i + 1, 2)
          out = out "%" toupper(hex)
          i += 3
        } else {
          out = out c
          i += 1
        }
      }
      path = out

      # Filter query params.
      filtered = ""
      if (query != "") {
        split(query, parts, "&")
        for (j = 1; j <= length(parts); j++) {
          p = parts[j]
          if (p == "") continue
          eq = index(p, "=")
          if (eq > 0) name = substr(p, 1, eq - 1)
          else        name = p
          drop = 0
          # Prefix match.
          split(prefixes, pa, " ")
          for (k = 1; k <= length(pa); k++) {
            pre = pa[k]
            if (pre == "") continue
            if (index(name, pre) == 1) { drop = 1; break }
          }
          if (drop == 1) continue
          # Exact name match.
          split(names, na, " ")
          for (k = 1; k <= length(na); k++) {
            if (name == na[k]) { drop = 1; break }
          }
          if (drop == 1) continue
          if (filtered == "") filtered = p
          else                filtered = filtered "&" p
        }
      }

      # Reassemble.
      result = scheme "://" host
      if (port != "") result = result ":" port
      result = result path
      if (filtered != "") result = result "?" filtered
      print result
    }
  '
}

# Extract host (lowercased, www-stripped) from a canonical URL for allowlist check.
host_of() {
  local canon="$1"
  printf '%s' "$canon" | awk '
    {
      i = index($0, "://")
      if (i == 0) { print ""; exit }
      rest = substr($0, i + 3)
      sp = index(rest, "/")
      sq = index(rest, "?")
      cut = 0
      if (sp > 0 && (sq == 0 || sp < sq)) cut = sp
      else if (sq > 0) cut = sq
      if (cut > 0) rest = substr(rest, 1, cut - 1)
      cp = index(rest, ":")
      if (cp > 0) rest = substr(rest, 1, cp - 1)
      print tolower(rest)
    }
  '
}

# ---------------------------------------------------------------------------
# Signature
# ---------------------------------------------------------------------------

# 16-char hex truncation of sha256(canonical_url + "|" + pattern_name).
sig_of() {
  local canon="$1"
  local pattern="$2"
  printf '%s|%s' "$canon" "$pattern" | shasum -a 256 | awk '{print substr($1, 1, 16)}'
}

# ---------------------------------------------------------------------------
# Allowlist
# ---------------------------------------------------------------------------

is_allowlisted() {
  local host="$1"
  local h
  for h in "${ALLOWLIST_HOSTS[@]}"; do
    if [ "$host" = "$h" ]; then
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# In-scope skills enumeration
# ---------------------------------------------------------------------------
#
# v1: list every workbench skill's SKILL.md under `skills/`. The subagent
# decides which are pattern-relevant based on the SKILL frontmatter.

list_skill_files() {
  local root="$1"
  find "$root/skills" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort
}

# ---------------------------------------------------------------------------
# HANDOFF emission
# ---------------------------------------------------------------------------

emit_handoff() {
  local canon="$1"
  local allowlisted="$2"   # "true" or "false"
  local root="$3"
  local request_id
  request_id=$(uuidgen 2>/dev/null || printf 'r%d-%d' "$$" "$(date +%s)")

  # Build in_scope_skill_files JSON array.
  local files
  files=$(list_skill_files "$root" | jq -R . | jq -s .)

  echo "CJ_IMPROVE_QUEUE_HANDOFF_BEGIN"
  jq -nc \
    --arg canonical_url "$canon" \
    --argjson in_scope_skill_files "$files" \
    --arg request_id "$request_id" \
    --argjson allowlisted "$allowlisted" \
    '{canonical_url:$canonical_url,in_scope_skill_files:$in_scope_skill_files,request_id:$request_id,allowlisted:$allowlisted}'
  echo "CJ_IMPROVE_QUEUE_HANDOFF_END"
}

# ---------------------------------------------------------------------------
# Row construction
# ---------------------------------------------------------------------------

# Build a single TODOS.md row block from a verdict JSON. Stdout = block.
# The row body adheres to S000048_SPEC.md Story #1.
#
# Heading shape (per spec):
#   ### Adopt <pattern_name> from <short_source_name> (P3, M)<!--impr-draft-->
#
# Body fields (all required per AC-1):
#   **Source:** <canonical_url>
#   **Verdict:** <verdict>
#   **Affected skills:** <comma-separated paths>
#   **Suggested change:** <one-liner or REVIEW: ...>
#   <!-- source-quote: "<≤200 byte source quote>" -->
#   <!-- impr-sig=<SIG> impr-conf=<N>/10 -->
build_row() {
  local verdict_json="$1"
  local canon="$2"
  local sig="$3"

  local verdict pattern short_source affected_skills suggested_change source_quote confidence
  verdict=$(echo "$verdict_json" | jq -r '.verdict')
  pattern=$(echo "$verdict_json" | jq -r '.pattern_name // "unknown-pattern"')
  short_source=$(echo "$verdict_json" | jq -r '.short_source_name // "anthropic"')
  affected_skills=$(echo "$verdict_json" | jq -r '.affected_skills // [] | join(", ")')
  suggested_change=$(echo "$verdict_json" | jq -r '.suggested_change // ""')
  source_quote=$(echo "$verdict_json" | jq -r '.source_quote // ""')
  confidence=$(echo "$verdict_json" | jq -r '.confidence // 5')

  # Trim source_quote to ≤200 bytes, strip newlines, and neutralize comment-end
  # sequences ("-->" -> "-- >") to prevent the HTML-comment-wrap from escaping
  # and bleeding source content into renderable markdown.
  source_quote=$(printf '%s' "$source_quote" | tr -d '\r\n' | sed 's/-->/-- >/g' | cut -c1-200)

  # If confidence < 7, prefix the suggested change with REVIEW: (per Subagent Contract).
  if [ -n "$suggested_change" ] && [ "$confidence" -lt 7 ] 2>/dev/null; then
    suggested_change="REVIEW: $suggested_change"
  fi

  printf '\n### Adopt %s from %s (P3, M)<!--impr-draft-->\n' "$pattern" "$short_source"
  printf '\n'
  printf '**Source:** %s\n' "$canon"
  printf '**Verdict:** %s\n' "$verdict"
  printf '**Affected skills:** %s\n' "$affected_skills"
  printf '**Suggested change:** %s\n' "$suggested_change"
  printf '<!-- source-quote: "%s" -->\n' "$source_quote"
  printf '<!-- impr-sig=%s impr-conf=%s/10 -->\n' "$sig" "$confidence"
}

# ---------------------------------------------------------------------------
# Lock + atomic-write
# ---------------------------------------------------------------------------

# Acquire write lock with retry. Returns 0 on success, 1 on persistent contention.
acquire_lock() {
  local attempts=0
  while [ "$attempts" -lt "$LOCK_RETRIES" ]; do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      return 0
    fi
    attempts=$((attempts + 1))
    sleep "$LOCK_SLEEP_SEC"
  done
  return 1
}

release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

# Append `$row_block` to `$todos_path` atomically. Backup first to
# $TMP_BASE/TODOS.md.bak.<ts>. mktemp -> cat existing + row -> mv.
atomic_append() {
  local todos_path="$1"
  local row_block="$2"

  mkdir -p "$TMP_BASE"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local backup="$TMP_BASE/TODOS.md.bak.$ts"
  cp -p "$todos_path" "$backup"

  local dir
  dir=$(dirname "$todos_path")
  local tmpfile
  tmpfile=$(mktemp "$dir/TODOS.md.XXXXXX")
  # Concatenate existing + new row into the temp, then atomic rename.
  cat "$todos_path" > "$tmpfile"
  printf '%s' "$row_block" >> "$tmpfile"
  mv "$tmpfile" "$todos_path"

  printf '%s' "$backup"
}

# Validate the most recently appended heading line matches the required regex.
# Return 0 on pass, 1 on fail. Reads $todos_path; checks the last
# `### Adopt ...` line.
validate_heading() {
  local todos_path="$1"
  # Find the last heading we wrote, strip the inline marker before regex check.
  local last
  last=$(grep -E '^### .* \(P[1-4], [SML]\)<!--impr-draft-->$' "$todos_path" | tail -1)
  if [ -z "$last" ]; then
    return 1
  fi
  # Strip <!--impr-draft--> and verify the underlying heading shape (suggest.sh:207).
  local naked
  naked=$(printf '%s' "$last" | sed 's/<!--impr-draft-->$//' | sed 's/^### //')
  if echo "$naked" | grep -qE '^(.*) \(P[1-4], [SML]\)$'; then
    return 0
  fi
  return 1
}

# Restore TODOS.md from backup.
restore_from_backup() {
  local todos_path="$1"
  local backup="$2"
  cp -p "$backup" "$todos_path"
}

# Keep last $BACKUP_RETAIN backups under $TMP_BASE; delete older.
rotate_backups() {
  # shellcheck disable=SC2010
  ls -t "$TMP_BASE"/TODOS.md.bak.* 2>/dev/null | tail -n +"$((BACKUP_RETAIN + 1))" | xargs -I {} rm -f {} 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Sub-commands
# ---------------------------------------------------------------------------

cmd_evaluate_prepare() {
  local raw_url="${1:-}"
  local allow_untrusted="${2:-0}"

  if [ -z "$raw_url" ]; then
    log_err "usage: improve_queue.sh evaluate-prepare <url> [--allow-untrusted-source]"
    exit 1
  fi

  check_darwin
  local root
  root=$(repo_root)
  check_todos_clean "$root"

  local canon host
  canon=$(canonicalize_url "$raw_url")
  host=$(host_of "$canon")

  local allowlisted="true"
  if ! is_allowlisted "$host"; then
    if [ "$allow_untrusted" = "1" ]; then
      allowlisted="false"
      log_err "source '$host' is not on the allowlist; --allow-untrusted-source passed, proceeding"
    else
      log_err "source '$host' is not on the allowlist; pass --allow-untrusted-source to override"
      exit 1
    fi
  fi

  emit_handoff "$canon" "$allowlisted" "$root"
}

cmd_evaluate() {
  local raw_url="${1:-}"
  local allow_untrusted="${2:-0}"

  # Test-hook short-circuit: stubbed verdict bypasses HANDOFF + Agent dispatch.
  # The shell envelope feeds the stub through `apply` directly.
  if [ -n "${CJ_IMPROVE_QUEUE_VERDICT_FILE:-}" ]; then
    if [ ! -f "$CJ_IMPROVE_QUEUE_VERDICT_FILE" ]; then
      log_err "CJ_IMPROVE_QUEUE_VERDICT_FILE set but file not found: $CJ_IMPROVE_QUEUE_VERDICT_FILE"
      exit 1
    fi
    # Still run preflight to exercise the gates.
    check_darwin
    local root
    root=$(repo_root)
    check_todos_clean "$root"
    # Pipe stub through apply.
    cat "$CJ_IMPROVE_QUEUE_VERDICT_FILE" | cmd_apply
    return
  fi

  # Live path: emit HANDOFF block. The orchestrator (SKILL.md prose) parses,
  # dispatches Agent, captures verdict, and re-invokes `apply` with the verdict
  # on stdin. Bash itself cannot reach Agent.
  cmd_evaluate_prepare "$raw_url" "$allow_untrusted"

  log_err "HANDOFF emitted on stdout. The orchestrator (SKILL.md prose) is responsible for"
  log_err "  (1) parsing the HANDOFF block,"
  log_err "  (2) dispatching the Agent tool with the Subagent Contract prompt,"
  log_err "  (3) piping the verdict JSON to 'improve_queue.sh apply' via stdin."
}

cmd_apply() {
  local verdict_json
  verdict_json=$(cat -)

  if [ -z "$verdict_json" ]; then
    log_err "apply: empty stdin; no verdict to process"
    exit 0
  fi

  # Validate the verdict parses as JSON and has a .verdict key.
  if ! echo "$verdict_json" | jq -e '.verdict' >/dev/null 2>&1; then
    log_err "subagent returned unparseable verdict; no row appended"
    exit 0
  fi

  local verdict
  verdict=$(echo "$verdict_json" | jq -r '.verdict')

  case "$verdict" in
    match)
      log_err "verdict=match (pattern already adopted); no row appended"
      exit 0
      ;;
    reject)
      log_err "verdict=reject (not a fit for this workbench); no row appended"
      exit 0
      ;;
    fetch_failed)
      local err
      err=$(echo "$verdict_json" | jq -r '.error // "unknown error"')
      log_err "WebFetch failed: $err; no row appended"
      exit 0
      ;;
    conflict|novel)
      ;;  # fall through to write path
    *)
      log_err "unrecognized verdict='$verdict'; no row appended"
      exit 0
      ;;
  esac

  # Need canonical_url (subagent echoes it back) + pattern_name.
  local canon pattern
  canon=$(echo "$verdict_json" | jq -r '.canonical_url // ""')
  pattern=$(echo "$verdict_json" | jq -r '.pattern_name // ""')

  if [ -z "$canon" ] || [ -z "$pattern" ]; then
    log_err "verdict missing canonical_url or pattern_name; no row appended"
    exit 0
  fi

  local root
  root=$(repo_root)
  local todos_path="$root/TODOS.md"
  if [ ! -f "$todos_path" ]; then
    log_err "TODOS.md not found at $todos_path"
    exit 1
  fi

  # Re-verify clean state (drift guard between evaluate-prepare and apply).
  check_todos_clean "$root"

  local sig
  sig=$(sig_of "$canon" "$pattern")

  # Idempotency probe.
  if grep -Fq "impr-sig=$sig" "$todos_path" 2>/dev/null; then
    log_err "signature already in TODOS.md (impr-sig=$sig); skipping"
    exit 0
  fi

  # Acquire write lock; on persistent contention exit 0 with retry hint.
  if ! acquire_lock; then
    log_err "another instance is writing TODOS.md; please retry"
    exit 0
  fi

  # Build row + atomic append + validate heading.
  local row_block backup
  row_block=$(build_row "$verdict_json" "$canon" "$sig")
  backup=$(atomic_append "$todos_path" "$row_block")

  if ! validate_heading "$todos_path"; then
    log_err "heading regex validation failed; restoring from $backup"
    restore_from_backup "$todos_path" "$backup"
    release_lock
    exit 1
  fi

  release_lock
  rotate_backups

  # Stdout summary line.
  printf '[CJ_improve-queue] appended draft row impr-sig=%s verdict=%s pattern=%s\n' "$sig" "$verdict" "$pattern"
}

# ---------------------------------------------------------------------------
# Arg dispatch
# ---------------------------------------------------------------------------

main() {
  local sub="${1:-}"
  shift || true

  # Pull --allow-untrusted-source out of the positional arg list.
  local allow_untrusted=0
  local pos_args=()
  for arg in "$@"; do
    case "$arg" in
      --allow-untrusted-source) allow_untrusted=1 ;;
      *) pos_args+=("$arg") ;;
    esac
  done

  case "$sub" in
    evaluate)
      cmd_evaluate "${pos_args[0]:-}" "$allow_untrusted"
      ;;
    evaluate-prepare)
      cmd_evaluate_prepare "${pos_args[0]:-}" "$allow_untrusted"
      ;;
    apply)
      cmd_apply
      ;;
    ""|-h|--help|help)
      cat <<'EOF'
usage: improve_queue.sh <sub-command> [args] [--allow-untrusted-source]

Sub-commands:
  evaluate <url>          One-shot orchestrator entry; emits HANDOFF, dispatches
                          Agent (via SKILL.md prose), pipes verdict to apply.
  evaluate-prepare <url>  Preflight + canonicalize + emit HANDOFF block, exit 0.
                          Useful for orchestrator testing in isolation.
  apply                   Read verdict JSON from stdin, append draft TODOS.md row.

Test hook:
  CJ_IMPROVE_QUEUE_VERDICT_FILE=<path>  Skip Agent dispatch; read verdict from file.

See: skills/CJ_improve-queue/SKILL.md (orchestrator), S000048_SPEC.md (acceptance).
EOF
      ;;
    *)
      log_err "unknown sub-command: $sub"
      log_err "run 'improve_queue.sh help' for usage"
      exit 1
      ;;
  esac
}

main "$@"
