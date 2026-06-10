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

echo "=== Running validate.sh ==="
if "$REPO_ROOT/scripts/validate.sh"; then
  ok "validate.sh passed"
else
  fail_test "validate.sh failed"
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
  # S4: Check 21 is wired into validate.sh and passes on the in-sync tree (advisory, exit 0).
  _S94_V=$("$REPO_ROOT/scripts/validate.sh" 2>&1 || true)
  printf '%s\n' "$_S94_V" | grep -q 'Check 21: cj_goal permission-policy drift' || fail_test "S000094: validate.sh missing Check 21"
  printf '%s\n' "$_S94_V" | grep -q 'PASS: permission policy + enforcement points in sync' || fail_test "S000094: Check 21 did not PASS on the in-sync tree"
  # Drift path (E1, isolated — no real-file mutation): a missing policy makes the
  # parser fail closed with the no-config halt (the "policy does not parse" drift).
  # if-then (not `A && B || C`) avoids SC2015, which CI's shellcheck flags as info.
  if PERMISSION_POLICY_PATH=/nonexistent-permission-policy.md bash "$_S94_PP" --validate >/dev/null 2>&1; then
    fail_test "S000094: parser did not fail on a missing policy (no-config drift undetected)"
  fi
  ok "F000053/S000094 permission-policy regression guards"
fi

# === F000054/S000096: gate-spec regression guards ===
# Exercise the gate-spec parser + the Check-22 drift wiring. Parallel test.sh
# fixture for the new validate.sh Check 22 (repo convention: a new validate.sh
# check ships with its test.sh assertions in the same PR). Mirrors the S000094
# permission-policy block above.
_S96_GS="$REPO_ROOT/scripts/gate-spec.sh"
# Resolve spec/-then-root (the family moved into spec/; root remains a fallback).
_S96_SPEC="$REPO_ROOT/spec/gate-spec.md"
[ -f "$_S96_SPEC" ] || _S96_SPEC="$REPO_ROOT/gate-spec.md"
if [ ! -x "$_S96_GS" ] || [ ! -f "$_S96_SPEC" ]; then
  fail_test "S000096: gate-spec.sh / gate-spec.md missing"
else
  # S1: the registry parses (schema_version + every gate's required keys + closed enums).
  bash "$_S96_GS" --validate >/dev/null 2>&1 || fail_test "S000096: gate-spec.sh --validate failed (registry does not parse)"
  [ "$(bash "$_S96_GS" --validate 2>/dev/null)" = "OK schema_version=1" ] || fail_test "S000096: --validate did not print 'OK schema_version=1'"
  # S2: the reader emits the right sets — the four layers + at least the known gates.
  for _l in local-hook ci pipeline-gate ratchet; do
    bash "$_S96_GS" --list-layers 2>/dev/null | grep -qx "$_l" || fail_test "S000096: --list-layers missing layer '$_l'"
  done
  for _g in isolation qa doc-sync portability ship; do
    bash "$_S96_GS" --list-gates 2>/dev/null | grep -qx "$_g" || fail_test "S000096: --list-gates missing gate '$_g'"
  done
  # S4: the universal markers resolve in ALL four modes' files; the per-mode
  # isolation markers resolve in their declared mode's file (either pipeline.md or SKILL.md).
  for _dir in CJ_goal_feature CJ_goal_defect CJ_goal_task CJ_goal_todo_fix; do
    for _m in '[portability-red]' '[doc-sync-red]'; do
      { grep -qF "$_m" "$REPO_ROOT/skills/$_dir/pipeline.md" 2>/dev/null || grep -qF "$_m" "$REPO_ROOT/skills/$_dir/SKILL.md" 2>/dev/null; } \
        || fail_test "S000096: universal marker $_m absent from skills/$_dir/{pipeline.md,SKILL.md}"
    done
  done
  { grep -qF '[feature-not-isolated]' "$REPO_ROOT/skills/CJ_goal_feature/pipeline.md" 2>/dev/null || grep -qF '[feature-not-isolated]' "$REPO_ROOT/skills/CJ_goal_feature/SKILL.md" 2>/dev/null; } \
    || fail_test "S000096: isolation marker [feature-not-isolated] absent from the feature mode's files"
  { grep -qF '[investigate-not-isolated]' "$REPO_ROOT/skills/CJ_goal_defect/pipeline.md" 2>/dev/null || grep -qF '[investigate-not-isolated]' "$REPO_ROOT/skills/CJ_goal_defect/SKILL.md" 2>/dev/null; } \
    || fail_test "S000096: isolation marker [investigate-not-isolated] absent from the defect mode's files"
  { grep -qF '[task-not-isolated]' "$REPO_ROOT/skills/CJ_goal_task/pipeline.md" 2>/dev/null || grep -qF '[task-not-isolated]' "$REPO_ROOT/skills/CJ_goal_task/SKILL.md" 2>/dev/null; } \
    || fail_test "S000096: isolation marker [task-not-isolated] absent from the task mode's files"
  # S3: Check 22 is wired into validate.sh, advisory, and PASSes on the in-sync tree (exit 0).
  _S96_V=$("$REPO_ROOT/scripts/validate.sh" 2>&1 || true)
  printf '%s\n' "$_S96_V" | grep -q 'Check 22: cj_goal gate-spec marker drift' || fail_test "S000096: validate.sh missing Check 22"
  printf '%s\n' "$_S96_V" | grep -q 'PASS: gate-spec registry + the four CJ_goal_\* pipelines in sync' || fail_test "S000096: Check 22 did not PASS on the in-sync tree"
  # Advisory posture: validate.sh exits 0 with Check 22 present (no hard-fail from the gate-spec check).
  "$REPO_ROOT/scripts/validate.sh" >/dev/null 2>&1 || fail_test "S000096: validate.sh exits non-zero with Check 22 active (check is not advisory)"
  # Drift path (isolated — no real-file mutation): a missing registry makes the
  # parser fail closed with the no-config halt. if-then (not A && B || C) avoids SC2015.
  if GATE_SPEC_PATH=/nonexistent-gate-spec.md bash "$_S96_GS" --validate >/dev/null 2>&1; then
    fail_test "S000096: parser did not fail on a missing registry (no-config drift undetected)"
  fi
  ok "F000054/S000096 gate-spec regression guards"
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

