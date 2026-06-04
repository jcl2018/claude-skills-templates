#!/usr/bin/env bash
# tests/cj-goal-common-sync.test.sh
#
# Test for the F000045 / S000081 `--phase sync` (Fork 2) in
# scripts/cj-goal-common.sh. Covers TEST-SPEC S5:
#   - dry-run previews (no mutation; SYNC_RAN=0; PHASE_RESULT=ok)
#   - --no-sync → PHASE_RESULT=skipped, NO install invoked (short-circuit)
#   - guard refusal (.source not on main / dirty tracked tree) → skipped, exit 0
#   - guard refusal (.source missing) → skipped, exit 0
#   - every mode emits all four KEY=VALUE keys: SYNC_RAN / VERSION_BEFORE /
#     VERSION_AFTER / PHASE_RESULT
#   - a REAL run (against a FAKE .source + FAKE skills-deploy) → SYNC_RAN=1,
#     version parsed, PHASE_RESULT=ok
#
# CRITICAL ISOLATION INVARIANT: this test NEVER runs a real `skills-deploy
# install` against the live ~/.claude and NEVER runs a real `git pull` against a
# real remote. It exercises the sync phase exclusively against:
#   - a POST_LAND_SYNC_MANIFEST override pointing at a TEMP manifest whose
#     `.source` is a throwaway temp git repo built inside this test, AND
#   - a FAKE `scripts/skills-deploy` in that throwaway source that only echoes.
# (cj-goal-common.sh invokes post-land-sync.sh as a subprocess, which inherits
# the POST_LAND_SYNC_MANIFEST env var.)
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
COMMON="$REPO_ROOT/scripts/cj-goal-common.sh"

echo "=== cj-goal-common-sync.test.sh: --phase sync (Fork 2) — hermetic, no real ~/.claude mutation ==="

[ -x "$COMMON" ] || { echo "RESULT: FAIL ($COMMON not executable)"; exit 1; }

# Belt-and-suspenders: record the REAL manifest's collection_version up front so
# we can prove at the end the test did not mutate it.
REAL_MANIFEST="$HOME/.claude/.skills-templates.json"
REAL_CV_BEFORE=""
if [ -f "$REAL_MANIFEST" ]; then
  REAL_CV_BEFORE=$(jq -r '.collection_version // empty' "$REAL_MANIFEST" 2>/dev/null | tr -d '\r' || echo "")
fi

# ── Sandbox: throwaway "source" repo (clean, on main) + fake skills-deploy ────
TMP=$(mktemp -d -t cj-goal-sync-test-XXXXXX)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FIXTURE_SRC="$TMP/source-repo"
mkdir -p "$FIXTURE_SRC/scripts"
(
  cd "$FIXTURE_SRC"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  git symbolic-ref HEAD refs/heads/main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
  printf '6.0.77\n' > VERSION
  # FAKE skills-deploy: echoes only — NEVER touches the real ~/.claude.
  printf '#!/usr/bin/env bash\necho "FAKE skills-deploy $*"\n' > scripts/skills-deploy
  chmod +x scripts/skills-deploy
  git add -A
  git commit -q -m "fixture: initial"
) || { echo "RESULT: FAIL (could not build fixture source repo)"; exit 1; }

# A clean-on-main manifest pointing at the fixture source repo.
GOOD_MANIFEST="$TMP/good-manifest.json"
cat > "$GOOD_MANIFEST" <<EOF
{ "source": "$FIXTURE_SRC", "collection_version": "6.0.77" }
EOF

# Helper: assert all four KEY=VALUE keys appear in the output.
assert_four_keys() {
  local label="$1" out="$2"
  local missing=""
  for k in SYNC_RAN VERSION_BEFORE VERSION_AFTER PHASE_RESULT; do
    printf '%s\n' "$out" | grep -qE "^${k}=" || missing="$missing $k"
  done
  if [ -z "$missing" ]; then
    ok "$label: emits all four keys (SYNC_RAN/VERSION_BEFORE/VERSION_AFTER/PHASE_RESULT)"
  else
    fail_test "$label: missing key(s):$missing; output: $out"
  fi
}

