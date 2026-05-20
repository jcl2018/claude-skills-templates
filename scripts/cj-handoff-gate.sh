#!/usr/bin/env bash
# cj-handoff-gate.sh — GATE #2 helper for /CJ_goal_auto's --auto-merge-small-diffs path.
#
# Invoked by /CJ_goal_run/run.md at the post-/ship / pre-/land-and-deploy seam
# (only when --handoff was passed). Exit 0 = proceed to merge; exit non-zero =
# halt for human review.
#
# All checks are deterministic and exit-coded. No LLM judgment.
#
# Conditions for exit 0 (ALL must hold):
#   1. Frozen-base denylist clean
#        - BASE = git merge-base origin/main HEAD (after git fetch origin main)
#        - git diff --no-renames --raw -z $BASE HEAD
#          - No raw-mode entry touches a denylisted glob on EITHER old or new path
#          - No raw-mode entry has mode 120000 (new symlink) added/changed
#   2. Size cap
#        - files <= MAX_FILES (default 5)
#        - added lines <= MAX_LINES (default 120)
#   3. Phase-2 markers all green
#        - PIPELINE_END_STATE=green
#        - SMOKE=pass
#        - E2E=pass
#        - All PHASE2_GATES checked
#      Sourced from $PHASE2_MARKERS_FILE (one KV per line, KEY=VAL).
#      Missing file OR any unexpected value => fail-closed.
#
# Stdout (always emitted, one line per field, KEY=VALUE):
#   BASE=<sha>
#   FILES=<count>
#   LINES=<count>
#   DENYLIST=<clean|hit:<path>|symlink:<path>|rename-denylist:<oldpath>->>>><newpath>>
#   PIPELINE_END_STATE=<value>
#   SMOKE=<value>
#   E2E=<value>
#   PHASE2_GATES=<value>
#   GATE_RESULT=<auto-approved|halted_at_gate2>
#
# Stderr (only on failure):
#   [gate2-<reason>] one-line description
#
# Args:
#   --max-files N           override MAX_FILES (default 5)
#   --max-lines N           override MAX_LINES (default 120)
#   --markers-file PATH     PHASE2_MARKERS_FILE override (default:
#                           ${GSTACK_PHASE2_MARKERS_FILE:-$repo_root/.gstack/phase2-markers.txt})
#   --base SHA              skip git fetch + merge-base; use SHA directly (test hook)
#   --diff-from-file PATH   read raw-mode `git diff` output from PATH instead of
#                           invoking git (test fixture hook). When set, --base is
#                           still required for the BASE= stdout field.
#   --numstat-from-file PATH read numstat diff output from PATH instead of git
#                           (test fixture hook). Pairs with --diff-from-file.

set -u  # strict on undefined vars; do NOT set -e (we want to handle errors explicitly)

# --- defaults ---
MAX_FILES=5
MAX_LINES=120
MARKERS_FILE=""
BASE_OVERRIDE=""
DIFF_FROM_FILE=""
NUMSTAT_FROM_FILE=""

# Denylist globs (rename/symlink-safe via `git diff --no-renames --raw`).
# Tested in scripts/test.sh tests 1, 3, 5.
DENYLIST_GLOBS=(
  # Reused sensitive surfaces (mirror /CJ_personal-pipeline Step 5.1)
  'skills-catalog.json'
  'personal-artifact-manifests.json'
  'company-artifact-manifests.json'
  'templates/personal-workflow/'
  'templates/company-workflow/'
  'scripts/validate.sh'
  'scripts/test.sh'
  'scripts/test-deploy.sh'
  '.git/hooks/'
  # Net-new test/assertion surfaces (CEO finding — block test-weakening diffs)
  'tests/'
  'fixtures/'
  # Sibling skill SKILL.md files (workflow / pipeline skills are infrastructure)
  'skills/CJ_personal-workflow/'
  'skills/CJ_personal-pipeline/'
  'skills/CJ_goal_run/SKILL.md'
  'skills/CJ_goal_auto/SKILL.md'
  'skills/CJ_implement-from-spec/'
  'skills/CJ_qa-work-item/'
  'skills/CJ_scaffold-work-item/'
  # The gate helper itself
  'scripts/cj-handoff-gate.sh'
)

# Test-script glob match (handled separately so it can include glob chars).
# Matched via case-pattern against each diff entry path.
DENYLIST_PATTERNS=(
  'scripts/*test*.sh'
  'scripts/*test*.py'
  '*fixture*'
  '*.golden'
)