# === F000059: test-pipeline registry + coverage guards ===
# Parallel test.sh assertions for the new validate.sh Check 24 (coverage
# cross-check) + the Check 23 third-view extension (repo convention: a new
# validate.sh check ships with its test.sh assertions in the same PR — the
# standing parallel-edit blind spot, defused in lockstep). The four temp-dir
# drift drills (fake banner / broken anchor / hand-edited view / removed runner
# / hook-env GIT_DIR / unregistered file / self-satisfying source
# block) live in tests/test-pipeline-spec.test.sh, registered in the hand-wired
# runner section below; this block asserts the live-tree positives + the
# fail-closed no-config path. Mirrors the S000094/S000096 blocks above.
_S59_TP="$REPO_ROOT/scripts/test-pipeline.sh"
_S59_REG="$REPO_ROOT/spec/test-pipeline.md"
[ -f "$_S59_REG" ] || _S59_REG="$REPO_ROOT/test-pipeline.md"
if [ ! -x "$_S59_TP" ] || [ ! -f "$_S59_REG" ]; then
  fail_test "F000059: scripts/test-pipeline.sh / spec/test-pipeline.md missing"
else
  # S1: the registry parses.
  [ "$(bash "$_S59_TP" --validate 2>/dev/null)" = "OK schema_version=1" ] || fail_test "F000059: test-pipeline.sh --validate did not print 'OK schema_version=1'"
  # S2: the rendered view is work-item-ID-free (the rendered-field lint's
  # end-to-end proof) and the coverage cross-check is clean on the live tree.
  _S59_R=$(bash "$_S59_TP" --render 2>/dev/null)
  if printf '%s\n' "$_S59_R" | grep -qE '[FSTD][0-9]{6}'; then
    fail_test "F000059: --render output carries a work-item ID (rendered fields must be ID-free)"
  fi
  bash "$_S59_TP" --check-coverage >/dev/null 2>&1 || fail_test "F000059: test-pipeline.sh --check-coverage has findings on the live tree"
  # S4: Check 24 + the Check 23 third-view diff are wired into validate.sh and
  # PASS on the in-sync tree.
  _S59_V=$("$REPO_ROOT/scripts/validate.sh" 2>&1 || true)
  printf '%s\n' "$_S59_V" | grep -q 'Check 24: test-pipeline coverage cross-check' || fail_test "F000059: validate.sh missing Check 24"
  printf '%s\n' "$_S59_V" | grep -q 'PASS: test-pipeline coverage cross-check clean' || fail_test "F000059: Check 24 did not PASS on the live tree"
  printf '%s\n' "$_S59_V" | grep -q 'PASS: docs/test-pipeline.md matches the test-pipeline registry' || fail_test "F000059: Check 23 third-view diff did not PASS on the live tree"
  # Drift path (isolated — no real-file mutation): a missing registry makes the
  # parser fail closed with the no-config halt. if-then (not A && B || C) avoids SC2015.
  if TEST_PIPELINE_PATH=/nonexistent-test-pipeline.md bash "$_S59_TP" --validate >/dev/null 2>&1; then
    fail_test "F000059: parser did not fail on a missing registry (no-config drift undetected)"
  fi
  ok "F000059 test-pipeline registry + coverage guards"
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

