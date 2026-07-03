#!/usr/bin/env bash
# tests/test-run.test.sh — fixture-repo unit tests for scripts/test-run.sh and
# the runners: axis of scripts/test-spec.sh (F000072 / S000122).
#
# CRITICAL: every drill runs against a TEMP-DIR fixture registry (via the
# REPO_ROOT / TEST_SPEC_PATH / TEST_SPEC_CUSTOM_PATH env overrides). It NEVER
# invokes the real scripts/test.sh — the workbench's `run-test-sh` runner IS
# `bash scripts/test.sh`, so executing it from inside this suite (which test.sh
# itself runs) is a recursion/runtime trap. Fixture runners are trivial shell
# (`true`, `false`, `printf ...`) with no side effects.
#
# Coverage:
#   G1  --validate accepts a well-formed runners: axis; an axis-less registry unchanged
#   G2  --validate rejects each named violation (dup id, bad tier/platform, empty
#       command, unknown covers family, explicit ci/hook in covers)
#   G3  --list-runners emits the parsed rows; --list-units --with-family emits id+family
#   R1  --dry-run plan output (per-runner decision, uncovered-family + ci/hook lines)
#   R2  tier gating (free default; --evals/--e2e/--all widen; unselected = tier-not-selected)
#   R3  platform guard (a platform-mismatched runner is skipped(platform))
#   R4  rc -> outcome mapping + aggregate fail + exit 1 + verbatim FAIL lines + ledger fail
#   R5  aggregate pass (>=1 green, none failed) + exit 0
#   R6  aggregate all-skipped (zero executed) + exit 0 + NEVER rendered pass
#   R7  self-gate: rc=0 + FIRST line ^SKIP: => skipped(self-gated); mid-output SKIP does not
#   R8  ledger fields: schema 1, timestamp, HEAD sha, repo root, flags, aggregate, per-runner rows
#   R9  registry edges: absent => REGISTRY=absent exit 0; invalid => passthrough exit 1;
#       zero-runners => "SKIP: no runners declared" exit 0 with NO report/ledger
#   R10 covers: all expands to every runnable family

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT_REAL=$(cd "$SCRIPT_DIR/.." && pwd)
TEST_SPEC_SH="$REPO_ROOT_REAL/scripts/test-spec.sh"
TEST_RUN_SH="$REPO_ROOT_REAL/scripts/test-run.sh"

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

for f in "$TEST_SPEC_SH" "$TEST_RUN_SH"; do
  [ -f "$f" ] || { echo "FATAL: missing $f"; exit 1; }
done

command -v jq >/dev/null 2>&1 || { echo "FATAL: jq required for ledger assertions"; exit 1; }

# ---- Fixture helpers ---------------------------------------------------------
# Build a fixture repo with a seeded general test-spec.md + a supplied overlay.
# Echoes the fixture root. Caller passes the overlay yaml body on stdin.
_mk_fixture() {
  _fx=$(mktemp -d -t cj-test-run.XXXXXX)
  mkdir -p "$_fx/spec"
  bash "$TEST_SPEC_SH" --seed > "$_fx/spec/test-spec.md"
  cat > "$_fx/spec/test-spec-custom.md"
  ( cd "$_fx" && git init -q && git config user.email t@t && git config user.name t \
      && git add -A >/dev/null 2>&1 && git commit -qm init >/dev/null 2>&1 )
  echo "$_fx"
}

# Run test-spec.sh against a fixture. Args after the fixture root are the subcommand.
_ts() { local fx="$1"; shift; REPO_ROOT="$fx" TEST_SPEC_PATH="$fx/spec/test-spec.md" bash "$TEST_SPEC_SH" "$@"; }
# Run test-run.sh against a fixture (fixed timestamp so paths are predictable).
_tr() { local fx="$1"; shift; REPO_ROOT="$fx" TEST_SPEC_PATH="$fx/spec/test-spec.md" TEST_RUN_TS="20260101T000000Z" bash "$TEST_RUN_SH" "$@"; }

