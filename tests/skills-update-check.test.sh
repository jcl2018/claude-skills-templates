#!/usr/bin/env bash
# tests/skills-update-check.test.sh
#
# Hermetic regression for scripts/skills-update-check's checkout-independent
# git-ls-remote version-notification (F000081/WS3).
#
# CRITICAL ISOLATION INVARIANT: this test must NEVER touch the operator's real
# ~/.claude and must NEVER hit the real network. It exercises the script with:
#   - SKILLS_TEMPLATES_MANIFEST → a TEMP manifest (a `.source`-absent one, the
#     remote-machine / consumer shape the rework unblocks),
#   - SKILLS_UPDATE_STATE_DIR    → a throwaway dir for the cache + marker,
#   - a PATH-stubbed `git` whose `ls-remote --tags` prints canned tag lines (no
#     network), plus SKILLS_UPDATE_REMOTE_URL to bypass upstream_url where needed.
#
# Asserts (>=8):
#   1. Script exists + is executable, and `bash -n` parses it.
#   2. Banner: remote (max v-tag) > local, .source ABSENT  → SKILLS_UPGRADE_AVAILABLE <local> <remote>.
#   3. Max-tag: the highest 3-digit v-tag wins (a peeled `^{}` ref is ignored).
#   4. Silent: remote == local → no output, exit 0.
#   5. Silent: remote < local  → no output, exit 0 (never a downgrade nudge).
#   6. Fail-soft: `git ls-remote` errors (unreachable) → no output, exit 0.
#   7. Fail-soft: remote has NO v-tags → no output, exit 0.
#   8. Override: SKILLS_UPDATE_REMOTE_URL wins even with no upstream_url in the manifest.
#   9. ssh→https: an ssh-form upstream_url is normalized (banner still fires; no ssh needed).
#  10. No .git-gate: a manifest WITH a `.source` that has no .git no longer suppresses the banner.
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/skills-update-check"

echo "=== skills-update-check.test.sh: checkout-independent git-ls-remote version-notification (hermetic, no network / no real ~/.claude) ==="

# Belt-and-suspenders: record the REAL cache mtime so we can prove we never wrote it.
REAL_CACHE="$HOME/.claude/.skills-templates-update.json"
REAL_CACHE_BEFORE=""
[ -f "$REAL_CACHE" ] && REAL_CACHE_BEFORE=$(stat -c %Y "$REAL_CACHE" 2>/dev/null || stat -f %m "$REAL_CACHE" 2>/dev/null || echo "")

# ---- 1. exists + executable + parses ----
if [ -x "$HELPER" ]; then
  ok "1: scripts/skills-update-check exists and is executable"
else
  fail_test "1: scripts/skills-update-check missing or not executable at $HELPER"
fi
if bash -n "$HELPER" 2>/dev/null; then
  ok "1: bash -n parses skills-update-check"
else
  fail_test "1: skills-update-check has a syntax error"
fi

# ---- shared fixture builders ----
# Build a throwaway sandbox: a state dir, a stubbed `git` on PATH whose ls-remote
# prints $1 (the canned tag block) or exits with $2 (rc) when $1 is the token FAIL.
_mk_sandbox() {
  # $1 = tag block for ls-remote (multi-line), or the literal "FAIL:<rc>" to make
  #      ls-remote exit non-zero, or "EMPTY" for a non-v-tag-only remote.
  local spec="$1"
  local work; work=$(mktemp -d)
  local bin="$work/bin"; mkdir -p "$bin" "$work/state"
  case "$spec" in
    FAIL:*)
      cat > "$bin/git" <<STUB
#!/usr/bin/env bash
for a in "\$@"; do
  if [ "\$a" = "ls-remote" ]; then echo "fatal: unable to access" >&2; exit ${spec#FAIL:}; fi
done
exit 0
STUB
      ;;
    EMPTY)
      # ls-remote succeeds but returns only NON-v refs (no release tags).
      cat > "$bin/git" <<'STUB'
#!/usr/bin/env bash
for a in "$@"; do
  if [ "$a" = "ls-remote" ]; then
    printf 'abc\trefs/tags/nightly-2026\n'
    printf 'def\trefs/heads/main\n'
    exit 0
  fi
