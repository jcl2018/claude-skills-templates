#!/usr/bin/env bash
# test-deploy.sh — Automated tests for skills-deploy.
# Uses temp directories to isolate from real ~/.claude/skills/ and ~/.claude/templates/.

set -euo pipefail

# Strip CRLF from jq output on Windows (jq.exe writes \r\n). No-op on Unix.
# Relies on `pipefail` (set above) so jq's exit status still propagates.
jq() { command jq "$@" | tr -d '\r'; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY="$REPO_ROOT/scripts/skills-deploy"
CATALOG="$REPO_ROOT/skills-catalog.json"
ERRORS=0
_CLEANUP_DIRS=()

# shellcheck disable=SC2154
trap 'for d in "${_CLEANUP_DIRS[@]+"${_CLEANUP_DIRS[@]}"}"; do rm -rf "$d" 2>/dev/null; done' EXIT

setup_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  export SKILLS_DEPLOY_TARGET="$tmp_dir"
  export SKILLS_DEPLOY_MANIFEST="$SKILLS_DEPLOY_TARGET/.skills-templates.json"
  export SKILLS_DEPLOY_TEMPLATES_TARGET="$SKILLS_DEPLOY_TARGET/templates"
  export SKILLS_DEPLOY_RULES_TARGET="$SKILLS_DEPLOY_TARGET/rules"
  mkdir -p "$SKILLS_DEPLOY_TEMPLATES_TARGET"
  _CLEANUP_DIRS+=("$SKILLS_DEPLOY_TARGET")
}

teardown_env() {
  rm -rf "$SKILLS_DEPLOY_TARGET" 2>/dev/null || true
}