# =============================================================================
echo "== G1: --validate accepts a well-formed runners: axis =="
FX=$(_mk_fixture <<'EOF'
# overlay
```yaml
schema_version: 1
runners:
  - id: r-free
    command: "true"
    tier: free
    covers: [test]
  - id: r-paid
    command: "true"
    tier: paid
    covers: [eval]
    platform: any
    note: "a paid runner"
```
EOF
)
if _ts "$FX" --validate 2>&1 | grep -q '^OK schema_version=1$'; then
  ok "well-formed runners: axis validates"
else
  fail_test "well-formed runners: axis should validate"
fi
# Axis-less registry still validates (registry-gated — no behavior change).
FX2=$(_mk_fixture <<'EOF'
# overlay
```yaml
schema_version: 1
units:
  - id: some-test
    family: test
    label: "a test"
    anchor: "tests/foo.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "a purpose."
```
EOF
)
if _ts "$FX2" --validate 2>&1 | grep -q '^OK schema_version=1$'; then
  ok "axis-less registry validates unchanged"
else
  fail_test "axis-less registry should validate unchanged"
fi
rm -rf "$FX" "$FX2"

# =============================================================================
echo "== G2: --validate rejects each named violation =="
_reject() {
  # $1 = label, $2 = expected substring in halt, stdin = overlay yaml.
  # Builds the fixture inline (reading stdin ONCE — do NOT delegate to
  # _mk_fixture, which also consumes stdin).
  local label="$1" expect="$2"
  local fx; fx=$(mktemp -d -t cj-test-run-rej.XXXXXX)
  mkdir -p "$fx/spec"
  bash "$TEST_SPEC_SH" --seed > "$fx/spec/test-spec.md"
  cat > "$fx/spec/test-spec-custom.md"
  ( cd "$fx" && git init -q && git config user.email t@t && git config user.name t \
      && git add -A >/dev/null 2>&1 && git commit -qm init >/dev/null 2>&1 )
  local out rc
  out=$(REPO_ROOT="$fx" TEST_SPEC_PATH="$fx/spec/test-spec.md" bash "$TEST_SPEC_SH" --validate 2>&1); rc=$?
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -qF "$expect"; then
    ok "$label rejected ($expect)"
  else
    fail_test "$label should be rejected with '$expect' (rc=$rc, out: $out)"
  fi
  rm -rf "$fx"
}
_reject "duplicate id" "duplicate runner id(s)" <<'EOF'
```yaml
schema_version: 1
runners:
  - id: dup
    command: "true"
    tier: free
    covers: [test]
  - id: dup
    command: "false"
    tier: free
    covers: [validate]
```
EOF
_reject "bad tier" "outside the closed enum {free, paid, local-only}" <<'EOF'
```yaml
schema_version: 1
runners:
  - id: bt
    command: "true"
    tier: cheap
    covers: [test]
```
EOF
_reject "bad platform" "outside the closed enum {any, windows, posix}" <<'EOF'
```yaml
schema_version: 1
runners:
  - id: bp
    command: "true"
    tier: free
    covers: [test]
    platform: bsd
```
EOF
_reject "empty command" "is missing 'command'" <<'EOF'
```yaml
schema_version: 1
runners:
  - id: nc
    tier: free
    covers: [test]
```
EOF
_reject "unknown covers family" "covers unknown family" <<'EOF'
```yaml
schema_version: 1
runners:
  - id: uf
    command: "true"
    tier: free
    covers: [nope]
```
EOF
_reject "ci in covers" "ci/hook are runner-less-by-design" <<'EOF'
```yaml
schema_version: 1
runners:
  - id: bc
    command: "true"
    tier: free
    covers: [ci]
```
EOF
_reject "hook in covers" "ci/hook are runner-less-by-design" <<'EOF'
```yaml
schema_version: 1
runners:
  - id: bh
    command: "true"
    tier: free
    covers: [hook]
```
EOF

# =============================================================================
echo "== G3: --list-runners + --list-units --with-family =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
units:
  - id: u1
    family: test
    label: "u1"
    anchor: "tests/u1.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "u1 purpose."
