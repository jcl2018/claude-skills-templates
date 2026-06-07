#!/usr/bin/env bash
set -euo pipefail

# cj-task-scaffold.sh — scaffold a `type: task` work-item from a FREE-TEXT topic
# for /CJ_goal_task (F000054).
#
# This is the no-design, no-TODOS-row sibling of
# skills/CJ_goal_todo_fix/scripts/todo_fix.sh's task-scaffold path. todo_fix
# scaffolds a T-task from an EXISTING TODOS.md row (it parses TODOS.md +
# /CJ_suggest); cj-task-scaffold scaffolds the SAME `type: task` work-item from a
# plain `--topic "<text>"` string instead — no TODOS.md parsing, no /CJ_suggest,
# no pre-existing row required. The downstream chain is identical
# (/CJ_implement-from-spec → /CJ_qa-work-item → /ship), so the produced dir must
# be byte-for-structure compatible with what todo_fix emits.
#
# THE HARD COMPLEXITY GATE (F000054 — the eligibility guardrail). Because there
# is no TODOS-row `(Pn, X)` suffix to read, the gate is keyword-based and it is a
# HARD REFUSAL (it HALTs, it does NOT warn-and-proceed): a topic that names a
# design-rework signal routes to /CJ_goal_feature; a topic that names a
# bug/investigation signal routes to /CJ_goal_defect. The gate runs BEFORE any
# ID claim or filesystem write, so a refused topic scaffolds nothing.
#
# DRIFT NOTE: the ID picker + domain/slug heuristics + template substitution
# below are mirrored from todo_fix.sh (which itself mirrors
# skills/CJ_scaffold-work-item/scaffold.md Step 5). Keep the three in sync until a
# shared scripts/cj-id-picker.sh extraction lands (tracked separately).
#
# Args:
#   --topic "<text>"   REQUIRED; the small-task description (the work-item scope)
#   --dry-run          preview the plan (gate verdict + planned T-ID/dir); no writes
#   --repo PATH        repo-root override (default: git toplevel)
#
# Stdout — three shapes, one fixed schema each:
#   (1) complexity refusal:
#         CJ_TASK_RESULT=too-complex
#         HALT_MARKER=[task-too-complex]
#         SUGGEST=/CJ_goal_feature | /CJ_goal_defect
#         REASON=<one-line why>
#       exit 2 (the caller HALTs).
#   (2) dry-run preview:
#         CJ_TASK_RESULT=dry-run  + a human-readable plan block
#       exit 0.
#   (3) success handoff:
#         CJ_TASK_HANDOFF_BEGIN
#         WORK_ITEM_DIR=<path>
#         T_ID=<id>
#         TOPIC=<topic>
#         IDEMPOTENT_SKIP=<0|1>
#         CJ_TASK_HANDOFF_END
#         CJ_TASK_RESULT=ok
#       exit 0.
#
# Exit codes: 0 (ok / dry-run), 1 (usage error), 2 (complexity refusal — caller halts).
#
# Security: no eval; the topic is only ever interpolated through sed/awk with the
# pipe-delimiter escaped, never executed. Template paths are resolved from a fixed
# 2-entry probe list (workbench source → deployed ~/.claude), never caller input.

# ---- arg parsing -------------------------------------------------------------

TOPIC=""
DRY_RUN=0
REPO_OVERRIDE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --topic)    TOPIC="${2:-}"; shift 2 ;;
    --topic=*)  TOPIC="${1#--topic=}"; shift ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --repo)     REPO_OVERRIDE="${2:-}"; shift 2 ;;
    *)          shift ;;  # ignore unknown args (caller may forward "$@")
  esac
done

if [ -z "$TOPIC" ]; then
  echo "Error: --topic \"<small task>\" is required." >&2
  exit 1
fi

# ---- resolve repo root -------------------------------------------------------

if [ -n "$REPO_OVERRIDE" ]; then
  REPO_ROOT="$REPO_OVERRIDE"
else
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Error: cj-task-scaffold.sh must run inside a git repo." >&2
    exit 1
  }
fi
cd "$REPO_ROOT"

WORKITEMS_DIR="work-items"

