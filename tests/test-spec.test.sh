#!/usr/bin/env bash
# tests/test-spec.test.sh
#
# Regression test for the two-tier test-spec registry (F000060): the general
# spec/test-spec.md (5 portable rules; == test-spec.sh --seed) merged with the
# spec/test-spec-custom.md units overlay by scripts/test-spec.sh — the
# machinery behind validate.sh Check 24. Ports the coverage drift drills from
# the retired predecessor suite.
#
# Asserts:
#   1. both registry files present, exactly one fenced ```yaml block each;
#      helper executable
#   2. --validate exits 0 + OK schema_version=1 on the merge; --list-rules
#      enumerates exactly the 5 portable rules; --list-units >= 60 unique ids
#   3. the absent-vs-invalid split: an ABSENT registry => REGISTRY=absent +
#      exit 0 (for --validate AND --check-coverage); a PRESENT-but-invalid
#      registry => [test-spec-no-config] + exit 1
#   4. malformed-registry fixtures fail closed: bad schema_version / family
#      outside the enum / work-item ID in a rendered field / duplicate id /
#      trigger token outside the enum / test row source-pin violation
#   5. units-gated floor: a rules-only registry (the seeded consumer default)
#      => the named "coverage cross-check inactive" note + exit 0
#   6. seed byte identity: --seed == spec/test-spec.md; the seed alone
#      validates in a bare temp dir (rules-only)
#   7. the coverage drift drills, temp-dir isolated (a COPY of the swept
#      surface; the live tree is never mutated):
#        (a) fake `=== Check 99` banner          -> REVERSE flags it
#        (b) corrupted anchor in the registry    -> FORWARD names row + source
#        (d) removed runner block in test.sh     -> FORWARD (silent-skip catch)
#        (f) unregistered tests/*.test.sh        -> REVERSE flags the file
#        (f2) self-satisfying source-pin row     -> the validate-time pin halts
#        (g) dead-text bypass (invocation gone)  -> execution-shaped FORWARD
#        (h) commented-out check banner          -> execution-shaped FORWARD
#        (i) vanished standalone suite script    -> FORWARD existence pin
#        (j) floor: TEST_SPEC_REVERSE_FLOOR=999  -> floor finding fires
#
# Temp-dir isolated throughout; never mutates the live tree.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/test-spec.sh"
GENERAL="$REPO_ROOT/spec/test-spec.md"
OVERLAY="$REPO_ROOT/spec/test-spec-custom.md"