done
exit 0
STUB
      ;;
    *)
      # $spec is the literal tag block; print it for ls-remote.
      cat > "$bin/git" <<STUB
#!/usr/bin/env bash
for a in "\$@"; do
  if [ "\$a" = "ls-remote" ]; then
    cat <<'TAGS'
$spec
TAGS
    exit 0
  fi
done
exit 0
STUB
      ;;
  esac
  chmod +x "$bin/git"
  echo "$work"
}

# Write a manifest into a sandbox. $1=work dir, $2=collection_version, $3=upstream_url
# (may be empty), $4=source (may be empty; the .source-absent remote-machine shape).
_write_manifest() {
  local work="$1" cv="$2" up="${3:-}" src="${4:-}"
  local m="$work/state/.skills-templates.json"
  {
    printf '{"collection_version":"%s"' "$cv"
    [ -n "$up" ]  && printf ',"upstream_url":"%s"' "$up"
    [ -n "$src" ] && printf ',"source":"%s"' "$src"
    printf '}\n'
  } > "$m"
  echo "$m"
}

# Run the helper inside a sandbox with the stubbed git on PATH. Any extra
# NAME=VALUE overrides are passed as $2.. and applied via `env` (a bare "$@"
# cannot be parsed as inline env assignments — they must be literal syntax).
_run_suc() {
  local work="$1"; shift
  local m="$work/state/.skills-templates.json"
  env PATH="$work/bin:$PATH" \
      SKILLS_TEMPLATES_MANIFEST="$m" \
      SKILLS_UPDATE_STATE_DIR="$work/state" \
      "$@" \
      bash "$HELPER"
}

