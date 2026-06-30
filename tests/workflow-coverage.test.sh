#!/usr/bin/env bash
# tests/workflow-coverage.test.sh
#
# Regression test for the workflow-coverage axis (F000070 / S000119): the
# forward+reverse gate (test-spec.sh --check-workflow-coverage) + the 6th
# `workflow` behaviors-TSV column + workflow-spec.sh --list-orchestrators. This
# is the machinery behind validate.sh Check 28.
#
# Asserts (all temp-dir isolated; the live tree is never mutated):
#   1. live tree: --check-workflow-coverage is GREEN from birth (orchestrators=4,
#      level:workflow behaviors=4, findings=0); --list-orchestrators emits exactly
#      the 4 CJ_goal_* names (no roster).
#   2. 6th-column parser round-trip: --validate accepts a level:workflow behavior
#      carrying a valid `workflow:` value; the `-` placeholder unwraps so a
#      non-workflow behavior with no workflow: field still validates; the `$1`-only
#      consumers (--list-behaviors) stay positional-safe.
#   3. enum-check: a `workflow:` value that is not a declared orchestrator HALTs
#      --validate; a `workflow:` field on a non-level:workflow row HALTs.
#   4. forward miss: a 5th orchestrator in the workflow registry with NO matching
#      level:workflow behavior -> a forward FINDING naming it + non-zero exit.
#   5. reverse orphan: a level:workflow behavior whose workflow: names an
#      undeclared orchestrator -> a reverse FINDING + non-zero exit.
#   6. all-declared -> clean (the positive of 4/5 in the same temp harness).
#   7. consumer-absent: no test-spec registry -> REGISTRY=absent + exit 0; a
#      workflow registry absent/non-canonical -> inactive note + exit 0.
#
# Temp-dir isolated throughout; never mutates the live tree.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
TS="$REPO_ROOT/scripts/test-spec.sh"
WS="$REPO_ROOT/scripts/workflow-spec.sh"

_TMPS=""
mk_tmp() {
  _d=$(mktemp -d -t workflow-coverage.XXXXXX)
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

echo "=== workflow-coverage axis: gate + 6th-column parser + --list-orchestrators ==="

if [ ! -x "$TS" ] || [ ! -x "$WS" ]; then
  fail_test "scripts/test-spec.sh and/or scripts/workflow-spec.sh missing or not executable"
  echo "FAIL: workflow-coverage ($ERRORS error(s))"
  exit 1
fi

# ---- helpers to build a hermetic temp repo (spec/test-spec.md +
#      spec/test-spec-custom.md + spec/workflow-spec.md) -----------------------

# Write a minimal valid general test-spec.md (== the seed) into $1/spec.
seed_general() {
  mkdir -p "$1/spec"
  bash "$TS" --seed > "$1/spec/test-spec.md"
}

# Write a test-spec-custom.md overlay with the given behaviors+coverage body.
# $1 = repo root; $2 = the yaml body (behaviors:/behavior_coverage: blocks).
write_overlay() {
  mkdir -p "$1/spec"
  {
    echo "# test-spec-custom (fixture)"
    echo ""
    echo '```yaml'
    echo "schema_version: 1"
    printf '%s\n' "$2"
    echo '```'
  } > "$1/spec/test-spec-custom.md"
}

# Emit one minimal-but-valid orchestrator section for the workflow registry.
# $1 = orchestrator name.
emit_orch_section() {
  cat <<EOF

## $1
kind: orchestrator
status: experimental (fixture)
category: fixture
source: \`skills/$1/SKILL.md\`
invoke_when: fixture
\`\`\`\`chart
$1 (fixture chart)
\`\`\`\`
\`\`\`\`summary
$1 fixture summary.
\`\`\`\`
\`\`\`\`touches-skills
- none (fixture)
\`\`\`\`
\`\`\`\`touches-steps
- none (fixture)
\`\`\`\`
\`\`\`\`touches-scripts
- none (fixture)
\`\`\`\`
\`\`\`\`touches-docs
- none (fixture)
\`\`\`\`
EOF
}

# Write a workflow-spec.md registry into $1/spec containing the named
# orchestrators (one section each). $1 = repo root; $2.. = orchestrator names.
write_workflow_registry() {
  _wr_root="$1"; shift
  mkdir -p "$_wr_root/spec"
  {
    echo "<!-- WORKFLOW-SPEC:BEGIN (fixture) -->"
    echo "# workflow-spec.md (fixture)"
    echo ""
    # The HEADER:BEGIN/END markers are load-bearing: _list_sections() ignores
    # everything until WORKFLOW-SPEC-HEADER:END, so without them no `## <name>`
    # section is ever listed (and --list-orchestrators returns empty).
    echo "<!-- WORKFLOW-SPEC-HEADER:BEGIN -->"
    echo '````header'
    echo "# Workflows (fixture index)"
    echo '````'
    echo "<!-- WORKFLOW-SPEC-HEADER:END -->"
    for _o in "$@"; do
      emit_orch_section "$_o"
    done
    echo ""
    echo "<!-- WORKFLOW-SPEC:END -->"
  } > "$_wr_root/spec/workflow-spec.md"
}