_TMPS=""
mk_tmp() {
  _d=$(mktemp -d -t test-spec.XXXXXX)
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

echo "=== test-spec two-tier registry + parser + coverage assertions ==="

# 1. files + fences + helper
for _f in "$GENERAL" "$OVERLAY"; do
  if [ -f "$_f" ]; then
    _FENCES=$(grep -cE '^```yaml' "$_f" || true)
    if [ "${_FENCES:-0}" -eq 1 ]; then
      ok "$(basename "$_f") present with exactly one fenced yaml block"
    else
      fail_test "$(basename "$_f") should have exactly 1 \`\`\`yaml block, found $_FENCES"
    fi
  else
    fail_test "$_f missing"
  fi
done
if [ -x "$HELPER" ]; then
  ok "scripts/test-spec.sh exists and is executable"
else
  fail_test "scripts/test-spec.sh missing or not executable"
  echo "FAIL: test-spec ($ERRORS error(s))"
  exit 1
fi

# 2. merged validate + lists
_V_OUT=$(bash "$HELPER" --validate 2>&1); _V_RC=$?
if [ "$_V_RC" -eq 0 ] && printf '%s' "$_V_OUT" | grep -qF 'OK schema_version=1'; then
  ok "--validate exits 0 + prints OK schema_version=1 on the merge"
else
  fail_test "--validate failed or wrong output (rc=$_V_RC): $_V_OUT"
fi
_RULES=$(bash "$HELPER" --list-rules 2>/dev/null)
if [ "$(printf '%s\n' "$_RULES" | grep -c .)" -eq 5 ] \
   && printf '%s\n' "$_RULES" | grep -qx 'tests-discoverable' \
   && printf '%s\n' "$_RULES" | grep -qx 'suite-green' \
   && printf '%s\n' "$_RULES" | grep -qx 'new-code-tested' \
   && printf '%s\n' "$_RULES" | grep -qx 'units-anchored' \
   && printf '%s\n' "$_RULES" | grep -qx 'single-owner'; then
  ok "--list-rules enumerates exactly the 5 portable rules"
else
  fail_test "--list-rules wrong (got: $(printf '%s' "$_RULES" | tr '\n' ' '))"
fi
_UNITS=$(bash "$HELPER" --list-units 2>/dev/null)
_N=$(printf '%s\n' "$_UNITS" | grep -c . || true)
_NU=$(printf '%s\n' "$_UNITS" | sort -u | grep -c . || true)
if [ "${_N:-0}" -ge 60 ] && [ "$_N" -eq "$_NU" ]; then
  ok "--list-units enumerates $_N overlay units, all ids unique"
else
  fail_test "--list-units wrong shape (n=$_N unique=$_NU; want >= 60 and equal)"
fi

# 3. absent-vs-invalid split
_ABS=$(TEST_SPEC_PATH=/nonexistent-test-spec.md bash "$HELPER" --validate 2>/dev/null); _ABS_RC=$?
if [ "$_ABS_RC" -eq 0 ] && [ "$_ABS" = "REGISTRY=absent" ]; then
  ok "absent registry: --validate prints REGISTRY=absent + exits 0 (machine-classifiable skip)"
else
  fail_test "absent registry mis-classified by --validate (rc=$_ABS_RC out=$_ABS)"
fi
_ABS2=$(TEST_SPEC_PATH=/nonexistent-test-spec.md bash "$HELPER" --check-coverage 2>/dev/null); _ABS2_RC=$?
if [ "$_ABS2_RC" -eq 0 ] && [ "$_ABS2" = "REGISTRY=absent" ]; then
  ok "absent registry: --check-coverage prints REGISTRY=absent + exits 0"
else
  fail_test "absent registry mis-classified by --check-coverage (rc=$_ABS2_RC out=$_ABS2)"
fi

# 4. malformed-registry fixtures fail closed (TEST_SPEC_PATH override; temp dir)
_MF=$(mk_tmp)
_mk_fixture() { cat > "$_MF/$1"; }
_assert_halts() {
  # $1 = fixture file, $2 = description, $3 = required output substring
  _H_OUT=$(TEST_SPEC_PATH="$_MF/$1" bash "$HELPER" --validate 2>&1); _H_RC=$?
  if [ "$_H_RC" -ne 0 ] && printf '%s' "$_H_OUT" | grep -qF '[test-spec-no-config]'; then
    if [ -n "${3:-}" ] && ! printf '%s' "$_H_OUT" | grep -qF "$3"; then
      fail_test "malformed fixture ($2) halted but without the expected reason '$3': $_H_OUT"
    else
      ok "malformed fixture ($2) fails closed with [test-spec-no-config]"
    fi
  else
    fail_test "malformed fixture ($2) did not halt (rc=$_H_RC out=$_H_OUT)"
  fi
}

_RULE_BLOCK='rules:
  - id: r-one
    statement: "A rule."
    scope: "everything"
    enforced_by: "a check"'

_mk_fixture bad-schema.md <<EOF
\`\`\`yaml
schema_version: 9
$_RULE_BLOCK
\`\`\`
EOF
_assert_halts bad-schema.md "bad schema_version" "unsupported"

_mk_fixture bad-family.md <<EOF
\`\`\`yaml
schema_version: 1
$_RULE_BLOCK
units:
  - id: u-one
    family: not-a-family
    label: "A unit"
    anchor: "anchor-1"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A purpose."
\`\`\`
EOF
_assert_halts bad-family.md "family outside the enum" "outside the closed enum"

_mk_fixture id-in-label.md <<EOF
\`\`\`yaml
schema_version: 1
$_RULE_BLOCK
units:
  - id: u-one
    family: validate
    label: "A unit shipped by F000999"
    anchor: "anchor-1"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A purpose."
\`\`\`
EOF
_assert_halts id-in-label.md "work-item ID in a rendered field" "rendered field"

_mk_fixture dup-id.md <<EOF
\`\`\`yaml
schema_version: 1
$_RULE_BLOCK
units:
  - id: u-one
    family: validate
    label: "A unit"
    anchor: "anchor-1"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A purpose."
  - id: u-one
    family: validate
    label: "Another unit"
    anchor: "anchor-2"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Another purpose."
\`\`\`
EOF
_assert_halts dup-id.md "duplicate id" "duplicate unit id"

_mk_fixture bad-trigger.md <<EOF
\`\`\`yaml
schema_version: 1
$_RULE_BLOCK
units:
  - id: u-one
    family: validate
    label: "A unit"
    anchor: "anchor-1"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci sometimes"
    purpose: "A purpose."
\`\`\`
EOF
_assert_halts bad-trigger.md "trigger token outside the enum" "trigger token"

_mk_fixture bad-test-source.md <<EOF
\`\`\`yaml
schema_version: 1
$_RULE_BLOCK
units:
  - id: test-self-ref
    family: test
    label: "A test suite"
    anchor: "tests/zz-selfref.test.sh"
    source: tests/zz-selfref.test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A purpose."
\`\`\`
EOF
_assert_halts bad-test-source.md "test row pointing source at the test file itself (silent-skip disarm)" "MUST declare source: scripts/test.sh"

_mk_fixture no-rules.md <<'EOF'
```yaml
schema_version: 1
units:
  - id: u-one
    family: validate
    label: "A unit"
    anchor: "anchor-1"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A purpose."
```
EOF
_assert_halts no-rules.md "no rules (the general contract must carry the portable rules)" "no rules"

# 5. units-gated floor: rules-only registry => named inactive note + exit 0
_RO=$(mk_tmp)
bash "$HELPER" --seed > "$_RO/test-spec.md" 2>/dev/null
_RO_OUT=$(TEST_SPEC_PATH="$_RO/test-spec.md" REPO_ROOT="$_RO" bash "$HELPER" --check-coverage 2>&1); _RO_RC=$?
if [ "$_RO_RC" -eq 0 ] && printf '%s' "$_RO_OUT" | grep -qF 'no units declared — coverage cross-check inactive; declare units in spec/test-spec-custom.md to activate'; then
  ok "rules-only registry: --check-coverage emits the named inactive note + exits 0 (units-gated floor)"
else
  fail_test "rules-only registry mis-handled (rc=$_RO_RC): $_RO_OUT"
fi

# 6. seed byte identity + bare validate
_SD=$(mk_tmp)
bash "$HELPER" --seed > "$_SD/seed.md" 2>/dev/null
if cmp -s "$_SD/seed.md" "$GENERAL"; then
  ok "--seed == spec/test-spec.md byte-for-byte (the general file IS the seed)"
else
  fail_test "spec/test-spec.md != --seed output (byte identity broken)"
fi
_SD_V=$(TEST_SPEC_PATH="$_SD/seed.md" bash "$HELPER" --validate 2>&1); _SD_RC=$?
if [ "$_SD_RC" -eq 0 ]; then
  ok "the seed alone validates (a seeded consumer repo parses clean, rules-only)"
else
  fail_test "the seed alone does not validate (rc=$_SD_RC): $_SD_V"
fi

# 7. coverage drift drills against a temp COPY of the swept surface.
_FIX=$(mk_tmp)
mkdir -p "$_FIX/scripts" "$_FIX/tests" "$_FIX/.github/workflows" "$_FIX/spec"
_rebuild_fixture() {
  cp "$REPO_ROOT/scripts/validate.sh" "$_FIX/scripts/validate.sh"
  cp "$REPO_ROOT/scripts/test.sh" "$_FIX/scripts/test.sh"
  cp "$REPO_ROOT/scripts/setup-hooks.sh" "$_FIX/scripts/setup-hooks.sh"
  # rows anchored on script paths require the file to exist on disk
  : > "$_FIX/scripts/test-deploy.sh"
  : > "$_FIX/scripts/eval.sh"
  : > "$_FIX/scripts/windows-smoke.sh"
  : > "$_FIX/scripts/cj-portability-audit.sh"
  cp "$REPO_ROOT"/.github/workflows/*.yml "$_FIX/.github/workflows/"
  rm -f "$_FIX/tests"/*.test.sh
  for _tf in "$REPO_ROOT"/tests/*.test.sh; do
    [ -e "$_tf" ] || continue
    : > "$_FIX/tests/$(basename "$_tf")"
  done
  cp "$GENERAL" "$_FIX/spec/test-spec.md"
  cp "$OVERLAY" "$_FIX/spec/test-spec-custom.md"
}
_rebuild_fixture

# Baseline: the fixture copy of the live surface is coverage-clean.
_B_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _B_RC=$?
if [ "$_B_RC" -eq 0 ] && printf '%s' "$_B_OUT" | grep -qF 'findings=0'; then
  ok "drill baseline: fixture copy of the live surface is coverage-clean"
else
  fail_test "drill baseline not clean (rc=$_B_RC): $_B_OUT"
fi

# Drill (a) — REVERSE: a new check lands without a registry row.
printf '\necho "=== Check 99: fake coverage drill ==="\n' >> "$_FIX/scripts/validate.sh"
_A_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _A_RC=$?
if [ "$_A_RC" -ne 0 ] && printf '%s' "$_A_OUT" | grep -qF "Check 99" \
   && printf '%s' "$_A_OUT" | grep -qF 'reverse'; then
  ok "drill (a): fake banner in the temp validate.sh -> reverse sweep flags 'Check 99'"
else
  fail_test "drill (a) did not flag the fake banner (rc=$_A_RC): $_A_OUT"
fi
_rebuild_fixture

# Drill (b) — FORWARD: a registry anchor rots (corrupt one overlay anchor).
sed 's/anchor: "# Error check 1:"/anchor: "# Error check 991:"/' \
  "$_FIX/spec/test-spec-custom.md" > "$_FIX/spec/test-spec-custom.md.new" \
  && mv "$_FIX/spec/test-spec-custom.md.new" "$_FIX/spec/test-spec-custom.md"
_B2_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _B2_RC=$?
if [ "$_B2_RC" -ne 0 ] && printf '%s' "$_B2_OUT" | grep -qF "validate-error-check-1" \
   && printf '%s' "$_B2_OUT" | grep -qF 'scripts/validate.sh'; then
  ok "drill (b): corrupted overlay anchor -> forward check names the row + its source"
else
  fail_test "drill (b) did not flag the corrupted anchor (rc=$_B2_RC): $_B2_OUT"
fi
_rebuild_fixture

# Drill (d) — FORWARD, the silent-skip catch: a runner block is removed from
# the temp test.sh while the test file stays on disk.
grep -vF 'tests/cj-id-claim.test.sh' "$_FIX/scripts/test.sh" > "$_FIX/scripts/test.sh.cut" \
  && mv "$_FIX/scripts/test.sh.cut" "$_FIX/scripts/test.sh"
_D_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _D_RC=$?
if [ "$_D_RC" -ne 0 ] && printf '%s' "$_D_OUT" | grep -qF "test-cj-id-claim" \
   && printf '%s' "$_D_OUT" | grep -qF 'no longer wired'; then
  ok "drill (d): removed runner block -> forward check flags the orphaned test row"
else
  fail_test "drill (d) did not flag the orphaned test row (rc=$_D_RC): $_D_OUT"
fi
_rebuild_fixture

# Drill (f) — REVERSE: a brand-new tests/*.test.sh appears with NO registry row.
: > "$_FIX/tests/zz-unregistered-drill.test.sh"
_F_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _F_RC=$?
if [ "$_F_RC" -ne 0 ] && printf '%s' "$_F_OUT" | grep -qF "zz-unregistered-drill.test.sh" \
   && printf '%s' "$_F_OUT" | grep -qF 'reverse'; then
  ok "drill (f): unregistered test file on disk -> reverse sweep flags it (no registry row)"
else
  fail_test "drill (f) did not flag the unregistered test file (rc=$_F_RC): $_F_OUT"
fi
_rebuild_fixture

# Drill (f2) — the source-pin bypass: an unwired test file ships WITH a row
# whose source points at the test file itself; the validate-time pin halts.
printf '#!/usr/bin/env bash\n# tests/zz-selfref.test.sh — self-referencing drill file\n' > "$_FIX/tests/zz-selfref.test.sh"
awk '
  /^```$/ && !done { print "  - id: test-zz-selfref"; \
    print "    family: test"; \
    print "    label: \"Self-ref drill suite\""; \
    print "    anchor: \"tests/zz-selfref.test.sh\""; \
    print "    source: tests/zz-selfref.test.sh"; \
    print "    layer: ci"; \
    print "    disposition: hard-fail"; \
    print "    trigger: \"pr-ci\""; \
    print "    purpose: \"A drill purpose.\""; done=1 }
  { print }
' "$_FIX/spec/test-spec-custom.md" > "$_FIX/spec/test-spec-custom.md.new" \
  && mv "$_FIX/spec/test-spec-custom.md.new" "$_FIX/spec/test-spec-custom.md"
_F2_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _F2_RC=$?
if [ "$_F2_RC" -ne 0 ] && printf '%s' "$_F2_OUT" | grep -qF "zz-selfref.test.sh" \
   && printf '%s' "$_F2_OUT" | grep -qF 'source: scripts/test.sh'; then
  ok "drill (f2): self-satisfying source row -> the source pin flags the unwired test"
else
  fail_test "drill (f2) did not flag the self-referencing row (rc=$_F2_RC): $_F2_OUT"
fi
_rebuild_fixture

# Drill (g) — FORWARD, the dead-text bypass: the runner INVOCATION line is
# deleted but every other textual mention stays.
sed -E '/^[^#]*bash .*tests\/cj-id-claim\.test\.sh/d' "$_FIX/scripts/test.sh" > "$_FIX/scripts/test.sh.cut" \
  && mv "$_FIX/scripts/test.sh.cut" "$_FIX/scripts/test.sh"
if grep -qF 'tests/cj-id-claim.test.sh' "$_FIX/scripts/test.sh"; then
  _G_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _G_RC=$?
  if [ "$_G_RC" -ne 0 ] && printf '%s' "$_G_OUT" | grep -qF "test-cj-id-claim" \
     && printf '%s' "$_G_OUT" | grep -qF 'forward'; then
    ok "drill (g): invocation deleted, log strings left behind -> execution-shaped forward flags it"
  else
    fail_test "drill (g) dead-text bypass not caught (rc=$_G_RC): $_G_OUT"
  fi
else
  fail_test "drill (g) setup broken: no residual textual mention left to prove the bypass"
fi
_rebuild_fixture

# Drill (h) — FORWARD, the commented-out-check bypass.
sed 's/^echo "=== Check 21:/# disabled: &/' "$_FIX/scripts/validate.sh" > "$_FIX/scripts/validate.sh.cut" \
  && mv "$_FIX/scripts/validate.sh.cut" "$_FIX/scripts/validate.sh"
_H2_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _H2_RC=$?
if [ "$_H2_RC" -ne 0 ] && printf '%s' "$_H2_OUT" | grep -qF "validate-check-21" \
   && printf '%s' "$_H2_OUT" | grep -qF 'forward'; then
  ok "drill (h): commented-out check banner -> execution-shaped forward flags the dead check"
else
  fail_test "drill (h) commented-out-check bypass not caught (rc=$_H2_RC): $_H2_OUT"
fi
_rebuild_fixture

# Drill (i) — FORWARD, the vanished-suite bypass.
rm -f "$_FIX/scripts/test-deploy.sh"
_I_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _I_RC=$?
if [ "$_I_RC" -ne 0 ] && printf '%s' "$_I_OUT" | grep -qF "suite-test-deploy"; then
  ok "drill (i): suite script absent from the surface -> forward existence pin flags the row"
else
  fail_test "drill (i) vanished-suite not caught (rc=$_I_RC): $_I_OUT"
fi
_rebuild_fixture

# Drill (j) — floor: an absurd floor makes the (clean) fixture fail loudly,
# proving the floor assert is alive and env-overridable.
_J_OUT=$(REPO_ROOT="$_FIX" TEST_SPEC_REVERSE_FLOOR=999 bash "$HELPER" --check-coverage 2>&1); _J_RC=$?
if [ "$_J_RC" -ne 0 ] && printf '%s' "$_J_OUT" | grep -qF 'floor'; then
  ok "drill (j): TEST_SPEC_REVERSE_FLOOR=999 -> the floor finding fires (alive + overridable)"
else
  fail_test "drill (j) floor assert not alive (rc=$_J_RC): $_J_OUT"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: test-spec"
  exit 0
else
  echo "FAIL: test-spec ($ERRORS error(s))"
  exit 1
fi
