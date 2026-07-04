#!/usr/bin/env bash
# tests/cj-goal-jq-crlf.test.sh
#
# Regression drill for the jq-CRLF class in the CJ_goal_* / check-* orchestrator
# helpers (the Windows P0). A Windows jq build emits CRLF line endings, so a raw
# `$(jq -r ...)` capture leaves a trailing \r on every value — e.g.
# `src='E:/path\r'`, which then fails `[ -d "$src" ]` and silently degrades the
# cj-goal-common sync / pr-check phases to `skipped` on Windows (fail-soft hides
# it). D000038 fixed this class in the spec engines (doc-spec.sh / test-spec.sh /
# workflow-spec.sh); this drill locks the SAME fix into the five orchestrator
# helpers that also parse jq:
#
#   scripts/cj-goal-common.sh     scripts/cj-worktree-init.sh
#   scripts/cj-worktree-cleanup.sh scripts/check-version-queue.sh
#   scripts/check-gates-update.sh
#
# The fix is the canonical CR-stripping wrapper (mirrors scripts/lib.sh:24), in
# the pipefail-independent form so it is correct in the two helpers that
# deliberately omit `set -o pipefail` (cj-goal-common.sh, cj-worktree-cleanup.sh)
# AND preserves jq's exit status for the exit-status call sites
# (cj-goal-common.sh's `if jq -nc ...`, check-version-queue.sh's `jq -e`):
#
#   jq() { command jq "$@" | tr -d '\r'; return "${PIPESTATUS[0]}"; }
#
# Asserts:
#   T1 (structural, x5) — each helper defines the CR-stripping jq() wrapper, so
#      removing it from ANY helper trips the guard (covers the helpers whose jq
#      output feeds internal logic, not observable stdout).
#   T2 (mechanism)      — under a Windows-style CRLF-emitting jq shim, the wrapper
#      idiom (a) strips CR from `jq -r` output and (b) preserves jq's NON-zero
#      exit status even with `set +o pipefail` (the property the two no-pipefail
#      helpers depend on).
#   T3 (end-to-end)     — `cj-goal-common.sh --phase worktree --dry-run` under the
#      CRLF shim emits non-empty, CR-free output (WT_STATE/WT_PATH are jq-derived,
#      so without the wrapper they would carry a trailing \r). --dry-run has no
#      side effects.
#
# Portable: on Linux the shim turns LF into CRLF; on Windows real jq already
# emits CRLF and the shim adds one more (\r\r\n) — either way the wrapper strips
# it. Runs identically on Linux CI and Windows Git Bash.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

HELPERS=(
  "scripts/cj-goal-common.sh"
  "scripts/cj-worktree-init.sh"
  "scripts/cj-worktree-cleanup.sh"
  "scripts/check-version-queue.sh"
  "scripts/check-gates-update.sh"
)

echo "=== cj-goal-jq-crlf: CR-stripping jq() wrapper in the 5 orchestrator helpers ==="

# ── T1: structural — each helper defines the CR-stripping wrapper ──────────────
# Anchor on the unique substring `command jq "$@" | tr -d` (grep -F, literal).
for rel in "${HELPERS[@]}"; do
  f="$REPO_ROOT/$rel"
  if [ ! -f "$f" ]; then
    fail_test "T1: missing helper: $rel"
    continue
  fi
  if grep -qF 'command jq "$@" | tr -d' "$f"; then
    ok "T1: $rel defines the CR-stripping jq() wrapper"
  else
    fail_test "T1: $rel is missing the CR-stripping jq() wrapper (jq-CRLF regression)"
  fi
done

# ── shim: a PATH-prepended jq that appends \r to every real-jq output line ─────
if ! command -v jq >/dev/null 2>&1; then
  echo "  OK:   T2/T3: skipped (jq not installed — jq-CRLF class is vacuous without jq)"
  echo
  if [ "$ERRORS" -eq 0 ]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL ($ERRORS)"; exit 1; fi
fi

SHIM=$(mktemp -d -t cjjqcrlf-XXXXXX)
trap 'rm -rf "$SHIM"' EXIT
_REALJQ=$(command -v jq)
# A faithful Windows-jq model: inject a trailing \r on every output line AND
# preserve real jq's exit status (real Windows jq emits CRLF yet still returns
# its own rc — e.g. `jq -e` fails on a non-array). `exit "${PIPESTATUS[0]}"`
# forwards jq's rc past the CR-injecting awk (bash, not /bin/sh, for PIPESTATUS).
cat > "$SHIM/jq" <<SHIMEOF
#!/usr/bin/env bash
"$_REALJQ" "\$@" | awk '{ printf "%s\r\n", \$0 }'
exit "\${PIPESTATUS[0]}"
SHIMEOF
chmod +x "$SHIM/jq"

# Shim sanity: it MUST emit a trailing CR, else the drill proves nothing.
if [ "$(printf '["x"]' | "$SHIM/jq" -r '.[0]' | tr -cd '\r' | wc -c | tr -cd '0-9')" = "0" ]; then
  fail_test "shim: CRLF jq shim failed to emit CR — T2/T3 inconclusive"
else
  # ── T2: mechanism — wrapper strips CR + preserves non-zero exit sans pipefail ─
  WRAP="$SHIM/wrapper.sh"
  cat > "$WRAP" <<'WRAPEOF'
jq() { command jq "$@" | tr -d '\r'; return "${PIPESTATUS[0]}"; }
WRAPEOF

  _t2_cr=$(PATH="$SHIM:$PATH" bash -c "set +o pipefail; . '$WRAP'; printf '{\"s\":\"x\"}' | jq -r '.s'" 2>/dev/null \
           | tr -cd '\r' | wc -c | tr -cd '0-9')
  if [ "${_t2_cr:-1}" = "0" ]; then
    ok "T2: wrapper strips CR from jq -r output under a CRLF-emitting jq"
  else
    fail_test "T2: wrapper left $_t2_cr CR byte(s) in jq -r output under a CRLF-emitting jq"
  fi

  PATH="$SHIM:$PATH" bash -c "set +o pipefail; . '$WRAP'; printf '{\"k\":\"v\"}' | jq -e 'type==\"array\"' >/dev/null 2>&1"
  _t2_rc=$?
  if [ "$_t2_rc" -ne 0 ]; then
    ok "T2: wrapper preserves jq's non-zero exit status with pipefail OFF (rc=$_t2_rc)"
  else
    fail_test "T2: wrapper masked jq's non-zero exit status with pipefail OFF (jq -e on a non-array returned 0)"
  fi

  # ── T3: end-to-end — cj-goal-common worktree phase emits CR-free jq-derived out
  _t3_out=$(PATH="$SHIM:$PATH" bash "$REPO_ROOT/scripts/cj-goal-common.sh" \
              --phase worktree --mode defect --dry-run 2>/dev/null)
  _t3_cr=$(printf '%s' "$_t3_out" | tr -cd '\r' | wc -c | tr -cd '0-9')
  if [ -n "$_t3_out" ] && [ "${_t3_cr:-1}" = "0" ]; then
    ok "T3: cj-goal-common.sh worktree phase emits non-empty CR-free output under a CRLF-emitting jq"
  else
    fail_test "T3: cj-goal-common.sh worktree phase output empty or CR-tainted under a CRLF-emitting jq (cr=$_t3_cr, empty=$([ -z "$_t3_out" ] && echo yes || echo no))"
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