runners:
  - id: r1
    command: "true"
    tier: free
    covers: [test]
```
EOF
)
if _ts "$FX" --list-runners 2>/dev/null | grep -qE '^r1	true	free	test'; then
  ok "--list-runners emits parsed tab-separated rows"
else
  fail_test "--list-runners should emit r1 row (got: $(_ts "$FX" --list-runners 2>/dev/null))"
fi
if _ts "$FX" --list-units --with-family 2>/dev/null | grep -qE '^u1	test$'; then
  ok "--list-units --with-family emits id<TAB>family"
else
  fail_test "--list-units --with-family should emit 'u1	test'"
fi
# Bare --list-units stays ids-only (unchanged).
if [ "$(_ts "$FX" --list-units 2>/dev/null)" = "u1" ]; then
  ok "bare --list-units stays ids-only (unchanged)"
else
  fail_test "bare --list-units should be ids-only"
fi
rm -rf "$FX"

# =============================================================================
echo "== R1: --dry-run plan output =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
runners:
  - id: r-free
    command: "true"
    tier: free
    covers: [test]
  - id: r-paid
    command: "true"
    tier: paid
    covers: [eval]
```
EOF
)
DR=$(_tr "$FX" --dry-run 2>&1)
if printf '%s' "$DR" | grep -q "runner: r-free" \
   && printf '%s' "$DR" | grep -q "decision: will-run" \
   && printf '%s' "$DR" | grep -q "skip(tier-not-selected)" \
   && printf '%s' "$DR" | grep -q "ci -> ci-only (runs on GitHub)"; then
  ok "--dry-run prints per-runner decisions + ci-only line"
else
  fail_test "--dry-run plan incomplete: $DR"
fi
# uncovered family (validate not covered by any runner here) shows the reason
if printf '%s' "$DR" | grep -q "validate -> skipped(no-covering-runner)"; then
  ok "--dry-run reports an uncovered family as skipped(no-covering-runner)"
else
  fail_test "--dry-run should report validate as skipped(no-covering-runner): $DR"
fi
# --dry-run writes nothing
if [ ! -d "$FX/tests/test-run/reports" ]; then
  ok "--dry-run writes no report/ledger"
else
  fail_test "--dry-run must not write a report dir"
fi
rm -rf "$FX"

# =============================================================================
echo "== R2: tier gating =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
runners:
  - id: r-free
    command: "true"
    tier: free
    covers: [test]
  - id: r-paid
    command: "true"
    tier: paid
    covers: [eval]
  - id: r-local
    command: "true"
    tier: local-only
    covers: [validate]
