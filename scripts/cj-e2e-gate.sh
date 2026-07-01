#!/usr/bin/env bash
# cj-e2e-gate.sh — pure, deterministic verdict helper for the cj_goal local-E2E
# build-gate auto-answer seam (F000071 Part A / S000120).
#
# The cj_goal BUILD gates (design-gate, qa-audit) are agent-emitted
# AskUserQuestion calls (prose in each pipeline.md), NOT shell — so a shell
# helper cannot suppress them directly. Instead this helper is a pure verdict
# FUNCTION: the pipeline prose runs it first and branches on its one-line stdout.
#
# Output: exactly ONE line on stdout, exit 0 always:
#   AUTO=continue   — the seam is active and the gate should auto-proceed
#                     (skip the AUQ, print the [E2E-AUTO] banner, continue)
#   AUTO=halt       — the seam is active but the digest carries findings
#                     (emit [qa-audit-declined]; NEVER auto-waive findings)
#   AUTO=inactive   — the seam is dormant; fire the AUQ unchanged (normal run)
#
# Usage:
#   cj-e2e-gate.sh --gate <design-gate|qa-audit> [--digest <doc:..,test:..>]
#
# Verdict logic (the safety contract — load-bearing):
#   1. DOUBLE HARD GUARD. Returns `inactive` UNLESS BOTH:
#        - the env flag  CJ_GOAL_E2E_AUTO=1  is set, AND
#        - the marker    <repo-root>/.cj-e2e-sandbox  exists
#      (repo root = git rev-parse --show-toplevel). Either alone → inactive,
#      so a normal run is behavior-unchanged and the seam can never fire by
#      accident.
#   2. BUILD-GATES-ONLY ALLOWLIST. The gate id MUST be in the hardcoded
#      allowlist {design-gate, qa-audit}. Any other id → inactive — it can
#      NEVER match a gstack /ship / merge / /land / deploy gate marker.
#   3. GREEN-ONLY CONTINUE (qa-audit). Reuses todo_fix --quiet's predicate:
#      continue ONLY on a fully-green digest (doc:ok AND test:ok); ANY findings
#      → halt; never auto-waive. design-gate is feature-only and takes no digest
#      (it auto-approves the design summary → continue).
#
# Pure: reads only its args + CJ_GOAL_E2E_AUTO + the marker file; writes only the
# one verdict line to stdout; mutates nothing. Deterministic + unit-testable
# (tests/cj-e2e-gate.test.sh) with no Claude.

set -euo pipefail

GATE=""
DIGEST=""

while [ $# -gt 0 ]; do
  case "$1" in
    --gate)
      GATE="${2:-}"
      shift 2
      ;;
    --digest)
      DIGEST="${2:-}"
      shift 2
      ;;
    *)
      # Unknown arg — ignore (pure verdict helper, never errors out).
      shift
      ;;
  esac
done

emit() { printf 'AUTO=%s\n' "$1"; exit 0; }

# Guard 1a: the env flag must be exactly 1.
if [ "${CJ_GOAL_E2E_AUTO:-}" != "1" ]; then
  emit inactive
fi

# Guard 1b: the sandbox marker must exist at the repo root.
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$REPO_ROOT" ] || [ ! -f "$REPO_ROOT/.cj-e2e-sandbox" ]; then
  emit inactive
fi

# Guard 2: build-gates-only allowlist. Anything outside {design-gate, qa-audit}
# is inactive — the seam can never match a ship/merge/land/deploy gate id.
case "$GATE" in
  design-gate)
    # The design-summary approval gate (CJ_goal_feature only) carries no digest;
    # under the active guard it auto-approves.
    emit continue
    ;;
  qa-audit)
    # Guard 3: green-only continue (todo_fix --quiet's predicate, generalized).
    # Continue ONLY when the digest is fully green (doc:ok AND test:ok);
    # ANY findings → halt. Never auto-waive.
    case "$DIGEST" in
      *doc:ok*) ;;
      *) emit halt ;;
    esac
    case "$DIGEST" in
      *test:ok*) ;;
      *) emit halt ;;
    esac
    emit continue
    ;;
  *)
    emit inactive
    ;;
esac
