#!/usr/bin/env bash
# windows-smoke.sh — Windows-relevant smoke for the F000044 POSIX-on-Windows work.
#
# Runs the Windows-specific subset of the suite: the three behaviors that differ
# between a POSIX host (macOS/Linux) and Git Bash on Windows, one per shipped
# story:
#
#   S000077  CRLF safety   — shell scripts check out with LF endings (.gitattributes)
#   S000078  portable date — the GNU-vs-BSD date probe resolves on this host
#   S000079  copy-mode      — skills-deploy installs as real files when symlinks are unusable
#
# Plus the fast per-PR portability PARITY assertions (F000083) — the CI-push
# stand-ins for the heavy nightly portability-deploy harness, so "another machine
# gets the same skills" gates on every PR without moving the slow test-deploy suite:
#
#   S5  completeness — a full install lands EVERY catalog skill (count == SKILL_COUNT)
#   S6  fidelity     — the deployed bytes match source (manifest source_checksums match)
#
# Deliberately PORTABLE: it passes on macOS/Linux too (copy-mode via the
# SKILLS_DEPLOY_FORCE_COPY override), so the same script is exercised by
# scripts/test.sh on the ubuntu CI + locally — it is not Windows-only-untested
# code. On windows-latest (Git Bash) it is the live check that the support holds
# (.github/workflows/windows.yml). It is the script behind S000080 AC-1/AC-2.

set -euo pipefail