# Run --check-workflow-coverage in a hermetic temp repo. Echoes output only;
# the CALLER captures rc via `_OUT=$(run_gate_in ...); _RC=$?` (command
# substitution runs this in a subshell, so a function-set _RC would not
# propagate — the caller reads $? from the substitution instead).
run_gate_in() {
  _g_root="$1"
  REPO_ROOT="$_g_root" \
  TEST_SPEC_PATH="$_g_root/spec/test-spec.md" \
  WORKFLOW_SPEC_PATH="$_g_root/spec/workflow-spec.md" \
    bash "$TS" --check-workflow-coverage 2>&1
}

# Run --validate in a hermetic temp repo. Echoes output only; caller captures rc.
run_validate_in() {
  _v_root="$1"
  REPO_ROOT="$_v_root" \
  TEST_SPEC_PATH="$_v_root/spec/test-spec.md" \
  WORKFLOW_SPEC_PATH="$_v_root/spec/workflow-spec.md" \
    bash "$TS" --validate 2>&1
}

# ---- 1. live tree: green from birth + --list-orchestrators shape -------------

_LIVE=$(bash "$TS" --check-workflow-coverage 2>&1); _LRC=$?
if [ "$_LRC" -eq 0 ] && printf '%s\n' "$_LIVE" | grep -qE '^workflow coverage: .*findings=0$'; then
  ok "live tree: --check-workflow-coverage is green from birth (findings=0, exit 0)"
else
  fail_test "live tree gate not green (rc=$_LRC): $_LIVE"
fi

_ORCHS=$(bash "$WS" --list-orchestrators 2>/dev/null)
_NO=$(printf '%s\n' "$_ORCHS" | grep -c . || true)
if [ "$_NO" -eq 4 ] \
   && printf '%s\n' "$_ORCHS" | grep -qx 'CJ_goal_feature' \
   && printf '%s\n' "$_ORCHS" | grep -qx 'CJ_goal_task' \
   && printf '%s\n' "$_ORCHS" | grep -qx 'CJ_goal_defect' \
   && printf '%s\n' "$_ORCHS" | grep -qx 'CJ_goal_todo_fix' \
   && ! printf '%s\n' "$_ORCHS" | grep -qx 'utilities-and-phase-steps'; then
  ok "--list-orchestrators emits exactly the 4 CJ_goal_* names (no roster)"
else
  fail_test "--list-orchestrators wrong (got: $(printf '%s' "$_ORCHS" | tr '\n' ' '))"
fi

# ---- 2. 6th-column round-trip + the - unwrap --------------------------------

T2=$(mk_tmp); git -C "$T2" init -q 2>/dev/null
seed_general "$T2"
write_workflow_registry "$T2" CJ_goal_alpha
write_overlay "$T2" "$(cat <<'YAML'
behaviors:
  - id: plain-contract-behavior
    statement: "A non-workflow behavior with no workflow: field still validates (the - unwrap)."
    level: contract
    area: fixture
    purpose: "Proves the placeholder column does not require a workflow value."
  - id: workflow-alpha-runs
    statement: "Running the alpha orchestrator drives it through a gstack-independent decision."
    level: workflow
    workflow: CJ_goal_alpha
    area: workflow-coverage
    purpose: "Round-trips the 6th workflow column on a level:workflow row."
