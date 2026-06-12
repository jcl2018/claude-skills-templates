#!/usr/bin/env bash
# tests/doc-spec-overlay.test.sh
#
# Regression test for the two-tier doc-spec registry (F000060): the general
# spec/doc-spec.md (== doc-spec.sh --seed, byte-identical) merged with the
# optional spec/doc-spec-custom.md overlay by scripts/doc-spec.sh.
#
# Asserts:
#   1. live tree: --validate exits 0 on the MERGED registry; the merged
#      --list-declared carries general AND overlay paths; --render custom
#      renders the overlay rows; --list-front-table-docs lists the seed's
#      flagged docs
#   2. seed 3-way byte identity: the embedded --seed heredoc (templates/
#      absent) == spec/doc-spec.md == templates/doc-spec-common.md
#   3. overlay-absent fixture: general-only results, no finding, no error
#   4. overlay-present fixture: merged list + render-custom from the overlay
#   5. duplicate path across the two files => --validate halts
#      [doc-sync-no-config] naming the duplicate
#   6. present-but-invalid overlay (bad audit_class) => --validate halts
#   7. DOC_SPEC_PATH override stays hermetic: the overlay resolves NEXT TO the
#      overridden general file, never the live repo's overlay
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
  _d=$(mktemp -d -t doc-spec-overlay.XXXXXX)
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

echo "=== doc-spec two-tier overlay merge assertions ==="

[ -x "$HELPER" ] || { fail_test "scripts/doc-spec.sh missing or not executable"; echo "FAIL: doc-spec-overlay ($ERRORS error(s))"; exit 1; }

# 1. live tree: merged validate + lists + render
_V=$(bash "$HELPER" --validate 2>&1); _VRC=$?
if [ "$_VRC" -eq 0 ] && printf '%s' "$_V" | grep -qF 'OK schema_version=1'; then
  ok "live --validate exits 0 on the merged registry"
else
  fail_test "live --validate failed (rc=$_VRC): $_V"
fi

_LD=$(bash "$HELPER" --list-declared 2>/dev/null)
if printf '%s\n' "$_LD" | grep -qx 'docs/philosophy.md' \
   && printf '%s\n' "$_LD" | grep -qx 'spec/test-spec.md' \
   && printf '%s\n' "$_LD" | grep -qx 'spec/gate-spec.md' \
   && printf '%s\n' "$_LD" | grep -qx 'spec/doc-spec-custom.md' \
   && printf '%s\n' "$_LD" | grep -qx 'spec/test-spec-custom.md'; then
  ok "live --list-declared carries general (philosophy, test-spec) AND overlay (gate-spec, both overlay self-rows) paths"
else
  fail_test "live --list-declared missing merged paths (got: $(printf '%s' "$_LD" | tr '\n' ' '))"
fi

_RC_OUT=$(bash "$HELPER" --render custom 2>/dev/null)
if printf '%s\n' "$_RC_OUT" | grep -qF 'spec/gate-spec.md' \
   && printf '%s\n' "$_RC_OUT" | grep -qF 'CONTRIBUTING.md' \
   && printf '%s\n' "$_RC_OUT" | grep -qF 'spec/permission-policy.md'; then
  ok "live --render custom renders the overlay's migrated rows"
else
  fail_test "live --render custom missing overlay rows: $_RC_OUT"
fi
if printf '%s\n' "$_RC_OUT" | grep -qF 'docs/philosophy.md'; then
  fail_test "live --render custom leaked a section:common row"
else
  ok "live --render custom carries no section:common rows"
fi

_FT=$(bash "$HELPER" --list-front-table-docs 2>/dev/null)
if [ "$(printf '%s\n' "$_FT" | grep -c .)" -eq 2 ] \
   && printf '%s\n' "$_FT" | grep -qx 'docs/philosophy.md' \
   && printf '%s\n' "$_FT" | grep -qx 'docs/workflow.md'; then
  ok "live --list-front-table-docs == the seed's two flagged docs"
else
  fail_test "front-table list wrong (got: $(printf '%s' "$_FT" | tr '\n' ' '))"
fi

# 2. seed 3-way byte identity (heredoc forced via empty REPO_ROOT temp)
_S=$(mk_tmp)
REPO_ROOT="$_S" bash "$HELPER" --seed > "$_S/seed-heredoc.md" 2>/dev/null
if cmp -s "$_S/seed-heredoc.md" "$REPO_ROOT/spec/doc-spec.md"; then
  ok "seed (embedded heredoc) == spec/doc-spec.md byte-for-byte (general file IS the seed)"
else
  fail_test "spec/doc-spec.md != --seed output (the general file must be byte-identical to the seed)"
fi
if cmp -s "$_S/seed-heredoc.md" "$REPO_ROOT/templates/doc-spec-common.md"; then
  ok "seed (embedded heredoc) == templates/doc-spec-common.md byte-for-byte"
else
  fail_test "templates/doc-spec-common.md != --seed output (3-way lockstep broken)"
fi

# 3. overlay-absent fixture: general-only results, no finding
_GA=$(mk_tmp)
bash "$HELPER" --seed > "$_GA/doc-spec.md" 2>/dev/null
_GA_V=$(REPO_ROOT="$_GA" bash "$HELPER" --validate 2>&1); _GA_RC=$?
if [ "$_GA_RC" -eq 0 ]; then
  ok "overlay-absent fixture: --validate exits 0 (nothing to merge, no finding)"
