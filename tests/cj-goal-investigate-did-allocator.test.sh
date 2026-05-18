#!/usr/bin/env bash
# tests/cj-goal-investigate-did-allocator.test.sh
#
# Regression test for the D000022 defect: skills/CJ_goal_investigate/pipeline.md
# D-ID allocator + resolver used `find ... -maxdepth 2`, which only reached
# work-items/defects/<domain>/D######_* (2 levels below work-items/defects) and
# MISSED nested 2-segment domains like work-items/defects/ops/skills-deploy/
# D000022_* (3 levels deep). Real impact: the allocator re-minted D000022 even
# though a depth-3 D000022 dir already existed (renumbered to D000024 mid-ship,
# PR #161 / commit dc7a46f, v4.6.12). Second gap: the highest-N allocator
# scanned only the filesystem, ignoring D-IDs that live ONLY in `git log --all`
# subjects or in TODOS.md (e.g. deferred D000023 — git/TODOS-only, no dir).
#
# This test builds a FULLY ISOLATED fixture tree (mktemp -d) — it does NOT
# depend on the live work-items/ tree or the live repo git history (both mutate
# every ship). It asserts the FIXED logic from pipeline.md:
#
#   Case 1: highest-N allocator reaches a depth-3 nested-domain fixture
#           (a/b/D000099_*) — a -maxdepth 2 scan would wrongly return 50.
#   Case 2: exact-D-ID resolver finds D000099 at the nested path.
#   Case 3: BASENAME_HITS fuzzy matcher finds D000099 at the nested path.
#   Case 4: highest-N allocator unions filesystem + git-log + TODOS.md D-IDs —
#           a TODOS-only / git-only D-ID greater than any on disk wins (proves
#           a deferred or shipped-and-relocated D-ID is never re-minted).
#
# The asserted snippets are byte-faithful extractions of the FIXED pipeline.md
# logic. A guard at the end greps pipeline.md to ensure no `-maxdepth 2` cap
# crept back onto any of the three defect find sites (prevents silent
# regression of the fix).

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
PIPELINE_MD="$REPO_ROOT/skills/CJ_goal_investigate/pipeline.md"

[ -f "$PIPELINE_MD" ] || { echo "FAIL: $PIPELINE_MD not found"; exit 1; }

# ---------- Isolated fixture tree ----------
#
# Layout (depths relative to $DEFECTS_ROOT):
#   x/D000050_x                       depth 2 (shallow, single-segment domain)
#   a/b/D000099_nested_fixture        depth 3 (nested 2-segment domain — the
#                                     exact shape the -maxdepth 2 bug missed)
# Plus an isolated TODOS.md carrying a D-ID (D000150) greater than any on disk,
# and a stubbed git-subject list carrying D000200 (greater still). NEITHER has
# a directory — they model a deferred / shipped-and-relocated D-ID.

T=$(mktemp -d -t cj-goal-investigate-did-allocator.XXXXXX)
trap 'rm -rf "$T"' EXIT

DEFECTS_ROOT="$T/work-items/defects"
mkdir -p "$DEFECTS_ROOT/x/D000050_x"
mkdir -p "$DEFECTS_ROOT/a/b/D000099_nested_fixture"

# Isolated TODOS.md: a D-ID with NO directory anywhere (deferred, like D000023).
cat > "$T/TODOS.md" <<'TODOS'
# TODOS

| ID | Pri | Status | Description |
|----|-----|--------|-------------|
| D000150 | P2 | deferred | a deferred defect that has NO directory — git/TODOS-only |
TODOS

