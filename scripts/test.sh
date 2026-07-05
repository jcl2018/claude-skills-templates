#!/usr/bin/env bash
# Smoke tests for the skill workbench. Superset of validate.sh.
# Exit 0 = all tests pass. Exit 1 = one or more failures.

. "$(dirname "$0")/lib.sh"
init

ERRORS=0

ok() { echo "  OK: $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

# Catalog-driven SKILL.md path lookup (F000006). Mirrors the helper in
# scripts/skills-deploy and scripts/validate.sh: skill source root is the
# dirname of catalog files[0], so a skill can live anywhere the catalog
# points (skills/, deprecated/, etc.).
skill_md_path() {
  jq -r --arg n "$1" '.[] | select(.name == $n) | (.files // []) | .[0] // ""' "$CATALOG" 2>/dev/null || true
}
skill_md_abs() {
  local f0
  f0=$(skill_md_path "$1")
  if [ -n "$f0" ]; then
    # shellcheck disable=SC2153  # REPO_ROOT is assigned in lib.sh (sourced; SC1091 already disabled repo-wide)
    echo "$REPO_ROOT/$f0"
  fi
}
skill_source_dir_abs() {
  local f0
  f0=$(skill_md_path "$1")
  if [ -n "$f0" ]; then
    echo "$REPO_ROOT/$(dirname "$f0")"
  fi
}

# Ensure git user config exists (required for commit in CI environments)
if ! git config user.name >/dev/null 2>&1; then
  git config user.name "test"
  git config user.email "test@test.local"
fi

# NOTE: keep this banner EXACT — it is the `testsh-validate-rerun` units-row anchor
# in spec/test-spec-custom.md (validate.sh Check 24 forward-check greps it verbatim).
echo "=== Running validate.sh ==="
# Run the full validator ONCE and reuse its output + exit code for every clean-tree
# guard below (S000094 Check 21, S000096 Check 24 + exit-0, F000060 Check 24). Those
# guards used to re-invoke validate.sh 4-5x back-to-back, which built runner memory
# pressure and OOM-killed a later run — the chronic "validate.sh exits non-zero" flake.
# Capturing once (not re-running) fixes it, the same way F000081 fixed the negatives.
# Capture output + real exit code without tripping errexit (CI runs `bash -e test.sh`).
# The assignment lives in an `if` condition (errexit-exempt) so a non-zero validate.sh
# is TOLERATED and surfaced as a clear fail_test below — not a silent `set -e` death.
# (An `A=$(...) || B` / `A && B || C` form would either lose the exit code or trip
# SC2015, which CI shellcheck flags; the if-form avoids both.)
if _VALIDATE_OUT=$("$REPO_ROOT/scripts/validate.sh" 2>&1); then _VALIDATE_RC=0; else _VALIDATE_RC=$?; fi
printf '%s\n' "$_VALIDATE_OUT"
if [ "$_VALIDATE_RC" -eq 0 ]; then
  ok "validate.sh passed"
else
  fail_test "validate.sh failed (exit $_VALIDATE_RC)"
fi

echo ""
echo "=== Additional smoke tests ==="

# === F000053/S000093: trajectory-QA regression guards ===
# Static guards that the "QA can't lie about correctness" fix stays in place.
# These are the PARALLEL test.sh assertions for the S000093 smoke rows (S1-S4) —
# the zzz-test-scaffold parallel-edit blind spot this repo keeps re-hitting (see
# the notes further down). qa.md is prose, so the guard is structural: assert the
# new landmarks are present and the closed hole (the date-only NO-OP) stays closed.
_S93_QA="$REPO_ROOT/skills/CJ_qa-work-item/qa.md"
_S93_PIPE="$REPO_ROOT/skills/CJ_goal_feature/pipeline.md"
_S93_TMPL="$REPO_ROOT/templates/CJ_personal-workflow/tracker-user-story.md"
# S2 (AC-1): the date-only NO-OP short-circuit is GONE; the receipt-vouches gate is in.
if grep -qF "already QA'd green; nothing to do" "$_S93_QA"; then
  fail_test "S000093: qa.md Step 3 date-only NO-OP exit line reappeared (the GAP-A hole reopened)"
fi
grep -q 'Resume Re-validation Gate' "$_S93_QA" || fail_test "S000093: qa.md Step 3 'Resume Re-validation Gate' heading missing"
grep -q 'RECEIPT_VOUCHES_HEAD' "$_S93_QA" || fail_test "S000093: qa.md RECEIPT_VOUCHES_HEAD gate missing"
# S1 (AC-2): receipts.qa emission documented in qa.md + the tracker template.
grep -q 'ac_ids_uncovered' "$_S93_QA" || fail_test "S000093: qa.md receipts.qa schema (ac_ids_uncovered) missing"
grep -q 'ready_for_ship' "$_S93_QA" || fail_test "S000093: qa.md receipts.qa schema (ready_for_ship) missing"
grep -q '# receipts:' "$_S93_TMPL" || fail_test "S000093: tracker-user-story.md commented '# receipts:' reference missing"
# S3 (AC-3/AC-4): fail-closed verdict (no receipt => RED).
grep -q 'fail-closed verdict' "$_S93_QA" || fail_test "S000093: qa.md fail-closed verdict missing"
grep -q 'no execution receipt' "$_S93_QA" || fail_test "S000093: qa.md fail-closed 'no execution receipt => RED' (AC4) missing"
# S4 (AC-5): write-idempotency anchor (the Step 6.5 run-start marker).
grep -q 'write-idempotency anchor' "$_S93_QA" || fail_test "S000093: qa.md Step 6.5 write-idempotency anchor missing"
# pipeline.md: QA is ALWAYS re-dispatched on resume (GAP A path-2 closed).
if grep -qF 'qa (skip if validated LAST_PHASE' "$_S93_PIPE"; then
  fail_test "S000093: pipeline.md Step 3.3 still phase-skips QA on resume (GAP-A path-2 hole reopened)"
fi
grep -q 'ALWAYS re-dispatched on resume' "$_S93_PIPE" || fail_test "S000093: pipeline.md Step 3.3 always-re-dispatch policy missing"
ok "F000053/S000093 trajectory-QA regression guards"

# === F000053/S000094: permission-policy regression guards ===
# Exercise the permission-policy parser + the Check-21 derivation/drift wiring.
# Parallel test.sh fixture for the new validate.sh Check 21 (repo convention: a
# new validate.sh check ships with its test.sh assertions in the same PR).
_S94_PP="$REPO_ROOT/scripts/permission-policy.sh"
# Resolve spec/-then-root (the family moved into spec/; root remains a fallback).
_S94_POLICY="$REPO_ROOT/spec/permission-policy.md"
[ -f "$_S94_POLICY" ] || _S94_POLICY="$REPO_ROOT/permission-policy.md"
if [ ! -x "$_S94_PP" ] || [ ! -f "$_S94_POLICY" ]; then
  fail_test "S000094: permission-policy.sh / permission-policy.md missing"
else
  # S1: the policy parses.
  bash "$_S94_PP" --validate >/dev/null 2>&1 || fail_test "S000094: permission-policy.sh --validate failed (policy does not parse)"
  # S3 + fail-closed: an unlisted verb resolves to deny; known modes resolve correctly.
  [ "$(bash "$_S94_PP" --resolve definitely-not-a-listed-verb 2>/dev/null)" = "deny" ] || fail_test "S000094: an unlisted verb did not resolve to 'deny' (fail-closed broken)"
  [ "$(bash "$_S94_PP" --resolve edit-catalog 2>/dev/null)" = "ask" ] || fail_test "S000094: edit-catalog did not resolve to 'ask'"
  [ "$(bash "$_S94_PP" --resolve git-push-to-main 2>/dev/null)" = "deny" ] || fail_test "S000094: git-push-to-main did not resolve to 'deny'"
  [ "$(bash "$_S94_PP" --resolve edit-in-scope 2>/dev/null)" = "allow" ] || fail_test "S000094: edit-in-scope did not resolve to 'allow'"
  # S2: the gate derives its denylist from the policy's ask surface globs.
  { bash "$_S94_PP" --surface-globs ask 2>/dev/null | grep -q 'skills-catalog.json'; } || fail_test "S000094: --surface-globs ask missing skills-catalog.json"
  grep -q 'surface-globs' "$REPO_ROOT/scripts/cj-handoff-gate.sh" || fail_test "S000094: cj-handoff-gate.sh does not derive its denylist from the policy"
  # E2: risky verbs are all present as deny.
  for _v in git-push-to-main gh-pr-merge rm network-egress; do
    bash "$_S94_PP" --deny-verbs 2>/dev/null | grep -qx "$_v" || fail_test "S000094: risky verb '$_v' not declared deny in the policy"
  done
  # S4: Check 21 is wired into validate.sh and passes on the in-sync tree (advisory,
  # exit 0). Reuse the single top-of-suite validate.sh capture (no redundant re-run).
  grep -q 'Check 21: cj_goal permission-policy drift' <<< "$_VALIDATE_OUT" || fail_test "S000094: validate.sh missing Check 21"
  grep -q 'PASS: permission policy + enforcement points in sync' <<< "$_VALIDATE_OUT" || fail_test "S000094: Check 21 did not PASS on the in-sync tree"
  # Drift path (E1, isolated — no real-file mutation): a missing policy makes the
  # parser fail closed with the no-config halt (the "policy does not parse" drift).
  # if-then (not `A && B || C`) avoids SC2015, which CI's shellcheck flags as info.
  if PERMISSION_POLICY_PATH=/nonexistent-permission-policy.md bash "$_S94_PP" --validate >/dev/null 2>&1; then
    fail_test "S000094: parser did not fail on a missing policy (no-config drift undetected)"
  fi
  ok "F000053/S000094 permission-policy regression guards"
fi

# === F000054/S000096 + F000063: gate (layers/gates) regression guards ===
# Exercise the layers[] + gates[] parsing — folded from the retired gate-spec.sh
# into scripts/test-spec.sh (F000063) — and the Check-24 advisory marker-drift
# wiring (absorbed from the retired Check 22). The layers/gates live in the
# merged test-spec registry: layers[] in the general spec/test-spec.md, the
# per-mode gates[] in spec/test-spec-custom.md.
_S96_TS="$REPO_ROOT/scripts/test-spec.sh"
_S96_SPEC="$REPO_ROOT/spec/test-spec.md"
[ -f "$_S96_SPEC" ] || _S96_SPEC="$REPO_ROOT/test-spec.md"
if [ ! -x "$_S96_TS" ] || [ ! -f "$_S96_SPEC" ]; then
  fail_test "S000096: test-spec.sh / test-spec.md missing"
else
  # S1: the merged registry parses (schema_version + every layer/gate's keys + closed enums).
  bash "$_S96_TS" --validate >/dev/null 2>&1 || fail_test "S000096: test-spec.sh --validate failed (merged registry does not parse)"
  [ "$(bash "$_S96_TS" --validate 2>/dev/null)" = "OK schema_version=1" ] || fail_test "S000096: --validate did not print 'OK schema_version=1'"
  # S2: the reader emits the right sets — the four layers + at least the known gates.
  for _l in CI-push CI-nightly pipeline-gate local-hook; do
    bash "$_S96_TS" --list-layers 2>/dev/null | grep -qx "$_l" || fail_test "S000096: --list-layers missing layer '$_l'"
  done
  for _g in isolation qa doc-sync ship; do
    bash "$_S96_TS" --list-gates 2>/dev/null | grep -qx "$_g" || fail_test "S000096: --list-gates missing gate '$_g'"
  done
  # S4: the universal markers resolve in ALL four modes' files; the per-mode
  # isolation markers resolve in their declared mode's file (either pipeline.md or SKILL.md).
  # [doc-sync-red] is the sole remaining universal marker (the portability gate
  # + its [portability-red] marker were removed in F000073).
  for _dir in CJ_goal_feature CJ_goal_defect CJ_goal_task CJ_goal_todo_fix; do
    { grep -qF '[doc-sync-red]' "$REPO_ROOT/skills/$_dir/pipeline.md" 2>/dev/null || grep -qF '[doc-sync-red]' "$REPO_ROOT/skills/$_dir/SKILL.md" 2>/dev/null; } \
      || fail_test "S000096: universal marker [doc-sync-red] absent from skills/$_dir/{pipeline.md,SKILL.md}"
  done
  { grep -qF '[feature-not-isolated]' "$REPO_ROOT/skills/CJ_goal_feature/pipeline.md" 2>/dev/null || grep -qF '[feature-not-isolated]' "$REPO_ROOT/skills/CJ_goal_feature/SKILL.md" 2>/dev/null; } \
    || fail_test "S000096: isolation marker [feature-not-isolated] absent from the feature mode's files"
  { grep -qF '[investigate-not-isolated]' "$REPO_ROOT/skills/CJ_goal_defect/pipeline.md" 2>/dev/null || grep -qF '[investigate-not-isolated]' "$REPO_ROOT/skills/CJ_goal_defect/SKILL.md" 2>/dev/null; } \
    || fail_test "S000096: isolation marker [investigate-not-isolated] absent from the defect mode's files"
  { grep -qF '[task-not-isolated]' "$REPO_ROOT/skills/CJ_goal_task/pipeline.md" 2>/dev/null || grep -qF '[task-not-isolated]' "$REPO_ROOT/skills/CJ_goal_task/SKILL.md" 2>/dev/null; } \
    || fail_test "S000096: isolation marker [task-not-isolated] absent from the task mode's files"
  # S3: the marker-drift cross-check is folded into validate.sh Check 24, advisory,
  # and PASSes on the in-sync tree (exit 0; only the coverage portion can hard-fail).
  # Reuse the single top-of-suite validate.sh capture (no redundant re-run — the OOM fix).
  grep -q 'Check 24: test-spec coverage cross-check + gate marker drift' <<< "$_VALIDATE_OUT" || fail_test "S000096: validate.sh Check 24 missing the merged banner"
  grep -q 'PASS: gate marker drift — the gates: array + the four CJ_goal_\* pipelines in sync' <<< "$_VALIDATE_OUT" || fail_test "S000096: Check 24 marker-drift did not PASS on the in-sync tree"
  # Advisory posture: validate.sh exits 0 (no hard-fail from the marker-drift portion).
  [ "$_VALIDATE_RC" -eq 0 ] || fail_test "S000096: validate.sh exits non-zero with Check 24 active"
  # Drift path (isolated — no real-file mutation): a missing registry makes the
  # parser classify absent (REGISTRY=absent + exit 0); a malformed one fails closed.
  [ "$(TEST_SPEC_PATH=/nonexistent-test-spec.md bash "$_S96_TS" --list-gates 2>/dev/null)" = "REGISTRY=absent" ] \
    || fail_test "S000096: --list-gates on an absent registry did not classify REGISTRY=absent"
  ok "F000054/S000096 + F000063 gate (layers/gates) regression guards"
fi

# === F000053/S000095: within-phase-receipts regression guards ===
# Static guards for the office-hours phase receipt (P1 context curation): the
# receipt is written atomically at the office-hours boundary, reuses S000093's
# shared envelope schema, Step 2.7 reads the digest FROM the receipt, and scope
# stays office-hours-only (no generic per-phase compaction hook). pipeline.md is
# prose, so the guard is structural — assert the landmarks are present.
_S95_PIPE="$REPO_ROOT/skills/CJ_goal_feature/pipeline.md"
# S1 (AC-1): a compact office-hours receipt is written via the atomic mktemp+mv path.
grep -qF '.office-hours.receipt' "$_S95_PIPE" || fail_test "S000095: pipeline.md office-hours receipt path (.office-hours.receipt) missing"
grep -q 'mktemp.*ohreceipt' "$_S95_PIPE" || fail_test "S000095: pipeline.md office-hours receipt atomic mktemp write missing"
# S2 (AC-4): the receipt envelope reuses S000093's locked schema keys. Anchored
# at line-start so they match only the receipt heredoc body (not prose / the
# vouches sed / last_completed_phase=); no '$' in the pattern (CI shellcheck
# flags SC2016 on a single-quoted '$').
grep -q '^phase=office-hours' "$_S95_PIPE" || fail_test "S000095: pipeline.md receipt key 'phase=office-hours' (shared S000093 schema) missing"
grep -q '^commit=' "$_S95_PIPE" || fail_test "S000095: pipeline.md receipt key 'commit' (shared S000093 schema) missing"
grep -q '^completed_at=' "$_S95_PIPE" || fail_test "S000095: pipeline.md receipt key 'completed_at' (shared S000093 schema) missing"
# AC-2: Step 2.7 sources the design-summary digest FROM the receipt + the state pointer exists.
grep -qF 'sourced design-summary digest from' "$_S95_PIPE" || fail_test "S000095: pipeline.md Step 2.7 does not source the digest from the receipt (AC2)"
grep -qF 'office_hours_receipt=' "$_S95_PIPE" || fail_test "S000095: pipeline.md state-file office_hours_receipt= pointer missing"
# S3 (AC-3): scoped to office-hours only — no generic hook + exactly one receipt-write site.
grep -qF 'no generic per-phase compaction hook' "$_S95_PIPE" || fail_test "S000095: pipeline.md AC3 scope guard (no generic per-phase compaction hook) missing"
_S95_WRITES=$(grep -c 'mv .*OH_RECEIPT' "$_S95_PIPE" || true)
[ "${_S95_WRITES:-0}" -eq 1 ] || fail_test "S000095: expected exactly 1 office-hours receipt write site, found ${_S95_WRITES:-0} (scope drift)"
ok "F000053/S000095 within-phase-receipts regression guards"

# === F000060: test-spec registry + coverage guards ===
# Parallel test.sh assertions for the swapped validate.sh Check 24 (the
# two-tier test-spec coverage cross-check; repo convention: a new/changed
# validate.sh check ships with its test.sh assertions in the same PR — the
# standing parallel-edit blind spot, defused in lockstep). The temp-dir drift
# drills (fake banner / broken anchor / removed runner / unregistered file /
# self-satisfying source / dead text / disabled check / vanished suite) live in
# tests/test-spec.test.sh, registered in the hand-wired runner section below;
# this block asserts the live-tree positives + the absent-vs-invalid split.
_S60_TS="$REPO_ROOT/scripts/test-spec.sh"
_S60_REG="$REPO_ROOT/spec/test-spec.md"
[ -f "$_S60_REG" ] || _S60_REG="$REPO_ROOT/test-spec.md"
if [ ! -x "$_S60_TS" ] || [ ! -f "$_S60_REG" ]; then
  fail_test "F000060: scripts/test-spec.sh / spec/test-spec.md missing"
else
  # S1: the merged registry (general rules + custom units overlay) parses.
  [ "$(bash "$_S60_TS" --validate 2>/dev/null)" = "OK schema_version=1" ] || fail_test "F000060: test-spec.sh --validate did not print 'OK schema_version=1'"
  # S2: the merged registry enumerates both tiers (5 portable rules + units).
  _S60_NR=$(bash "$_S60_TS" --list-rules 2>/dev/null | { grep -c . || true; })
  [ "${_S60_NR:-0}" -eq 5 ] || fail_test "F000060: test-spec.sh --list-rules expected the 5 portable rules, got ${_S60_NR:-0}"
  _S60_NU=$(bash "$_S60_TS" --list-units 2>/dev/null | { grep -c . || true; })
  [ "${_S60_NU:-0}" -ge 60 ] || fail_test "F000060: test-spec.sh --list-units expected >= 60 overlay units, got ${_S60_NU:-0}"
  # S3: the coverage cross-check is clean on the live tree.
  bash "$_S60_TS" --check-coverage >/dev/null 2>&1 || fail_test "F000060: test-spec.sh --check-coverage has findings on the live tree"
  # S4: Check 24 is wired into validate.sh (validate-first, then coverage) and
  # PASSes on the in-sync tree.
  # Reuse the single top-of-suite validate.sh capture (no redundant re-run — the OOM fix).
  grep -q 'Check 24: test-spec coverage cross-check' <<< "$_VALIDATE_OUT" || fail_test "F000060: validate.sh missing the swapped Check 24"
  grep -q 'PASS: test-spec registry valid' <<< "$_VALIDATE_OUT" || fail_test "F000060: Check 24 registry-validate step did not PASS"
  grep -q 'PASS: test-spec coverage cross-check clean' <<< "$_VALIDATE_OUT" || fail_test "F000060: Check 24 coverage did not PASS on the live tree"
  # Absent-vs-invalid split (isolated — no real-file mutation): an ABSENT
  # registry classifies as REGISTRY=absent + exit 0 (skip, not finding); a
  # PRESENT-but-invalid registry fails closed with the no-config halt.
  _S60_ABS=$(TEST_SPEC_PATH=/nonexistent-test-spec.md bash "$_S60_TS" --validate 2>/dev/null); _S60_ABS_RC=$?
  if [ "$_S60_ABS_RC" -ne 0 ] || [ "$_S60_ABS" != "REGISTRY=absent" ]; then
    fail_test "F000060: absent registry did not classify as REGISTRY=absent + exit 0 (rc=$_S60_ABS_RC out=$_S60_ABS)"
  fi
  _S60_BAD=$(mktemp -d)
  cat > "$_S60_BAD/test-spec.md" <<'S60_BAD_FIXTURE'
```yaml
schema_version: 9
rules:
  - id: r-one
    statement: "s"
    scope: "s"
    enforced_by: "s"
```
S60_BAD_FIXTURE
  if TEST_SPEC_PATH="$_S60_BAD/test-spec.md" bash "$_S60_TS" --validate >/dev/null 2>&1; then
    fail_test "F000060: present-but-invalid registry did not fail closed with the no-config halt"
  fi
  rm -rf "$_S60_BAD"
  # F000066: the behavior-coverage axis. Live-tree positives — the dogfood
  # behaviors[] + behavior_coverage[] in spec/test-spec-custom.md enumerate via
  # the new --list-behaviors / --list-behavior-coverage subcommands and resolve
  # clean (no behavior findings). The 6 deterministic checks (positive +
  # negatives) live in tests/test-spec.test.sh §9; this block asserts the live
  # dogfood is green + the new subcommands exist (the parallel-edit blind spot,
  # defused: a new --check-coverage axis ships with its test.sh assertions).
  _S60_NB=$(bash "$_S60_TS" --list-behaviors 2>/dev/null | { grep -c . || true; })
  [ "${_S60_NB:-0}" -ge 8 ] || fail_test "F000066: --list-behaviors expected >= 8 dogfood behaviors, got ${_S60_NB:-0}"
  _S60_NBC=$(bash "$_S60_TS" --list-behavior-coverage 2>/dev/null | { grep -c . || true; })
  [ "${_S60_NBC:-0}" -ge 8 ] || fail_test "F000066: --list-behavior-coverage expected >= 8 covers, got ${_S60_NBC:-0}"
  # The live dogfood resolves with no behavior findings (real anchored covers).
  _S60_BCOV=$(bash "$_S60_TS" --check-coverage 2>&1)
  printf '%s\n' "$_S60_BCOV" | grep -qF 'FINDING: behavior-coverage' \
    && fail_test "F000066: live dogfood behaviors have a behavior-coverage finding: $_S60_BCOV"
  # A units-only registry (the seed has no behaviors) reports the inactive note.
  _S60_RO=$(mktemp -d)
  bash "$_S60_TS" --seed > "$_S60_RO/test-spec.md" 2>/dev/null
  _S60_BINACT=$(TEST_SPEC_PATH="$_S60_RO/test-spec.md" REPO_ROOT="$_S60_RO" bash "$_S60_TS" --check-coverage 2>&1)
  printf '%s\n' "$_S60_BINACT" | grep -qF 'behavior coverage inactive' \
    || fail_test "F000066: a no-behaviors registry did not report 'behavior coverage inactive'"
  rm -rf "$_S60_RO"
  ok "F000060 test-spec registry + coverage guards (+ F000066 behavior-coverage axis)"
fi

# Test: No duplicate skill names in catalog
echo ""
echo "Checking for duplicate skill names..."
dupes=$(jq -r '.[].name' "$CATALOG" | sort | uniq -d)
if [ -z "$dupes" ]; then
  ok "No duplicate skill names"
else
  fail_test "Duplicate skill names found: $dupes"
fi

# Test: All SKILL.md files have parseable frontmatter
echo ""
echo "Checking SKILL.md frontmatter parseability..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  skill_file=$(skill_md_abs "$name")
  if [ -z "$skill_file" ] || [ ! -f "$skill_file" ]; then
    continue
  fi
  # Check frontmatter exists between --- markers
  fm=$(sed -n '/^---$/,/^---$/p' "$skill_file")
  if echo "$fm" | grep -q 'name:' && echo "$fm" | grep -q 'description:'; then
    ok "$name frontmatter is parseable"
  else
    fail_test "$name SKILL.md frontmatter is not parseable"
  fi
done

# Test: Doc triplets have required sections
echo ""
echo "Checking doc triplet required sections..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  doc_dir="$DOCS_DIR/$name"
  [ -d "$doc_dir" ] || continue

  if [ -f "$doc_dir/PRD.md" ]; then
    if grep -q '## Problem Statement' "$doc_dir/PRD.md" 2>/dev/null; then
      ok "$name PRD.md has ## Problem Statement"
    else
      fail_test "$name PRD.md missing ## Problem Statement section"
    fi
  fi

  if [ -f "$doc_dir/ARCHITECTURE.md" ]; then
    if grep -qE '## (Overview|Architecture)' "$doc_dir/ARCHITECTURE.md" 2>/dev/null; then
      ok "$name ARCHITECTURE.md has ## Overview or ## Architecture"
    else
      fail_test "$name ARCHITECTURE.md missing ## Overview or ## Architecture section"
    fi
  fi

  if [ -f "$doc_dir/TEST-SPEC.md" ]; then
    ts_missing=""
    for sec in "## Smoke Tests" "## E2E Tests"; do
      grep -q "$sec" "$doc_dir/TEST-SPEC.md" 2>/dev/null || ts_missing="$ts_missing $sec"
    done
    if [ -z "$ts_missing" ]; then
      ok "$name TEST-SPEC.md has ## Smoke Tests and ## E2E Tests"
    else
      fail_test "$name TEST-SPEC.md missing required section(s):$ts_missing"
    fi
  fi

  if [ -f "$doc_dir/feature-summary.md" ]; then
    fs_missing=""
    for sec in "## Scope" "## Success Criteria" "## Constituent User-Stories" "## Out-of-Scope"; do
      grep -q "$sec" "$doc_dir/feature-summary.md" 2>/dev/null || fs_missing="$fs_missing $sec"
    done
    if [ -z "$fs_missing" ]; then
      ok "$name feature-summary.md has all required sections (Scope, Success Criteria, Constituent User-Stories, Out-of-Scope)"
    else
      fail_test "$name feature-summary.md missing sections:$fs_missing"
    fi
  fi
done

# Test: Advisory scripts run without crashing
echo ""
echo "Smoke-testing advisory scripts..."

if "$REPO_ROOT/scripts/doctor.sh" >/dev/null 2>&1; then
  ok "doctor.sh runs without crash"
else
  fail_test "doctor.sh crashed"
fi

# lint-skill.sh exits non-zero on warnings (expected behavior, not a crash)
lint_output=$("$REPO_ROOT/scripts/lint-skill.sh" 2>&1) || true
if echo "$lint_output" | grep -q "Skill Content Lint"; then
  ok "lint-skill.sh runs without crash"
else
  fail_test "lint-skill.sh crashed (no output)"
fi

if deps_output=$("$REPO_ROOT/scripts/deps.sh" 2>&1); then
  if echo "$deps_output" | grep -q "CJ_personal-workflow\|CJ_system-health"; then
    ok "deps.sh runs and output contains known skills"
  else
    fail_test "deps.sh runs but output missing expected skill names"
  fi
else
  fail_test "deps.sh crashed"
fi

if "$REPO_ROOT/scripts/generate-readme.sh" >/dev/null 2>&1; then
  ok "generate-readme.sh runs without crash"
  # Idempotency check
  first=$("$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null)
  second=$("$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null)
  if [ "$first" = "$second" ]; then
    ok "generate-readme.sh is idempotent"
  else
    fail_test "generate-readme.sh produces different output on repeated runs"
  fi
else
  fail_test "generate-readme.sh crashed"
fi


# Integration test: catalog consistency after manual skill creation
echo ""
echo "Integration test: manual skill creation cycle..."

# Backup catalog for safe restore
cp "$CATALOG" "/tmp/catalog-backup-$$"
cp "$REPO_ROOT/README.md" "/tmp/readme-backup-$$"
[ -f "$REPO_ROOT/VERSION" ] && cp "$REPO_ROOT/VERSION" "/tmp/version-backup-$$"
[ -f "$REPO_ROOT/CHANGELOG.md" ] && cp "$REPO_ROOT/CHANGELOG.md" "/tmp/changelog-backup-$$"
# F000069 / Check 26: back up the generated test catalog so the Step-3e fixture
# (which plants drift in docs/test-catalog.md) is safe even on an unexpected exit.
[ -f "$REPO_ROOT/docs/test-catalog.md" ] && cp "$REPO_ROOT/docs/test-catalog.md" "/tmp/testcatalog-backup-$$"
# F000069 / S000115 / Check 27: back up the generated workflow index so the Step-3f
# fixture (which plants drift in docs/workflow.md) is safe even on an unexpected exit.
[ -f "$REPO_ROOT/docs/workflow.md" ] && cp "$REPO_ROOT/docs/workflow.md" "/tmp/workflowidx-backup-$$"
trap 'cp "/tmp/catalog-backup-$$" "$CATALOG"; cp "/tmp/readme-backup-$$" "$REPO_ROOT/README.md"; [ -f "/tmp/version-backup-$$" ] && cp "/tmp/version-backup-$$" "$REPO_ROOT/VERSION"; [ -f "/tmp/changelog-backup-$$" ] && cp "/tmp/changelog-backup-$$" "$REPO_ROOT/CHANGELOG.md"; [ -f "/tmp/testcatalog-backup-$$" ] && cp "/tmp/testcatalog-backup-$$" "$REPO_ROOT/docs/test-catalog.md"; [ -f "/tmp/workflowidx-backup-$$" ] && cp "/tmp/workflowidx-backup-$$" "$REPO_ROOT/docs/workflow.md"; rm -rf "$SKILLS_DIR/zzz-test-scaffold" "$DOCS_DIR/zzz-test-scaffold" "/tmp/catalog-backup-$$" "/tmp/readme-backup-$$" "/tmp/version-backup-$$" "/tmp/changelog-backup-$$" "/tmp/testcatalog-backup-$$" "/tmp/workflowidx-backup-$$"' EXIT

# Step 1: manually create a skill directory + SKILL.md (the CLAUDE.md-guided way)
mkdir -p "$SKILLS_DIR/zzz-test-scaffold"
cat > "$SKILLS_DIR/zzz-test-scaffold/SKILL.md" << 'SKILLEOF'
---
name: zzz-test-scaffold
description: "Test skill for integration testing."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
---

# Test Skill

This is a test skill created by the integration test suite.
SKILLEOF

# Step 1b (F000032): scaffold USAGE.md alongside SKILL.md to satisfy Check 13
cat > "$SKILLS_DIR/zzz-test-scaffold/USAGE.md" << 'USAGEEOF'
---
skill-name: "zzz-test-scaffold"
version: 0.1.0
status: experimental
---

# Skill Usage: zzz-test-scaffold

## When to use

Test fixture only. Created by `scripts/test.sh` integration test.

## When NOT to use

Anywhere. This is a synthesized test skill that is cleaned up after the run.

## Mental model

Fixture for the manual-skill-creation integration test.

## Common pitfalls

None — fixture is removed by EXIT trap + inline cleanup.

## Related skills

None.
USAGEEOF

# Step 1c (T000037): NO workflow-doc section is needed for zzz-test-scaffold.
# Since T000037 re-scoped validate.sh Check 15b's completeness predicate to
# `startswith("CJ_goal_")`, only the cj_goal *workflow* orchestrators require a
# section in doc/WORKFLOWS.md. A non-orchestrator scaffolded skill (like this
# fixture) does NOT match the predicate, so the catalog entry added in Step 2
# below makes it routable WITHOUT obligating any doc/ section. This is the
# positive regression test for the reorg: Step 3's validate.sh run must stay
# GREEN even though zzz-test-scaffold has no WORKFLOWS.md entry. The fixture no
# longer touches any doc/ file (the old per-skill catalog-doc stub-append + its
# backup/restore plumbing were removed in T000037).

# Step 2: add catalog entry
jq '. + [{"name":"zzz-test-scaffold","version":"0.1.0","description":"Test skill for integration testing.","source":"local","depends":{"skills":[],"tools":[]},"portability":"standalone","files":["skills/zzz-test-scaffold/SKILL.md"],"templates":[],"status":"experimental"}]' "$CATALOG" > "/tmp/catalog-new-$$" && mv "/tmp/catalog-new-$$" "$CATALOG"

# Step 2b (T000050 / Check 25): the catalog mutation above drives
# generate-readme.sh output away from the committed README. The new validate.sh
# Check 25 (README <-> generate-readme.sh sync) would then fire for the REST of
# this block — falsely failing the exit-0 assertions in Steps 3/3b/3b'/3c, which
# test OTHER checks and assume validate is otherwise green. Regenerate README
# from the mutated catalog so Check 25 stays GREEN throughout; the EXIT trap
# above already backs up + restores the original README.
"$REPO_ROOT/scripts/generate-readme.sh" > "$REPO_ROOT/README.md" 2>/dev/null

# Step 3: validate passes with the new skill
if "$REPO_ROOT/scripts/validate.sh" >/dev/null 2>&1; then
  ok "validate.sh passes with manually created skill"
else
  fail_test "validate.sh fails after manual skill creation"
fi

# Step 3b: Check 17 root-doc placement allowlist (now parsed from the doc-spec.md
# registry, not the retired CLAUDE.md allowlist).
# KNOWN BLIND SPOT — every prior new validate.sh check (Check 13/14/15/16) needed
# a parallel zzz-test-scaffold assertion and it was forgotten each time. The
# F000050 doc-spec migration re-pointed Checks 15/15a/16/17 to doc-spec.md/docs/
# and ADDED Check 19 (no-work-item-refs in human docs); this block is updated in
# lockstep (Step 3b = Check 17, Step 3c = Check 19) per that migration's mandate.
# Run validate.sh from $REPO_ROOT so Check 17's `find . -maxdepth 1` resolves
# against the repo root deterministically regardless of the launch cwd. Synthesize
# a STRAY.md root doc NOT declared in the registry → assert validate.sh exits
# non-zero AND emits the literal Check 17 orphan prefix (`  ERROR: root doc
# STRAY.md is not declared in the doc-spec.md registry` — the `  ERROR:` form
# Checks 15/16/17 use, NOT `  FAIL:`). Then rm it → assert validate.sh exits 0
# again. STRAY.md is removed before Step 4 so it never leaks into a later test.
# TARGETED (F000081/WS4): the negative planted-fault check invokes ONLY Check 17's
# engine (doc-spec.sh --check-on-disk, the root-declared conformance check) instead
# of the whole validate.sh — same fault caught, no ~16x whole-validator re-run
# (the OOM flake). The engine's finding is `stage1/root-declared` (its wrapper form
# in validate.sh is the `  ERROR: root doc … not declared` line; both are the same
# check). REPO_ROOT is exported so the engine resolves the registry against the repo.
touch "$REPO_ROOT/STRAY.md"
if _C17_OUT=$( cd "$REPO_ROOT" && bash scripts/doc-spec.sh --check-on-disk 2>&1 ); then
  fail_test "Check 17: doc-spec.sh --check-on-disk should have exited non-zero with a stray root doc (STRAY.md), but exited 0"
else
  if echo "$_C17_OUT" | grep -qF "FINDING: stage1/root-declared" && echo "$_C17_OUT" | grep -qF "STRAY.md"; then
    ok "Check 17: stray root doc STRAY.md triggers the root-declared FINDING + non-zero exit (targeted engine)"
  else
    fail_test "Check 17: doc-spec.sh --check-on-disk exited non-zero but missing the stage1/root-declared STRAY.md finding; output: $_C17_OUT"
  fi
fi
rm -f "$REPO_ROOT/STRAY.md"
if ( cd "$REPO_ROOT" && bash scripts/doc-spec.sh --check-on-disk >/dev/null 2>&1 ); then
  ok "Check 17: doc-spec.sh --check-on-disk exits 0 again after the stray root doc is removed"
else
  fail_test "Check 17: doc-spec.sh --check-on-disk should have exited 0 after STRAY.md removed, but exited non-zero"
fi

# Step 3b' (F000057 / S000099 / TEST-SPEC S2,S3): the new Check 15a spec/*.md
# orphan scan. THE PARALLEL test.sh EDIT the new validate.sh orphan scan needs —
# pre-flighted in lockstep with the scan add (the standing F000032/34/35 zzz-mirror
# blind spot, defused). The spec-registry family moved into spec/; Check 15a now
# holds spec/*.md to the same declared <=> on-disk discipline as docs/*.md. Plant
# a STRAY.md under spec/ that is NOT declared in the registry → assert validate.sh
# exits non-zero AND emits the literal spec/ orphan ERROR (`  ERROR: spec/STRAY.md
# is in spec/ but not declared in the doc-spec.md registry`), then rm it → assert
# validate.sh exits 0 again. STRAY is removed before later tests so it never leaks.
# TARGETED (F000081/WS4): the negative planted-fault check invokes ONLY Check 15a's
# engine (doc-spec.sh --check-on-disk, the spec/ orphan sweep) instead of the whole
# validate.sh — same fault caught, no whole-validator re-run. The engine's finding
# is `stage1/orphans` (the validate.sh wrapper form is `  ERROR: spec/… not declared`).
touch "$REPO_ROOT/spec/STRAY.md"
if _C15A_SPEC_OUT=$( cd "$REPO_ROOT" && bash scripts/doc-spec.sh --check-on-disk 2>&1 ); then
  fail_test "Check 15a spec/: doc-spec.sh --check-on-disk should have exited non-zero with an undeclared spec/STRAY.md, but exited 0"
else
  if echo "$_C15A_SPEC_OUT" | grep -qF "FINDING: stage1/orphans" && echo "$_C15A_SPEC_OUT" | grep -qF "spec/STRAY.md"; then
    ok "Check 15a spec/: stray spec/STRAY.md triggers the orphans FINDING + non-zero exit (targeted engine)"
  else
    fail_test "Check 15a spec/: doc-spec.sh --check-on-disk exited non-zero but missing the stage1/orphans spec/STRAY.md finding; output: $_C15A_SPEC_OUT"
  fi
fi
rm -f "$REPO_ROOT/spec/STRAY.md"
if ( cd "$REPO_ROOT" && bash scripts/doc-spec.sh --check-on-disk >/dev/null 2>&1 ); then
  ok "Check 15a spec/: doc-spec.sh --check-on-disk exits 0 again after the stray spec/ doc is removed"
else
  fail_test "Check 15a spec/: doc-spec.sh --check-on-disk should have exited 0 after spec/STRAY.md removed, but exited non-zero"
fi

# Step 3c (F000050 / TEST-SPEC S3): Check 19 no-work-item-refs-in-human-docs lint.
# THE PARALLEL test.sh EDIT the new validate.sh check needs — pre-flighted in the
# same step as the Check 19 add (the F000032/34/35 blind spot, defused). Plant a
# work-item ref (F000999) into a real human-doc declared by the doc-spec.md
# registry (docs/philosophy.md), assert validate.sh exits non-zero AND emits the
# literal Check 19 prefix, then restore the file and assert validate.sh exits 0
# again. The plant is done on a backup-and-restore basis so the checkout is never
# left dirty. Proves Check 19 actually FIRES, not just defaults green.
# TARGETED (F000081/WS4): the negative planted-fault check invokes ONLY Check 19's
# engine (doc-spec.sh --check-on-disk, the human-doc-ids conformance check) instead
# of the whole validate.sh — same fault caught, no whole-validator re-run. The
# engine's finding is `stage1/human-doc-ids` (the validate.sh wrapper form is the
# `  ERROR: human-doc … contains work-item ref(s)` line; same check).
_C19_HUMANDOC="$REPO_ROOT/docs/philosophy.md"
if [ -f "$_C19_HUMANDOC" ]; then
  cp "$_C19_HUMANDOC" "/tmp/c19-humandoc-backup-$$"
  printf '\n<!-- planted ref for Check 19 negative test: F000999 -->\n' >> "$_C19_HUMANDOC"
  if _C19_OUT=$( cd "$REPO_ROOT" && bash scripts/doc-spec.sh --check-on-disk 2>&1 ); then
    fail_test "Check 19: doc-spec.sh --check-on-disk should have exited non-zero with a planted F000999 in a human-doc, but exited 0"
  else
    if echo "$_C19_OUT" | grep -qF "FINDING: stage1/human-doc-ids" && echo "$_C19_OUT" | grep -qF "docs/philosophy.md"; then
      ok "Check 19: planted F000999 in docs/philosophy.md triggers the human-doc-ids FINDING + non-zero exit (targeted engine)"
    else
      fail_test "Check 19: doc-spec.sh --check-on-disk exited non-zero but missing the stage1/human-doc-ids finding for docs/philosophy.md; output: $_C19_OUT"
    fi
  fi
  cp "/tmp/c19-humandoc-backup-$$" "$_C19_HUMANDOC"
  rm -f "/tmp/c19-humandoc-backup-$$"
  if ( cd "$REPO_ROOT" && bash scripts/doc-spec.sh --check-on-disk >/dev/null 2>&1 ); then
    ok "Check 19: doc-spec.sh --check-on-disk exits 0 again after the planted ref is removed"
  else
    fail_test "Check 19: doc-spec.sh --check-on-disk should have exited 0 after the planted F000999 was removed, but exited non-zero"
  fi
else
  fail_test "Check 19: docs/philosophy.md (a registry human-doc) not found for the negative test"
fi

# Step 3d (T000050 / Check 25): README.md ↔ generate-readme.sh sync check.
# THE PARALLEL test.sh EDIT the new validate.sh Check 25 needs — pre-flighted in
# lockstep with the check add (the standing F000032/34/35 zzz-mirror blind spot,
# defused). README.md is fully generated from skills-catalog.json by
# scripts/generate-readme.sh; Check 25 diffs the generator's stdout against
# README.md so a stale catalog-derived README cannot pass validation. README.md
# is already backed up + restored by the EXIT trap above (the catalog/README/
# VERSION/CHANGELOG backup at the top of this integration block), so mutating it
# here is safe even on an unexpected exit. POSITIVE: on the live (in-sync) tree
# Check 25 PASSes. NEGATIVE: append a stray line to README.md (the catalog stays
# unchanged so the generator output diverges) → assert validate.sh exits non-zero
# AND emits the literal Check 25 stale ERROR, then restore README.md from the
# generator → assert validate.sh exits 0 again. Proves Check 25 actually FIRES,
# not just defaults green.
# TARGETED (F000081/WS4): Check 25 IS a diff of generate-readme.sh's output vs
# README.md. The negative planted-fault check invokes ONLY that targeted diff
# instead of the whole validate.sh — same fault caught (a drifted README diverges
# from the generator), no whole-validator re-run. POSITIVE: the live tree matches.
if diff <( "$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null ) "$REPO_ROOT/README.md" >/dev/null 2>&1; then
  ok "Check 25: README.md is in sync with generate-readme.sh on the live tree (targeted diff)"
else
  fail_test "Check 25: README.md does not match generate-readme.sh output on the in-sync live tree"
fi
printf '\n<!-- planted drift for Check 25 negative test -->\n' >> "$REPO_ROOT/README.md"
if diff <( "$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null ) "$REPO_ROOT/README.md" >/dev/null 2>&1; then
  fail_test "Check 25: the README diff should have detected the planted drift, but reported in-sync"
else
  ok "Check 25: a drifted README.md is detected by the generate-readme.sh diff (targeted engine)"
fi
# Restore README.md from the generator (its single source of truth), then assert green.
"$REPO_ROOT/scripts/generate-readme.sh" > "$REPO_ROOT/README.md" 2>/dev/null
if diff <( "$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null ) "$REPO_ROOT/README.md" >/dev/null 2>&1; then
  ok "Check 25: README.md matches the generator again after regeneration"
else
  fail_test "Check 25: README.md should have matched the generator after regeneration, but still drifted"
fi

# Step 3e (F000069 / Check 26): docs/tests/ + docs/test-catalog.md ↔
# test-spec.sh --render-docs freshness check. THE PARALLEL test.sh EDIT the new
# validate.sh Check 26 needs — pre-flighted in lockstep with the check add (the
# standing F000032/34/35 zzz-mirror blind spot that bit Check 25 too, defused
# here for Check 26). The generated test catalog is rendered from the merged
# test-spec registry by scripts/test-spec.sh --render-docs; Check 26 calls
# --render-docs --check (render to temp + diff vs on-disk) so a stale catalog
# cannot pass validation. docs/test-catalog.md is already backed up + restored by
# the EXIT trap above, so mutating it here is safe even on an unexpected exit.
# POSITIVE: on the live (in-sync) tree Check 26 PASSes. NEGATIVE: append a stray
# line to docs/test-catalog.md (the registry is unchanged so the render diverges)
# → assert validate.sh exits non-zero AND emits the literal Check 26 stale ERROR,
# then regenerate the catalog from the registry → assert validate.sh exits 0
# again. Proves Check 26 actually FIRES, not just defaults green.
# TARGETED (F000081/WS4): Check 26 IS test-spec.sh --render-docs --check (render to
# a temp dir + diff vs on-disk). The negative planted-fault check invokes ONLY that
# targeted engine instead of the whole validate.sh — same fault caught, no
# whole-validator re-run. The engine's finding is `FINDING: render — … stale`.
if _C26_OK=$( cd "$REPO_ROOT" && bash scripts/test-spec.sh --render-docs --check 2>&1 ) && echo "$_C26_OK" | grep -qF "OK render"; then
  ok "Check 26: generated test catalog is in sync with test-spec.sh --render-docs on the live tree (targeted engine)"
else
  fail_test "Check 26: test-spec.sh --render-docs --check did not report OK render on the in-sync live tree; output: $_C26_OK"
fi
printf '\n<!-- planted drift for Check 26 negative test -->\n' >> "$REPO_ROOT/docs/test-catalog.md"
if _C26_OUT=$( cd "$REPO_ROOT" && bash scripts/test-spec.sh --render-docs --check 2>&1 ); then
  fail_test "Check 26: test-spec.sh --render-docs --check should have exited non-zero with a drifted test catalog, but exited 0"
else
  if echo "$_C26_OUT" | grep -qF "FINDING: render" && echo "$_C26_OUT" | grep -qF "test-catalog.md"; then
    ok "Check 26: a drifted docs/test-catalog.md triggers the render FINDING + non-zero exit (targeted engine)"
  else
    fail_test "Check 26: test-spec.sh --render-docs --check exited non-zero but missing the render/test-catalog.md finding; output: $_C26_OUT"
  fi
fi
# Regenerate the catalog from the registry (its single source of truth), then assert green.
bash "$REPO_ROOT/scripts/test-spec.sh" --render-docs >/dev/null 2>&1
if ( cd "$REPO_ROOT" && bash scripts/test-spec.sh --render-docs --check >/dev/null 2>&1 ); then
  ok "Check 26: test-spec.sh --render-docs --check is clean again after the test catalog is regenerated"
else
  fail_test "Check 26: test-spec.sh --render-docs --check should have been clean after regeneration, but reported stale"
fi

# Step 3f (F000069 / S000115 / Check 27): docs/workflow.md + docs/workflows/*.md ↔
# workflow-spec.sh --render-docs freshness check. THE PARALLEL test.sh EDIT the new
# validate.sh Check 27 needs — pre-flighted in lockstep with the check add (the
# standing F000032/34/35 zzz-mirror blind spot that bit Check 25/26 too, defused
# here for Check 27). The generated workflow surface is rendered from
# spec/workflow-spec.md by scripts/workflow-spec.sh --render-docs; Check 27 calls
# --render-docs --check (render to temp + diff vs on-disk) so a stale workflow doc
# cannot pass validation. docs/workflow.md is already backed up + restored by the
# EXIT trap above, so mutating it here is safe even on an unexpected exit.
# POSITIVE: on the live (in-sync) tree Check 27 PASSes. NEGATIVE: append a stray
# line to docs/workflow.md (the registry is unchanged so the render diverges)
# → assert validate.sh exits non-zero AND emits the literal Check 27 stale ERROR,
# then regenerate the surface from the registry → assert validate.sh exits 0
# again. Proves Check 27 actually FIRES, not just defaults green.
# TARGETED (F000081/WS4): Check 27 IS workflow-spec.sh --render-docs --check (render
# to a temp dir + diff vs on-disk). The negative planted-fault check invokes ONLY
# that targeted engine instead of the whole validate.sh — same fault caught, no
# whole-validator re-run. The engine's finding is `FINDING: render — … stale`.
if _C27_OK=$( cd "$REPO_ROOT" && bash scripts/workflow-spec.sh --render-docs --check 2>&1 ) && echo "$_C27_OK" | grep -qF "OK render"; then
  ok "Check 27: generated workflow surface is in sync with workflow-spec.sh --render-docs on the live tree (targeted engine)"
else
  fail_test "Check 27: workflow-spec.sh --render-docs --check did not report OK render on the in-sync live tree; output: $_C27_OK"
fi
printf '\n<!-- planted drift for Check 27 negative test -->\n' >> "$REPO_ROOT/docs/workflow.md"
if _C27_OUT=$( cd "$REPO_ROOT" && bash scripts/workflow-spec.sh --render-docs --check 2>&1 ); then
  fail_test "Check 27: workflow-spec.sh --render-docs --check should have exited non-zero with a drifted workflow surface, but exited 0"
else
  if echo "$_C27_OUT" | grep -qF "FINDING: render" && echo "$_C27_OUT" | grep -qF "workflow.md"; then
    ok "Check 27: a drifted docs/workflow.md triggers the render FINDING + non-zero exit (targeted engine)"
  else
    fail_test "Check 27: workflow-spec.sh --render-docs --check exited non-zero but missing the render/workflow.md finding; output: $_C27_OUT"
  fi
fi
# Regenerate the workflow surface from the registry (its single source of truth), then assert green.
bash "$REPO_ROOT/scripts/workflow-spec.sh" --render-docs >/dev/null 2>&1
if ( cd "$REPO_ROOT" && bash scripts/workflow-spec.sh --render-docs --check >/dev/null 2>&1 ); then
  ok "Check 27: workflow-spec.sh --render-docs --check is clean again after the workflow surface is regenerated"
else
  fail_test "Check 27: workflow-spec.sh --render-docs --check should have been clean after regeneration, but reported stale"
fi

# Step 3g (F000070 / S000119 / Check 28): the workflow-coverage gate. THE PARALLEL
# test.sh EDIT the new validate.sh Check 28 needs — pre-flighted in lockstep with
# the check add (the standing F000032/34/35 zzz-mirror blind spot that bit Check
# 25/26/27 too, defused here for Check 28). The gate (test-spec.sh
# --check-workflow-coverage) is a forward+reverse cross-check between the declared
# CJ_goal_* orchestrators (workflow-spec.sh --list-orchestrators) and the
# level:workflow behaviors — NOT a generated-doc diff, so there is no on-disk
# drift to plant. POSITIVE: on the live (in-sync) tree Check 28 PASSes with the
# orchestrators=N level:workflow behaviors=N findings=0 summary. The forward-miss /
# reverse-orphan / registry-absent NEGATIVE paths are exercised hermetically in
# tests/workflow-coverage.test.sh (registered below + as a units row). This block
# proves Check 28 actually FIRES its PASS on the live tree, not just defaults green.
# TARGETED (F000081/WS4): Check 28 IS test-spec.sh --check-workflow-coverage (a
# forward+reverse cross-check, NOT a generated-doc diff — there is no on-disk drift
# to plant). The positive assertion invokes ONLY that targeted engine instead of the
# whole validate.sh — same signal, no whole-validator re-run. The forward-miss /
# reverse-orphan / registry-absent NEGATIVE paths are exercised hermetically in
# tests/workflow-coverage.test.sh (registered below + as a units row).
if bash "$REPO_ROOT/scripts/test-spec.sh" --check-workflow-coverage 2>&1 | grep -qE '^workflow coverage: .*findings=0$'; then
  ok "Check 28: test-spec.sh --check-workflow-coverage reports findings=0 on the live tree (targeted engine — every CJ_goal_* orchestrator has a level:workflow behavior)"
else
  fail_test "Check 28: test-spec.sh --check-workflow-coverage did not report findings=0 on the live tree"
fi

# Step 3h (F000071 / S000120 / Check 29): the cj_goal E2E sandbox marker-absence
# guard. THE PARALLEL test.sh EDIT the new validate.sh Check 29 needs —
# pre-flighted in lockstep with the check add (the standing F000032/34/35
# zzz-mirror blind spot that bit Check 25/26/27/28 too, defused here for Check
# 29). Check 29 hard-fails when git tracks .cj-e2e-sandbox (the build-gate seam's
# guard marker, which must never ship). It is NOT a generated-doc diff, so the
# negative path plants a TRACKED marker (git add -f, since the marker is
# gitignored) and asserts validate.sh exits non-zero AND emits the literal Check
# 29 ERROR, then untracks + removes it and asserts validate.sh exits 0 again.
# POSITIVE: on the live tree (no tracked marker) Check 29 PASSes. The marker is
# untracked + removed in a cleanup that runs regardless, so it never leaks into a
# later test or the working tree.
# TARGETED (F000081/WS4): Check 29 IS a `git ls-files` probe for a TRACKED
# .cj-e2e-sandbox marker (the build-gate seam's guard, which must never ship). The
# negative planted-fault check invokes ONLY that targeted git probe instead of the
# whole validate.sh — same fault caught, no whole-validator re-run.
# `git ls-files --error-unmatch <path>` exits 0 iff the path is TRACKED.
if ! git -C "$REPO_ROOT" ls-files --error-unmatch .cj-e2e-sandbox >/dev/null 2>&1; then
  ok "Check 29: cj_goal E2E sandbox marker is absent from the tracked tree on the live tree (targeted git probe)"
else
  fail_test "Check 29: .cj-e2e-sandbox is unexpectedly tracked on the live tree"
fi
touch "$REPO_ROOT/.cj-e2e-sandbox"
git -C "$REPO_ROOT" add -f .cj-e2e-sandbox >/dev/null 2>&1
if git -C "$REPO_ROOT" ls-files --error-unmatch .cj-e2e-sandbox >/dev/null 2>&1; then
  ok "Check 29: a tracked .cj-e2e-sandbox is detected by the git ls-files probe (targeted engine)"
else
  fail_test "Check 29: git ls-files should have detected the force-added .cj-e2e-sandbox as tracked, but did not"
fi
# Cleanup (runs regardless of the assertions above): untrack + remove the marker.
git -C "$REPO_ROOT" rm --cached -f .cj-e2e-sandbox >/dev/null 2>&1 || true
rm -f "$REPO_ROOT/.cj-e2e-sandbox"
if ! git -C "$REPO_ROOT" ls-files --error-unmatch .cj-e2e-sandbox >/dev/null 2>&1; then
  ok "Check 29: .cj-e2e-sandbox is untracked again after the marker is removed (targeted git probe)"
else
  fail_test "Check 29: .cj-e2e-sandbox should have been untracked after cleanup, but is still tracked"
fi

# Step 3i (F000082 / S000132 / Check 30): the three-layer topic contract. THE
# PARALLEL test.sh EDIT the new validate.sh Check 30 needs — pre-flighted in lockstep
# with the check add (the standing F000032/34/35 zzz-mirror blind spot that bit Check
# 25/26/27/28/29 too, defused here for Check 30). Check 30 IS test-spec.sh
# --check-topic-contract: for every ENROLLED topic (topic_contracts:, portability
# today), assert >=1 CI-push + >=1 CI-nightly + >=1 local-hook{deterministic} + >=1
# local-hook{agentic} test carrying that topic, each with its front-door doc. It is
# NOT a generated-doc diff, so the negative path plants the fault HERMETICALLY (a temp
# copy of the merged registry with portability's agentic row removed) and asserts the
# targeted engine exits non-zero AND names the missing local-hook+agentic coverage,
# then confirms the LIVE tree passes — never mutating the real overlay.
# TARGETED (F000081/WS4): the positive + negative assertions invoke ONLY that targeted
# engine instead of the whole validate.sh — same signal, no whole-validator re-run.
# POSITIVE: on the live (enrolled + fully-covered) tree Check 30 reports findings=0.
if bash "$REPO_ROOT/scripts/test-spec.sh" --check-topic-contract 2>&1 | grep -qE '^topic contract: .*findings=0$'; then
  ok "Check 30: test-spec.sh --check-topic-contract reports findings=0 on the live tree (targeted engine — every enrolled topic reaches all three layers + both local modes)"
else
  fail_test "Check 30: test-spec.sh --check-topic-contract did not report findings=0 on the live tree"
fi
# NEGATIVE (hermetic): remove portability's local-hook+agentic row from a TEMP copy of
# the merged registry, point the engine at it via TEST_SPEC_PATH/TEST_SPEC_CUSTOM_PATH,
# and assert it hard-fails naming the missing coverage. The real overlay is untouched.
_C30_TMP=$(mktemp -d -t test-sh-c30-XXXXXX)
cp "$REPO_ROOT/spec/test-spec.md" "$_C30_TMP/test-spec.md"
# Drop the 9-line `- name: portability-version-agentic` block (name..topic).
awk '
  /^  - name: portability-version-agentic$/ { skip=9 }
  skip>0 { skip--; next }
  { print }
' "$REPO_ROOT/spec/test-spec-custom.md" > "$_C30_TMP/test-spec-custom.md"
# Export the temp-registry env for the forked test-spec.sh (a bare assignment +
# separate rc capture — the env-prefix-in-subshell form shellcheck misreads under
# `if`; SC2097/SC2098). The subshell isolates the exports from the rest of test.sh;
# REPO_ROOT is inherited from the parent (no self-re-export — that trips SC2030/2031).
_C30_OUT=$(
  export TEST_SPEC_PATH="$_C30_TMP/test-spec.md"
  export TEST_SPEC_CUSTOM_PATH="$_C30_TMP/test-spec-custom.md"
  bash "$REPO_ROOT/scripts/test-spec.sh" --check-topic-contract 2>&1
) && _C30_RC=0 || _C30_RC=$?
if [ "$_C30_RC" -eq 0 ]; then
  fail_test "Check 30: --check-topic-contract should have exited non-zero with portability's agentic row removed, but exited 0; output: $_C30_OUT"
else
  if echo "$_C30_OUT" | grep -qF "missing a local-hook + agentic test" && echo "$_C30_OUT" | grep -qF "portability"; then
    ok "Check 30: removing portability's local-hook+agentic row triggers the topic-contract FINDING + non-zero exit (targeted engine, hermetic)"
  else
    fail_test "Check 30: --check-topic-contract exited non-zero but missing the expected agentic-coverage finding; output: $_C30_OUT"
  fi
fi
rm -rf "$_C30_TMP"

# Step 4: frontmatter is parseable
fm=$(sed -n '/^---$/,/^---$/p' "$SKILLS_DIR/zzz-test-scaffold/SKILL.md")
if echo "$fm" | grep -q 'name:' && echo "$fm" | grep -q 'description:'; then
  ok "manually created skill has valid frontmatter"
else
  fail_test "manually created skill has invalid frontmatter"
fi

# Step 5 (S000052): inline cleanup of the scaffold-test fixture before any
# downstream test (e.g. test-deploy.sh) runs. EXIT trap also cleans this up,
# but that fires after the script finishes — too late for downstream tests
# that read $CATALOG or scan $SKILLS_DIR. Without inline cleanup, the
# zzz-test-scaffold catalog entry persists into test-deploy.sh's `install`
# call, doctor then resolves its source to $main_toplevel (per T000025) which
# differs from the worktree path where the dir lives, and Test 8 ("Doctor on
# healthy install") fails with `WARN: zzz-test-scaffold — source directory
# missing in repo`. Cleaning up inline keeps the EXIT trap as a defense-in-depth
# fallback for unexpected exits.
cp "/tmp/catalog-backup-$$" "$CATALOG"
rm -rf "$SKILLS_DIR/zzz-test-scaffold" "$DOCS_DIR/zzz-test-scaffold"

# Step 6 (F000045 / S000081 — TEST-SPEC S6): exercise the new `--phase sync`
# (Fork 2) end-to-end inside the integration cycle. This is the explicit
# parallel-edit to the integration fixture that prior new-feature work
# (F000032/34/35) systematically forgot for validate.sh checks — here applied to
# the cj-goal-common.sh sync phase. HERMETIC: runs against a THROWAWAY fake
# `.source` (temp git repo + fake skills-deploy that only echoes) via a
# POST_LAND_SYNC_MANIFEST override — NEVER a real `skills-deploy install`
# against the live ~/.claude. Asserts the four-key schema across dry-run +
# --no-sync (skipped) modes end-to-end.
echo ""
echo "Integration test (F000045 / S000081): --phase sync end-to-end (hermetic fake .source)..."
_SYNC_TMP=$(mktemp -d -t test-sh-sync-XXXXXX)
_SYNC_SRC="$_SYNC_TMP/source-repo"
mkdir -p "$_SYNC_SRC/scripts"
(
  cd "$_SYNC_SRC"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  git symbolic-ref HEAD refs/heads/main 2>/dev/null || git checkout -q -b main 2>/dev/null || true
  printf '6.0.0\n' > VERSION
  printf '#!/usr/bin/env bash\necho "FAKE skills-deploy $*"\n' > scripts/skills-deploy
  chmod +x scripts/skills-deploy
  git add -A && git commit -q -m "fixture"
) >/dev/null 2>&1
cat > "$_SYNC_TMP/manifest.json" <<EOF
{ "source": "$_SYNC_SRC", "collection_version": "6.0.0" }
EOF
# dry-run end-to-end: must emit the four keys + PHASE_RESULT=ok, mutate nothing.
_SYNC_DRY=$(POST_LAND_SYNC_MANIFEST="$_SYNC_TMP/manifest.json" bash "$REPO_ROOT/scripts/cj-goal-common.sh" --phase sync --mode feature --dry-run 2>&1)
if printf '%s\n' "$_SYNC_DRY" | grep -qE '^SYNC_RAN=' \
   && printf '%s\n' "$_SYNC_DRY" | grep -qE '^VERSION_BEFORE=' \
   && printf '%s\n' "$_SYNC_DRY" | grep -qE '^VERSION_AFTER=' \
   && printf '%s\n' "$_SYNC_DRY" | grep -qE '^PHASE_RESULT=ok$'; then
  ok "Integration: --phase sync --dry-run emits 4-key schema + PHASE_RESULT=ok (no mutation)"
else
  fail_test "Integration: --phase sync --dry-run missing 4-key schema / PHASE_RESULT=ok; output: $_SYNC_DRY"
fi
# --no-sync end-to-end: must short-circuit to PHASE_RESULT=skipped (no install).
_SYNC_NS=$(POST_LAND_SYNC_MANIFEST="$_SYNC_TMP/manifest.json" bash "$REPO_ROOT/scripts/cj-goal-common.sh" --phase sync --mode feature --no-sync 2>&1)
if printf '%s\n' "$_SYNC_NS" | grep -qE '^PHASE_RESULT=skipped$' \
   && ! printf '%s\n' "$_SYNC_NS" | grep -q 'FAKE skills-deploy'; then
  ok "Integration: --phase sync --no-sync → PHASE_RESULT=skipped, no install invoked"
else
  fail_test "Integration: --phase sync --no-sync should skip without install; output: $_SYNC_NS"
fi
rm -rf "$_SYNC_TMP"

# F000054: cj-goal-common.sh must accept --mode task (the new `task` verb). Smoke
# it through the `recap` phase (a pure formatter — hermetic, no git/manifest/env
# dependency) so the enum edit is guarded directly; an invalid mode would exit 1
# with [common-usage-mode]. (Not `sync`: that phase delegates to post-land-sync.sh
# and returns PHASE_RESULT=skipped on a fresh CI runner with no manifest.)
echo ""
echo "Integration test (F000054): cj-goal-common.sh accepts --mode task..."
_TASK_MODE=$(bash "$REPO_ROOT/scripts/cj-goal-common.sh" --phase recap --mode task --dry-run 2>&1) && _TASK_MODE_RC=0 || _TASK_MODE_RC=$?
if [ "$_TASK_MODE_RC" -eq 0 ] \
   && printf '%s\n' "$_TASK_MODE" | grep -qE '^MODE=task$' \
   && printf '%s\n' "$_TASK_MODE" | grep -qE '^PHASE_RESULT=ok$'; then
  ok "Integration: --mode task accepted (MODE=task, PHASE_RESULT=ok)"
else
  fail_test "Integration: --mode task not accepted (rc=$_TASK_MODE_RC); output: $_TASK_MODE"
fi
# And the worktree phase maps --mode task → --caller task → cj-task-* prefix.
_TASK_WT=$(cd "$(mktemp -d)" && git init -q && git config user.email t@t && git config user.name t && git checkout -q -b main && echo s>s && git add s && git commit -qm s && bash "$REPO_ROOT/scripts/cj-goal-common.sh" --phase worktree --mode task --dry-run 2>&1)
if printf '%s\n' "$_TASK_WT" | grep -qE '^WT_BRANCH=cj-task-' \
   && printf '%s\n' "$_TASK_WT" | grep -qE '^PHASE_RESULT=ok$'; then
  ok "Integration: --phase worktree --mode task → cj-task-* branch prefix"
else
  fail_test "Integration: --mode task worktree phase wrong; output: $_TASK_WT"
fi

# Template content smoke tests (S000002 TEST-SPEC)
echo ""
echo "Checking tracker template content..."

# S1: No "reviewer noted" in any tracker
if grep -rl "reviewer noted" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise gate 'reviewer noted' still present in personal tracker templates"
else
  ok "No 'reviewer noted' in personal tracker templates"
fi

# S2: No "Linux branch" in any personal tracker
if grep -rl "Linux branch" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise gate 'Linux branch' still present in personal tracker templates"
else
  ok "No 'Linux branch' in personal tracker templates"
fi

# S3: No JIRA/TFS in any personal tracker
if grep -rl "JIRA\|TFS" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise references (JIRA/TFS) still present in personal tracker templates"
else
  ok "No JIRA/TFS references in personal tracker templates"
fi

# S4: No workflow_type in any personal tracker
if grep -rl "workflow_type" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Redundant field 'workflow_type' still present in personal tracker templates"
else
  ok "No workflow_type in personal tracker templates"
fi

# S6: Task total gate count <= feature total gate count (lighter lifecycle)
task_total=$(grep -c '^\- \[ \]' "$REPO_ROOT/templates/CJ_personal-workflow/tracker-task.md" || true)
feat_total=$(grep -c '^\- \[ \]' "$REPO_ROOT/templates/CJ_personal-workflow/tracker-feature.md" || true)
if [ "$task_total" -le "$feat_total" ] 2>/dev/null; then
  ok "Task total gates ($task_total) <= feature total gates ($feat_total)"
else
  fail_test "Task total gates ($task_total) > feature total gates ($feat_total)"
fi

# No review tracker template should exist in CJ_personal-workflow templates
# (CJ_company-workflow/tracker-review.md is valid — it's a separate template set)
if [ -f "$REPO_ROOT/templates/CJ_personal-workflow/tracker-review.md" ]; then
  fail_test "tracker-review.md should not exist in CJ_personal-workflow (review type is company-only)"
else
  ok "No tracker-review.md in CJ_personal-workflow (review type correctly absent)"
fi

# Personal-workflow template directory exists with expected count
pw_count=$(find "$REPO_ROOT/templates/CJ_personal-workflow" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$pw_count" -eq 10 ]; then
  ok "templates/CJ_personal-workflow/ contains $pw_count templates (expected 10)"
else
  fail_test "templates/CJ_personal-workflow/ contains $pw_count templates (expected 10)"
fi

# Personal-workflow catalog entry exists
if jq -e '.[] | select(.name == "CJ_personal-workflow")' "$CATALOG" >/dev/null 2>&1; then
  ok "CJ_personal-workflow catalog entry exists"
else
  fail_test "CJ_personal-workflow catalog entry missing from skills-catalog.json"
fi

# No stale /docs references in personal tracker templates
if grep -rl "/docs check\|/docs tree" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Stale /docs references in personal tracker templates (should be /CJ_personal-workflow)"
else
  ok "No stale /docs references in personal tracker templates"
fi

# Portability test: CJ_personal-workflow skill has zero gstack dependencies
echo ""
echo "Portability test: CJ_personal-workflow standalone..."

if grep -q "gstack" "$REPO_ROOT/skills/CJ_personal-workflow/SKILL.md" 2>/dev/null; then
  fail_test "CJ_personal-workflow SKILL.md contains gstack references (should be standalone)"
else
  ok "CJ_personal-workflow SKILL.md has zero gstack references"
fi

# shellcheck disable=SC2088
if grep -q "~/.gstack" "$REPO_ROOT/skills/CJ_personal-workflow/SKILL.md" 2>/dev/null; then
  fail_test "CJ_personal-workflow SKILL.md references ~/.gstack/ (should be standalone)"
else
  ok "CJ_personal-workflow SKILL.md has no ~/.gstack/ paths"
fi

# Negative test: create orphan directory, verify validate catches it
echo ""
echo "Negative test: orphan directory detection..."
mkdir -p "$SKILLS_DIR/zzz-test-orphan"
if "$REPO_ROOT/scripts/validate.sh" >/dev/null 2>&1; then
  fail_test "validate.sh should have detected orphan zzz-test-orphan but passed"
else
  ok "validate.sh correctly detected orphan directory"
fi
rmdir "$SKILLS_DIR/zzz-test-orphan"

# Regression test: Windows jq CRLF wrapper (D000005)
# Background: jq.exe on Windows writes output with CRLF line endings, which
# breaks template-name regexes and integer comparisons in bash. Each script
# that calls jq must either source lib.sh (which defines the wrapper) or
# define its own inline wrapper. This test guards against that wrapper
# silently disappearing in a future refactor.
echo ""
echo "Regression test (D000005): Windows jq CRLF wrapper present..."

# 1. lib.sh defines the wrapper
if grep -qE '^jq\(\) \{ command jq "\$@" \| tr -d .{1,3}r.{1,3}; \}' "$REPO_ROOT/scripts/lib.sh"; then
  ok "scripts/lib.sh defines the jq() wrapper"
else
  fail_test "scripts/lib.sh is missing the jq() CRLF-stripping wrapper"
fi

# 2. skills-deploy defines its own wrapper (it does not source lib.sh)
if grep -qE '^jq\(\) \{ command jq "\$@" \| tr -d .{1,3}r.{1,3}; \}' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy defines the jq() wrapper"
else
  fail_test "scripts/skills-deploy is missing the jq() CRLF-stripping wrapper"
fi

# 3. test-deploy.sh defines its own wrapper (it does not source lib.sh)
if grep -qE '^jq\(\) \{ command jq "\$@" \| tr -d .{1,3}r.{1,3}; \}' "$REPO_ROOT/scripts/test-deploy.sh"; then
  ok "scripts/test-deploy.sh defines the jq() wrapper"
else
  fail_test "scripts/test-deploy.sh is missing the jq() CRLF-stripping wrapper"
fi

# 4. Behavior test: the wrapper strips CR when invoked from a script context
#    with `set -o pipefail`. Simulate by sourcing lib.sh then feeding jq input
#    whose output we then stringify and check for CR bytes.
crlf_probe=$(bash -c "set -euo pipefail; . '$REPO_ROOT/scripts/lib.sh'; printf '{\"n\":3}' | jq -r '.n'" 2>/dev/null | od -c | head -1)
if echo "$crlf_probe" | grep -q '\\r'; then
  fail_test "lib.sh jq wrapper did NOT strip CR (output contained \\r bytes)"
else
  ok "lib.sh jq wrapper output is CR-free"
fi

# 5. Pipefail-propagation test: jq -e must still return non-zero when the
#    expression is false, even through the tr pipe. Without `pipefail` active
#    (or with a naive wrapper), `if jq -e ... ` would always take the true
#    branch.
if bash -c "set -euo pipefail; . '$REPO_ROOT/scripts/lib.sh'; echo '{\"a\":1}' | jq -e '.b' >/dev/null 2>&1"; then
  fail_test "jq -e wrapper leaks true exit when expression is null (pipefail not respected)"
else
  ok "jq -e wrapper correctly propagates false exit through pipe"
fi

# Regression test (S000080 / F000044): the Windows smoke runs green on this host
# too. It is portable — exercises CRLF endings + the portable-date probe +
# copy-mode install (via FORCE_COPY) — so running it on the ubuntu CI + locally
# means it is not Windows-only-untested. windows.yml runs the SAME script on real
# Git Bash, where it is the live signal.
echo ""
echo "Regression test (S000080): windows-smoke.sh passes on this host..."
if bash "$REPO_ROOT/scripts/windows-smoke.sh" >/dev/null 2>&1; then
  ok "windows-smoke.sh passes (CRLF + portable date + copy-mode install)"
else
  fail_test "windows-smoke.sh failed on this host"
fi

echo ""
echo "Regression test (D000006): test-doc scope contracts..."

# Scope comments in test-doc templates (CJ_personal-workflow only after
# CJ_company-workflow retirement in F000023/S000053).
_tp_path="$REPO_ROOT/templates/CJ_personal-workflow/doc-test-plan.md"
_tp_disp="CJ_personal-workflow doc-test-plan.md"
if grep -q "ONE fix (defect) or ONE task" "$_tp_path"; then
  ok "$_tp_disp has the test-plan scope comment"
else
  fail_test "$_tp_disp is missing the test-plan scope comment"
fi

_ts_path="$REPO_ROOT/templates/CJ_personal-workflow/doc-TEST-SPEC.md"
_ts_disp="CJ_personal-workflow doc-TEST-SPEC.md"
if grep -q "ENTIRE user story" "$_ts_path"; then
  ok "$_ts_disp has the TEST-SPEC scope comment"
else
  fail_test "$_ts_disp is missing the TEST-SPEC scope comment"
fi

echo ""
echo "Regression test (D000007): contract.json eliminated; templates are the single source of truth..."

# contract.json must NOT exist for the personal-workflow skill (templates are the spec)
if [ -f "$REPO_ROOT/skills/CJ_personal-workflow/contract.json" ]; then
  fail_test "skills/CJ_personal-workflow/contract.json still exists; D000007 deleted it (templates are now the spec)"
else
  ok "skills/CJ_personal-workflow/contract.json correctly absent"
fi

# Validator files must not reference the deleted contract.json as a runtime dependency
# (intentional documentation mentions like "there is no separate contract.json" are
# fine — we grep for read/cat/load patterns that would indicate runtime use)
for vf in \
    "$REPO_ROOT/skills/CJ_personal-workflow/SKILL.md" \
    "$REPO_ROOT/skills/CJ_personal-workflow/check.md"; do
  vf_rel="${vf#"$REPO_ROOT"/}"
  if grep -qE '(cat|jq|Read|read).*contract\.json' "$vf"; then
    fail_test "$vf_rel still has a runtime read of contract.json (line should be removed)"
  else
    ok "$vf_rel does not load contract.json at runtime"
  fi
done

# Catalog must not list contract.json under either skill (would cause validate.sh
# orphan-file warnings after the delete)
if jq -r '.[] | select(.name=="CJ_company-workflow" or .name=="CJ_personal-workflow") | .files[]' "$REPO_ROOT/skills-catalog.json" 2>/dev/null | grep -q "contract\.json"; then
  fail_test "skills-catalog.json still lists contract.json under CJ_company-workflow or CJ_personal-workflow"
else
  ok "skills-catalog.json no longer references contract.json for either workflow skill"
fi

echo ""
echo "Regression test (D000008): CLAUDE.md merge convention guard..."

# CLAUDE.md must keep the merge-convention section so future /ship runs in this
# repo use the right gh pr merge invocation. The convention evolved in v2.0.6:
# - Original: prescribe --auto --squash --delete-branch (guarded against
#   regressing to --auto --delete-branch which silently fails without --squash).
# - v2.0.6+: --auto removed entirely. This repo's auto-merge is disabled, so
#   `gh pr merge --auto` exits 0 even when the actual merge fails (error to
#   stderr). Skipping --auto sidesteps the silent-fail; the new "Verify before
#   cleanup" guard tells agents to confirm state=MERGED after merge.
# This guard now checks for the new convention: --squash --delete-branch
# without --auto, plus the verify-before-cleanup paragraph.
if grep -q "^## CI/CD merge convention" "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md has the CI/CD merge convention section"
else
  fail_test "CLAUDE.md is missing the '## CI/CD merge convention' section (D000008 guard)"
fi

# shellcheck disable=SC2016  # backticks are intentional regex content, not command substitution
if grep -qE 'gh pr merge[^`]*--squash[^`]*--delete-branch' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md prescribes the --squash --delete-branch invocation"
else
  fail_test "CLAUDE.md is missing the --squash --delete-branch gh pr merge invocation (D000008 guard)"
fi

# v2.0.6+ guard: must explicitly tell agents NOT to add --auto.
if grep -qE '(Do NOT add|do NOT use).{0,30}--auto' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md warns against the --auto flag (auto-merge disabled in repo)"
else
  fail_test "CLAUDE.md is missing the 'do not add --auto' warning (v2.0.6 D000008 guard)"
fi

# v2.0.6+ guard: must tell agents to verify state=MERGED before cleanup.
if grep -qE '(must print|state.{0,5}=|state.{0,5}is).{0,40}MERGED|MERGED.{0,40}(before|cleanup)' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md prescribes the verify-state=MERGED check before cleanup"
else
  fail_test "CLAUDE.md is missing the verify-state=MERGED guidance (v2.0.6 D000008 guard)"
fi

if grep -qE 'gh api .*-X DELETE.*git/refs/heads' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md documents the worktree-aware remote-branch cleanup workaround"
else
  fail_test "CLAUDE.md is missing the 'gh api -X DELETE' worktree cleanup workaround (D000008 guard)"
fi

# v2.0.6+ guard: must point to the workbench-side check-version-queue.sh preflight.
if grep -q "check-version-queue.sh" "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md points to scripts/check-version-queue.sh queue-collision preflight"
else
  fail_test "CLAUDE.md is missing the check-version-queue.sh queue-collision preflight pointer (v2.0.6 D000008 guard)"
fi

echo ""
echo "Regression test (D000009): feature type requires DESIGN.md artifact..."

# Both manifests must declare a design artifact under types.feature.required,
# and matching doc-DESIGN.md templates must exist. Prevents a future refactor
# from silently dropping the DESIGN requirement back to where it was before.
if jq -e '.types.feature.required[] | select(.filename == "DESIGN.md" and .template == "doc-DESIGN.md")' \
     "$REPO_ROOT/skills/CJ_personal-workflow/personal-artifact-manifests.json" > /dev/null; then
  ok "personal-artifact-manifests.json feature.required includes DESIGN.md"
else
  fail_test "personal-artifact-manifests.json feature.required missing DESIGN.md entry (D000009 guard)"
fi

if [ -f "$REPO_ROOT/templates/CJ_personal-workflow/doc-DESIGN.md" ]; then
  ok "templates/CJ_personal-workflow/doc-DESIGN.md present"
else
  fail_test "templates/CJ_personal-workflow/doc-DESIGN.md missing (D000009 guard)"
fi

echo ""
echo "Regression test (D000012): deployed workflow templates stay in sync with workbench..."

# Background: D000009 added doc-DESIGN.md and v0.14.2 added doc-feature-summary.md
# to the workbench manifests + templates dir, but ~/.claude/templates/ was never
# refreshed via skills-deploy install --overwrite. Downstream repos (e.g. portfolio)
# that resolve templates from ~/.claude/ saw the new manifest requirement without
# the corresponding template files. This block:
#   (a) verifies skills-catalog.json declares both new templates so skills-deploy
#       install has the metadata to copy them
#   (b) when ~/.claude/templates/{personal,company}-workflow/ exists on this host,
#       asserts every workbench template is present and byte-identical in the
#       deployed copy. Skipped on hosts where skills-deploy hasn't run (e.g. CI).

# shellcheck disable=SC2043  # single-element loop preserved for CJ_personal-workflow scope after CJ_company-workflow retirement (F000023/S000053)
for _wf in CJ_personal-workflow; do
  case "$_wf" in
    CJ_personal-workflow) _tmpls="doc-DESIGN.md doc-SPEC.md doc-ROADMAP.md" ;;
  esac
  for _tmpl in $_tmpls; do
    if jq -e --arg p "$_wf/$_tmpl" --arg n "$_wf" \
         '.[] | select(.name == $n) | .templates | index($p)' \
         "$CATALOG" > /dev/null 2>&1; then
      ok "skills-catalog.json $_wf.templates includes $_tmpl"
    else
      fail_test "skills-catalog.json $_wf.templates missing $_tmpl (D000012 guard)"
    fi
  done
done

# shellcheck disable=SC2043  # single-element loop preserved for CJ_personal-workflow scope after CJ_company-workflow retirement (F000023/S000053)
for _wf in CJ_personal-workflow; do
  _D12_DEPLOYED="${HOME}/.claude/templates/$_wf"
  # Catalog-driven workbench source dir (F000006). Honors the catalog
  # templates_source override; falls back to templates/{wf} for active skills.
  _D12_SRC_REL=$(jq -r --arg n "$_wf" '.[] | select(.name == $n) | .templates_source // ""' "$CATALOG" 2>/dev/null || echo "")
  if [ -n "$_D12_SRC_REL" ]; then
    _D12_SRC="$REPO_ROOT/$_D12_SRC_REL"
  else
    _D12_SRC="$REPO_ROOT/templates/$_wf"
  fi
  if [ -d "$_D12_DEPLOYED" ]; then
    _D12_DRIFT=0
    # Forward direction: every workbench template must exist + byte-match in deployed (D000012)
    for _src in "$_D12_SRC"/*.md; do
      [ -f "$_src" ] || continue
      _name=$(basename "$_src")
      _dst="$_D12_DEPLOYED/$_name"
      if [ ! -f "$_dst" ]; then
        fail_test "deployed template missing: $_wf/$_name (run scripts/skills-deploy install --overwrite; D000012 guard)"
        _D12_DRIFT=$((_D12_DRIFT + 1))
      elif ! cmp -s "$_src" "$_dst"; then
        fail_test "deployed template differs from workbench: $_wf/$_name (run scripts/skills-deploy install --overwrite; D000012 guard)"
        _D12_DRIFT=$((_D12_DRIFT + 1))
      fi
    done
    # Reverse direction: every deployed template must exist in workbench (D000014)
    # Catches stale templates left in ~/.claude/ after a workbench removal — skills-deploy
    # install --overwrite adds files but does not remove them, so without this check
    # extras accumulate undetected (made more relevant by D000013's auto-sync hook).
    for _dst in "$_D12_DEPLOYED"/*.md; do
      [ -f "$_dst" ] || continue
      _name=$(basename "$_dst")
      _src="$_D12_SRC/$_name"
      if [ ! -f "$_src" ]; then
        fail_test "deployed template not in workbench: $_wf/$_name (manually rm — workbench removed this template; D000014 guard)"
        _D12_DRIFT=$((_D12_DRIFT + 1))
      fi
    done
    if [ "$_D12_DRIFT" -eq 0 ]; then
      ok "deployed templates/$_wf/ matches workbench source (both directions)"
    fi
  else
    echo "  SKIP: ~/.claude/templates/$_wf/ not present — skills-deploy hasn't run on this host"
  fi
done

echo ""
echo "Regression test (D000014): WORKFLOW.md type-to-artifact counts match manifest..."

# Background: D000009 (DESIGN), v0.14.2 (feature-summary), and earlier CJ_company-workflow
# changes (PR-DESCRIPTION) added required artifacts to the manifest but didn't update
# the type-to-artifact tables and prose in skills/{personal,company}-workflow/WORKFLOW.md.
# Scaffolding AIs read WORKFLOW.md, see the wrong count, and produce incomplete work
# items that fail downstream validation. This block forces the markdown table count
# to match the manifest's required-array length — manifest is authoritative.

# shellcheck disable=SC2043  # single-element loop preserved for CJ_personal-workflow scope after CJ_company-workflow retirement (F000023/S000053)
for _wf in CJ_personal-workflow; do
  # Strip the CJ_ prefix from the skill name to recover the manifest filename
  # base (manifests retain their original "personal-artifact-manifests.json"
  # filename; only the directory was renamed under T000018).
  _NAKED="${_wf#CJ_}"
  _PREFIX="${_NAKED%-workflow}"
  # Catalog-driven source dir (F000006): manifest + WORKFLOW.md live in the
  # same directory as the skill's SKILL.md, wherever the catalog points.
  _SOURCE_DIR=$(skill_source_dir_abs "$_wf")
  _MANIFEST="$_SOURCE_DIR/${_PREFIX}-artifact-manifests.json"
  _WORKFLOW_MD="$_SOURCE_DIR/WORKFLOW.md"
  if [ ! -f "$_MANIFEST" ] || [ ! -f "$_WORKFLOW_MD" ]; then
    fail_test "$_wf manifest or WORKFLOW.md missing (D000014 guard)"
    continue
  fi
  while IFS=$'\t' read -r _type _expected; do
    _md_count=$(grep -E "^\| $_type \|" "$_WORKFLOW_MD" | head -1 | awk -F'|' '{print $4}' | tr -d ' ')
    if [ -z "$_md_count" ]; then
      fail_test "$_wf WORKFLOW.md missing table row for type \"$_type\" (D000014 guard)"
    elif [ "$_md_count" = "$_expected" ]; then
      ok "$_wf WORKFLOW.md $_type count ($_expected) matches manifest"
    else
      fail_test "$_wf WORKFLOW.md $_type count drift: WORKFLOW.md=$_md_count, manifest=$_expected (D000014 guard)"
    fi
  done < <(jq -r '.types | to_entries[] | .key + "\t" + (.value.required | length | tostring)' "$_MANIFEST")
done

echo ""
echo "Regression test (D000013): setup-hooks.sh installs post-merge auto-sync hook..."

# Background: D000012 added a regression check that catches deploy drift but doesn't
# prevent it. D000013 closes Option C2 from D000012's RCA: setup-hooks.sh now writes
# a post-merge hook so workbench pulls auto-run skills-deploy install --overwrite
# whenever templates/skills/catalog/rules change. This block verifies the source
# script still emits the right hook content; it does not fire the hook itself
# (avoids touching .git/hooks/ in CI).

# D000022 re-anchored this guard from the literal 'cat > "$HOOK_DIR/post-merge"'
# to the install_hook shape: setup-hooks.sh now installs hooks via the
# clobber-safe install_hook helper, not a bare cat-redirect. Same D000013
# regression intent (setup-hooks.sh still writes a post-merge hook); new
# structural token. No SC2016 disable needed — the pattern has no literal $.
if grep -qE 'install_hook[[:space:]]+post-merge' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh writes a post-merge hook"
else
  fail_test "setup-hooks.sh missing post-merge hook block (D000013 guard)"
fi

if grep -qE 'skills-deploy.*install.*--overwrite' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "post-merge hook invokes skills-deploy install --overwrite"
else
  fail_test "post-merge hook missing skills-deploy install --overwrite call (D000013 guard)"
fi

if grep -qF 'templates/|skills/|skills-catalog\.json|rules/' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "post-merge hook filters on deploy-relevant paths (templates, skills, catalog, rules)"
else
  fail_test "post-merge hook missing path filter for templates/skills/catalog/rules (D000013 guard)"
fi

# D000021: setup.sh bootstrap must wire setup-hooks.sh, else a fresh clone never
# installs the post-merge auto-sync hook above and the repo's update model
# silently degrades to manual behavior. Source-level static check only — never
# runs the network-dependent setup.sh (same CI-safety rationale as this block).
# Anchor on the executable invocation (quoted $CLONE_DIR prefix), NOT a bare
# 'setup-hooks.sh' substring — the explanatory comments in setup.sh also
# contain that string, so a loose grep stays green even if the invocation
# line is deleted (matches the structural-token style of the D000013 guards
# above, e.g. 'install_hook post-merge').
# shellcheck disable=SC2016 # literal $CLONE_DIR is intentional — grepping for the exact source string in setup.sh
if grep -qE '"\$CLONE_DIR/scripts/setup-hooks\.sh"' "$REPO_ROOT/scripts/setup.sh"; then
  ok "setup.sh bootstrap invokes setup-hooks.sh (post-merge hook auto-installed on fresh clone)"
else
  fail_test "setup.sh does not invoke setup-hooks.sh — fresh-clone bootstrap leaves auto-sync hook uninstalled (D000013 bootstrap-wiring guard)"
fi

# D000022: the git-hook installer must not blind-clobber operator/tooling-owned
# hooks. Since D000021 wired setup-hooks.sh into setup.sh's always-on update path,
# an unconditional `cat > "$HOOK_DIR/<hook>"` would silently destroy a customized
# pre-commit/post-merge (Husky, lefthook, local) with no backup, and a partial
# write would leave a truncated hook present. The fix installs via a
# sentinel-aware, atomic install_hook helper.
#
# F000069/S000117 EXTRACTED that clobber-safe install_hook (+ the SENTINEL) into
# the ONE shared, sourceable scripts/cj-hook-lib.sh that BOTH setup-hooks.sh and
# skills-deploy source (no two drifting copies). So the D000022 source-level static
# checks now anchor on cj-hook-lib.sh (the new home of the safety logic) PLUS a
# parity check that setup-hooks.sh actually sources the lib (so the wrapper still
# routes through the safe primitive). Source-level static checks only — never fires
# a hook (same CI-safety rationale as the D000013 block above).
LIB="$REPO_ROOT/scripts/cj-hook-lib.sh"
# Parity: setup-hooks.sh must source cj-hook-lib.sh AND call cj_install_hook (so
# the shared safety primitive is the only install path — not a stale inline copy).
if grep -qF 'cj-hook-lib.sh' "$REPO_ROOT/scripts/setup-hooks.sh" \
   && grep -qF 'cj_install_hook' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh sources the shared cj-hook-lib.sh and routes installs through cj_install_hook (F000069/S000117 parity)"
else
  fail_test "setup-hooks.sh does not source cj-hook-lib.sh / call cj_install_hook — the shared hook-install safety is bypassed (S000117 parity guard)"
fi

# shellcheck disable=SC2016 # literal $CJ_HOOK_SENTINEL is intentional — grepping for the exact source string in cj-hook-lib.sh
if grep -qF '! grep -qF "$CJ_HOOK_SENTINEL"' "$LIB"; then
  ok "cj-hook-lib.sh checks the workbench sentinel before overwriting an existing hook (D000022 guard)"
else
  fail_test "cj-hook-lib.sh missing sentinel ownership check — operator/tooling hooks can be blind-clobbered (D000022 guard)"
fi

# shellcheck disable=SC2016 # literal $hook_dir/$tmp/$hook_path are intentional — grepping for the exact source strings in cj-hook-lib.sh
if grep -qF 'mktemp "$hook_dir/.${hook_name}.XXXXXX"' "$LIB" \
   && grep -qF 'mv "$tmp" "$hook_path"' "$LIB"; then
  ok "cj-hook-lib.sh stages hooks via mktemp and installs with an atomic mv (D000022 guard)"
else
  fail_test "cj-hook-lib.sh missing atomic mktemp-stage + mv install — a partial write can leave a truncated hook (D000022 guard)"
fi

# shellcheck disable=SC2016 # literal $hook_path/$backup are intentional — grepping for the exact source string in cj-hook-lib.sh
if grep -qF 'cp -p "$hook_path" "$backup"' "$LIB"; then
  ok "cj-hook-lib.sh backs up a non-workbench hook to <hook>.bak before clobbering (D000022 guard)"
else
  fail_test "cj-hook-lib.sh missing .bak backup of non-workbench hooks — custom hooks lost unrecoverably (D000022 guard)"
fi

# D000022 (pre-landing-review hardening): the two failure-mode invariants below
# have no other static anchor, so a regression that drops them would stay green
# while re-opening exactly the bug classes D000022 exists to kill.
#   (a) exit $rc — setup-hooks.sh must propagate a non-zero exit so setup.sh's
#       `|| echo WARN >&2` guard fires; dropping it re-introduces the masked
#       partial-failure class (the original D000022 / PR #150 finding). This
#       invariant stays in setup-hooks.sh (the wrapper that aggregates per-hook rc).
#   (b) backup-fail abort — if the .bak copy fails, cj_install_hook must refuse to
#       overwrite (the design's "one unacceptable outcome": losing an un-backed
#       custom hook). The ERROR string is emitted only on that abort path,
#       immediately before its `return 1`, so its presence proves the branch. It
#       now lives in cj-hook-lib.sh (the extracted primitive).
# shellcheck disable=SC2016 # literal $rc is intentional — grepping for the exact source string in setup-hooks.sh
if grep -qF 'exit $rc' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh propagates a non-zero exit on hook-install failure (D000022 guard)"
else
  fail_test "setup-hooks.sh missing 'exit \$rc' — a failed hook install is masked from setup.sh's WARN guard (D000022 guard)"
fi

if grep -qF 'could not be backed up — refusing to overwrite' "$LIB"; then
  ok "cj-hook-lib.sh aborts without clobbering when the .bak backup fails (D000022 guard)"
else
  fail_test "cj-hook-lib.sh missing backup-fail abort — an un-backed custom hook can be destroyed (D000022 guard)"
fi

echo ""
echo "Regression test (D000015): skills-deploy install overwrites drifted templates by default..."

# Background: pre-D000015, `skills-deploy install` defaulted to `overwrite=false`
# and skipped drifted templates with a WARN line. Users had to remember
# `--overwrite` for every routine deploy. D000015 flips the default: deploy
# overwrites by default; `--no-overwrite` is the new opt-out. `--overwrite` is
# kept as a tolerated no-op so D000013's post-merge hook (which still passes it)
# continues to work without modification.

# Check 1: default is overwrite=true
if grep -qE 'local skills=\(\) overwrite=true' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy default is overwrite=true (D000015)"
else
  fail_test "scripts/skills-deploy default is not overwrite=true — D000015 regressed"
fi

# Check 2: --no-overwrite flag is wired
if grep -qE -- '--no-overwrite\) overwrite=false' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy supports --no-overwrite opt-out (D000015)"
else
  fail_test "scripts/skills-deploy missing --no-overwrite flag handler (D000015 guard)"
fi

# Check 3: --overwrite is still tolerated (backwards compat with D000013's hook)
if grep -qE -- '--overwrite\) overwrite=true' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy still tolerates --overwrite as a no-op (backwards compat with D000013)"
else
  fail_test "scripts/skills-deploy dropped --overwrite handler — D000013 post-merge hook will break (D000015 guard)"
fi

# Check 4: WARN-and-skip language is gone (PRESERVE replaces it under --no-overwrite)
if ! grep -qF 'use --overwrite to replace' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy no longer emits 'use --overwrite to replace' (D000015)"
else
  fail_test "scripts/skills-deploy still references 'use --overwrite to replace' — D000015 regressed"
fi

# Check 5: help text documents --no-overwrite
if grep -qE 'install \[skill\.\.\.\] \[--no-overwrite\]' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy help text documents --no-overwrite (D000015)"
else
  fail_test "scripts/skills-deploy help text not updated for D000015"
fi

# Check 6: CLAUDE.md reflects the new default
if grep -qF 'overwritten by default' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md documents new default install behavior (D000015)"
else
  fail_test "CLAUDE.md still documents --overwrite as opt-in — D000015 docs not synced"
fi

echo ""
echo "Regression test (S000079): skills-deploy copy-mode fallback (symlink-free install)..."

# Background: on Git Bash `ln -s` copies-by-default / needs admin, so skills-deploy
# falls back to copy-mode: regular-file copies + a manifest install_kind + per-file
# source_checksums, with doctor/remove/relink branching on install_kind (default
# "symlink" when the field is absent, for back-compat). This is a KNOWN BLIND SPOT:
# every prior skills-deploy change needed a parallel test.sh structural guard and it
# was forgotten repeatedly. These structural greps fail loudly if the copy-mode
# scaffolding is dropped in a refactor; the behavioral coverage runs end-to-end via
# test-deploy.sh (Tests C1–C7), invoked below.

# Check 1: _can_symlink probe helper exists
if grep -qE '^_can_symlink\(\) \{' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy defines the _can_symlink() probe (S000079)"
else
  fail_test "scripts/skills-deploy missing _can_symlink() probe — copy-mode mode-selection regressed (S000079 guard)"
fi

# Check 2: SKILLS_DEPLOY_FORCE_COPY override is honored
if grep -qF 'SKILLS_DEPLOY_FORCE_COPY' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy honors SKILLS_DEPLOY_FORCE_COPY override (S000079)"
else
  fail_test "scripts/skills-deploy dropped SKILLS_DEPLOY_FORCE_COPY override (S000079 guard)"
fi

# Check 3: install resolves an install_kind and copy-mode records source_checksums
if grep -qE 'install_kind="copy"' "$REPO_ROOT/scripts/skills-deploy" \
   && grep -qF 'source_checksums' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy writes install_kind + source_checksums in copy-mode (S000079)"
else
  fail_test "scripts/skills-deploy missing install_kind/source_checksums manifest schema (S000079 guard)"
fi

# Check 4: doctor/remove/relink default an absent install_kind to "symlink" (back-compat)
default_count=$(grep -cF '.install_kind // "symlink"' "$REPO_ROOT/scripts/skills-deploy" || true)
if [ "$default_count" -ge 3 ]; then
  ok "scripts/skills-deploy defaults absent install_kind to symlink in doctor/remove/relink ($default_count sites; S000079)"
else
  fail_test "scripts/skills-deploy back-compat default '.install_kind // \"symlink\"' present at only $default_count site(s), expected >=3 (S000079 guard)"
fi


# ---------- copilot-deploy.py: install → doctor → remove round-trip ----------
# Guards against regressions in the 264-LoC Python installer. Tier 1 smoke:
# install the bundle into a tmp target, run doctor (expect all PASS), then
# remove and verify cleanup. This is the only automated coverage for
# scripts/copilot-deploy.py.
if command -v python3 >/dev/null 2>&1; then
  _CD_TMP=$(mktemp -d -t copilot-deploy-test.XXXXXX)
  mkdir -p "$_CD_TMP/target"
  _CD_PY="$REPO_ROOT/scripts/copilot-deploy.py"

  # install
  _cd_install_out=$(python3 "$_CD_PY" install "$_CD_TMP/target" 2>&1)
  _cd_install_rc=$?
  if [ "$_cd_install_rc" -eq 0 ] && echo "$_cd_install_out" | grep -q "SUMMARY: installed=" \
     && [ -f "$_CD_TMP/target/.github/copilot-instructions.md" ] \
     && [ -f "$_CD_TMP/target/.github/work-copilot/copilot-artifact-manifests.json" ] \
     && [ -f "$_CD_TMP/target/.github/work-copilot/install-manifest.json" ]; then
    ok "copilot-deploy install lands bundle files into target .github/"
  else
    fail_test "copilot-deploy install failed or missing expected files. rc=$_cd_install_rc output=[$_cd_install_out]"
  fi

  # doctor (expect all PASS, exit 0)
  _cd_doctor_out=$(python3 "$_CD_PY" doctor "$_CD_TMP/target" 2>&1)
  _cd_doctor_rc=$?
  if [ "$_cd_doctor_rc" -eq 0 ] \
     && ! echo "$_cd_doctor_out" | grep -qE "\[MISSING\]|\[DRIFT\]|\[ORPHAN\]"; then
    ok "copilot-deploy doctor reports clean install (no MISSING/DRIFT/ORPHAN)"
  else
    fail_test "copilot-deploy doctor found issues. rc=$_cd_doctor_rc output=[$_cd_doctor_out]"
  fi

  # CRLF normalization: mutate a .md file to add CRLF line endings, doctor
  # should still PASS (hash is computed on normalized LF content).
  _cd_test_file="$_CD_TMP/target/.github/copilot-instructions.md"
  python3 -c "
import sys
from pathlib import Path
p = Path(sys.argv[1])
data = p.read_bytes().replace(b'\n', b'\r\n')
p.write_bytes(data)
" "$_cd_test_file"
  _cd_doctor_crlf_out=$(python3 "$_CD_PY" doctor "$_CD_TMP/target" 2>&1)
  _cd_doctor_crlf_rc=$?
  if [ "$_cd_doctor_crlf_rc" -eq 0 ] \
     && ! echo "$_cd_doctor_crlf_out" | grep -qE "\[DRIFT\]"; then
    ok "copilot-deploy doctor treats CRLF and LF as equivalent for text files"
  else
    fail_test "copilot-deploy doctor flagged CRLF as drift (Windows autocrlf regression). rc=$_cd_doctor_crlf_rc output=[$_cd_doctor_crlf_out]"
  fi

  # remove
  _cd_remove_out=$(python3 "$_CD_PY" remove "$_CD_TMP/target" 2>&1)
  _cd_remove_rc=$?
  if [ "$_cd_remove_rc" -eq 0 ] && echo "$_cd_remove_out" | grep -q "SUMMARY: removed=" \
     && [ ! -f "$_CD_TMP/target/.github/copilot-instructions.md" ] \
     && [ ! -f "$_CD_TMP/target/.github/work-copilot/install-manifest.json" ]; then
    ok "copilot-deploy remove deletes installed files"
  else
    fail_test "copilot-deploy remove failed. rc=$_cd_remove_rc output=[$_cd_remove_out]"
  fi

  rm -rf "$_CD_TMP"
else
  echo "  SKIP: python3 not available, skipping copilot-deploy smoke test"
fi

# ---------- S000010: bundle artifact completeness coverage ----------
# Tests the v2 mirror artifacts beyond the v1 templates check.
# (S000010_TEST-SPEC.md tests 8, 9, 10, 12 — install-side coverage.)
#
# These tests deliberately invoke commands that exit non-zero (validate.sh
# failing on drift, doctor refusing path-traversal). Disable errexit for
# this block; restore at the end. Test failures still report via fail_test.

set +e

echo ""
echo "Checking S000010 bundle-artifact-completeness coverage..."

# Test 8 (S000010): copilot-instructions.md ≤ 8192 bytes
_ci_size=$(wc -c < "$REPO_ROOT/work-copilot/instructions/copilot-instructions.md" | tr -d ' ')
if [ "$_ci_size" -le 8192 ]; then
  ok "S000010 test 8: copilot-instructions.md is $_ci_size bytes (≤8192 budget)"
else
  fail_test "S000010 test 8: copilot-instructions.md is $_ci_size bytes (over 8192 budget)"
fi

# Test 9 (S000010): bundle-layout pointers present (grep -F per path)
_ci_file="$REPO_ROOT/work-copilot/instructions/copilot-instructions.md"
_ci_missing=""
for _path in "work-copilot/WORKFLOW.md" "work-copilot/reference/" "work-copilot/philosophy/" "work-copilot/examples/" "work-copilot/fixtures/"; do
  if ! grep -qF "$_path" "$_ci_file"; then
    _ci_missing="$_ci_missing $_path"
  fi
done
if [ -z "$_ci_missing" ]; then
  ok "S000010 test 9: copilot-instructions.md references all 5 new bundle dirs"
else
  fail_test "S000010 test 9: copilot-instructions.md missing path strings:$_ci_missing"
fi

# Test 10 (S000010): install spot-checks for each new bundle dir + DRIFT case
if command -v python3 >/dev/null 2>&1; then
  _S010_TMP=$(mktemp -d -t s010-test.XXXXXX)
  mkdir -p "$_S010_TMP/target"
  python3 "$REPO_ROOT/scripts/copilot-deploy.py" install "$_S010_TMP/target" >/dev/null 2>&1
  _spot_missing=""
  for _spot in \
    ".github/work-copilot/WORKFLOW.md" \
    ".github/work-copilot/reference/guide-general.md" \
    ".github/work-copilot/philosophy/rationale-PRD.md" \
    ".github/work-copilot/examples/example-doc-ARCHITECTURE.md" \
    ".github/work-copilot/fixtures/invalid-bad-frontmatter.md"; do
    [ -f "$_S010_TMP/target/$_spot" ] || _spot_missing="$_spot_missing $_spot"
  done
  if [ -z "$_spot_missing" ]; then
    ok "S000010 test 10: install lays down 5/5 new mirror artifacts (1 per new bundle dir)"
  else
    fail_test "S000010 test 10: install missing artifacts:$_spot_missing"
  fi

  # Test 12 (S000010): doctor reports DRIFT on a NESTED fixture (G9 — the file
  # that historically drifted, not just top-level WORKFLOW.md)
  _nested="$_S010_TMP/target/.github/work-copilot/fixtures/valid-feature-dir/TRACKER.md"
  if [ -f "$_nested" ]; then
    echo "extra mutation" >> "$_nested"
    _drift_out=$(python3 "$REPO_ROOT/scripts/copilot-deploy.py" doctor "$_S010_TMP/target" 2>&1)
    _drift_rc=$?
    if [ "$_drift_rc" -ne 0 ] && echo "$_drift_out" | grep -qF "[DRIFT]" && echo "$_drift_out" | grep -qF "valid-feature-dir/TRACKER.md"; then
      ok "S000010 test 12 (G9): doctor reports DRIFT on nested fixture mutation"
    else
      fail_test "S000010 test 12 (G9): doctor missed DRIFT on nested fixture. rc=$_drift_rc output=[$_drift_out]"
    fi
  else
    fail_test "S000010 test 12 (G9): nested fixture not installed; cannot test DRIFT detection"
  fi

  # Test 13 (autoplan G3): path-traversal defense in doctor
  python3 -c "
import json, sys
mp = sys.argv[1]
with open(mp) as f: m = json.load(f)
m['files'].append({'src':'fake', 'dest':'../../../etc/passwd', 'sha256':'fake'})
with open(mp, 'w') as f: json.dump(m, f, indent=2)
" "$_S010_TMP/target/.github/work-copilot/install-manifest.json"
  _trav_out=$(python3 "$REPO_ROOT/scripts/copilot-deploy.py" doctor "$_S010_TMP/target" 2>&1)
  _trav_rc=$?
  if [ "$_trav_rc" -eq 2 ] && echo "$_trav_out" | grep -qF "escapes target directory"; then
    ok "autoplan G3: doctor refuses path-traversal in install-manifest"
  else
    fail_test "autoplan G3: doctor accepted path-traversal entry. rc=$_trav_rc output=[$_trav_out]"
  fi

  # Test 14 (DX3): --dry-run leaves filesystem untouched
  _DRY_TMP=$(mktemp -d -t s010-dry.XXXXXX)
  mkdir -p "$_DRY_TMP/target"
  python3 "$REPO_ROOT/scripts/copilot-deploy.py" install --dry-run "$_DRY_TMP/target" >/dev/null 2>&1
  if [ ! -d "$_DRY_TMP/target/.github" ]; then
    ok "DX3: install --dry-run does not write to filesystem"
  else
    fail_test "DX3: install --dry-run created $_DRY_TMP/target/.github (should not write)"
  fi
  rm -rf "$_DRY_TMP"

  rm -rf "$_S010_TMP"
else
  echo "  SKIP: python3 not available, skipping S000010 install tests"
fi

# ---------- CJ_improve-queue: append path keeps TODOS.md POSIX-clean ----------
# Regression guard: build_row()'s output is captured via $(...), which strips
# the trailing newline; atomic_append must re-add exactly one so TODOS.md ends
# with a single \n after every append. All three modes (audit/evaluate/research)
# funnel through cmd_apply -> atomic_append, so this one path covers them all.
# A prior fix (commit 8c2ee8f) only patched the artifact, not the source — this
# test fails if the EOF newline regresses (dropped) or doubles (trailing blank
# line), on the FIRST append and on a SECOND consecutive append.
echo ""
echo "Checking CJ_improve-queue append path keeps TODOS.md POSIX-clean..."
_IQ_SCRIPT="$REPO_ROOT/skills/CJ_improve-queue/scripts/improve_queue.sh"
_IQ_FIX="$REPO_ROOT/tests/fixtures/CJ_improve-queue"
if [ -x "$_IQ_SCRIPT" ] && [ -f "$_IQ_FIX/sample-verdict-novel.json" ] && [ -f "$_IQ_FIX/sample-verdict-conflict.json" ]; then
  _IQ_TMP=$(mktemp -d -t improve-queue-eof.XXXXXX)
  (
    cd "$_IQ_TMP"
    git init -q
    git config user.email test@test.local
    git config user.name test
    printf '# TODOS\n\n- existing row\n' > TODOS.md
    git add TODOS.md && git commit -qm init
  ) >/dev/null 2>&1

  # assert TODOS.md ends with exactly one LF: last 2 bytes hex = "XX0a", XX != 0a.
  _iq_assert_single_lf() {  # $1=file  $2=label
    local l2
    l2=$(tail -c 2 "$1" | xxd -p | tr -d '\n')
    case "$l2" in
      0a0a) fail_test "$2: TODOS.md EOF has a trailing blank line (double \\n, last2=[$l2])" ;;
      *0a)  ok "$2: TODOS.md ends with exactly one trailing newline" ;;
      *)    fail_test "$2: TODOS.md missing trailing newline (last2=[$l2])" ;;
    esac
  }

  # 1st append (novel verdict).
  ( cd "$_IQ_TMP" && bash "$_IQ_SCRIPT" apply < "$_IQ_FIX/sample-verdict-novel.json" ) >/dev/null 2>&1
  _iq_assert_single_lf "$_IQ_TMP/TODOS.md" "CJ_improve-queue 1st append"

  # Commit row1, then 2nd append (conflict verdict — distinct signature, so it
  # appends rather than NO-OPs). Proves the fix recurs cleanly across appends.
  ( cd "$_IQ_TMP" && git add -A && git commit -qm row1 ) >/dev/null 2>&1
  ( cd "$_IQ_TMP" && bash "$_IQ_SCRIPT" apply < "$_IQ_FIX/sample-verdict-conflict.json" ) >/dev/null 2>&1
  _iq_assert_single_lf "$_IQ_TMP/TODOS.md" "CJ_improve-queue 2nd append"

  unset -f _iq_assert_single_lf
  rm -rf "$_IQ_TMP" /tmp/cj-improve-queue-lock
else
  echo "  SKIP: CJ_improve-queue script or fixtures missing, skipping EOF regression test"
fi

# T000011 MIRROR_SPECS sync-check block deleted in S000052 (F000023).
# The validate.sh Error check 10 MIRROR_SPECS machinery this block tested
# (drift detection, orphan FAIL-vs-WARN policy, manifest schema parity) was
# removed when work-copilot/ became canonical. No mirror = no drift = no
# corresponding test surface. The existence-check that replaces it is
# directly exercised by ./scripts/validate.sh on every CI run.

# Restore errexit after the S000010 test block.
set -e

# Integration: test-deploy.sh end-to-end (D000016)
# The wrapper-grep check at line ~388 confirms test-deploy.sh defines the jq()
# CRLF-stripping wrapper structurally. This phase actually RUNS test-deploy.sh
# end-to-end so template-ownership regressions in skills-deploy fail in CI loudly
# instead of rotting silently — closes the meta-bug behind D000016.
echo ""
# TEST_FAST (F000081 follow-up): test-deploy.sh is the heavy skills-deploy fixture
# suite (many throwaway temp-dir installs) — the slowest deterministic sub-suite and
# the biggest remaining CI-push cost after the negative-test speedup. It is re-layered
# to CI-nightly: the per-PR gate (.github/workflows/validate.yml) runs test.sh with
# TEST_FAST=1 to SKIP it, and the full nightly suite (.github/workflows/nightly.yml,
# no flag) still runs it every night. TEST_FAST gates ONLY this heavy suite; every
# fast unit sub-suite + the inline integration tests still run on every PR.
if [ "${TEST_FAST:-0}" = "1" ]; then
  echo "SKIP: scripts/test-deploy.sh (TEST_FAST=1 — the heavy skills-deploy fixture suite runs on the CI-nightly cadence via .github/workflows/nightly.yml, not per-PR)"
else
  echo "Running scripts/test-deploy.sh end-to-end..."
  if "$REPO_ROOT/scripts/test-deploy.sh" >/dev/null 2>&1; then
    ok "scripts/test-deploy.sh passed end-to-end (skills-deploy template-ownership tests)"
  else
    _td_rc=$?
    fail_test "scripts/test-deploy.sh failed end-to-end (rc=$_td_rc) — run \`./scripts/test-deploy.sh\` directly to see failures"
  fi
fi

# Smoke-test scripts/check-version-queue.sh
echo ""
echo "Smoke-testing scripts/check-version-queue.sh..."
if "$REPO_ROOT/scripts/check-version-queue.sh" >/dev/null 2>&1; then
  ok "scripts/check-version-queue.sh exits 0 on default (human-readable) invocation"
else
  _cvq_rc=$?
  fail_test "scripts/check-version-queue.sh failed on default invocation (rc=$_cvq_rc) — run \`./scripts/check-version-queue.sh\` directly to see"
fi
# Verify --json mode produces valid JSON (only when gh is online + authed; skip otherwise)
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  _cvq_json=$("$REPO_ROOT/scripts/check-version-queue.sh" --json 2>/dev/null || true)
  if [ -n "$_cvq_json" ] && echo "$_cvq_json" | jq -e '.next' >/dev/null 2>&1; then
    ok "scripts/check-version-queue.sh --json emits valid JSON with .next field"
  else
    fail_test "scripts/check-version-queue.sh --json output is not valid JSON or missing .next field"
  fi
fi

# Regression test (F000025/S000054): /CJ_goal_todo_fix SKILL.md preamble sources
# scripts/cj-worktree-init.sh BEFORE Path Resolution / Routing.
# Mirrors the D000013 setup-hooks idiom — single grep per target SKILL.md.
# Without these, an upstream refactor could silently drop the auto-worktree
# wiring and the feature would regress to "polluting main checkout"
# behavior with no test signal.
# (F000035 v6.0.0 sunset: dropped the /CJ_goal_run + /CJ_goal_investigate shim
# assertions — both skills retired, files deleted.)
echo ""
echo "Regression test (F000025): /CJ_goal_todo_fix SKILL.md wires cj-worktree-init.sh..."

if grep -qE 'cj-worktree-init\.sh' "$REPO_ROOT/skills/CJ_goal_todo_fix/SKILL.md" \
   && grep -qE -- '--caller todo' "$REPO_ROOT/skills/CJ_goal_todo_fix/SKILL.md"; then
  ok "skills/CJ_goal_todo_fix/SKILL.md sources cj-worktree-init.sh (--caller todo)"
else
  fail_test "skills/CJ_goal_todo_fix/SKILL.md missing cj-worktree-init.sh wiring (F000025 regression guard)"
fi

if grep -q 'cj-worktree-init\.sh' "$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh" \
   && grep -qE '\-\-caller todo.*--force-create' "$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"; then
  ok "skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh calls cj-worktree-init.sh with --caller todo --force-create"
else
  fail_test "drain-one-todo.sh missing per-iteration cj-worktree-init.sh --force-create call (F000025 regression guard)"
fi

# Helper test: behavior coverage (F000025 5 mutating-mode cases + F000045 4
# base-freshness Fork-1 cases [behind/diverged/offline/already-fresh, local fake
# origin] + T000033 8 --assert-isolated verdict cases + caller→prefix matrix +
# CJ_goal_feature/pipeline.md Step 1.9 static-grep guard). (F000039: the prior
# guard assertion on the now-deleted middle-layer pipeline skill retired with
# that skill; only the feature pipeline.md guard remains.)
echo ""
echo "Running tests/cj-worktree-init.test.sh (helper behavior test incl. F000045 Fork-1 freshness cases)..."
if bash "$REPO_ROOT/tests/cj-worktree-init.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-worktree-init.test.sh: all cases pass (incl. behind/diverged/offline/already-fresh)"
else
  _cwit_rc=$?
  fail_test "tests/cj-worktree-init.test.sh failed (rc=$_cwit_rc) — run \`bash tests/cj-worktree-init.test.sh\` directly to see"
fi

# Helper test (T000036): the post-run worktree-cleanup janitor. 13 behavior cases
# (PR-state decision table + local-state rails + dry-run no-op + prune + guarded
# root-refresh + cwd-not-a-repo) using a fake cj-goal-common.sh sibling for
# deterministic PR-state control, plus static-grep wiring assertions for the
# --phase cleanup registration and all four terminal seams. Registration is
# MANDATORY — scripts/test.sh discovery is NOT glob-based; an unregistered
# tests/*.test.sh silently never runs.
echo ""
echo "Running tests/cj-worktree-cleanup.test.sh (post-run janitor: 13 cases + wiring)..."
if bash "$REPO_ROOT/tests/cj-worktree-cleanup.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-worktree-cleanup.test.sh: all cases pass"
else
  _cwct_rc=$?
  fail_test "tests/cj-worktree-cleanup.test.sh failed (rc=$_cwct_rc) — run \`bash tests/cj-worktree-cleanup.test.sh\` directly to see"
fi

# F000054: /CJ_goal_task topic-driven scaffold + the HARD complexity gate.
echo ""
echo "Running tests/cj-task-scaffold.test.sh (F000054 complexity gate + topic scaffold)..."
if bash "$REPO_ROOT/tests/cj-task-scaffold.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-task-scaffold.test.sh: gate refusals + dry-run + live scaffold + idempotency all pass"
else
  _cts_rc=$?
  fail_test "tests/cj-task-scaffold.test.sh failed (rc=$_cts_rc) — run \`bash tests/cj-task-scaffold.test.sh\` directly to see"
fi

# T000052: guard the PR-body splice idiom across the 4 cj_goal pipeline.md files.
# T000053 (PR #279) replaced the BSD/macOS-awk-fragile `awk -v <var>="$payload"`
# splice with temp-file + `gh pr edit --body-file` but shipped DOC-ONLY; this
# guard asserts the wiper idiom cannot creep back into one of the four copies.
# Registration is MANDATORY — scripts/test.sh discovery is hand-written, NOT
# glob-based; an unregistered tests/*.test.sh silently never runs.
echo ""
echo "Running tests/cj-goal-pr-body-splice-guard.test.sh (no multi-line 'awk -v' PR-body payload in 4 pipeline.md)..."
if bash "$REPO_ROOT/tests/cj-goal-pr-body-splice-guard.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-pr-body-splice-guard.test.sh: no dangerous 'awk -v' payload idiom in any cj_goal pipeline.md"
else
  _cgpbsg_rc=$?
  fail_test "tests/cj-goal-pr-body-splice-guard.test.sh failed (rc=$_cgpbsg_rc) — run \`bash tests/cj-goal-pr-body-splice-guard.test.sh\` directly to see"
fi

# Regression drill for the jq-CRLF class in the CJ_goal_* / check-* orchestrator
# helpers (the Windows P0). A Windows jq build emits CRLF, so a raw $(jq -r ...)
# capture leaves a trailing \r that breaks `[ -d "$src" ]` and silently degrades
# the cj-goal-common sync/pr-check phases to `skipped` on Windows. This drill
# asserts the CR-stripping jq() wrapper (mirrors lib.sh:24) is present in all five
# helpers and works under a CRLF-emitting jq shim. Registration is MANDATORY —
# scripts/test.sh discovery is hand-written, NOT glob-based; an unregistered
# tests/*.test.sh silently never runs.
echo ""
echo "Running tests/cj-goal-jq-crlf.test.sh (CR-stripping jq() wrapper in the 5 orchestrator helpers)..."
if bash "$REPO_ROOT/tests/cj-goal-jq-crlf.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-jq-crlf.test.sh: all 5 helpers strip jq CRLF (structural + CRLF-shim mechanism + worktree-phase e2e)"
else
  _cgjc_rc=$?
  fail_test "tests/cj-goal-jq-crlf.test.sh failed (rc=$_cgjc_rc) — run \`bash tests/cj-goal-jq-crlf.test.sh\` directly to see"
fi

# F000071 Part A / S000120: the build-gate auto-answer seam verdict helper
# (scripts/cj-e2e-gate.sh). The seam is dormant unless a double hard guard holds
# (CJ_GOAL_E2E_AUTO=1 AND a .cj-e2e-sandbox marker at the repo root) AND the gate
# id is in the {design-gate, qa-audit} allowlist; the qa-audit auto-continue
# reuses todo_fix --quiet's green-only predicate (continue ONLY on doc:ok,test:ok;
# any findings → halt). This deterministic test asserts the whole verdict matrix
# in throwaway sandboxes (no Claude). Registration is MANDATORY — scripts/test.sh
# discovery is hand-written, NOT glob-based; an unregistered tests/*.test.sh
# silently never runs.
echo ""
echo "Running tests/cj-e2e-gate.test.sh (build-gate auto-answer seam verdict matrix)..."
if bash "$REPO_ROOT/tests/cj-e2e-gate.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-e2e-gate.test.sh: verdict matrix passes (flag/marker/allowlist/green-digest guard, design-gate auto-approve)"
else
  _ceg_rc=$?
  fail_test "tests/cj-e2e-gate.test.sh failed (rc=$_ceg_rc) — run \`bash tests/cj-e2e-gate.test.sh\` directly to see"
fi

# The nightly doc/test audit runner (F000076) relocates the advisory Stage-2/3
# audit off the CJ_goal_* build hot path. Its deterministic half (SKIP-without-key,
# dry-run, findings-parse, issue create/update/none) is exercised here with claude
# + gh stubbed on PATH — no model, no network, no spend in a normal test.sh.
echo ""
echo "Running tests/audit-nightly.test.sh (nightly doc/test audit runner — deterministic half, claude+gh stubbed)..."
if bash "$REPO_ROOT/tests/audit-nightly.test.sh" >/dev/null 2>&1; then
  ok "tests/audit-nightly.test.sh: SKIP-without-key + dry-run + findings-parse + issue create/update/none all pass (no model, no network)"
else
  _an_rc=$?
  fail_test "tests/audit-nightly.test.sh failed (rc=$_an_rc) — run \`bash tests/audit-nightly.test.sh\` directly to see"
fi

# F000071 Part B / S000121: the local-E2E harness (scripts/e2e-local.sh +
# tests/e2e-local/lib/{sandbox,report}.sh). This runs the harness's DETERMINISTIC
# half only (no Claude, no gstack, no API key): the SKIP path (flag unset →
# exit 0, no claude), the sandbox provision/teardown, the materialized report
# generator on synthetic evidence (DETERMINISTIC-vs-claude-print rows; a missing
# evidence row renders `unverified`, never a false pass), and the gitignore
# posture. The REAL /CJ_goal_task run is a LOCAL manual E2E and is deliberately
# NOT invoked here. Registration is MANDATORY — scripts/test.sh discovery is
# hand-written, NOT glob-based; an unregistered tests/*.test.sh silently never runs.
echo ""
echo "Running tests/e2e-local.test.sh (local-E2E harness deterministic half)..."
if bash "$REPO_ROOT/tests/e2e-local.test.sh" >/dev/null 2>&1; then
  ok "tests/e2e-local.test.sh: SKIP path + sandbox lib + report generator + gitignore posture all pass (real run is local-only)"
else
  _eel_rc=$?
  fail_test "tests/e2e-local.test.sh failed (rc=$_eel_rc) — run \`bash tests/e2e-local.test.sh\` directly to see"
fi

# F000072 / S000122: the runners: axis + test-run.sh engine. This runs the engine
# against TEMP-DIR FIXTURE registries only (the REPO_ROOT / TEST_SPEC_PATH env
# overrides) — it NEVER invokes the real scripts/test.sh (the workbench's
# run-test-sh runner IS `bash scripts/test.sh`, so calling it from inside the
# suite test.sh runs would be a recursion trap). It asserts: --validate accepts a
# well-formed runners: axis + rejects each violation (dup id, bad tier/platform,
# empty command, unknown covers, ci/hook rejection); --list-runners +
# --list-units --with-family; the --dry-run plan; tier gating; the platform guard;
# rc->outcome mapping; aggregate {pass, fail, all-skipped}; self-gate detection;
# ledger fields (schema 1); the absent/invalid/no-runners edge paths; covers: all
# expansion. Registration is MANDATORY — scripts/test.sh discovery is hand-written,
# NOT glob-based; an unregistered tests/*.test.sh silently never runs.
echo ""
echo "Running tests/test-run.test.sh (runners: axis + test-run.sh engine — fixture repos)..."
if bash "$REPO_ROOT/tests/test-run.test.sh" >/dev/null 2>&1; then
  ok "tests/test-run.test.sh: runners-axis grammar + plan/tier/platform/rc-mapping/aggregate/self-gate/ledger/edge-path/covers-all drills all pass (fixtures only; never runs the real test.sh)"
else
  _trs_rc=$?
  fail_test "tests/test-run.test.sh failed (rc=$_trs_rc) — run \`bash tests/test-run.test.sh\` directly to see"
fi

# Regression test (F000011 fix, Approach A): the post-merge git hook installed by
# setup-hooks.sh must redeploy skills (Section 1) but NOT auto-edit work-item
# trackers. The former Phase-3 lifecycle-gate block dirtied main on every
# main-moving pull (breaking post-land-sync.sh's `pull --ff-only` and re-arming
# cj-worktree-init.sh's dirty-checkout guard). setup-hooks.test.sh Smoke 1
# installs into a throwaway temp repo and asserts the generated post-merge hook
# has Section 1 but no check-gates-update / Phase-3 auto-tick. Registration is
# MANDATORY — scripts/test.sh discovery is hand-written, NOT glob-based; an
# unregistered tests/*.test.sh silently never runs (this file was previously
# unregistered).
echo ""
echo "Running tests/setup-hooks.test.sh (post-merge hook: no tracker auto-tick after F000011 fix)..."
if bash "$REPO_ROOT/tests/setup-hooks.test.sh" >/dev/null 2>&1; then
  ok "tests/setup-hooks.test.sh: installed post-merge hook redeploys but no longer auto-ticks trackers (F000011 fix)"
else
  _shk_rc=$?
  fail_test "tests/setup-hooks.test.sh failed (rc=$_shk_rc) — run \`bash tests/setup-hooks.test.sh\` directly to see"
fi

# Regression test (drain-one-todo worktree-init path resolution defect):
# drain-one-todo.sh must resolve scripts/cj-worktree-init.sh via the
# workbench-source path in ~/.claude/.skills-templates.json (.source) — the
# same convention todo_fix.sh / the single-TODO SKILL.md preamble / the
# F000009 update-check preamble use. The original BASH_SOURCE-relative
# `../../..` resolution silently broke from the deployed ~/.claude/ location
# (skills-deploy never deploys repo-root scripts/ there), so drain ran every
# TODO in-place and lost per-iteration worktree isolation (the F000025/S000054
# collision-avoidance the feature exists to provide).
echo ""
echo "Running tests/drain-one-todo-worktree-resolve.test.sh (deployed-path resolution)..."
if bash "$REPO_ROOT/tests/drain-one-todo-worktree-resolve.test.sh" >/dev/null 2>&1; then
  ok "tests/drain-one-todo-worktree-resolve.test.sh: deployed drain resolves cj-worktree-init.sh via manifest .source"
else
  _dwr_rc=$?
  fail_test "tests/drain-one-todo-worktree-resolve.test.sh failed (rc=$_dwr_rc) — run \`bash tests/drain-one-todo-worktree-resolve.test.sh\` directly to see"
fi

# Regression test (drain-one-todo silent in-place scaffold when worktree
# helper unavailable — distinct from D000021): when cj-worktree-init.sh is
# genuinely unreachable in drain dispatch context ($_WT_HELPER empty: manifest
# .source missing/empty/non-exec AND the BASH_SOURCE in-repo fallback also not
# executable), drain-one-todo.sh must FAIL LOUD (release lock; RESULT:
# STATUS=halted; REASON=worktree-helper-unavailable; exit 2) instead of
# silently delegating to todo_fix.sh and scaffolding the drained TODO into the
# current (possibly dirty / unrelated) branch. D000021 fixed only the path
# resolution; its RCA Insights explicitly scoped this silent-fallthrough out.
echo ""
echo "Running tests/drain-one-todo-helper-unavailable.test.sh (unreachable-helper fail-loud)..."
if bash "$REPO_ROOT/tests/drain-one-todo-helper-unavailable.test.sh" >/dev/null 2>&1; then
  ok "tests/drain-one-todo-helper-unavailable.test.sh: drain halts loud when cj-worktree-init.sh unreachable (no in-place scaffold)"
else
  _dhu_rc=$?
  fail_test "tests/drain-one-todo-helper-unavailable.test.sh failed (rc=$_dhu_rc) — run \`bash tests/drain-one-todo-helper-unavailable.test.sh\` directly to see"
fi

# (F000035 v6.0.0 sunset: removed the `tests/cj-goal-investigate-did-allocator.test.sh`
# runner block — the test exercised the /CJ_goal_investigate pipeline's D-ID
# allocator, which retired with the skill itself. The depth-3 nested-domain
# bug it guarded against is now CJ_goal_defect-territory; if that path
# regresses, a fresh test in the defect skill's TEST-SPEC owns the guard.)

# (F000040 / S000073 retirement: removed the
# `tests/cj-goal-doc-sync-auq-recommendation.test.sh` runner block — the test
# exercised the F000028/F000029 doc-sync marker-pickup AUQ polarity, which has
# been fully retired and deleted from disk. The surviving F000036 Step 5.5
# inline doc-sync wiring is still covered by cj-goal-doc-sync-wiring.test.sh below.)

# (F000035 v6.0.0 sunset: removed the `tests/cj-goal-investigate-shim.test.sh`
# runner block — the test exercised the T000035 deprecation-shim contract for
# /CJ_goal_investigate, which has now been fully retired and deleted from disk.)

# Regression test (F000035): the CJ_document-release skill exists, has valid
# frontmatter + USAGE.md, is registered in skills-catalog.json (a non-orchestrator
# skill registers there only — T000037 re-scoped the workflow-doc requirement to
# the CJ_goal_* orchestrators, so CJ_document-release needs NO doc/WORKFLOWS.md
# section), and documents the halt-marker shape + branch + clean-tree refusal
# prose. Unit-shape tests (file content greps) covering the skill itself.
echo ""
echo "Running tests/cj-document-release.test.sh (F000035 skill structure + body assertions; F000037 helper+JSON assertions)..."
if bash "$REPO_ROOT/tests/cj-document-release.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-document-release.test.sh: CJ_document-release skill structure + frontmatter + USAGE.md + catalog + halt markers + F000037 config helper all present"
else
  _cdr_rc=$?
  fail_test "tests/cj-document-release.test.sh failed (rc=$_cdr_rc) — run \`bash tests/cj-document-release.test.sh\` directly to see"
fi

# Regression test (F000050): doc-spec.md registry + scripts/doc-spec.sh helper
# assertions — registry shape, helper subcommands (--validate / --list-declared /
# --list-human-docs / --expand-whitelist / --seed), strict failure gates, and
# cwd-toplevel portability. Replaces the retired JSON-sidecar config checks.
echo ""
echo "Running tests/cj-document-release-config.test.sh (F000050 doc-spec.md registry + helper assertions)..."
if bash "$REPO_ROOT/tests/cj-document-release-config.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-document-release-config.test.sh: doc-spec.md registry + doc-spec.sh subcommands + strict gates + portability all PASS"
else
  _cdrc_rc=$?
  fail_test "tests/cj-document-release-config.test.sh failed (rc=$_cdrc_rc) — run \`bash tests/cj-document-release-config.test.sh\` directly to see"
fi

# Regression test (F000035 + F000076): all 4 cj_goal orchestrators (CJ_goal_feature,
# CJ_goal_defect, CJ_goal_task, CJ_goal_todo_fix) have the Step 5.5 doc-sync
# subsection wired into pipeline.md AND both [doc-sync-red] / [doc-sync-non-doc-write]
# halt-taxonomy rows in SKILL.md, AND (F000076) NO inline qa-audit checkpoint
# machinery survives in any pipeline.md/SKILL.md (the agent-judged audit moved off
# the inline path — it now runs on-demand off the build path; the build tail is doc-sync -> /ship).
echo ""
echo "Running tests/cj-goal-doc-sync-wiring.test.sh (F000035/F000076 4-way symmetric Step 5.5 wiring + no-checkpoint guard)..."
if bash "$REPO_ROOT/tests/cj-goal-doc-sync-wiring.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-doc-sync-wiring.test.sh: Step 5.5 + halt-taxonomy rows present in all 4 cj_goal orchestrators; no inline qa-audit checkpoint survives"
else
  _cgdsw_rc=$?
  fail_test "tests/cj-goal-doc-sync-wiring.test.sh failed (rc=$_cgdsw_rc) — run \`bash tests/cj-goal-doc-sync-wiring.test.sh\` directly to see"
fi

# (F000050 doc-spec migration: removed the `tests/cj-repo-init.test.sh` runner
# block — /CJ_repo-init was retired by the doc-spec.md migration. Its doc-bootstrap
# duty is subsumed by /CJ_document-release's self-bootstrap + stub-scaffold (covered
# by tests/cj-document-release.test.sh + tests/cj-document-release-config.test.sh);
# the non-doc prerequisites are lazy-created by the skills that read them. The skill
# source + its test + its work-item history are relocated under deprecated/CJ_repo-init/
# as archival reference, not run by this suite.)
# Regression test (F000041): scripts/post-land-sync.sh exists + is executable,
# --dry-run resolves `.source` + prints collection_version + would-run commands
# without mutating, and the four guards (missing / non-git / non-main / dirty
# `.source`) refuse with a named message + non-zero exit. Driven entirely via
# --dry-run + a POST_LAND_SYNC_MANIFEST temp fixture — never touches the real
# ~/.claude.
echo ""
echo "Running tests/post-land-sync.test.sh (F000041 helper + --dry-run + guards, no real ~/.claude mutation)..."
if bash "$REPO_ROOT/tests/post-land-sync.test.sh" >/dev/null 2>&1; then
  ok "tests/post-land-sync.test.sh: helper exists + executable; --dry-run previews without mutation; guards refuse bad .source"
else
  _pls_rc=$?
  fail_test "tests/post-land-sync.test.sh failed (rc=$_pls_rc) — run \`bash tests/post-land-sync.test.sh\` directly to see"
fi

# Regression: scripts/tag-release.sh — the post-land v<VERSION> tag publish that
# makes scripts/skills-update-check's ls-remote read non-inert. Hermetic: a local
# bare repo as a fake origin (no network, no real origin), asserting the tag is
# created + pushed, idempotent, --version override, non-semver → exit 1, and the
# --strict-fails / default-fail-softs push-failure split.
echo ""
echo "Running tests/tag-release.test.sh (post-land v<VERSION> tag publish, hermetic — local bare origin, no network / no real origin)..."
if _tr_out=$(bash "$REPO_ROOT/tests/tag-release.test.sh" 2>&1); then
  ok "tests/tag-release.test.sh: v<VERSION> created + pushed to a fake origin; idempotent no-op on re-run; --version override; non-semver → exit 1; strict-fails / default-fail-softs on a push failure"
else
  _tr_rc=$?
  fail_test "tests/tag-release.test.sh failed (rc=$_tr_rc):"
  printf '%s\n' "$_tr_out" | sed 's/^/    [tag-release] /' >&2
fi

# Regression test (F000045 / S000081): scripts/cj-goal-common.sh `--phase sync`
# (Fork 2) — dry-run previews without mutation, --no-sync short-circuits to
# skipped (no install), guard refusals (.source off-main / dirty / missing) →
# skipped + exit 0 (never failed), every mode emits the four KEY=VALUE keys, and
# a real run against a FAKE .source + FAKE skills-deploy reports SYNC_RAN=1.
# Hermetic — never runs a real skills-deploy install against the live ~/.claude.
echo ""
echo "Running tests/cj-goal-common-sync.test.sh (F000045 --phase sync Fork 2, hermetic)..."
if bash "$REPO_ROOT/tests/cj-goal-common-sync.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-common-sync.test.sh: dry-run/no-sync/guard-refusal/real-run all emit the 4-key schema; fail-soft; no real ~/.claude mutation"
else
  _cgcs_rc=$?
  fail_test "tests/cj-goal-common-sync.test.sh failed (rc=$_cgcs_rc) — run \`bash tests/cj-goal-common-sync.test.sh\` directly to see"
fi

# Regression test (F000068 / S000112): scripts/cj-goal-common.sh `--phase recap`
# (the land/PR human-readable 3-part recap formatter) — renders Delivered / How
# to E2E-test it / Next step; the header switches on --when before|after; a
# missing --field renders an empty section and still exits 0 (fail-soft); and
# --field content prints verbatim (no eval). The phase is a PURE FORMATTER, so
# the test is trivially hermetic — it just inspects stdout / exit code, mutating
# nothing.
echo ""
echo "Running tests/cj-goal-common-recap.test.sh (F000068 --phase recap formatter, hermetic)..."
if bash "$REPO_ROOT/tests/cj-goal-common-recap.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-common-recap.test.sh: 3-part block / --when header switch / fail-soft on missing field / verbatim --field (no eval); exit 0"
else
  _cgcr_rc=$?
  fail_test "tests/cj-goal-common-recap.test.sh failed (rc=$_cgcr_rc) — run \`bash tests/cj-goal-common-recap.test.sh\` directly to see"
fi

# Regression test (F000048 / S000084): scripts/cj-id-claim.sh — the atomic
# scaffold-time ID-claim engine that closes the scaffold-before-push race. Cases
# incl. the LOOPED concurrent race (25 rounds, distinct IDs), both reap modes
# (on-origin + TTL), prefix isolation, same-branch reuse, cwd-independent
# shared-claim-root resolution from a linked worktree + a nested subdir, AND the
# slug-less feature-tracker reap regression (Case 8a/8b — a merged `${id}_TRACKER.md`
# with no slug must be reaped on both paths, else stale claims accrue and the next
# scaffold re-hands an already-used F/S ID). Hermetic: every claim happens inside a
# throwaway sandbox repo (live workbench .git untouched).
# MANDATORY — scripts/test.sh discovery is hand-wired, NOT glob-based; an
# unregistered tests/*.test.sh silently never runs.
echo ""
echo "Running tests/cj-id-claim.test.sh (F000048 atomic ID-claim engine: race + reap + reuse + worktree resolution + slug-less feature-tracker reap)..."
if bash "$REPO_ROOT/tests/cj-id-claim.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-id-claim.test.sh: all 12 cases pass (incl. 25-round concurrent race with 0 duplicates + reuse floor/CAS/dry-run regressions + slug-less feature-tracker reap 8a/8b)"
else
  _cic_rc=$?
  fail_test "tests/cj-id-claim.test.sh failed (rc=$_cic_rc) — run \`bash tests/cj-id-claim.test.sh\` directly to see"
fi

# Regression test (F000027 / S000057): the feature-path SHAPE harness —
# worktree entry (--caller feature), the shared helper's worktree/ship/telemetry
# phases under --mode feature, and the leaf-subagent dispatch targets on disk.
# Registered by the F000059 Step-0 triage: this file sat on disk UNREGISTERED
# (the live silent-skip instance the test-spec coverage cross-check now
# mechanizes — validate.sh Check 24 reverse-flags any tests/*.test.sh without a
# registry row, and the row's runner-path anchor forward-proves THIS block
# exists). MANDATORY — scripts/test.sh discovery is hand-wired, NOT glob-based.
echo ""
echo "Running tests/cj-goal-feature-smoke.test.sh (feature-path shape: worktree entry + common phases + leaf targets)..."
if bash "$REPO_ROOT/tests/cj-goal-feature-smoke.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-feature-smoke.test.sh: worktree entry + worktree/ship/telemetry phases + leaf dispatch targets all pass"
else
  _cgfs_rc=$?
  fail_test "tests/cj-goal-feature-smoke.test.sh failed (rc=$_cgfs_rc) — run \`bash tests/cj-goal-feature-smoke.test.sh\` directly to see"
fi

# Regression test (F000060 + F000063): the doc-spec two-tier overlay machinery —
# merge semantics (overlay present/absent), the duplicate-path guard, merged list
# subcommands, the seed == general-file byte identity (3-way lockstep), and the
# 4-check --check-on-disk Stage-1 battery. Temp-dir isolated; never mutates the
# live tree. MANDATORY — scripts/test.sh discovery is hand-wired, NOT glob-based.
echo ""
echo "Running tests/doc-spec-overlay.test.sh (F000060 doc-spec two-tier overlay merge)..."
if bash "$REPO_ROOT/tests/doc-spec-overlay.test.sh" >/dev/null 2>&1; then
  ok "tests/doc-spec-overlay.test.sh: overlay merge + duplicate-path guard + seed byte-identity + Stage-1 battery all pass"
else
  _dso_rc=$?
  fail_test "tests/doc-spec-overlay.test.sh failed (rc=$_dso_rc) — run \`bash tests/doc-spec-overlay.test.sh\` directly to see"
fi

# Regression test (F000060): the test-spec two-tier registry machinery — merged
# parser round-trip (validate / list-rules / list-units), the absent-vs-invalid
# split (REGISTRY=absent exit 0 vs the no-config halt), malformed-registry
# fixtures, the units-gated floor note, seed emission, and the temp-dir
# coverage drift drills ported from the predecessor suite. Temp-dir isolated;
# never mutates the live tree. MANDATORY registration — this suite tests the
# very mechanism that catches unregistered tests, so it must not itself be an
# unregistered test.
echo ""
echo "Running tests/test-spec.test.sh (F000060 two-tier registry parser + coverage drift drills)..."
if bash "$REPO_ROOT/tests/test-spec.test.sh" >/dev/null 2>&1; then
  ok "tests/test-spec.test.sh: merged parser round-trip + absent/invalid split + malformed fixtures + drift drills + units-gated floor all pass"
else
  _tss_rc=$?
  fail_test "tests/test-spec.test.sh failed (rc=$_tss_rc) — run \`bash tests/test-spec.test.sh\` directly to see"
fi

# Regression test (F000060): the audit-skill engines end-to-end in a bare temp
# repo — first run seed-delivers spec/ + both contract files (seeded: yes),
# second run is idempotent (seeded: no), seeded violations produce findings,
# and the clean workbench run stays green. Temp-dir isolated; never mutates
# the live tree. MANDATORY — scripts/test.sh discovery is hand-wired.
echo ""
echo "Running tests/cj-audit-skills.test.sh (F000060 audit-skill seed delivery + engines)..."
if bash "$REPO_ROOT/tests/cj-audit-skills.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-audit-skills.test.sh: bare-repo seed delivery + idempotence + seeded-violation findings + clean workbench baseline all pass"
else
  _cas_rc=$?
  fail_test "tests/cj-audit-skills.test.sh failed (rc=$_cas_rc) — run \`bash tests/cj-audit-skills.test.sh\` directly to see"
fi

# Regression test (F000065): the doc-spec self-healing reconcile — the read-only
# --classify generation detector (absent/canonical/legacy/duplicate/malformed)
# and the opt-in --reconcile write path (a 40+-row legacy YAML fixture migrated
# to the canonical Markdown table preserving every row, atomic + .bak +
# idempotent; the audit_class asymmetry guard; the malformed-no-clobber halt;
# the live-workbench canonical-no-noise baseline). Temp-dir isolated; never
# mutates the live tree. MANDATORY — scripts/test.sh discovery is hand-wired,
# NOT glob-based.
echo ""
echo "Running tests/doc-spec-reconcile.test.sh (F000065 doc-spec classify + legacy->canonical reconcile)..."
if bash "$REPO_ROOT/tests/doc-spec-reconcile.test.sh" >/dev/null 2>&1; then
  ok "tests/doc-spec-reconcile.test.sh: classify four generations + 40+-row legacy migration (every row preserved) + asymmetry guard + malformed-no-clobber + live-canonical-no-noise all pass"
else
  _dsr_rc=$?
  fail_test "tests/doc-spec-reconcile.test.sh failed (rc=$_dsr_rc) — run \`bash tests/doc-spec-reconcile.test.sh\` directly to see"
fi

# Regression test (F000065): the test-spec self-healing reconcile — the
# SYMMETRIC but REDUCED partner of the doc-spec engine. test-spec's fenced-yaml
# format never diverged on disk, so --classify labels {canonical, absent,
# duplicate, malformed} (never legacy) and --reconcile is a dedup/no-op
# (canonical clean no-op; duplicate reports the redundant copy with no
# auto-delete; malformed halts; live-workbench canonical-no-noise). Temp-dir
# isolated; never mutates the live tree. MANDATORY registration — Check 24's
# reverse sweep hard-fails any unregistered tests/*.test.sh.
echo ""
echo "Running tests/test-spec-reconcile.test.sh (F000065 test-spec classify + dedup/no-op reconcile)..."
if bash "$REPO_ROOT/tests/test-spec-reconcile.test.sh" >/dev/null 2>&1; then
  ok "tests/test-spec-reconcile.test.sh: classify (never legacy) + canonical no-op + duplicate-reported-no-delete + malformed-halt + live-canonical-no-noise all pass"
else
  _tsr_rc=$?
  fail_test "tests/test-spec-reconcile.test.sh failed (rc=$_tsr_rc) — run \`bash tests/test-spec-reconcile.test.sh\` directly to see"
fi

# Regression test (F000069): the generated test-catalog renderer — test-spec.sh
# --render-docs is the SECOND instance of the README ↔ generate-readme.sh ↔
# Check 25 freshness primitive, applied to the test surface. The suite asserts
# render→render byte-stability, work-item-ID-freeness of the output (the anchor
# IDs are masked so the human-docs pass Check 19 by construction), --check exit 0
# on a freshly-rendered tree, and --check exit 1 after a hand-edit. Temp-dir
# isolated (TESTDOC_OUT override); never mutates the live tree. MANDATORY
# registration — Check 24's reverse sweep hard-fails any unregistered
# tests/*.test.sh.
echo ""
echo "Running tests/test-spec-render.test.sh (F000069 generated test-catalog renderer + freshness)..."
if bash "$REPO_ROOT/tests/test-spec-render.test.sh" >/dev/null 2>&1; then
  ok "tests/test-spec-render.test.sh: render stability + ID-free output + --check pass-on-fresh / fail-on-edit all pass"
else
  _tsrender_rc=$?
  fail_test "tests/test-spec-render.test.sh failed (rc=$_tsrender_rc) — run \`bash tests/test-spec-render.test.sh\` directly to see"
fi

# tests/workflow-spec-render.test.sh — the hermetic test for scripts/workflow-spec.sh
# --render-docs, the THIRD instance of the README ↔ generate-readme.sh ↔ Check 25 +
# test-catalog ↔ Check 26 freshness primitive, applied to the workflow surface
# (F000069/S000115). The suite asserts render→render byte-stability,
# work-item-ID-freeness of the output (IDs masked so the human-docs pass Check 19),
# --check exit 0 on a fresh tree + exit 1 after a hand-edit / a removal, AND the
# no-vanish remove-an-entry drill (--validate registry-completeness fails closed
# when a routable CJ_goal_* orchestrator entry is removed — the retired-Check-15c
# replacement), AND the CRLF-jq drill (a PATH-prepended CRLF-emitting jq shim must
# not false-halt registry-completeness — the Windows-jq regression guard for the
# engine's local jq() wrapper). Temp-dir + temp-repo isolated; never mutates the
# live tree or the real catalog. MANDATORY registration — Check 24's reverse sweep
# hard-fails any unregistered tests/*.test.sh.
echo ""
echo "Running tests/workflow-spec-render.test.sh (F000069 generated workflow-docs renderer + freshness + no-vanish)..."
if bash "$REPO_ROOT/tests/workflow-spec-render.test.sh" >/dev/null 2>&1; then
  ok "tests/workflow-spec-render.test.sh: render stability + ID-free output + --check pass/fail-on-edit/fail-on-missing + the no-vanish drill + the CRLF-jq drill all pass"
else
  _wsrender_rc=$?
  fail_test "tests/workflow-spec-render.test.sh failed (rc=$_wsrender_rc) — run \`bash tests/workflow-spec-render.test.sh\` directly to see"
fi

# tests/seed-contracts.test.sh — the hermetic test for `skills-deploy
# seed-contracts` + the stale-engine capability probe (F000069/S000116). The
# suite asserts: (A) seed-all-3 into a consumer repo + each --validate-clean +
# idempotent re-run; (B) the workbench self-repo is SKIPPED via BOTH detection
# signals (manifest-source match + custom-overlay) with the real contracts
# untouched (the data-loss guard); (C) a planted stale repo-local engine (no
# --classify) falls back to _cj-shared + emits stage1/engine-stale; (D) the
# corruption guard holds — a --validate-dirty --seed reports seed-failed and
# nothing lands in spec/. Fully hermetic: engines resolve from a pinned
# _cj-shared (the repo's scripts/), SKILLS_DEPLOY_MANIFEST is overridden, and
# every seed lands in a throwaway sandbox — the live workbench + the operator's
# real ~/.claude are never touched. MANDATORY registration — Check 24's reverse
# sweep hard-fails any unregistered tests/*.test.sh.
echo ""
echo "Running tests/seed-contracts.test.sh (F000069/S000116 forced seeding + stale-engine probe + data-loss guard)..."
if bash "$REPO_ROOT/tests/seed-contracts.test.sh" >/dev/null 2>&1; then
  ok "tests/seed-contracts.test.sh: seed-all-3 + idempotent + workbench-self skip + stale-engine fallback + corruption guard all pass"
else
  _seedc_rc=$?
  fail_test "tests/seed-contracts.test.sh failed (rc=$_seedc_rc) — run \`bash tests/seed-contracts.test.sh\` directly to see"
fi

# tests/cj-contract-gate.test.sh — the hermetic test for scripts/cj-contract-gate.sh
# (the deterministic, agent-free Stage-1 contract gate) + its guarded consumer
# pre-commit auto-install (F000069/S000117 — the FINAL story of the epic). The
# suite asserts: PART (a) gate dispositions — PASS on a clean fully-adopted
# contract, hard-FAIL on a planted violation (a stale generated catalog OR a
# malformed registry), a missing DECLARED doc treated as a SOFT remediation
# (exit 0, pointing at /CJ_document-release — never a block), and a registry-absent
# contract a clean SKIP; PART (b) the guarded consumer install — install-contract-gate
# installs a sentinel pre-commit hook resolving cj-contract-gate.sh from _cj-shared
# (idempotent re-run), a custom core.hooksPath (husky) is SKIPPED, the workbench
# self-repo is SKIPPED, and --remove uninstalls ONLY a sentinel hook while a
# non-workbench hook is left untouched. Fully hermetic: engines + the gate resolve
# from a pinned _cj-shared (the repo's scripts/), SKILLS_DEPLOY_MANIFEST is
# overridden, every sandbox is a throwaway repo — the live workbench + the real
# ~/.claude are never touched. MANDATORY registration — Check 24's reverse sweep
# hard-fails any unregistered tests/*.test.sh.
echo ""
echo "Running tests/cj-contract-gate.test.sh (F000069/S000117 deterministic contract gate + guarded consumer hook install)..."
if bash "$REPO_ROOT/tests/cj-contract-gate.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-contract-gate.test.sh: gate PASS/hard-FAIL/declared-exists-soft/registry-absent-SKIP + consumer auto-install sentinel/husky-skip/self-skip/--remove all pass"
else
  _ccg_rc=$?
  fail_test "tests/cj-contract-gate.test.sh failed (rc=$_ccg_rc) — run \`bash tests/cj-contract-gate.test.sh\` directly to see"
fi

# F000070 / S000119 — the workflow-coverage gate machinery (the forward+reverse
# level:workflow gate + the 6th `workflow` behaviors-TSV column + the registry-
# sourced --list-orchestrators). MANDATORY registration — Check 24's reverse
# sweep hard-fails any unregistered tests/*.test.sh, and this file has a parallel
# `test-workflow-coverage` units row in spec/test-spec-custom.md. Fully hermetic:
# every fixture is a throwaway temp repo; the live tree is never mutated.
echo ""
echo "Running tests/workflow-coverage.test.sh (F000070/S000119 level:workflow gate + 6th-column parser + --list-orchestrators)..."
if bash "$REPO_ROOT/tests/workflow-coverage.test.sh" >/dev/null 2>&1; then
  ok "tests/workflow-coverage.test.sh: green-from-birth + forward-miss/reverse-orphan/enum-check/consumer-absent + 6th-column round-trip all pass"
else
  _wfc_rc=$?
  fail_test "tests/workflow-coverage.test.sh failed (rc=$_wfc_rc) — run \`bash tests/workflow-coverage.test.sh\` directly to see"
fi

echo "Running tests/skills-update-check.test.sh (F000081/WS3 checkout-independent git-ls-remote version-notification, hermetic — stubbed ls-remote, no network / no real ~/.claude)..."
if bash "$REPO_ROOT/tests/skills-update-check.test.sh" >/dev/null 2>&1; then
  ok "tests/skills-update-check.test.sh: banner-when-newer / silent-when-equal-or-older / fail-soft-when-unreachable-or-untagged / override / ssh-normalize / no-.git-gate all pass"
else
  _suc_rc=$?
  fail_test "tests/skills-update-check.test.sh failed (rc=$_suc_rc) — run \`bash tests/skills-update-check.test.sh\` directly to see"
fi

# F000082 / S000132 — the AGENTIC counterpart to skills-update-check.test.sh:
# portability's local-hook agentic proof (does an AGENT surface the upgrade nudge?).
# It is local-only + SKIPs cleanly (exit 0, no model spend) without CJ_E2E_LOCAL=1 +
# a claude login, so running it here NEVER touches a model in CI / a normal test.sh
# — it exercises only the SKIP path and provides the live `bash tests/...` invocation
# the Check-24 forward-coverage grep needs to prove the file is wired.
echo "Running tests/portability-version-agentic.test.sh (F000082 portability local-hook agentic proof; SKIPs clean without CJ_E2E_LOCAL=1 + a claude login — no model spend in CI)..."
if bash "$REPO_ROOT/tests/portability-version-agentic.test.sh" >/dev/null 2>&1; then
  ok "tests/portability-version-agentic.test.sh: SKIPs cleanly (exit 0) without the local gate (CI never spends a model); the live model path is a local /CJ_test_run --e2e run"
else
  _pva_rc=$?
  fail_test "tests/portability-version-agentic.test.sh did not exit 0 (rc=$_pva_rc) — it must SKIP cleanly without CJ_E2E_LOCAL=1; run \`bash tests/portability-version-agentic.test.sh\` directly to see"
fi

# T000057 — the hermetic detail-surfacing regression: proves run_preamble_via_claude
# exposes the exact cold-agent prompt (byte-identically, via a stubbed claude — no
# model), the agentic test emits the AGENTIC-DETAIL block past its SKIP gate, and
# scripts/test-run.sh folds it into the materialized report. Fully offline (stub +
# source greps); provides the live `bash tests/...` invocation the Check-24 forward
# grep needs to prove tests/portability-version-agentic-detail.test.sh is wired.
echo "Running tests/portability-version-agentic-detail.test.sh (T000057 cold-agent prompt+response surfacing; hermetic, no model)..."
if bash "$REPO_ROOT/tests/portability-version-agentic-detail.test.sh" >/dev/null 2>&1; then
  ok "tests/portability-version-agentic-detail.test.sh: the detailed prompt/response report plumbing is wired (prompt exposed byte-identically, block emitted past the SKIP gate, folded into the test-run report)"
else
  _pvad_rc=$?
  fail_test "tests/portability-version-agentic-detail.test.sh failed (rc=$_pvad_rc) — the T000057 detail-surfacing plumbing regressed; run \`bash tests/portability-version-agentic-detail.test.sh\` directly to see"
fi

# ─────────────────────────────────────────────────────────────────────────────
# F000026 / S000056 — scripts/cj-handoff-gate.sh test rows
# Tests 1-11 of the TEST-SPEC, executed against the deterministic gate helper.
# Each test crafts a minimal git-diff fixture (raw + numstat) and feeds it to
# scripts/cj-handoff-gate.sh via --diff-from-file / --numstat-from-file +
# --base, then asserts exit code / stdout markers / stderr halt markers.
# ─────────────────────────────────────────────────────────────────────────────

GATE_HELPER="$REPO_ROOT/scripts/cj-handoff-gate.sh"
CJGA_FIX_DIR=$(mktemp -d -t cjga-fix-XXXXX)
# Defect 3 fix: compose with the existing suite-level EXIT trap (line 177)
# instead of clobbering it. Without composition, the suite-level trap that
# restores README.md / skills-catalog.json / VERSION / CHANGELOG.md and cleans
# up zzz-test-scaffold is silently overwritten — the checkout is left dirty
# after the run. The trap-union pattern below preserves both behaviors.
_OLD_EXIT_TRAP=$(trap -p EXIT | sed -E "s/^trap -- '(.*)' EXIT$/\\1/")
if [ -n "$_OLD_EXIT_TRAP" ]; then
  # Single-quote the cleanup portion so $CJGA_FIX_DIR expands at signal time,
  # not at trap-definition time (shellcheck SC2064). The previous-trap text is
  # already a literal command string from `trap -p`, so it composes safely.
  trap "${_OLD_EXIT_TRAP}; "'rm -rf "$CJGA_FIX_DIR"' EXIT
else
  trap 'rm -rf "$CJGA_FIX_DIR"' EXIT
fi

_write_markers_green() {
  local f="$1"
  cat > "$f" <<EOF
PIPELINE_END_STATE=green
SMOKE=pass
E2E=pass
PHASE2_GATES=checked
EOF
}

_write_markers_red() {
  local f="$1" key="$2" val="$3"
  cat > "$f" <<EOF
PIPELINE_END_STATE=green
SMOKE=pass
E2E=pass
PHASE2_GATES=checked
EOF
  # Patch the specific marker
  if command -v gsed >/dev/null 2>&1; then
    gsed -i "s/^$key=.*/$key=$val/" "$f"
  else
    sed -i.bak "s/^$key=.*/$key=$val/" "$f" && rm -f "$f.bak"
  fi
}

# Helper to build a single-entry raw-mode diff. Format per `git diff --raw -z`:
#   :100644 100644 <sha_a> <sha_b> <STATUS>\t<PATH>\0
# Multiple entries are NUL-separated. We build a single line then convert
# the trailing tab+path to NUL when writing the fixture.
_raw_entry() {
  local mode_a="$1" mode_b="$2" status="$3" path="$4"
  # Use printf %b so the trailing \0 is written literally.
  printf ':%s %s 1111111 2222222 %s\t%s\0' "$mode_a" "$mode_b" "$status" "$path"
}

echo ""
echo "=== F000026: scripts/cj-handoff-gate.sh deterministic tests ==="

if [ ! -x "$GATE_HELPER" ]; then
  fail_test "scripts/cj-handoff-gate.sh missing or not executable"
else
  ok "scripts/cj-handoff-gate.sh present + executable"
fi

# Test 1 (S1): denylisted-path change → exit non-zero
echo ""
echo "Test 1 (S1): denylist hit on skills/CJ_personal-workflow/SKILL.md"
_RAW="$CJGA_FIX_DIR/t1.raw"
_NUM="$CJGA_FIX_DIR/t1.numstat"
_MKR="$CJGA_FIX_DIR/t1.markers"
_raw_entry 100644 100644 M "skills/CJ_personal-workflow/SKILL.md" > "$_RAW"
printf '3\t0\tskills/CJ_personal-workflow/SKILL.md\n' > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t1.err"; then
  fail_test "Test 1: gate should have halted on denylist hit, but exited 0"
else
  if grep -q '\[gate2-denylist\]' "$CJGA_FIX_DIR/t1.err"; then
    ok "Test 1: gate halted with [gate2-denylist] (correct)"
  else
    fail_test "Test 1: gate halted but missing [gate2-denylist] marker"
  fi
fi

# Test 2a (S2): >120 added lines → exit non-zero
echo ""
echo "Test 2a (S2): size cap — 121 added lines"
_RAW="$CJGA_FIX_DIR/t2a.raw"
_NUM="$CJGA_FIX_DIR/t2a.numstat"
_MKR="$CJGA_FIX_DIR/t2a.markers"
_raw_entry 100644 100644 M "docs/notes.md" > "$_RAW"
printf '121\t0\tdocs/notes.md\n' > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t2a.err"; then
  fail_test "Test 2a: gate should have halted on 121-line size cap, but exited 0"
else
  if grep -q '\[gate2-size-cap\]' "$CJGA_FIX_DIR/t2a.err"; then
    ok "Test 2a: gate halted with [gate2-size-cap] (correct)"
  else
    fail_test "Test 2a: gate halted but missing [gate2-size-cap] marker"
  fi
fi

# Test 2b (S2): >5 files → exit non-zero
echo ""
echo "Test 2b (S2): size cap — 6 files"
_RAW="$CJGA_FIX_DIR/t2b.raw"
_NUM="$CJGA_FIX_DIR/t2b.numstat"
_MKR="$CJGA_FIX_DIR/t2b.markers"
{
  _raw_entry 100644 100644 M "docs/a.md"
  _raw_entry 100644 100644 M "docs/b.md"
  _raw_entry 100644 100644 M "docs/c.md"
  _raw_entry 100644 100644 M "docs/d.md"
  _raw_entry 100644 100644 M "docs/e.md"
  _raw_entry 100644 100644 M "docs/f.md"
} > "$_RAW"
{
  printf '2\t0\tdocs/a.md\n'
  printf '2\t0\tdocs/b.md\n'
  printf '2\t0\tdocs/c.md\n'
  printf '2\t0\tdocs/d.md\n'
  printf '2\t0\tdocs/e.md\n'
  printf '2\t0\tdocs/f.md\n'
} > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t2b.err"; then
  fail_test "Test 2b: gate should have halted on 6-file size cap, but exited 0"
else
  if grep -q '\[gate2-size-cap\]' "$CJGA_FIX_DIR/t2b.err"; then
    ok "Test 2b: gate halted with [gate2-size-cap] (correct)"
  else
    fail_test "Test 2b: gate halted but missing [gate2-size-cap] marker"
  fi
fi

# Test 3 (S3): rename of denylisted file → exit non-zero (via --no-renames decomposition)
echo ""
echo "Test 3 (S3): rename of denylisted file (--no-renames surfaces as add+delete)"
_RAW="$CJGA_FIX_DIR/t3.raw"
_NUM="$CJGA_FIX_DIR/t3.numstat"
_MKR="$CJGA_FIX_DIR/t3.markers"
{
  _raw_entry 100644 000000 D "skills/CJ_personal-workflow/SKILL.md"
  _raw_entry 000000 100644 A "skills/foo.md"
} > "$_RAW"
{
  printf '0\t10\tskills/CJ_personal-workflow/SKILL.md\n'
  printf '10\t0\tskills/foo.md\n'
} > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t3.err"; then
  fail_test "Test 3: gate should have halted on rename-of-denylisted-file, but exited 0"
else
  if grep -q '\[gate2-denylist\]' "$CJGA_FIX_DIR/t3.err"; then
    ok "Test 3: rename surfaced as denylist hit via --no-renames decomposition (correct)"
  else
    fail_test "Test 3: gate halted but missing [gate2-denylist] marker"
  fi
fi

# Test 4 (S4): new symlink → exit non-zero
echo ""
echo "Test 4 (S4): new symlink (mode 120000)"
_RAW="$CJGA_FIX_DIR/t4.raw"
_NUM="$CJGA_FIX_DIR/t4.numstat"
_MKR="$CJGA_FIX_DIR/t4.markers"
_raw_entry 000000 120000 A "docs/link.md" > "$_RAW"
printf '1\t0\tdocs/link.md\n' > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t4.err"; then
  fail_test "Test 4: gate should have halted on new symlink, but exited 0"
else
  if grep -q '\[gate2-symlink\]' "$CJGA_FIX_DIR/t4.err"; then
    ok "Test 4: gate halted with [gate2-symlink] (correct)"
  else
    fail_test "Test 4: gate halted but missing [gate2-symlink] marker"
  fi
fi

# Test 5 (S5): test-surface change → exit non-zero
echo ""
echo "Test 5 (S5): test-surface weakening (tests/ change)"
_RAW="$CJGA_FIX_DIR/t5.raw"
_NUM="$CJGA_FIX_DIR/t5.numstat"
_MKR="$CJGA_FIX_DIR/t5.markers"
_raw_entry 100644 100644 M "tests/foo.test.sh" > "$_RAW"
printf '5\t2\ttests/foo.test.sh\n' > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t5.err"; then
  fail_test "Test 5: gate should have halted on tests/ touch, but exited 0"
else
  if grep -q '\[gate2-denylist\]' "$CJGA_FIX_DIR/t5.err"; then
    ok "Test 5: tests/ touch surfaced as denylist hit (correct)"
  else
    fail_test "Test 5: gate halted but missing [gate2-denylist] marker"
  fi
fi

# Test 6 (S6): frozen-base behavior — re-run with same fixture must yield identical
# stdout regardless of git-state. We exercise --base override + fixture path twice;
# the helper's counts depend solely on the fixture, so they MUST match.
echo ""
echo "Test 6 (S6): frozen-base regression — identical fixture, identical counts"
_RAW="$CJGA_FIX_DIR/t6.raw"
_NUM="$CJGA_FIX_DIR/t6.numstat"
_MKR="$CJGA_FIX_DIR/t6.markers"
_raw_entry 100644 100644 M "docs/notes.md" > "$_RAW"
printf '3\t0\tdocs/notes.md\n' > "$_NUM"
_write_markers_green "$_MKR"
_OUT_A=$("$GATE_HELPER" --base sha-A --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" 2>&1)
_RC_A=$?
_OUT_B=$("$GATE_HELPER" --base sha-B --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" 2>&1)
_RC_B=$?
# Counts must match (ignore the BASE= line which differs)
_COUNTS_A=$(echo "$_OUT_A" | grep -E '^(FILES|LINES|DENYLIST|PIPELINE_END_STATE|SMOKE|E2E|PHASE2_GATES|GATE_RESULT)=')
_COUNTS_B=$(echo "$_OUT_B" | grep -E '^(FILES|LINES|DENYLIST|PIPELINE_END_STATE|SMOKE|E2E|PHASE2_GATES|GATE_RESULT)=')
if [ "$_COUNTS_A" = "$_COUNTS_B" ] && [ "$_RC_A" = "$_RC_B" ]; then
  ok "Test 6: identical fixture yields identical gate decision (counts + exit code stable across --base override)"
else
  fail_test "Test 6: gate decision diverged across --base override (counts or rc differ)"
fi

# Test 7 (S7): QA predicate — fail each marker individually
echo ""
echo "Test 7 (S7): QA predicate (Phase-2 markers)"
_RAW="$CJGA_FIX_DIR/t7.raw"
_NUM="$CJGA_FIX_DIR/t7.numstat"
_raw_entry 100644 100644 M "docs/ok.md" > "$_RAW"
printf '3\t0\tdocs/ok.md\n' > "$_NUM"

for _key in PIPELINE_END_STATE SMOKE E2E PHASE2_GATES; do
  _MKR="$CJGA_FIX_DIR/t7.${_key}.markers"
  _write_markers_red "$_MKR" "$_key" "fail"
  if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t7.${_key}.err"; then
    fail_test "Test 7 ($_key=fail): gate should have halted, but exited 0"
  else
    if grep -q '\[gate2-qa-marker\]' "$CJGA_FIX_DIR/t7.${_key}.err"; then
      ok "Test 7 ($_key=fail): gate halted with [gate2-qa-marker] (correct)"
    else
      fail_test "Test 7 ($_key=fail): gate halted but missing [gate2-qa-marker] marker"
    fi
  fi
done


# Test 12: green-path positive — denylist clean, ≤5 files, ≤120 lines, markers green → exit 0
echo ""
echo "Test 12: green-path positive (gate exits 0 when all conditions hold)"
_RAW="$CJGA_FIX_DIR/t12.raw"
_NUM="$CJGA_FIX_DIR/t12.numstat"
_MKR="$CJGA_FIX_DIR/t12.markers"
_raw_entry 100644 100644 M "docs/small.md" > "$_RAW"
printf '5\t1\tdocs/small.md\n' > "$_NUM"
_write_markers_green "$_MKR"
if _OUT=$("$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" 2>&1); then
  if echo "$_OUT" | grep -q '^GATE_RESULT=auto-approved$'; then
    ok "Test 12: gate exited 0 with GATE_RESULT=auto-approved (green path works)"
  else
    fail_test "Test 12: gate exited 0 but GATE_RESULT missing/incorrect; got: $(echo "$_OUT" | grep '^GATE_RESULT=')"
  fi
else
  fail_test "Test 12: gate should have exited 0 on green-path fixture, but halted; output: $_OUT"
fi

# Test 13: Check 14 USAGE.md drift fires and is overridable
# F000033/S000066: prove that validate.sh Check 14 detects SKILL.md > USAGE.md
# drift (ERRORs with the documented override command), and that bumping the
# last-updated frontmatter field silences it. Cleanup via PRIOR_SHA reset.
#
# Clean-tree gate (F000033 QA-reverify): the test creates temp commits via
# `git commit -am` and resets with `git reset --hard`. On an uncommitted tree
# the `-am` would sweep unrelated work into the temp commit, and the reset
# would then discard it. Skip in that context with a code-presence check so
# Check 14's source still gets verified. The full test runs in CI and in any
# post-/ship invocation (clean tree).
echo ""
echo "Test 13: Check 14 USAGE.md drift fires and is overridable"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  if grep -q '^echo "=== Check 14:' scripts/validate.sh \
     && grep -q 'is stale' scripts/validate.sh \
     && grep -q 'last-updated' scripts/validate.sh; then
    ok "Test 13: SKIP (uncommitted working tree); Check 14 source present (=== Check 14:, is stale, last-updated)"
  else
    fail_test "Test 13: SKIP requested (uncommitted working tree) but Check 14 source missing one of: '=== Check 14:', 'is stale', 'last-updated'"
  fi
else
  PRIOR_SHA=$(git rev-parse HEAD)
  trap 'git reset --hard "$PRIOR_SHA" >/dev/null 2>&1 || true; rm -f skills/CJ_system-health/USAGE.md.bak skills/CJ_system-health/SKILL.md.bak' EXIT
  # (a) Advance CJ_system-health/SKILL.md's %ct via trailing newline + commit
  echo "" >> skills/CJ_system-health/SKILL.md
  git commit -am "TEST: temp SKILL.md edit" >/dev/null 2>&1
  # (b) Re-run validate.sh; assert non-zero exit AND drift ERROR in output
  if _T13_OUT=$(./scripts/validate.sh 2>&1); then
    fail_test "Test 13: validate.sh should have exited non-zero after SKILL.md drift, but exited 0"
  else
    if echo "$_T13_OUT" | grep -qF "ERROR: skills/CJ_system-health/USAGE.md is stale"; then
      ok "Test 13a: validate.sh exited non-zero with stale-USAGE.md ERROR (drift detected)"
    else
      fail_test "Test 13a: validate.sh exited non-zero but missing 'ERROR: skills/CJ_system-health/USAGE.md is stale' substring; output: $_T13_OUT"
    fi
  fi
  # (c) Apply the documented override — ISO-8601 second-resolution timestamp.
  # Date-only would be a no-op when USAGE.md already shows today's date (common
  # case immediately after a freshly-created USAGE.md gets a sibling SKILL.md
  # edit). The pre-commit hook accepts the override commit because Check 14 is
  # staged-aware: USAGE.md appears in `git diff --cached --name-only` and is
  # treated as current.
  sed -i.bak 's/^last-updated:.*/last-updated: "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"/' skills/CJ_system-health/USAGE.md && rm skills/CJ_system-health/USAGE.md.bak
  git commit -am "TEST: apply override" >/dev/null 2>&1
  # (d) Re-run validate.sh; assert exit 0 AND PASS line in output
  if _T13_OUT2=$(./scripts/validate.sh 2>&1); then
    if echo "$_T13_OUT2" | grep -qF "PASS: skills/CJ_system-health/USAGE.md is current"; then
      ok "Test 13b: validate.sh exited 0 with USAGE.md current PASS (override silences drift)"
    else
      fail_test "Test 13b: validate.sh exited 0 but missing 'PASS: skills/CJ_system-health/USAGE.md is current' substring"
    fi
  else
    fail_test "Test 13b: validate.sh should have exited 0 after override, but exited non-zero; output: $_T13_OUT2"
  fi
  # (e) Cleanup — restore worktree via PRIOR_SHA reset (trap handles this on EXIT too)
  git reset --hard "$PRIOR_SHA" >/dev/null 2>&1
  trap - EXIT
fi

# ---------- S000078: portable POSIX runtime (date + OS gate) — F000044 ----------
# Proves the macOS-only gate is widened to a POSIX allowlist and date math is
# portable, so /CJ_suggest + /CJ_improve-queue run on Linux (this CI) / WSL2 /
# Git Bash, not just Darwin. AC-4: exercise a check_darwin-gated path on the
# current OS (the prior `apply`-only coverage skipped the gate). Side-effecting
# audit runs in an isolated temp repo.
echo ""
echo "Checking S000078 portable POSIX runtime (gate allowlist + date_to_epoch)..."
_S078_SUGGEST="$REPO_ROOT/skills/CJ_suggest/scripts/suggest.sh"
_S078_IQ="$REPO_ROOT/skills/CJ_improve-queue/scripts/improve_queue.sh"
set +e
# (1) Structural: both scripts use the POSIX allowlist + define date_to_epoch, and
#     the old Darwin-only refuse is gone.
_s078_struct=1
for _s078_f in "$_S078_SUGGEST" "$_S078_IQ"; do
  grep -qF 'Darwin|Linux|MINGW' "$_s078_f" || _s078_struct=0
  grep -qF 'date_to_epoch()' "$_s078_f" || _s078_struct=0
  grep -qE '!= "Darwin"' "$_s078_f" && _s078_struct=0
done
if [ "$_s078_struct" -eq 1 ]; then
  ok "S000078: both skills use the POSIX OS allowlist + define date_to_epoch (old Darwin-only gate removed)"
else
  fail_test "S000078: a skill still has the Darwin-only gate or is missing date_to_epoch (gate-widening regressed)"
fi
# (2) Functional: portable date->epoch parses a known date on THIS OS.
_s078_de() { if date --version >/dev/null 2>&1; then date -d "$1" +%s 2>/dev/null; else date -j -f "$2" "$1" +%s 2>/dev/null; fi; }
_s078_e=$(_s078_de "2026-01-01" "%Y-%m-%d")
if [ -n "$_s078_e" ] && [ "$_s078_e" -gt 1700000000 ] 2>/dev/null; then
  ok "S000078: date_to_epoch parses 2026-01-01 to a sane epoch on $(uname -s)"
else
  fail_test "S000078: date_to_epoch failed on $(uname -s) (got '$_s078_e')"
fi
unset -f _s078_de
# (3) AC-1/AC-4: suggest ranks (read-only) on this OS without the gate refusal.
_s078_sug_err=$( cd "$REPO_ROOT" && bash "$_S078_SUGGEST" 2>&1 >/dev/null ); _s078_sug_rc=$?
if [ "$_s078_sug_rc" -eq 0 ] && ! printf '%s' "$_s078_sug_err" | grep -qiE 'requires macOS|supports macOS|unknown OS'; then
  ok "S000078: suggest.sh ranks on $(uname -s) without the OS refusal (AC-1/AC-4)"
else
  fail_test "S000078: suggest.sh refused/errored on $(uname -s) (rc=$_s078_sug_rc; err='$_s078_sug_err')"
fi
# (4) AC-2/AC-4: improve_queue audit hits the check_darwin gate without refusing.
#     Isolated temp repo so audit's draft-row writes never touch the real TODOS.md.
if [ -x "$_S078_IQ" ]; then
  _S078_TMP=$(mktemp -d -t s078-iq.XXXXXX)
  ( cd "$_S078_TMP" && git init -q && git config user.email t@t.local && git config user.name t \
      && printf '# TODOS\n\n- row\n' > TODOS.md && mkdir -p skills && git add -A && git commit -qm init ) >/dev/null 2>&1
  _s078_iq_err=$( cd "$_S078_TMP" && bash "$_S078_IQ" audit 2>&1 >/dev/null )
  if ! printf '%s' "$_s078_iq_err" | grep -qiE 'macOS-only skill|unknown OS'; then
    ok "S000078: improve_queue audit runs the check_darwin gate on $(uname -s) without refusal (AC-2/AC-4)"
  else
    fail_test "S000078: improve_queue audit refused on $(uname -s) (err='$_s078_iq_err')"
  fi
  rm -rf "$_S078_TMP" /tmp/cj-improve-queue-lock
fi
set -e

# ---------- T000038: registered-doc requirements audit is WIRED (not inert) ----------
# Two deterministic smoke checks proving the FULL producer->PR-body path is wired.
# The verdict CONTENT is agent-judged (non-deterministic); these guard the WIRING:
# the wrapper SKILL.md contains the producer step (§6a) AND the CJ_goal_feature
# pipeline contains the post-/ship surfacing step (§6b). Together they prevent
# shipping an inert feature (the second-adversarial-review requirement).
echo ""
echo "Checking T000038 registered-doc audit wiring (producer + surfacing)..."
_T38_PRODUCER="$REPO_ROOT/skills/CJ_document-release/SKILL.md"
_T38_SURFACE="$REPO_ROOT/skills/CJ_goal_feature/pipeline.md"
set +e
# (§6a) PRODUCER wired in the CJ_document-release wrapper SKILL.md: the jq
#       skill-enumeration selector AND the emit-block heading AND the scratch-file write.
_t38a=1
grep -qF 'select((.files | length) > 0)' "$_T38_PRODUCER" || _t38a=0
grep -qF '### Registered-doc requirements' "$_T38_PRODUCER" || _t38a=0
grep -qF '.cj-goal-feature/registered-doc-verdicts.md' "$_T38_PRODUCER" || _t38a=0
if [ "$_t38a" -eq 1 ]; then
  ok "T000038a: CJ_document-release/SKILL.md contains the producer step (jq selector + '### Registered-doc requirements' emit + scratch-file write)"
else
  fail_test "T000038a: CJ_document-release/SKILL.md missing a producer-wiring substring (jq 'select((.files | length) > 0)' / '### Registered-doc requirements' / '.cj-goal-feature/registered-doc-verdicts.md') — the audit producer is inert"
fi
# (§6b) SURFACING wired in CJ_goal_feature/pipeline.md: the Step 4.6 PR-body edit
#       (gh pr edit) AND the scratch-file read (registered-doc-verdicts.md).
_t38b=1
grep -qF 'gh pr edit' "$_T38_SURFACE" || _t38b=0
grep -qF 'registered-doc-verdicts.md' "$_T38_SURFACE" || _t38b=0
if [ "$_t38b" -eq 1 ]; then
  ok "T000038b: CJ_goal_feature/pipeline.md contains the Step 4.6 surfacing step ('gh pr edit' + 'registered-doc-verdicts.md' scratch read)"
else
  fail_test "T000038b: CJ_goal_feature/pipeline.md missing a surfacing-wiring substring ('gh pr edit' / 'registered-doc-verdicts.md') — verdicts never reach the PR body"
fi
set -e

# ---------- T000039: registered-doc verdict SURFACING wired into the other two cj_goal orchestrators ----------
# Job-2.1 parity: T000038 wired the post-/ship surfacing into CJ_goal_feature ONLY.
# These two deterministic smoke checks (mirroring T000038b) prove the surfacing is
# ALSO wired into CJ_goal_defect (Step 9.5) and CJ_goal_todo_fix (Step 5.6), so all
# three orchestrators put the verdict in the PR body. The scratch path is the LITERAL
# '.cj-goal-feature/registered-doc-verdicts.md' in all three (NOT verb-renamed — only
# that dir is gitignored); each check greps the literal 'registered-doc-verdicts.md'
# AND 'gh pr edit' to lock the wiring in (an inert mirror can't ship).
echo ""
echo "Checking T000039 registered-doc surfacing wiring (defect + todo_fix pipelines)..."
_T39_DEFECT="$REPO_ROOT/skills/CJ_goal_defect/pipeline.md"
_T39_TODO="$REPO_ROOT/skills/CJ_goal_todo_fix/pipeline.md"
set +e
# (§6a) SURFACING wired in CJ_goal_defect/pipeline.md (Step 9.5): the PR-body edit
#       (gh pr edit) AND the literal scratch-file read (registered-doc-verdicts.md).
_t39a=1
grep -qF 'gh pr edit' "$_T39_DEFECT" || _t39a=0
grep -qF 'registered-doc-verdicts.md' "$_T39_DEFECT" || _t39a=0
if [ "$_t39a" -eq 1 ]; then
  ok "T000039a: CJ_goal_defect/pipeline.md contains the Step 9.5 surfacing step ('gh pr edit' + 'registered-doc-verdicts.md' scratch read)"
else
  fail_test "T000039a: CJ_goal_defect/pipeline.md missing a surfacing-wiring substring ('gh pr edit' / 'registered-doc-verdicts.md') — defect verdicts never reach the PR body"
fi
# (§6b) SURFACING wired in CJ_goal_todo_fix/pipeline.md (Step 5.6): same two substrings.
_t39b=1
grep -qF 'gh pr edit' "$_T39_TODO" || _t39b=0
grep -qF 'registered-doc-verdicts.md' "$_T39_TODO" || _t39b=0
if [ "$_t39b" -eq 1 ]; then
  ok "T000039b: CJ_goal_todo_fix/pipeline.md contains the Step 5.6 surfacing step ('gh pr edit' + 'registered-doc-verdicts.md' scratch read)"
else
  fail_test "T000039b: CJ_goal_todo_fix/pipeline.md missing a surfacing-wiring substring ('gh pr edit' / 'registered-doc-verdicts.md') — todo_fix verdicts never reach the PR body"
fi
set -e

# ---------- D000031: CJ_goal_defect Step 7.4 emits a tracker-defect.md-compliant tracker ----------
# A minimal promoted tracker (frontmatter + ## Bug Report + ## Journal only) FAILS the
# `/CJ_personal-workflow check` boundary gate `/CJ_qa-work-item` runs at Step 8 (missing
# required frontmatter fields + ## Lifecycle / 3 phases / 11 checkboxes / sections), so
# every cj_goal_defect run halted at QA. This extracts the Step 7.4 TRK heredoc and
# asserts full tracker-defect.md compliance, AND that the Step 7.6 commit-before-QA step
# exists (the Phase-2 `Fix committed` gate + doc-sync clean-tree gate both need it).
echo ""
echo "Checking D000031 CJ_goal_defect promotes a compliant tracker (Step 7.4 + 7.6)..."
_D31_PIPE="$REPO_ROOT/skills/CJ_goal_defect/pipeline.md"
set +e
_D31_TRK=$(awk '/<<TRK$/{f=1;next} /^TRK$/{f=0} f' "$_D31_PIPE")
_d31=1; _d31_why=""
for _k in name type id status created updated repo branch blocked_by; do
  printf '%s\n' "$_D31_TRK" | grep -qE "^${_k}:" || { _d31=0; _d31_why="$_d31_why missing-fm:$_k"; }
done
printf '%s\n' "$_D31_TRK" | grep -qF '## Lifecycle' || { _d31=0; _d31_why="$_d31_why no-lifecycle"; }
for _p in 'Phase 1: Track' 'Phase 2: Implement' 'Phase 3: Ship'; do
  printf '%s\n' "$_D31_TRK" | grep -qF "### $_p" || { _d31=0; _d31_why="$_d31_why no:$_p"; }
done
_d31_cb=$(printf '%s\n' "$_D31_TRK" | awk '/^## Lifecycle/{f=1;next} f&&/^## /{f=0} f' | grep -cE '^- \[[ xX]\]')
[ "${_d31_cb:-0}" -ge 11 ] || { _d31=0; _d31_why="$_d31_why lifecycle-checkboxes=$_d31_cb<11"; }
for _s in 'Reproduction Steps' 'Todos' 'Log' 'PRs' 'Files' 'Insights' 'Journal'; do
  printf '%s\n' "$_D31_TRK" | grep -qF "## $_s" || { _d31=0; _d31_why="$_d31_why no-sec:$_s"; }
done
grep -qF '## Step 7.6: Commit the fix' "$_D31_PIPE" || { _d31=0; _d31_why="$_d31_why no-step7.6"; }
if [ "$_d31" -eq 1 ]; then
  ok "D000031: CJ_goal_defect Step 7.4 emits a tracker-defect.md-compliant tracker (9 frontmatter fields + 3 phases + ${_d31_cb} lifecycle checkboxes + all sections) and Step 7.6 commits before QA"
else
  fail_test "D000031: CJ_goal_defect promotion tracker not compliant / missing commit step —$_d31_why"
fi
set -e

# ---------- F000069 / S000115: the Check-15b Touches-block structural fixture is RETIRED ----------
# The standalone smoke check that asserted each docs/workflows/<name>.md carried
# the 4 anchored Touches bullets (the parallel of retired validate.sh Check 15b)
# is removed: the workflow surface is now GENERATED from spec/workflow-spec.md, so
# the Touches blocks are faithfully reproduced by the renderer (asserted by
# tests/workflow-spec-render.test.sh) and a stale/dropped block is caught by
# validate.sh Check 27 (regenerate→diff) — the new Check-27 fixture below proves
# that gate fires. The no-vanish guarantee (every CJ_goal_* has an entry) now
# lives in workflow-spec.sh --validate registry-completeness (the remove-an-entry
# drill in tests/workflow-spec-render.test.sh T6).

# ---------- F000047 / S000083: portability-audit engine integration fixture ----------
# THE PARALLEL test.sh EDIT every new validate.sh check needs (the systematically-
# forgotten step — F000032/F000034/F000035 all hit it; pre-flighted here). Check 18
# (scripts/validate.sh) runs the shared static-lint engine scripts/cj-portability-audit.sh;
# this block is its regression fixture. HERMETIC: builds a SYNTHETIC catalog + skill
# tree in a throwaway tmpdir and runs the engine via --catalog against it — it never
# touches the real skills-catalog.json. Asserts the load-bearing classifier behaviors
# (TEST-SPEC S2 + S8): a standalone skill EXECUTING a root helper -> FINDING; a
# DOCUMENTED-only mention -> NOT a finding; a bundled-own script -> OK; a
# portability_requires-adjudicated dep -> OK; a stale portability_requires entry -> note.
echo ""
echo "Integration test (F000047 / S000083): cj-portability-audit.sh engine fixture..."
_PA_ENGINE="$REPO_ROOT/scripts/cj-portability-audit.sh"
if [ ! -f "$_PA_ENGINE" ]; then
  fail_test "S000083: scripts/cj-portability-audit.sh missing (the portability-audit engine)"
else
  _PA_TMP=$(mktemp -d -t test-sh-portability-XXXXXX)
  # Synthetic repo: a scripts/ with a ROOT helper, plus 4 synthetic skills.
  mkdir -p "$_PA_TMP/scripts"
  printf '#!/usr/bin/env bash\necho hi\n' > "$_PA_TMP/scripts/zzz-root-helper.sh"
  chmod +x "$_PA_TMP/scripts/zzz-root-helper.sh"

  # Skill A: standalone, EXECUTES the root helper inside a ```bash fence -> FINDING.
  mkdir -p "$_PA_TMP/skills/zzz-exec-standalone"
  cat > "$_PA_TMP/skills/zzz-exec-standalone/SKILL.md" <<'PASK'
---
name: zzz-exec-standalone
description: "fixture — standalone skill that executes a root helper."
---
Run the helper:
```bash
bash "$REPO_ROOT/scripts/zzz-root-helper.sh"
```
PASK

  # Skill B: standalone, only DOCUMENTS the root helper in prose -> NOT a finding.
  mkdir -p "$_PA_TMP/skills/zzz-doc-standalone"
  cat > "$_PA_TMP/skills/zzz-doc-standalone/SKILL.md" <<'PASK'
---
name: zzz-doc-standalone
description: "fixture — standalone skill that only mentions a root helper in prose."
---
This skill is related to the scripts/zzz-root-helper.sh tooling but never runs it.
PASK

  # Skill C: standalone, references a BUNDLED-OWN script (under its own dir) -> OK.
  mkdir -p "$_PA_TMP/skills/zzz-bundled-standalone/scripts"
  printf '#!/usr/bin/env bash\necho own\n' > "$_PA_TMP/skills/zzz-bundled-standalone/scripts/own.sh"
  cat > "$_PA_TMP/skills/zzz-bundled-standalone/SKILL.md" <<'PASK'
---
name: zzz-bundled-standalone
description: "fixture — standalone skill that executes its OWN bundled script."
---
Run my own script:
```bash
bash "$HOME/.claude/skills/zzz-bundled-standalone/scripts/own.sh"
```
PASK

  # Skill D: standalone, EXECUTES the root helper BUT adjudicated via
  # portability_requires (+ one stale entry) -> OK with a stale note.
  mkdir -p "$_PA_TMP/skills/zzz-adjudicated-standalone"
  cat > "$_PA_TMP/skills/zzz-adjudicated-standalone/SKILL.md" <<'PASK'
---
name: zzz-adjudicated-standalone
description: "fixture — standalone skill whose root-helper dep is adjudicated."
---
Run the helper:
```bash
bash "$REPO_ROOT/scripts/zzz-root-helper.sh"
```
PASK

  # Skill E: standalone, bundles a .sh that contains a config filename as a
  # QUOTED STRING-LITERAL in seed data it WRITES (e.g. "CLAUDE.md" in a JSON
  # array) -> NOT a finding. Guards the is_exec precision fix (D000032): in a
  # .sh every token is "runnable", so before the fix the seed literal was
  # mis-read as an executed read of the workbench CLAUDE.md.
  mkdir -p "$_PA_TMP/skills/zzz-seed-standalone/scripts"
  cat > "$_PA_TMP/skills/zzz-seed-standalone/scripts/seed.sh" <<'PSEED'
#!/usr/bin/env bash
# Scaffold a generic config — these filenames are SEED DATA we WRITE, not reads.
cat <<JSON
{
  "whitelist_patterns": [
    "README.md",
    "CLAUDE.md"
  ]
}
JSON
PSEED
  cat > "$_PA_TMP/skills/zzz-seed-standalone/SKILL.md" <<'PASK'
---
name: zzz-seed-standalone
description: "fixture — standalone skill whose bundled engine writes config filenames as seed data."
---
Run my bundled engine:
```bash
bash "$HOME/.claude/skills/zzz-seed-standalone/scripts/seed.sh"
```
PASK

  cat > "$_PA_TMP/skills-catalog.json" <<'PCAT'
[
  {"name":"zzz-exec-standalone","version":"0.1.0","description":"x","source":"local","depends":{"skills":[],"tools":[]},"portability":"standalone","files":["skills/zzz-exec-standalone/SKILL.md"],"templates":[],"status":"experimental"},
  {"name":"zzz-doc-standalone","version":"0.1.0","description":"x","source":"local","depends":{"skills":[],"tools":[]},"portability":"standalone","files":["skills/zzz-doc-standalone/SKILL.md"],"templates":[],"status":"experimental"},
  {"name":"zzz-bundled-standalone","version":"0.1.0","description":"x","source":"local","depends":{"skills":[],"tools":[]},"portability":"standalone","files":["skills/zzz-bundled-standalone/SKILL.md"],"templates":[],"status":"experimental"},
  {"name":"zzz-adjudicated-standalone","version":"0.1.0","description":"x","source":"local","depends":{"skills":[],"tools":[]},"portability":"standalone","files":["skills/zzz-adjudicated-standalone/SKILL.md"],"templates":[],"portability_requires":["scripts/zzz-root-helper.sh","scripts/zzz-stale-no-longer-referenced.sh"],"status":"experimental"},
  {"name":"zzz-seed-standalone","version":"0.1.0","description":"x","source":"local","depends":{"skills":[],"tools":[]},"portability":"standalone","files":["skills/zzz-seed-standalone/SKILL.md","skills/zzz-seed-standalone/scripts/seed.sh"],"templates":[],"status":"experimental"}
]
PCAT

  # Run the engine against the synthetic catalog (raw — no adjudication).
  _PA_RAW=$(bash "$_PA_ENGINE" --catalog "$_PA_TMP/skills-catalog.json" --no-adjudication 2>&1)
  # Run again WITH adjudication (default mode honors portability_requires).
  _PA_ADJ=$(bash "$_PA_ENGINE" --catalog "$_PA_TMP/skills-catalog.json" 2>&1)

  # (a) standalone EXECUTING the root helper -> FINDING naming the dep.
  if printf '%s\n' "$_PA_RAW" | grep -qE 'zzz-exec-standalone.*findings.*zzz-root-helper\.sh'; then
    ok "S000083a: standalone skill executing a root helper yields a FINDING naming the dep"
  else
    fail_test "S000083a: expected a finding for zzz-exec-standalone -> scripts/zzz-root-helper.sh; got: $(printf '%s' "$_PA_RAW" | grep zzz-exec-standalone)"
  fi

  # (b) standalone only DOCUMENTING the helper -> NOT a finding (portable*).
  if printf '%s\n' "$_PA_RAW" | grep -E 'zzz-doc-standalone' | grep -qv 'findings'; then
    ok "S000083b: standalone skill only documenting a root helper is NOT a finding (EXECUTED-vs-documented precision)"
  else
    fail_test "S000083b: zzz-doc-standalone should be portable (documented-only), but got a finding: $(printf '%s' "$_PA_RAW" | grep zzz-doc-standalone)"
  fi

  # (c) bundled-own-script carve-out -> OK (no finding).
  if printf '%s\n' "$_PA_RAW" | grep -E 'zzz-bundled-standalone' | grep -qv 'findings'; then
    ok "S000083c: standalone skill executing its OWN bundled script is OK (bundled-own carve-out)"
  else
    fail_test "S000083c: zzz-bundled-standalone should be OK (own script), but got a finding: $(printf '%s' "$_PA_RAW" | grep zzz-bundled-standalone)"
  fi

  # (i) bundled .sh containing a config filename as a SEED-DATA string-literal ->
  # NOT a finding (is_exec precision; D000032). Without the fix, the quoted
  # "CLAUDE.md" inside the engine's seed array is mis-read as an executed read.
  if printf '%s\n' "$_PA_RAW" | grep -E 'zzz-seed-standalone' | grep -qv 'findings'; then
    ok "S000083i: bundled .sh writing a config filename as a quoted seed literal is NOT a finding (is_exec precision)"
  else
    fail_test "S000083i: zzz-seed-standalone should be OK (seed data, not an executed read), but got a finding: $(printf '%s' "$_PA_RAW" | grep zzz-seed-standalone)"
  fi

  # (d) portability_requires adjudication -> OK in default mode.
  if printf '%s\n' "$_PA_ADJ" | grep -E 'zzz-adjudicated-standalone' | grep -qv 'findings'; then
    ok "S000083d: a portability_requires-adjudicated dep is OK in default (adjudicated) mode"
  else
    fail_test "S000083d: zzz-adjudicated-standalone should be OK after adjudication, but got a finding: $(printf '%s' "$_PA_ADJ" | grep zzz-adjudicated-standalone)"
  fi

  # (e) the SAME skill IS a finding in --no-adjudication mode (proves adjudication is what flips it).
  if printf '%s\n' "$_PA_RAW" | grep -qE 'zzz-adjudicated-standalone.*findings'; then
    ok "S000083e: the adjudicated skill is a FINDING in --no-adjudication mode (adjudication is load-bearing)"
  else
    fail_test "S000083e: zzz-adjudicated-standalone should be a finding raw (pre-adjudication); got: $(printf '%s' "$_PA_RAW" | grep zzz-adjudicated-standalone)"
  fi

  # (f) stale portability_requires entry -> informational note, never a finding.
  if printf '%s\n' "$_PA_ADJ" | grep -qF "portability_requires entry 'scripts/zzz-stale-no-longer-referenced.sh' no longer referenced"; then
    ok "S000083f: a stale portability_requires entry surfaces as an informational note (not a finding)"
  else
    fail_test "S000083f: expected a stale-entry note for scripts/zzz-stale-no-longer-referenced.sh; adj output: $_PA_ADJ"
  fi

  rm -rf "$_PA_TMP"
fi

# (g) The portability check is WIRED into validate.sh (Check 18) — proves the
# parallel validate.sh edit exists and its output is visible (TEST-SPEC S2/S3:
# `bash scripts/test.sh ... | grep -q 'portability'`). Capture-then-grep (not a
# pipe in the `if`) so `set -e` + validate.sh's own exit code can't mask the
# match, and the captured output is inspectable on failure.
set +e
_S83G_OUT=$("$REPO_ROOT/scripts/validate.sh" 2>&1)
set -e
if printf '%s\n' "$_S83G_OUT" | grep -qiE 'Check 18: skill portability audit'; then
  ok "S000083g: validate.sh runs the portability audit as Check 18 (strict-by-default check wired)"
else
  fail_test "S000083g: validate.sh is missing the 'Check 18: skill portability audit' check (the parallel validate.sh edit)"
fi

# (g2) T000054: validate.sh Check 18 is STRICT-BY-DEFAULT — PORTABILITY_STRICT
# defaults to 1, so a portability finding ERRORs WITHOUT any env opt-in (the whole
# repo is the ratchet, not just the cj_goal gate). Structural assert: validate.sh
# audits the live (clean) catalog, so it cannot surface a finding from a fixture;
# this grep proves the flip landed and guards against a silent revert to ':-0'.
if grep -qE 'PORTABILITY_STRICT:-1' "$REPO_ROOT/scripts/validate.sh"; then
  ok "S000083g2 (T000054): validate.sh Check 18 defaults PORTABILITY_STRICT to 1 (strict-by-default hard-fail)"
else
  fail_test "S000083g2 (T000054): validate.sh Check 18 is not strict-by-default (expected \${PORTABILITY_STRICT:-1} in Check 18)"
fi

# (h) PORTABILITY_STRICT=1 flips the engine's exit code to non-zero when findings
# remain (the documented future hard-fail path). Use the synthetic raw-finding set.
_PA_TMP2=$(mktemp -d -t test-sh-portability2-XXXXXX)
mkdir -p "$_PA_TMP2/scripts" "$_PA_TMP2/skills/zzz-strict"
printf '#!/usr/bin/env bash\necho hi\n' > "$_PA_TMP2/scripts/zzz-root-helper.sh"
cat > "$_PA_TMP2/skills/zzz-strict/SKILL.md" <<'PASK'
---
name: zzz-strict
description: "fixture."
---
```bash
bash "$REPO_ROOT/scripts/zzz-root-helper.sh"
```
PASK
cat > "$_PA_TMP2/skills-catalog.json" <<'PCAT'
[{"name":"zzz-strict","version":"0.1.0","description":"x","source":"local","depends":{"skills":[],"tools":[]},"portability":"standalone","files":["skills/zzz-strict/SKILL.md"],"templates":[],"status":"experimental"}]
PCAT
if PORTABILITY_STRICT=1 bash "$_PA_ENGINE" --catalog "$_PA_TMP2/skills-catalog.json" >/dev/null 2>&1; then
  fail_test "S000083h: PORTABILITY_STRICT=1 should exit non-zero with an unresolved finding, but exited 0"
else
  ok "S000083h: PORTABILITY_STRICT=1 flips the engine exit code to non-zero on an unresolved finding (hard-fail path)"
fi
rm -rf "$_PA_TMP2"

# ---------- F000049 / S000085: shared-scripts self-containment ----------
# Verifies (1) skills-deploy deposits the shared scripts to a _cj-shared home,
# (2) the 3-tier preamble resolves a shared script from that deployed home with
# NO source clone present (the consumer-repo simulation — the D000030/D000032
# pattern), and (3) the 4 orchestrator-family skills are re-tiered local-only and
# the audit engine confirms it with zero findings (--no-adjudication, honest view).
echo ""
echo "Integration test (F000049 / S000085): shared-scripts self-containment..."
_S85_TMP=$(mktemp -d -t test-sh-s85-XXXXXX)

# (1) Deposit: a fully hermetic install (all targets redirected) must land the
# shared scripts/*.sh set (+ skills-update-check) in _cj-shared/scripts/.
SKILLS_DEPLOY_TARGET="$_S85_TMP/skills" \
SKILLS_DEPLOY_TEMPLATES_TARGET="$_S85_TMP/templates" \
SKILLS_DEPLOY_RULES_TARGET="$_S85_TMP/rules" \
SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$_S85_TMP/_cj-shared/scripts" \
SKILLS_DEPLOY_MANIFEST="$_S85_TMP/manifest.json" \
  bash "$REPO_ROOT/scripts/skills-deploy" install >/dev/null 2>&1 || true
if [ -x "$_S85_TMP/_cj-shared/scripts/cj-goal-common.sh" ] \
   && [ -x "$_S85_TMP/_cj-shared/scripts/doc-spec.sh" ] \
   && [ -x "$_S85_TMP/_cj-shared/scripts/skills-update-check" ]; then
  ok "S000085: skills-deploy deposits the shared scripts to _cj-shared/scripts/"
else
  fail_test "S000085: shared scripts not deposited to _cj-shared/scripts/"
fi
if [ "$(jq -r '.shared_scripts["cj-goal-common.sh"].source_checksum // empty' "$_S85_TMP/manifest.json" 2>/dev/null | wc -c | tr -d ' ')" -gt 1 ]; then
  ok "S000085: manifest tracks deposited shared scripts with SHA256 checksums"
else
  fail_test "S000085: manifest.shared_scripts not populated with checksums"
fi

# (2) Consumer-repo simulation: the 3-tier resolution idiom resolves
# cj-goal-common.sh from the deployed _cj-shared home with NO repo-local scripts
# AND NO .source (source clone) present — proving the runtime de-coupling.
_S85_DEP="$_S85_TMP/_cj-shared/scripts"
_S85_RESOLVED=$(
  _REPO_ROOT=""                      # not in the workbench source repo
  _S=""                              # no .source / no source clone reachable
  _SHARED="$_S85_DEP"
  _COMMON=""
  if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-goal-common.sh" ]; then _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh";
  elif [ -x "$_SHARED/cj-goal-common.sh" ]; then _COMMON="$_SHARED/cj-goal-common.sh";
  elif [ -n "$_S" ] && [ -x "$_S/scripts/cj-goal-common.sh" ]; then _COMMON="$_S/scripts/cj-goal-common.sh"; fi
  printf '%s' "$_COMMON"
)
if [ "$_S85_RESOLVED" = "$_S85_DEP/cj-goal-common.sh" ]; then
  ok "S000085: 3-tier preamble resolves cj-goal-common.sh from _cj-shared with no source clone"
else
  fail_test "S000085: no-source-clone resolution failed (got '$_S85_RESOLVED')"
fi

# (3) Catalog re-tier + audit confirmation (real catalog + real engine).
_S85_TIERS=$(jq -r '.[] | select(.name=="CJ_goal_feature" or .name=="CJ_goal_task" or .name=="CJ_goal_defect" or .name=="CJ_goal_todo_fix" or .name=="CJ_document-release") | .portability' "$CATALOG" 2>/dev/null | sort -u)
if [ "$_S85_TIERS" = "local-only" ]; then
  ok "S000085: the 4 orchestrator-family skills are re-tiered local-only in the catalog"
else
  fail_test "S000085: orchestrator-family skills not all local-only (got: $_S85_TIERS)"
fi
_S85_AUDIT=$(bash "$REPO_ROOT/scripts/cj-portability-audit.sh" --no-adjudication 2>&1)
if printf '%s\n' "$_S85_AUDIT" | grep -qE '^FINDINGS=0$' \
   && printf '%s\n' "$_S85_AUDIT" | grep -qE 'CJ_goal_feature[ ]*\|[ ]*local-only'; then
  ok "S000085: audit reports the re-tiered family local-only with zero findings (--no-adjudication)"
else
  fail_test "S000085: audit did not confirm the local-only re-tier with zero findings"
fi

rm -rf "$_S85_TMP"

# ---------- F000049 / S2 (S000086): single-bundle layout + install == clone ----------
# Verifies `skills-deploy install --bundle` ensures a managed git checkout and
# symlinks the flat /CJ_* skills INTO it (install == clone), AND that the default
# install (no --bundle) is untouched (still symlinks to the dev clone, no bundle marker).
echo ""
echo "Integration test (F000049 / S000086): bundle install == clone..."
_S86_TMP=$(mktemp -d -t test-sh-s86-XXXXXX)

# (1) --bundle: clone the repo as a managed bundle, delegate the install INTO it.
SKILLS_DEPLOY_BUNDLE_TARGET="$_S86_TMP/cj-workbench" \
SKILLS_DEPLOY_BUNDLE_SOURCE="$REPO_ROOT" \
SKILLS_DEPLOY_TARGET="$_S86_TMP/skills" \
SKILLS_DEPLOY_TEMPLATES_TARGET="$_S86_TMP/templates" \
SKILLS_DEPLOY_RULES_TARGET="$_S86_TMP/rules" \
SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$_S86_TMP/_cj-shared/scripts" \
SKILLS_DEPLOY_MANIFEST="$_S86_TMP/manifest.json" \
  bash "$REPO_ROOT/scripts/skills-deploy" install --bundle >/dev/null 2>&1 || true

if [ -d "$_S86_TMP/cj-workbench/.git" ]; then
  ok "S000086: --bundle ensures a managed git checkout (install == clone)"
else
  fail_test "S000086: --bundle did not create a git checkout at the bundle path"
fi

_S86_LINK=$(readlink "$_S86_TMP/skills/CJ_goal_feature/SKILL.md" 2>/dev/null || echo "")
if [ "$_S86_LINK" = "$_S86_TMP/cj-workbench/skills/CJ_goal_feature/SKILL.md" ]; then
  ok "S000086: flat /CJ_* skills symlink INTO the bundle checkout"
else
  fail_test "S000086: flat skill symlink does not point into the bundle (got '$_S86_LINK')"
fi

if [ "$(jq -r '.install_mode // empty' "$_S86_TMP/manifest.json" 2>/dev/null)" = "bundle" ] \
   && jq -e '.bundle_path | test("cj-workbench")' "$_S86_TMP/manifest.json" >/dev/null 2>&1 \
   && jq -e '.source | test("cj-workbench")' "$_S86_TMP/manifest.json" >/dev/null 2>&1; then
  ok "S000086: manifest records the install==clone receipt (install_mode=bundle, bundle_path, source=bundle)"
else
  fail_test "S000086: manifest not stamped with the install==clone receipt"
fi

# (2) Additive guarantee: a DEFAULT install (no --bundle) still symlinks to a
# dev-clone source and writes NO bundle marker — the legacy path is untouched.
_S86_TMP2=$(mktemp -d -t test-sh-s86b-XXXXXX)
SKILLS_DEPLOY_TARGET="$_S86_TMP2/skills" \
SKILLS_DEPLOY_TEMPLATES_TARGET="$_S86_TMP2/templates" \
SKILLS_DEPLOY_RULES_TARGET="$_S86_TMP2/rules" \
SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$_S86_TMP2/_cj-shared/scripts" \
SKILLS_DEPLOY_MANIFEST="$_S86_TMP2/manifest.json" \
  bash "$REPO_ROOT/scripts/skills-deploy" install >/dev/null 2>&1 || true
_S86_LINK2=$(readlink "$_S86_TMP2/skills/CJ_goal_feature/SKILL.md" 2>/dev/null || echo "")
_S86_MODE2=$(jq -r '.install_mode // "none"' "$_S86_TMP2/manifest.json" 2>/dev/null)
if printf '%s' "$_S86_LINK2" | grep -q '/skills/CJ_goal_feature/SKILL.md' \
   && ! printf '%s' "$_S86_LINK2" | grep -q 'cj-workbench' \
   && [ "$_S86_MODE2" != "bundle" ]; then
  ok "S000086: default install (no --bundle) untouched — symlinks to the dev clone, no bundle marker"
else
  fail_test "S000086: default install changed (link='$_S86_LINK2', install_mode='$_S86_MODE2')"
fi

rm -rf "$_S86_TMP" "$_S86_TMP2"

# ---------- F000049 / S3 (S000087): develop-in-place enablement ----------
# Verifies the bundle is set up so you can develop + ship FROM it: --bundle
# repoints the bundle's `origin` to the GitHub upstream (even when cloned from a
# local .source), and `skills-deploy bundle-status` reports the dev checkout's state.
echo ""
echo "Integration test (F000049 / S000087): develop-in-place (origin repoint + bundle-status)..."
_S87_TMP=$(mktemp -d -t test-sh-s87-XXXXXX)
_S87_UPSTREAM="https://github.com/jcl2018/claude-skills-templates.git"

SKILLS_DEPLOY_BUNDLE_TARGET="$_S87_TMP/cj-workbench" \
SKILLS_DEPLOY_BUNDLE_SOURCE="$REPO_ROOT" \
SKILLS_DEPLOY_BUNDLE_UPSTREAM="$_S87_UPSTREAM" \
SKILLS_DEPLOY_TARGET="$_S87_TMP/skills" \
SKILLS_DEPLOY_TEMPLATES_TARGET="$_S87_TMP/templates" \
SKILLS_DEPLOY_RULES_TARGET="$_S87_TMP/rules" \
SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$_S87_TMP/_cj-shared/scripts" \
SKILLS_DEPLOY_MANIFEST="$_S87_TMP/manifest.json" \
  bash "$REPO_ROOT/scripts/skills-deploy" install --bundle >/dev/null 2>&1 || true

# (1) origin repointed to the GitHub upstream (so branch/push/PR works FROM the bundle).
if [ "$(git -C "$_S87_TMP/cj-workbench" remote get-url origin 2>/dev/null)" = "$_S87_UPSTREAM" ]; then
  ok "S000087: --bundle repoints the bundle's origin to the GitHub upstream (develop-in-place: push/PR from the bundle)"
else
  fail_test "S000087: bundle origin not repointed to the upstream (got '$(git -C "$_S87_TMP/cj-workbench" remote get-url origin 2>/dev/null)')"
fi

# (2) bundle-status reports the install==clone checkout state.
_S87_STATUS=$(SKILLS_DEPLOY_MANIFEST="$_S87_TMP/manifest.json" bash "$REPO_ROOT/scripts/skills-deploy" bundle-status 2>&1)
if printf '%s\n' "$_S87_STATUS" | grep -qE '^install_mode: bundle' \
   && printf '%s\n' "$_S87_STATUS" | grep -qF "$_S87_TMP/cj-workbench" \
   && printf '%s\n' "$_S87_STATUS" | grep -qF "$_S87_UPSTREAM"; then
  ok "S000087: bundle-status reports install_mode=bundle + the bundle path + origin"
else
  fail_test "S000087: bundle-status did not report the expected develop-in-place state"
fi

# (3) bundle-status on a NON-bundle install reports dev-clone (no false bundle claim).
_S87_TMP2=$(mktemp -d -t test-sh-s87b-XXXXXX)
echo '{}' > "$_S87_TMP2/manifest.json"
_S87_STATUS2=$(SKILLS_DEPLOY_MANIFEST="$_S87_TMP2/manifest.json" bash "$REPO_ROOT/scripts/skills-deploy" bundle-status 2>&1)
if printf '%s\n' "$_S87_STATUS2" | grep -qE 'install_mode: dev-clone' \
   && printf '%s\n' "$_S87_STATUS2" | grep -qF 'Legacy dev-clone install'; then
  ok "S000087: bundle-status on a non-bundle install reports dev-clone (no false install==clone claim)"
else
  fail_test "S000087: bundle-status mis-reported a non-bundle install"
fi

rm -rf "$_S87_TMP" "$_S87_TMP2"

# ---------- F000049 / S4 (S000088): retire the separate-clone legacy ----------
# Verifies the in-place install==clone declaration + the runtime .source de-coupling:
# (1) the DEFAULT install (no --bundle) stamps install_mode=in-place + bundle_path==source;
# (2) bundle-status recognizes in-place; (3) NO skill's update-check snippet reaches
# $_S/.source; (4) the 4 orchestrators carry no skills-templates.json + .source
# co-occurrence; (5) each orchestrator audits FINDINGS=0 with no .source reach-back note.
echo ""
echo "Integration test (F000049 / S000088): in-place install==clone + .source de-coupling..."
_S88_TMP=$(mktemp -d -t test-sh-s88-XXXXXX)
SKILLS_DEPLOY_TARGET="$_S88_TMP/skills" \
SKILLS_DEPLOY_TEMPLATES_TARGET="$_S88_TMP/templates" \
SKILLS_DEPLOY_RULES_TARGET="$_S88_TMP/rules" \
SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$_S88_TMP/_cj-shared/scripts" \
SKILLS_DEPLOY_MANIFEST="$_S88_TMP/manifest.json" \
  bash "$REPO_ROOT/scripts/skills-deploy" install >/dev/null 2>&1 || true

# (1) AC-1: default install declares install==clone-in-place.
_S88_MODE=$(jq -r '.install_mode // "none"' "$_S88_TMP/manifest.json" 2>/dev/null)
_S88_SRC=$(jq -r '.source // empty' "$_S88_TMP/manifest.json" 2>/dev/null)
_S88_BP=$(jq -r '.bundle_path // empty' "$_S88_TMP/manifest.json" 2>/dev/null)
if [ "$_S88_MODE" = "in-place" ] && [ -n "$_S88_SRC" ] && [ "$_S88_BP" = "$_S88_SRC" ]; then
  ok "S000088: default install declares install==clone-in-place (install_mode=in-place, bundle_path==source)"
else
  fail_test "S000088: default install did not stamp the in-place receipt (mode='$_S88_MODE', bundle_path='$_S88_BP', source='$_S88_SRC')"
fi

# (2) AC-4: bundle-status recognizes the in-place mode (not a false dev-clone/bundle).
_S88_STATUS=$(SKILLS_DEPLOY_MANIFEST="$_S88_TMP/manifest.json" bash "$REPO_ROOT/scripts/skills-deploy" bundle-status 2>&1)
if printf '%s\n' "$_S88_STATUS" | grep -qE '^install_mode: in-place'; then
  ok "S000088: bundle-status recognizes install_mode=in-place"
else
  fail_test "S000088: bundle-status did not report in-place (got: $(printf '%s' "$_S88_STATUS" | head -1))"
fi
rm -rf "$_S88_TMP"

# (3) AC-3: the PASSIVE per-invocation update-check nudge no longer reads $_S/.source —
# its signature is the `[ -x "$_S/..." ]` guard, which Transformation A repointed to
# _cj-shared. The ACTIVE Update Nudge Handling upgrade flow (--should-prompt / --snooze /
# --skip / --prompted) legitimately reads manifest `source` == the in-place checkout to
# `git pull` + `skills-deploy install` it, so it is OUT of the "passive reach-back" AC
# scope — the same posture as post-land-sync and skills-update-check's own manifest read.
# shellcheck disable=SC2016  # the single-quoted $_S is a literal grep needle, not a shell expansion
# `{ grep || true; }` so a zero-match (the SUCCESS case) does not trip set -e + pipefail.
_S88_UC=$( { grep -rlF '[ -x "$_S/scripts/skills-update-check" ]' "$REPO_ROOT/skills/" 2>/dev/null || true; } | wc -l | tr -d ' ')
if [ "$_S88_UC" = "0" ]; then
  ok "S000088: the passive update-check nudge no longer reaches \$_S/.source (repointed to _cj-shared)"
else
  fail_test "S000088: $_S88_UC skill(s) still have the passive .source update-check nudge"
fi

# (4) AC-2: the 4 orchestrators carry no skills-templates.json + .source co-occurrence.
_S88_REACH=0
for _sk in CJ_goal_feature CJ_goal_task CJ_goal_defect CJ_goal_todo_fix CJ_document-release; do
  if grep -rnE 'skills-templates\.json' "$REPO_ROOT/skills/$_sk/" 2>/dev/null | grep -q '\.source'; then
    _S88_REACH=1
  fi
done
if [ "$_S88_REACH" = "0" ]; then
  ok "S000088: no orchestrator file reads manifest .source at runtime (preamble + pipeline + scripts de-coupled)"
else
  fail_test "S000088: an orchestrator still has a skills-templates.json + .source co-occurrence"
fi

# (5) AC-4: each orchestrator audits FINDINGS=0 with no .source reach-back note.
_S88_AUDIT_CLEAN=1
for _sk in CJ_goal_feature CJ_goal_task CJ_goal_defect CJ_goal_todo_fix CJ_document-release; do
  _S88_O=$(bash "$REPO_ROOT/scripts/cj-portability-audit.sh" --skill "$_sk" 2>&1)
  printf '%s\n' "$_S88_O" | grep -qE '^FINDINGS=0$' || _S88_AUDIT_CLEAN=0
  printf '%s\n' "$_S88_O" | grep -qiF 'reads manifest .source' && _S88_AUDIT_CLEAN=0
done
if [ "$_S88_AUDIT_CLEAN" = "1" ]; then
  ok "S000088: each orchestrator audits FINDINGS=0 with no '.source' reach-back note"
else
  fail_test "S000088: an orchestrator still has a .source note or non-zero findings"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
