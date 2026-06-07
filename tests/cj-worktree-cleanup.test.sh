#!/usr/bin/env bash
# tests/cj-worktree-cleanup.test.sh — test for scripts/cj-worktree-cleanup.sh.
#
# T000036: the post-run worktree-cleanup janitor (teardown mirror of
# cj-worktree-init.sh). Behavior coverage for the PR-state-gated sweep.
#
# How the PR-state gate is faked (the load-bearing test mechanic):
#   cj-worktree-cleanup.sh resolves cj-goal-common.sh as a SIBLING in its own
#   scripts/ dir FIRST (before the manifest .source probe). So each case stages a
#   sandbox `scripts/` dir containing (1) a COPY of the real cleanup script and
#   (2) a FAKE cj-goal-common.sh that emits scripted PR_CHECK/PR_EXISTS/PR_STATE
#   keyed off the --branch arg. This gives full deterministic control over the
#   decision table with zero real `gh` / network dependency. Worktrees are real
#   (git worktree add) so the local-state rails (current/locked/dirty) and the
#   actual `git worktree remove`/`prune` paths are exercised for real.
#
# Cases:
#   1  --dry-run mutates nothing (MERGED fixture present)
#   2  PR_STATE=MERGED removed
#   3  PR_STATE=CLOSED removed
#   4  PR_STATE=OPEN skipped (still in review)
#   5  PR_EXISTS=0 skipped (no PR)
#   6  PR_CHECK=skipped (gh offline) skipped
#   7  current worktree never removed (MERGED PR)
#   8  locked skipped (MERGED PR)
#   9  dirty skipped (MERGED PR)
#   10 non-cj worktree untouched (MERGED PR)
#   11 prune invoked (PRUNED=ok on a real sweep)
#   12  root-refresh guarded on dirty TRACKED root (ROOT_REFRESH=skipped)
#   12b root-refresh PROCEEDS on untracked-only root (ROOT_REFRESH=ok) — the
#       D-fix: `git checkout main`+`git pull` never touch untracked files, so an
#       untracked-only root (e.g. this repo's .gstack/*.md) must NOT skip
#   13 cwd-not-a-repo ⇒ RESULT=skipped
#
# Plus static-grep wiring assertions (case 16/17 from the test-plan):
#   - cj-goal-common.sh registers --phase cleanup (usage + validation case)
#   - feature/defect pipeline.md + todo SKILL.md + drain-one-todo.sh wire the
#     terminal cleanup at the four real seams
#   - the new test is registered in scripts/test.sh (a hand-written runner block)
#
# Pure behavior smoke: every fixture is torn down per case.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
REAL_CLEANUP="$REPO_ROOT/scripts/cj-worktree-cleanup.sh"

[ -x "$REAL_CLEANUP" ] || { echo "FAIL: $REAL_CLEANUP not executable"; exit 1; }

# ---------- Fake cj-goal-common.sh generator ----------
#
# Writes a fake cj-goal-common.sh into <scripts_dir> that, for `--phase pr-check
# --branch <b>`, emits PR_CHECK / PR_EXISTS / PR_STATE according to a per-branch
# rule table passed as the body. The rule is a case statement on $BR.
write_fake_common() {
  local scripts_dir="$1" rule_body="$2"
  cat > "$scripts_dir/cj-goal-common.sh" <<FAKE
#!/usr/bin/env bash
# FAKE cj-goal-common.sh for cj-worktree-cleanup.test.sh — pr-check only.
set -u
PHASE=""; BR=""
while [ \$# -gt 0 ]; do
  case "\$1" in
    --phase)  PHASE="\${2:-}"; shift 2 ;;
    --branch) BR="\${2:-}";    shift 2 ;;
    *)        shift ;;
  esac
done
if [ "\$PHASE" = "pr-check" ]; then
  echo "PHASE=pr-check"
$rule_body
fi
exit 0
FAKE
  chmod +x "$scripts_dir/cj-goal-common.sh"
}

