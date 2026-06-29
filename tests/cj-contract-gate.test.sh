#!/usr/bin/env bash
# tests/cj-contract-gate.test.sh — hermetic test for the deterministic contract
# gate + its guarded consumer pre-commit auto-install (F000069 / S000117).
#
# The gate (scripts/cj-contract-gate.sh) is the engine-only Stage-1 subset of
# validate.sh, runnable with NO agent, so a consumer repo can enforce its
# doc/test/workflow contract from a git hook / CI step. This suite proves:
#
#   PART (a) — gate dispositions (cases map to S000117_TEST-SPEC.md smoke S1):
#     A1  clean contract                         → PASS, exit 0
#     A2  planted HARD violation (stale catalog)  → BLOCK, exit 1
#     A3  malformed registry (test-spec invalid)  → BLOCK, exit 1
#     A4  missing DECLARED doc                     → SOFT REMEDIATION, exit 0 (not a block)
#     A5  registry-absent (no contracts)           → clean SKIP, exit 0
#
#   PART (b) — guarded consumer install (smoke S2/S3/S4):
#     B1  consumer auto-install installs a sentinel pre-commit hook + idempotent
#     B2  a temp repo with core.hooksPath set (husky) is SKIPPED
#     B3  the workbench self-repo is SKIPPED
#     B4  install-contract-gate --remove uninstalls a sentinel hook; a
#         non-workbench hook is left UNTOUCHED
#
# Harness style mirrors tests/seed-contracts.test.sh: ok/fail_test counters, a
# per-case temp git sandbox, a PASS/FAIL summary. Fully hermetic — every sandbox
# is a throwaway repo, the engines + gate resolve from a pinned _cj-shared (the
# repo's own scripts/), and SKILLS_DEPLOY_MANIFEST is overridden, so the live
# workbench and the operator's real ~/.claude are never touched.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); return 1; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
DEPLOY="$REPO_ROOT/scripts/skills-deploy"
GATE="$REPO_ROOT/scripts/cj-contract-gate.sh"
SENTINEL='# Auto-installed by scripts/setup-hooks.sh'

[ -x "$GATE" ]   || { echo "FAIL: $GATE not executable"; exit 1; }
[ -x "$DEPLOY" ] || { echo "FAIL: $DEPLOY not executable"; exit 1; }

# Pin the deployed _cj-shared home to the repo's own scripts/ so the engines + the
# gate resolve without touching the operator's real ~/.claude/_cj-shared.
SHARED_PIN="$REPO_ROOT/scripts"
export CJ_SHARED_SCRIPTS="$SHARED_PIN"
export SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$SHARED_PIN"

# Cleanup is keyed off a single parent temp dir.
WORK=$(mktemp -d -t cj-contract-gate.XXXXXX)
# A manifest whose source/bundle_path point nowhere real, so a fresh sandbox is
# NEVER mistaken for the workbench self-repo via the manifest signal.
printf '{"source":"/nonexistent/workbench","bundle_path":"/nonexistent/workbench"}\n' > "$WORK/manifest.json"
export SKILLS_DEPLOY_MANIFEST="$WORK/manifest.json"
# shellcheck disable=SC2064
trap "rm -rf '$WORK' 2>/dev/null" EXIT

mk_sandbox() {
  local dir
  dir=$(mktemp -d "$WORK/sandbox.XXXXXX")
  git -C "$dir" init -q
  git -C "$dir" config user.email t@t.t
  git -C "$dir" config user.name t
  echo "$dir"
}

