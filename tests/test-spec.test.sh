#!/usr/bin/env bash
# tests/test-spec.test.sh
#
# Regression test for the two-tier test-spec registry (F000060 + F000063): the
# general spec/test-spec.md (5 portable rules + the four-layer layers[] map;
# == test-spec.sh --seed) merged with the spec/test-spec-custom.md units + gates
# overlay by scripts/test-spec.sh — the machinery behind validate.sh Check 24.
# Ports the coverage drift drills from the retired predecessor suite; the
# layers[]/gates[] parsing folded in from the retired gate-spec.sh (F000063).
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
# F000063: the merged registry carries the four-layer layers[] (general) + the
# per-mode gates[] (overlay, folded in from the retired gate-spec.md).
_LAYERS=$(bash "$HELPER" --list-layers 2>/dev/null)
if printf '%s\n' "$_LAYERS" | grep -qx 'local-hook' \
   && printf '%s\n' "$_LAYERS" | grep -qx 'ci' \
   && printf '%s\n' "$_LAYERS" | grep -qx 'pipeline-gate' \
   && printf '%s\n' "$_LAYERS" | grep -qx 'ratchet'; then
  ok "--list-layers enumerates the four verification layers"
else
  fail_test "--list-layers wrong (got: $(printf '%s' "$_LAYERS" | tr '\n' ' '))"
fi
_GATES=$(bash "$HELPER" --list-gates 2>/dev/null)
if printf '%s\n' "$_GATES" | grep -qx 'isolation' \
   && printf '%s\n' "$_GATES" | grep -qx 'qa-audit' \
   && printf '%s\n' "$_GATES" | grep -qx 'doc-sync' \
   && printf '%s\n' "$_GATES" | grep -qx 'portability' \
   && printf '%s\n' "$_GATES" | grep -qx 'ship'; then
  ok "--list-gates enumerates the per-mode pipeline gates"
