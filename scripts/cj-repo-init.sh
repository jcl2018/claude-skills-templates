#!/usr/bin/env bash
# cj-repo-init.sh — detect deployed CJ_ skills, verify their per-repo
# prerequisites, print a health table, and (on --fix) scaffold the missing
# repo-level prerequisites from generic portable seeds.
#
# Pattern precedent: scripts/skills-doc-sync-check (detection-in-script /
# AUQ-in-prose split, CLAUDE.md "Novel pattern callout"). This script does
# detection + verification + scaffolding ONLY; the /CJ_repo-init SKILL.md prose
# owns the single confirm AskUserQuestion on gaps.
#
# Modes:
#   (default)    detect + verify; print health table + machine-readable
#                GAPS=<n> line + one REPO_GAP / INSTALL_GAP line per gap.
#                Writes nothing. Exit 0 when no repo-level gaps, 1 when any
#                repo-level gap remains.
#   --dry-run    identical to default (explicit no-write preview).
#   --fix        scaffold the missing repo-level prerequisites from inline
#                generic seeds; re-verify; print the post-fix table. Idempotent
#                (existing-and-valid prereqs are left untouched). Install-level
#                gaps are reported only — never auto-installed.
#   --help|-h    usage.
#
# Prerequisite map (skill -> per-repo prereq):
#   cj-document-release.json   needed-by: CJ_document-release,
#                              CJ_goal_feature/defect/todo_fix  [repo-level]
#   TODOS.md                   needed-by: CJ_suggest, CJ_goal_todo_fix,
#                              CJ_improve-queue                  [repo-level]
#   work-items/{features,defects,tasks}/  needed-by: scaffold/implement/qa,
#                              CJ_personal-workflow, CJ_goal_*   [repo-level]
#   ~/.claude/skills/CJ_personal-workflow assets  needed-by: all pipeline
#                              phases                            [install-level]
#
# Exit codes: 0 = no repo-level gaps; 1 = repo-level gaps remain;
#             2 = usage / not-a-git-repo error.

set -uo pipefail

# Strip CRLF from jq output on Windows (jq.exe writes \r\n). No-op on Unix.
jq() { command jq "$@" | tr -d '\r'; }

PROG="cj-repo-init.sh"

usage() {
  cat <<'USAGE'
cj-repo-init.sh — verify/scaffold per-repo prerequisites for the CJ_ skill family.

Usage:
  cj-repo-init.sh              detect + verify; print health table + GAPS=<n>; no writes
  cj-repo-init.sh --dry-run    same as default (explicit no-write preview)
  cj-repo-init.sh --fix        scaffold missing repo-level prereqs from generic seeds
  cj-repo-init.sh --help       this message

Exit: 0 = no repo-level gaps, 1 = repo-level gaps remain, 2 = usage / not-a-git-repo.
USAGE
}

# ----- arg parse -----
MODE="report"   # report | dryrun | fix
case "${1:-}" in
  ""|--report) MODE="report" ;;
  --dry-run)   MODE="dryrun" ;;
  --fix)       MODE="fix" ;;
  --help|-h)   usage; exit 0 ;;
  *) echo "$PROG: unknown argument '${1:-}'" >&2; usage >&2; exit 2 ;;
esac

# ----- locate repo root (clean degradation, P1 AC-9) -----
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -z "$REPO_ROOT" ]; then
  echo "$PROG: error: not inside a git repository." >&2
  echo "$PROG: run this from a repo that has (or will have) the CJ_ skill family deployed." >&2
  exit 2
fi

CLAUDE_HOME="${CJ_REPO_INIT_CLAUDE_HOME:-$HOME/.claude}"
MANIFEST="$CLAUDE_HOME/.skills-templates.json"

# ----- detection: which CJ_ skills are deployed -----
# Fallback chain (DESIGN decision #3):
#   1. ~/.claude/.skills-templates.json  (.skills object keys)
#   2. ls ~/.claude/skills/CJ_*          (deployed skill dirs)
#   3. repo-local skills/CJ_*            (self-dev inside the workbench)
DETECT_SOURCE=""
DEPLOYED_SKILLS=""

