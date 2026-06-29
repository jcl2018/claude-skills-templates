#!/usr/bin/env bash
# cj-contract-gate.sh — deterministic, agent-free contract gate (F000069 / S000117).
#
# The engine-only (Stage-1) subset of validate.sh, runnable with NO agent — so a
# CONSUMER repo can enforce its doc/test/workflow contract from a git pre-commit
# hook or a CI step. It composes the three deterministic engines
# (doc-spec.sh / test-spec.sh / workflow-spec.sh) and thresholds their dispositions:
#
#   doc-spec.sh --check-on-disk             HARD, EXCEPT a `declared-exists` finding
#                                           → a SOFT REMEDIATION note pointing at
#                                             /CJ_document-release (NOT a block)
#   test-spec.sh --validate                 HARD
#   test-spec.sh --check-coverage           HARD (rules-only ⇒ "inactive", not a finding)
#   workflow-spec.sh --validate             HARD (no-vanish / registry-completeness)
#   test-spec.sh --render-docs --check      HARD freshness (registry-present ⇒ checked)
#   workflow-spec.sh --render-docs --check  HARD freshness (registry-present ⇒ checked)
#
# REGISTRY-GATED throughout: an engine that reports `REGISTRY=absent` (a contract
# the repo has not adopted) is a clean SKIP (exit 0 for that check) — a repo is
# never blocked by a contract it does not carry. The gate exits NON-ZERO iff at
# least one HARD check finds a violation.
#
# Engine resolution (per check), reusing Story-3's stale-engine capability probe:
#   1. repo-local "<repo>/scripts/<engine>.sh" — but ONLY if CURRENT, proven by the
#      side-effect-free `--classify` probe emitting `GENERATION=`. A repo that
#      vendored an OLD engine (no --classify) would otherwise SHADOW the deployed
#      _cj-shared one and silently mis-gate.
#   2. the deployed shared home ($CJ_SHARED_SCRIPTS, default ~/.claude/_cj-shared/scripts).
#   3. (last resort) the gate's own dir — under _cj-shared the gate is co-located
#      with the engines, so BASH_SOURCE's dirname is the same shared home.
#
# Usage:
#   cj-contract-gate.sh [--repo <path>] [--quiet]
#     --repo <path>   run against <path> (default: cwd / git toplevel)
#     --quiet         suppress per-check PASS/SKIP lines on success (hook use);
#                     on FAILURE the findings + summary are still printed
#
# Output: a compact per-check line — PASS / FINDING / REMEDIATION / SKIP — plus an
# overall verdict. Exit 0 = clean (or soft-only); exit 1 = at least one HARD finding.

set -uo pipefail

# --- args ---
REPO=""
QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help)
      sed -n '2,40p' "$0"
      exit 0
      ;;
    *) shift ;;
  esac
done

