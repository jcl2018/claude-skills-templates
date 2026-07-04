#!/usr/bin/env bash
# tests/workflow/local-hook/doc-sync.test.sh — the `doc-sync` workflow-category
# test (F000078). Proves the doc/test-sync audit WORKFLOW (/CJ_doc_audit +
# /CJ_test_audit, driven by scripts/audit-nightly.sh) is wired and honest end to
# end, WITHOUT spending a single model token: it asserts the runner's
# command — `bash scripts/audit-nightly.sh --dry-run`, the exact `command` value
# of the `doc-sync` categories: row — either prints its DRY-RUN plan (when a model
# key is present) OR self-gates with a leading `SKIP:` (no key), and NEVER runs a
# real audit or exits non-zero on a clean tree.
#
# This is the workflow-category front door's deterministic proof. It COEXISTS with
# tests/audit-nightly.test.sh (which drills the runner's parse/report/issue halves
# with claude + gh stubbed); this file is the lighter workflow-level assertion the
# `doc-sync` category row points at. mode: agentic in the contract refers to the
# REAL on-demand run (claude --print); this deterministic guard spends nothing.
#
# Category: workflow   Layer: local-hook   (see docs/tests/workflow/local-hook/doc-sync.md)

set -u

# Resolve repo root from this file's location (tests/workflow/CI-nightly/ -> repo).
_SELF_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=${REPO_ROOT:-$(cd "$_SELF_DIR/../../.." && pwd)}
AUDIT="$REPO_ROOT/scripts/audit-nightly.sh"

FAILED=0
ok()        { echo "  ok: $1"; }
fail_test() { echo "  FAIL: $1"; FAILED=1; }

echo "=== doc-sync workflow-category test (audit-nightly.sh --dry-run honesty) ==="

# G1: the runner script exists and is the command the categories: row declares.
if [ -f "$AUDIT" ]; then
  ok "G1: scripts/audit-nightly.sh (the doc-sync workflow runner) is present"
else
  fail_test "G1: scripts/audit-nightly.sh is missing (the doc-sync category command)"
fi

# G2: `--dry-run` exits 0 (either the plan, or a clean self-gating SKIP) — never a
# real model run, never a non-zero exit on a clean tree.
if [ -f "$AUDIT" ]; then
  _OUT=$(bash "$AUDIT" --dry-run 2>&1); _RC=$?
  _FIRST=$(printf '%s\n' "$_OUT" | head -1)
  if [ "$_RC" -eq 0 ]; then
    ok "G2: audit-nightly.sh --dry-run exits 0 (spends nothing)"
  else
    fail_test "G2: audit-nightly.sh --dry-run exited $_RC (expected 0): $_OUT"
  fi

  # G3: the output is honest — EITHER the DRY-RUN plan (model key present) OR a
  # leading SKIP: self-gate (no key). Both are correct; a real audit banner is not.
  if printf '%s\n' "$_OUT" | grep -qF 'DRY-RUN: nightly doc/test audit plan'; then
    ok "G3: --dry-run printed the audit plan (model key present; nothing run)"
  elif printf '%s' "$_FIRST" | grep -q '^SKIP:'; then
    ok "G3: --dry-run self-gated with a leading SKIP: (no model key; nothing run)"
  else
    fail_test "G3: --dry-run output is neither the plan nor a SKIP: self-gate: $_OUT"
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  echo "doc-sync workflow-category test: FAIL"
  exit 1
fi
echo "doc-sync workflow-category test: PASS"
exit 0
