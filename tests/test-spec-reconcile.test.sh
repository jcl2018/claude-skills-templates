#!/usr/bin/env bash
# tests/test-spec-reconcile.test.sh
#
# Regression test for the F000065/S000109 test-spec self-healing reconcile:
# scripts/test-spec.sh --classify + --reconcile, the SYMMETRIC partner of the
# doc-spec engine — but REDUCED, because test-spec's fenced-yaml on-disk format
# never diverged (confirmed from git history: test-spec.md has carried the
# schema_version: + rules: yaml block since introduction). So:
#   - --classify labels {canonical, absent, duplicate, malformed} — it NEVER
#     emits `legacy` (there is no old on-disk format to detect).
#   - --reconcile is a dedup / no-op: canonical => clean no-op; duplicate =>
#     reports the redundant copy (no auto-delete); malformed => halt; absent =>
#     "run the audit to seed". There is NO legacy migration to exercise.
#
# Asserts:
#   1. --classify: absent / canonical / duplicate / malformed labeled correctly,
#      and `legacy` NEVER appears
#   2. --reconcile on a canonical contract is a clean no-op (RECONCILE: already
#      canonical) with the documented "no divergent legacy format" note, and
#      writes nothing (no .bak)
#   3. --reconcile on a duplicate reports the redundant copy (RECONCILE-WARN)
#      and does NOT auto-delete either file
#   4. --reconcile on a malformed registry HALTS [test-spec-no-config] (no clobber)
#   5. the LIVE workbench classifies canonical with DUPLICATE=0 and --reconcile
#      is a clean no-op (no .bak)
#
# Temp-dir isolated; never mutates the live tree.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/test-spec.sh"

_TMPS=""
mk_tmp() {
  _d=$(mktemp -d -t test-spec-reconcile.XXXXXX)
  _TMPS="$_TMPS $_d"
  printf '%s' "$_d"
}
# shellcheck disable=SC2317,SC2329  # invoked indirectly via the EXIT trap below
cleanup() {
  for _d in $_TMPS; do
    [ -n "$_d" ] && [ -d "$_d" ] && rm -rf "$_d"
  done
}
trap cleanup EXIT

echo "=== test-spec reconcile + classify assertions (reduced — no legacy on-disk format) ==="

[ -x "$HELPER" ] || { fail_test "scripts/test-spec.sh missing or not executable"; echo "FAIL: test-spec-reconcile ($ERRORS error(s))"; exit 1; }

# ---------------------------------------------------------------------------
# 1. --classify: absent / canonical / duplicate / malformed; never legacy
# ---------------------------------------------------------------------------