# generate-doc-views.sh: runs + idempotent (temp-only — the EXIT trap does NOT
# restore docs/doc-*.md, so this mirror of validate.sh Check 23 must NEVER write
# into docs/; generate into two temp dirs and compare, like the README check above).
if [ -f "$REPO_ROOT/scripts/generate-doc-views.sh" ]; then
  _dv_t1=$(mktemp -d)
  _dv_t2=$(mktemp -d)
  if bash "$REPO_ROOT/scripts/generate-doc-views.sh" --output-dir "$_dv_t1" >/dev/null 2>&1 \
     && bash "$REPO_ROOT/scripts/generate-doc-views.sh" --output-dir "$_dv_t2" >/dev/null 2>&1; then
    ok "generate-doc-views.sh runs without crash"
    if [ -f "$_dv_t1/doc-general.md" ] && [ -f "$_dv_t1/doc-custom.md" ]; then
      ok "generate-doc-views.sh writes doc-general.md + doc-custom.md"
    else
      fail_test "generate-doc-views.sh did not write both view files"
    fi
    # F000059 third view: when the test-pipeline parser + registry are present
    # the generator must also write test-pipeline.md (the Check 23-extension
    # mirror, temp-only — never writes into docs/). diff -r below covers its
    # idempotency alongside the two doc-spec views.
    if [ -f "$REPO_ROOT/scripts/test-pipeline.sh" ] \
       && { [ -f "$REPO_ROOT/spec/test-pipeline.md" ] || [ -f "$REPO_ROOT/test-pipeline.md" ]; }; then
      if [ -f "$_dv_t1/test-pipeline.md" ]; then
        ok "generate-doc-views.sh writes the third view (test-pipeline.md) when the registry + parser are present"
      else
        fail_test "generate-doc-views.sh did not write test-pipeline.md despite the registry + parser being present"
      fi
    fi
    if diff -r "$_dv_t1" "$_dv_t2" >/dev/null 2>&1; then
      ok "generate-doc-views.sh is idempotent"
    else
      fail_test "generate-doc-views.sh produces different output on repeated runs"
    fi
  else
    fail_test "generate-doc-views.sh crashed"
  fi
  rm -rf "$_dv_t1" "$_dv_t2"
fi

# Integration test: catalog consistency after manual skill creation
echo ""
echo "Integration test: manual skill creation cycle..."

# Backup catalog for safe restore
cp "$CATALOG" "/tmp/catalog-backup-$$"
cp "$REPO_ROOT/README.md" "/tmp/readme-backup-$$"
[ -f "$REPO_ROOT/VERSION" ] && cp "$REPO_ROOT/VERSION" "/tmp/version-backup-$$"
[ -f "$REPO_ROOT/CHANGELOG.md" ] && cp "$REPO_ROOT/CHANGELOG.md" "/tmp/changelog-backup-$$"
trap 'cp "/tmp/catalog-backup-$$" "$CATALOG"; cp "/tmp/readme-backup-$$" "$REPO_ROOT/README.md"; [ -f "/tmp/version-backup-$$" ] && cp "/tmp/version-backup-$$" "$REPO_ROOT/VERSION"; [ -f "/tmp/changelog-backup-$$" ] && cp "/tmp/changelog-backup-$$" "$REPO_ROOT/CHANGELOG.md"; rm -rf "$SKILLS_DIR/zzz-test-scaffold" "$DOCS_DIR/zzz-test-scaffold" "/tmp/catalog-backup-$$" "/tmp/readme-backup-$$" "/tmp/version-backup-$$" "/tmp/changelog-backup-$$"' EXIT

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
touch "$REPO_ROOT/STRAY.md"
if _C17_OUT=$( cd "$REPO_ROOT" && ./scripts/validate.sh 2>&1 ); then
  fail_test "Check 17: validate.sh should have exited non-zero with a stray root doc (STRAY.md), but exited 0"