# ---------- Sandbox builder ----------
#
# Creates: a temp ROOT git repo on main, a temp scripts/ dir holding a copy of
# the real cleanup script + a fake common helper. Returns the ROOT path via the
# named global SBX_ROOT and the scripts dir via SBX_SCRIPTS.
SBX_ROOT=""
SBX_SCRIPTS=""
mk_sandbox() {
  local rule_body="$1"
  SBX_ROOT=$(mktemp -d -t cj-wt-cleanup-root.XXXXXX)
  SBX_SCRIPTS=$(mktemp -d -t cj-wt-cleanup-scripts.XXXXXX)
  (
    cd "$SBX_ROOT"
    git init -q
    git config user.email "test@test"
    git config user.name "test"
    git checkout -q -b main 2>/dev/null || true
    echo "seed" > seed.txt
    git add seed.txt
    git commit -qm "seed"
    mkdir -p .claude/worktrees
  )
  cp "$REAL_CLEANUP" "$SBX_SCRIPTS/cj-worktree-cleanup.sh"
  chmod +x "$SBX_SCRIPTS/cj-worktree-cleanup.sh"
  write_fake_common "$SBX_SCRIPTS" "$rule_body"
}

# Add a worktree under the sandbox root on the given branch. Echoes its path.
add_wt() {
  local branch="$1" name="$2"
  local p="$SBX_ROOT/.claude/worktrees/$name"
  ( cd "$SBX_ROOT" && git worktree add -q -b "$branch" "$p" >/dev/null 2>&1 )
  printf '%s' "$p"
}

# Give SBX_ROOT a real upstream so the cleanup script's `git pull --ff-only` half
# of the root refresh actually succeeds (returns ROOT_REFRESH=ok instead of fail).
# Clones a bare origin from the current root state and sets main to track it; the
# pull is then a clean already-up-to-date no-op. Used by Case 12b, where the
# refresh is expected to PROCEED (untracked-only root). Registered for teardown.
add_origin_upstream() {
  local origin="$SBX_ROOT.origin.git"
  git clone -q --bare "$SBX_ROOT" "$origin" >/dev/null 2>&1
  (
    cd "$SBX_ROOT"
    git remote add origin "$origin" 2>/dev/null || git remote set-url origin "$origin"
    git fetch -q origin 2>/dev/null || true
    git branch --set-upstream-to=origin/main main >/dev/null 2>&1 || true
  )
  ALL_SANDBOXES+=("$origin")   # rm -rf on EXIT (bare repo has no worktrees to detach)
}

ALL_SANDBOXES=()
register_sbx() { ALL_SANDBOXES+=("$SBX_ROOT" "$SBX_SCRIPTS"); }
cleanup_all() {
  for d in "${ALL_SANDBOXES[@]:-}"; do
    if [ -n "$d" ] && [ -d "$d" ]; then
      ( cd "$d" 2>/dev/null && git worktree list --porcelain 2>/dev/null \
          | awk '/^worktree /{print $2}' | while read -r wt; do
          [ "$wt" != "$d" ] && git worktree remove --force "$wt" 2>/dev/null || true
        done ) || true
      rm -rf "$d"
    fi
  done
}
trap cleanup_all EXIT

# Run the COPIED cleanup script from inside <cwd>. Forwards extra args.
run_cleanup() {
  local cwd="$1"; shift
  ( cd "$cwd" && bash "$SBX_SCRIPTS/cj-worktree-cleanup.sh" "$@" 2>&1 )
}

# Standard rule: any branch → MERGED.
RULE_MERGED='echo "PR_EXISTS=1"; echo "PR_STATE=MERGED"; echo "PR_CHECK=ok"; echo "PHASE_RESULT=ok"'
RULE_CLOSED='echo "PR_EXISTS=1"; echo "PR_STATE=CLOSED"; echo "PR_CHECK=ok"; echo "PHASE_RESULT=ok"'
RULE_OPEN='echo "PR_EXISTS=1"; echo "PR_STATE=OPEN"; echo "PR_CHECK=ok"; echo "PHASE_RESULT=ok"'
RULE_NOPR='echo "PR_EXISTS=0"; echo "PR_STATE="; echo "PR_CHECK=ok"; echo "PHASE_RESULT=ok"'
RULE_OFFLINE='echo "PR_CHECK=skipped"; echo "PR_EXISTS="; echo "PR_STATE="; echo "PHASE_RESULT=skipped"'