else
  fail_test "--list-gates wrong (got: $(printf '%s' "$_GATES" | tr '\n' ' '))"
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
  # The dogfood behaviors[] (F000066) anchor their semantic evidence in
  # tests/test-spec.test.sh; the reverse sweep only needs each test file to
  # EXIST (it greps scripts/test.sh for the runner path, not the file body), so
  # copying the real test-spec.test.sh content keeps the fixture's behavior
  # coverage clean WITHOUT affecting the units reverse sweep.
  cp "$REPO_ROOT/tests/test-spec.test.sh" "$_FIX/tests/test-spec.test.sh"
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
# Insert the self-ref unit row inside the units: block — BEFORE the top-level
# `gates:` line (the overlay carries units: then gates:); appending at the
# closing fence would land it inside the gates: block and the gates parser
# would mis-read it.
awk '
  /^gates:$/ && !done { print "  - id: test-zz-selfref"; \
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

# 8. surface-existence gating of the reverse floors (D000035). A consumer repo
# that adopts the contract against ITS OWN surface (vitest *.test.ts + a
# workflow, with NO scripts/validate.sh / tests/*.test.sh / scripts/setup-hooks.sh)
# legitimately yields zero tokens in the absent namespaces — the floors must
# treat an absent surface as N/A, never a finding. The fix is surface-existence
# GATING, not floor removal: a present-but-zero-token namespace still fires.

# Case (a) — consumer-shaped fixture: units against a vitest *.test.ts + a
# GitHub workflow; NO shell validate/test-files/hooks surfaces on disk.
# --check-coverage must exit 0, print "OK coverage", and emit NO floor findings.
_CONS=$(mk_tmp)
mkdir -p "$_CONS/spec" "$_CONS/tests" "$_CONS/.github/workflows"
bash "$HELPER" --seed > "$_CONS/spec/test-spec.md" 2>/dev/null
cat > "$_CONS/tests/foo.test.ts" <<'CONS_TS'
import { describe, it, expect } from 'vitest';
describe('consumer suite', () => {
  it('CONSUMER_ANCHOR_TOKEN does the thing', () => { expect(1 + 1).toBe(2); });
});
CONS_TS
cat > "$_CONS/.github/workflows/ci.yml" <<'CONS_WF'
name: Consumer CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test
CONS_WF
cat > "$_CONS/spec/test-spec-custom.md" <<'CONS_OVL'
# test-spec-custom.md — consumer overlay

```yaml
schema_version: 1
units:
  - id: consumer-foo-suite
    family: ci
    label: "Consumer foo suite — the vitest unit suite"
    anchor: "CONSUMER_ANCHOR_TOKEN"
    source: tests/foo.test.ts
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The consumer's vitest suite asserts the core unit behaves."
  - id: consumer-ci-workflow
    family: ci
    label: "Consumer CI workflow — the PR gate"
    anchor: "name: Consumer CI"
    source: .github/workflows/ci.yml
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The consumer's GitHub Actions workflow runs the suite on every PR."
```
CONS_OVL
_CONS_OUT=$(REPO_ROOT="$_CONS" TEST_SPEC_PATH="$_CONS/spec/test-spec.md" TEST_SPEC_CUSTOM_PATH="$_CONS/spec/test-spec-custom.md" bash "$HELPER" --check-coverage 2>&1); _CONS_RC=$?
if [ "$_CONS_RC" -eq 0 ] \
   && printf '%s' "$_CONS_OUT" | grep -qF 'OK coverage' \
   && ! printf '%s' "$_CONS_OUT" | grep -qF 'FINDING: floor'; then
  ok "case (a): consumer surface (no shell validate/test-files/hooks) -> OK coverage, exit 0, NO floor findings (surface-gated)"
else
  fail_test "case (a) floor false-fired on a consumer surface (rc=$_CONS_RC): $_CONS_OUT"
fi

# Case (b) — workbench-shaped regression guard: ALL FOUR surfaces present, but
# ONE namespace (hooks) is present-yet-yields-zero-tokens (setup-hooks.sh
# exists with NO `if install_hook` lines). The per-namespace floor for that
# namespace must STILL fire — proving the fix is surface-existence GATING, not
# floor removal. (The global floor stays calibrated: dropping the 2 hook
# tokens still leaves the full-surface fixture above the 20-token floor.)
_rebuild_fixture
: > "$_FIX/scripts/setup-hooks.sh"   # surface PRESENT but emits zero hook tokens
_HZ_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _HZ_RC=$?
if [ "$_HZ_RC" -ne 0 ] \
   && printf '%s' "$_HZ_OUT" | grep -qF "ZERO live tokens in the 'hooks' namespace"; then
  ok "case (b): hooks surface present but zero tokens -> the per-namespace floor STILL fires (gating, not removal)"
else
  fail_test "case (b) present-but-zero-token namespace floor did not fire (rc=$_HZ_RC): $_HZ_OUT"
fi
_rebuild_fixture

# Case (c) — rules-only registry (no units: rows): the whole coverage
# cross-check is inactive (units-gated), so neither the reverse sweep nor any
# floor runs. "coverage cross-check inactive", exit 0 — unchanged behavior.
_RO2=$(mk_tmp)
mkdir -p "$_RO2/spec"
bash "$HELPER" --seed > "$_RO2/spec/test-spec.md" 2>/dev/null
_RO2_OUT=$(REPO_ROOT="$_RO2" TEST_SPEC_PATH="$_RO2/spec/test-spec.md" bash "$HELPER" --check-coverage 2>&1); _RO2_RC=$?
if [ "$_RO2_RC" -eq 0 ] \
   && printf '%s' "$_RO2_OUT" | grep -qF 'coverage cross-check inactive' \
   && ! printf '%s' "$_RO2_OUT" | grep -qF 'FINDING: floor'; then
  ok "case (c): rules-only registry -> coverage cross-check inactive, exit 0, no floor findings (unchanged)"
else
  fail_test "case (c) rules-only registry mis-handled (rc=$_RO2_RC): $_RO2_OUT"
fi

# Case (d) — reserved-path collision (D000035 strengthening). A non-workbench
# consumer declares ONLY a ci-family unit (a workflow) but ALSO happens to have a
# file at a reserved shell-surface path in a DIFFERENT grammar: a husky-style
# scripts/setup-hooks.sh (no `if install_hook` lines) and its own scripts/validate.sh
# (no `=== Check N:` banners). Path-existence ALONE would false-fire the 'validate'
# and 'hooks' zero-token floors; gating each floor on "path present AND the registry
# declares rows in that namespace's family" closes that residual. Expect: exit 0,
# "OK coverage", NO floor findings (the consumer declares no validate/hook rows).
_COL=$(mk_tmp)
mkdir -p "$_COL/spec" "$_COL/scripts" "$_COL/.github/workflows"
bash "$HELPER" --seed > "$_COL/spec/test-spec.md" 2>/dev/null
cat > "$_COL/.github/workflows/ci.yml" <<'COL_WF'
name: Consumer CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test
COL_WF
# A husky-style installer at the reserved hooks path — NO `if install_hook` lines.
cat > "$_COL/scripts/setup-hooks.sh" <<'COL_HK'
#!/usr/bin/env bash
# Consumer's own hook installer (husky-style) — not the workbench grammar.
npx husky install
COL_HK
# The consumer's own preflight at the reserved validate path — NO `=== Check N:` banners.
cat > "$_COL/scripts/validate.sh" <<'COL_VAL'
#!/usr/bin/env bash
# Consumer's own preflight — not the workbench check-banner grammar.
npm run lint && npm run typecheck
COL_VAL
cat > "$_COL/spec/test-spec-custom.md" <<'COL_OVL'
# test-spec-custom.md — consumer overlay (ci-family only)

```yaml
schema_version: 1
units:
  - id: consumer-ci-workflow
    family: ci
    label: "Consumer CI workflow — the PR gate"
    anchor: "name: Consumer CI"
    source: .github/workflows/ci.yml
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The consumer's GitHub Actions workflow runs the suite on every PR."
```
COL_OVL
_COL_OUT=$(REPO_ROOT="$_COL" TEST_SPEC_PATH="$_COL/spec/test-spec.md" TEST_SPEC_CUSTOM_PATH="$_COL/spec/test-spec-custom.md" bash "$HELPER" --check-coverage 2>&1); _COL_RC=$?
if [ "$_COL_RC" -eq 0 ] \
   && printf '%s' "$_COL_OUT" | grep -qF 'OK coverage' \
   && ! printf '%s' "$_COL_OUT" | grep -qF 'FINDING: floor'; then
  ok "case (d): reserved-path file in a non-workbench grammar (no rows in that family) -> NO floor false-fire (family-row gating)"
else
  fail_test "case (d) reserved-path collision false-fired a floor (rc=$_COL_RC): $_COL_OUT"
fi

# 9. the behavior-coverage axis (F000066): parser round-trip + the 6
# deterministic checks (positive + negatives), temp-dir isolated. Checks 1-2
# (schema/enum/id-unique) live in the shared registry gate; Checks 3-6
# (link/family/anchor/>=1-cover) live in _run_coverage gated on behaviors:.
echo
echo "=== behavior-coverage axis (F000066) ==="

# 9.0 — live dogfood: the workbench overlay declares behaviors that resolve.
_LB=$(bash "$HELPER" --list-behaviors 2>/dev/null)
_NLB=$(printf '%s\n' "$_LB" | grep -c . || true)
if [ "${_NLB:-0}" -ge 8 ] \
   && printf '%s\n' "$_LB" | grep -qx 'seed-byte-identical' \
   && printf '%s\n' "$_LB" | grep -qx 'reverse-floor-prevents-vacuous-pass'; then
  ok "--list-behaviors enumerates the $_NLB dogfood behaviors (>= 8)"
else
  fail_test "--list-behaviors wrong (n=$_NLB; got: $(printf '%s' "$_LB" | tr '\n' ' '))"
fi
_LBC=$(bash "$HELPER" --list-behavior-coverage 2>/dev/null)
if [ "$(printf '%s\n' "$_LBC" | grep -c . || true)" -eq "$_NLB" ]; then
  ok "--list-behavior-coverage enumerates one cover per dogfood behavior"
else
  fail_test "--list-behavior-coverage wrong ($(printf '%s' "$_LBC" | tr '\n' ' '))"
fi
# The live dogfood is coverage-clean (no behavior findings on the real tree).
_BLIVE=$(bash "$HELPER" --check-coverage 2>&1)
if printf '%s' "$_BLIVE" | grep -qF 'findings=0' \
   && ! printf '%s' "$_BLIVE" | grep -qF 'FINDING: behavior-coverage'; then
  ok "live dogfood behaviors resolve to real anchored test-bearing covers (no behavior findings)"
else
  fail_test "live dogfood behaviors have findings: $_BLIVE"
fi

# 9.1 — a hermetic behavior fixture: one test unit + one behavior with a good
# cover. The test file carries the live-anchor token. Units coverage is clean
# (only a test-family row + scripts/test.sh wiring; no validate/hook surfaces).
_BFX=$(mk_tmp)
mkdir -p "$_BFX/spec" "$_BFX/tests" "$_BFX/scripts"
bash "$HELPER" --seed > "$_BFX/spec/test-spec.md" 2>/dev/null
printf '#!/usr/bin/env bash\n# tests/foo.test.sh\nok "BEHAVIOR_EVIDENCE_TOKEN proves the thing"\n' > "$_BFX/tests/foo.test.sh"
printf '#!/usr/bin/env bash\nbash tests/foo.test.sh\n' > "$_BFX/scripts/test.sh"
_bfx_overlay() { cat > "$_BFX/spec/test-spec-custom.md"; }
_bfx_run() {
  REPO_ROOT="$_BFX" TEST_SPEC_PATH="$_BFX/spec/test-spec.md" \
    TEST_SPEC_CUSTOM_PATH="$_BFX/spec/test-spec-custom.md" bash "$HELPER" "$@" 2>&1
}
_BFX_UNIT='units:
  - id: test-foo
    family: test
    label: "Foo suite"
    anchor: "tests/foo.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Foo behavior."'

# 9.1a — positive: a good behavior + cover is coverage-clean.
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
$_BFX_UNIT
behaviors:
  - id: good-behavior
    statement: "Foo does the thing."
    level: unit
behavior_coverage:
  - behavior: good-behavior
    unit: test-foo
    source: tests/foo.test.sh
    anchor: "BEHAVIOR_EVIDENCE_TOKEN proves the thing"
\`\`\`
EOF
_B_POS=$(_bfx_run --check-coverage); _B_POS_RC=$?
if [ "$_B_POS_RC" -eq 0 ] && printf '%s' "$_B_POS" | grep -qF 'findings=0' \
   && ! printf '%s' "$_B_POS" | grep -qF 'FINDING: behavior-coverage'; then
  ok "behavior positive: a good behavior + anchored test-bearing cover is coverage-clean"
else
  fail_test "behavior positive not clean (rc=$_B_POS_RC): $_B_POS"
fi

# 9.1b — Check 2 negative: a bad level halts --validate with [test-spec-no-config].
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
$_BFX_UNIT
behaviors:
  - id: good-behavior
    statement: "Foo does the thing."
    level: e2e
behavior_coverage:
  - behavior: good-behavior
    unit: test-foo
    source: tests/foo.test.sh
    anchor: "BEHAVIOR_EVIDENCE_TOKEN proves the thing"
\`\`\`
EOF
_B_LVL=$(_bfx_run --validate); _B_LVL_RC=$?
if [ "$_B_LVL_RC" -ne 0 ] && printf '%s' "$_B_LVL" | grep -qF '[test-spec-no-config]' \
   && printf '%s' "$_B_LVL" | grep -qF 'level'; then
  ok "behavior Check 2: a level outside the enum halts --validate with [test-spec-no-config]"
else
  fail_test "behavior bad-level did not halt (rc=$_B_LVL_RC): $_B_LVL"
fi

# 9.1b' — Check 1 negative: a duplicate behavior id halts --validate.
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
$_BFX_UNIT
behaviors:
  - id: dup-behavior
    statement: "One."
    level: unit
  - id: dup-behavior
    statement: "Two."
    level: unit
behavior_coverage:
  - behavior: dup-behavior
    unit: test-foo
    source: tests/foo.test.sh
    anchor: "BEHAVIOR_EVIDENCE_TOKEN proves the thing"
\`\`\`
EOF
_B_DUP=$(_bfx_run --validate); _B_DUP_RC=$?
if [ "$_B_DUP_RC" -ne 0 ] && printf '%s' "$_B_DUP" | grep -qF 'duplicate behavior id'; then
  ok "behavior Check 1: a duplicate behavior id halts --validate"
else
  fail_test "behavior dup-id did not halt (rc=$_B_DUP_RC): $_B_DUP"
fi

# 9.1c — Check 3 negative: a dangling behavior ref (typo) is a finding.
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
$_BFX_UNIT
behaviors:
  - id: good-behavior
    statement: "Foo does the thing."
    level: unit
behavior_coverage:
  - behavior: good-behaviorr
    unit: test-foo
    source: tests/foo.test.sh
    anchor: "BEHAVIOR_EVIDENCE_TOKEN proves the thing"
\`\`\`
EOF
_B_DANG=$(_bfx_run --check-coverage); _B_DANG_RC=$?
if [ "$_B_DANG_RC" -ne 0 ] && printf '%s' "$_B_DANG" | grep -qF "behavior 'good-behaviorr' resolves to 0 behaviors"; then
  ok "behavior Check 3: a dangling behavior ref (typo) is a finding"
else
  fail_test "behavior dangling-ref not flagged (rc=$_B_DANG_RC): $_B_DANG"
fi

# 9.1d — Check 4 negative: a non-test-bearing (ci-family) proof unit is a finding.
mkdir -p "$_BFX/.github/workflows"
printf 'name: Drill CI\non: [push]\n' > "$_BFX/.github/workflows/ci.yml"
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
$_BFX_UNIT
  - id: ci-drill
    family: ci
    label: "Drill CI workflow"
    anchor: "name: Drill CI"
    source: .github/workflows/ci.yml
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "CI."
behaviors:
  - id: good-behavior
    statement: "Foo does the thing."
    level: unit
behavior_coverage:
  - behavior: good-behavior
    unit: ci-drill
    source: tests/foo.test.sh
    anchor: "BEHAVIOR_EVIDENCE_TOKEN proves the thing"
\`\`\`
EOF
_B_FAM=$(_bfx_run --check-coverage); _B_FAM_RC=$?
if [ "$_B_FAM_RC" -ne 0 ] && printf '%s' "$_B_FAM" | grep -qF "has family 'ci' (not test-bearing)"; then
  ok "behavior Check 4: a non-test-bearing (ci) proof unit is a finding"
else
  fail_test "behavior non-test-bearing-family not flagged (rc=$_B_FAM_RC): $_B_FAM"
fi
rm -f "$_BFX/.github/workflows/ci.yml"

# 9.1e — Check 5 negative: an anchor that does not grep live (grep -F miss).
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
$_BFX_UNIT
behaviors:
  - id: good-behavior
    statement: "Foo does the thing."
    level: unit
behavior_coverage:
  - behavior: good-behavior
    unit: test-foo
    source: tests/foo.test.sh
    anchor: "TOKEN_NOT_PRESENT_IN_THE_FILE"
\`\`\`
EOF
_B_ANC=$(_bfx_run --check-coverage); _B_ANC_RC=$?
if [ "$_B_ANC_RC" -ne 0 ] && printf '%s' "$_B_ANC" | grep -qF 'anchor not found LIVE (grep -F)'; then
  ok "behavior Check 5: an anchor that does not grep live is a finding"
else
  fail_test "behavior dead-anchor not flagged (rc=$_B_ANC_RC): $_B_ANC"
fi

# 9.1f — Check 6 negative: a behavior with zero coverage rows is a finding.
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
$_BFX_UNIT
behaviors:
  - id: good-behavior
    statement: "Foo does the thing."
    level: unit
  - id: orphan-behavior
    statement: "Nothing proves this."
    level: unit
behavior_coverage:
  - behavior: good-behavior
    unit: test-foo
    source: tests/foo.test.sh
    anchor: "BEHAVIOR_EVIDENCE_TOKEN proves the thing"
\`\`\`
EOF
_B_ORPH=$(_bfx_run --check-coverage); _B_ORPH_RC=$?
if [ "$_B_ORPH_RC" -ne 0 ] && printf '%s' "$_B_ORPH" | grep -qF "behavior 'orphan-behavior' has no behavior_coverage row"; then
  ok "behavior Check 6: a behavior with zero coverage rows is a finding"
else
  fail_test "behavior uncovered not flagged (rc=$_B_ORPH_RC): $_B_ORPH"
fi

# 9.2 — behaviors-gated inactivity: a units-only registry (no behaviors:) reports
# "behavior coverage inactive" and stays green (parity with units-gated reverse).
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
$_BFX_UNIT
\`\`\`
EOF
_B_INACT=$(_bfx_run --check-coverage); _B_INACT_RC=$?
if [ "$_B_INACT_RC" -eq 0 ] && printf '%s' "$_B_INACT" | grep -qF 'behavior coverage inactive'; then
  ok "behaviors-gated: a units-only registry reports 'behavior coverage inactive' + exit 0"
else
  fail_test "behaviors inactivity note missing on a units-only registry (rc=$_B_INACT_RC): $_B_INACT"
fi

# 9.3 — independent gate: a registry with behaviors but NO units still runs the
# behavior checks (a declared-but-uncovered behavior is the open-world gap).
_bfx_overlay <<EOF
\`\`\`yaml
schema_version: 1
behaviors:
  - id: lonely-behavior
    statement: "Proven by nothing."
    level: unit
\`\`\`
EOF
_B_INDEP=$(_bfx_run --check-coverage); _B_INDEP_RC=$?
if [ "$_B_INDEP_RC" -ne 0 ] \
   && printf '%s' "$_B_INDEP" | grep -qF 'coverage cross-check inactive' \
   && printf '%s' "$_B_INDEP" | grep -qF "behavior 'lonely-behavior' has no behavior_coverage row"; then
  ok "independent gate: behaviors with no units still run (uncovered behavior flagged despite no units)"
else
  fail_test "behavior gate not independent of units (rc=$_B_INDEP_RC): $_B_INDEP"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: test-spec"
  exit 0
else
  echo "FAIL: test-spec ($ERRORS error(s))"
  exit 1
fi
