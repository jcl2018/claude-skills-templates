#!/usr/bin/env bash
# tests/regression/CI-push/tag-release.test.sh
#
# Hermetic regression for scripts/tag-release.sh — the post-land helper that
# publishes the `v<VERSION>` release tag to origin so scripts/skills-update-check's
# `git ls-remote --tags` read can actually see the newest release.
#
# THE BUG THIS GUARDS: the land flow bumped VERSION on every ship but NEVER pushed a
# matching `v<VERSION>` tag, so origin's newest tag stayed v1.1.0 while VERSION marched
# to 6.0.x → skills-update-check's compare was always `remote(1.1.0) < local` → the
# no-downgrade-nudge branch → silent forever. This test proves the helper closes that:
# after it runs, the fake origin actually carries the `v<VERSION>` tag.
#
# CRITICAL ISOLATION INVARIANT: this test must NEVER touch the operator's real
# ~/.claude, the real origin, or the real network. It builds a LOCAL `git init --bare`
# repo as a fake origin (accepts pushes, no network) and a throwaway working clone,
# and runs the helper against them exclusively.
#
# Asserts (>=8):
#   1. Helper exists + is executable, and `bash -n` parses it.
#   2. --dry-run against a fixture reports the tag/version and mutates nothing (no tag pushed).
#   3. Real run: the `v<VERSION>` tag is CREATED and PUSHED to the fake origin.
#   4. Idempotency: a second run is a no-op (exit 0), origin tag unchanged, no error.
#   5. Idempotency (already-present, no local tag): a fresh clone whose origin already
#      has the tag runs cleanly (no-op, exit 0) without re-creating a local tag.
#   6. --version override tags the given version, not the VERSION file.
#   7. Bad VERSION (non-semver) → exit 1 (bad invocation), nothing pushed.
#   8. --strict surfaces a push failure (bad remote) as a non-zero exit.
#   9. Fail-soft (default): a push failure (bad remote) WARNs but exits 0 — never halts a land.
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)  # tests/regression/CI-push/ -> repo root
HELPER="$REPO_ROOT/scripts/tag-release.sh"

echo "=== tag-release.test.sh: post-land v<VERSION> tag publish (hermetic — local bare origin, no network / no real origin) ==="

# ---- 1. exists + executable + parses ----
if [ -x "$HELPER" ]; then
  ok "1: scripts/tag-release.sh exists and is executable"
else
  fail_test "1: scripts/tag-release.sh missing or not executable at $HELPER"
fi
if bash -n "$HELPER" 2>/dev/null; then
  ok "1: bash -n parses tag-release.sh"
else
  fail_test "1: tag-release.sh has a syntax error"
fi

# ── Sandbox ──────────────────────────────────────────────────────────────────
TMP=$(mktemp -d -t tag-release-test-XXXXXX)
# shellcheck disable=SC2329  # invoked indirectly via the EXIT trap
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# A LOCAL bare repo acting as the fake "origin". Accepts pushes; no network.
ORIGIN="$TMP/origin.git"
git init -q --bare "$ORIGIN"

# Build a working clone with a VERSION file + an origin remote pointing at the bare.
build_clone() {
  # $1 = clone dir, $2 = VERSION contents
  local dir="$1" ver="$2"
  mkdir -p "$dir"
  (
    cd "$dir" || exit 1
    git init -q
    git config user.email "test@example.com"
    git config user.name "test"
    git checkout -q -b main 2>/dev/null || git branch -q -m main 2>/dev/null || true
    printf '%s\n' "$ver" > VERSION
    git add -A
    git commit -q -m "fixture: VERSION $ver"
    git remote add origin "$ORIGIN"
    # Push main so the bare origin has the commit the tag will point at.
    git push -q origin main 2>/dev/null || true
  )
}

# List v-tags currently on the bare origin (peeled ^{} refs stripped, deduped).
origin_vtags() {
  git ls-remote --tags "$ORIGIN" 'v*' 2>/dev/null \
    | awk '{print $2}' | sed 's/\^{}$//' | sed 's#^refs/tags/##' | sort -u
}

# ---- 2. --dry-run mutates nothing ----
C1="$TMP/clone-dry"
build_clone "$C1" "6.0.200"
DRY_OUT=$( cd "$C1" && bash "$HELPER" --dry-run 2>&1 ); DRY_RC=$?
if [ "$DRY_RC" -eq 0 ] \
   && printf '%s' "$DRY_OUT" | grep -q "v6.0.200" \
   && [ -z "$(origin_vtags)" ]; then
  ok "2: --dry-run reports v6.0.200 + mutates nothing (no v-tag on origin)"
else
  fail_test "2: --dry-run wrong (rc=$DRY_RC) or it pushed a tag; origin v-tags=[$(origin_vtags)]; out: $DRY_OUT"
fi