else
  if echo "$_C17_OUT" | grep -qF "  ERROR: root doc STRAY.md is not declared in the doc-spec.md registry"; then
    ok "Check 17: stray root doc STRAY.md triggers orphan ERROR + non-zero exit"
  else
    fail_test "Check 17: validate.sh exited non-zero but missing '  ERROR: root doc STRAY.md is not declared in the doc-spec.md registry' substring; output: $_C17_OUT"
  fi
fi
rm -f "$REPO_ROOT/STRAY.md"
if ( cd "$REPO_ROOT" && ./scripts/validate.sh >/dev/null 2>&1 ); then
  ok "Check 17: validate.sh exits 0 again after the stray root doc is removed"
else
  fail_test "Check 17: validate.sh should have exited 0 after STRAY.md removed, but exited non-zero"
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
touch "$REPO_ROOT/spec/STRAY.md"
if _C15A_SPEC_OUT=$( cd "$REPO_ROOT" && ./scripts/validate.sh 2>&1 ); then
  fail_test "Check 15a spec/: validate.sh should have exited non-zero with an undeclared spec/STRAY.md, but exited 0"
else
  if echo "$_C15A_SPEC_OUT" | grep -qF "  ERROR: spec/STRAY.md is in spec/ but not declared in the doc-spec.md registry"; then
    ok "Check 15a spec/: stray spec/STRAY.md triggers orphan ERROR + non-zero exit"
  else
    fail_test "Check 15a spec/: validate.sh exited non-zero but missing '  ERROR: spec/STRAY.md is in spec/ but not declared in the doc-spec.md registry' substring; output: $_C15A_SPEC_OUT"
  fi
fi
rm -f "$REPO_ROOT/spec/STRAY.md"
if ( cd "$REPO_ROOT" && ./scripts/validate.sh >/dev/null 2>&1 ); then
  ok "Check 15a spec/: validate.sh exits 0 again after the stray spec/ doc is removed"
else
  fail_test "Check 15a spec/: validate.sh should have exited 0 after spec/STRAY.md removed, but exited non-zero"
fi

# Step 3c (F000050 / TEST-SPEC S3): Check 19 no-work-item-refs-in-human-docs lint.
# THE PARALLEL test.sh EDIT the new validate.sh check needs — pre-flighted in the
# same step as the Check 19 add (the F000032/34/35 blind spot, defused). Plant a
# work-item ref (F000999) into a real human-doc declared by the doc-spec.md
# registry (docs/philosophy.md), assert validate.sh exits non-zero AND emits the
# literal Check 19 prefix, then restore the file and assert validate.sh exits 0
# again. The plant is done on a backup-and-restore basis so the checkout is never
# left dirty. Proves Check 19 actually FIRES, not just defaults green.
_C19_HUMANDOC="$REPO_ROOT/docs/philosophy.md"
if [ -f "$_C19_HUMANDOC" ]; then
  cp "$_C19_HUMANDOC" "/tmp/c19-humandoc-backup-$$"
  printf '\n<!-- planted ref for Check 19 negative test: F000999 -->\n' >> "$_C19_HUMANDOC"
  if _C19_OUT=$( cd "$REPO_ROOT" && ./scripts/validate.sh 2>&1 ); then
    fail_test "Check 19: validate.sh should have exited non-zero with a planted F000999 in a human-doc, but exited 0"
  else
    if echo "$_C19_OUT" | grep -qF "  ERROR: human-doc docs/philosophy.md contains work-item ref(s)"; then
      ok "Check 19: planted F000999 in docs/philosophy.md triggers no-work-item-ref ERROR + non-zero exit"
    else
      fail_test "Check 19: validate.sh exited non-zero but missing the Check-19 human-doc ERROR for docs/philosophy.md; output: $_C19_OUT"
    fi
  fi
  cp "/tmp/c19-humandoc-backup-$$" "$_C19_HUMANDOC"
  rm -f "/tmp/c19-humandoc-backup-$$"
  if ( cd "$REPO_ROOT" && ./scripts/validate.sh >/dev/null 2>&1 ); then
    ok "Check 19: validate.sh exits 0 again after the planted ref is removed"
  else
    fail_test "Check 19: validate.sh should have exited 0 after the planted F000999 was removed, but exited non-zero"
  fi
else
  fail_test "Check 19: docs/philosophy.md (a registry human-doc) not found for the negative test"
fi