# Build a GENUINELY clean, fully-adopted contract in $1: README + the three
# contracts (a rules-only test-spec, a one-roster workflow-spec) + the rendered
# generated surfaces (docs/test-catalog.md, docs/workflow.md, docs/workflows/*.md)
# + a doc-spec declaring exactly what exists. The gate must PASS on this state.
mk_clean_contract() {
  local d="$1"
  local ts="$REPO_ROOT/scripts/test-spec.sh"
  local ws="$REPO_ROOT/scripts/workflow-spec.sh"
  mkdir -p "$d/spec"
  echo "# Test repo" > "$d/README.md"
  env REPO_ROOT="$d" bash "$ts" --seed > "$d/spec/test-spec.md"
  # workflow-spec seed + ONE roster section inserted before the END marker (a
  # roster renders to a docs/workflows/*.md, satisfying the non-empty
  # workflows-subfolder check). No `awk -v` — a read-loop splice (BSD-awk safe).
  env REPO_ROOT="$d" bash "$ws" --seed > "$d/spec/workflow-spec.md.tmp"
  local rf out
  rf=$(mktemp "$WORK/roster.XXXXXX")
  # shellcheck disable=SC2016  # the backtick fences are literal registry content, not command substitution
  printf '\n## utilities-and-phase-steps\nkind: roster\n\n````body\n## Utilities\n\nUtility + phase-step skills.\n````\n' > "$rf"
  out=$(mktemp "$WORK/wfspec.XXXXXX")
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    [ "$line" = "<!-- WORKFLOW-SPEC:END -->" ] && cat "$rf" >> "$out"
    printf '%s\n' "$line" >> "$out"
  done < "$d/spec/workflow-spec.md.tmp"
  mv "$out" "$d/spec/workflow-spec.md"
  rm -f "$d/spec/workflow-spec.md.tmp"
  # Render the generated surfaces from the registries.
  env REPO_ROOT="$d" bash "$ts" --render-docs >/dev/null 2>&1
  env REPO_ROOT="$d" bash "$ws" --render-docs >/dev/null 2>&1
  # doc-spec declaring README + the spec files + every generated doc (so no orphan,
  # no declared-missing).
  {
    echo "# doc-spec.md"; echo
    echo "| Doc | Purpose | Requirement |"
    echo "|-----|---------|-------------|"
    echo "| README.md | Repo landing. | Has content. |"
    echo "| spec/doc-spec.md | Doc contract. | Present. |"
    echo "| spec/test-spec.md | Test contract. | Present. |"
    echo "| spec/workflow-spec.md | Workflow contract. | Present. |"
    local f
    while IFS= read -r f; do
      echo "| $f | Generated doc. | In sync. |"
    done < <(cd "$d" && find docs -name '*.md' | sort)
  } > "$d/spec/doc-spec.md"
}

echo "=== cj-contract-gate.test.sh ==="

# ───────────────────────── PART (a): gate dispositions ─────────────────────────