behavior_coverage:
  - behavior: plain-contract-behavior
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
  - behavior: workflow-alpha-runs
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
YAML
)"
# Note: the overlay declares suite-eval coverage but the general seed has no
# suite-eval unit; --validate does NOT run behavior_coverage conformance (that is
# --check-coverage), so --validate here exercises ONLY the 6th-column parser +
# enum-check. The enum-check needs CJ_goal_alpha to resolve as an orchestrator,
# which the fixture workflow registry provides.
_OUT=$(run_validate_in "$T2"); _RC=$?
if [ "$_RC" -eq 0 ] && printf '%s' "$_OUT" | grep -qF 'OK schema_version=1'; then
  ok "6th-column parser: a valid workflow: on a level:workflow row + a placeholder-only contract row both --validate"
else
  fail_test "6th-column round-trip failed (rc=$_RC): $_OUT"
fi
# --list-behaviors ($1-only consumer) stays positional-safe (emits both ids).
_LB=$(REPO_ROOT="$T2" TEST_SPEC_PATH="$T2/spec/test-spec.md" WORKFLOW_SPEC_PATH="$T2/spec/workflow-spec.md" bash "$TS" --list-behaviors 2>/dev/null)
if printf '%s\n' "$_LB" | grep -qx 'plain-contract-behavior' && printf '%s\n' "$_LB" | grep -qx 'workflow-alpha-runs'; then
  ok "--list-behaviors (\$1-only) stays positional-safe with the 6th column present"
else
  fail_test "--list-behaviors lost a row with the 6th column (got: $(printf '%s' "$_LB" | tr '\n' ' '))"
fi

# ---- 3. enum-check: unknown orchestrator + workflow: on wrong level ----------

T3=$(mk_tmp); git -C "$T3" init -q 2>/dev/null
seed_general "$T3"
write_workflow_registry "$T3" CJ_goal_alpha
write_overlay "$T3" "$(cat <<'YAML'
behaviors:
  - id: bad-enum-behavior
    statement: "A workflow: naming an undeclared orchestrator must be rejected."
    level: workflow
    workflow: CJ_goal_undeclared
    area: workflow-coverage
    purpose: "Enum-check negative."
behavior_coverage:
  - behavior: bad-enum-behavior
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
YAML
)"
_OUT=$(run_validate_in "$T3"); _RC=$?
if [ "$_RC" -ne 0 ] && printf '%s' "$_OUT" | grep -qF 'is not a declared orchestrator'; then
  ok "enum-check: an unknown workflow: value HALTs --validate"
else
  fail_test "enum-check did not reject an unknown orchestrator (rc=$_RC): $_OUT"
fi

T3b=$(mk_tmp); git -C "$T3b" init -q 2>/dev/null
seed_general "$T3b"
write_workflow_registry "$T3b" CJ_goal_alpha
write_overlay "$T3b" "$(cat <<'YAML'
behaviors:
  - id: wrong-level-workflow
    statement: "A workflow: field on a non-level:workflow row must be rejected."
    level: contract
    workflow: CJ_goal_alpha
    area: fixture
    purpose: "Allowed-only-on-level:workflow negative."
behavior_coverage:
  - behavior: wrong-level-workflow
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
YAML
)"
_OUT=$(run_validate_in "$T3b"); _RC=$?
if [ "$_RC" -ne 0 ] && printf '%s' "$_OUT" | grep -qF 'allowed ONLY on level: workflow rows'; then
  ok "enum-check: a workflow: field on a non-level:workflow row HALTs --validate"
else
  fail_test "enum-check did not reject workflow: on a non-workflow level (rc=$_RC): $_OUT"
fi

# ---- 4. forward miss: a 5th orchestrator with no matching behavior ----------