# Normalize the topic to a single trimmed line (the work-item title).
NAKED_TOPIC=$(printf '%s' "$TOPIC" | tr '\n\r' '  ' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')

# =============================================================================
# THE HARD COMPLEXITY GATE (runs BEFORE any ID claim / write)
# =============================================================================
#
# Two refusal classes, each a HARD HALT (exit 2) routing to the right verb:
#   - design-rework signals   → /CJ_goal_feature (this needs an /office-hours design)
#   - bug/investigation signals → /CJ_goal_defect (this needs root-cause first)
#   - coarse explicit-scale signals → /CJ_goal_feature (too big for a task)
#
# The design + bug keyword sets are the SAME ones todo_fix.sh Gate 5 uses (proven
# to avoid false positives — e.g. bare "design" is deliberately NOT matched, so
# "refine the design doc" is allowed; only "needs design"/"redesign"/"/office-hours"
# etc. trip it). A future size-ESTIMATE (file-count heuristic) is deferred; v1 is
# keyword-only + explicit-scale words.

emit_too_complex() {
  # $1 = SUGGEST verb, $2 = one-line reason
  echo "CJ_TASK_RESULT=too-complex"
  echo "HALT_MARKER=[task-too-complex]"
  echo "SUGGEST=$1"
  echo "REASON=$2"
  exit 2
}

# Design-rework signals → route to /CJ_goal_feature.
if printf '%s' "$NAKED_TOPIC" | grep -qiE '\b(needs design|figure out|redesign|re-?do|re-?ground|rewrite|rescope|spike|need to decide)\b|/office-hours\b'; then
  KW=$(printf '%s' "$NAKED_TOPIC" | grep -oiE '\b(needs design|figure out|redesign|re-?do|re-?ground|rewrite|rescope|spike|need to decide)\b|/office-hours\b' | head -1)
  emit_too_complex "/CJ_goal_feature" "topic names a design-rework signal ('$KW') — design it via /office-hours first"
fi

# Bug / investigation signals → route to /CJ_goal_defect.
if printf '%s' "$NAKED_TOPIC" | grep -qiE '\b(root[ -]?cause|debug|reproduce|regression|stack ?trace|traceback|investigate|why (is|does|are|did))\b'; then
  KW=$(printf '%s' "$NAKED_TOPIC" | grep -oiE '\b(root[ -]?cause|debug|reproduce|regression|stack ?trace|traceback|investigate|why (is|does|are|did))\b' | head -1)
  emit_too_complex "/CJ_goal_defect" "topic names a bug/investigation signal ('$KW') — root-cause it via /CJ_goal_defect"
fi

# Coarse explicit-scale signals (a topic that announces it is big) → /CJ_goal_feature.
if printf '%s' "$NAKED_TOPIC" | grep -qiE '\b(epic|overhaul|end[ -]to[ -]end feature|large refactor|multi-?(skill|file|phase|step) (feature|change|refactor))\b'; then
  KW=$(printf '%s' "$NAKED_TOPIC" | grep -oiE '\b(epic|overhaul|end[ -]to[ -]end feature|large refactor|multi-?(skill|file|phase|step) (feature|change|refactor))\b' | head -1)
  emit_too_complex "/CJ_goal_feature" "topic announces a large change ('$KW') — too big for a task; build it via /CJ_goal_feature"
fi

# =============================================================================
# Idempotency: reuse an existing T-task scaffolded for this same topic.
# =============================================================================
#
# Footer shape: `<!-- Source: /CJ_goal_task: <NAKED_TOPIC> -->`. A re-run with the
# same topic reuses the existing dir (mirrors todo_fix's TODOS-row footer check).

FOOTER="<!-- Source: /CJ_goal_task: ${NAKED_TOPIC} -->"
EXISTING_DIR=""
if [ -d "$WORKITEMS_DIR/tasks" ]; then
  EXISTING_MATCH=$(grep -rlF "$FOOTER" "$WORKITEMS_DIR/tasks/" 2>/dev/null | head -1 || true)
  [ -n "$EXISTING_MATCH" ] && EXISTING_DIR=$(dirname "$EXISTING_MATCH")
fi

if [ -n "$EXISTING_DIR" ]; then
  EXIST_TRACKER=$(find "$EXISTING_DIR" -maxdepth 1 -name "T*_TRACKER.md" 2>/dev/null | head -1)
  EXIST_ID=$(basename "${EXIST_TRACKER:-T000000_TRACKER.md}" | sed 's/_TRACKER\.md$//')
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "CJ_TASK_RESULT=dry-run"
    echo "DRY RUN — no writes will happen."
    echo "Complexity gate:  PASS"
    echo "Idempotent reuse: $EXISTING_DIR (already scaffolded for this topic)"
    echo "T-ID:             $EXIST_ID"
    exit 0
  fi
  echo "CJ_TASK_HANDOFF_BEGIN"
  echo "WORK_ITEM_DIR=$EXISTING_DIR"
  echo "T_ID=$EXIST_ID"
  echo "TOPIC=$NAKED_TOPIC"
  echo "IDEMPOTENT_SKIP=1"
  echo "CJ_TASK_HANDOFF_END"
  echo "CJ_TASK_RESULT=ok"
  exit 0
fi

# =============================================================================
# ID picker — verbatim from todo_fix.sh (DRIFT NOTE above).
# =============================================================================

PREFIX="T"
LOCAL_MAX=$(find work-items -name "${PREFIX}*_TRACKER.md" 2>/dev/null \
  | sed "s|.*/${PREFIX}\([0-9]*\)_.*|\1|" \
  | sort -un | tail -1)
LOCAL_MAX=${LOCAL_MAX:-0}

PR_MAX=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  for PR_NUM in $(gh pr list --state open --base main --limit 5 --json number -q '.[].number' 2>/dev/null || true); do
    while IFS= read -r CLAIMED; do
      case "$CLAIMED" in
        ''|*[!0-9]*) continue ;;
      esac
      [ "$CLAIMED" -gt "$PR_MAX" ] 2>/dev/null && PR_MAX="$CLAIMED"
    done < <(
      gh pr view "$PR_NUM" --json files -q '.files[].path' 2>/dev/null \
        | grep -oE "${PREFIX}[0-9]{6}_[^/]*_TRACKER\.md$" \
        | sed "s|^${PREFIX}\([0-9]*\)_.*|\1|"
    )
  done
