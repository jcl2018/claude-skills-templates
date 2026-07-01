#!/usr/bin/env bash
# Local happy-path E2E harness for the cj_goal workflows (F000071 Part B).
#
# Runs a REAL /CJ_goal_task build in an isolated sandbox, driven unattended via
# the Part-A build-gate auto-answer seam (scripts/cj-e2e-gate.sh), stops at the
# /ship boundary (a LOCAL bare origin defeats `gh pr create`), and writes a
# materialized report distinguishing DETERMINISTIC checks from the claude --print
# run (tests/e2e-local/reports/<verb>-<UTC-ts>.md + .json).
#
# LOCAL-ONLY. Gated on CJ_E2E_LOCAL=1 AND gstack + ANTHROPIC_API_KEY + claude +
# gh present. With the flag unset or any prerequisite missing it SKIPs (exit 0),
# so CI and a normal `test.sh` stay green/unchanged and never touch a model.
#
# SAFETY: the harness activates ONLY the Part-A seam, whose allowlist is
# {design-gate, qa-audit} — it can NEVER auto-answer a ship/merge/deploy gate.
# The sandbox's LOCAL bare origin is the sole auto-ship backstop (task's /ship
# diff-review AUQ is already suppressed, so no-remote is the load-bearing stop).
#
# Usage:
#   CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh [--topic "<topic>"] [--budget <usd>] [--dry-run]
#
# Exit: 0 = SKIP (flag/prereq missing) OR sandbox SUCCESS (reached >= qa-audit, no PR).
#       non-zero = a real failure (infra error before qa-audit, or a real PR opened).

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH='' cd "$SCRIPT_DIR/.." && pwd)
LIB_DIR="$REPO_ROOT/tests/e2e-local/lib"
CASE_TOPIC_FILE="$REPO_ROOT/tests/e2e-local/CJ_goal_task/happy-build/topic.txt"
REPORTS_DIR="$REPO_ROOT/tests/e2e-local/reports"

TOPIC=""
BUDGET="${E2E_BUDGET_USD:-8.00}"
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --topic)  TOPIC="${2:-}"; shift 2 ;;
    --topic=*) TOPIC="${1#--topic=}"; shift ;;
    --budget) BUDGET="${2:-}"; shift 2 ;;
    --budget=*) BUDGET="${1#--budget=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "e2e-local: unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---- Pre-flight gate: SKIP (exit 0) unless the flag AND all prereqs hold ----
# This block is what CI + a normal test.sh exercise; it must never reach claude.
skip() { echo "SKIP: e2e-local — $1 (this harness is local-only; set CJ_E2E_LOCAL=1 with gstack + ANTHROPIC_API_KEY + claude + gh to run)"; exit 0; }

[ "${CJ_E2E_LOCAL:-}" = "1" ] || skip "CJ_E2E_LOCAL is not set"

_missing=""
[ -d "$HOME/.claude/skills/gstack" ] || _missing="$_missing gstack(/ship)"
[ -n "${ANTHROPIC_API_KEY:-}" ]     || _missing="$_missing ANTHROPIC_API_KEY"
command -v claude >/dev/null 2>&1   || _missing="$_missing claude"
command -v gh     >/dev/null 2>&1   || _missing="$_missing gh"
[ -x "$REPO_ROOT/scripts/cj-e2e-gate.sh" ] || _missing="$_missing cj-e2e-gate.sh(Part-A-seam)"
if [ -n "$_missing" ]; then
  skip "missing prerequisites:$_missing"
fi

# Resolve the topic (arg > case file first non-comment line).
if [ -z "$TOPIC" ] && [ -f "$CASE_TOPIC_FILE" ]; then
  TOPIC=$(grep -vE '^[[:space:]]*(#|$)' "$CASE_TOPIC_FILE" | head -1)
fi
[ -n "$TOPIC" ] || { echo "e2e-local: no topic (pass --topic or populate $CASE_TOPIC_FILE)" >&2; exit 2; }

TS="${E2E_TS:-$(date -u +%Y%m%dT%H%M%SZ)}"

# shellcheck source=tests/e2e-local/lib/sandbox.sh
. "$LIB_DIR/sandbox.sh"
# shellcheck source=tests/e2e-local/lib/report.sh
. "$LIB_DIR/report.sh"

if [ "$DRY_RUN" = "1" ]; then
  echo "=== e2e-local DRY-RUN ==="
  echo "topic:   $TOPIC"
  echo "budget:  \$$BUDGET"
  echo "report:  $REPORTS_DIR/task-$TS.md (+ .json)"
  echo "plan:    provision sandbox -> claude --print /CJ_goal_task (CJ_GOAL_E2E_AUTO=1) -> assert /ship boundary -> render report -> teardown"
  echo "(no sandbox provisioned, no claude invoked, no report written)"
  exit 0
fi

echo "[E2E-LOCAL] provisioning sandbox from $REPO_ROOT ..."
SANDBOX=$(e2e_sandbox_provision "$REPO_ROOT") || { echo "e2e-local: sandbox provision failed" >&2; exit 1; }
trap 'e2e_sandbox_teardown "$SANDBOX"' EXIT INT TERM
echo "[E2E-LOCAL] sandbox: $SANDBOX"

