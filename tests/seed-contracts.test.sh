#!/usr/bin/env bash
# tests/seed-contracts.test.sh — test for `skills-deploy seed-contracts` +
# the stale-engine capability probe (F000069 / S000116).
#
# Forced contract seeding makes adoption reliable: `do_seed_contracts` force-seeds
# the three contracts (spec/doc-spec.md, spec/test-spec.md, spec/workflow-spec.md)
# into a CONSUMER repo, corruption-guarded + idempotent, while the workbench
# self-repo is NEVER touched (the data-loss guard). The stale-engine probe is the
# actual bug fix — a stale vendored repo-local engine (no --classify) no longer
# shadows the deployed _cj-shared engine.
#
# Cases (map to S000116_TEST-SPEC.md smoke rows S1-S3):
#   (A) seed-all-3 + valid + idempotent          [S1 / AC-2,AC-4]
#   (B) workbench self-repo SKIPPED (data-loss)  [S1 / AC-3]
#   (C) stale repo-local engine → _cj-shared +
#       stage1/engine-stale finding emitted       [S2 / AC-1]
#   (D) corruption guard: --validate-dirty seed
#       → seed-failed, nothing written to spec/   [S3 / AC-2]
#
# Harness style mirrors tests/cj-id-claim.test.sh: ok/fail_test counters, a
# per-case temp git sandbox, and a PASS/FAIL summary. Fully hermetic — every seed
# lands inside a throwaway sandbox repo, the engines resolve from a pinned
# _cj-shared (the repo's own scripts/), and SKILLS_DEPLOY_MANIFEST is overridden,
# so the live workbench and the operator's real ~/.claude are never touched.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); return 1; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
DEPLOY="$REPO_ROOT/scripts/skills-deploy"

[ -x "$DEPLOY" ] || { echo "FAIL: $DEPLOY not executable"; exit 1; }

# Pin the deployed _cj-shared home to the repo's own scripts/ so the engines
# resolve without touching the operator's real ~/.claude/_cj-shared. Pin the
# manifest to a temp file so is_workbench_self_repo reads a controlled source.
SHARED_PIN="$REPO_ROOT/scripts"
MANIFEST_TMP=$(mktemp)
# A manifest whose source/bundle_path point nowhere real, so a fresh sandbox is
# NEVER mistaken for the workbench self-repo via the manifest signal.
printf '{"source":"/nonexistent/workbench","bundle_path":"/nonexistent/workbench"}\n' > "$MANIFEST_TMP"

export SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$SHARED_PIN"
export SKILLS_DEPLOY_MANIFEST="$MANIFEST_TMP"

# Cleanup is keyed off a single parent temp dir so subshell additions are not
# needed (a subshell `+=` would not propagate to the parent — SC2030/SC2031).
# Every sandbox + temp manifest is created UNDER $WORK so one rm -rf clears all.
WORK=$(mktemp -d -t cj-seed-contracts.XXXXXX)
mv "$MANIFEST_TMP" "$WORK/manifest.json"
MANIFEST_TMP="$WORK/manifest.json"
export SKILLS_DEPLOY_MANIFEST="$MANIFEST_TMP"
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

# Validate a seeded contract with REPO_ROOT pinned to the sandbox so the engine
# reads the sandbox tree (e.g. workflow-spec's no-vanish is vacuous with no
# catalog). Both env vars are passed via `env` so they reach the forked bash.
validate_contract() {
  local engine="$1" sandbox="$2" path_var="$3"
  env "REPO_ROOT=$sandbox" "$path_var=$sandbox/spec/$engine.md" \
    bash "$REPO_ROOT/scripts/$engine.sh" --validate >/dev/null 2>&1
}

echo "=== seed-contracts.test.sh ==="