fi

HIGHEST=$LOCAL_MAX
[ "$PR_MAX" -gt "$HIGHEST" ] 2>/dev/null && HIGHEST=$PR_MAX
NEW_ID=$(printf "${PREFIX}%06d" $((10#$HIGHEST + 1)))

# ---- domain inference (heuristic on the topic; default ops) -------------------

DOMAIN="ops"
if printf '%s' "$NAKED_TOPIC" | grep -qE 'skills/CJ_|templates/CJ_personal-workflow/|\bskill\b'; then
  DOMAIN="skills"
elif printf '%s' "$NAKED_TOPIC" | grep -qE 'work-copilot'; then
  DOMAIN="work-copilot"
elif printf '%s' "$NAKED_TOPIC" | grep -qE 'scripts/|setup-hooks|validate\.sh|test\.sh|test-deploy\.sh|eval\.sh'; then
  DOMAIN="ops"
fi

# ---- slug generation (lowercase; non-alnum → _; collapse; ≤40 at word boundary)

SLUG=$(printf '%s' "$NAKED_TOPIC" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/_/g' \
  | sed -E 's/_+/_/g' \
  | sed -E 's/^_+|_+$//g')
if [ "${#SLUG}" -gt 40 ]; then
  TRUNCATED=$(printf '%s' "$SLUG" | cut -c1-40 | sed -E 's/_[^_]*$//')
  if [ -z "$TRUNCATED" ]; then
    SLUG=$(printf '%s' "$SLUG" | cut -c1-40)
  else
    SLUG="$TRUNCATED"
  fi
fi
[ -z "$SLUG" ] && SLUG="task"

WORK_ITEM_DIR="work-items/tasks/${DOMAIN}/${NEW_ID}_${SLUG}"

# ---- dry-run: print the plan, write nothing ----------------------------------

if [ "$DRY_RUN" -eq 1 ]; then
  echo "CJ_TASK_RESULT=dry-run"
  echo "DRY RUN — no writes will happen."
  echo ""
  echo "Topic:            $NAKED_TOPIC"
  echo "Complexity gate:  PASS"
  echo "Domain:           $DOMAIN"
  echo "Slug:             $SLUG"
  echo "Planned T-ID:     $NEW_ID"
  echo "Planned dir:      $WORK_ITEM_DIR"
  echo "Dispatch chain:   /CJ_implement-from-spec <dir> → /CJ_qa-work-item <dir> → /ship → STOP at PR"
  exit 0
fi

# =============================================================================
# Scaffold the T-task (TRACKER + test-plan) — mirrors todo_fix.sh.
# =============================================================================

mkdir -p "$WORK_ITEM_DIR"

# Resolve template paths (workbench source → deployed ~/.claude).
TPL_TRACKER=""
TPL_TEST_PLAN=""
for p in \
  "$REPO_ROOT/templates/CJ_personal-workflow/tracker-task.md" \
  "$HOME/.claude/templates/CJ_personal-workflow/tracker-task.md"; do
  if [ -f "$p" ]; then TPL_TRACKER="$p"; break; fi
done
for p in \
  "$REPO_ROOT/templates/CJ_personal-workflow/doc-test-plan.md" \
  "$HOME/.claude/templates/CJ_personal-workflow/doc-test-plan.md"; do
  if [ -f "$p" ]; then TPL_TEST_PLAN="$p"; break; fi
done
if [ -z "$TPL_TRACKER" ]; then
  echo "CJ_TASK_RESULT=scaffold-error"
  echo "REASON=tracker-task.md template not found (workbench source nor ~/.claude)"
  exit 1
fi
if [ -z "$TPL_TEST_PLAN" ]; then
  echo "CJ_TASK_RESULT=scaffold-error"
  echo "REASON=doc-test-plan.md template not found (workbench source nor ~/.claude)"
  exit 1
fi

TODAY=$(date +%Y-%m-%d)
AUTHOR=$(git config user.name 2>/dev/null || echo "chjiang")
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# Write TRACKER.md (template substitution — mirrors todo_fix.sh).
TRACKER_OUT="$WORK_ITEM_DIR/${NEW_ID}_TRACKER.md"
sed \
  -e "s|{TASK_NAME}|${NAKED_TOPIC//|/\\|}|g" \
  -e "s|{TASK_ID}|${NEW_ID}|g" \
  -e "s|{YYYY-MM-DD}|${TODAY}|g" \
  -e "s|{PARENT_ID}||g" \
  -e "s|{REPO_PATH}|${REPO_ROOT//|/\\|}|g" \
  -e "s|{BRANCH_NAME}|${BRANCH//|/\\|}|g" \
  -e "s|{slug}|${SLUG}|g" \
  "$TPL_TRACKER" > "$TRACKER_OUT"

# Inject the topic as the scope into the ## Insights section (the topic IS the
# scope for a free-text task — no TODOS body to copy). awk getline from a tmpfile
# to tolerate any punctuation in the topic.
TRACKER_TMP=$(mktemp)
BODY_TMP=$(mktemp)
printf 'Scope (from /CJ_goal_task topic): %s\n' "$NAKED_TOPIC" > "$BODY_TMP"
awk -v body_file="$BODY_TMP" '
  /^## Insights[[:space:]]*$/ {
    print $0
    print ""
    print "<!-- Auto-injected from the /CJ_goal_task topic -->"
    print ""
    while ((getline line < body_file) > 0) print line
    close(body_file)
    print ""
    next
  }
  { print }
' "$TRACKER_OUT" > "$TRACKER_TMP" && mv "$TRACKER_TMP" "$TRACKER_OUT"
rm -f "$BODY_TMP"
printf '\n%s\n' "$FOOTER" >> "$TRACKER_OUT"

# Replace the template's placeholder Todos row with a real starter row.
TRACKER_TMP=$(mktemp)
awk -v h="$NAKED_TOPIC" '
  /^- \[ \] \{todo\}$/ { print "- [ ] Implement: " h; next }
  { print }
' "$TRACKER_OUT" > "$TRACKER_TMP" && mv "$TRACKER_TMP" "$TRACKER_OUT"

# Replace the template's placeholder Created log line.
TRACKER_TMP=$(mktemp)
awk -v t="$TODAY" -v h="$NAKED_TOPIC" '
  /^- \{YYYY-MM-DD\}: Created\./ { print "- " t ": Created. Auto-scaffolded by /CJ_goal_task from topic: " h; next }
  /^- [0-9]{4}-[0-9]{2}-[0-9]{2}: Created\. \{brief scope from parent work item\}$/ { print "- " t ": Created. Auto-scaffolded by /CJ_goal_task from topic: " h; next }
  { print }
' "$TRACKER_OUT" > "$TRACKER_TMP" && mv "$TRACKER_TMP" "$TRACKER_OUT"

# Write test-plan.md (template substitution + real starter row).
TEST_PLAN_OUT="$WORK_ITEM_DIR/test-plan.md"
sed \
  -e "s|{ITEM_ID}|${NEW_ID}|g" \
  -e "s|{ITEM_NAME}|${NAKED_TOPIC//|/\\|}|g" \
  -e "s|{YYYY-MM-DD}|${TODAY}|g" \
  -e "s|{author}|${AUTHOR//|/\\|}|g" \
  "$TPL_TEST_PLAN" > "$TEST_PLAN_OUT"

TEST_TMP=$(mktemp)
awk -v h="${NAKED_TOPIC//|/\\|}" '
  /^\| 1 \| \{original bug scenario\}/ {
    print "| 1 | Manual verification: " h " | Apply the change and exercise it | Behavior matches the topic description | Pending |"
    next
  }
  /^\| 2 \| \{related scenario\}/ { next }
  /^\| \{OS \+ config\} \|/ { print "| local macOS | main / current branch | Pending |"; next }
  /^- \[ \] \{additional verification specific to this fix\}$/ { next }
  { print }
' "$TEST_PLAN_OUT" > "$TEST_TMP" && mv "$TEST_TMP" "$TEST_PLAN_OUT"

# Post-scaffold boundary check is handled downstream: /CJ_implement-from-spec +
# /CJ_qa-work-item each run the portable `/CJ_personal-workflow check` at their
# boundaries (works in any repo) — same contract as todo_fix (T000028).

echo "CJ_TASK_HANDOFF_BEGIN"
echo "WORK_ITEM_DIR=$WORK_ITEM_DIR"
echo "T_ID=$NEW_ID"
echo "TOPIC=$NAKED_TOPIC"
echo "IDEMPOTENT_SKIP=0"
echo "CJ_TASK_HANDOFF_END"
echo "CJ_TASK_RESULT=ok"
exit 0
