#!/usr/bin/env bash
# tests/doc-spec-reconcile.test.sh
#
# Regression test for the F000065/S000109 doc-spec self-healing reconcile:
# scripts/doc-spec.sh --classify (read-only generation detector) +
# --reconcile (the only new write path; opt-in legacy->canonical migration).
#
# Asserts:
#   1. --classify labels the four generations correctly:
#        absent     -> GENERATION=absent, DUPLICATE=0
#        canonical  -> GENERATION=canonical
#        legacy     -> GENERATION=legacy (ONLY when the old yaml signature
#                      matches AND no canonical table parses)
#        duplicate  -> DUPLICATE=1 (both spec/ + root present)
#      AND a malformed (no-table, no-signature) file -> GENERATION=malformed
#      (NOT legacy — the [doc-sync-no-config] halt is preserved, never clobbered)
#   2. --reconcile migrates a 40+-row legacy YAML fixture -> canonical 3-column
#      Markdown table preserving EVERY declared row (row-count in == out), the
#      migrated file --validate's clean, a <path>.bak is written, and a re-run
#      is a clean no-op (RECONCILE: already canonical)
#   3. the audit_class asymmetry guard fires RECONCILE-WARN for a docs/* row
#      declared audit_class: operational
#   4. --reconcile on a malformed file HALTS [doc-sync-no-config] (never writes)
#   5. the LIVE workbench classifies canonical with DUPLICATE=0 and --reconcile
#      is a clean no-op (zero migration, no .bak)
#
# Temp-dir isolated; never mutates the live tree.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/doc-spec.sh"