T4=$(mk_tmp); git -C "$T4" init -q 2>/dev/null
seed_general "$T4"
# Two orchestrators declared, but only one has a level:workflow behavior.
write_workflow_registry "$T4" CJ_goal_alpha CJ_goal_beta
write_overlay "$T4" "$(cat <<'YAML'
behaviors:
  - id: workflow-alpha-runs
    statement: "Alpha runs to a gstack-independent decision."
    level: workflow
    workflow: CJ_goal_alpha
    area: workflow-coverage
    purpose: "Covers alpha; beta is left UNcovered to trip the forward check."
behavior_coverage:
  - behavior: workflow-alpha-runs
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
YAML
)"
_OUT=$(run_gate_in "$T4"); _RC=$?
if [ "$_RC" -ne 0 ] \
   && printf '%s' "$_OUT" | grep -qF "orchestrator 'CJ_goal_beta'" \
   && printf '%s' "$_OUT" | grep -qF 'has NO level:workflow behavior'; then
  ok "forward miss: a 5th orchestrator with no level:workflow behavior FAILS the gate (negative fixture)"
else
  fail_test "forward miss not caught (rc=$_RC): $_OUT"
fi

# ---- 5. reverse orphan: a behavior naming an undeclared orchestrator ---------
#
# A level:workflow behavior whose workflow: names an undeclared orchestrator is
# an ORPHAN forward-link. There are TWO lines of defense, and this case proves
# both:
#  5a. --validate's enum-check is the FIRST line: an undeclared workflow: value
#      HARD-HALTs --validate. The gate runs _run_registry_gates (== --validate)
#      first, so the gate ALSO fails on this orphan via the enum-check. This is
#      the realistic catch (the registry can never even parse with the orphan).
#  5b. the gate's OWN reverse arm is the BELT-AND-SUSPENDERS: a level:workflow
#      behavior with an EMPTY workflow: field passes --validate (an absent
#      forward-link is allowed there) but the gate flags it ("has no 'workflow:'
#      field"). This proves the reverse arm fires on the path validate leaves open.
# 5a: undeclared workflow: value -> enum-check halt (caught by the gate).
T5=$(mk_tmp); git -C "$T5" init -q 2>/dev/null
seed_general "$T5"
write_workflow_registry "$T5" CJ_goal_alpha
write_overlay "$T5" "$(cat <<'YAML'
behaviors:
  - id: workflow-orphan-runs
    statement: "Names an orchestrator absent from the workflow registry (orphan link)."
    level: workflow
    workflow: CJ_goal_ghost
    area: workflow-coverage
    purpose: "Reverse-orphan negative — workflow: resolves to no declared orchestrator."
behavior_coverage:
  - behavior: workflow-orphan-runs
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
YAML
)"
_OUT=$(run_gate_in "$T5"); _RC=$?
if [ "$_RC" -ne 0 ] \
   && printf '%s' "$_OUT" | grep -qF "workflow: CJ_goal_ghost" \
   && printf '%s' "$_OUT" | grep -qF 'is not a declared orchestrator'; then
  ok "reverse orphan (5a): an undeclared workflow: value FAILS the gate (via the --validate enum-check)"
else
  fail_test "reverse orphan (5a) not caught (rc=$_RC): $_OUT"
fi

# 5b: a level:workflow behavior with an EMPTY workflow: field — validate allows
# it, but the gate's reverse arm flags the missing forward-link.
T5b=$(mk_tmp); git -C "$T5b" init -q 2>/dev/null
seed_general "$T5b"
# One orchestrator declared + one level:workflow behavior that DOES cover it, so
# the forward arm is satisfied; PLUS an orphan-empty behavior to trip the reverse
# arm specifically (without also tripping the forward arm for an uncovered orch).
write_workflow_registry "$T5b" CJ_goal_alpha
write_overlay "$T5b" "$(cat <<'YAML'
behaviors:
  - id: workflow-alpha-runs
    statement: "Alpha runs to a gstack-independent decision."
    level: workflow
    workflow: CJ_goal_alpha
    area: workflow-coverage
    purpose: "Covers alpha (forward arm satisfied)."
  - id: workflow-no-link
    statement: "A level:workflow behavior with no workflow: forward-link."
    level: workflow
    area: workflow-coverage
    purpose: "Reverse arm negative — a level:workflow row missing its workflow: field."
