#!/usr/bin/env bash
# tests/test-pipeline-spec.test.sh
#
# Regression test for the test-pipeline registry (spec/test-pipeline.md) + the
# scripts/test-pipeline.sh parser/renderer/coverage engine (F000059) — the
# machinery behind validate.sh Check 24 (coverage cross-check) and the Check 23
# third-view extension (docs/test-pipeline.md view-sync).
#
# Asserts:
#   1. spec/test-pipeline.md exists and carries exactly one fenced ```yaml block
#   2. scripts/test-pipeline.sh exists + is executable
#   3. --validate exits 0 + prints OK schema_version=1
#   4. --list-units enumerates >= 60 units with unique ids
#   5. --render is byte-identical across two runs, work-item-ID-free, opens
#      with the summary table BEFORE the first `## ` heading, and carries the
#      single gate-spec pointer line
#   6. malformed-registry fixtures fail closed with [test-pipeline-no-config]:
#      bad schema_version / family outside the enum / a work-item ID in a
#      rendered field / a duplicate id / a trigger token outside the enum
#   7. the drift drills (a)-(f2), temp-dir isolated (a COPY of the swept surface;
#      the live tree is never mutated):
#        (a) fake `=== Check 99` banner in the temp validate.sh -> the REVERSE
#            sweep flags it
#        (b) corrupted anchor in the temp registry -> the FORWARD check flags
#            the orphaned row, naming row + source
#        (c) hand-edited copy of the generated view -> the temp-regen+diff
#            (Check 23-extension semantics) detects it; the live validate.sh
#            carries the third-view diff + remediation literal
#        (d) removed runner block in the temp test.sh -> the FORWARD check
#            flags the orphaned test row (the silent-skip catch)
#   8. consumer-repo skip posture: in a scratch repo WITHOUT the registry +
#      parser, generate-doc-views.sh skips the third view with a one-line note
#      and writes no test-pipeline.md; the parser fails closed there (the
#      validate.sh Check 24 SKIP guard is presence-gated BEFORE the helper runs,
#      asserted via its literal SKIP line)
#
# Temp-dir isolated throughout; never mutates the live tree.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/test-pipeline.sh"
REGISTRY="$REPO_ROOT/spec/test-pipeline.md"
[ -f "$REGISTRY" ] || REGISTRY="$REPO_ROOT/test-pipeline.md"