# Step 3d (F000052 / TEST-SPEC S4): Check 20 front-table-required negative test.
# THE PARALLEL test.sh EDIT the new validate.sh check needs (the F000032/34/35
# blind spot — every prior new validate.sh check forgot its zzz-test-scaffold /
# plant-and-restore assertion; defused here in lockstep with the Check 20 add).
# docs/philosophy.md is flagged `front_table: required` in the doc-spec.md
# registry. Temporarily STRIP its leading summary table (every `^|` row before the
# first `^## ` heading), assert validate.sh exits non-zero AND emits the literal
# Check 20 `  ERROR:` prefix for docs/philosophy.md, then RESTORE the file exactly
# from a backup and assert validate.sh exits 0 again. Backup-and-restore so the
# checkout is never left dirty. Proves Check 20 actually FIRES, not just defaults
# green.
_C20_FTDOC="$REPO_ROOT/docs/philosophy.md"
if [ -f "$_C20_FTDOC" ]; then
  cp "$_C20_FTDOC" "/tmp/c20-ftdoc-backup-$$"
  # Strip leading table rows (lines starting with `|`) that appear BEFORE the
  # first `^## ` heading. awk -> temp -> mv (in-place edit, portable).
  awk 'BEGIN{past=0} /^## /{past=1} { if (!past && $0 ~ /^\|/) next; print }' \
    "/tmp/c20-ftdoc-backup-$$" > "/tmp/c20-ftdoc-stripped-$$" \
    && mv "/tmp/c20-ftdoc-stripped-$$" "$_C20_FTDOC"
  if _C20_OUT=$( cd "$REPO_ROOT" && ./scripts/validate.sh 2>&1 ); then
    fail_test "Check 20: validate.sh should have exited non-zero with docs/philosophy.md's leading table stripped, but exited 0"
  else
    if echo "$_C20_OUT" | grep -qF "  ERROR: front-table-required doc docs/philosophy.md does not open with a summary table"; then
      ok "Check 20: stripping docs/philosophy.md's leading table triggers front-table ERROR + non-zero exit"
    else
      fail_test "Check 20: validate.sh exited non-zero but missing the Check-20 ERROR for docs/philosophy.md; output: $_C20_OUT"
    fi
  fi
  cp "/tmp/c20-ftdoc-backup-$$" "$_C20_FTDOC"
  rm -f "/tmp/c20-ftdoc-backup-$$" "/tmp/c20-ftdoc-stripped-$$"
  if ( cd "$REPO_ROOT" && ./scripts/validate.sh >/dev/null 2>&1 ); then
    ok "Check 20: validate.sh exits 0 again after the leading table is restored"
  else
    fail_test "Check 20: validate.sh should have exited 0 after docs/philosophy.md's table was restored, but exited non-zero"
  fi
else
  fail_test "Check 20: docs/philosophy.md (a front_table-required doc) not found for the negative test"
fi

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

# Step 6b (F000051 / S000091): exercise the new `--phase portability-audit` gate
# end-to-end inside the integration cycle — the parallel-edit to the integration
# fixture for the new shared phase (the implement-subagent blind spot prior
# new-phase work hit). Runs the REAL repo engine against the live (clean) catalog
# (read-only; the audit mutates nothing) + asserts the --dry-run schema.
echo ""
echo "Integration test (F000051 / S000091): --phase portability-audit end-to-end (real engine, clean catalog)..."
# Clean catalog: PHASE_RESULT=ok, FINDINGS=0, a clean VERDICT_LINE, exit 0.
_PORT_OK=$(bash "$REPO_ROOT/scripts/cj-goal-common.sh" --phase portability-audit --mode feature 2>&1) && _PORT_OK_RC=0 || _PORT_OK_RC=$?
if [ "$_PORT_OK_RC" -eq 0 ] \
   && printf '%s\n' "$_PORT_OK" | grep -qE '^PHASE=portability-audit$' \
   && printf '%s\n' "$_PORT_OK" | grep -qE '^PHASE_RESULT=ok$' \
   && printf '%s\n' "$_PORT_OK" | grep -qE '^FINDINGS=0$' \
   && printf '%s\n' "$_PORT_OK" | grep -qE '^VERDICT_LINE=Portability: all [0-9]+ skills honestly declared'; then
  ok "Integration: --phase portability-audit on clean catalog → ok/exit0/FINDINGS=0 + clean VERDICT_LINE"
else
  fail_test "Integration: --phase portability-audit clean run wrong (rc=$_PORT_OK_RC); output: $_PORT_OK"