behavior_coverage:
  - behavior: workflow-alpha-runs
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
  - behavior: workflow-no-link
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
YAML
)"
# --validate must PASS (an empty workflow: field is allowed there).
_OUT=$(run_validate_in "$T5b"); _RC=$?
if [ "$_RC" -ne 0 ]; then
  fail_test "reverse arm setup (5b): --validate should pass with an empty workflow: field, but failed: $_OUT"
fi
# The gate's reverse arm flags the missing forward-link.
_OUT=$(run_gate_in "$T5b"); _RC=$?
if [ "$_RC" -ne 0 ] \
   && printf '%s' "$_OUT" | grep -qF "behavior 'workflow-no-link'" \
   && printf '%s' "$_OUT" | grep -qF "has no 'workflow:' field"; then
  ok "reverse orphan (5b): the gate's reverse arm flags a level:workflow behavior with no workflow: field"
else
  fail_test "reverse arm (5b) not caught (rc=$_RC): $_OUT"
fi

# ---- 6. all-declared -> clean ----------------------------------------------

T6=$(mk_tmp); git -C "$T6" init -q 2>/dev/null
seed_general "$T6"
write_workflow_registry "$T6" CJ_goal_alpha CJ_goal_beta
write_overlay "$T6" "$(cat <<'YAML'
behaviors:
  - id: workflow-alpha-runs
    statement: "Alpha runs to a gstack-independent decision."
    level: workflow
    workflow: CJ_goal_alpha
    area: workflow-coverage
    purpose: "Covers alpha."
  - id: workflow-beta-runs
    statement: "Beta runs to a gstack-independent decision."
    level: workflow
    workflow: CJ_goal_beta
    area: workflow-coverage
    purpose: "Covers beta."
behavior_coverage:
  - behavior: workflow-alpha-runs
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
  - behavior: workflow-beta-runs
    unit: suite-eval
    source: spec/test-spec.md
    anchor: "schema_version"
YAML
)"
_OUT=$(run_gate_in "$T6"); _RC=$?
if [ "$_RC" -eq 0 ] && printf '%s' "$_OUT" | grep -qE 'findings=0$'; then
  ok "all-declared: every orchestrator has a matching behavior + no orphan -> gate clean (exit 0)"
else
  fail_test "all-declared should be clean but was not (rc=$_RC): $_OUT"
fi

# ---- 7. consumer-absent: no test-spec registry / workflow registry absent ----

T7=$(mk_tmp); git -C "$T7" init -q 2>/dev/null
# No spec/ at all: test-spec registry absent -> REGISTRY=absent + exit 0.
_OUT=$(REPO_ROOT="$T7" TEST_SPEC_PATH="$T7/spec/test-spec.md" WORKFLOW_SPEC_PATH="$T7/spec/workflow-spec.md" bash "$TS" --check-workflow-coverage 2>&1); _RC=$?
if [ "$_RC" -eq 0 ] && printf '%s' "$_OUT" | grep -qF 'REGISTRY=absent'; then
  ok "consumer-absent: no test-spec registry -> REGISTRY=absent + exit 0"
else
  fail_test "consumer-absent (no test-spec) wrong (rc=$_RC): $_OUT"
fi

# test-spec present (rules-only seed) but workflow registry absent -> inactive + 0.
T7b=$(mk_tmp); git -C "$T7b" init -q 2>/dev/null
seed_general "$T7b"
_OUT=$(REPO_ROOT="$T7b" TEST_SPEC_PATH="$T7b/spec/test-spec.md" WORKFLOW_SPEC_PATH="$T7b/spec/workflow-spec.md" bash "$TS" --check-workflow-coverage 2>&1); _RC=$?
if [ "$_RC" -eq 0 ] && printf '%s' "$_OUT" | grep -qF 'workflow coverage inactive'; then
  ok "consumer-absent: workflow registry absent -> inactive note + exit 0"
else
  fail_test "consumer-absent (no workflow registry) wrong (rc=$_RC): $_OUT"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: workflow-coverage (all assertions)"
  exit 0
else
  echo "FAIL: workflow-coverage ($ERRORS error(s))"
  exit 1
fi
