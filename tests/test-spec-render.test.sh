#!/usr/bin/env bash
# tests/test-spec-render.test.sh
#
# Test for the F000069 / S000114 `--render-docs` generated test-catalog renderer
# in scripts/test-spec.sh — the SECOND instance of the proven
# README ↔ generate-readme.sh ↔ validate.sh Check 25 freshness primitive, applied
# to the test surface. Covers TEST-SPEC S2 (deterministic + ID-free) and S3
# (--check round-trip), plus the live-tree freshness invariant:
#   T1 (resilience) — --render-docs twice into two temp dirs is BYTE-IDENTICAL
#                     (stable sort, fixed headers, no timestamps).
#   T2 (resilience) — the rendered output is work-item-ID-free (no [FSTD][0-9]{6}
#                     anywhere — anchors that embed IDs are masked).
#   T3 (observability) — --render-docs --check exits 0 on a freshly-rendered tree.
#   T4 (observability) — --check exits 1 (naming the file) after a hand-edit to a
#                        generated file, and again after a generated file is
#                        removed (missing-file finding).
#   T5 (integration) — the LIVE committed docs/tests/ + docs/test-catalog.md are
#                      in sync with a fresh render (the Check-26 invariant).
#
# HERMETIC: T1–T4 render into THROWAWAY temp dirs via the TESTDOC_OUT override —
# the live committed tree is never mutated. T5 is read-only against the live tree.
# No ~/.claude touch, no git mutation.
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
ENGINE="$REPO_ROOT/scripts/test-spec.sh"

echo "=== test-spec-render.test.sh: --render-docs renderer + freshness primitive — hermetic ==="

[ -f "$ENGINE" ] || { echo "RESULT: FAIL ($ENGINE not found)"; exit 1; }

# ── T1: render twice into two temp dirs → byte-identical (deterministic) ──────
T1A=$(mktemp -d -t tsrender-a-XXXXXX)
T1B=$(mktemp -d -t tsrender-b-XXXXXX)
TESTDOC_OUT="$T1A/docs" bash "$ENGINE" --render-docs >/dev/null 2>&1
TESTDOC_OUT="$T1B/docs" bash "$ENGINE" --render-docs >/dev/null 2>&1
if diff -r "$T1A/docs" "$T1B/docs" >/dev/null 2>&1; then
  ok "T1: two consecutive renders are byte-identical (deterministic)"
else
  fail_test "T1: renders differ across runs (non-deterministic):"
  diff -r "$T1A/docs" "$T1B/docs" >&2 || true
fi
# Sanity: the render actually produced the index + at least one family page.
if [ -f "$T1A/docs/test-catalog.md" ] && ls "$T1A/docs/tests/"*.md >/dev/null 2>&1; then
  ok "T1: render produced docs/test-catalog.md + docs/tests/<family>.md"
else
  fail_test "T1: render did not produce the expected catalog files under $T1A/docs"
fi

# ── T2: the rendered output is work-item-ID-free ─────────────────────────────
if grep -rE '[FSTD][0-9]{6}' "$T1A/docs" >/dev/null 2>&1; then
  fail_test "T2: rendered catalog contains a work-item ID (must be ID-free for Check 19):"
  grep -rEn '[FSTD][0-9]{6}' "$T1A/docs" | head -5 >&2 || true
else
  ok "T2: rendered catalog is work-item-ID-free (passes Check 19 by construction)"
fi

# ── T3: --render-docs --check exits 0 on a freshly-rendered tree ──────────────
T3=$(mktemp -d -t tsrender-c-XXXXXX)
TESTDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs >/dev/null 2>&1
if TESTDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs --check >/dev/null 2>&1; then
  ok "T3: --check exits 0 on a freshly-rendered tree"
else
  fail_test "T3: --check should exit 0 on a fresh render but exited non-zero"
fi

# ── T4: --check fails (exit 1, naming the file) after a hand-edit / a removal ─
# 4a — hand-edit a generated file.
printf '\nhand-edit drift line\n' >> "$T3/docs/test-catalog.md"
_T4A_OUT=$(TESTDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs --check 2>&1)
_T4A_RC=$?
if [ "$_T4A_RC" -ne 0 ] && printf '%s\n' "$_T4A_OUT" | grep -qF "test-catalog.md is stale"; then
  ok "T4a: a hand-edited generated file → --check exit non-zero + names the stale file"
else
  fail_test "T4a: --check should fail naming the stale file (rc=$_T4A_RC); output: $_T4A_OUT"
fi
# Regenerate → green again.
TESTDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs >/dev/null 2>&1
if TESTDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs --check >/dev/null 2>&1; then
  ok "T4a: --check exits 0 again after regenerate"
else
  fail_test "T4a: --check should exit 0 after regenerate but exited non-zero"
fi
# 4b — remove a generated family page → missing-file finding.
_VICTIM=$(ls "$T3/docs/tests/"*.md 2>/dev/null | head -1)
if [ -n "$_VICTIM" ]; then
  rm -f "$_VICTIM"
  _T4B_OUT=$(TESTDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs --check 2>&1)
  _T4B_RC=$?
  if [ "$_T4B_RC" -ne 0 ] && printf '%s\n' "$_T4B_OUT" | grep -qF "is missing on disk"; then
    ok "T4b: a missing generated file → --check exit non-zero + names the missing file"
  else
    fail_test "T4b: --check should fail naming the missing file (rc=$_T4B_RC); output: $_T4B_OUT"
  fi
else
  fail_test "T4b: no family page found to remove for the missing-file drill"
fi

# ── T5: the LIVE committed catalog is in sync with a fresh render (Check-26) ──
if bash "$ENGINE" --render-docs --check >/dev/null 2>&1; then
  ok "T5: live committed docs/tests/ + docs/test-catalog.md are in sync with the registry"
else
  fail_test "T5: live committed catalog is stale vs the registry — run: bash scripts/test-spec.sh --render-docs"
fi

# Cleanup throwaway temp dirs.
rm -rf "$T1A" "$T1B" "$T3"

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS error(s))"
  exit 1
fi