# ---- 3. Real run creates + pushes v<VERSION> to the fake origin ----
RUN_OUT=$( cd "$C1" && bash "$HELPER" --strict 2>&1 ); RUN_RC=$?
if [ "$RUN_RC" -eq 0 ] && [ "$(origin_vtags)" = "v6.0.200" ]; then
  ok "3: real run published v6.0.200 to the fake origin (the core fix — tag now exists on origin)"
else
  fail_test "3: real run did not publish the tag (rc=$RUN_RC); origin v-tags=[$(origin_vtags)]; out: $RUN_OUT"
fi

# ---- 4. Idempotency — a second run is a clean no-op, origin unchanged ----
RERUN_OUT=$( cd "$C1" && bash "$HELPER" --strict 2>&1 ); RERUN_RC=$?
if [ "$RERUN_RC" -eq 0 ] \
   && [ "$(origin_vtags)" = "v6.0.200" ] \
   && printf '%s' "$RERUN_OUT" | grep -qi 'no-op'; then
  ok "4: second run is an idempotent no-op (exit 0, origin tag unchanged, 'no-op' reported)"
else
  fail_test "4: second run not idempotent (rc=$RERUN_RC); origin v-tags=[$(origin_vtags)]; out: $RERUN_OUT"
fi

# ---- 5. Already-present on origin, no LOCAL tag → clean no-op ----
# A fresh clone (no local v-tag) whose origin ALREADY carries v6.0.200 must no-op
# without trying to re-create/re-push.
C2="$TMP/clone-fresh"
build_clone "$C2" "6.0.200"   # origin already has v6.0.200 from case 3
FRESH_OUT=$( cd "$C2" && bash "$HELPER" --strict 2>&1 ); FRESH_RC=$?
if [ "$FRESH_RC" -eq 0 ] && printf '%s' "$FRESH_OUT" | grep -qi 'no-op'; then
  ok "5: fresh clone with the tag already on origin → clean no-op (exit 0)"
else
  fail_test "5: already-present-on-origin path wrong (rc=$FRESH_RC); out: $FRESH_OUT"
fi

# ---- 6. --version override tags the given version, not the VERSION file ----
C3="$TMP/clone-override"
build_clone "$C3" "6.0.200"   # VERSION file says 6.0.200
OV_OUT=$( cd "$C3" && bash "$HELPER" --strict --version 7.1.0 2>&1 ); OV_RC=$?
if [ "$OV_RC" -eq 0 ] && printf '%s\n' "$(origin_vtags)" | grep -qx "v7.1.0"; then
  ok "6: --version 7.1.0 override published v7.1.0 (not the VERSION-file value)"
else
  fail_test "6: --version override wrong (rc=$OV_RC); origin v-tags=[$(origin_vtags)]; out: $OV_OUT"
fi

# ---- 7. Bad VERSION (non-semver) → exit 1, nothing pushed ----
C4="$TMP/clone-badver"
build_clone "$C4" "not-a-version"
BEFORE_BAD="$(origin_vtags)"
BAD_OUT=$( cd "$C4" && bash "$HELPER" --strict 2>&1 ); BAD_RC=$?
if [ "$BAD_RC" -eq 1 ] && [ "$(origin_vtags)" = "$BEFORE_BAD" ]; then
  ok "7: non-semver VERSION → exit 1 (bad invocation), nothing pushed"
else
  fail_test "7: bad VERSION should exit 1 + push nothing (rc=$BAD_RC); out: $BAD_OUT"
fi

# ---- 8 + 9. Push failure to a bad remote — --strict fails, default fail-softs ----
C5="$TMP/clone-badremote"
build_clone "$C5" "8.0.0"
# Point at a nonexistent bare so the push cannot succeed. ls-remote against it fails,
# so the helper falls through to attempt the push, which also fails.
BADREMOTE="$TMP/does-not-exist.git"

STRICT_OUT=$( cd "$C5" && bash "$HELPER" --strict --remote "$BADREMOTE" 2>&1 ); STRICT_RC=$?
if [ "$STRICT_RC" -ne 0 ]; then
  ok "8: --strict surfaces a push failure to a bad remote as a non-zero exit (rc=$STRICT_RC)"
else
  fail_test "8: --strict should exit non-zero on a push failure (rc=$STRICT_RC); out: $STRICT_OUT"
fi

SOFT_OUT=$( cd "$C5" && bash "$HELPER" --remote "$BADREMOTE" 2>&1 ); SOFT_RC=$?
if [ "$SOFT_RC" -eq 0 ] && printf '%s' "$SOFT_OUT" | grep -qi 'WARN'; then
  ok "9: default fail-soft — a push failure WARNs but exits 0 (never halts a land)"
else
  fail_test "9: default should fail-soft (exit 0 + WARN) on a push failure (rc=$SOFT_RC); out: $SOFT_OUT"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS error(s))"
  exit 1
fi