# ============================================================================
# Case 1: --dry-run mutates nothing (MERGED fixture present)
# ============================================================================
echo ""
echo "Case 1: --dry-run mutates nothing..."
mk_sandbox "$RULE_MERGED"; register_sbx
WT1=$(add_wt cj-feat-20260101-000001-111 cj-feat-one)
BEFORE=$(cd "$SBX_ROOT" && git worktree list | wc -l | tr -d ' ')
# Run from the ROOT (not inside the worktree) so the MERGED worktree is a
# removal candidate, not the current-dir rail — this case tests the WOULD-REMOVE
# listing + the no-mutation guarantee.
OUT=$(run_cleanup "$SBX_ROOT" --dry-run --caller feature)
AFTER=$(cd "$SBX_ROOT" && git worktree list | wc -l | tr -d ' ')
if echo "$OUT" | grep -q 'WOULD-REMOVE_PATH=.*cj-feat-one' \
   && [ "$BEFORE" = "$AFTER" ] && [ -d "$WT1" ] \
   && echo "$OUT" | grep -q 'RESULT=ok'; then
  ok "Case 1: WOULD-REMOVE listed, worktree count unchanged ($BEFORE), dir intact"
else
  fail_test "Case 1: dry-run should list WOULD-REMOVE + mutate nothing; before=$BEFORE after=$AFTER out=$OUT"
fi

# ============================================================================
# Case 2: PR_STATE=MERGED removed
# ============================================================================
echo ""
echo "Case 2: PR_STATE=MERGED removed..."
mk_sandbox "$RULE_MERGED"; register_sbx
WT2=$(add_wt cj-feat-20260101-000002-222 cj-feat-merged)
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if echo "$OUT" | grep -q 'REMOVED_PATH=.*cj-feat-merged' && [ ! -d "$WT2" ] \
   && echo "$OUT" | grep -q '^REMOVED=1'; then
  ok "Case 2: MERGED worktree REMOVED (dir gone, REMOVED=1)"
else
  fail_test "Case 2: expected MERGED removed; dir_exists=$([ -d "$WT2" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Case 3: PR_STATE=CLOSED removed
# ============================================================================
echo ""
echo "Case 3: PR_STATE=CLOSED removed (v1 treats CLOSED == MERGED)..."
mk_sandbox "$RULE_CLOSED"; register_sbx
WT3=$(add_wt cj-def-20260101-000003-333 cj-def-closed)
OUT=$(run_cleanup "$SBX_ROOT" --caller defect)
if echo "$OUT" | grep -q 'REMOVED_PATH=.*cj-def-closed' && [ ! -d "$WT3" ]; then
  ok "Case 3: CLOSED worktree REMOVED"
else
  fail_test "Case 3: expected CLOSED removed; dir_exists=$([ -d "$WT3" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Case 3b (F000054): cj-task-* branch is in the janitor's scope (MERGED removed)
# ============================================================================
echo ""
echo "Case 3b: cj-task-* MERGED removed (F000054 — proves the cj-task scoping)..."
mk_sandbox "$RULE_MERGED"; register_sbx
WT3B=$(add_wt cj-task-20260101-000003-3b3 cj-task-merged)
OUT=$(run_cleanup "$SBX_ROOT" --caller task)
if echo "$OUT" | grep -q 'REMOVED_PATH=.*cj-task-merged' && [ ! -d "$WT3B" ] \
   && echo "$OUT" | grep -q '^REMOVED=1'; then
  ok "Case 3b: MERGED cj-task-* worktree REMOVED (cj-task-* is in scope)"
else
  fail_test "Case 3b: expected cj-task-* MERGED removed; dir_exists=$([ -d "$WT3B" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Case 4: PR_STATE=OPEN skipped
# ============================================================================
echo ""
echo "Case 4: PR_STATE=OPEN skipped (still in review)..."
mk_sandbox "$RULE_OPEN"; register_sbx
WT4=$(add_wt cj-feat-20260101-000004-444 cj-feat-open)
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if echo "$OUT" | grep -q 'SKIPPED_PATH=.*cj-feat-open reason=pr-OPEN' && [ -d "$WT4" ] \
   && echo "$OUT" | grep -q '^REMOVED=0'; then
  ok "Case 4: OPEN worktree SKIPPED (reason=pr-OPEN, dir intact, REMOVED=0)"
