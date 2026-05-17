#!/usr/bin/env bash
# tests/drain-one-todo-worktree-resolve.test.sh
#
# Regression test for the "drain-one-todo worktree-init path resolution" defect.
#
# Bug: scripts/drain-one-todo.sh resolved scripts/cj-worktree-init.sh via a
# BASH_SOURCE-relative `../../..` path. That only holds for the in-repo
# checkout. skills-deploy symlinks per-skill files into
# ~/.claude/skills/CJ_goal_todo_fix/scripts/ but NEVER deploys repo-root
# scripts/ to ~/.claude/scripts/. From the DEPLOYED location, `../../..`
# resolves to ~/.claude and the helper was looked for at the nonexistent
# ~/.claude/scripts/cj-worktree-init.sh — drain silently ran every TODO on
# the current branch (the collision F000025/S000054 fixes).
#
# Fix: drain-one-todo.sh resolves the helper via the workbench-source path
# recorded in ~/.claude/.skills-templates.json (.source) — the same
# convention todo_fix.sh / the single-TODO SKILL.md preamble / the F000009
# update-check preamble already use — with the BASH_SOURCE-relative path
# kept only as an in-repo / no-manifest fallback.
#
# Cases:
#   (1) Static: drain-one-todo.sh reads .skills-templates.json .source to
#       resolve cj-worktree-init.sh (the workbench convention), matching how
#       todo_fix.sh does it.
#   (2) Behavioral: from a SIMULATED DEPLOYED layout
#       (~/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh) with a
#       manifest whose .source points at the workbench checkout, the helper
#       resolves and the per-iteration worktree IS created (state=created).
#       Pre-fix this case fails because the helper is unreachable.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
DRAIN="$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"
WT_HELPER="$REPO_ROOT/scripts/cj-worktree-init.sh"

[ -f "$DRAIN" ]      || { echo "FAIL: $DRAIN not found"; exit 1; }
[ -x "$WT_HELPER" ]  || { echo "FAIL: $WT_HELPER not executable"; exit 1; }

# ---------- Case 1: static — manifest .source resolution present ----------

echo ""
echo "Case 1: drain-one-todo.sh resolves cj-worktree-init.sh via .skills-templates.json .source..."
if grep -q '\.skills-templates\.json' "$DRAIN" \
   && grep -qE 'jq -r .*\.source.*\.skills-templates\.json' "$DRAIN" \
   && grep -q 'scripts/cj-worktree-init\.sh' "$DRAIN"; then
  ok "Case 1: drain-one-todo.sh reads .skills-templates.json .source to resolve cj-worktree-init.sh"
else
  fail_test "Case 1: drain-one-todo.sh does not resolve cj-worktree-init.sh via .skills-templates.json .source (regression: BASH_SOURCE-only resolution breaks from deployed ~/.claude/)"
fi

# ---------- Case 2: behavioral — deployed layout, manifest .source set ----------
#
# Build a sandbox that mirrors the real failure surface:
#   $SBX/workbench/                       <- a git repo (the workbench source)
#     skills/CJ_goal_todo_fix/scripts/    <- where todo_fix.sh would live
#     scripts/cj-worktree-init.sh         <- the helper, ONLY here
#   $SBX/home/.claude/
#     .skills-templates.json              <- {"source": "$SBX/workbench"}
#     skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh  <- DEPLOYED copy
#
# We invoke the DEPLOYED drain-one-todo.sh in DRY_RUN mode with HOME pointed at
# the sandbox home. If the manifest .source resolution works, the helper is
# found and the per-iteration worktree is created (worktree dir appears under
# the workbench's .claude/worktrees/). Pre-fix: helper unreachable, no
# worktree, drain proceeds in-place.

echo ""
echo "Case 2: deployed layout + manifest .source → helper resolves, worktree created..."

SBX=$(mktemp -d -t drain-wt-resolve-test.XXXXXX)
trap 'rm -rf "$SBX"' EXIT

# Unique heading per run so the cross-skill daily lockfile
# (/tmp/cj-goal-active-headings-YYYYMMDD.txt — hardcoded, not env-overridable)
# can never collide with a stale entry from a prior run / parallel session and
# short-circuit the dispatch path with a spurious lock_skip BEFORE the
# worktree-resolution code is reached.
UNIQ="resolve smoke $$ $(date +%s%N 2>/dev/null || date +%s)"

