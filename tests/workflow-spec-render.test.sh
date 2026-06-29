#!/usr/bin/env bash
# tests/workflow-spec-render.test.sh
#
# Test for the F000069 / S000115 workflow-docs registry + renderer in
# scripts/workflow-spec.sh — the THIRD instance of the proven
# README ↔ generate-readme.sh ↔ Check 25 + test-catalog ↔ Check 26
# generate→freshness→audit primitive, applied to the workflow surface. Covers
# TEST-SPEC S2/S3/S4 (deterministic + ID-free + --check round-trip) plus the
# no-vanish drill (the retired-Check-15c replacement):
#   T1 (resilience)    — --render-docs twice into two temp dirs is BYTE-IDENTICAL
#                        (registry order, fixed headers, no timestamps).
#   T2 (resilience)    — the rendered output is work-item-ID-free (no
#                        [FSTD][0-9]{6} anywhere — masked).
#   T3 (observability) — --render-docs --check exits 0 on a freshly-rendered tree.
#   T4 (observability) — --check exits 1 (naming the file) after a hand-edit to a
#                        generated file, and again after a generated file is
#                        removed (missing-file finding).
#   T5 (integration)   — the LIVE committed docs/workflow.md + docs/workflows/*.md
#                        are in sync with a fresh render (the Check-27 invariant).
#   T6 (core)          — the remove-an-entry drill: in a hermetic temp repo with a
#                        catalog declaring a routable CJ_goal_* skill, --validate
#                        passes when the registry has the matching orchestrator
#                        entry and FAILS CLOSED (exit non-zero, naming the missing
#                        workflow) when that entry is removed. This is the
#                        no-vanish guarantee that replaces retired Check 15c.
#
# HERMETIC: T1–T4 render into THROWAWAY temp dirs via the WORKFLOWDOC_OUT override;
# the live committed tree is never mutated. T5 is read-only against the live tree.
# T6 builds a throwaway repo (REPO_ROOT + WORKFLOW_SPEC_PATH overrides) — never
# touches the real catalog or registry. No ~/.claude touch, no git mutation.
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
ENGINE="$REPO_ROOT/scripts/workflow-spec.sh"

echo "=== workflow-spec-render.test.sh: workflow-docs registry renderer + freshness + no-vanish — hermetic ==="

[ -f "$ENGINE" ] || { echo "RESULT: FAIL ($ENGINE not found)"; exit 1; }

# ── T1: render twice into two temp dirs → byte-identical (deterministic) ──────
T1A=$(mktemp -d -t wsrender-a-XXXXXX)
T1B=$(mktemp -d -t wsrender-b-XXXXXX)
WORKFLOWDOC_OUT="$T1A/docs" bash "$ENGINE" --render-docs >/dev/null 2>&1
WORKFLOWDOC_OUT="$T1B/docs" bash "$ENGINE" --render-docs >/dev/null 2>&1
if diff -r "$T1A/docs" "$T1B/docs" >/dev/null 2>&1; then
  ok "T1: two consecutive renders are byte-identical (deterministic)"
else
  fail_test "T1: renders differ across runs (non-deterministic):"
  diff -r "$T1A/docs" "$T1B/docs" >&2 || true
fi
# Sanity: the render produced the index + at least one per-workflow page.
if [ -f "$T1A/docs/workflow.md" ] && ls "$T1A/docs/workflows/"*.md >/dev/null 2>&1; then
  ok "T1: render produced docs/workflow.md + docs/workflows/<name>.md"
else
  fail_test "T1: render did not produce the expected workflow files under $T1A/docs"
fi

# ── T2: the rendered output is work-item-ID-free ─────────────────────────────
if grep -rE '[FSTD][0-9]{6}' "$T1A/docs" >/dev/null 2>&1; then
  fail_test "T2: rendered workflow surface contains a work-item ID (must be ID-free for Check 19):"
  grep -rEn '[FSTD][0-9]{6}' "$T1A/docs" | head -5 >&2 || true
else
  ok "T2: rendered workflow surface is work-item-ID-free (passes Check 19 by construction)"
fi

# ── T3: --render-docs --check exits 0 on a freshly-rendered tree ──────────────
T3=$(mktemp -d -t wsrender-c-XXXXXX)
WORKFLOWDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs >/dev/null 2>&1
if WORKFLOWDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs --check >/dev/null 2>&1; then
  ok "T3: --check exits 0 on a freshly-rendered tree"
else
  fail_test "T3: --check should exit 0 on a fresh render but exited non-zero"
fi

# ── T4: --check fails (exit 1, naming the file) after a hand-edit / a removal ─
# 4a — hand-edit a generated file.
printf '\nhand-edit drift line\n' >> "$T3/docs/workflow.md"
_T4A_OUT=$(WORKFLOWDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs --check 2>&1)
_T4A_RC=$?
if [ "$_T4A_RC" -ne 0 ] && printf '%s\n' "$_T4A_OUT" | grep -qF "workflow.md is stale"; then
  ok "T4a: a hand-edited generated file → --check exit non-zero + names the stale file"
else
  fail_test "T4a: --check should fail naming the stale file (rc=$_T4A_RC); output: $_T4A_OUT"
fi
# Regenerate → green again.
WORKFLOWDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs >/dev/null 2>&1
if WORKFLOWDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs --check >/dev/null 2>&1; then
  ok "T4a: --check exits 0 again after regenerate"
else
  fail_test "T4a: --check should exit 0 after regenerate but exited non-zero"