getkey() { printf '%s\n' "$2" | sed -n "s/^$1=//p" | head -1; }

# ── 1. --dry-run: preview, no mutation, PHASE_RESULT=ok, SYNC_RAN=0 ───────────
SRC_HEAD_BEFORE=$(git -C "$FIXTURE_SRC" rev-parse HEAD 2>/dev/null || echo "")
DRY_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$COMMON" --phase sync --mode feature --dry-run 2>&1)
DRY_RC=$?
assert_four_keys "dry-run" "$DRY_OUT"
if [ "$DRY_RC" -eq 0 ] && [ "$(getkey PHASE_RESULT "$DRY_OUT")" = "ok" ] && [ "$(getkey SYNC_RAN "$DRY_OUT")" = "0" ]; then
  ok "dry-run: exit 0, PHASE_RESULT=ok, SYNC_RAN=0"
else
  fail_test "dry-run: expected exit0/ok/SYNC_RAN=0 (rc=$DRY_RC); output: $DRY_OUT"
fi
if [ "$(getkey VERSION_BEFORE "$DRY_OUT")" = "6.0.77" ]; then
  ok "dry-run: VERSION_BEFORE parsed from collection_version (6.0.77)"
else
  fail_test "dry-run: VERSION_BEFORE not parsed; output: $DRY_OUT"
fi
SRC_HEAD_AFTER=$(git -C "$FIXTURE_SRC" rev-parse HEAD 2>/dev/null || echo "")
if [ "$SRC_HEAD_BEFORE" = "$SRC_HEAD_AFTER" ]; then
  ok "dry-run: mutated nothing (fixture source HEAD unchanged)"
else
  fail_test "dry-run: fixture source HEAD changed — isolation broken"
fi

# ── 2. --no-sync: short-circuit to skipped, NO install invoked ───────────────
NOSYNC_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$COMMON" --phase sync --mode feature --no-sync 2>&1)
NOSYNC_RC=$?
assert_four_keys "--no-sync" "$NOSYNC_OUT"
if [ "$NOSYNC_RC" -eq 0 ] \
   && [ "$(getkey PHASE_RESULT "$NOSYNC_OUT")" = "skipped" ] \
   && [ "$(getkey SYNC_RAN "$NOSYNC_OUT")" = "0" ]; then
  ok "--no-sync: exit 0, PHASE_RESULT=skipped, SYNC_RAN=0"
else
  fail_test "--no-sync: expected exit0/skipped/SYNC_RAN=0 (rc=$NOSYNC_RC); output: $NOSYNC_OUT"
fi
# Proof no install ran: the FAKE skills-deploy echoes "FAKE skills-deploy ..."
# on a real run. --no-sync short-circuits before any call, so it must be absent.
if ! printf '%s\n' "$NOSYNC_OUT" | grep -q "FAKE skills-deploy"; then
  ok "--no-sync: no skills-deploy invoked (short-circuit before any call)"
else
  fail_test "--no-sync: skills-deploy was invoked despite --no-sync; output: $NOSYNC_OUT"
fi

# ── 3. Guard refusal: .source NOT on main → skipped, exit 0 ──────────────────
git -C "$FIXTURE_SRC" checkout -q -b feature-x 2>/dev/null || true
NOTMAIN_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$COMMON" --phase sync --mode feature 2>&1)
NOTMAIN_RC=$?
assert_four_keys "guard:not-on-main" "$NOTMAIN_OUT"
if [ "$NOTMAIN_RC" -eq 0 ] && [ "$(getkey PHASE_RESULT "$NOTMAIN_OUT")" = "skipped" ]; then
  ok "guard: .source not on main → PHASE_RESULT=skipped, exit 0 (NEVER failed)"
