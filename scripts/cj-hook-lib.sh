#!/usr/bin/env bash
# cj-hook-lib.sh — ONE shared, sourceable implementation of the clobber-safe git
# hook installer (F000069 / S000117). Sourced by BOTH scripts/setup-hooks.sh (the
# workbench's own pre-commit/post-merge install) AND scripts/skills-deploy (the
# consumer-repo contract-gate pre-commit auto-install), so the back-up-and-warn
# safety lives ONCE instead of in two drifting copies.
#
# This file is SOURCED, never executed — it defines functions + the SENTINEL and
# returns. It deliberately does NOT set shell options (the sourcing script owns
# its own `set -e`/`pipefail` posture).
#
# The SENTINEL is the marker every workbench-owned hook body carries; it lets
# cj_install_hook tell a workbench-owned hook from an operator/tooling-owned one
# (Husky, lefthook, a local debug hook) so a custom hook is never blindly
# destroyed.
CJ_HOOK_SENTINEL='# Auto-installed by scripts/setup-hooks.sh'

# cj_install_hook <hook_dir> <hook_name>   (hook body on stdin)
# Clobber-safe, atomic install of <hook_dir>/<hook_name>:
#   - Stage the body into a temp file in <hook_dir> and chmod +x it BEFORE the
#     target is touched. The live hook is only ever changed by an atomic mv of a
#     fully-written file (same dir => same filesystem => rename(2)), so a
#     mid-write/chmod failure leaves the prior hook intact — never a truncated or
#     non-executable hook.
#   - If an existing hook lacks $CJ_HOOK_SENTINEL it is operator/tooling-owned:
#     back it up to <hook>.bak (timestamped if .bak exists) and warn, instead of
#     silently destroying it. If the backup itself fails, abort WITHOUT clobbering
#     — losing an un-backed custom hook is the one unacceptable outcome.
#   - An existing hook that already carries $CJ_HOOK_SENTINEL is our own prior
#     install: refreshed in place, no backup, so repeated installs stay a no-op.
# Returns non-zero on failure so callers' `|| ...` guards fire.
cj_install_hook() {
  local hook_dir="$1" hook_name="$2"
  local hook_path="$hook_dir/$hook_name"
  local tmp
  tmp="$(mktemp "$hook_dir/.${hook_name}.XXXXXX" 2>/dev/null)" || {
    echo "ERROR: cannot create temp file in $hook_dir for $hook_name hook" >&2
    return 1
  }
  if ! cat > "$tmp"; then
    rm -f "$tmp"
    echo "ERROR: failed to write $hook_name hook body" >&2
    return 1
  fi
  if ! chmod +x "$tmp"; then
    rm -f "$tmp"
    echo "ERROR: chmod +x failed for $hook_name hook" >&2
    return 1
  fi
  if [ -e "$hook_path" ] && ! grep -qF "$CJ_HOOK_SENTINEL" "$hook_path" 2>/dev/null; then
    local backup="$hook_path.bak"
    [ -e "$backup" ] && backup="$hook_path.bak.$(date +%Y%m%d%H%M%S)"
    if ! cp -p "$hook_path" "$backup"; then
      rm -f "$tmp"
      echo "ERROR: existing $hook_path is not workbench-owned and could not be backed up — refusing to overwrite (your custom hook is untouched)" >&2
      return 1
    fi
    echo "WARN: existing $hook_path is not workbench-owned — backed up to $(basename "$backup") before installing the workbench hook" >&2
  fi
  if ! mv "$tmp" "$hook_path"; then
    rm -f "$tmp"
    echo "ERROR: failed to install $hook_name hook" >&2
    return 1
  fi
  return 0
}

# cj_remove_hook <hook_dir> <hook_name>
# Uninstall ONLY a workbench-owned (sentinel-carrying) hook; a non-workbench hook
# is left UNTOUCHED. Echoes a one-line outcome:
#   removed   — a sentinel hook was deleted
#   foreign   — a hook exists but is not workbench-owned (left in place)
#   absent    — no hook to remove (no-op)
# Always returns 0 (best-effort uninstall).
cj_remove_hook() {
  local hook_dir="$1" hook_name="$2"
  local hook_path="$hook_dir/$hook_name"
  if [ ! -e "$hook_path" ]; then
    echo "absent"
    return 0
  fi
  if grep -qF "$CJ_HOOK_SENTINEL" "$hook_path" 2>/dev/null; then
    rm -f "$hook_path"
    echo "removed"
    return 0
  fi
  echo "foreign"
  return 0
}

# cj_resolve_hook_dir <repo>
# Resolve the git hooks directory for <repo>, worktree-aware. Echoes the absolute
# hooks dir (empty if <repo> is not a git repo). --git-common-dir resolves the
# shared .git for both regular checkouts and worktrees; it is relative in main
# checkouts (".git") and absolute in worktrees, so we normalize to absolute.
cj_resolve_hook_dir() {
  local repo="$1" gcd
  gcd="$(git -C "$repo" rev-parse --git-common-dir 2>/dev/null)" || return 0
  [ -n "$gcd" ] || return 0
  case "$gcd" in
    /*) echo "$gcd/hooks" ;;
    *)  echo "$repo/$gcd/hooks" ;;
  esac
}

# cj_has_custom_hookspath <repo>
# True (exit 0) when <repo> sets a custom core.hooksPath (husky/lefthook/
# pre-commit-framework signal). The contract-gate auto-install SKIPS such a repo
# rather than fighting the committed hooks dir. Echoes the configured value when
# set (for the skip note).
cj_has_custom_hookspath() {
  local repo="$1" hp
  hp="$(git -C "$repo" config --get core.hooksPath 2>/dev/null)" || return 1
  if [ -n "$hp" ]; then
    echo "$hp"
    return 0
  fi
  return 1
}