ok() { echo "  OK: $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

# Count catalog entries that have skill files AND aren't deprecated.
# Default `skills-deploy install` skips deprecated skills (use --include-deprecated
# to install them); the test expectations must mirror that behavior.
SKILL_COUNT=$(jq '[.[] | select(.files | length > 0) | select((.status // "active") != "deprecated")] | length' "$CATALOG")

echo "=== Deploy script tests ==="
echo ""

# Test 1: Install all skills
echo "Test 1: Install all skills"
setup_env
"$DEPLOY" install >/dev/null 2>&1
count=$(find "$SKILLS_DEPLOY_TARGET" -mindepth 1 -maxdepth 1 -type d ! -path "$SKILLS_DEPLOY_TEMPLATES_TARGET" ! -path "$SKILLS_DEPLOY_RULES_TARGET" 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -eq "$SKILL_COUNT" ]; then
  ok "Installed $SKILL_COUNT skill directories"
else
  fail_test "Expected $SKILL_COUNT skills, got $count"
fi
teardown_env

# Test 2: Multi-file skill gets all .md files
echo "Test 2: Multi-file skill (CJ_personal-workflow)"
setup_env
"$DEPLOY" install CJ_personal-workflow >/dev/null 2>&1
md_count=$(find "$SKILLS_DEPLOY_TARGET/CJ_personal-workflow" -name "*.md" -type l 2>/dev/null | wc -l | tr -d ' ')
if [ "$md_count" -ge 3 ]; then
  ok "CJ_personal-workflow has $md_count .md symlinks"
else
  fail_test "Expected 3+ .md symlinks, got $md_count"
fi
teardown_env

# Test 3: Templates-only catalog entry (no SKILL.md, just templates)
echo "Test 3: Templates-only catalog entry"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
tpl_count=$(jq -r '.[] | select(.name == "templates") | .templates | length' "$CATALOG")
actual_count=$(find "$SKILLS_DEPLOY_TEMPLATES_TARGET" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$actual_count" -eq "$tpl_count" ]; then
  ok "Templates entry deployed $tpl_count templates"
else
  fail_test "Expected $tpl_count templates, got $actual_count"
fi
teardown_env

# Test 4: Idempotent install
echo "Test 4: Idempotent install"
setup_env
"$DEPLOY" install >/dev/null 2>&1
"$DEPLOY" install >/dev/null 2>&1
count=$(find "$SKILLS_DEPLOY_TARGET" -mindepth 1 -maxdepth 1 -type d ! -path "$SKILLS_DEPLOY_TEMPLATES_TARGET" ! -path "$SKILLS_DEPLOY_RULES_TARGET" 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -eq "$SKILL_COUNT" ]; then
  ok "Second install still has $SKILL_COUNT skills"
else
  fail_test "Expected $SKILL_COUNT skills after re-install, got $count"
fi
teardown_env

# Test 5: Remove requires args
echo "Test 5: Remove requires args"
setup_env
"$DEPLOY" install >/dev/null 2>&1
if "$DEPLOY" remove 2>/dev/null; then
  fail_test "remove with no args should fail"
else
  ok "remove with no args fails"
fi
teardown_env

# Test 6: Remove specific skill
echo "Test 6: Remove specific skill"
setup_env
"$DEPLOY" install >/dev/null 2>&1
"$DEPLOY" remove CJ_system-health --force >/dev/null 2>&1
if [ ! -d "$SKILLS_DEPLOY_TARGET/CJ_system-health" ]; then
  ok "CJ_system-health removed"
else
  fail_test "CJ_system-health still exists"
fi
teardown_env

# Test 7: Remove --all
echo "Test 7: Remove --all"
setup_env
"$DEPLOY" install >/dev/null 2>&1
"$DEPLOY" remove --all --force >/dev/null 2>&1
# Only templates/ dir should remain (empty)
skill_count=$(find "$SKILLS_DEPLOY_TARGET" -mindepth 1 -maxdepth 1 -type d -not -name "templates" -not -name "rules" 2>/dev/null | wc -l | tr -d ' ')
if [ "$skill_count" -eq 0 ]; then
  ok "All skills removed"
else
  fail_test "Expected 0 skill dirs, got $skill_count"
fi
if [ ! -f "$SKILLS_DEPLOY_MANIFEST" ]; then
  ok "Manifest cleaned up"
else
  fail_test "Manifest still exists"
fi
teardown_env

# Test 8: Doctor on healthy install
# F000036: relaxed the assertion from `Health: OK` to `Health: 0 errors`. Warnings
# are not errors. A new skill in catalog but not yet at main_toplevel surfaces a
# legitimate transient WARN ("source directory missing in repo") that auto-resolves
# on merge — see CLAUDE.md "Worktree skills-deploy" notes and T000025. Doctor's
# error count is the right signal for "healthy install."
echo "Test 8: Doctor on healthy install"
setup_env
"$DEPLOY" install >/dev/null 2>&1
output=$("$DEPLOY" doctor 2>&1)
if echo "$output" | grep -qE "Health: (OK|0 errors)"; then
  ok "Doctor reports healthy (0 errors)"
else
  fail_test "Doctor did not report healthy: $output"
fi
teardown_env

# Test 8b: Worktree VERSION split must NOT produce a spurious drift WARN.
# Regression for T000025: it moved manifest `source` to the main repo toplevel
# but left `col_ver` reading from `$REPO_ROOT/VERSION` (the ephemeral worktree).
# When the worktree's VERSION leads the stale main checkout (the normal state
# during worktree-based dev), doctor compared installed_cv (worktree VERSION at
# install) against current_cv (main VERSION now) — two different files — and
# emitted "installed != current", failing Test 8. Fixture: a real main repo
# with a linked worktree whose VERSION diverges; install from the worktree must
# record collection_version from the main toplevel (= manifest `source`).
echo "Test 8b: Worktree VERSION split — no spurious drift WARN (T000025 regression)"
setup_env
wt_main=$(mktemp -d)
_CLEANUP_DIRS+=("$wt_main")
git -c init.defaultBranch=main init --quiet "$wt_main"
mkdir -p "$wt_main/scripts"
cp "$REPO_ROOT/scripts/skills-deploy" "$wt_main/scripts/skills-deploy"
# Templates-only entry (empty files[]) — gives `install` one catalog entry to
# process so it reaches the manifest write, without needing skill files on disk.
# An empty `[]` catalog would abort do_install (set -u + empty-array iteration).
echo '[{"name":"_fixture","files":[],"templates":[]}]' > "$wt_main/skills-catalog.json"
printf '4.6.7' > "$wt_main/VERSION"
git -C "$wt_main" add -A
git -C "$wt_main" -c user.name=test -c user.email=t@e.st commit --quiet -m "main 4.6.7"
wt_link="$wt_main/.claude/worktrees/wt-test"
git -C "$wt_main" worktree add --quiet -b wt-test "$wt_link" >/dev/null 2>&1
printf '4.6.13' > "$wt_link/VERSION"
"$wt_link/scripts/skills-deploy" install >/dev/null 2>&1
recorded_cv=$(jq -r '.collection_version' "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null || echo MISSING)
recorded_src=$(jq -r '.source' "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null || echo MISSING)
src_ver=$(tr -d '[:space:]' < "$recorded_src/VERSION" 2>/dev/null || echo MISSING)
doctor_out=$("$wt_link/scripts/skills-deploy" doctor 2>&1)
git -C "$wt_main" worktree remove --force "$wt_link" >/dev/null 2>&1 || true
if [ "$recorded_cv" = "$src_ver" ] && [ "$recorded_cv" != "MISSING" ] && echo "$doctor_out" | grep -q "Health: OK"; then
  ok "collection_version ($recorded_cv) matches source VERSION; doctor healthy"
else
  fail_test "spurious drift: recorded_cv=$recorded_cv source=$recorded_src src_ver=$src_ver doctor=[$(echo "$doctor_out" | grep -E 'Collection version|Health:' | tr '\n' '|')]"
fi
teardown_env

# Test 9: Doctor detects broken symlink
echo "Test 9: Doctor detects broken symlink"
setup_env
"$DEPLOY" install CJ_system-health >/dev/null 2>&1
rm -f "$SKILLS_DEPLOY_TARGET/CJ_system-health/SKILL.md"
ln -s /nonexistent/path "$SKILLS_DEPLOY_TARGET/CJ_system-health/SKILL.md"
output=$("$DEPLOY" doctor 2>&1)
if echo "$output" | grep -q "broken symlink"; then
  ok "Doctor detects broken symlink"
else
  fail_test "Doctor missed broken symlink"
fi
teardown_env

# Test 10: Non-existent skill name
echo "Test 10: Non-existent skill name"
setup_env
output=$("$DEPLOY" install nonexistent-skill 2>&1)
if echo "$output" | grep -q "SKIP"; then
  ok "Non-existent skill skipped"
else
  fail_test "Non-existent skill not handled"
fi
teardown_env

# Test 11: Manifest is valid JSON
echo "Test 11: Manifest is valid JSON"
setup_env
"$DEPLOY" install >/dev/null 2>&1
if jq empty "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null; then
  ok "Manifest is valid JSON"
else
  fail_test "Manifest is invalid JSON"
fi
teardown_env

# Test 12: Relink repairs broken symlink
echo "Test 12: Relink repairs broken symlink"
setup_env
"$DEPLOY" install CJ_system-health >/dev/null 2>&1
rm -f "$SKILLS_DEPLOY_TARGET/CJ_system-health/SKILL.md"
"$DEPLOY" relink >/dev/null 2>&1
if [ -L "$SKILLS_DEPLOY_TARGET/CJ_system-health/SKILL.md" ] && [ -e "$SKILLS_DEPLOY_TARGET/CJ_system-health/SKILL.md" ]; then
  ok "Relink restored broken symlink"
else
  fail_test "Relink did not restore symlink"
fi
teardown_env

### ============================================================
### skills-update-check tests (F000009)
### ============================================================

UPDATE_CHECK="$REPO_ROOT/scripts/skills-update-check"

# Per-test setup: temp manifest + cache + marker paths.
setup_update_env() {
  local tmp
  tmp=$(mktemp -d)
  export SKILLS_TEMPLATES_MANIFEST="$tmp/manifest.json"
  export SKILLS_TEMPLATES_CACHE="$tmp/cache.json"
  export SKILLS_TEMPLATES_MARKER="$tmp/just-upgraded"
  _CLEANUP_DIRS+=("$tmp")
  echo "$tmp"
}

teardown_update_env() {
  unset SKILLS_TEMPLATES_MANIFEST SKILLS_TEMPLATES_CACHE SKILLS_TEMPLATES_MARKER
}

# Build a fixture: a temp "clone" with VERSION + .git + a remote that has a newer VERSION.
make_fake_clone() {
  local local_ver="$1" remote_ver="$2"
  local origin_dir local_dir
  origin_dir=$(mktemp -d)
  local_dir=$(mktemp -d)
  _CLEANUP_DIRS+=("$origin_dir" "$local_dir")

  git -c init.defaultBranch=main init --quiet "$origin_dir"
  printf '%s' "$remote_ver" > "$origin_dir/VERSION"
  git -C "$origin_dir" add VERSION
  git -C "$origin_dir" -c user.name=test -c user.email=t@e.st commit --quiet -m "init $remote_ver"

  git clone --quiet "$origin_dir" "$local_dir"
  printf '%s' "$local_ver" > "$local_dir/VERSION"
  git -C "$local_dir" -c user.name=test -c user.email=t@e.st commit --quiet -am "local $local_ver" || true
  git -C "$local_dir" reset --hard origin/main --quiet
  printf '%s' "$local_ver" > "$local_dir/VERSION"

  echo "$local_dir"
}

write_manifest() {
  local clone="$1" cv="$2"
  printf '{"source":"%s","collection_version":"%s","skills":{},"templates":{}}\n' "$clone" "$cv" > "$SKILLS_TEMPLATES_MANIFEST"
}

# --- Subcommand tests ---

echo "Test U1: Default exits silent when no manifest"
setup_update_env >/dev/null
out=$("$UPDATE_CHECK" 2>&1)
if [ -z "$out" ]; then
  ok "Silent exit (no manifest)"
else
  fail_test "Expected silent, got: $out"
fi
teardown_update_env

echo "Test U2: --help exits 0 with usage text"
setup_update_env >/dev/null
out=$("$UPDATE_CHECK" --help 2>&1)
if echo "$out" | grep -q "skills-update-check"; then
  ok "Help text emitted"
else
  fail_test "Help text missing"
fi
teardown_update_env

echo "Test U3: --snooze writes snooze_until to cache"
setup_update_env >/dev/null
"$UPDATE_CHECK" --snooze 2 2>&1
if [ -f "$SKILLS_TEMPLATES_CACHE" ] && jq -e '.snooze_until' "$SKILLS_TEMPLATES_CACHE" >/dev/null 2>&1; then
  ok "Cache has snooze_until"
else
  fail_test "Cache missing snooze_until"
fi
teardown_update_env

echo "Test U4: --snooze defaults to 24h when no arg"
setup_update_env >/dev/null
now=$(date +%s)
"$UPDATE_CHECK" --snooze 2>&1
until_ts=$(jq -r '.snooze_until' "$SKILLS_TEMPLATES_CACHE")
diff_hours=$(( (until_ts - now) / 3600 ))
if [ "$diff_hours" -ge 23 ] && [ "$diff_hours" -le 25 ]; then
  ok "Default snooze ~24h"
else
  fail_test "Expected ~24h snooze, got ${diff_hours}h"
fi
teardown_update_env

echo "Test U5: --skip writes skip_version"
setup_update_env >/dev/null
"$UPDATE_CHECK" --skip 1.6.0 2>&1
if [ "$(jq -r '.skip_version' "$SKILLS_TEMPLATES_CACHE")" = "1.6.0" ]; then
  ok "skip_version written"
else
  fail_test "skip_version missing or wrong"
fi
teardown_update_env

echo "Test U6: --skip rejects non-semver"
setup_update_env >/dev/null
if "$UPDATE_CHECK" --skip "not-a-version" 2>/dev/null; then
  fail_test "--skip should reject non-semver"
else
  ok "--skip rejects non-semver input"
fi
teardown_update_env

echo "Test U7: --skip rejects missing value"
setup_update_env >/dev/null
if "$UPDATE_CHECK" --skip 2>/dev/null; then
  fail_test "--skip should reject empty"
else
  ok "--skip rejects empty value"
fi
teardown_update_env

echo "Test U8: --prompted writes prompted_session and prompted_at"
setup_update_env >/dev/null
"$UPDATE_CHECK" --prompted "session-abc" 2>&1
ps=$(jq -r '.prompted_session' "$SKILLS_TEMPLATES_CACHE")
pa=$(jq -r '.prompted_at' "$SKILLS_TEMPLATES_CACHE")
if [ "$ps" = "session-abc" ] && [ -n "$pa" ] && [ "$pa" != "null" ]; then
  ok "prompted_session + prompted_at written"
else
  fail_test "prompted state not written correctly (session=$ps, at=$pa)"
fi
teardown_update_env

echo "Test U9: --should-prompt fresh exits 0"
setup_update_env >/dev/null
if "$UPDATE_CHECK" --should-prompt session-X 2>/dev/null; then
  ok "Fresh session gets exit 0 (prompt)"
else
  fail_test "Fresh session should exit 0"
fi
teardown_update_env

echo "Test U10: --should-prompt within 10 min for same session exits 1"
setup_update_env >/dev/null
"$UPDATE_CHECK" --prompted session-Y 2>&1
if "$UPDATE_CHECK" --should-prompt session-Y 2>/dev/null; then
  fail_test "Same-session within 10min should exit 1"
else
  ok "Same-session within 10min suppresses prompt"
fi
teardown_update_env

echo "Test U11: --should-prompt for different session exits 0"
setup_update_env >/dev/null
"$UPDATE_CHECK" --prompted session-Y 2>&1
if "$UPDATE_CHECK" --should-prompt session-Z 2>/dev/null; then
  ok "Different session gets exit 0"
else
  fail_test "Different session should exit 0"
fi
teardown_update_env

echo "Test U12: --should-prompt expired window (>10min ago) exits 0"
setup_update_env >/dev/null
old_ts=$(($(date +%s) - 11 * 60))
printf '{"prompted_session":"session-old","prompted_at":%d}\n' "$old_ts" > "$SKILLS_TEMPLATES_CACHE"
if "$UPDATE_CHECK" --should-prompt session-old 2>/dev/null; then
  ok "Expired prompt window allows re-prompt"
else
  fail_test "Expired window should allow prompt"
fi
teardown_update_env

echo "Test U13: Atomic cache writes leave no .tmp.* debris"
setup_update_env >/dev/null
"$UPDATE_CHECK" --snooze 12 2>&1
"$UPDATE_CHECK" --skip 2.0.0 2>&1
"$UPDATE_CHECK" --prompted session-Q 2>&1
debris=$(find "$(dirname "$SKILLS_TEMPLATES_CACHE")" -name 'cache.json.tmp.*' 2>/dev/null | wc -l | tr -d ' ')
if [ "$debris" = "0" ]; then
  ok "No .tmp.* debris"
else
  fail_test "Found $debris debris files"
fi
teardown_update_env

echo "Test U14: Subsequent subcommand merges into existing cache"
setup_update_env >/dev/null
"$UPDATE_CHECK" --snooze 5 2>&1
"$UPDATE_CHECK" --skip 1.7.0 2>&1
both=$(jq -r '[.snooze_until, .skip_version] | @csv' "$SKILLS_TEMPLATES_CACHE")
if echo "$both" | grep -q '"1.7.0"' && echo "$both" | grep -qE '[0-9]+'; then
  ok "Snooze + skip both retained"
else
  fail_test "Cache merge failed: $both"
fi
teardown_update_env

# --- E2E tests with fake git clone fixture ---

echo "Test U15: Banner emits when origin advanced past installed"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.1.0")
write_manifest "$clone" "1.0.0"
out=$("$UPDATE_CHECK" 2>&1 | head -1)
if echo "$out" | grep -q '^SKILLS_UPGRADE_AVAILABLE 1\.0\.0 1\.1\.0$'; then
  ok "Banner emitted with correct versions"
else
  fail_test "Expected SKILLS_UPGRADE_AVAILABLE, got: $out"
fi
teardown_update_env

echo "Test U16: No banner when local == remote"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.0.0")
write_manifest "$clone" "1.0.0"
out=$("$UPDATE_CHECK" 2>&1)
if [ -z "$out" ]; then
  ok "Silent when up to date"
else
  fail_test "Should be silent, got: $out"
fi
teardown_update_env

echo "Test U17: Cache is populated after first fetch"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.1.0")
write_manifest "$clone" "1.0.0"
"$UPDATE_CHECK" >/dev/null 2>&1
checked=$(jq -r '.checked_at // empty' "$SKILLS_TEMPLATES_CACHE")
remote=$(jq -r '.remote_version // empty' "$SKILLS_TEMPLATES_CACHE")
if [ -n "$checked" ] && [ "$remote" = "1.1.0" ]; then
  ok "Cache populated"
else
  fail_test "Cache missing fields (checked=$checked, remote=$remote)"
fi
teardown_update_env

echo "Test U18: skip_version suppresses banner for that version"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.1.0")
write_manifest "$clone" "1.0.0"
"$UPDATE_CHECK" >/dev/null 2>&1
"$UPDATE_CHECK" --skip 1.1.0 2>&1
out=$("$UPDATE_CHECK" 2>&1)
if [ -z "$out" ]; then
  ok "skip_version suppresses banner"
else
  fail_test "Should be silent, got: $out"
fi
teardown_update_env

echo "Test U19: snooze_until suppresses banner during window"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.1.0")
write_manifest "$clone" "1.0.0"
"$UPDATE_CHECK" --snooze 1 2>&1
out=$("$UPDATE_CHECK" 2>&1)
if [ -z "$out" ]; then
  ok "snooze suppresses banner during window"
else
  fail_test "Should be silent during snooze, got: $out"
fi
teardown_update_env

echo "Test U20: source path moved/deleted exits silent"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.1.0")
write_manifest "$clone" "1.0.0"
rm -rf "$clone"
out=$("$UPDATE_CHECK" 2>&1)
if [ -z "$out" ]; then
  ok "Silent exit when source missing"
else
  fail_test "Expected silent, got: $out"
fi
teardown_update_env

echo "Test U21: JUST_UPGRADED marker is read, unlinked, and emitted"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.1.0" "1.1.0")
write_manifest "$clone" "1.1.0"
printf '%s %s\n' "1.0.0" "1.1.0" > "$SKILLS_TEMPLATES_MARKER"
out=$("$UPDATE_CHECK" 2>&1)
if echo "$out" | grep -q '^SKILLS_JUST_UPGRADED 1\.0\.0 1\.1\.0$' && [ ! -f "$SKILLS_TEMPLATES_MARKER" ]; then
  ok "Marker emitted and unlinked"
else
  fail_test "Marker handling failed (out='$out')"
fi
teardown_update_env

echo "Test U22: Marker race tolerated (marker missing)"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.0.0")
write_manifest "$clone" "1.0.0"
out=$("$UPDATE_CHECK" 2>&1)
if [ -z "$out" ] || ! echo "$out" | grep -q "JUST_UPGRADED"; then
  ok "Missing marker tolerated"
else
  fail_test "Should not emit JUST_UPGRADED with no marker"
fi
teardown_update_env

# --- skills-deploy --from-upgrade tests ---

echo "Test U23: skills-deploy install --from-upgrade rejects missing value"
setup_env
if "$DEPLOY" install CJ_personal-workflow --from-upgrade 2>/dev/null; then
  fail_test "--from-upgrade with no value should fail"
else
  ok "--from-upgrade rejects missing value"
fi
teardown_env

echo "Test U24: skills-deploy install --from-upgrade rejects non-semver value"
setup_env
if "$DEPLOY" install CJ_personal-workflow --from-upgrade not-a-version 2>/dev/null; then
  fail_test "--from-upgrade with bad version should fail"
else
  ok "--from-upgrade rejects non-semver"
fi
teardown_env

echo "Test U25: skills-deploy install --from-upgrade writes JUST_UPGRADED marker"
setup_env
export SKILLS_TEMPLATES_MARKER="$SKILLS_DEPLOY_TARGET/just-upgraded-marker"
"$DEPLOY" install CJ_personal-workflow --from-upgrade 1.4.0 >/dev/null 2>&1
if [ -f "$SKILLS_TEMPLATES_MARKER" ]; then
  payload=$(cat "$SKILLS_TEMPLATES_MARKER")
  if echo "$payload" | grep -qE '^1\.4\.0 [0-9]+\.[0-9]+\.[0-9]+'; then
    ok "Marker written: $payload"
  else
    fail_test "Marker malformed: $payload"
  fi
else
  fail_test "Marker file not written"
fi
unset SKILLS_TEMPLATES_MARKER
teardown_env

echo "Test U26: skills-deploy install (no --from-upgrade) does NOT write marker"
setup_env
export SKILLS_TEMPLATES_MARKER="$SKILLS_DEPLOY_TARGET/should-not-exist"
"$DEPLOY" install CJ_personal-workflow >/dev/null 2>&1
if [ ! -f "$SKILLS_TEMPLATES_MARKER" ]; then
  ok "No marker without --from-upgrade"
else
  fail_test "Marker written when not requested"
fi
unset SKILLS_TEMPLATES_MARKER
teardown_env

echo "Test U27: doctor surfaces update-check cache"
setup_env
export SKILLS_TEMPLATES_CACHE="$SKILLS_DEPLOY_TARGET/test-update-cache.json"
"$DEPLOY" install CJ_personal-workflow >/dev/null 2>&1
"$UPDATE_CHECK" --skip 9.9.9 2>&1
out=$("$DEPLOY" doctor 2>&1)
if echo "$out" | grep -q "Update check:" && echo "$out" | grep -q "Skipping version: 9.9.9"; then
  ok "Doctor surfaces update-check cache state"
else
  fail_test "Doctor output missing cache info"
fi
unset SKILLS_TEMPLATES_CACHE
teardown_env

echo "Test U28: doctor handles missing cache file gracefully"
setup_env
export SKILLS_TEMPLATES_CACHE="$SKILLS_DEPLOY_TARGET/never-created.json"
"$DEPLOY" install CJ_personal-workflow >/dev/null 2>&1
out=$("$DEPLOY" doctor 2>&1)
if echo "$out" | grep -q "Update check: (never run"; then
  ok "Doctor reports never-run state cleanly"
else
  fail_test "Doctor missing 'never run' message"
fi
unset SKILLS_TEMPLATES_CACHE
teardown_env

echo "Test U29: install writes manifest.upstream_url from source origin (T000031)"
setup_env
"$DEPLOY" install CJ_personal-workflow >/dev/null 2>&1
upstream=$(jq -r '.upstream_url // empty' "$SKILLS_DEPLOY_MANIFEST")
expected=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)
if [ -n "$upstream" ] && [ "$upstream" = "$expected" ]; then
  ok "upstream_url captured ($upstream)"
else
  fail_test "Expected upstream_url=$expected, got: $upstream"
fi
teardown_env

echo "Test U30: update-check suppresses banner when origin URL mismatches manifest pin (T000031)"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.1.0")
# Write manifest with a bogus upstream_url that does NOT match the clone's actual origin
printf '{"source":"%s","collection_version":"1.0.0","upstream_url":"git@github.com:attacker/evil.git","skills":{},"templates":{}}\n' "$clone" > "$SKILLS_TEMPLATES_MANIFEST"
out=$("$UPDATE_CHECK" 2>&1)
banner=$(echo "$out" | grep -c '^SKILLS_UPGRADE_AVAILABLE' || true)
warn=$(echo "$out" | grep -c 'origin URL mismatch' || true)
if [ "$banner" = "0" ] && [ "$warn" -ge "1" ]; then
  ok "Banner suppressed and warning emitted on origin mismatch"
else
  fail_test "Expected suppression + warning, got banner=$banner warn=$warn out=$out"
fi
teardown_update_env

echo "Test U31: update-check emits banner when origin URL matches manifest pin (T000031)"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.1.0")
actual_origin=$(git -C "$clone" remote get-url origin 2>/dev/null)
printf '{"source":"%s","collection_version":"1.0.0","upstream_url":"%s","skills":{},"templates":{}}\n' "$clone" "$actual_origin" > "$SKILLS_TEMPLATES_MANIFEST"
out=$("$UPDATE_CHECK" 2>&1 | head -1)
if echo "$out" | grep -q '^SKILLS_UPGRADE_AVAILABLE 1\.0\.0 1\.1\.0$'; then
  ok "Banner emits normally when origin matches pin"
else
  fail_test "Expected SKILLS_UPGRADE_AVAILABLE with matching pin, got: $out"
fi
teardown_update_env

echo "Test U32: pre-T000031 manifest (no upstream_url field) still gets banner (backward compat)"
setup_update_env >/dev/null
clone=$(make_fake_clone "1.0.0" "1.1.0")
write_manifest "$clone" "1.0.0"  # legacy helper omits upstream_url
out=$("$UPDATE_CHECK" 2>&1 | head -1)
if echo "$out" | grep -q '^SKILLS_UPGRADE_AVAILABLE'; then
  ok "Pre-T000031 manifest skips pin check (no field → not pinned)"
else
  fail_test "Expected banner for legacy manifest, got: $out"
fi
teardown_update_env

# === Subdirectory tests ===
# Tests 13-19 (subdirectory symlink behaviors) deleted in S000053 (F000023):
# they exercised the deprecated CJ_company-workflow skill's reference/philosophy/
# fixtures subdirs. The skill is gone; the behavior they covered (catalog-driven
# subdir symlinking) is still exercised by Test 16 below for CJ_system-health
# (no-subdirs case) — sufficient regression coverage for the subdir codepath.

# Test 16: Skill without subdirectories unaffected
echo "Test 16: Skill without subdirectories unaffected"
setup_env
"$DEPLOY" install CJ_system-health >/dev/null 2>&1
subdir_count=$(find "$SKILLS_DEPLOY_TARGET/CJ_system-health" -maxdepth 1 -type l -not -name "*.md" -not -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
if [ "$subdir_count" -eq 0 ]; then
  ok "No spurious subdirectory symlinks for CJ_system-health"
else
  fail_test "CJ_system-health has unexpected subdirectory symlinks: $subdir_count"
fi
teardown_env

# === Template tests ===
echo ""
echo "=== Template deployment tests ==="
echo ""

# Test T1: Install deploys templates
echo "Test T1: Install deploys templates"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
expected_count=$(jq -r '.[] | select(.name == "templates") | .templates | length' "$CATALOG")
actual_count=$(find "$SKILLS_DEPLOY_TEMPLATES_TARGET" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$actual_count" -eq "$expected_count" ]; then
  ok "Templates entry deployed $expected_count templates"
else
  fail_test "Expected $expected_count templates, got $actual_count"
fi
# Verify manifest has templates section
if jq -e '.templates' "$SKILLS_DEPLOY_MANIFEST" >/dev/null 2>&1; then
  ok "Manifest has templates section"
else
  fail_test "Manifest missing templates section"
fi
teardown_env

# Test T2: Shared ownership (synthetic fixture)
echo "Test T2: Shared ownership"
setup_env
# Install both templates and CJ_system-health
"$DEPLOY" install templates >/dev/null 2>&1
"$DEPLOY" install CJ_system-health >/dev/null 2>&1
# Manually add CJ_system-health as co-owner of doc-SKILL-DESIGN.md (simulating shared template)
jq '.templates["doc-SKILL-DESIGN.md"].owners += ["CJ_system-health"] | .templates["doc-SKILL-DESIGN.md"].owners = (.templates["doc-SKILL-DESIGN.md"].owners | unique)' \
  "$SKILLS_DEPLOY_MANIFEST" > "$SKILLS_DEPLOY_MANIFEST.tmp" && mv "$SKILLS_DEPLOY_MANIFEST.tmp" "$SKILLS_DEPLOY_MANIFEST"
# Remove templates — doc-SKILL-DESIGN.md should persist (CJ_system-health still owns it)
"$DEPLOY" remove templates --force >/dev/null 2>&1
if [ -f "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md" ]; then
  ok "doc-SKILL-DESIGN.md persists (CJ_system-health still owns it)"
else
  fail_test "doc-SKILL-DESIGN.md was deleted despite CJ_system-health ownership"
fi
# Remove CJ_system-health — now doc-SKILL-DESIGN.md should be cleaned up
"$DEPLOY" remove CJ_system-health --force >/dev/null 2>&1
if [ ! -f "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md" ]; then
  ok "doc-SKILL-DESIGN.md removed when last owner removed"
else
  fail_test "doc-SKILL-DESIGN.md still exists after all owners removed"
fi
teardown_env

# Test T3: Full cleanup
echo "Test T3: Full cleanup"
setup_env
"$DEPLOY" install >/dev/null 2>&1
tpl_count=$(find "$SKILLS_DEPLOY_TEMPLATES_TARGET" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$tpl_count" -gt 0 ]; then
  ok "Templates deployed ($tpl_count files)"
else
  fail_test "No templates deployed"
fi
"$DEPLOY" remove --all --force >/dev/null 2>&1
tpl_count=$(find "$SKILLS_DEPLOY_TEMPLATES_TARGET" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$tpl_count" -eq 0 ]; then
  ok "All templates cleaned up"
else
  fail_test "Templates remain after remove --all: $tpl_count"
fi
teardown_env

# Test T4: Doctor detects missing template
echo "Test T4: Doctor detects missing template"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
rm -f "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md"
output=$("$DEPLOY" doctor 2>&1)
if echo "$output" | grep -q "FAIL.*doc-SKILL-DESIGN.md"; then
  ok "Doctor detects missing template"
else
  fail_test "Doctor missed missing template"
fi
teardown_env

# Test T5: Doctor detects drifted template
echo "Test T5: Doctor detects drifted template"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
echo "modified content" >> "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md"
output=$("$DEPLOY" doctor 2>&1)
if echo "$output" | grep -q "WARN.*doc-SKILL-DESIGN.md"; then
  ok "Doctor detects drifted template"
else
  fail_test "Doctor missed drifted template"
fi
teardown_env

# Test T6: drifted-template handling (D000015 — default overwrites; --no-overwrite preserves)
echo "Test T6: drifted-template handling"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1

# T6a: default install (no flag) overwrites drifted templates and logs UPDATE
echo "modified content" >> "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md"
output=$("$DEPLOY" install templates 2>&1)
if echo "$output" | grep -qF "UPDATE:"; then
  ok "Default install overwrites drifted template (D000015)"
else
  fail_test "Default install did not log UPDATE for drifted template (D000015 regressed)"
fi
if diff -q "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md" "$REPO_ROOT/templates/doc-SKILL-DESIGN.md" >/dev/null 2>&1; then
  ok "Default install restored template to source content"
else
  fail_test "Default install did not restore drifted template"
fi

# T6b: --no-overwrite preserves drifted content and logs PRESERVE
echo "modified content again" >> "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md"
output=$("$DEPLOY" install templates --no-overwrite 2>&1)
if echo "$output" | grep -qF "PRESERVE:"; then
  ok "--no-overwrite preserves drifted template (D000015)"
else
  fail_test "--no-overwrite did not log PRESERVE (D000015 regressed)"
fi
if diff -q "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md" "$REPO_ROOT/templates/doc-SKILL-DESIGN.md" >/dev/null 2>&1; then
  fail_test "--no-overwrite incorrectly overwrote drifted template"
else
  ok "--no-overwrite kept drifted content intact"
fi

# T6c: legacy --overwrite still works (backwards compat with D000013 post-merge hook)
"$DEPLOY" install templates --overwrite >/dev/null 2>&1
if diff -q "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-SKILL-DESIGN.md" "$REPO_ROOT/templates/doc-SKILL-DESIGN.md" >/dev/null 2>&1; then
  ok "Legacy --overwrite still restores template (backwards compat)"
else
  fail_test "Legacy --overwrite did not restore template (broke D000013 hook compat)"
fi
teardown_env

# Test T7: Idempotent install (no duplicate owners)
echo "Test T7: Idempotent install"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
"$DEPLOY" install templates >/dev/null 2>&1
# shellcheck disable=SC2034  # dup_count used for debug inspection
dup_count=$(jq '[.templates // {} | .[] | .owners | length] | map(select(. > 1)) | length' "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null || echo "0")
# Each template should have exactly 1 owner (templates), not 2
owner_count=$(jq '.templates["doc-SKILL-DESIGN.md"].owners | length' "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null || echo "0")
if [ "$owner_count" -eq 1 ]; then
  ok "No duplicate owners after double install"
else
  fail_test "Expected 1 owner for doc-SKILL-DESIGN.md, got $owner_count"
fi
teardown_env

# Test T8: Path traversal rejected
echo "Test T8: Path traversal protection"
setup_env
# Test validate_template_name by calling it as a bash function
output=$(bash -c '[[ "../../evil.md" =~ ^[a-zA-Z0-9_.-]+\.md$ ]] && echo "MATCH" || echo "BLOCKED"' 2>&1)
if [ "$output" = "BLOCKED" ]; then
  ok "Path traversal pattern rejected by regex"
else
  fail_test "Path traversal not caught by regex"
fi
# Also test a valid name passes
output=$(bash -c '[[ "doc-SKILL-DESIGN.md" =~ ^[a-zA-Z0-9_.-]+\.md$ ]] && echo "MATCH" || echo "BLOCKED"' 2>&1)
if [ "$output" = "MATCH" ]; then
  ok "Valid template name accepted by regex"
else
  fail_test "Valid template name rejected"
fi
teardown_env

# Test T9: rules/ deploy
echo "Test T9: rules/ deploy"
setup_env
"$DEPLOY" install >/dev/null 2>&1
# T9a: each rule in rules/ is deployed to RULES_TARGET
if [ -d "$REPO_ROOT/rules" ]; then
  rules_found=0
  for rule_file in "$REPO_ROOT/rules"/*.md; do
    [ -f "$rule_file" ] || continue
    rules_found=$((rules_found + 1))
    rule_name=$(basename "$rule_file")
    if [ -f "$SKILLS_DEPLOY_RULES_TARGET/$rule_name" ]; then
      ok "rules/$rule_name deployed to RULES_TARGET"
    else
      fail_test "rules/$rule_name not deployed (expected at $SKILLS_DEPLOY_RULES_TARGET/$rule_name)"
    fi
  done
  [ "$rules_found" -eq 0 ] && ok "rules/ is empty — nothing to deploy (T9 vacuously passes)"
else
  ok "rules/ directory does not exist — nothing to deploy (T9 vacuously passes)"
fi

# T9b: deployed content matches source
if [ -d "$REPO_ROOT/rules" ]; then
  for rule_file in "$REPO_ROOT/rules"/*.md; do
    [ -f "$rule_file" ] || continue
    rule_name=$(basename "$rule_file")
    if diff -q "$rule_file" "$SKILLS_DEPLOY_RULES_TARGET/$rule_name" >/dev/null 2>&1; then
      ok "rules/$rule_name content matches source"
    else
      fail_test "rules/$rule_name deployed content differs from source"
    fi
  done
else
  ok "rules/ does not exist — T9b vacuously passes"
fi

# T9c: --no-overwrite emits WARN (not PRESERVE) for drifted rule
if [ -d "$REPO_ROOT/rules" ]; then
  first_rule=""
  for rule_file in "$REPO_ROOT/rules"/*.md; do
    [ -f "$rule_file" ] || continue
    first_rule="$rule_file"
    break
  done
  if [ -n "$first_rule" ]; then
    rule_name=$(basename "$first_rule")
    echo "drifted content" > "$SKILLS_DEPLOY_RULES_TARGET/$rule_name"
    no_overwrite_output=$("$DEPLOY" install --no-overwrite 2>&1 || true)
    if echo "$no_overwrite_output" | grep -q "WARN:.*$rule_name"; then
      ok "--no-overwrite emits WARN for drifted rule"
    else
      fail_test "--no-overwrite did not emit WARN for drifted rule (T000021 regressed)"
    fi
    if diff -q "$SKILLS_DEPLOY_RULES_TARGET/$rule_name" "$first_rule" >/dev/null 2>&1; then
      fail_test "--no-overwrite incorrectly overwrote drifted rule"
    else
      ok "--no-overwrite kept drifted rule intact"
    fi
  fi
fi
teardown_env

# Test T9d: doctor reports MISSING for undeployed rule
echo "Test T9d: doctor MISSING for undeployed rule"
setup_env
"$DEPLOY" install >/dev/null 2>&1
if [ -d "$REPO_ROOT/rules" ]; then
  first_rule=""
  for rule_file in "$REPO_ROOT/rules"/*.md; do
    [ -f "$rule_file" ] || continue
    first_rule="$rule_file"
    break
  done
  if [ -n "$first_rule" ]; then
    rule_name=$(basename "$first_rule")
    rm -f "$SKILLS_DEPLOY_RULES_TARGET/$rule_name"
    doctor_output=$("$DEPLOY" doctor 2>&1 || true)
    if echo "$doctor_output" | grep -q "MISSING: $rule_name"; then
      ok "doctor reports MISSING for undeployed rule"
    else
      fail_test "doctor did not report MISSING for removed rule $rule_name"
    fi
  else
    ok "rules/ is empty — T9d vacuously passes"
  fi
else
  ok "rules/ does not exist — T9d vacuously passes"
fi
teardown_env

# Test T9e: doctor reports WARN for drifted rule
echo "Test T9e: doctor WARN for drifted rule"
setup_env
"$DEPLOY" install >/dev/null 2>&1
if [ -d "$REPO_ROOT/rules" ]; then
  first_rule=""
  for rule_file in "$REPO_ROOT/rules"/*.md; do
    [ -f "$rule_file" ] || continue
    first_rule="$rule_file"
    break
  done
  if [ -n "$first_rule" ]; then
    rule_name=$(basename "$first_rule")
    echo "drifted content" >> "$SKILLS_DEPLOY_RULES_TARGET/$rule_name"
    doctor_output=$("$DEPLOY" doctor 2>&1 || true)
    if echo "$doctor_output" | grep -q "WARN: $rule_name"; then
      ok "doctor reports WARN for drifted rule"
    else
      fail_test "doctor did not report WARN for drifted rule $rule_name"
    fi
  else
    ok "rules/ is empty — T9e vacuously passes"
  fi
else
  ok "rules/ does not exist — T9e vacuously passes"
fi
teardown_env

# Test T9g: remove single skill does NOT remove deployed rules
echo "Test T9g: remove single skill keeps deployed rules"
setup_env
"$DEPLOY" install >/dev/null 2>&1
if [ -d "$REPO_ROOT/rules" ] && find "$SKILLS_DEPLOY_RULES_TARGET" -name "*.md" 2>/dev/null | grep -q .; then
  "$DEPLOY" remove CJ_system-health --force >/dev/null 2>&1 || true
  remaining_rules=$(find "$SKILLS_DEPLOY_RULES_TARGET" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$remaining_rules" -gt 0 ]; then
    ok "remove single skill keeps deployed rules intact"
  else
    fail_test "remove single skill incorrectly deleted deployed rules"
  fi
else
  ok "rules/ empty or not deployed — T9g vacuously passes"
fi
teardown_env

# Test T9f: remove --all also removes deployed rules
echo "Test T9f: remove --all removes deployed rules"
setup_env
"$DEPLOY" install >/dev/null 2>&1
if [ -d "$REPO_ROOT/rules" ] && [ "$(ls -A "$SKILLS_DEPLOY_RULES_TARGET" 2>/dev/null)" ]; then
  "$DEPLOY" remove --all --force >/dev/null 2>&1
  remaining_rules=$(find "$SKILLS_DEPLOY_RULES_TARGET" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$remaining_rules" -eq 0 ]; then
    ok "remove --all removes deployed rules"
  else
    fail_test "remove --all left $remaining_rules rule file(s) in RULES_TARGET"
  fi
else
  ok "rules/ empty or not deployed — T9f vacuously passes"
fi
teardown_env

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$ERRORS test(s) failed." >&2
  exit 1
fi