else
  fail_test "Case 4: expected OPEN skipped + intact; dir_exists=$([ -d "$WT4" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Case 5: PR_EXISTS=0 skipped
# ============================================================================
echo ""
echo "Case 5: PR_EXISTS=0 skipped (no PR — in-flight drain sibling)..."
mk_sandbox "$RULE_NOPR"; register_sbx
WT5=$(add_wt cj-todo-20260101-000005-555 cj-todo-nopr)
OUT=$(run_cleanup "$SBX_ROOT" --caller todo)
if echo "$OUT" | grep -q 'SKIPPED_PATH=.*cj-todo-nopr reason=no-pr' && [ -d "$WT5" ]; then
  ok "Case 5: no-PR worktree SKIPPED (reason=no-pr, dir intact)"
else
  fail_test "Case 5: expected no-PR skipped + intact; dir_exists=$([ -d "$WT5" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Case 6: PR_CHECK=skipped (gh offline) skipped
# ============================================================================
echo ""
echo "Case 6: PR_CHECK=skipped (gh offline) skipped..."
mk_sandbox "$RULE_OFFLINE"; register_sbx
WT6=$(add_wt cj-feat-20260101-000006-666 cj-feat-offline)
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if echo "$OUT" | grep -q 'SKIPPED_PATH=.*cj-feat-offline reason=pr-check-skipped' && [ -d "$WT6" ]; then
  ok "Case 6: gh-offline worktree SKIPPED (reason=pr-check-skipped, dir intact)"
else
  fail_test "Case 6: expected gh-offline skipped + intact; dir_exists=$([ -d "$WT6" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Case 7: current worktree never removed (even with MERGED PR)
# ============================================================================
echo ""
echo "Case 7: current worktree never removed (MERGED PR)..."
mk_sandbox "$RULE_MERGED"; register_sbx
WT7=$(add_wt cj-feat-20260101-000007-777 cj-feat-current)
# Run FROM INSIDE the cj-* worktree → it is _CURRENT.
OUT=$(run_cleanup "$WT7" --caller feature)
if echo "$OUT" | grep -q 'SKIPPED_PATH=.*cj-feat-current reason=current' && [ -d "$WT7" ]; then
  ok "Case 7: current worktree SKIPPED (reason=current) despite MERGED PR"
else
  fail_test "Case 7: expected current skipped + intact; dir_exists=$([ -d "$WT7" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Case 8: locked skipped (MERGED PR)
# ============================================================================
echo ""
echo "Case 8: locked skipped (MERGED PR)..."
mk_sandbox "$RULE_MERGED"; register_sbx
WT8=$(add_wt cj-feat-20260101-000008-888 cj-feat-locked)
( cd "$SBX_ROOT" && git worktree lock "$WT8" 2>/dev/null || true )
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if echo "$OUT" | grep -q 'SKIPPED_PATH=.*cj-feat-locked reason=locked' && [ -d "$WT8" ]; then
  ok "Case 8: locked worktree SKIPPED (reason=locked) despite MERGED PR"
else
  fail_test "Case 8: expected locked skipped + intact; dir_exists=$([ -d "$WT8" ] && echo yes || echo no) out=$OUT"
fi
( cd "$SBX_ROOT" && git worktree unlock "$WT8" 2>/dev/null || true )

# ============================================================================
# Case 9: dirty skipped (MERGED PR)
# ============================================================================
echo ""
echo "Case 9: dirty skipped (MERGED PR)..."
mk_sandbox "$RULE_MERGED"; register_sbx
WT9=$(add_wt cj-feat-20260101-000009-999 cj-feat-dirty)
echo "uncommitted" > "$WT9/dirt.txt"
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if echo "$OUT" | grep -q 'SKIPPED_PATH=.*cj-feat-dirty reason=dirty' && [ -d "$WT9" ]; then
  ok "Case 9: dirty worktree SKIPPED (reason=dirty) despite MERGED PR"
else
  fail_test "Case 9: expected dirty skipped + intact; dir_exists=$([ -d "$WT9" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Case 10: non-cj worktree untouched (MERGED PR rule still active)