# ---- 2 + 3. Banner when remote > local, .source ABSENT; max v-tag wins (peeled ^{} ignored) ----
W=$(_mk_sandbox 'aaa	refs/tags/v6.0.113
bbb	refs/tags/v6.0.200
bbb	refs/tags/v6.0.200^{}
ccc	refs/tags/v5.9.9')
_write_manifest "$W" "6.0.113" "https://github.com/jcl2018/claude-skills-templates.git" "" >/dev/null
OUT=$(_run_suc "$W"); RC=$?
if [ "$RC" -eq 0 ] && [ "$OUT" = "SKILLS_UPGRADE_AVAILABLE 6.0.113 6.0.200" ]; then
  ok "2/3: remote (6.0.200) > local (6.0.113) with NO .source → SKILLS_UPGRADE_AVAILABLE 6.0.113 6.0.200 (max v-tag wins, peeled ^{} ignored)"
else
  fail_test "2/3: wrong banner (rc=$RC): [$OUT]"
fi
rm -rf "$W"

# ---- 4. Silent when remote == local ----
W=$(_mk_sandbox 'aaa	refs/tags/v6.0.113')
_write_manifest "$W" "6.0.113" "https://github.com/jcl2018/claude-skills-templates.git" "" >/dev/null
OUT=$(_run_suc "$W"); RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "4: remote == local (6.0.113) → silent, exit 0"
else
  fail_test "4: expected silence for equal versions (rc=$RC): [$OUT]"
fi
rm -rf "$W"

# ---- 5. Silent when remote < local (never a downgrade nudge) ----
W=$(_mk_sandbox 'aaa	refs/tags/v6.0.100')
_write_manifest "$W" "6.0.113" "https://github.com/jcl2018/claude-skills-templates.git" "" >/dev/null
OUT=$(_run_suc "$W"); RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "5: remote (6.0.100) < local (6.0.113) → silent, exit 0 (no downgrade nudge)"
else
  fail_test "5: expected silence when remote older (rc=$RC): [$OUT]"
fi
rm -rf "$W"

# ---- 6. Fail-soft when ls-remote errors (unreachable) ----
W=$(_mk_sandbox 'FAIL:128')
_write_manifest "$W" "6.0.113" "https://github.com/jcl2018/claude-skills-templates.git" "" >/dev/null
OUT=$(_run_suc "$W"); RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "6: git ls-remote unreachable (exit 128) → fail-soft silent, exit 0 (no false nudge)"
else
  fail_test "6: expected fail-soft silence on unreachable remote (rc=$RC): [$OUT]"
fi
rm -rf "$W"

# ---- 7. Fail-soft when remote has NO v-tags ----
W=$(_mk_sandbox 'EMPTY')
_write_manifest "$W" "6.0.113" "https://github.com/jcl2018/claude-skills-templates.git" "" >/dev/null
OUT=$(_run_suc "$W"); RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "7: remote has no release v-tags → fail-soft silent, exit 0 (untagged-upstream path)"
else
  fail_test "7: expected fail-soft silence when no v-tags (rc=$RC): [$OUT]"
fi
rm -rf "$W"

# ---- 8. SKILLS_UPDATE_REMOTE_URL override wins with NO upstream_url in the manifest ----
W=$(_mk_sandbox 'aaa	refs/tags/v7.0.0')
_write_manifest "$W" "6.0.113" "" "" >/dev/null
OUT=$(_run_suc "$W" SKILLS_UPDATE_REMOTE_URL="file:///nonexistent-but-stubbed"); RC=$?
if [ "$RC" -eq 0 ] && [ "$OUT" = "SKILLS_UPGRADE_AVAILABLE 6.0.113 7.0.0" ]; then
  ok "8: SKILLS_UPDATE_REMOTE_URL override drives the read with no upstream_url → banner 6.0.113 7.0.0"
else
  fail_test "8: override did not drive the remote read (rc=$RC): [$OUT]"
fi
rm -rf "$W"

# ---- 9. ssh-form upstream_url is normalized (banner still fires, no ssh key needed) ----
# The stub git ignores the URL, so this asserts the ssh-form URL does not crash/hang
# the normalize path and the banner still emits from the canned tags.
W=$(_mk_sandbox 'aaa	refs/tags/v6.5.0')
_write_manifest "$W" "6.0.113" "git@github.com:jcl2018/claude-skills-templates.git" "" >/dev/null
OUT=$(_run_suc "$W"); RC=$?
if [ "$RC" -eq 0 ] && [ "$OUT" = "SKILLS_UPGRADE_AVAILABLE 6.0.113 6.5.0" ]; then
  ok "9: ssh-form upstream_url normalized ssh→https; banner still fires (6.0.113 6.5.0)"
else
  fail_test "9: ssh-form upstream_url path wrong (rc=$RC): [$OUT]"
fi
rm -rf "$W"

# ---- 10. No .git-gate: a `.source` that is NOT a git checkout no longer suppresses the banner ----
# This is the core regression: the old `[ -d "$source_path/.git" ] || exit 0` gate
# made a non-checkout .source silently no-op. With the gate removed, the remote read
# still drives the banner.
W=$(_mk_sandbox 'aaa	refs/tags/v6.0.250')
# Point .source at a directory that exists but is NOT a git repo (no .git).
_NOGIT="$W/not-a-checkout"; mkdir -p "$_NOGIT"
_write_manifest "$W" "6.0.113" "https://github.com/jcl2018/claude-skills-templates.git" "$_NOGIT" >/dev/null
OUT=$(_run_suc "$W"); RC=$?
if [ "$RC" -eq 0 ] && [ "$OUT" = "SKILLS_UPGRADE_AVAILABLE 6.0.113 6.0.250" ]; then
  ok "10: a non-git .source no longer suppresses the banner (the .git-gate is removed) → 6.0.113 6.0.250"
else
  fail_test "10: .git-gate removal regression — banner suppressed by a non-checkout .source (rc=$RC): [$OUT]"
fi
rm -rf "$W"

# ---- isolation proof: the real cache was never written ----
REAL_CACHE_AFTER=""
[ -f "$REAL_CACHE" ] && REAL_CACHE_AFTER=$(stat -c %Y "$REAL_CACHE" 2>/dev/null || stat -f %m "$REAL_CACHE" 2>/dev/null || echo "")
if [ "$REAL_CACHE_BEFORE" = "$REAL_CACHE_AFTER" ]; then
  ok "isolation: the real ~/.claude update cache was not mutated by this test"
else
  fail_test "isolation: the real ~/.claude update cache mtime changed (before=$REAL_CACHE_BEFORE after=$REAL_CACHE_AFTER)"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS error(s))"
  exit 1
fi