else
  fail_test "overlay-absent fixture errored (rc=$_GA_RC): $_GA_V"
fi
_GA_C=$(REPO_ROOT="$_GA" bash "$HELPER" --render custom 2>/dev/null | { grep -c '^| ' || true; })
# 2 = header + delimiter rows only (no data rows render with a leading '| path')
if [ "${_GA_C:-0}" -eq 0 ]; then
  ok "overlay-absent fixture: --render custom has no custom data rows"
else
  # header rows start with '| Doc' / '|---'; data rows are '| <path> |'
  _GA_DATA=$(REPO_ROOT="$_GA" bash "$HELPER" --render custom 2>/dev/null | { grep -vc '^| Doc\|^|---' || true; })
  if [ "${_GA_DATA:-0}" -eq 0 ]; then
    ok "overlay-absent fixture: --render custom has no custom data rows"
  else
    fail_test "overlay-absent fixture rendered unexpected custom data rows"
  fi
fi

# 4. overlay-present fixture: merged list + render-custom from the overlay
cat > "$_GA/doc-spec-custom.md" <<'EOF'
# overlay fixture
```yaml
schema_version: 1
docs:
  - path: EXTRA.md
    section: custom
    audit_class: operational
    purpose: "An overlay fixture doc."
    requirement: "Present."
```
EOF
_GA_LD=$(REPO_ROOT="$_GA" bash "$HELPER" --list-declared 2>/dev/null)
if printf '%s\n' "$_GA_LD" | grep -qx 'EXTRA.md' && printf '%s\n' "$_GA_LD" | grep -qx 'README.md'; then
  ok "overlay-present fixture: --list-declared is the MERGE (general + overlay row)"
else
  fail_test "overlay-present fixture merge broken (got: $(printf '%s' "$_GA_LD" | tr '\n' ' '))"
fi
if REPO_ROOT="$_GA" bash "$HELPER" --render custom 2>/dev/null | grep -qF 'EXTRA.md'; then
  ok "overlay-present fixture: --render custom reads the overlay"
else
  fail_test "overlay-present fixture: --render custom missing the overlay row"
fi
if REPO_ROOT="$_GA" bash "$HELPER" --expand-whitelist 2>/dev/null | grep -qx 'EXTRA.md'; then
  ok "overlay-present fixture: --expand-whitelist includes the overlay path"
else
  fail_test "overlay-present fixture: --expand-whitelist missing the overlay path"
fi

# 5. duplicate path across the two files => --validate halts
cat > "$_GA/doc-spec-custom.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: README.md
    section: custom
    audit_class: operational
    purpose: "Duplicate of a general row."
    requirement: "Present."
```
EOF
_DUP=$(REPO_ROOT="$_GA" bash "$HELPER" --validate 2>&1); _DUP_RC=$?
if [ "$_DUP_RC" -ne 0 ] && printf '%s' "$_DUP" | grep -qF '[doc-sync-no-config]' \
   && printf '%s' "$_DUP" | grep -qF 'duplicate path' \
   && printf '%s' "$_DUP" | grep -qF 'README.md'; then
  ok "duplicate path across general + overlay halts [doc-sync-no-config] naming the path"
else
  fail_test "duplicate-path guard did not fire (rc=$_DUP_RC): $_DUP"
fi

# 6. present-but-invalid overlay halts
cat > "$_GA/doc-spec-custom.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: BAD.md
    section: custom
    audit_class: not-a-class
```
EOF
_BAD=$(REPO_ROOT="$_GA" bash "$HELPER" --validate 2>&1); _BAD_RC=$?
if [ "$_BAD_RC" -ne 0 ] && printf '%s' "$_BAD" | grep -qF '[doc-sync-no-config]' \
   && printf '%s' "$_BAD" | grep -qF 'overlay'; then
  ok "present-but-invalid overlay halts [doc-sync-no-config] naming the overlay"
else
  fail_test "invalid-overlay gate did not fire (rc=$_BAD_RC): $_BAD"
fi
rm -f "$_GA/doc-spec-custom.md"

# 7. DOC_SPEC_PATH override stays hermetic (overlay resolves NEXT TO the override)
_H=$(mk_tmp)
bash "$HELPER" --seed > "$_H/doc-spec.md" 2>/dev/null
_H_LD=$(DOC_SPEC_PATH="$_H/doc-spec.md" bash "$HELPER" --list-declared 2>/dev/null)
if printf '%s\n' "$_H_LD" | grep -qx 'spec/gate-spec.md'; then
  fail_test "DOC_SPEC_PATH override leaked the live repo's overlay rows (not hermetic)"
else
  ok "DOC_SPEC_PATH override is hermetic (live overlay rows NOT merged into the temp parse)"
fi
cat > "$_H/doc-spec-custom.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: SIBLING.md
    section: custom
    audit_class: operational
    purpose: "Sibling overlay of an overridden general file."
    requirement: "Present."
```
EOF
_H_LD2=$(DOC_SPEC_PATH="$_H/doc-spec.md" bash "$HELPER" --list-declared 2>/dev/null)
if printf '%s\n' "$_H_LD2" | grep -qx 'SIBLING.md'; then
  ok "the overlay resolves next to the overridden general file (sibling merge)"
else
  fail_test "sibling overlay of an overridden general file was not merged"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: doc-spec-overlay"
  exit 0
else
  echo "FAIL: doc-spec-overlay ($ERRORS error(s))"
  exit 1
fi