fi
# 4b — remove a generated per-workflow page → missing-file finding.
_VICTIM=$(ls "$T3/docs/workflows/"*.md 2>/dev/null | head -1)
if [ -n "$_VICTIM" ]; then
  rm -f "$_VICTIM"
  _T4B_OUT=$(WORKFLOWDOC_OUT="$T3/docs" bash "$ENGINE" --render-docs --check 2>&1)
  _T4B_RC=$?
  if [ "$_T4B_RC" -ne 0 ] && printf '%s\n' "$_T4B_OUT" | grep -qF "is missing on disk"; then
    ok "T4b: a missing generated file → --check exit non-zero + names the missing file"
  else
    fail_test "T4b: --check should fail naming the missing file (rc=$_T4B_RC); output: $_T4B_OUT"
  fi
else
  fail_test "T4b: no per-workflow page found to remove for the missing-file drill"
fi

# ── T5: the LIVE committed surface is in sync with a fresh render (Check-27) ──
if bash "$ENGINE" --render-docs --check >/dev/null 2>&1; then
  ok "T5: live committed docs/workflow.md + docs/workflows/ are in sync with the registry"
else
  fail_test "T5: live committed workflow surface is stale vs the registry — run: bash scripts/workflow-spec.sh --render-docs"
fi

# ── T6: the no-vanish drill — --validate registry-completeness fails closed ───
# Build a hermetic temp "repo": a skills-catalog.json declaring one routable
# CJ_goal_* skill + a spec/workflow-spec.md with the matching orchestrator entry.
# --validate passes complete; removing the entry makes it fail closed (exit
# non-zero, naming the missing workflow). This is the retired-Check-15c
# replacement (the source-of-truth completeness guarantee).
T6=$(mktemp -d -t wsrender-novanish-XXXXXX)
mkdir -p "$T6/spec" "$T6/skills/CJ_goal_zzz"
cat > "$T6/skills-catalog.json" <<'CATEOF'
[
  {
    "name": "CJ_goal_zzz",
    "version": "0.1.0",
    "description": "Fixture orchestrator for the no-vanish drill.",
    "source": "local",
    "depends": { "skills": [], "tools": [] },
    "portability": "workbench",
    "files": ["skills/CJ_goal_zzz/SKILL.md"],
    "templates": [],
    "status": "experimental"
  }
]
CATEOF
# A complete fixture registry: header + the matching CJ_goal_zzz orchestrator.
cat > "$T6/spec/workflow-spec.md" <<'WSEOF'
<!-- WORKFLOW-SPEC:BEGIN (parsed by scripts/workflow-spec.sh) -->
# workflow-spec.md — fixture

<!-- WORKFLOW-SPEC-HEADER:BEGIN -->
````header
# Workflows

Fixture index preamble.
````
<!-- WORKFLOW-SPEC-HEADER:END -->

## CJ_goal_zzz
kind: orchestrator
status: experimental (fixture)
category: workbench (fixture)
source: `skills/CJ_goal_zzz/SKILL.md`
invoke_when: a fixture orchestrator for the hermetic no-vanish drill. It proves registry-completeness fails closed.

````chart
"<fixture>"
   v
done
````

````summary
a fixture orchestrator used only by the hermetic test to prove the no-vanish guarantee.
````

````touches-skills
- **Skills dispatched:** none (fixture).
````

````touches-steps
- **Steps · phases:** none (fixture).
````

````touches-scripts
- **Scripts · tools · shell:** none (fixture).
````

````touches-docs
- **Docs touched:** none (fixture).
````
<!-- WORKFLOW-SPEC:END -->
WSEOF

# 6a — complete registry → --validate exits 0.
if REPO_ROOT="$T6" WORKFLOW_SPEC_PATH="$T6/spec/workflow-spec.md" bash "$ENGINE" --validate >/dev/null 2>&1; then
  ok "T6a: --validate exits 0 when every routable CJ_goal_* has an orchestrator entry (completeness satisfied)"
else
  fail_test "T6a: --validate should exit 0 on the complete fixture registry but exited non-zero"
fi

# 6b — remove the orchestrator entry (everything from `## CJ_goal_zzz` to the
# END marker, then re-append the END marker) → --validate fails closed.
awk '
  /^## CJ_goal_zzz$/ { skip=1 }
  /^<!-- WORKFLOW-SPEC:END/ { skip=0 }
  !skip { print }
' "$T6/spec/workflow-spec.md" > "$T6/spec/workflow-spec.stripped.md"
printf '<!-- WORKFLOW-SPEC:END -->\n' >> "$T6/spec/workflow-spec.stripped.md"
mv "$T6/spec/workflow-spec.stripped.md" "$T6/spec/workflow-spec.md"
_T6B_OUT=$(REPO_ROOT="$T6" WORKFLOW_SPEC_PATH="$T6/spec/workflow-spec.md" bash "$ENGINE" --validate 2>&1)
_T6B_RC=$?
if [ "$_T6B_RC" -ne 0 ] \
   && printf '%s\n' "$_T6B_OUT" | grep -qF "registry-completeness" \
   && printf '%s\n' "$_T6B_OUT" | grep -qF "CJ_goal_zzz"; then
  ok "T6b: removing a CJ_goal_* orchestrator entry → --validate fails closed naming the missing workflow (no-vanish)"
else
  fail_test "T6b: --validate should fail closed naming CJ_goal_zzz after the entry is removed (rc=$_T6B_RC); output: $_T6B_OUT"
fi

# Cleanup throwaway temp dirs.
rm -rf "$T1A" "$T1B" "$T3" "$T6"

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS error(s))"
  exit 1
fi