# Strip CRLF from jq output on Windows (jq.exe writes \r\n). No-op on Unix.
# Relies on `pipefail` (set above) so jq's exit status still propagates.
jq() { command jq "$@" | tr -d '\r'; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY="$REPO_ROOT/scripts/skills-deploy"
ERRORS=0
_CLEANUP_DIRS=()

# shellcheck disable=SC2154
trap 'for d in "${_CLEANUP_DIRS[@]+"${_CLEANUP_DIRS[@]}"}"; do rm -rf "$d" 2>/dev/null; done' EXIT

ok()        { echo "  OK: $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

echo "=== Windows smoke (Git Bash subset) ==="
echo "host: $(uname -s 2>/dev/null || echo unknown)  bash: ${BASH_VERSION:-?}"
echo ""

# ---------------------------------------------------------------------------
# S1 (S000077) — shell scripts have LF working-tree endings.
# `git ls-files --eol` reports w/<eol> for the working tree; .gitattributes
# (`* text=auto eol=lf` + explicit shell entries) must keep them LF even when
# core.autocrlf=true (the Git-for-Windows default). A w/crlf here means the
# CRLF guard regressed and bash would choke on \r in shebangs/heredocs.
# ---------------------------------------------------------------------------
echo "S1: shell scripts check out with LF endings (S000077 .gitattributes)"
crlf=$(git -C "$REPO_ROOT" ls-files --eol -- 'scripts/*.sh' 'scripts/skills-deploy' 'scripts/skills-update-check' 2>/dev/null | grep -c 'w/crlf' || true)
if [ "${crlf:-0}" -eq 0 ]; then
  ok "no CRLF working-tree endings among shell scripts"
else
  fail_test "$crlf shell script(s) checked out with CRLF — .gitattributes regressed"
  git -C "$REPO_ROOT" ls-files --eol -- 'scripts/*.sh' 'scripts/skills-deploy' 'scripts/skills-update-check' 2>/dev/null | grep 'w/crlf' >&2 || true
fi

# ---------------------------------------------------------------------------
# S2 (S000078) — the portable date probe resolves on this host.
# Mirrors date_to_epoch in suggest.sh / improve_queue.sh: GNU date (-d) on
# Linux + Git Bash, BSD date (-j -f) on macOS. A broken branch yields an empty
# or zero epoch.
# ---------------------------------------------------------------------------
echo "S2: portable date probe resolves (S000078 GNU/BSD date_to_epoch)"
if date --version >/dev/null 2>&1; then
  epoch=$(date -d "2026-01-01" +%s 2>/dev/null || echo 0)   # GNU (Linux / Git Bash)
  branch="GNU date -d"
else
  epoch=$(date -j -f "%Y-%m-%d" "2026-01-01" +%s 2>/dev/null || echo 0)  # BSD (macOS)
  branch="BSD date -j -f"
fi
if [ "${epoch:-0}" -gt 0 ]; then
  ok "$branch resolved 2026-01-01 -> $epoch"
else
  fail_test "date probe returned no epoch ($branch)"
fi

# ---------------------------------------------------------------------------
# S2b (S000078) — suggest.sh runs end-to-end (exercises date_to_epoch on the
# real tracker `updated:` dates). Exits non-zero under set -euo pipefail if the
# date math breaks on this host.
# ---------------------------------------------------------------------------
echo "S2b: suggest.sh ranks without a date error (S000078 end-to-end)"
if (cd "$REPO_ROOT" && bash skills/CJ_suggest/scripts/suggest.sh >/dev/null 2>&1); then
  ok "suggest.sh exited 0"
else
  fail_test "suggest.sh exited non-zero (date_to_epoch may have broken on this host)"
fi

# ---------------------------------------------------------------------------
# S3 (S000079) — copy-mode install lands real files + records install_kind=copy
# + doctor is healthy. Uses SKILLS_DEPLOY_FORCE_COPY=1 so the assertion is
# identical on macOS/Linux (symlink-capable) and Git Bash (the natural mode).
# ---------------------------------------------------------------------------
echo "S3: copy-mode install lands regular files + healthy doctor (S000079)"
tmp_dir=$(mktemp -d)
_CLEANUP_DIRS+=("$tmp_dir")
export SKILLS_DEPLOY_TARGET="$tmp_dir"
export SKILLS_DEPLOY_MANIFEST="$tmp_dir/.skills-templates.json"
export SKILLS_DEPLOY_TEMPLATES_TARGET="$tmp_dir/templates"
export SKILLS_DEPLOY_RULES_TARGET="$tmp_dir/rules"
mkdir -p "$SKILLS_DEPLOY_TEMPLATES_TARGET"

if SKILLS_DEPLOY_FORCE_COPY=1 "$DEPLOY" install CJ_system-health >/dev/null 2>&1; then
  kind=$(jq -r '.skills["CJ_system-health"].install_kind // "ABSENT"' "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null || echo ABSENT)
  skfile="$SKILLS_DEPLOY_TARGET/CJ_system-health/SKILL.md"
  if [ "$kind" = "copy" ]; then
    ok "manifest records install_kind=copy"
  else
    fail_test "expected install_kind=copy, got: $kind"
  fi
  if [ -f "$skfile" ] && [ ! -L "$skfile" ]; then
    ok "SKILL.md is a regular file (not a symlink)"
  else
    fail_test "SKILL.md is missing or a symlink under copy-mode"
  fi
  if SKILLS_DEPLOY_FORCE_COPY=1 "$DEPLOY" doctor >/dev/null 2>&1; then
    ok "doctor healthy on copy-mode install"
  else
    fail_test "doctor reported unhealthy on a fresh copy-mode install"
  fi
else
  fail_test "copy-mode install (FORCE_COPY) failed"
fi

# Informational: on a real symlink-incapable host (Git Bash) the unforced probe
# auto-selects copy-mode. Logged, not asserted, so the script stays green on
# symlink-capable POSIX hosts where the natural mode is symlink.
tmp_probe=$(mktemp -d); _CLEANUP_DIRS+=("$tmp_probe")
SKILLS_DEPLOY_TARGET="$tmp_probe" SKILLS_DEPLOY_MANIFEST="$tmp_probe/.skills-templates.json" \
  SKILLS_DEPLOY_TEMPLATES_TARGET="$tmp_probe/templates" SKILLS_DEPLOY_RULES_TARGET="$tmp_probe/rules" \
  "$DEPLOY" install CJ_system-health >/dev/null 2>&1 || true
probe_kind=$(jq -r '.skills["CJ_system-health"].install_kind // "?"' "$tmp_probe/.skills-templates.json" 2>/dev/null || echo "?")
echo "  INFO: unforced install auto-selected install_kind=$probe_kind on this host"

# ---------------------------------------------------------------------------
# S4 (F000049/S000088) lock-in (S000089) — the in-place install==clone model
# holds under copy-mode. A DEFAULT `skills-deploy install` stamps install_mode:
# in-place (bundle_path == source), copy-deposits skills-update-check to
# _cj-shared, and the copy-installed orchestrators carry the de-coupled
# `_UC=`/`_cj-shared` update-check (no .source). This is F000049's "Windows
# copy-mode parity" criterion — asserted here under FORCE_COPY (host-independent,
# so green on macOS/Linux too) so a future change cannot silently revert it on
# windows-latest (windows.yml) OR the ubuntu CI (scripts/test.sh:506).
# ---------------------------------------------------------------------------
echo "S4: in-place install==clone + .source de-coupling hold under copy-mode (S000088 lock-in / S000089)"
s5_dir=$(mktemp -d); _CLEANUP_DIRS+=("$s5_dir")
SKILLS_DEPLOY_FORCE_COPY=1 \
  SKILLS_DEPLOY_TARGET="$s5_dir/skills" SKILLS_DEPLOY_MANIFEST="$s5_dir/m.json" \
  SKILLS_DEPLOY_TEMPLATES_TARGET="$s5_dir/templates" SKILLS_DEPLOY_RULES_TARGET="$s5_dir/rules" \
  SKILLS_DEPLOY_SHARED_SCRIPTS_TARGET="$s5_dir/_cj-shared/scripts" \
  "$DEPLOY" install >/dev/null 2>&1 || true
s5_mode=$(jq -r '.install_mode // "none"' "$s5_dir/m.json" 2>/dev/null || echo none)
s5_src=$(jq -r '.source // empty' "$s5_dir/m.json" 2>/dev/null || echo "")
s5_bp=$(jq -r '.bundle_path // empty' "$s5_dir/m.json" 2>/dev/null || echo "")
if [ "$s5_mode" = "in-place" ] && [ -n "$s5_src" ] && [ "$s5_bp" = "$s5_src" ]; then
  ok "copy-mode default install declares install==clone-in-place (install_mode=in-place, bundle_path==source)"
else
  fail_test "copy-mode install did not stamp the in-place receipt (mode='$s5_mode', bundle_path='$s5_bp', source='$s5_src')"
fi
if [ -f "$s5_dir/_cj-shared/scripts/skills-update-check" ]; then
  ok "skills-update-check copy-deposited to _cj-shared (update-check resolves on Windows)"
else
  fail_test "skills-update-check not deposited to _cj-shared under copy-mode"
fi
s5_sk="$s5_dir/skills/CJ_goal_feature/SKILL.md"
if [ -f "$s5_sk" ] && grep -qF '_UC=' "$s5_sk" && grep -qF '_cj-shared' "$s5_sk"; then
  ok "copy-installed orchestrator resolves update-check from _cj-shared (de-coupled, no .source)"
else
  fail_test "copy-installed orchestrator update-check did not de-couple to _cj-shared"
fi

# ---------------------------------------------------------------------------
# S5 (F000083) — COMPLETENESS: a full `skills-deploy install` lands EVERY catalog
# skill on another machine. Deployed skill-dir count == SKILL_COUNT (catalog-
# derived: non-deprecated skills with files), so a deploy that silently drops a
# skill fails here. The fast per-PR stand-in for portability-deploy Test 1 (which
# re-checks the full catalog nightly, Windows-native). REUSES S4's full FORCE_COPY
# install at $s5_dir — host-independent (green on macOS/Linux too).
# ---------------------------------------------------------------------------
echo "S5: full install lands every catalog skill — completeness (F000083)"
CATALOG="$REPO_ROOT/skills-catalog.json"
SKILL_COUNT=$(jq '[.[] | select(.files | length > 0) | select((.status // "active") != "deprecated")] | length' "$CATALOG" 2>/dev/null || echo 0)
s5_count=$(find "$s5_dir/skills" -mindepth 1 -maxdepth 1 -type d ! -path "$s5_dir/skills/templates" ! -path "$s5_dir/skills/rules" 2>/dev/null | wc -l | tr -d ' ')
if [ "${SKILL_COUNT:-0}" -gt 0 ] && [ "${s5_count:-0}" -eq "${SKILL_COUNT:-0}" ]; then
  ok "full install deployed all $SKILL_COUNT catalog skills (completeness)"
else
  fail_test "completeness: expected $SKILL_COUNT skill dirs, got ${s5_count:-0}"
fi

# ---------------------------------------------------------------------------
# S6 (F000083) — FIDELITY: the deployed bytes match source. Copy-mode records a
# per-file source_checksum in the manifest; each must equal the installed copy's
# actual hash, so a corrupted/CRLF-rewritten copy cannot masquerade as source. The
# fast per-PR stand-in for portability-deploy C1/C3 (which additionally prove doctor
# DETECTS drift + relink REPAIRS it, nightly). Reuses the S4 install.
# ---------------------------------------------------------------------------
echo "S6: deployed checksums match source — fidelity (F000083)"
s6_sk="$s5_dir/skills/CJ_system-health/SKILL.md"
s6_rec=$(jq -r '.skills["CJ_system-health"].source_checksums["SKILL.md"] // ""' "$s5_dir/m.json" 2>/dev/null)
s6_act=$( (shasum -a 256 "$s6_sk" 2>/dev/null || sha256sum "$s6_sk" 2>/dev/null) | awk '{print $1}')
if [ -n "$s6_rec" ] && [ "$s6_rec" = "$s6_act" ]; then
  ok "recorded source_checksum matches the installed copy (fidelity)"
else
  fail_test "fidelity: SKILL.md checksum mismatch (recorded='$s6_rec' actual='$s6_act')"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== windows-smoke: PASS (0 failures) ==="
  exit 0
else
  echo "=== windows-smoke: FAIL ($ERRORS failure(s)) ===" >&2
  exit 1
fi