fi
# --dry-run: PHASE_RESULT=ok, empty FINDINGS=, runs the engine NOT at all.
_PORT_DRY=$(bash "$REPO_ROOT/scripts/cj-goal-common.sh" --phase portability-audit --mode feature --dry-run 2>&1)
if printf '%s\n' "$_PORT_DRY" | grep -qE '^PHASE_RESULT=ok$' \
   && printf '%s\n' "$_PORT_DRY" | grep -qE '^FINDINGS=$'; then
  ok "Integration: --phase portability-audit --dry-run → ok + empty FINDINGS= (engine not run)"
else
  fail_test "Integration: --phase portability-audit --dry-run wrong; output: $_PORT_DRY"
fi

# F000054: cj-goal-common.sh must accept --mode task (the new `task` verb). Smoke
# it through a mode-agnostic phase (portability-audit --dry-run) so the enum edit
# is guarded directly; an invalid mode would exit 1 with [common-usage-mode].
echo ""
echo "Integration test (F000054): cj-goal-common.sh accepts --mode task..."
_TASK_MODE=$(bash "$REPO_ROOT/scripts/cj-goal-common.sh" --phase portability-audit --mode task --dry-run 2>&1) && _TASK_MODE_RC=0 || _TASK_MODE_RC=$?
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

# D000022: setup-hooks.sh must not blind-clobber operator/tooling-owned git
# hooks. Since D000021 wired setup-hooks.sh into setup.sh's always-on update
# path, an unconditional `cat > "$HOOK_DIR/<hook>"` would silently destroy a
# customized pre-commit/post-merge (Husky, lefthook, local) with no backup, and
# a partial write would leave a truncated hook present. The fix installs via a
# sentinel-aware, atomic install_hook helper. Source-level static checks only —
# never fires a hook (same CI-safety rationale as the D000013 block above).
# shellcheck disable=SC2016 # literal $SENTINEL is intentional — grepping for the exact source string in setup-hooks.sh
if grep -qF '! grep -qF "$SENTINEL"' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh checks the workbench sentinel before overwriting an existing hook (D000022 guard)"
else
  fail_test "setup-hooks.sh missing sentinel ownership check — operator/tooling hooks can be blind-clobbered (D000022 guard)"
fi

# shellcheck disable=SC2016 # literal $HOOK_DIR/$tmp/$hook_path are intentional — grepping for the exact source strings in setup-hooks.sh
if grep -qF 'mktemp "$HOOK_DIR/.${hook_name}.XXXXXX"' "$REPO_ROOT/scripts/setup-hooks.sh" \
   && grep -qF 'mv "$tmp" "$hook_path"' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh stages hooks via mktemp and installs with an atomic mv (D000022 guard)"
else
  fail_test "setup-hooks.sh missing atomic mktemp-stage + mv install — a partial write can leave a truncated hook (D000022 guard)"
fi

# shellcheck disable=SC2016 # literal $hook_path/$backup are intentional — grepping for the exact source string in setup-hooks.sh
if grep -qF 'cp -p "$hook_path" "$backup"' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh backs up a non-workbench hook to <hook>.bak before clobbering (D000022 guard)"
else
  fail_test "setup-hooks.sh missing .bak backup of non-workbench hooks — custom hooks lost unrecoverably (D000022 guard)"
fi

# D000022 (pre-landing-review hardening): the two failure-mode invariants below
# have no other static anchor, so a regression that drops them would stay green
# while re-opening exactly the bug classes D000022 exists to kill.
#   (a) exit $rc — setup-hooks.sh must propagate a non-zero exit so setup.sh's
#       `|| echo WARN >&2` guard fires; dropping it re-introduces the masked
#       partial-failure class (the original D000022 / PR #150 finding).
#   (b) backup-fail abort — if the .bak copy fails, install_hook must refuse to
#       overwrite (the design's "one unacceptable outcome": losing an un-backed
#       custom hook). The ERROR string is emitted only on that abort path,
#       immediately before its `return 1`, so its presence proves the branch.
# shellcheck disable=SC2016 # literal $rc is intentional — grepping for the exact source string in setup-hooks.sh
if grep -qF 'exit $rc' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh propagates a non-zero exit on hook-install failure (D000022 guard)"
else
  fail_test "setup-hooks.sh missing 'exit \$rc' — a failed hook install is masked from setup.sh's WARN guard (D000022 guard)"
fi