```
EOF
)
# default: only free runs
_tr "$FX" >/dev/null 2>&1
L="$FX/tests/test-run/reports/20260101T000000Z.json"
if [ "$(jq -r '.runners[] | select(.id=="r-free") | .outcome' "$L")" = "pass" ] \
   && [ "$(jq -r '.runners[] | select(.id=="r-paid") | .outcome' "$L")" = "skipped:tier-not-selected" ] \
   && [ "$(jq -r '.runners[] | select(.id=="r-local") | .outcome' "$L")" = "skipped:tier-not-selected" ]; then
  ok "default selects only tier: free"
else
  fail_test "default tier gating wrong: $(jq -c '.runners[]|{id,outcome}' "$L")"
fi
# --all: all three run
_tr "$FX" --all >/dev/null 2>&1
if [ "$(jq -r '[.runners[]|select(.outcome=="pass")]|length' "$L")" = "3" ]; then
  ok "--all selects every tier"
else
  fail_test "--all should run all three: $(jq -c '.runners[]|{id,outcome}' "$L")"
fi
rm -rf "$FX"

# =============================================================================
echo "== R3: platform guard =="
# Force a host mismatch: declare platform posix on windows OR windows on posix.
HOSTP=$(case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*|Windows_NT) echo windows ;; *) echo posix ;; esac)
if [ "$HOSTP" = "windows" ]; then OTHER=posix; else OTHER=windows; fi
FX=$(_mk_fixture <<EOF
\`\`\`yaml
schema_version: 1
runners:
  - id: r-wrongplat
    command: "true"
    tier: free
    covers: [test]
    platform: $OTHER
\`\`\`
EOF
)
_tr "$FX" >/dev/null 2>&1
L="$FX/tests/test-run/reports/20260101T000000Z.json"
if [ "$(jq -r '.runners[] | select(.id=="r-wrongplat") | .outcome' "$L")" = "skipped:platform" ]; then
  ok "platform-mismatched runner is skipped(platform)"
else
  fail_test "platform guard wrong: $(jq -c '.runners[]|{id,outcome}' "$L")"
fi
rm -rf "$FX"

# =============================================================================
echo "== R4: rc->outcome fail + aggregate fail + exit 1 + verbatim FAIL + ledger =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
runners:
  - id: r-green
    command: "true"
    tier: free
    covers: [test]
  - id: r-red
    command: "echo FAIL: boom here; false"
    tier: free
    covers: [validate]
```
EOF
)
OUT=$(_tr "$FX" 2>&1); RC=$?
L="$FX/tests/test-run/reports/20260101T000000Z.json"
M="$FX/tests/test-run/reports/20260101T000000Z.md"
if [ "$RC" -eq 1 ]; then ok "aggregate fail => exit 1"; else fail_test "expected exit 1 on a failing runner (rc=$RC)"; fi
if [ "$(jq -r '.aggregate' "$L")" = "fail" ]; then ok "ledger aggregate=fail"; else fail_test "ledger aggregate should be fail"; fi
if [ "$(jq -r '.runners[]|select(.id=="r-red")|.outcome' "$L")" = "fail" ] \
   && [ "$(jq -r '.runners[]|select(.id=="r-red")|.rc' "$L")" = "1" ]; then
  ok "failing runner: outcome=fail rc=1"
else
  fail_test "failing runner ledger fields wrong"
fi
if grep -qF "FAIL: boom here" "$M"; then ok "report carries the verbatim FAIL line"; else fail_test "report should carry the verbatim FAIL line"; fi
rm -rf "$FX"

# =============================================================================
echo "== R5: aggregate pass =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
runners:
  - id: r-green
    command: "true"
    tier: free
    covers: [test]
```
EOF
)
OUT=$(_tr "$FX" 2>&1); RC=$?
L="$FX/tests/test-run/reports/20260101T000000Z.json"
if [ "$RC" -eq 0 ] && [ "$(jq -r '.aggregate' "$L")" = "pass" ]; then
  ok ">=1 green, none failed => pass + exit 0"
else
  fail_test "expected aggregate pass + exit 0 (rc=$RC, agg=$(jq -r '.aggregate' "$L"))"
fi
rm -rf "$FX"

# =============================================================================
echo "== R6: aggregate all-skipped (never pass) =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
runners:
  - id: r-paid
    command: "true"
    tier: paid
    covers: [eval]
```
EOF
)
OUT=$(_tr "$FX" 2>&1); RC=$?
L="$FX/tests/test-run/reports/20260101T000000Z.json"
if [ "$RC" -eq 0 ] && [ "$(jq -r '.aggregate' "$L")" = "all-skipped" ]; then
  ok "zero executed => all-skipped + exit 0 (never pass)"
else
  fail_test "expected all-skipped + exit 0 (rc=$RC, agg=$(jq -r '.aggregate' "$L"))"
fi
rm -rf "$FX"

# =============================================================================
echo "== R7: self-gate (first-line ^SKIP:) vs mid-output SKIP =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
runners:
  - id: r-selfgate
    command: "printf 'SKIP: not applicable\nmore\n'"
    tier: free
    covers: [test]
  - id: r-midskip
    command: "printf 'begin\nSKIP: this is mid\nend\n'"
    tier: free
    covers: [validate]