# --- arg parse ---
while [ $# -gt 0 ]; do
  case "$1" in
    --max-files) MAX_FILES="$2"; shift 2 ;;
    --max-lines) MAX_LINES="$2"; shift 2 ;;
    --markers-file) MARKERS_FILE="$2"; shift 2 ;;
    --base) BASE_OVERRIDE="$2"; shift 2 ;;
    --diff-from-file) DIFF_FROM_FILE="$2"; shift 2 ;;
    --numstat-from-file) NUMSTAT_FROM_FILE="$2"; shift 2 ;;
    -h|--help) sed -n '1,/^set -u/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "[gate2-arg-error] unknown arg '$1'" >&2; exit 2 ;;
  esac
done

# --- resolve markers file default ---
if [ -z "$MARKERS_FILE" ]; then
  _repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
  MARKERS_FILE="${GSTACK_PHASE2_MARKERS_FILE:-$_repo_root/.gstack/phase2-markers.txt}"
fi

# --- helper: emit stdout KV line ---
emit() { printf '%s=%s\n' "$1" "$2"; }

# --- step 1: resolve BASE (frozen merge-base) ---
if [ -n "$BASE_OVERRIDE" ]; then
  BASE="$BASE_OVERRIDE"
else
  # Best-effort fetch; do NOT fail if offline (the merge-base still resolves
  # against the local origin/main ref).
  git fetch origin main 2>/dev/null || true
  BASE=$(git merge-base origin/main HEAD 2>/dev/null || echo "")
  if [ -z "$BASE" ]; then
    emit BASE ""
    emit GATE_RESULT halted_at_gate2
    echo "[gate2-base-resolve-failed] could not resolve git merge-base origin/main HEAD" >&2
    exit 1
  fi
fi
emit BASE "$BASE"

# --- step 2: file / line counts ---
if [ -n "$NUMSTAT_FROM_FILE" ]; then
  _numstat=$(cat "$NUMSTAT_FROM_FILE")
else
  _numstat=$(git diff --numstat "$BASE" HEAD 2>/dev/null)
fi
LINES=$(echo "$_numstat" | awk '{a+=$1+0} END{print a+0}')
emit LINES "$LINES"

# Read the raw-mode NUL-separated diff into a temp file (never into a shell
# variable — bash command substitution strips embedded NULs and would silently
# corrupt the multi-entry count).
_RAW_FILE=$(mktemp -t cjga-raw-XXXXX)
trap 'rm -f "$_RAW_FILE"' EXIT
if [ -n "$DIFF_FROM_FILE" ]; then
  cp "$DIFF_FROM_FILE" "$_RAW_FILE"
else
  # --no-renames: surface a rename of a denylisted file as add+delete so the
  # delete trips the denylist on the OLD path.
  # --raw -z: NUL-separated raw mode with mode bits (so we can detect 120000 symlinks).
  git diff --no-renames --raw -z "$BASE" HEAD 2>/dev/null > "$_RAW_FILE" || true
fi

# Count files: every NUL-terminated record after the metadata. The raw -z
# format is: ":mode_a mode_b sha_a sha_b status\tpath" then NUL.
# For added/deleted/modified (A/D/M), one record per file. We count records
# (not paths) which is equivalent for non-rename mode.
if [ -s "$_RAW_FILE" ]; then
  # awk-based NUL-aware counter: count records by counting status letters at
  # the start of each metadata field. Each entry starts with ":".
  FILES=$(tr '\0' '\n' < "$_RAW_FILE" | awk '/^:/{c++} END{print c+0}')
else
  FILES=0
fi
emit FILES "$FILES"

# --- step 3: denylist + symlink scan ---
DENYLIST_RESULT="clean"

# Walk the raw entries. With --no-renames the format is one entry per file:
#   :mode_a mode_b sha_a sha_b STATUS\tPATH\0
# (no rename src/dst, since --no-renames forces R->add+delete decomposition).
#
# We need: STATUS (A/M/D/T/C — the latter two for typechange and copy edge cases)
# and PATH (single path under --no-renames).
#
# tr '\0' '\n' then iterate, awk to split metadata + path.
_check_denylist_paths() {
  local path="$1" mode_b="$2" status="$3"

  # Symlink check: mode_b == 120000 means the new mode is symlink. Reject on any
  # A/M/T touching a symlink (added or changed to symlink).
  if [ "$mode_b" = "120000" ] && [ "$status" != "D" ]; then
    DENYLIST_RESULT="symlink:$path"
    return 1
  fi

  # Denylist literal-substring check (DENYLIST_GLOBS are file paths or dir
  # prefixes; we match by substring at path start OR by directory containment).
  local g
  for g in "${DENYLIST_GLOBS[@]}"; do
    case "$path" in
      "$g"|"$g"*)
        DENYLIST_RESULT="hit:$path"
        return 1
        ;;
    esac
  done

  # Denylist glob-pattern check (DENYLIST_PATTERNS use shell glob chars).
  local p
  for p in "${DENYLIST_PATTERNS[@]}"; do
    # shellcheck disable=SC2254  # intentional glob match
    case "$path" in
      $p)
        DENYLIST_RESULT="hit:$path"
        return 1
        ;;
    esac
  done

  return 0
}