# Stubbed git-subject list (do NOT depend on live repo git history).
GIT_SUBJECTS_STUB="$T/git-subjects.txt"
cat > "$GIT_SUBJECTS_STUB" <<'GITLOG'
v1.2.3 fix: D000099 some nested defect (#42)
chore: TODOS.md — defer D000200 eval-hardening (no dir minted)
v1.0.0 feat: unrelated commit with no D-ID
GITLOG

# ---------- Case 1: highest-N filesystem scan reaches depth-3 ----------
#
# FIXED snippet (filesystem half of the Step 7.4 union, verbatim logic):
echo ""
echo "Case 1: highest-N filesystem scan reaches the depth-3 nested fixture..."
_FS_NS=$(find "$DEFECTS_ROOT" -type d -name 'D[0-9][0-9][0-9][0-9][0-9][0-9]_*' 2>/dev/null \
         | sed -E 's|.*/D0*([0-9]+)_.*|\1|')
FS_MAX=$(printf '%s\n' "$_FS_NS" | grep -E '^[0-9]+$' | sort -n | tail -1)
if [ "$FS_MAX" = "99" ]; then
  ok "Case 1: filesystem max N=99 (deep scan reached a/b/D000099_*)"
else
  fail_test "Case 1: expected filesystem max N=99; got '$FS_MAX' (a -maxdepth 2 scan would wrongly return 50)"
fi

# Negative control: prove the OLD buggy -maxdepth 2 scan WOULD miss it (this is
# the bug being regression-guarded; assert the buggy form returns 50, not 99).
_BUGGY_NS=$(find "$DEFECTS_ROOT" -maxdepth 2 -type d -name 'D[0-9][0-9][0-9][0-9][0-9][0-9]_*' 2>/dev/null \
            | sed -E 's|.*/D0*([0-9]+)_.*|\1|')
BUGGY_MAX=$(printf '%s\n' "$_BUGGY_NS" | grep -E '^[0-9]+$' | sort -n | tail -1)
if [ "$BUGGY_MAX" = "50" ]; then
  ok "Case 1 (control): old -maxdepth 2 scan returns 50 — confirms the bug the fix removes"
else
  fail_test "Case 1 (control): expected old -maxdepth 2 scan to return 50; got '$BUGGY_MAX'"
fi

# ---------- Case 2: exact-D-ID resolver finds the nested defect ----------
#
# FIXED snippet (Step 2 exact-D-ID find, verbatim logic):
echo ""
echo "Case 2: exact-D-ID resolver finds D000099 at the nested depth-3 path..."
ARG="D000099"
MATCHES=$(find "$DEFECTS_ROOT" -type d -name "${ARG}_*" 2>/dev/null)
MATCH_COUNT=$(printf '%s\n' "$MATCHES" | grep -c '^[^[:space:]]' || true)
if [ "$MATCH_COUNT" = "1" ] && echo "$MATCHES" | grep -q '/a/b/D000099_nested_fixture$'; then
  ok "Case 2: exact-D-ID resolved D000099 at .../a/b/D000099_nested_fixture"
else
  fail_test "Case 2: expected 1 match at .../a/b/D000099_nested_fixture; got count=$MATCH_COUNT matches=[$MATCHES]"
fi

# ---------- Case 3: BASENAME_HITS fuzzy matcher finds the nested defect ----------
#
# FIXED snippet (Step 2 BASENAME_HITS find, verbatim logic):
echo ""
echo "Case 3: BASENAME_HITS fuzzy matcher finds the nested defect..."
ARG="nested_fixture"
ARG_GLOB=$(printf '%s' "$ARG" | sed 's/[][*?]/\\&/g')
BASENAME_HITS=$(find "$DEFECTS_ROOT" -type d -iname "*${ARG_GLOB}*" 2>/dev/null \
                | grep -E '/D[0-9]{6}_' || true)
if echo "$BASENAME_HITS" | grep -q '/a/b/D000099_nested_fixture$'; then
  ok "Case 3: fuzzy BASENAME_HITS resolved the nested defect"
else
  fail_test "Case 3: expected BASENAME_HITS to include .../a/b/D000099_nested_fixture; got [$BASENAME_HITS]"
fi

# ---------- Case 4: allocator unions filesystem + git-log + TODOS.md ----------
#
# FIXED snippet (full Step 7.4 union, verbatim logic — git source swapped for
# the stubbed subject list so this does NOT depend on live repo history):
echo ""
echo "Case 4: highest-N unions filesystem + git-log + TODOS.md D-IDs..."
_FS_NS=$(find "$DEFECTS_ROOT" -type d -name 'D[0-9][0-9][0-9][0-9][0-9][0-9]_*' 2>/dev/null \
         | sed -E 's|.*/D0*([0-9]+)_.*|\1|')
# Stubbed git subjects (mirrors `git -C "$_REPO_ROOT" log --all --format='%s'`):
_GIT_NS=$(grep -oE 'D[0-9]{6}' "$GIT_SUBJECTS_STUB" 2>/dev/null | sed -E 's|D0*([0-9]+)|\1|')
_TODOS_NS=""
if [ -f "$T/TODOS.md" ]; then
  _TODOS_NS=$(grep -oE 'D[0-9]{6}' "$T/TODOS.md" 2>/dev/null | sed -E 's|D0*([0-9]+)|\1|')
fi
HIGHEST=$(printf '%s\n%s\n%s\n' "$_FS_NS" "$_GIT_NS" "$_TODOS_NS" \
          | grep -E '^[0-9]+$' | sort -n | tail -1)
NEXT_N=$(( ${HIGHEST:-0} + 1 ))
NEXT_ID=$(printf "D%06d" "$NEXT_N")
# On-disk max = 99, TODOS-only = 150, git-only = 200 → union max = 200 → next D000201.
if [ "$HIGHEST" = "200" ] && [ "$NEXT_ID" = "D000201" ]; then
  ok "Case 4: union max=200 (git-only D000200 beat on-disk 99 + TODOS 150) → next=D000201"
else
  fail_test "Case 4: expected union max=200 / next=D000201; got HIGHEST=$HIGHEST NEXT_ID=$NEXT_ID"
fi

# ---------- Guard: no -maxdepth 2 crept back onto the 3 defect find sites ----------
#
# pipeline.md must NOT contain a `find "$DEFECTS_ROOT" -maxdepth 2` on any of
# the three defect-resolver/allocator sites. (`-maxdepth 1` on the unrelated
# *_TRACKER.md find at Step 2 tail is fine and intentional — that scans a
# single known dir, not the defects tree.)
echo ""
echo "Guard: no '-maxdepth 2' on any \$DEFECTS_ROOT find in pipeline.md..."
if grep -nE 'find "\$DEFECTS_ROOT"[^|]*-maxdepth 2' "$PIPELINE_MD"; then
  fail_test "Guard: a 'find \"\$DEFECTS_ROOT\" ... -maxdepth 2' reappeared in pipeline.md (D000022 regression)"
else
  ok "Guard: no -maxdepth 2 cap on any \$DEFECTS_ROOT find (fix intact)"
fi

# ---------- Summary ----------

echo ""
echo "=== cj-goal-investigate-did-allocator.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