```
EOF
)
_tr "$FX" >/dev/null 2>&1
L="$FX/tests/test-run/reports/20260101T000000Z.json"
if [ "$(jq -r '.runners[]|select(.id=="r-selfgate")|.outcome' "$L")" = "skipped:self-gated" ]; then
  ok "rc=0 + FIRST line ^SKIP: => skipped(self-gated)"
else
  fail_test "self-gate not detected: $(jq -c '.runners[]|{id,outcome}' "$L")"
fi
if [ "$(jq -r '.runners[]|select(.id=="r-midskip")|.outcome' "$L")" = "pass" ]; then
  ok "mid-output SKIP does NOT trigger self-gate (outcome=pass)"
else
  fail_test "mid-output SKIP wrongly self-gated"
fi
rm -rf "$FX"

# =============================================================================
echo "== R8: ledger fields (schema 1, timestamp, head, repo root, flags, aggregate) =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
runners:
  - id: r-green
    command: "true"
    tier: free
    covers: [test]
```
EOF
)
_tr "$FX" --evals >/dev/null 2>&1
L="$FX/tests/test-run/reports/20260101T000000Z.json"
_miss=""
[ "$(jq -r '.schema' "$L")" = "1" ] || _miss="$_miss schema"
[ "$(jq -r '.timestamp' "$L")" = "20260101T000000Z" ] || _miss="$_miss timestamp"
[ -n "$(jq -r '.head_sha' "$L")" ] || _miss="$_miss head_sha"
[ -n "$(jq -r '.repo_root' "$L")" ] || _miss="$_miss repo_root"
printf '%s' "$(jq -r '.flags' "$L")" | grep -q -- '--evals' || _miss="$_miss flags"
[ -n "$(jq -r '.aggregate' "$L")" ] || _miss="$_miss aggregate"
[ -n "$(jq -r '.runners[0].id' "$L")" ] || _miss="$_miss runner-id"
[ -n "$(jq -r '.families[] | select(.family=="ci")' "$L")" ] || _miss="$_miss ci-family-row"
if [ -z "$_miss" ]; then
  ok "ledger carries schema/timestamp/head/repo_root/flags/aggregate/runner/family rows"
else
  fail_test "ledger missing fields:$_miss"
fi
# ledger is valid JSON
if jq empty "$L" 2>/dev/null; then ok "ledger is valid JSON"; else fail_test "ledger is not valid JSON"; fi
rm -rf "$FX"

# =============================================================================
echo "== R9: registry edge paths =="
# absent
FXA=$(mktemp -d -t cj-tr-absent.XXXXXX); ( cd "$FXA" && git init -q && git config user.email t@t && git config user.name t )
OUT=$(REPO_ROOT="$FXA" TEST_SPEC_PATH="$FXA/spec/test-spec.md" bash "$TEST_RUN_SH" 2>&1); RC=$?
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q '^REGISTRY=absent$'; then
  ok "absent registry => REGISTRY=absent + exit 0"
else
  fail_test "absent path wrong (rc=$RC, out: $OUT)"
fi
rm -rf "$FXA"
# invalid
FXI=$(mktemp -d -t cj-tr-invalid.XXXXXX); mkdir -p "$FXI/spec"; printf 'no yaml here\n' > "$FXI/spec/test-spec.md"
( cd "$FXI" && git init -q && git config user.email t@t && git config user.name t )
OUT=$(REPO_ROOT="$FXI" TEST_SPEC_PATH="$FXI/spec/test-spec.md" bash "$TEST_RUN_SH" 2>&1); RC=$?
if [ "$RC" -eq 1 ] && printf '%s' "$OUT" | grep -q '^\[test-spec-no-config\]'; then
  ok "invalid registry => [test-spec-no-config] passthrough + exit 1"
else
  fail_test "invalid path wrong (rc=$RC, out: $OUT)"
fi
rm -rf "$FXI"
# zero runners (valid, no runners: rows)
FXZ=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
units:
  - id: u1
    family: test
    label: "u1"
    anchor: "tests/u1.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "u1."