# absent
_A=$(mk_tmp)
_CA=$(REPO_ROOT="$_A" TEST_SPEC_PATH="$_A/spec/test-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CA" | grep -qx 'GENERATION=absent' \
   && printf '%s\n' "$_CA" | grep -qx 'DUPLICATE=0' \
   && printf '%s\n' "$_CA" | grep -qx 'CANONICAL_PATH=spec/test-spec.md'; then
  ok "--classify on an absent contract => GENERATION=absent, DUPLICATE=0, CANONICAL_PATH=spec/test-spec.md"
else
  fail_test "--classify absent wrong: $(printf '%s' "$_CA" | tr '\n' ' ')"
fi

# canonical (seed-built)
_C=$(mk_tmp); mkdir -p "$_C/spec"
bash "$HELPER" --seed > "$_C/spec/test-spec.md" 2>/dev/null
_CC=$(REPO_ROOT="$_C" TEST_SPEC_PATH="$_C/spec/test-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CC" | grep -qx 'GENERATION=canonical' \
   && printf '%s\n' "$_CC" | grep -qx 'DUPLICATE=0' \
   && ! printf '%s\n' "$_CC" | grep -qx 'GENERATION=legacy'; then
  ok "--classify on a seeded canonical contract => GENERATION=canonical (NEVER legacy)"
else
  fail_test "--classify canonical wrong: $(printf '%s' "$_CC" | tr '\n' ' ')"
fi

# duplicate (canonical at both spec/ and root)
_D=$(mk_tmp); mkdir -p "$_D/spec"
bash "$HELPER" --seed > "$_D/spec/test-spec.md" 2>/dev/null
bash "$HELPER" --seed > "$_D/test-spec.md" 2>/dev/null
_CD=$(REPO_ROOT="$_D" TEST_SPEC_PATH="$_D/spec/test-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CD" | grep -qx 'DUPLICATE=1'; then
  ok "--classify with files at both spec/ and root => DUPLICATE=1"
else
  fail_test "--classify duplicate wrong: $(printf '%s' "$_CD" | tr '\n' ' ')"
fi

# malformed (no yaml registry) => GENERATION=malformed
_M=$(mk_tmp); mkdir -p "$_M/spec"
printf '# test-spec.md\n\nNo yaml registry here, just prose.\n' > "$_M/spec/test-spec.md"
_CM=$(REPO_ROOT="$_M" TEST_SPEC_PATH="$_M/spec/test-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CM" | grep -qx 'GENERATION=malformed' \
   && ! printf '%s\n' "$_CM" | grep -qx 'GENERATION=legacy'; then
  ok "--classify on a no-registry file => GENERATION=malformed (never legacy)"
else
  fail_test "--classify malformed wrong: $(printf '%s' "$_CM" | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
# 2. --reconcile on canonical: clean no-op + documented note, no .bak
# ---------------------------------------------------------------------------
_R=$(mk_tmp); mkdir -p "$_R/spec"
bash "$HELPER" --seed > "$_R/spec/test-spec.md" 2>/dev/null
_REC=$(REPO_ROOT="$_R" TEST_SPEC_PATH="$_R/spec/test-spec.md" TEST_SPEC_CUSTOM_PATH="$_R/spec/none.md" bash "$HELPER" --reconcile 2>&1)
_REC_RC=$?
if [ "$_REC_RC" -eq 0 ] \
   && printf '%s' "$_REC" | grep -qF 'RECONCILE: already canonical' \
   && printf '%s' "$_REC" | grep -qF 'no divergent legacy on-disk format' \
   && [ ! -f "$_R/spec/test-spec.md.bak" ]; then
  ok "--reconcile on a canonical contract is a clean no-op (note: no divergent legacy format; no .bak)"
else
  fail_test "--reconcile canonical no-op wrong (rc=$_REC_RC): $_REC"
fi

# ---------------------------------------------------------------------------
# 3. --reconcile on duplicate: reports the redundant copy, no auto-delete
# ---------------------------------------------------------------------------
_DR=$(mk_tmp); mkdir -p "$_DR/spec"
bash "$HELPER" --seed > "$_DR/spec/test-spec.md" 2>/dev/null
bash "$HELPER" --seed > "$_DR/test-spec.md" 2>/dev/null
_RECD=$(REPO_ROOT="$_DR" TEST_SPEC_PATH="$_DR/spec/test-spec.md" TEST_SPEC_CUSTOM_PATH="$_DR/spec/none.md" bash "$HELPER" --reconcile 2>&1)
if printf '%s' "$_RECD" | grep -qF 'RECONCILE-WARN' \
   && printf '%s' "$_RECD" | grep -qF 'redundant' \
   && [ -f "$_DR/spec/test-spec.md" ] && [ -f "$_DR/test-spec.md" ]; then
  ok "--reconcile on a duplicate reports the redundant copy and auto-deletes NEITHER file"
else
  fail_test "--reconcile duplicate handling wrong: $_RECD"
fi

# ---------------------------------------------------------------------------
# 4. --reconcile on a malformed registry HALTS (no clobber)
# ---------------------------------------------------------------------------
_MR=$(mk_tmp); mkdir -p "$_MR/spec"
printf '# test-spec.md\n\nHand-broken — no yaml registry.\n' > "$_MR/spec/test-spec.md"
_MR_BEFORE=$(cat "$_MR/spec/test-spec.md")
_RECMR=$(REPO_ROOT="$_MR" TEST_SPEC_PATH="$_MR/spec/test-spec.md" TEST_SPEC_CUSTOM_PATH="$_MR/spec/none.md" bash "$HELPER" --reconcile 2>&1)
_RECMR_RC=$?
_MR_AFTER=$(cat "$_MR/spec/test-spec.md")
if [ "$_RECMR_RC" -ne 0 ] && printf '%s' "$_RECMR" | grep -qF '[test-spec-no-config]' \
   && [ "$_MR_BEFORE" = "$_MR_AFTER" ] && [ ! -f "$_MR/spec/test-spec.md.bak" ]; then
  ok "--reconcile on a malformed registry HALTS [test-spec-no-config] and leaves the file untouched"
else
  fail_test "--reconcile clobbered or did not halt on a malformed registry (rc=$_RECMR_RC): $_RECMR"
fi

# ---------------------------------------------------------------------------
# 5. LIVE workbench: canonical, DUPLICATE=0, --reconcile clean no-op, no .bak
# ---------------------------------------------------------------------------
_LIVE=$(bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_LIVE" | grep -qx 'GENERATION=canonical' \
   && printf '%s\n' "$_LIVE" | grep -qx 'DUPLICATE=0'; then
  ok "LIVE workbench classifies GENERATION=canonical, DUPLICATE=0"
else
  fail_test "LIVE workbench did NOT classify canonical/0: $(printf '%s' "$_LIVE" | tr '\n' ' ')"
fi

_LIVEREC=$(bash "$HELPER" --reconcile 2>&1)
if printf '%s' "$_LIVEREC" | grep -qF 'RECONCILE: already canonical' \
   && ! printf '%s' "$_LIVEREC" | grep -qE '^RECONCILE: migrated' \
   && [ ! -f "$REPO_ROOT/spec/test-spec.md.bak" ]; then
  ok "LIVE workbench --reconcile is a clean no-op (no migration, no .bak written)"
else
  fail_test "LIVE workbench --reconcile was not a clean no-op: $_LIVEREC"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: test-spec-reconcile (all assertions passed)"
  exit 0
else
  echo "FAIL: test-spec-reconcile ($ERRORS error(s))"
  exit 1
fi