_TMPS=""
mk_tmp() {
  _d=$(mktemp -d -t test-pipeline-spec.XXXXXX)
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

echo "=== test-pipeline registry + parser + coverage assertions ==="

# 1. registry present + exactly one fenced yaml block
if [ -f "$REGISTRY" ]; then
  ok "test-pipeline.md registry present ($REGISTRY)"
else
  fail_test "test-pipeline.md missing (looked in spec/ then root): $REGISTRY"
  echo "FAIL: test-pipeline-spec ($ERRORS error(s))"
  exit 1
fi
_FENCES=$(grep -cE '^```yaml' "$REGISTRY" || true)
if [ "${_FENCES:-0}" -eq 1 ]; then
  ok "test-pipeline.md has exactly one fenced \`\`\`yaml registry block"
else
  fail_test "test-pipeline.md should have exactly 1 \`\`\`yaml block, found $_FENCES"
fi

# 2. helper exists + executable
if [ -x "$HELPER" ]; then
  ok "scripts/test-pipeline.sh exists and is executable"
else
  fail_test "scripts/test-pipeline.sh missing or not executable"
  echo "FAIL: test-pipeline-spec ($ERRORS error(s))"
  exit 1
fi

# 3. --validate
_V_OUT=$(bash "$HELPER" --validate 2>&1); _V_RC=$?
if [ "$_V_RC" -eq 0 ] && printf '%s' "$_V_OUT" | grep -qF 'OK schema_version=1'; then
  ok "helper --validate exits 0 + prints OK schema_version=1"
else
  fail_test "helper --validate failed or wrong output: $_V_OUT"
fi

# 4. --list-units: >= 60 rows, unique ids
_UNITS=$(bash "$HELPER" --list-units 2>/dev/null)
_N=$(printf '%s\n' "$_UNITS" | grep -c . || true)
_NU=$(printf '%s\n' "$_UNITS" | sort -u | grep -c . || true)
if [ "${_N:-0}" -ge 60 ] && [ "$_N" -eq "$_NU" ]; then
  ok "helper --list-units enumerates $_N units, all ids unique"
else
  fail_test "helper --list-units wrong shape (n=$_N unique=$_NU; want >= 60 and equal)"
fi

# 5. --render: idempotent, ID-free, front-table-shaped, gate-spec pointer
_RT=$(mk_tmp)
bash "$HELPER" --render > "$_RT/r1.md" 2>/dev/null; _R1_RC=$?
[ "$_R1_RC" -eq 0 ] || fail_test "helper --render exited non-zero ($_R1_RC) — idempotency/shape asserts below would be vacuous"
bash "$HELPER" --render > "$_RT/r2.md" 2>/dev/null
if diff -q "$_RT/r1.md" "$_RT/r2.md" >/dev/null 2>&1; then
  ok "helper --render is byte-identical across two runs"
else
  fail_test "helper --render differs across two consecutive runs (non-deterministic)"
fi
if grep -qE '[FSTD][0-9]{6}' "$_RT/r1.md"; then
  fail_test "rendered view carries a work-item ID (rendered fields must be ID-free)"
else
  ok "rendered view is work-item-ID-free"
fi
# Front-table shape: a `|`-row immediately followed by a delimiter row BEFORE
# the first `## ` heading (the Check 20 awk, verbatim).
if awk '
  /^## / { exit }
  /^\|[ :|+-]*-[ :|+-]*\|$/ {
    if (prev ~ /^\|/) { found = 1; exit }
  }
  { prev = $0 }
  END { exit !found }
' "$_RT/r1.md" >/dev/null 2>&1; then
  ok "rendered view opens with the summary table before its first '## ' heading"
else
  fail_test "rendered view does not open with a summary table before the first '## ' heading"
fi
if grep -qF 'spec/gate-spec.md' "$_RT/r1.md"; then
  ok "rendered view carries the gate-spec pointer line (layer model linked, not re-explained)"
else
  fail_test "rendered view missing the spec/gate-spec.md pointer line"
fi

# 6. malformed-registry fixtures fail closed (TEST_PIPELINE_PATH override; the
# fixture file lives in a temp dir — the live registry is never touched).
_MF=$(mk_tmp)
_mk_fixture() {
  # $1 = filename, then body on stdin
  cat > "$_MF/$1"
}
_assert_halts() {
  # $1 = fixture file, $2 = description, $3 = required output substring (optional)
  _H_OUT=$(TEST_PIPELINE_PATH="$_MF/$1" bash "$HELPER" --validate 2>&1); _H_RC=$?
  if [ "$_H_RC" -ne 0 ] && printf '%s' "$_H_OUT" | grep -qF '[test-pipeline-no-config]'; then
    if [ -n "${3:-}" ] && ! printf '%s' "$_H_OUT" | grep -qF "$3"; then
      fail_test "malformed fixture ($2) halted but without the expected reason '$3': $_H_OUT"
    else
      ok "malformed fixture ($2) fails closed with [test-pipeline-no-config]"
    fi
  else
    fail_test "malformed fixture ($2) did not halt (rc=$_H_RC out=$_H_OUT)"
  fi
}

_mk_fixture bad-schema.md <<'EOF'
```yaml
schema_version: 9
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
_assert_halts bad-schema.md "bad schema_version" "unsupported"

_mk_fixture bad-family.md <<'EOF'
```yaml
schema_version: 1
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
```
EOF
_assert_halts bad-family.md "family outside the enum" "outside the closed enum"

_mk_fixture id-in-label.md <<'EOF'
```yaml
schema_version: 1
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
```
EOF
_assert_halts id-in-label.md "work-item ID in a rendered field" "rendered field"

_mk_fixture dup-id.md <<'EOF'
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
  - id: u-one
    family: validate
    label: "Another unit"
    anchor: "anchor-2"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Another purpose."
```
EOF
_assert_halts dup-id.md "duplicate id" "duplicate unit id"

_mk_fixture bad-trigger.md <<'EOF'
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
    trigger: "pr-ci sometimes"
    purpose: "A purpose."
```
EOF
_assert_halts bad-trigger.md "trigger token outside the enum" "trigger token"

_mk_fixture bad-test-source.md <<'EOF'
```yaml
schema_version: 1
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
```
EOF
_assert_halts bad-test-source.md "test row pointing source at the test file itself (silent-skip disarm)" "MUST declare source: scripts/test.sh"

# 7. The drift drills (a)-(f2) — against a temp COPY of the swept surface.
# The fixture tree carries: the registry, the three anchored script sources,
# the workflows, and name-only placeholders for every tests/*.test.sh on disk
# (the reverse sweep enumerates file NAMES; the forward check greps the runner
# paths inside the copied scripts/test.sh).
_FIX=$(mk_tmp)
mkdir -p "$_FIX/scripts" "$_FIX/tests" "$_FIX/.github/workflows" "$_FIX/spec"
_rebuild_fixture() {
  cp "$REPO_ROOT/scripts/validate.sh" "$_FIX/scripts/validate.sh"
  cp "$REPO_ROOT/scripts/test.sh" "$_FIX/scripts/test.sh"
  cp "$REPO_ROOT/scripts/setup-hooks.sh" "$_FIX/scripts/setup-hooks.sh"
  cp "$REPO_ROOT"/.github/workflows/*.yml "$_FIX/.github/workflows/"
  rm -f "$_FIX/tests"/*.test.sh
  for _tf in "$REPO_ROOT"/tests/*.test.sh; do
    [ -e "$_tf" ] || continue
    : > "$_FIX/tests/$(basename "$_tf")"
  done
  cp "$REGISTRY" "$_FIX/spec/test-pipeline.md"
}
_rebuild_fixture

# Baseline: the fixture copy of the live surface is coverage-clean.
_B_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _B_RC=$?
if [ "$_B_RC" -eq 0 ] && printf '%s' "$_B_OUT" | grep -qF 'findings=0'; then
  ok "drill baseline: fixture copy of the live surface is coverage-clean"
else
  fail_test "drill baseline not clean (rc=$_B_RC): $_B_OUT"
fi

# Drill (a) — REVERSE: a new check lands without a registry row. Append a fake
# banner to the temp validate.sh (after its final exit — content only matters
# to the grep-based sweep).
printf '\necho "=== Check 99: fake coverage drill ==="\n' >> "$_FIX/scripts/validate.sh"
_A_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _A_RC=$?
if [ "$_A_RC" -ne 0 ] && printf '%s' "$_A_OUT" | grep -qF "Check 99" \
   && printf '%s' "$_A_OUT" | grep -qF 'reverse'; then
  ok "drill (a): fake banner in the temp validate.sh -> reverse sweep flags 'Check 99'"
else
  fail_test "drill (a) did not flag the fake banner (rc=$_A_RC): $_A_OUT"
fi
_rebuild_fixture

# Drill (b) — FORWARD: a registry anchor rots. Corrupt one row's anchor in the
# temp registry copy and point the engine at it via TEST_PIPELINE_PATH.
sed 's/anchor: "# Error check 1:"/anchor: "# Error check 991:"/' \
  "$_FIX/spec/test-pipeline.md" > "$_FIX/spec/test-pipeline.corrupt.md"
_B2_OUT=$(REPO_ROOT="$_FIX" TEST_PIPELINE_PATH="$_FIX/spec/test-pipeline.corrupt.md" bash "$HELPER" --check-coverage 2>&1); _B2_RC=$?
if [ "$_B2_RC" -ne 0 ] && printf '%s' "$_B2_OUT" | grep -qF "validate-error-check-1" \
   && printf '%s' "$_B2_OUT" | grep -qF 'scripts/validate.sh'; then
  ok "drill (b): corrupted anchor -> forward check names the row + its source"
else
  fail_test "drill (b) did not flag the corrupted anchor (rc=$_B2_RC): $_B2_OUT"
fi
rm -f "$_FIX/spec/test-pipeline.corrupt.md"

# Drill (c) — VIEW-SYNC (Check 23-extension semantics): a human hand-edits the
# generated view. The extension's mechanism is regenerate-into-temp + diff; a
# hand-edited copy must differ from a fresh render. Plus: the live validate.sh
# must actually wire the third-view diff with its remediation message.
bash "$HELPER" --render > "$_RT/view-fresh.md" 2>/dev/null
cp "$_RT/view-fresh.md" "$_RT/view-edited.md"
printf '\nA hand-written line that never came from the generator.\n' >> "$_RT/view-edited.md"
if ! diff -q "$_RT/view-fresh.md" "$_RT/view-edited.md" >/dev/null 2>&1; then
  ok "drill (c): hand-edited view differs from a fresh render (the temp-regen+diff catches it)"
else
  fail_test "drill (c): hand-edited view did not differ from a fresh render"
fi
if grep -qF 'docs/test-pipeline.md drifted from the test-pipeline registry — run scripts/generate-doc-views.sh' "$REPO_ROOT/scripts/validate.sh"; then
  ok "drill (c): validate.sh wires the third-view diff with the generate-doc-views remediation"
else
  fail_test "drill (c): validate.sh missing the third-view drift ERROR + remediation literal"
fi

# Drill (d) — FORWARD, the silent-skip catch: a runner block is removed from
# the temp test.sh while the test file stays on disk. The orphaned row's
# runner-path anchor no longer greps.
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

# Drill (e) — HOOK-ENV regression: inside a git hook, git exports GIT_DIR (+
# GIT_INDEX_FILE), under which a `git -C <dir>` --show-toplevel resolves the
# work tree to <dir> itself. generate-doc-views.sh once resolved REPO_ROOT that
# way, silently skipped the third view, and Check 23 diffed a never-written
# file — blocking every commit from the pre-commit hook while a direct
# validate.sh run passed. Pin: under hook env, the generator MUST still write
# the third view, byte-identical to a clean-env render.
_HE=$(mk_tmp); _HE2=$(mk_tmp)
bash "$REPO_ROOT/scripts/generate-doc-views.sh" --output-dir "$_HE2" >/dev/null 2>&1
( cd "$REPO_ROOT" \
  && GIT_DIR="$(git rev-parse --git-dir)" GIT_INDEX_FILE="$(git rev-parse --git-path index)" \
     bash scripts/generate-doc-views.sh --output-dir "$_HE" >/dev/null 2>&1 )
if [ -f "$_HE/test-pipeline.md" ] && diff -q "$_HE/test-pipeline.md" "$_HE2/test-pipeline.md" >/dev/null 2>&1; then
  ok "drill (e): hook env (GIT_DIR set) still renders the third view, identical to clean-env"
else
  fail_test "drill (e): hook env broke the third view (exists=$([ -f "$_HE/test-pipeline.md" ] && echo yes || echo no))"
fi

# Drill (f) — REVERSE, the silent-skip catch's OTHER half: a brand-new
# tests/*.test.sh appears on disk with NO registry row at all (drill (d) covers
# the row-exists-but-runner-block-removed half). The reverse sweep enumerates
# test files by name, so the orphan must surface as a finding naming the file.
: > "$_FIX/tests/zz-unregistered-drill.test.sh"
_F_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _F_RC=$?
if [ "$_F_RC" -ne 0 ] && printf '%s' "$_F_OUT" | grep -qF "zz-unregistered-drill.test.sh" \
   && printf '%s' "$_F_OUT" | grep -qF 'reverse'; then
  ok "drill (f): unregistered test file on disk -> reverse sweep flags it (no registry row)"
else
  fail_test "drill (f) did not flag the unregistered test file (rc=$_F_RC): $_F_OUT"
fi
_rebuild_fixture

# Drill (f2) — REVERSE, the source-pin bypass (red-team find): an unwired test
# file ships WITH a registry row, but the row points source at the test file
# itself. The file names itself in its header, so the FORWARD grep
# self-satisfies — only the reverse sweep's source pin (source must be
# scripts/test.sh) catches that the suite never runs it.
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
' "$_FIX/spec/test-pipeline.md" > "$_FIX/spec/test-pipeline.md.new" \
  && mv "$_FIX/spec/test-pipeline.md.new" "$_FIX/spec/test-pipeline.md"
_F2_OUT=$(REPO_ROOT="$_FIX" bash "$HELPER" --check-coverage 2>&1); _F2_RC=$?
if [ "$_F2_RC" -ne 0 ] && printf '%s' "$_F2_OUT" | grep -qF "zz-selfref.test.sh" \
   && printf '%s' "$_F2_OUT" | grep -qF 'source: scripts/test.sh'; then
  ok "drill (f2): self-satisfying source row -> reverse source-pin flags the unwired test"
else
  fail_test "drill (f2) did not flag the self-referencing row (rc=$_F2_RC): $_F2_OUT"
fi
_rebuild_fixture

# 8. Consumer-repo skip posture: a scratch repo WITHOUT the registry + parser.
_CR=$(mk_tmp)
git -C "$_CR" init -q 2>/dev/null || true
mkdir -p "$_CR/scripts" "$_CR/docs"
cp "$REPO_ROOT/scripts/generate-doc-views.sh" "$_CR/scripts/"
cp "$REPO_ROOT/scripts/doc-spec.sh" "$_CR/scripts/"
( cd "$_CR" && REPO_ROOT="$_CR" bash scripts/doc-spec.sh --seed > doc-spec.md 2>/dev/null )
_G_OUT=$( cd "$_CR" && bash scripts/generate-doc-views.sh --output-dir "$_CR/docs" 2>&1 ); _G_RC=$?
if [ "$_G_RC" -eq 0 ] \
   && printf '%s' "$_G_OUT" | grep -qF 'skipping test-pipeline.md view' \
   && [ ! -f "$_CR/docs/test-pipeline.md" ] \
   && [ -f "$_CR/docs/doc-general.md" ]; then
  ok "consumer skip: generator skips the third view with a note, writes no test-pipeline.md, two views still written"
else
  fail_test "consumer skip broken (rc=$_G_RC; tp_exists=$([ -f "$_CR/docs/test-pipeline.md" ] && echo yes || echo no)): $_G_OUT"
fi
# The parser fails closed where the registry is absent; validate.sh's Check 24
# therefore gates on registry presence BEFORE calling it (literal SKIP line).
if ( cd "$_CR" && bash "$HELPER" --validate >/dev/null 2>&1 ); then
  fail_test "consumer skip: parser did not fail closed in a registry-less repo"
else
  ok "consumer skip: parser fails closed in a registry-less repo (validate.sh SKIPs before calling it)"
fi
if grep -qF 'SKIP: test-pipeline.md registry not present' "$REPO_ROOT/scripts/validate.sh"; then
  ok "consumer skip: validate.sh Check 24 carries the registry-absent SKIP branch"
else
  fail_test "consumer skip: validate.sh Check 24 missing the registry-absent SKIP literal"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: test-pipeline-spec"
  exit 0
else
  echo "FAIL: test-pipeline-spec ($ERRORS error(s))"
  exit 1
fi