# ---------- A0: a FRESHLY-ADOPTED consumer is gate-clean (THE key regression) ----------
# The brick-on-adoption guard: a fresh consumer that ran the real adoption path
# (seed → complete adoption: refresh generated surfaces + auto-declare repo docs)
# must PASS the FULLY-HARD gate (only declared-exists soft remains — the prose docs
# that can't be auto-authored). This is the regression that proves auto-installing
# the gate never bricks a fresh adopter.
if ! (
  S=$(mk_sandbox)
  a_ok=yes
  "$DEPLOY" seed-contracts --repo "$S" >/dev/null 2>&1 || { fail_test "A0: seed-contracts failed"; a_ok=no; }
  "$DEPLOY" install-contract-gate --repo "$S" >/dev/null 2>&1 || { fail_test "A0: install-contract-gate failed"; a_ok=no; }
  [ -f "$S/spec/doc-spec-custom.md" ] || { fail_test "A0: adoption did not write spec/doc-spec-custom.md"; a_ok=no; }
  grep -qF 'auto-generated by skills-deploy' "$S/spec/doc-spec-custom.md" 2>/dev/null || { fail_test "A0: overlay missing the auto-generated marker"; a_ok=no; }
  [ -f "$S/docs/workflow.md" ] || { fail_test "A0: adoption did not render docs/workflow.md"; a_ok=no; }
  [ -f "$S/docs/test-catalog.md" ] || { fail_test "A0: adoption did not render docs/test-catalog.md"; a_ok=no; }
  out=$(bash "$GATE" --repo "$S" 2>&1); rc=$?
  [ "$rc" -eq 0 ] || { fail_test "A0: gate exited $rc on a freshly-ADOPTED consumer (expected 0 — the brick guard)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'VERDICT: PASS' || { fail_test "A0: no PASS verdict on a freshly-adopted consumer (out: $out)"; a_ok=no; }
  if printf '%s\n' "$out" | grep -q 'doc-spec/check-on-disk: FINDING'; then fail_test "A0: a HARD doc-contract finding survived adoption (orphan/workflows-subfolder not resolved)"; a_ok=no; fi
  [ "$a_ok" = yes ] && ok "A0: a freshly-ADOPTED consumer (seed + complete-adoption) is gate-clean — exit 0 (the brick-on-adoption guard)"
  [ "$a_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- A1: clean contract → PASS (exit 0) ----------
if ! (
  S=$(mk_sandbox)
  mk_clean_contract "$S"
  a_ok=yes
  out=$(bash "$GATE" --repo "$S" 2>&1); rc=$?
  [ "$rc" -eq 0 ] || { fail_test "A1: gate exited $rc on a clean contract (expected 0)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'VERDICT: PASS' || { fail_test "A1: no PASS verdict on clean contract (out: $out)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'doc-spec/check-on-disk: PASS' || { fail_test "A1: doc-spec check-on-disk not PASS"; a_ok=no; }
  [ "$a_ok" = yes ] && ok "A1: gate PASSes (exit 0) on a clean, fully-adopted contract"
  [ "$a_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- A2: planted HARD violation (stale generated catalog) → BLOCK ----------
if ! (
  S=$(mk_sandbox)
  mk_clean_contract "$S"
  echo "STALE TAMPER LINE" >> "$S/docs/test-catalog.md"
  a_ok=yes
  out=$(bash "$GATE" --repo "$S" 2>&1); rc=$?
  [ "$rc" -ne 0 ] || { fail_test "A2: gate exited 0 on a stale catalog (expected non-zero)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'test-spec/render-docs-check: FINDING' || { fail_test "A2: render-docs-check did not FIND the stale catalog (out: $out)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'VERDICT: BLOCK' || { fail_test "A2: no BLOCK verdict on stale catalog"; a_ok=no; }
  [ "$a_ok" = yes ] && ok "A2: gate hard-FAILS (exit 1) on a stale generated catalog"
  [ "$a_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- A3: malformed registry (test-spec --validate fails) → BLOCK ----------
if ! (
  S=$(mk_sandbox)
  mk_clean_contract "$S"
  # Corrupt the test-spec registry: set schema_version to a non-supported value so
  # --validate hard-fails ([test-spec-no-config]).
  perl -pi -e 's/^schema_version:.*/schema_version: notanumber/' "$S/spec/test-spec.md"
  a_ok=yes
  out=$(bash "$GATE" --repo "$S" 2>&1); rc=$?
  [ "$rc" -ne 0 ] || { fail_test "A3: gate exited 0 on a malformed test-spec (expected non-zero)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'test-spec/validate: FINDING' || { fail_test "A3: test-spec/validate did not FIND the malformed registry (out: $out)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'VERDICT: BLOCK' || { fail_test "A3: no BLOCK verdict on malformed registry"; a_ok=no; }
  [ "$a_ok" = yes ] && ok "A3: gate hard-FAILS (exit 1) on a malformed test-spec registry"
  [ "$a_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- A4: missing DECLARED doc → SOFT REMEDIATION (exit 0, not a block) ----------
if ! (
  S=$(mk_sandbox)
  mk_clean_contract "$S"
  # Delete a declared doc (README) — a declared-exists finding, which is SOFT.
  rm -f "$S/README.md"
  a_ok=yes
  out=$(bash "$GATE" --repo "$S" 2>&1); rc=$?
  [ "$rc" -eq 0 ] || { fail_test "A4: gate exited $rc on a missing declared doc (expected 0 — soft)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'doc-spec/declared-exists: REMEDIATION' || { fail_test "A4: no REMEDIATION note for the missing declared doc (out: $out)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q '/CJ_document-release' || { fail_test "A4: REMEDIATION note did not point at /CJ_document-release"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'VERDICT: PASS' || { fail_test "A4: a missing declared doc was treated as a BLOCK (expected soft PASS)"; a_ok=no; }
  [ "$a_ok" = yes ] && ok "A4: a missing DECLARED doc is a SOFT remediation (exit 0; points at /CJ_document-release; not a block)"
  [ "$a_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- A5: registry-absent → clean SKIP (exit 0) ----------
if ! (
  S=$(mk_sandbox)   # no contracts at all
  a_ok=yes
  out=$(bash "$GATE" --repo "$S" 2>&1); rc=$?
  [ "$rc" -eq 0 ] || { fail_test "A5: gate exited $rc on a registry-absent repo (expected 0 — skip)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'doc-spec/check-on-disk: SKIP — REGISTRY=absent' || { fail_test "A5: doc-spec not a registry-absent SKIP (out: $out)"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'workflow-spec/validate: SKIP — REGISTRY=absent' || { fail_test "A5: workflow-spec not a registry-absent SKIP"; a_ok=no; }
  printf '%s\n' "$out" | grep -q 'VERDICT: PASS' || { fail_test "A5: registry-absent repo did not PASS"; a_ok=no; }
  [ "$a_ok" = yes ] && ok "A5: an unadopted contract (REGISTRY=absent) is a clean SKIP (exit 0)"
  [ "$a_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ───────────────────── PART (b): guarded consumer install ──────────────────────

# ---------- B1: consumer auto-install installs a sentinel hook + idempotent ----------
if ! (
  S=$(mk_sandbox)
  b_ok=yes
  "$DEPLOY" install-contract-gate --repo "$S" >/dev/null 2>&1
  hook="$S/.git/hooks/pre-commit"
  [ -f "$hook" ] || { fail_test "B1: no pre-commit hook installed"; b_ok=no; }
  grep -qF "$SENTINEL" "$hook" 2>/dev/null || { fail_test "B1: installed hook lacks the setup-hooks SENTINEL"; b_ok=no; }
  grep -q 'cj-contract-gate.sh' "$hook" 2>/dev/null || { fail_test "B1: hook body does not resolve cj-contract-gate.sh"; b_ok=no; }
  grep -q 'CJ_SHARED_SCRIPTS' "$hook" 2>/dev/null || { fail_test "B1: hook body does not resolve from _cj-shared (\$CJ_SHARED_SCRIPTS)"; b_ok=no; }
  # Idempotent re-run: no backup file created (a backup ⇒ it treated its own hook as foreign).
  "$DEPLOY" install-contract-gate --repo "$S" >/dev/null 2>&1
  # shellcheck disable=SC2012
  baks=$(ls "$S/.git/hooks/"*.bak 2>/dev/null | wc -l | tr -d ' ')
  [ "$baks" = "0" ] || { fail_test "B1: re-install was not idempotent (a .bak appeared — own hook treated as foreign)"; b_ok=no; }
  [ "$b_ok" = yes ] && ok "B1: consumer install-contract-gate installs a sentinel hook resolving cj-contract-gate.sh from _cj-shared; re-run idempotent"
  [ "$b_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- B2: custom core.hooksPath (husky) → SKIPPED ----------
if ! (
  S=$(mk_sandbox)
  git -C "$S" config core.hooksPath .husky
  b_ok=yes
  out=$("$DEPLOY" install-contract-gate --repo "$S" 2>&1)
  printf '%s\n' "$out" | grep -q 'custom core.hooksPath' || { fail_test "B2: custom core.hooksPath not noted as skipped (out: $out)"; b_ok=no; }
  [ -f "$S/.git/hooks/pre-commit" ] && { fail_test "B2: a hook was installed into .git/hooks despite a custom core.hooksPath"; b_ok=no; }
  [ "$b_ok" = yes ] && ok "B2: a repo with a custom core.hooksPath (husky) is SKIPPED with a note (does not fight the committed hooks dir)"
  [ "$b_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- B3: workbench self-repo → SKIPPED ----------
if ! (
  S=$(mk_sandbox)
  MAIN_TOP=$(git -C "$S" rev-parse --show-toplevel)
  SELF_MANIFEST=$(mktemp "$WORK/self-manifest.XXXXXX")
  printf '{"source":"%s","bundle_path":"%s"}\n' "$MAIN_TOP" "$MAIN_TOP" > "$SELF_MANIFEST"
  b_ok=yes
  out=$(SKILLS_DEPLOY_MANIFEST="$SELF_MANIFEST" "$DEPLOY" install-contract-gate --repo "$S" 2>&1)
  printf '%s\n' "$out" | grep -q 'workbench self-repo' || { fail_test "B3: workbench self-repo not detected/skipped (out: $out)"; b_ok=no; }
  [ -f "$S/.git/hooks/pre-commit" ] && { fail_test "B3: a gate hook was installed into the workbench self-repo (it runs validate.sh — no double-enforce)"; b_ok=no; }
  [ "$b_ok" = yes ] && ok "B3: the workbench self-repo is SKIPPED (it enforces via validate.sh — no double-enforcement)"
  [ "$b_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- B4: --remove uninstalls a sentinel hook; a non-workbench hook untouched ----------
if ! (
  b_ok=yes
  # (i) --remove uninstalls a sentinel hook.
  S=$(mk_sandbox)
  "$DEPLOY" install-contract-gate --repo "$S" >/dev/null 2>&1
  [ -f "$S/.git/hooks/pre-commit" ] || { fail_test "B4(i): precondition — gate hook not installed"; b_ok=no; }
  "$DEPLOY" install-contract-gate --repo "$S" --remove >/dev/null 2>&1
  [ -f "$S/.git/hooks/pre-commit" ] && { fail_test "B4(i): --remove did not uninstall the sentinel hook"; b_ok=no; }
  # (ii) --remove leaves a NON-workbench hook UNTOUCHED.
  S2=$(mk_sandbox)
  printf '#!/usr/bin/env bash\necho my-custom-hook\n' > "$S2/.git/hooks/pre-commit"
  chmod +x "$S2/.git/hooks/pre-commit"
  out=$("$DEPLOY" install-contract-gate --repo "$S2" --remove 2>&1)
  printf '%s\n' "$out" | grep -q 'NOT workbench-owned' || { fail_test "B4(ii): --remove did not report a non-workbench hook as left untouched (out: $out)"; b_ok=no; }
  grep -q 'my-custom-hook' "$S2/.git/hooks/pre-commit" 2>/dev/null || { fail_test "B4(ii): --remove clobbered a non-workbench hook"; b_ok=no; }
  [ "$b_ok" = yes ] && ok "B4: --remove uninstalls ONLY the sentinel hook; a non-workbench pre-commit hook is left UNTOUCHED"
  [ "$b_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- Summary ----------
echo ""
echo "=== cj-contract-gate.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