# ============================================================================
echo ""
echo "Case 10: non-cj worktree untouched (never enumerated)..."
mk_sandbox "$RULE_MERGED"; register_sbx
WT10=$(add_wt claude/some-conductor-session conductor-wt)
WT10B=$(add_wt chore/manual-fix chore-wt)
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if [ -d "$WT10" ] && [ -d "$WT10B" ] \
   && ! echo "$OUT" | grep -q 'conductor-wt' \
   && ! echo "$OUT" | grep -q 'chore-wt' \
   && echo "$OUT" | grep -q '^REMOVED=0'; then
  ok "Case 10: non-cj worktrees never enumerated for removal (both intact, REMOVED=0)"
else
  fail_test "Case 10: expected non-cj untouched + unreported; out=$OUT"
fi

# ============================================================================
# Case 11: prune invoked (PRUNED=ok on a real non-dry-run sweep)
# ============================================================================
echo ""
echo "Case 11: prune invoked (PRUNED=ok)..."
mk_sandbox "$RULE_MERGED"; register_sbx
_=$(add_wt cj-feat-20260101-000011-aaa cj-feat-prune)
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if echo "$OUT" | grep -q '^PRUNED=ok'; then
  ok "Case 11: PRUNED=ok (git worktree prune invoked on real sweep)"
else
  fail_test "Case 11: expected PRUNED=ok; out=$OUT"
fi

# ============================================================================
# Case 12: root-refresh guarded on dirty TRACKED root (ROOT_REFRESH=skipped)
# ============================================================================
echo ""
echo "Case 12: root-refresh guarded on dirty TRACKED root..."
mk_sandbox "$RULE_MERGED"; register_sbx
# Dirty the ROOT's TRACKED tree (modify the committed seed.txt). The guard
# short-circuits to skipped BEFORE reaching `git pull`, so no upstream is needed.
echo "tracked-change" >> "$SBX_ROOT/seed.txt"
WT12=$(add_wt cj-feat-20260101-000012-bbb cj-feat-rootdirty)
OUT=$(run_cleanup "$WT12" --caller feature)   # run from the worktree so root stays dirty
if echo "$OUT" | grep -q '^ROOT_REFRESH=skipped' \
   && echo "$OUT" | grep -q 'dirty tracked tree'; then
  ok "Case 12: dirty TRACKED root → ROOT_REFRESH=skipped (root never disturbed)"
else
  fail_test "Case 12: expected ROOT_REFRESH=skipped on dirty tracked root; out=$OUT"
fi

# ============================================================================
# Case 12b: root-refresh PROCEEDS on untracked-only root (ROOT_REFRESH=ok)
# ============================================================================
# The D-fix regression guard. `git checkout main` + `git pull --ff-only` never
# touch untracked files, so an untracked-only root (clean TRACKED tree) MUST NOT
# skip the refresh — counting untracked here is the bug (this workbench always has
# untracked .gstack/*.md design docs at root, which perma-skipped the refresh).
# Needs a real upstream so the (now-reached) `git pull --ff-only` succeeds → ok.
echo ""
echo "Case 12b: root-refresh proceeds on untracked-only root (the D-fix)..."
mk_sandbox "$RULE_MERGED"; register_sbx
add_origin_upstream    # bare origin + main set-upstream-to so pull --ff-only is a clean no-op
# Untracked-ONLY content at root (mimics .gstack/*.md): tracked tree stays clean.
echo "scratch design doc" > "$SBX_ROOT/untracked-design.md"
WT12B=$(add_wt cj-feat-20260101-000012-ccc cj-feat-rootuntracked)
OUT=$(run_cleanup "$WT12B" --caller feature)  # run from the worktree so root keeps its untracked file
if echo "$OUT" | grep -q '^ROOT_REFRESH=ok' \
   && ! echo "$OUT" | grep -q 'ROOT_REFRESH=skipped'; then
  ok "Case 12b: untracked-only root → ROOT_REFRESH=ok (refresh proceeds; untracked no longer blocks)"
else
  fail_test "Case 12b: expected ROOT_REFRESH=ok on untracked-only root; out=$OUT"
fi