```
EOF
)
OUT=$(_tr "$FXZ" 2>&1); RC=$?
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q '^SKIP: no runners declared'; then
  ok "zero runners => SKIP: no runners declared + exit 0"
else
  fail_test "zero-runners path wrong (rc=$RC, out: $OUT)"
fi
if [ ! -d "$FXZ/tests/test-run/reports" ]; then
  ok "zero runners writes NO report/ledger"
else
  fail_test "zero-runners must not write a report dir"
fi
rm -rf "$FXZ"

# =============================================================================
echo "== R10: covers: all expands to every runnable family =="
FX=$(_mk_fixture <<'EOF'
```yaml
schema_version: 1
runners:
  - id: r-all
    command: "true"
    tier: free
    covers: all
```
EOF
)
_tr "$FX" >/dev/null 2>&1
L="$FX/tests/test-run/reports/20260101T000000Z.json"
CF=$(jq -r '.runners[]|select(.id=="r-all")|.covered_families' "$L")
if printf '%s' "$CF" | grep -q "validate" && printf '%s' "$CF" | grep -q "windows-smoke" && printf '%s' "$CF" | grep -q "test-deploy"; then
  ok "covers: all expands to every runnable family ($CF)"
else
  fail_test "covers: all should expand to all runnable families (got: $CF)"
fi
rm -rf "$FX"

# =============================================================================
# S5 (F000074): category-mode selection — --category / single-name, cost tiers,
# --dry-run, and additivity (the runners flow is unchanged when neither is used).
echo "== S5: category-mode selection (--category / single name / --dry-run) =="
FXC=$(_mk_fixture <<'EOF'
# overlay
```yaml
schema_version: 1
runners:
  - id: r-free
    command: "true"
    tier: free
    covers: [test]
categories:
  - name: wf-a
    category: workflow
    command: "true"
    tier: paid
    doc: "docs/tests/workflow/wf-a.md"
    purpose: "a paid workflow test"
  - name: ci-a
    category: CI
    command: "true"
    tier: free
    doc: "docs/tests/CI/ci-a.md"
    purpose: "a free CI test"
  - name: ci-b
    category: CI
    command: "echo FAIL: ci-b boom; false"
    tier: free
    doc: "docs/tests/CI/ci-b.md"
    purpose: "a free CI test that fails"