if [ -s "$_RAW_FILE" ]; then
  # NUL-separated entries — stream via process substitution (NOT a pipeline)
  # so the while loop runs in the parent shell and DENYLIST_RESULT assignments
  # survive after the loop exits.
  # Each entry is metadata + TAB + path; under --no-renames, no extra NUL within.
  while IFS= read -r _entry; do
    [ -z "$_entry" ] && continue
    # Parse: ":mode_a mode_b sha_a sha_b STATUS\tPATH"
    _meta=$(printf '%s' "$_entry" | cut -d'	' -f1)
    _path=$(printf '%s' "$_entry" | cut -d'	' -f2-)
    _mode_b=$(printf '%s' "$_meta" | awk '{print $2}')
    _status=$(printf '%s' "$_meta" | awk '{print $5}')
    if ! _check_denylist_paths "$_path" "$_mode_b" "$_status"; then
      break
    fi
  done < <(tr '\0' '\n' < "$_RAW_FILE")
fi
emit DENYLIST "$DENYLIST_RESULT"

# --- step 4: Phase-2 markers ---
PIPELINE_END_STATE=""
SMOKE=""
E2E=""
PHASE2_GATES=""

if [ -f "$MARKERS_FILE" ]; then
  while IFS='=' read -r _k _v; do
    case "$_k" in
      PIPELINE_END_STATE) PIPELINE_END_STATE="$_v" ;;
      SMOKE) SMOKE="$_v" ;;
      E2E) E2E="$_v" ;;
      PHASE2_GATES) PHASE2_GATES="$_v" ;;
    esac
  done < "$MARKERS_FILE"
fi
emit PIPELINE_END_STATE "$PIPELINE_END_STATE"
emit SMOKE "$SMOKE"
emit E2E "$E2E"
emit PHASE2_GATES "$PHASE2_GATES"

# --- step 5: gate evaluation ---
_FAIL_REASON=""

# Denylist
if [ "$DENYLIST_RESULT" != "clean" ]; then
  case "$DENYLIST_RESULT" in
    symlink:*) _FAIL_REASON="symlink" ;;
    hit:*)     _FAIL_REASON="denylist" ;;
    rename-denylist:*) _FAIL_REASON="rename-denylist" ;;
  esac
fi

# Size cap (only check if denylist clean — earlier fail wins for surfacing)
if [ -z "$_FAIL_REASON" ]; then
  if [ "$FILES" -gt "$MAX_FILES" ] 2>/dev/null; then
    _FAIL_REASON="size-cap"
    _FAIL_DETAIL="files=$FILES max=$MAX_FILES"
  elif [ "$LINES" -gt "$MAX_LINES" ] 2>/dev/null; then
    _FAIL_REASON="size-cap"
    _FAIL_DETAIL="lines=$LINES max=$MAX_LINES"
  fi
fi

# Phase-2 markers
if [ -z "$_FAIL_REASON" ]; then
  if [ "$PIPELINE_END_STATE" != "green" ] \
     || [ "$SMOKE" != "pass" ] \
     || [ "$E2E" != "pass" ] \
     || [ "$PHASE2_GATES" != "checked" ]; then
    _FAIL_REASON="qa-marker"
    _FAIL_DETAIL="PIPELINE_END_STATE=$PIPELINE_END_STATE SMOKE=$SMOKE E2E=$E2E PHASE2_GATES=$PHASE2_GATES"
  fi
fi

if [ -n "$_FAIL_REASON" ]; then
  emit GATE_RESULT "halted_at_gate2"
  case "$_FAIL_REASON" in
    denylist)
      echo "[gate2-denylist] denylisted path tripped: ${DENYLIST_RESULT#hit:}" >&2
      ;;
    symlink)
      echo "[gate2-symlink] new/changed symlink: ${DENYLIST_RESULT#symlink:}" >&2
      ;;
    rename-denylist)
      echo "[gate2-rename-denylist] rename touched denylist: ${DENYLIST_RESULT#rename-denylist:}" >&2
      ;;
    size-cap)
      echo "[gate2-size-cap] $_FAIL_DETAIL" >&2
      ;;
    qa-marker)
      echo "[gate2-qa-marker] $_FAIL_DETAIL" >&2
      ;;
  esac
  exit 1
fi

emit GATE_RESULT "auto-approved"
exit 0