# ---------- Case A: seed-all-3 + valid + idempotent ----------
if ! (
  S=$(mk_sandbox)
  out1=$("$DEPLOY" seed-contracts --repo "$S" 2>&1)
  a_ok=yes
  # all three files written
  for c in doc-spec test-spec workflow-spec; do
    [ -f "$S/spec/$c.md" ] || { fail_test "Case A: $c.md not seeded"; a_ok=no; }
  done
  # each --validate-clean
  validate_contract doc-spec "$S" DOC_SPEC_PATH       || { fail_test "Case A: doc-spec.md not validate-clean"; a_ok=no; }
  validate_contract test-spec "$S" TEST_SPEC_PATH     || { fail_test "Case A: test-spec.md not validate-clean"; a_ok=no; }
  validate_contract workflow-spec "$S" WORKFLOW_SPEC_PATH || { fail_test "Case A: workflow-spec.md not validate-clean"; a_ok=no; }
  # first run reported all three seeded
  printf '%s\n' "$out1" | grep -q 'doc-spec: seeded'      || { fail_test "Case A: first run did not report doc-spec seeded"; a_ok=no; }
  printf '%s\n' "$out1" | grep -q 'workflow-spec: seeded' || { fail_test "Case A: first run did not report workflow-spec seeded"; a_ok=no; }
  # re-run is idempotent (all present, nothing re-seeded)
  out2=$("$DEPLOY" seed-contracts --repo "$S" 2>&1)
  printf '%s\n' "$out2" | grep -q 'doc-spec: present'      || { fail_test "Case A: re-run did not report doc-spec present"; a_ok=no; }
  printf '%s\n' "$out2" | grep -q 'seeded=0 present=3'     || { fail_test "Case A: re-run summary not seeded=0 present=3"; a_ok=no; }
  [ "$a_ok" = yes ] && ok "Case A: all 3 contracts seeded + validate-clean; re-run idempotent (all present)"
  [ "$a_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- Case B: workbench self-repo SKIPPED ----------
if ! (
  S=$(mk_sandbox)
  # Make THIS sandbox look like the workbench self-repo via the manifest source
  # match (resolve the sandbox's main toplevel, point the manifest at it).
  MAIN_TOP=$(git -C "$S" rev-parse --show-toplevel)
  SELF_MANIFEST=$(mktemp "$WORK/self-manifest.XXXXXX")
  printf '{"source":"%s","bundle_path":"%s"}\n' "$MAIN_TOP" "$MAIN_TOP" > "$SELF_MANIFEST"
  out=$(SKILLS_DEPLOY_MANIFEST="$SELF_MANIFEST" "$DEPLOY" seed-contracts --repo "$S" 2>&1)
  b_ok=yes
  printf '%s\n' "$out" | grep -q 'workbench self-repo' || { fail_test "Case B: self-repo not detected/skipped (out: $out)"; b_ok=no; }
  # NOTHING written to spec/ — the real contracts are untouched.
  [ -d "$S/spec" ] && { fail_test "Case B: spec/ was created in the self-repo (skeleton overwrite risk)"; b_ok=no; }
  # Second self-signal: a sandbox carrying a custom overlay is also detected as self.
  S2=$(mk_sandbox)
  mkdir -p "$S2/spec"
  echo "overlay" > "$S2/spec/doc-spec-custom.md"
  out2=$("$DEPLOY" seed-contracts --repo "$S2" 2>&1)
  printf '%s\n' "$out2" | grep -q 'workbench self-repo' || { fail_test "Case B: custom-overlay repo not detected as self (out: $out2)"; b_ok=no; }
  [ -f "$S2/spec/doc-spec.md" ] && { fail_test "Case B: doc-spec.md seeded into a canonical-contract repo"; b_ok=no; }
  [ "$b_ok" = yes ] && ok "Case B: workbench self-repo skipped (manifest-source match AND custom-overlay signal); contracts untouched"
  [ "$b_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- Case C: stale repo-local engine → _cj-shared + engine-stale finding ----------
if ! (
  S=$(mk_sandbox)
  mkdir -p "$S/scripts"
  # Plant a STALE repo-local doc-spec.sh that does NOT handle --classify.
  cat > "$S/scripts/doc-spec.sh" <<'STALE'
#!/usr/bin/env bash
echo "stale engine — does not know --classify"
exit 0
STALE
  chmod +x "$S/scripts/doc-spec.sh"
  out=$("$DEPLOY" seed-contracts --repo "$S" 2>&1)
  c_ok=yes
  printf '%s\n' "$out" | grep -q 'stage1/engine-stale' || { fail_test "Case C: stage1/engine-stale finding not emitted (out: $out)"; c_ok=no; }
  printf '%s\n' "$out" | grep -q 'repo-local doc-spec.sh is stale' || { fail_test "Case C: engine-stale message did not name doc-spec.sh"; c_ok=no; }
  # Despite the stale repo-local engine, doc-spec is still seeded (via _cj-shared).
  [ -f "$S/spec/doc-spec.md" ] || { fail_test "Case C: doc-spec.md not seeded after stale fallback"; c_ok=no; }
  validate_contract doc-spec "$S" DOC_SPEC_PATH || { fail_test "Case C: _cj-shared-seeded doc-spec.md not validate-clean"; c_ok=no; }
  [ "$c_ok" = yes ] && ok "Case C: stale repo-local engine detected → fell back to _cj-shared + emitted stage1/engine-stale + still seeded"
  [ "$c_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- Case D: corruption guard (--validate-dirty seed → seed-failed) ----------
if ! (
  S=$(mk_sandbox)
  # A _cj-shared stand-in whose doc-spec.sh looks current (--classify=absent) but
  # whose --seed emits garbage that --validate rejects. Only doc-spec is stubbed.
  BADSHARED=$(mktemp -d "$WORK/badshared.XXXXXX")
  cat > "$BADSHARED/doc-spec.sh" <<'BAD'
#!/usr/bin/env bash
case "$1" in
  --classify) echo "GENERATION=absent" ;;
  --seed)     echo "not a valid registry table" ;;
  --validate) exit 1 ;;
  *)          exit 0 ;;
esac
BAD
  chmod +x "$BADSHARED/doc-spec.sh"
  out=$(SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$BADSHARED" "$DEPLOY" seed-contracts --repo "$S" 2>&1)
  d_ok=yes
  printf '%s\n' "$out" | grep -q 'doc-spec: seed-failed' || { fail_test "Case D: doc-spec not reported seed-failed (out: $out)"; d_ok=no; }
  # CORRUPTION GUARD: nothing written to spec/doc-spec.md.
  [ -f "$S/spec/doc-spec.md" ] && { fail_test "Case D: a --validate-dirty seed landed in spec/ (corruption guard breached)"; d_ok=no; }
  [ "$d_ok" = yes ] && ok "Case D: corruption guard held — --validate-dirty --seed reported seed-failed, nothing written to spec/"
  [ "$d_ok" = yes ]
); then ERRORS=$((ERRORS + 1)); fi

# ---------- Summary ----------
echo ""
echo "=== seed-contracts.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