```
EOF
)

# --category CI --dry-run: plans BOTH CI tests as will-run (free tier), runs nothing.
_DRY=$(_tr "$FXC" --category CI --dry-run 2>&1); _DRY_RC=$?
if [ "$_DRY_RC" -eq 0 ] \
   && printf '%s\n' "$_DRY" | grep -qF 'test: ci-a (CI)' \
   && printf '%s\n' "$_DRY" | grep -qF 'decision: will-run' \
   && printf '%s\n' "$_DRY" | grep -qF 'no test executed, no report or ledger'; then
  ok "S5: --category CI --dry-run plans the CI tests as will-run; executes nothing"
else
  fail_test "S5: --category CI --dry-run wrong (rc=$_DRY_RC): $_DRY"
fi

# --category workflow --dry-run on a DEFAULT (free) run: the paid workflow test is
# skip(tier-not-selected) — no surprise paid spend.
_DRYW=$(_tr "$FXC" --category workflow --dry-run 2>&1)
if printf '%s\n' "$_DRYW" | grep -qF 'test: wf-a (workflow)' \
   && printf '%s\n' "$_DRYW" | grep -qF 'skip(tier-not-selected)'; then
  ok "S5: a paid category test is skip(tier-not-selected) on a default (free) run — no surprise model spend"
else
  fail_test "S5: paid workflow test not tier-gated on a default run: $_DRYW"
fi

# Single-name execute: run just ci-a (free, passes) -> aggregate pass + a
# mode:category ledger with exactly one test object.
_ONE=$(_tr "$FXC" ci-a 2>&1); _ONE_RC=$?
_ONE_LEDGER="$FXC/tests/test-run/reports/20260101T000000Z.json"
if [ "$_ONE_RC" -eq 0 ] && [ -f "$_ONE_LEDGER" ] \
   && [ "$(jq -r '.mode' "$_ONE_LEDGER")" = "category" ] \
   && [ "$(jq -r '.aggregate' "$_ONE_LEDGER")" = "pass" ] \
   && [ "$(jq -r '.tests | length' "$_ONE_LEDGER")" = "1" ] \
   && [ "$(jq -r '.tests[0].name' "$_ONE_LEDGER")" = "ci-a" ]; then
  ok "S5: single-name run selects + runs exactly that test; writes a mode:category ledger; aggregate pass"
else
  fail_test "S5: single-name execute wrong (rc=$_ONE_RC ledger=$_ONE_LEDGER): $_ONE"
fi
rm -f "$_ONE_LEDGER" "$FXC/tests/test-run/reports/20260101T000000Z.md"

# --category CI execute: ci-a passes, ci-b fails -> aggregate fail + exit 1.
_CIRUN=$(_tr "$FXC" --category CI 2>&1); _CIRUN_RC=$?
_CI_LEDGER="$FXC/tests/test-run/reports/20260101T000000Z.json"
if [ "$_CIRUN_RC" -eq 1 ] && [ -f "$_CI_LEDGER" ] \
   && [ "$(jq -r '.aggregate' "$_CI_LEDGER")" = "fail" ]; then
  ok "S5: --category CI execute derives aggregate fail (a real failing test) + exit 1"
else
  fail_test "S5: --category CI execute did not fail as expected (rc=$_CIRUN_RC): $_CIRUN"
fi
rm -f "$_CI_LEDGER" "$FXC/tests/test-run/reports/20260101T000000Z.md"

# Error paths: unknown name (exit 2) + mutual exclusion (exit 2).
_UNK=$(_tr "$FXC" nonesuch --dry-run 2>&1); _UNK_RC=$?
_MEX=$(_tr "$FXC" --category CI ci-a --dry-run 2>&1); _MEX_RC=$?
if [ "$_UNK_RC" -eq 2 ] && printf '%s\n' "$_UNK" | grep -qF "no category test named 'nonesuch'" \
   && [ "$_MEX_RC" -eq 2 ] && printf '%s\n' "$_MEX" | grep -qF 'mutually exclusive'; then
  ok "S5: unknown name + --category-with-name are named exit-2 errors"
else
  fail_test "S5: error paths wrong (unk rc=$_UNK_RC mex rc=$_MEX_RC): $_UNK | $_MEX"
fi

# Additivity: with NO --category and NO name, the runners flow runs unchanged
# (the free runner executes; a runners-shaped ledger, NOT mode:category).
_RUNFLOW=$(_tr "$FXC" 2>&1); _RUNFLOW_RC=$?
_RF_LEDGER="$FXC/tests/test-run/reports/20260101T000000Z.json"
if [ "$_RUNFLOW_RC" -eq 0 ] && [ -f "$_RF_LEDGER" ] \
   && [ "$(jq -r '.mode // "runners"' "$_RF_LEDGER")" = "runners" ] \
   && [ "$(jq -r '.runners | length' "$_RF_LEDGER")" -ge 1 ]; then
  ok "S5 additivity: no --category/name => the runners flow runs unchanged (runners-shaped ledger)"
else
  fail_test "S5 additivity: runners flow perturbed by the category axis (rc=$_RUNFLOW_RC): $_RUNFLOW"
fi
rm -rf "$FXC"

# Category-mode inactive: a repo with runners but NO categories: axis reports the
# honest note on --category (never a crash).
FXNC=$(_mk_fixture <<'EOF'
# overlay
```yaml
schema_version: 1
runners:
  - id: r-free
    command: "true"
    tier: free
    covers: [test]
```
EOF
)
_INA=$(_tr "$FXNC" --category CI 2>&1); _INA_RC=$?
if [ "$_INA_RC" -eq 0 ] && printf '%s\n' "$_INA" | grep -qF 'category contract not adopted / inactive'; then
  ok "S5: --category on a no-categories repo => 'not adopted / inactive' + exit 0"
else
  fail_test "S5: category-inactive path wrong (rc=$_INA_RC): $_INA"
fi
rm -rf "$FXNC"

# =============================================================================
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: all test-run.sh + runners-axis drills green"
  exit 0
else
  echo "FAIL: $ERRORS test-run.sh drill(s) failed" >&2
  exit 1
fi