# Resolve the target repo toplevel. A non-git target still works (the engines
# resolve their registry relative to REPO_ROOT); normalize to the git toplevel
# when available so `spec/` resolves at the repo root.
[ -n "$REPO" ] || REPO="$(pwd)"
_top=$(git -C "$REPO" rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$_top" ] && REPO="$_top"

# The shared home: env override → default. Also the gate's own dir as a last
# resort (under _cj-shared the gate sits alongside the engines).
SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- output helpers ---
SUMMARY=()            # collected per-check lines (printed at the end under --quiet)
HARD_FINDINGS=0       # count of HARD violations (drives the exit code)
SOFT_NOTES=0          # count of SOFT remediation notes (never blocks)
SKIPS=0               # count of registry-absent skips

emit() {
  # emit <line>  — buffer it; print immediately unless --quiet
  SUMMARY+=("$1")
  [ "$QUIET" -eq 0 ] && echo "$1"
}

# Resolve an engine basename (doc-spec | test-spec | workflow-spec) for $REPO.
# Echoes the resolved engine path (empty if none usable). Reuses the Story-3
# capability probe: a repo-local engine is used ONLY when its `--classify` emits
# GENERATION= (current); otherwise fall through to the shared home, then the
# gate's own dir.
resolve_engine() {
  engine="$1"
  repo_local="$REPO/scripts/${engine}.sh"
  shared="$SHARED/${engine}.sh"
  self_local="$SELF_DIR/${engine}.sh"
  if [ -x "$repo_local" ]; then
    gen=$(REPO_ROOT="$REPO" bash "$repo_local" --classify 2>/dev/null | awk -F= '/^GENERATION=/{print $1}')
    if [ "$gen" = "GENERATION" ]; then
      echo "$repo_local"
      return 0
    fi
    # Stale repo-local engine: fall through to the shared / self copy.
  fi
  if [ -x "$shared" ]; then echo "$shared"; return 0; fi
  if [ -x "$self_local" ]; then echo "$self_local"; return 0; fi
  echo ""
}

# Run an engine subcommand against $REPO, capturing stdout+stderr and the exit.
# Sets the globals _OUT (captured text) and _RC (exit code).
run_engine() {
  engine_path="$1"; shift
  _OUT=$(REPO_ROOT="$REPO" bash "$engine_path" "$@" 2>&1)
  _RC=$?
}

# Is the captured output a registry-absent skip? Both doc-spec/test-spec/
# workflow-spec emit the literal `REGISTRY=absent` on an unadopted contract.
is_registry_absent() {
  printf '%s\n' "$_OUT" | grep -q '^REGISTRY=absent$'
}

if [ "$QUIET" -eq 0 ]; then
  echo "=== cj-contract-gate (deterministic Stage-1 contract gate) ==="
  echo "repo: $REPO"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Check 1 — doc-spec.sh --check-on-disk
#   HARD, EXCEPT a `declared-exists` finding → a SOFT REMEDIATION (not a block).
#   The engine exits 1 on ANY finding (incl. declared-exists), so we cannot trust
#   its exit code alone — we parse the FINDING lines by check-id.
# ─────────────────────────────────────────────────────────────────────────────
DOC_ENGINE=$(resolve_engine doc-spec)
if [ -z "$DOC_ENGINE" ]; then
  emit "doc-spec/check-on-disk: SKIP — engine absent (no usable doc-spec.sh)"
  SKIPS=$((SKIPS + 1))
else
  run_engine "$DOC_ENGINE" --check-on-disk
  if is_registry_absent; then
    emit "doc-spec/check-on-disk: SKIP — REGISTRY=absent (contract not adopted)"
    SKIPS=$((SKIPS + 1))
  else
    # Split findings into declared-exists (SOFT) vs everything else (HARD).
    _hard=$(printf '%s\n' "$_OUT" | grep -c '^FINDING: stage1/' || true)
    _decl=$(printf '%s\n' "$_OUT" | grep -c '^FINDING: stage1/declared-exists' || true)
    _hard=$(( _hard - _decl ))
    if [ "$_decl" -gt 0 ]; then
      emit "doc-spec/declared-exists: REMEDIATION — ${_decl} declared doc(s) missing on disk; run /CJ_document-release to stub-scaffold them (soft — not a block)"
      SOFT_NOTES=$((SOFT_NOTES + 1))
    fi
    if [ "$_hard" -gt 0 ]; then
      emit "doc-spec/check-on-disk: FINDING — ${_hard} HARD doc-contract violation(s) (orphan / workflows-subfolder / root-declared / human-doc-ids):"
      printf '%s\n' "$_OUT" | grep '^FINDING: stage1/' | grep -v 'stage1/declared-exists' | while IFS= read -r _ln; do
        echo "    $_ln"
      done
      HARD_FINDINGS=$((HARD_FINDINGS + 1))
    elif [ "$_decl" -eq 0 ]; then
      emit "doc-spec/check-on-disk: PASS"
    fi
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Check 2 — test-spec.sh --validate (HARD)
# ─────────────────────────────────────────────────────────────────────────────
TEST_ENGINE=$(resolve_engine test-spec)
if [ -z "$TEST_ENGINE" ]; then
  emit "test-spec/validate: SKIP — engine absent (no usable test-spec.sh)"
  SKIPS=$((SKIPS + 1))
else
  run_engine "$TEST_ENGINE" --validate
  if is_registry_absent; then
    emit "test-spec/validate: SKIP — REGISTRY=absent (contract not adopted)"
    SKIPS=$((SKIPS + 1))
  elif [ "$_RC" -ne 0 ]; then
    emit "test-spec/validate: FINDING — registry does not validate:"
    printf '%s\n' "$_OUT" | sed 's/^/    /'
    HARD_FINDINGS=$((HARD_FINDINGS + 1))
  else
    emit "test-spec/validate: PASS"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Check 3 — test-spec.sh --check-coverage (HARD; rules-only ⇒ "inactive")
#   The engine exits 0 on a rules-only repo (coverage cross-check inactive) AND on
#   a clean coverage; it exits non-zero only on a genuine coverage finding.
# ─────────────────────────────────────────────────────────────────────────────
if [ -n "$TEST_ENGINE" ]; then
  run_engine "$TEST_ENGINE" --check-coverage
  if is_registry_absent; then
    emit "test-spec/check-coverage: SKIP — REGISTRY=absent (contract not adopted)"
    SKIPS=$((SKIPS + 1))
  elif printf '%s\n' "$_OUT" | grep -q 'coverage cross-check inactive'; then
    emit "test-spec/check-coverage: PASS (rules-only — coverage cross-check inactive)"
  elif [ "$_RC" -ne 0 ]; then
    emit "test-spec/check-coverage: FINDING — coverage cross-check failed:"
    printf '%s\n' "$_OUT" | grep -E '^(FINDING|REVERSE|FAIL)' | sed 's/^/    /'
    HARD_FINDINGS=$((HARD_FINDINGS + 1))
  else
    emit "test-spec/check-coverage: PASS"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Check 4 — workflow-spec.sh --validate (HARD — no-vanish / registry-completeness)
# ─────────────────────────────────────────────────────────────────────────────
WF_ENGINE=$(resolve_engine workflow-spec)
if [ -z "$WF_ENGINE" ]; then
  emit "workflow-spec/validate: SKIP — engine absent (no usable workflow-spec.sh)"
  SKIPS=$((SKIPS + 1))
else
  run_engine "$WF_ENGINE" --validate
  if is_registry_absent; then
    emit "workflow-spec/validate: SKIP — REGISTRY=absent (contract not adopted)"
    SKIPS=$((SKIPS + 1))
  elif [ "$_RC" -ne 0 ]; then
    emit "workflow-spec/validate: FINDING — registry does not validate (no-vanish / completeness):"
    printf '%s\n' "$_OUT" | sed 's/^/    /'
    HARD_FINDINGS=$((HARD_FINDINGS + 1))
  else
    emit "workflow-spec/validate: PASS"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Check 5 — test-spec.sh --render-docs --check (HARD freshness)
#   Registry-present ⇒ the generated test catalog must be in sync; registry-absent
#   ⇒ a clean SKIP.
# ─────────────────────────────────────────────────────────────────────────────
if [ -n "$TEST_ENGINE" ]; then
  run_engine "$TEST_ENGINE" --render-docs --check
  if is_registry_absent; then
    emit "test-spec/render-docs-check: SKIP — REGISTRY=absent (no generated surface)"
    SKIPS=$((SKIPS + 1))
  elif [ "$_RC" -ne 0 ]; then
    emit "test-spec/render-docs-check: FINDING — generated test catalog is stale (run: test-spec.sh --render-docs):"
    printf '%s\n' "$_OUT" | grep -E '^(FINDING|RENDER)' | sed 's/^/    /'
    HARD_FINDINGS=$((HARD_FINDINGS + 1))
  else
    emit "test-spec/render-docs-check: PASS"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Check 6 — workflow-spec.sh --render-docs --check (HARD freshness)
# ─────────────────────────────────────────────────────────────────────────────
if [ -n "$WF_ENGINE" ]; then
  run_engine "$WF_ENGINE" --render-docs --check
  if is_registry_absent; then
    emit "workflow-spec/render-docs-check: SKIP — REGISTRY=absent (no generated surface)"
    SKIPS=$((SKIPS + 1))
  elif [ "$_RC" -ne 0 ]; then
    emit "workflow-spec/render-docs-check: FINDING — generated workflow surface is stale (run: workflow-spec.sh --render-docs):"
    printf '%s\n' "$_OUT" | grep -E '^(FINDING|RENDER)' | sed 's/^/    /'
    HARD_FINDINGS=$((HARD_FINDINGS + 1))
  else
    emit "workflow-spec/render-docs-check: PASS"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Verdict
# ─────────────────────────────────────────────────────────────────────────────
if [ "$HARD_FINDINGS" -gt 0 ]; then
  # Under --quiet the per-check lines were suppressed; replay the buffered summary
  # so a blocked commit shows exactly which check(s) failed.
  if [ "$QUIET" -eq 1 ]; then
    echo "--- contract-gate summary (blocking findings) ---"
    for _l in "${SUMMARY[@]}"; do echo "$_l"; done
  fi
  echo "VERDICT: BLOCK — ${HARD_FINDINGS} hard contract finding(s) (soft notes: ${SOFT_NOTES}, skips: ${SKIPS})"
  exit 1
fi

# Clean (or soft-only): a hook stays silent on success; an interactive run prints
# the verdict. A soft remediation note (if any) was already surfaced above.
if [ "$QUIET" -eq 0 ]; then
  echo "VERDICT: PASS — no hard contract findings (soft notes: ${SOFT_NOTES}, skips: ${SKIPS})"
fi
exit 0