# ============================================================================
# Case 13: cwd-not-a-repo ⇒ RESULT=skipped
# ============================================================================
echo ""
echo "Case 13: cwd-not-a-repo ⇒ RESULT=skipped..."
NONGIT=$(mktemp -d -t cj-wt-cleanup-nongit.XXXXXX)
OUT=$( cd "$NONGIT" && bash "$REAL_CLEANUP" --caller feature 2>&1 )
RC=$?
if echo "$OUT" | grep -q '^RESULT=skipped' && [ "$RC" -eq 0 ]; then
  ok "Case 13: non-git cwd → RESULT=skipped, exit 0"
else
  fail_test "Case 13: expected RESULT=skipped/exit0 in non-git dir; rc=$RC out=$OUT"
fi
rm -rf "$NONGIT"

# ============================================================================
# Orphan-dir sweep: rm leftover cj-* dirs git no longer tracks
# ============================================================================
echo ""
echo "Orphan: leftover cj-* dir (on disk, not a worktree) is removed..."
mk_sandbox "$RULE_MERGED"; register_sbx
ORPH="$SBX_ROOT/.claude/worktrees/cj-feat-20260101-000099-orphan"
mkdir -p "$ORPH"; echo "stale" > "$ORPH/leftover.txt"   # present on disk, NOT git-registered
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if [ ! -d "$ORPH" ] \
   && echo "$OUT" | grep -q 'RM-ORPHAN_PATH=.*cj-feat-20260101-000099-orphan' \
   && echo "$OUT" | grep -qE '^ORPHANS_RM=[1-9]'; then
  ok "Orphan: cj-* orphan dir rm'd (gone, RM-ORPHAN listed, ORPHANS_RM>=1)"
else
  fail_test "Orphan: expected cj-* orphan removed; dir_exists=$([ -d "$ORPH" ] && echo yes || echo no) out=$OUT"
fi

echo ""
echo "Orphan: non-cj leftover dir is NOT touched (out of scope)..."
mk_sandbox "$RULE_MERGED"; register_sbx
NONCJ="$SBX_ROOT/.claude/worktrees/claude-conductor-abc123"
mkdir -p "$NONCJ"; echo "keep" > "$NONCJ/keep.txt"
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if [ -d "$NONCJ" ] && ! echo "$OUT" | grep -q 'RM-ORPHAN_PATH=.*claude-conductor-abc123'; then
  ok "Orphan: non-cj dir left intact (cj-* scope respected)"
else
  fail_test "Orphan: non-cj dir must NOT be removed; dir_exists=$([ -d "$NONCJ" ] && echo yes || echo no) out=$OUT"
fi

echo ""
echo "Orphan: a still-registered worktree is NOT orphan-rm'd (even an OPEN-PR one)..."
mk_sandbox "$RULE_OPEN"; register_sbx
REGWT=$(add_wt cj-feat-20260101-000100-reg cj-feat-registered-open)
ORPH2="$SBX_ROOT/.claude/worktrees/cj-def-20260101-000101-orphan2"
mkdir -p "$ORPH2"
OUT=$(run_cleanup "$SBX_ROOT" --caller feature)
if [ -d "$REGWT" ] && [ ! -d "$ORPH2" ] \
   && ! echo "$OUT" | grep -q "RM-ORPHAN_PATH=$REGWT"; then
  ok "Orphan: registered OPEN worktree survived; only the unregistered orphan was rm'd"
else
  fail_test "Orphan: registered worktree must survive orphan sweep; reg_exists=$([ -d "$REGWT" ] && echo yes || echo no) orph_exists=$([ -d "$ORPH2" ] && echo yes || echo no) out=$OUT"
fi

echo ""
echo "Orphan: --dry-run lists WOULD-RM-ORPHAN and mutates nothing..."
mk_sandbox "$RULE_MERGED"; register_sbx
ORPH3="$SBX_ROOT/.claude/worktrees/cj-todo-20260101-000102-orphan3"
mkdir -p "$ORPH3"
OUT=$(run_cleanup "$SBX_ROOT" --dry-run --caller todo)
if [ -d "$ORPH3" ] \
   && echo "$OUT" | grep -q 'WOULD-RM-ORPHAN_PATH=.*cj-todo-20260101-000102-orphan3' \
   && echo "$OUT" | grep -qE '^WOULD_ORPHANS_RM=[1-9]'; then
  ok "Orphan: dry-run listed WOULD-RM-ORPHAN, dir intact"