if [ -f "$MANIFEST" ] && command -v jq >/dev/null 2>&1 && jq -e . "$MANIFEST" >/dev/null 2>&1; then
  DEPLOYED_SKILLS=$(jq -r '(.skills // {}) | keys[]' "$MANIFEST" 2>/dev/null | grep -E '^CJ_' || true)
  [ -n "$DEPLOYED_SKILLS" ] && DETECT_SOURCE="manifest"
fi

if [ -z "$DEPLOYED_SKILLS" ] && [ -d "$CLAUDE_HOME/skills" ]; then
  DEPLOYED_SKILLS=$(find "$CLAUDE_HOME/skills" -maxdepth 1 -type d -name 'CJ_*' -exec basename {} \; 2>/dev/null || true)
  [ -n "$DEPLOYED_SKILLS" ] && DETECT_SOURCE="deployed-dirs"
fi

if [ -z "$DEPLOYED_SKILLS" ] && [ -d "$REPO_ROOT/skills" ]; then
  DEPLOYED_SKILLS=$(find "$REPO_ROOT/skills" -maxdepth 1 -type d -name 'CJ_*' -exec basename {} \; 2>/dev/null || true)
  [ -n "$DEPLOYED_SKILLS" ] && DETECT_SOURCE="repo-local"
fi

if [ -z "$DEPLOYED_SKILLS" ]; then
  # No deployed manifest AND no skill dirs anywhere: degrade cleanly (P1 AC-9).
  # Nothing detected => nothing to require; report empty + exit clean.
  DETECT_SOURCE="none"
fi

# Membership helper.
_has_skill() { printf '%s\n' "$DEPLOYED_SKILLS" | grep -qx "$1"; }

# ----- map detected skills -> required prereqs -----
# Each prereq is gated by whether ANY skill needing it is deployed. When the
# detect source is "none" we conservatively require all repo-level prereqs so a
# fresh-machine operator still gets a useful health table + scaffold path.
NEED_DOCREL=false   # cj-document-release.json
NEED_TODOS=false    # TODOS.md
NEED_WORKITEMS=false
NEED_PWASSETS=false # install-level

if [ "$DETECT_SOURCE" = "none" ]; then
  NEED_DOCREL=true; NEED_TODOS=true; NEED_WORKITEMS=true; NEED_PWASSETS=true
else
  for s in CJ_document-release CJ_goal_feature CJ_goal_defect CJ_goal_todo_fix \
           cj_goal_feature cj_goal_defect; do
    _has_skill "$s" && NEED_DOCREL=true
  done
  for s in CJ_suggest CJ_goal_todo_fix CJ_improve-queue; do
    _has_skill "$s" && NEED_TODOS=true
  done
  for s in CJ_scaffold-work-item CJ_implement-from-spec CJ_qa-work-item \
           CJ_personal-workflow CJ_personal-pipeline CJ_goal_feature \
           CJ_goal_defect CJ_goal_todo_fix; do
    _has_skill "$s" && NEED_WORKITEMS=true
  done
  for s in CJ_personal-workflow CJ_scaffold-work-item CJ_implement-from-spec \
           CJ_qa-work-item; do
    _has_skill "$s" && NEED_PWASSETS=true
  done
fi

# ----- verification -----
DOCREL_PATH="$REPO_ROOT/cj-document-release.json"
TODOS_PATH="$REPO_ROOT/TODOS.md"