_TMPS=""
mk_tmp() {
  _d=$(mktemp -d -t doc-spec-reconcile.XXXXXX)
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

# Emit a legacy-generation doc-spec.md (the pre-F000063 yaml registry) with N
# data rows into $1. $2 (optional) = "asym" adds a docs/* row declared
# audit_class: operational (the asymmetry-guard case).
emit_legacy() {
  _out="$1"; _mode="${2:-}"
  {
    echo "<!-- DOC-SPEC-COMMON:BEGIN -->"
    echo "# doc-spec.md — legacy generation fixture"
    echo ""
    echo "Prose that the legacy generation carried."
    echo ""
    echo "## Machine registry"
    echo ""
    echo '```yaml'
    echo "# doc-spec registry (legacy)"
    echo "schema_version: 1"
    echo "docs:"
    # Four real human/operational rows.
    echo "  - path: docs/philosophy.md"
    echo "    section: common"
    echo "    audit_class: human-doc"
    echo "    front_table: required"
    echo "    purpose: \"Major design logic.\""
    echo "    requirement: \"Arranged by principle; no work-item IDs.\""
    echo "  - path: docs/workflow.md"
    echo "    section: common"
    echo "    audit_class: human-doc"
    echo "    purpose: \"The major workflows.\""
    echo "    requirement: \"Lists every major workflow; no work-item IDs.\""
    echo "  - path: README.md"
    echo "    section: common"
    echo "    audit_class: human-doc"
    echo "    purpose: \"Landing page.\""
    echo "    requirement: \"Folder structure + getting started.\""
    echo "  - path: CLAUDE.md"
    echo "    section: custom"
    echo "    audit_class: operational"
    echo "    purpose: \"Agent instructions.\""
    echo "    requirement: \"Present; work-item refs allowed.\""
    # Synthetic operational rows to push the registry past 40 declared rows.
    _i=1
    while [ "$_i" -le 40 ]; do
      echo "  - path: docs/gen/topic-$_i.md"
      echo "    section: custom"
      echo "    audit_class: operational"
      echo "    purpose: \"Generated topic $_i purpose.\""
      echo "    requirement: \"Topic $_i requirement string.\""
      _i=$((_i + 1))
    done
    if [ "$_mode" = "asym" ]; then
      echo "  - path: docs/asym-row.md"
      echo "    section: custom"
      echo "    audit_class: operational"
      echo "    purpose: \"Asymmetric row.\""
      echo "    requirement: \"Path derives human-doc but declared operational.\""
    fi
    echo '```'
    echo "<!-- DOC-SPEC-COMMON:END -->"
  } > "$_out"
}

echo "=== doc-spec reconcile + classify assertions ==="

[ -x "$HELPER" ] || { fail_test "scripts/doc-spec.sh missing or not executable"; echo "FAIL: doc-spec-reconcile ($ERRORS error(s))"; exit 1; }

# ---------------------------------------------------------------------------
# 1. --classify: four generations
# ---------------------------------------------------------------------------

# absent
_A=$(mk_tmp)
_CA=$(REPO_ROOT="$_A" DOC_SPEC_PATH="$_A/spec/doc-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CA" | grep -qx 'GENERATION=absent' \
   && printf '%s\n' "$_CA" | grep -qx 'DUPLICATE=0' \
   && printf '%s\n' "$_CA" | grep -qx 'CANONICAL_PATH=spec/doc-spec.md'; then
  ok "--classify on an absent contract => GENERATION=absent, DUPLICATE=0, CANONICAL_PATH=spec/doc-spec.md"
else
  fail_test "--classify absent wrong: $(printf '%s' "$_CA" | tr '\n' ' ')"
fi

# canonical (seed-built)
_C=$(mk_tmp); mkdir -p "$_C/spec"
bash "$HELPER" --seed > "$_C/spec/doc-spec.md" 2>/dev/null
_CC=$(REPO_ROOT="$_C" DOC_SPEC_PATH="$_C/spec/doc-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CC" | grep -qx 'GENERATION=canonical' \
   && printf '%s\n' "$_CC" | grep -qx 'DUPLICATE=0'; then
  ok "--classify on a seeded canonical contract => GENERATION=canonical, DUPLICATE=0"
else
  fail_test "--classify canonical wrong: $(printf '%s' "$_CC" | tr '\n' ' ')"
fi

# legacy
_L=$(mk_tmp); mkdir -p "$_L/spec"
emit_legacy "$_L/spec/doc-spec.md"
_CL=$(REPO_ROOT="$_L" DOC_SPEC_PATH="$_L/spec/doc-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CL" | grep -qx 'GENERATION=legacy'; then
  ok "--classify on a legacy yaml fixture => GENERATION=legacy (signature matched, no canonical table)"
else
  fail_test "--classify legacy wrong: $(printf '%s' "$_CL" | tr '\n' ' ')"
fi

# duplicate (canonical at BOTH spec/ and root)
_D=$(mk_tmp); mkdir -p "$_D/spec"
bash "$HELPER" --seed > "$_D/spec/doc-spec.md" 2>/dev/null
bash "$HELPER" --seed > "$_D/doc-spec.md" 2>/dev/null
_CD=$(REPO_ROOT="$_D" DOC_SPEC_PATH="$_D/spec/doc-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CD" | grep -qx 'DUPLICATE=1'; then
  ok "--classify with files at both spec/ and root => DUPLICATE=1"
else
  fail_test "--classify duplicate wrong: $(printf '%s' "$_CD" | tr '\n' ' ')"
fi

# malformed (no table, no legacy signature) => GENERATION=malformed (NOT legacy)
_M=$(mk_tmp); mkdir -p "$_M/spec"
printf '# doc-spec.md\n\nNo table and no yaml registry here, just prose.\n' > "$_M/spec/doc-spec.md"
_CM=$(REPO_ROOT="$_M" DOC_SPEC_PATH="$_M/spec/doc-spec.md" bash "$HELPER" --classify 2>/dev/null)
if printf '%s\n' "$_CM" | grep -qx 'GENERATION=malformed'; then
  ok "--classify on a no-table no-signature file => GENERATION=malformed (never mislabeled legacy)"
else
  fail_test "--classify malformed wrong: $(printf '%s' "$_CM" | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
# 2. --reconcile: 40+-row legacy migration preserving every row + atomic + .bak
#    + idempotent re-run
# ---------------------------------------------------------------------------
_R=$(mk_tmp); mkdir -p "$_R/spec"
emit_legacy "$_R/spec/doc-spec.md"
_IN_ROWS=$(grep -cE '^[[:space:]]*-[[:space:]]*path:' "$_R/spec/doc-spec.md")
if [ "$_IN_ROWS" -ge 40 ]; then
  ok "legacy fixture has $_IN_ROWS declared rows (>= 40, the row-preservation stress case)"
else
  fail_test "legacy fixture only has $_IN_ROWS rows (< 40)"
fi

_REC=$(REPO_ROOT="$_R" DOC_SPEC_PATH="$_R/spec/doc-spec.md" DOC_SPEC_CUSTOM_PATH="$_R/spec/none.md" bash "$HELPER" --reconcile 2>&1)
_REC_RC=$?
if [ "$_REC_RC" -eq 0 ] && printf '%s' "$_REC" | grep -qE '^RECONCILE: migrated [0-9]+ rows'; then
  ok "--reconcile migrated the legacy fixture (exit 0 + migration report)"
else
  fail_test "--reconcile failed (rc=$_REC_RC): $_REC"
fi

# every declared row preserved: canonical-table row count == legacy row count
_OUT_ROWS=$(grep -cE '^\| `' "$_R/spec/doc-spec.md")
if [ "$_OUT_ROWS" -eq "$_IN_ROWS" ]; then
  ok "every declared row preserved: $_IN_ROWS in == $_OUT_ROWS canonical-table rows out"
else
  fail_test "ROW LOSS: $_IN_ROWS legacy rows in but $_OUT_ROWS canonical rows out"
fi

# the migrated file validates clean
if REPO_ROOT="$_R" DOC_SPEC_PATH="$_R/spec/doc-spec.md" DOC_SPEC_CUSTOM_PATH="$_R/spec/none.md" bash "$HELPER" --validate >/dev/null 2>&1; then
  ok "the migrated canonical file --validate's clean (exit 0)"
else
  fail_test "the migrated file did NOT validate clean"
fi

# a .bak of the original was kept
if [ -f "$_R/spec/doc-spec.md.bak" ] && grep -qE '^[[:space:]]*-[[:space:]]*path:' "$_R/spec/doc-spec.md.bak"; then
  ok ".bak of the original legacy file was written"
else
  fail_test "no .bak written (or .bak is not the original legacy file)"
fi

# the canonical Doc column carries clean paths (no leftover '- path:' prefix).
# The backtick + pipe in these patterns are LITERAL Markdown-table glyphs, not
# shell expansions — single quotes are correct here.
# shellcheck disable=SC2016
if grep -qE '^\| `docs/philosophy\.md` \|' "$_R/spec/doc-spec.md" \
   && ! grep -qE '`[[:space:]]*-[[:space:]]*path:' "$_R/spec/doc-spec.md"; then
  ok "the migrated Doc column carries clean repo-relative paths (no list-item prefix bleed)"
else
  fail_test "the migrated Doc column has a malformed path cell"
fi

# idempotent: a re-run on the now-canonical file is a clean no-op
_REC2=$(REPO_ROOT="$_R" DOC_SPEC_PATH="$_R/spec/doc-spec.md" DOC_SPEC_CUSTOM_PATH="$_R/spec/none.md" bash "$HELPER" --reconcile 2>&1)
if printf '%s' "$_REC2" | grep -qF 'RECONCILE: already canonical' \
   && ! printf '%s' "$_REC2" | grep -qE '^RECONCILE: migrated'; then
  ok "idempotent: re-running --reconcile on the migrated file => RECONCILE: already canonical (no second migration)"
else
  fail_test "second --reconcile was not a clean no-op: $_REC2"
fi

# ---------------------------------------------------------------------------
# 3. audit_class asymmetry guard
# ---------------------------------------------------------------------------
_AS=$(mk_tmp); mkdir -p "$_AS/spec"
emit_legacy "$_AS/spec/doc-spec.md" asym
_RECAS=$(REPO_ROOT="$_AS" DOC_SPEC_PATH="$_AS/spec/doc-spec.md" DOC_SPEC_CUSTOM_PATH="$_AS/spec/none.md" bash "$HELPER" --reconcile 2>&1)
if printf '%s' "$_RECAS" | grep -qE "RECONCILE-WARN.*docs/asym-row\.md.*audit_class was 'operational' but path derives 'human-doc'"; then
  ok "audit_class asymmetry guard: RECONCILE-WARN fires for a docs/* row declared operational"
else
  fail_test "asymmetry guard did NOT fire: $_RECAS"
fi

# ---------------------------------------------------------------------------
# 4. --reconcile on a malformed file HALTS (never clobbers)
# ---------------------------------------------------------------------------
_MR=$(mk_tmp); mkdir -p "$_MR/spec"
printf '# doc-spec.md\n\nNo table, no yaml registry — hand-broken canonical.\n' > "$_MR/spec/doc-spec.md"
_MR_BEFORE=$(cat "$_MR/spec/doc-spec.md")
_RECMR=$(REPO_ROOT="$_MR" DOC_SPEC_PATH="$_MR/spec/doc-spec.md" DOC_SPEC_CUSTOM_PATH="$_MR/spec/none.md" bash "$HELPER" --reconcile 2>&1)
_RECMR_RC=$?
_MR_AFTER=$(cat "$_MR/spec/doc-spec.md")
if [ "$_RECMR_RC" -ne 0 ] && printf '%s' "$_RECMR" | grep -qF '[doc-sync-no-config]' \
   && [ "$_MR_BEFORE" = "$_MR_AFTER" ] && [ ! -f "$_MR/spec/doc-spec.md.bak" ]; then
  ok "--reconcile on a malformed file HALTS [doc-sync-no-config] and leaves the file untouched (no clobber, no .bak)"
else
  fail_test "--reconcile clobbered or did not halt on a malformed file (rc=$_RECMR_RC): $_RECMR"
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
   && [ ! -f "$REPO_ROOT/spec/doc-spec.md.bak" ]; then
  ok "LIVE workbench --reconcile is a clean no-op (no migration, no .bak written)"
else
  fail_test "LIVE workbench --reconcile was not a clean no-op (or wrote a .bak): $_LIVEREC"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: doc-spec-reconcile (all assertions passed)"
  exit 0
else
  echo "FAIL: doc-spec-reconcile ($ERRORS error(s))"
  exit 1
fi