# --- workbench source repo ---
WB="$SBX/workbench"
mkdir -p "$WB/scripts" "$WB/skills/CJ_goal_todo_fix/scripts" "$WB/work-items/tasks/ops"
cp "$WT_HELPER" "$WB/scripts/cj-worktree-init.sh"
chmod +x "$WB/scripts/cj-worktree-init.sh"

# Minimal TODOS.md so todo_fix.sh single-TODO mode can resolve the fragment.
cat > "$WB/TODOS.md" <<TODOS_EOF
## Active work

### Drain $UNIQ (P3, S)

Body long enough to clear the >=50-char preflight gate so the dispatch path
proceeds far enough to trigger the per-iteration worktree creation step.
TODOS_EOF

(
  cd "$WB"
  git init -q
  git config user.email "test@test"
  git config user.name "test"
  git checkout -q -b main 2>/dev/null || true
  git add -A
  git commit -qm "seed workbench"
)

# --- deployed ~/.claude layout ---
HOMEDIR="$SBX/home"
mkdir -p "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts"
cp "$DRAIN" "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"
chmod +x "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"
# Also deploy todo_fix.sh so the dispatch delegation has a target (resolved via
# $HOME/.claude/skills/... fallback inside drain-one-todo.sh).
cp "$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/todo_fix.sh" \
   "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh"
chmod +x "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh"

# Manifest: .source points at the workbench checkout (what skills-deploy writes).
cat > "$HOMEDIR/.claude/.skills-templates.json" <<MANIFEST_EOF
{"source": "$WB", "skills": {"CJ_goal_todo_fix": {"path": "skills/CJ_goal_todo_fix/SKILL.md"}}}
MANIFEST_EOF

DEPLOYED_DRAIN="$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"

# Run the deployed drain from inside the workbench repo with HOME pointed at
# the sandbox so the manifest resolves. DRY_RUN=1 makes the delegated
# todo_fix.sh do no writes — but drain-one-todo.sh passes the worktree helper
# `--caller todo --force-create --quiet` (NOT --dry-run), so a reachable
# helper actually creates a real per-iteration worktree under
# $WB/.claude/worktrees/cj-todo-<ts>-<pid>/. That directory is the true
# behavioral signal:
#   - WITH the fix: manifest .source resolves the helper -> worktree created.
#   - PRE-fix:       helper unreachable from ~/.claude/ -> NO worktree created
#                    (drain silently runs in-place — the defect).
OUT=$(cd "$WB" && HOME="$HOMEDIR" DRY_RUN=1 bash "$DEPLOYED_DRAIN" dispatch "Drain $UNIQ" "test-session-$$" 2>&1 || true)

WT_CREATED=0
if [ -d "$WB/.claude/worktrees" ]; then
  if find "$WB/.claude/worktrees" -maxdepth 1 -type d -name 'cj-todo-*' 2>/dev/null | grep -q .; then
    WT_CREATED=1
  fi
fi

# Best-effort cleanup of any worktree the helper created so the sandbox tmpdir
# rm (EXIT trap) is clean and no stray git worktree refs leak.
if [ "$WT_CREATED" = "1" ]; then
  ( cd "$WB" 2>/dev/null && git worktree list --porcelain 2>/dev/null \
      | awk '/^worktree /{print $2}' | while read -r wt; do
        case "$wt" in */.claude/worktrees/cj-todo-*) git worktree remove --force "$wt" 2>/dev/null || true ;; esac
      done ) || true
fi

if [ "$WT_CREATED" = "1" ]; then
  ok "Case 2: deployed drain resolved cj-worktree-init.sh via manifest .source (real per-iteration worktree created under \$WB/.claude/worktrees/cj-todo-*)"
else
  fail_test "Case 2: deployed drain did NOT create a per-iteration worktree — cj-worktree-init.sh unreachable from ~/.claude/ via manifest .source (the defect). Output: $OUT"
fi

# ---------- Summary ----------

echo ""
echo "=== drain-one-todo-worktree-resolve.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