# cj-document-release.json: existence + parseable JSON + supported schema_version
# (mirror validate.sh Check 16). Returns one of: ok | missing | invalid
verify_docrel() {
  [ -f "$DOCREL_PATH" ] || { echo "missing"; return; }
  if ! command -v jq >/dev/null 2>&1; then echo "ok"; return; fi
  if ! jq empty "$DOCREL_PATH" >/dev/null 2>&1; then echo "invalid"; return; fi
  local sv
  sv=$(jq -r '.schema_version // empty' "$DOCREL_PATH" 2>/dev/null)
  [ "$sv" = "1" ] || { echo "invalid"; return; }
  jq -e '.whitelist_patterns | type == "array" and length > 0' "$DOCREL_PATH" >/dev/null 2>&1 || { echo "invalid"; return; }
  jq -e '.categories | type == "object" and length > 0' "$DOCREL_PATH" >/dev/null 2>&1 || { echo "invalid"; return; }
  jq -e '[.categories | to_entries[] | .value | type == "array" and length > 0] | all' "$DOCREL_PATH" >/dev/null 2>&1 || { echo "invalid"; return; }
  echo "ok"
}

verify_todos()     { [ -f "$TODOS_PATH" ] && echo "ok" || echo "missing"; }
verify_workitems() {
  local missing=""
  for d in features defects tasks; do
    [ -d "$REPO_ROOT/work-items/$d" ] || missing="$missing $d"
  done
  [ -z "$missing" ] && echo "ok" || echo "missing:$missing"
}
verify_pwassets()  {
  [ -f "$CLAUDE_HOME/skills/CJ_personal-workflow/personal-artifact-manifests.json" ] && echo "ok" || echo "missing"
}

# ----- inline generic PORTABLE seeds (DESIGN decision #4) -----
# These MUST NOT leak workbench-specific paths — they ship to any adopting repo.
seed_docrel() {
  cat > "$DOCREL_PATH" <<'JSON'
{
  "schema_version": 1,
  "whitelist_patterns": [
    "README.md",
    "CHANGELOG.md",
    "CLAUDE.md",
    "CONTRIBUTING.md",
    "doc/**/*.md"
  ],
  "categories": {
    "readme": ["README.md"],
    "changelog": ["CHANGELOG.md"],
    "claude": ["CLAUDE.md"],
    "contributing": ["CONTRIBUTING.md"],
    "docs": ["doc/**/*.md"]
  }
}
JSON
}

seed_todos() {
  cat > "$TODOS_PATH" <<'MD'
# TODOS

<!--
  Active backlog for this repo. /CJ_suggest ranks rows from the section below;
  /CJ_goal_todo_fix drains them into PRs. One row per work item, e.g.:

  ### Short title (P2, S)
  One-line description of the work.

  Priority Pn (P0 highest), size S/M/L. Strike through (~~...~~) closed rows so
  /CJ_suggest excludes them.
-->

## Active work
MD
}

seed_workitems() {
  for d in features defects tasks; do
    mkdir -p "$REPO_ROOT/work-items/$d"
  done
}

# ----- gap collection -----
REPO_GAPS=0
INSTALL_GAPS=0
GAP_LINES=()    # machine-readable: "REPO_GAP <prereq> <detail>" / "INSTALL_GAP ..."
TABLE_ROWS=()   # human-readable: "prereq|needed-by|status"

add_row() { TABLE_ROWS+=("$1|$2|$3"); }