if grep -qF 'could not be backed up — refusing to overwrite' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh aborts without clobbering when the .bak backup fails (D000022 guard)"
else
  fail_test "setup-hooks.sh missing backup-fail abort — an un-backed custom hook can be destroyed (D000022 guard)"
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
echo "Running scripts/test-deploy.sh end-to-end..."
if "$REPO_ROOT/scripts/test-deploy.sh" >/dev/null 2>&1; then
  ok "scripts/test-deploy.sh passed end-to-end (skills-deploy template-ownership tests)"
else
  _td_rc=$?
  fail_test "scripts/test-deploy.sh failed end-to-end (rc=$_td_rc) — run \`./scripts/test-deploy.sh\` directly to see failures"
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

# Regression test (F000035): all 3 cj_goal orchestrators (CJ_goal_feature,
# CJ_goal_defect, CJ_goal_todo_fix) have the Step 5.5 doc-sync subsection wired
# into pipeline.md AND both [doc-sync-red] / [doc-sync-non-doc-write] halt-taxonomy
# rows in SKILL.md, with correct row ordering (after qa, before ship).
echo ""
echo "Running tests/cj-goal-doc-sync-wiring.test.sh (F000035 3-way symmetric Step 5.5 wiring)..."
if bash "$REPO_ROOT/tests/cj-goal-doc-sync-wiring.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-doc-sync-wiring.test.sh: Step 5.5 + halt-taxonomy rows present in all 3 cj_goal orchestrators with correct ordering"
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

# Regression test (F000051 / S000091): scripts/cj-goal-common.sh
# `--phase portability-audit` (the pre-ship portability gate) — clean catalog →
# ok/exit 0; --dry-run → ok/exit 0 running nothing; dishonest-declaration fixture
# → findings/non-zero; engine-absent → skipped/exit 0 (fail-soft). Hermetic — the
# fixture + engine-absent cases run a COPY of cj-goal-common.sh against a
# controlled sibling engine + a HOME-overridden temp manifest; never mutates the
# real ~/.claude and the engine audit is read-only.
echo ""
echo "Running tests/cj-goal-common-portability.test.sh (F000051 --phase portability-audit gate)..."
if bash "$REPO_ROOT/tests/cj-goal-common-portability.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-common-portability.test.sh: clean→ok / dry-run→ok-runs-nothing / findings-fixture→findings-nonzero / engine-absent→skipped; fail-soft"
else
  _cgcp_rc=$?
  fail_test "tests/cj-goal-common-portability.test.sh failed (rc=$_cgcp_rc) — run \`bash tests/cj-goal-common-portability.test.sh\` directly to see"
fi

# Regression test (F000048 / S000084): scripts/cj-id-claim.sh — the atomic
# scaffold-time ID-claim engine that closes the scaffold-before-push race. Seven
# cases incl. the LOOPED concurrent race (25 rounds, distinct IDs), both reap
# modes (on-origin + TTL), prefix isolation, same-branch reuse, and cwd-independent
# shared-claim-root resolution from a linked worktree + a nested subdir. Hermetic:
# every claim happens inside a throwaway sandbox repo (live workbench .git untouched).
# MANDATORY — scripts/test.sh discovery is hand-wired, NOT glob-based; an
# unregistered tests/*.test.sh silently never runs.
echo ""
echo "Running tests/cj-id-claim.test.sh (F000048 atomic ID-claim engine: race + reap + reuse + worktree resolution)..."
if bash "$REPO_ROOT/tests/cj-id-claim.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-id-claim.test.sh: all 10 cases pass (incl. 25-round concurrent race with 0 duplicates + reuse floor/CAS/dry-run regressions)"
else
  _cic_rc=$?
  fail_test "tests/cj-id-claim.test.sh failed (rc=$_cic_rc) — run \`bash tests/cj-id-claim.test.sh\` directly to see"
fi

# Regression test (F000027 / S000057): the feature-path SHAPE harness —
# worktree entry (--caller feature), the shared helper's worktree/ship/telemetry
# phases under --mode feature, and the leaf-subagent dispatch targets on disk.
# Registered by the F000059 Step-0 triage: this file sat on disk UNREGISTERED
# (the live silent-skip instance the test-pipeline coverage cross-check now
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

