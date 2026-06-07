#!/usr/bin/env bash
# tests/cj-goal-common-portability.test.sh
#
# Test for the F000051 / S000091 `--phase portability-audit` (the pre-ship
# portability gate) in scripts/cj-goal-common.sh. Covers TEST-SPEC S2/S3 + the
# clean-catalog AC-1 shape:
#   - clean catalog (the REAL repo engine)        -> PHASE_RESULT=ok, exit 0,
#                                                    FINDINGS=0, SKILLS_AUDITED>0,
#                                                    a clean VERDICT_LINE
#   - dishonest-declaration fixture (FAKE engine) -> PHASE_RESULT=findings,
#                                                    non-zero exit, FINDINGS>0
#   - engine absent (sibling missing + manifest   -> PHASE_RESULT=skipped, exit 0
#     .source has no engine)                         (fail-soft; NEVER findings)
#   - --dry-run                                    -> PHASE_RESULT=ok, exit 0,
#                                                    empty FINDINGS=, engine NOT run
#
# HERMETIC: the engine-absent + findings cases run a COPY of cj-goal-common.sh
# from a throwaway dir with a controlled sibling engine, and a HOME override
# pointing at a temp manifest whose `.source` has no engine — so the
# resolve_portability_engine() probe is fully sandboxed and never reaches the
# real ~/.claude manifest or the real repo engine. The clean + dry-run cases run
# the REAL repo cj-goal-common.sh + the REAL engine (read-only; the audit mutates
# nothing).
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
COMMON="$REPO_ROOT/scripts/cj-goal-common.sh"

echo "=== cj-goal-common-portability.test.sh: --phase portability-audit (F000051) — hermetic ==="

[ -x "$COMMON" ] || { echo "RESULT: FAIL ($COMMON not executable)"; exit 1; }

getkey() { printf '%s\n' "$2" | sed -n "s/^$1=//p" | head -1; }

# ── Sandbox ──────────────────────────────────────────────────────────────────
TMP=$(mktemp -d -t cj-goal-port-test-XXXXXX)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ── 1. Clean catalog (REAL repo engine): ok, exit 0, FINDINGS=0 ──────────────
CLEAN_OUT=$(bash "$COMMON" --phase portability-audit --mode feature 2>&1)
CLEAN_RC=$?
if [ "$CLEAN_RC" -eq 0 ] \
   && [ "$(getkey PHASE "$CLEAN_OUT")" = "portability-audit" ] \
   && [ "$(getkey MODE "$CLEAN_OUT")" = "feature" ] \
   && [ "$(getkey PHASE_RESULT "$CLEAN_OUT")" = "ok" ] \
   && [ "$(getkey FINDINGS "$CLEAN_OUT")" = "0" ]; then
  ok "clean catalog: exit 0, PHASE=portability-audit, MODE=feature, PHASE_RESULT=ok, FINDINGS=0"
else
  fail_test "clean catalog: expected exit0/ok/FINDINGS=0 (rc=$CLEAN_RC); output: $CLEAN_OUT"
fi
_CLEAN_SA=$(getkey SKILLS_AUDITED "$CLEAN_OUT")
if [ -n "$_CLEAN_SA" ] && [ "$_CLEAN_SA" -gt 0 ] 2>/dev/null; then
  ok "clean catalog: SKILLS_AUDITED=$_CLEAN_SA (>0)"
else
  fail_test "clean catalog: SKILLS_AUDITED not a positive int; output: $CLEAN_OUT"
fi
if printf '%s\n' "$CLEAN_OUT" | grep -qE '^VERDICT_LINE=Portability: all [0-9]+ skills honestly declared'; then
  ok "clean catalog: clean VERDICT_LINE present"
else
  fail_test "clean catalog: clean VERDICT_LINE missing; output: $CLEAN_OUT"
fi