# Build status per prereq (pre-fix snapshot).
collect() {
  REPO_GAPS=0; INSTALL_GAPS=0; GAP_LINES=(); TABLE_ROWS=()

  if $NEED_DOCREL; then
    local st; st=$(verify_docrel)
    case "$st" in
      ok)      add_row "cj-document-release.json" "CJ_document-release, CJ_goal_*" "OK" ;;
      missing) add_row "cj-document-release.json" "CJ_document-release, CJ_goal_*" "MISSING"
               GAP_LINES+=("REPO_GAP cj-document-release.json missing"); REPO_GAPS=$((REPO_GAPS+1)) ;;
      invalid) add_row "cj-document-release.json" "CJ_document-release, CJ_goal_*" "INVALID"
               GAP_LINES+=("REPO_GAP cj-document-release.json invalid (unparseable or unsupported schema_version)"); REPO_GAPS=$((REPO_GAPS+1)) ;;
    esac
  fi

  if $NEED_TODOS; then
    local st; st=$(verify_todos)
    if [ "$st" = "ok" ]; then
      add_row "TODOS.md" "CJ_suggest, CJ_goal_todo_fix, CJ_improve-queue" "OK"
    else
      add_row "TODOS.md" "CJ_suggest, CJ_goal_todo_fix, CJ_improve-queue" "MISSING"
      GAP_LINES+=("REPO_GAP TODOS.md missing"); REPO_GAPS=$((REPO_GAPS+1))
    fi
  fi

  if $NEED_WORKITEMS; then
    local st; st=$(verify_workitems)
    if [ "$st" = "ok" ]; then
      add_row "work-items/{features,defects,tasks}" "scaffold/implement/qa, CJ_goal_*" "OK"
    else
      add_row "work-items/{features,defects,tasks}" "scaffold/implement/qa, CJ_goal_*" "MISSING"
      GAP_LINES+=("REPO_GAP work-items dirs missing (${st#missing:})"); REPO_GAPS=$((REPO_GAPS+1))
    fi
  fi

  if $NEED_PWASSETS; then
    local st; st=$(verify_pwassets)
    if [ "$st" = "ok" ]; then
      add_row "CJ_personal-workflow assets (~/.claude)" "all pipeline phases" "OK"
    else
      add_row "CJ_personal-workflow assets (~/.claude)" "all pipeline phases" "MISSING [install]"
      GAP_LINES+=("INSTALL_GAP CJ_personal-workflow assets missing — run: <source>/scripts/skills-deploy install"); INSTALL_GAPS=$((INSTALL_GAPS+1))
    fi
  fi
}

print_table() {
  echo "CJ_repo-init — per-repo prerequisite health"
  echo "Repo:           $REPO_ROOT"
  echo "Detect source:  $DETECT_SOURCE"
  echo ""
  printf '%-40s | %-45s | %s\n' "prereq" "needed-by" "status"
  printf '%-40s-+-%-45s-+-%s\n' "----------------------------------------" "---------------------------------------------" "----------"
  local row
  for row in "${TABLE_ROWS[@]}"; do
    local p nb st
    p=${row%%|*}; row=${row#*|}; nb=${row%%|*}; st=${row#*|}
    printf '%-40s | %-45s | %s\n' "$p" "$nb" "$st"
  done
  echo ""
}

print_machine() {
  echo "GAPS=$REPO_GAPS"
  echo "INSTALL_GAPS=$INSTALL_GAPS"
  local g
  for g in "${GAP_LINES[@]:-}"; do
    [ -n "$g" ] && echo "$g"
  done
}

# ----- run -----
collect

if [ "$MODE" = "fix" ]; then
  # Scaffold only repo-level gaps. Install-level gaps are reported, never fixed.
  FIXED=()
  if $NEED_DOCREL; then
    st=$(verify_docrel)
    if [ "$st" = "missing" ]; then
      seed_docrel; FIXED+=("cj-document-release.json (created)")
    elif [ "$st" = "invalid" ]; then
      # Do NOT clobber an existing (intentional but broken) config — report it.
      echo "NOTE: cj-document-release.json present but invalid; NOT overwritten. Fix by hand or remove + re-run --fix." >&2
    fi
  fi
  if $NEED_TODOS && [ "$(verify_todos)" = "missing" ]; then
    seed_todos; FIXED+=("TODOS.md (created)")
  fi
  if $NEED_WORKITEMS && [ "$(verify_workitems)" != "ok" ]; then
    seed_workitems; FIXED+=("work-items/{features,defects,tasks}/ (created)")
  fi

  # Re-verify after scaffolding.
  collect
  print_table
  echo "Scaffolded:"
  if [ "${#FIXED[@]}" -eq 0 ]; then
    echo "  (nothing — no repo-level gaps to fix; idempotent no-op)"
  else
    for f in "${FIXED[@]}"; do echo "  - $f"; done
  fi
  echo ""
  print_machine
else
  # report / dryrun: identical output, never writes.
  print_table
  print_machine
fi

# ----- exit code: repo-level gaps only -----
[ "$REPO_GAPS" -eq 0 ] && exit 0 || exit 1