else
  fail_test "guard: not-on-main should be skipped/exit0 (rc=$NOTMAIN_RC); output: $NOTMAIN_OUT"
fi
git -C "$FIXTURE_SRC" checkout -q main 2>/dev/null || true

# ── 4. Guard refusal: .source dirty (tracked change) → skipped, exit 0 ───────
printf 'dirty\n' >> "$FIXTURE_SRC/VERSION"   # modify a TRACKED file
DIRTY_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$COMMON" --phase sync --mode feature 2>&1)
DIRTY_RC=$?
if [ "$DIRTY_RC" -eq 0 ] && [ "$(getkey PHASE_RESULT "$DIRTY_OUT")" = "skipped" ]; then
  ok "guard: dirty .source (tracked) → PHASE_RESULT=skipped, exit 0"
else
  fail_test "guard: dirty .source should be skipped/exit0 (rc=$DIRTY_RC); output: $DIRTY_OUT"
fi
git -C "$FIXTURE_SRC" checkout -q -- VERSION 2>/dev/null || true

# ── 5. Guard refusal: .source missing in manifest → skipped, exit 0 ──────────
NOSRC_MANIFEST="$TMP/nosrc-manifest.json"
printf '{ "collection_version": "6.0.77" }\n' > "$NOSRC_MANIFEST"
NOSRC_OUT=$(POST_LAND_SYNC_MANIFEST="$NOSRC_MANIFEST" bash "$COMMON" --phase sync --mode feature 2>&1)
NOSRC_RC=$?
if [ "$NOSRC_RC" -eq 0 ] && [ "$(getkey PHASE_RESULT "$NOSRC_OUT")" = "skipped" ]; then
  ok "guard: missing .source → PHASE_RESULT=skipped, exit 0"
else
  fail_test "guard: missing .source should be skipped/exit0 (rc=$NOSRC_RC); output: $NOSRC_OUT"
fi

# ── 6. REAL run against FAKE .source + FAKE skills-deploy → SYNC_RAN=1 ────────
# Give the fixture source an origin so `git pull --ff-only` succeeds offline-free.
git init -q --bare "$TMP/origin.git"
git -C "$FIXTURE_SRC" remote add origin "$TMP/origin.git" 2>/dev/null \
  || git -C "$FIXTURE_SRC" remote set-url origin "$TMP/origin.git"
git -C "$FIXTURE_SRC" push -q -u origin main >/dev/null 2>&1
REAL_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$COMMON" --phase sync --mode feature 2>&1)
REAL_RC=$?
assert_four_keys "real-run" "$REAL_OUT"
if [ "$REAL_RC" -eq 0 ] \
   && [ "$(getkey PHASE_RESULT "$REAL_OUT")" = "ok" ] \
   && [ "$(getkey SYNC_RAN "$REAL_OUT")" = "1" ] \
   && [ "$(getkey VERSION_BEFORE "$REAL_OUT")" = "6.0.77" ]; then
  ok "real-run (fake .source): exit0, PHASE_RESULT=ok, SYNC_RAN=1, version parsed"
else
  fail_test "real-run: expected exit0/ok/SYNC_RAN=1/version (rc=$REAL_RC); output: $REAL_OUT"
fi

# ── Isolation backstop: real ~/.claude collection_version unchanged ──────────
if [ -f "$REAL_MANIFEST" ]; then
  REAL_CV_AFTER=$(jq -r '.collection_version // empty' "$REAL_MANIFEST" 2>/dev/null | tr -d '\r' || echo "")
  if [ "$REAL_CV_BEFORE" = "$REAL_CV_AFTER" ]; then
    ok "real ~/.claude collection_version unchanged by this test ($REAL_CV_AFTER)"
  else
    fail_test "real ~/.claude collection_version CHANGED ($REAL_CV_BEFORE → $REAL_CV_AFTER) — test mutated the real install!"
  fi
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS error(s))"
  exit 1
fi