# Regression test (F000059): the test-pipeline registry machinery — parser
# round-trip (validate / list / render), malformed-registry fixtures, the four
# temp-dir drift drills for the Check 24 coverage cross-check + the Check 23
# third-view extension, and the consumer-repo skip posture. Temp-dir isolated;
# never mutates the live tree. MANDATORY registration — this suite tests the
# very mechanism that catches unregistered tests, so it must not itself be an
# unregistered test.
echo ""
echo "Running tests/test-pipeline-spec.test.sh (F000059 registry parser + coverage drift drills)..."
if bash "$REPO_ROOT/tests/test-pipeline-spec.test.sh" >/dev/null 2>&1; then
  ok "tests/test-pipeline-spec.test.sh: parser round-trip + malformed fixtures + drift drills (a)-(h) + consumer-skip posture all pass"
else
  _tps_rc=$?
  fail_test "tests/test-pipeline-spec.test.sh failed (rc=$_tps_rc) — run \`bash tests/test-pipeline-spec.test.sh\` directly to see"
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

# ---------- T000040: doc/WORKFLOWS.md Touches blocks carry all 4 anchored bullets ----------
# STANDALONE hermetic smoke check (mirrors the F000045/S000081 + T000038/T000039
# blocks). The granular-enumeration rule (T000040) requires each CJ_goal_* section
# to enumerate ALL skills/steps/tools/shell via a 4-bullet Touches block — Skills
# dispatched / Steps · phases / Scripts · tools · shell / Docs touched. validate.sh
# Check 15b structurally enforces it on every CJ_goal_* catalog entry; this smoke
# check is a redundant standalone guard asserting the 3 REAL sections in
# doc/WORKFLOWS.md carry all 4 anchored bullets (`^- \*\*Skills` / `^- \*\*Steps` /
# `^- \*\*Scripts` / `^- \*\*Docs`). Patterns are LINE-ANCHORED on the bullet shape,
# NOT bare substrings (a bare `Steps` would false-match a chart node like `Step 5.5`).
# The zzz-test-scaffold fixture is non-CJ_goal_* and is NOT touched — Check 15b's
# loop is `select(.name | startswith("CJ_goal_"))`, so the sub-check never iterates it.
echo ""
echo "Checking docs/workflow.md Touches blocks (4 anchored bullets per CJ_goal_* section)..."
_T40_WF="$REPO_ROOT/docs/workflow.md"
set +e
if [ ! -f "$_T40_WF" ]; then
  fail_test "docs/workflow.md not found at $_T40_WF"
else
  for _t40_skill in CJ_goal_feature CJ_goal_task CJ_goal_defect CJ_goal_todo_fix; do
    # Extract the section body (between `### <name>` and the next `^### `), same
    # flag-based awk shape validate.sh Check 15b uses.
    _t40_section=$(awk -v skill="$_t40_skill" '
      $0 == "### " skill {flag=1; next}
      /^### / {flag=0}
      flag {print}
    ' "$_T40_WF")
    _t40_missing=""
    echo "$_t40_section" | grep -qE '^- \*\*Skills'  || _t40_missing="$_t40_missing Skills"
    echo "$_t40_section" | grep -qE '^- \*\*Steps'   || _t40_missing="$_t40_missing Steps"
    echo "$_t40_section" | grep -qE '^- \*\*Scripts' || _t40_missing="$_t40_missing Scripts"
    echo "$_t40_section" | grep -qE '^- \*\*Docs'    || _t40_missing="$_t40_missing Docs"
    if [ -z "$_t40_missing" ]; then
      ok "docs/workflow.md section '$_t40_skill' Touches block has all 4 anchored bullets (Skills/Steps/Scripts/Docs)"
    else
      fail_test "docs/workflow.md section '$_t40_skill' Touches block missing anchored bullet(s):$_t40_missing"
    fi
  done
fi
set -e
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

# (g) The advisory check is WIRED into validate.sh (Check 18) — proves the
# parallel validate.sh edit exists and its output is visible (TEST-SPEC S2/S3:
# `bash scripts/test.sh ... | grep -q 'portability'`). Capture-then-grep (not a
# pipe in the `if`) so `set -e` + validate.sh's own exit code can't mask the
# match, and the captured output is inspectable on failure.
set +e
_S83G_OUT=$("$REPO_ROOT/scripts/validate.sh" 2>&1)
set -e
if printf '%s\n' "$_S83G_OUT" | grep -qiE 'Check 18: skill portability audit'; then
  ok "S000083g: validate.sh runs the portability audit as Check 18 (advisory check wired)"
else
  fail_test "S000083g: validate.sh is missing the 'Check 18: skill portability audit' advisory check (the parallel validate.sh edit)"
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