HEAD_SHA=$(git -C "$SANDBOX" rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH=$(git -C "$SANDBOX" symbolic-ref --short HEAD 2>/dev/null || echo "main")

# Snapshot pre-run task dirs so a NEW one is real evidence that scaffold ran.
_tasks_before=$(find "$SANDBOX/work-items/tasks" -maxdepth 1 -type d 2>/dev/null | sort || true)

# The deterministic seam verdicts (these rows are asserted in shell, not by the model).
SEAM_QA_AUDIT=$(CJ_GOAL_E2E_AUTO=1 bash "$SANDBOX/scripts/cj-e2e-gate.sh" --gate qa-audit --digest "doc:ok,test:ok" 2>/dev/null | sed -n 's/^AUTO=//p' | head -1)
SEAM_NONALLOW=$(CJ_GOAL_E2E_AUTO=1 bash "$SANDBOX/scripts/cj-e2e-gate.sh" --gate ship 2>/dev/null | sed -n 's/^AUTO=//p' | head -1)

echo "[E2E-LOCAL] running /CJ_goal_task for real (budget \$$BUDGET) — this drives a live model build ..."
_run_log="$SANDBOX/.e2e-run.log"
# Run the real build INSIDE the sandbox: the marker + CJ_GOAL_E2E_AUTO=1 arm the
# Part-A seam so the qa-audit gate auto-continues; /ship's gate is NEVER auto-answered.
(
  cd "$SANDBOX" || exit 1
  CJ_GOAL_E2E_AUTO=1 claude -p "/CJ_goal_task --no-worktree $TOPIC" \
    --print \
    --plugin-dir "$SANDBOX/skills" \
    --add-dir "$SANDBOX" \
    --max-budget-usd "$BUDGET" \
    --no-session-persistence \
    --permission-mode bypassPermissions \
    --allowedTools "Bash,Read,Glob,Grep,Write,Edit,Agent,Skill" 2>&1
) | tee "$_run_log" || true

# ---- Collect post-run evidence (grep the sandbox — real, not a template) ----
_tasks_after=$(find "$SANDBOX/work-items/tasks" -maxdepth 1 -type d 2>/dev/null | sort || true)
if [ "$_tasks_before" != "$_tasks_after" ]; then TASK_DIR_CREATED="yes"; else TASK_DIR_CREATED="no"; fi

if [ -n "$(git -C "$SANDBOX" log --oneline "origin/$BRANCH..HEAD" 2>/dev/null)" ] \
   || [ -n "$(git -C "$SANDBOX" status --porcelain 2>/dev/null)" ]; then
  DIFF_NONEMPTY="yes"
else
  DIFF_NONEMPTY="no"
fi

# A feature/task branch pushed to the bare origin (any ref beyond the base branch).
if git -C "$SANDBOX" ls-remote --heads origin 2>/dev/null | grep -qvE "refs/heads/$BRANCH\$"; then
  BRANCH_PUSHED="yes"
elif [ -n "$(git -C "$SANDBOX" log --oneline "origin/$BRANCH..HEAD" 2>/dev/null)" ]; then
  # The build committed but the push may have gone to the same branch on the bare origin.
  BRANCH_PUSHED="yes"
else
  BRANCH_PUSHED="no"
fi

# No real PR: the run log must not contain a github.com PR URL.
if grep -qE 'https://github\.com/[^ ]+/pull/[0-9]+' "$_run_log" 2>/dev/null; then
  PR_BLOCKED="no"
else
  PR_BLOCKED="yes"
fi

# The end_state: last recognized terminal marker in the run log.
END_STATE=$(grep -oE 'halted_at_ship|halted_at_qa_audit|green_pr_opened|halted_at_[a-z_]+' "$_run_log" 2>/dev/null | tail -1)
[ -n "$END_STATE" ] || END_STATE=""

# ---- Render the materialized report ----
_ev="$SANDBOX/.e2e-evidence.txt"
{
  printf 'topic=%s\n' "$TOPIC"
  printf 'sandbox=%s\n' "$SANDBOX"
  printf 'head_sha=%s\n' "$HEAD_SHA"
  printf 'end_state=%s\n' "$END_STATE"
  printf 'task_dir_created=%s\n' "$TASK_DIR_CREATED"
  printf 'diff_nonempty=%s\n' "$DIFF_NONEMPTY"
  printf 'branch_pushed=%s\n' "$BRANCH_PUSHED"
  printf 'pr_blocked=%s\n' "$PR_BLOCKED"
  printf 'seam_qa_audit=%s\n' "${SEAM_QA_AUDIT:-}"
  printf 'seam_nonallowlisted=%s\n' "${SEAM_NONALLOW:-}"
  printf 'budget=$%s\n' "$BUDGET"
  printf 'duration=%s\n' "n/a"
  printf 'tokens=%s\n' "n/a"
} > "$_ev"

mkdir -p "$REPORTS_DIR"
REPORT_MD=$(e2e_report_render "$REPORTS_DIR" "task" "$TS" "$_ev")
echo ""
echo "[E2E-LOCAL] report: $REPORT_MD"
echo "[E2E-LOCAL] report: ${REPORT_MD%.md}.json"

# ---- Boundary verdict: the /ship-boundary pair is the sandbox SUCCESS signal ----
if [ "$BRANCH_PUSHED" = "yes" ] && [ "$PR_BLOCKED" = "yes" ] \
   && { [ "$END_STATE" = "halted_at_ship" ] || [ "$END_STATE" = "halted_at_qa_audit" ]; }; then
  echo "[E2E-LOCAL] PASS — reached the $END_STATE boundary, no real PR (sandbox)."
  exit 0
fi
echo "[E2E-LOCAL] INCONCLUSIVE — see $REPORT_MD (some evidence was not found; end_state=${END_STATE:-none})." >&2
exit 1