else
  fail_test "Orphan: dry-run should list + not rm; dir_exists=$([ -d "$ORPH3" ] && echo yes || echo no) out=$OUT"
fi

# ============================================================================
# Static wiring assertions (test-plan cases 14/15/16/17)
# ============================================================================

echo ""
echo "Wiring: cj-goal-common.sh registers --phase cleanup (usage + validation)..."
_COMMON="$REPO_ROOT/scripts/cj-goal-common.sh"
if grep -qF 'worktree|telemetry|pr-check|cleanup' "$_COMMON" \
   && grep -qF 'worktree, telemetry, pr-check, ship, cleanup' "$_COMMON" \
   && grep -qF 'PHASE=cleanup' "$_COMMON"; then
  ok "cj-goal-common.sh: cleanup in --phase validation case + usage string + dispatch"
else
  fail_test "cj-goal-common.sh missing --phase cleanup registration (validation case / usage / dispatch)"
fi

# Case 14/15 behavior: --phase cleanup never emits failed; --mode todo still rejected.
echo ""
echo "Wiring: cj-goal-common.sh --phase cleanup behavior (never failed; --mode todo rejected)..."
_C_OUT=$(bash "$_COMMON" --phase cleanup --mode feature --dry-run 2>/dev/null || true)
_TODO_OUT=$(bash "$_COMMON" --phase cleanup --mode todo 2>&1 || true)
if echo "$_C_OUT" | grep -q 'PHASE_RESULT=ok' \
   && ! echo "$_C_OUT" | grep -q 'PHASE_RESULT=failed' \
   && echo "$_C_OUT" | grep -q 'PHASE=cleanup' \
   && echo "$_TODO_OUT" | grep -q 'common-usage-mode'; then
  ok "cj-goal-common.sh --phase cleanup: PHASE_RESULT=ok (never failed); --mode todo rejected at usage-check"
else
  fail_test "cj-goal-common.sh --phase cleanup behavior wrong; cleanup_out=$_C_OUT todo_out=$_TODO_OUT"
fi

echo ""
echo "Wiring: terminal cleanup present at all five seams (static grep)..."
_FEAT="$REPO_ROOT/skills/CJ_goal_feature/pipeline.md"
_TASK="$REPO_ROOT/skills/CJ_goal_task/pipeline.md"
_DEF="$REPO_ROOT/skills/CJ_goal_defect/pipeline.md"
_TODO_SKILL="$REPO_ROOT/skills/CJ_goal_todo_fix/SKILL.md"
_DRAIN="$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"
_seams_ok=1
grep -qF -- '--phase cleanup --mode feature' "$_FEAT" || { _seams_ok=0; echo "    (feature pipeline.md seam missing)"; }
grep -qF -- '--phase cleanup --mode task'    "$_TASK" || { _seams_ok=0; echo "    (task pipeline.md seam missing)"; }
grep -qF -- '--phase cleanup --mode defect'  "$_DEF"  || { _seams_ok=0; echo "    (defect pipeline.md seam missing)"; }
grep -qF -- 'cj-worktree-cleanup.sh --caller todo' "$_TODO_SKILL" || { _seams_ok=0; echo "    (todo SKILL.md single-mode seam missing)"; }
{ grep -qF 'cj-worktree-cleanup.sh' "$_DRAIN" && grep -qF -- '--caller todo' "$_DRAIN"; } || { _seams_ok=0; echo "    (drain-one-todo.sh seam missing)"; }
if [ "$_seams_ok" = "1" ]; then
  ok "all five terminal cleanup seams wired (feature/task/defect via cj-goal-common; todo single+drain direct)"
else
  fail_test "one or more terminal cleanup seams missing (see notes above)"
fi

echo ""
echo "Wiring: this test is registered in scripts/test.sh (discovery is NOT glob-based)..."
if grep -qF 'cj-worktree-cleanup.test.sh' "$REPO_ROOT/scripts/test.sh"; then
  ok "scripts/test.sh has a cj-worktree-cleanup.test.sh runner block"
else
  fail_test "scripts/test.sh missing cj-worktree-cleanup.test.sh runner block (test would silently never run)"
fi

# ---------- Summary ----------
echo ""
echo "=== cj-worktree-cleanup.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