# ── 2. --dry-run: ok, exit 0, empty FINDINGS=, engine NOT run ────────────────
# Run a COPY whose sibling engine is a tripwire: if --dry-run runs the engine,
# the tripwire would emit FINDINGS=99; dry-run must NOT run it (empty FINDINGS).
DRY_DIR="$TMP/dry/scripts"
mkdir -p "$DRY_DIR"
cp "$COMMON" "$DRY_DIR/"
cat > "$DRY_DIR/cj-portability-audit.sh" <<'TRIP'
#!/usr/bin/env bash
echo "TRIPWIRE: engine ran during --dry-run"
echo "FINDINGS=99"
echo "SKILLS_AUDITED=99"
exit 1
TRIP
chmod +x "$DRY_DIR/cj-portability-audit.sh"
DRY_OUT=$(bash "$DRY_DIR/cj-goal-common.sh" --phase portability-audit --mode feature --dry-run 2>&1)
DRY_RC=$?
if [ "$DRY_RC" -eq 0 ] \
   && [ "$(getkey PHASE_RESULT "$DRY_OUT")" = "ok" ] \
   && [ -z "$(getkey FINDINGS "$DRY_OUT")" ] \
   && ! printf '%s\n' "$DRY_OUT" | grep -q 'TRIPWIRE'; then
  ok "--dry-run: exit 0, PHASE_RESULT=ok, empty FINDINGS=, engine NOT run (no tripwire)"
else
  fail_test "--dry-run: expected exit0/ok/empty-FINDINGS/no-engine (rc=$DRY_RC); output: $DRY_OUT"
fi

# ── 3. Findings fixture (FAKE engine emitting FINDINGS): findings, non-zero ──
FK_DIR="$TMP/findings/scripts"
mkdir -p "$FK_DIR"
cp "$COMMON" "$FK_DIR/"
# FAKE engine: a dishonest-declaration shape. Honors PORTABILITY_STRICT=1 by
# exiting non-zero on findings, exactly like the real engine.
cat > "$FK_DIR/cj-portability-audit.sh" <<'FAKE'
#!/usr/bin/env bash
echo "my-skill                   | standalone  | findings: executes scripts/foo.sh (workbench dep)"
echo ""
echo "FINDINGS=1"
echo "SKILLS_AUDITED=3"
if [ "${PORTABILITY_STRICT:-0}" = "1" ]; then
  echo "RESULT: FINDINGS (PORTABILITY_STRICT=1 -> non-zero exit)"
  exit 1
fi
echo "RESULT: OK (advisory)"
exit 0
FAKE
chmod +x "$FK_DIR/cj-portability-audit.sh"
FK_OUT=$(bash "$FK_DIR/cj-goal-common.sh" --phase portability-audit --mode defect 2>&1)
FK_RC=$?
if [ "$FK_RC" -ne 0 ] \
   && [ "$(getkey PHASE_RESULT "$FK_OUT")" = "findings" ] \
   && [ "$(getkey FINDINGS "$FK_OUT")" = "1" ]; then
  ok "findings fixture: non-zero exit (rc=$FK_RC), PHASE_RESULT=findings, FINDINGS=1"
else
  fail_test "findings fixture: expected non-zero/findings/FINDINGS=1 (rc=$FK_RC); output: $FK_OUT"
fi
if printf '%s\n' "$FK_OUT" | grep -qE '^VERDICT_LINE=Portability: 1 skill\(s\) with findings — findings:'; then
  ok "findings fixture: red VERDICT_LINE carries the first finding line"
else
  fail_test "findings fixture: red VERDICT_LINE missing first finding; output: $FK_OUT"
fi

# ── 4. Engine absent: skipped, exit 0 (sibling missing + .source has no engine)
ABS_DIR="$TMP/absent/scripts"
mkdir -p "$ABS_DIR"
cp "$COMMON" "$ABS_DIR/"   # NO sibling cj-portability-audit.sh next to it
# HOME override so resolve_portability_engine()'s manifest probe reads a temp
# manifest whose .source points at a dir with no engine (fully sandboxed).
ABS_HOME="$TMP/absent-home"
mkdir -p "$ABS_HOME/.claude"
printf '{ "source": "%s" }\n' "$TMP/nonexistent-source" > "$ABS_HOME/.claude/.skills-templates.json"
ABS_OUT=$(HOME="$ABS_HOME" bash "$ABS_DIR/cj-goal-common.sh" --phase portability-audit --mode feature 2>&1)
ABS_RC=$?
if [ "$ABS_RC" -eq 0 ] && [ "$(getkey PHASE_RESULT "$ABS_OUT")" = "skipped" ]; then
  ok "engine absent: exit 0, PHASE_RESULT=skipped (fail-soft, NEVER findings)"
else
  fail_test "engine absent: expected exit0/skipped (rc=$ABS_RC); output: $ABS_OUT"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS error(s))"
  exit 1
fi
