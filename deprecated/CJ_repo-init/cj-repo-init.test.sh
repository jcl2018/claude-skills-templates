#!/usr/bin/env bash
# tests/cj-repo-init.test.sh
#
# Unit tests for scripts/cj-repo-init.sh (F000042 / S000075).
#
# Each test runs the engine in an isolated temp git repo with a synthetic
# CJ_REPO_INIT_CLAUDE_HOME, so the deployed-manifest detection path is fully
# controlled. Covers TEST-SPEC smoke rows S1–S5:
#
#   S1 detect_emits_gaps                 — default run prints table + GAPS=<n>
#   S2 fix_then_noop                     — --fix scaffolds, exit 0; re-run no-op
#   S3 config_valid_and_invalid_detected — generated config valid; bad config flagged
#   S4 dry_run_no_write                  — --dry-run mutates nothing
#   S5 degrades_cleanly                  — not-a-git-repo errors; missing manifest degrades
#   S6 docguide_prereq                   — CJ-DOC-RELEASE.md: missing->gap, --fix
#                                          seeds->ok, present->ok, headingless->invalid
#                                          (no-overwrite)
#
# Run: bash tests/cj-repo-init.test.sh   (exit 0 = all pass, 1 = failures)

set -uo pipefail

# NOTE: /CJ_repo-init is DEPRECATED (retired by the doc-spec.md migration). This
# test + the engine it exercises are relocated under deprecated/CJ_repo-init/ as
# archival reference and are NOT run by scripts/test.sh. The engine is now a
# sibling of this test, not under skills/.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
ENGINE="$SCRIPT_DIR/scripts/cj-repo-init.sh"

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

# Make a fresh temp git repo with a fake ~/.claude home. Echoes the repo path.
# Arg 1 (optional): "deploy" to write a manifest declaring CJ_ skills.
make_repo() {
  local tmp fakehome
  tmp=$(mktemp -d -t cjri-repo-XXXXX)
  git -C "$tmp" init -q .
  fakehome="$tmp/.fake-claude"
  mkdir -p "$fakehome"
  if [ "${1:-}" = "deploy" ]; then
    mkdir -p "$fakehome/skills/CJ_personal-workflow"
    echo '{}' > "$fakehome/skills/CJ_personal-workflow/personal-artifact-manifests.json"
    cat > "$fakehome/.skills-templates.json" <<'JSON'
{
  "source": "/tmp/fake-source",
  "skills": {
    "CJ_document-release": {},
    "CJ_suggest": {},
    "CJ_scaffold-work-item": {},
    "CJ_personal-workflow": {}
  }
}
JSON
  fi
  echo "$tmp"
}

run_engine() {  # run_engine <repo> <fakehome> [args...]
  local repo="$1" fakehome="$2"; shift 2
  ( cd "$repo" && CJ_REPO_INIT_CLAUDE_HOME="$fakehome" bash "$ENGINE" "$@" )
}

[ -x "$ENGINE" ] || { fail_test "engine missing or not executable: $ENGINE"; echo "FAIL: cj-repo-init ($ERRORS error(s))"; exit 1; }

echo "=== cj-repo-init.sh unit tests ==="

# ─── S1: detect_emits_gaps ───────────────────────────────────────────────────
echo "--- S1 detect_emits_gaps ---"
REPO=$(make_repo deploy); FH="$REPO/.fake-claude"
OUT=$(run_engine "$REPO" "$FH"); RC=$?
if [ "$RC" -eq 1 ]; then ok "S1: exit 1 with repo-level gaps present"; else fail_test "S1: expected exit 1, got $RC"; fi
echo "$OUT" | grep -q "GAPS=4" && ok "S1: GAPS=4 emitted (4 repo-level gaps)" || fail_test "S1: GAPS=4 not found"
echo "$OUT" | grep -q "prereq" && echo "$OUT" | grep -q "needed-by" && ok "S1: human-readable table header present" || fail_test "S1: table header missing"
echo "$OUT" | grep -q "REPO_GAP cj-document-release.json missing" && ok "S1: per-gap REPO_GAP line for docrel" || fail_test "S1: docrel REPO_GAP line missing"
echo "$OUT" | grep -q "REPO_GAP CJ-DOC-RELEASE.md missing" && ok "S1: per-gap REPO_GAP line for docguide" || fail_test "S1: docguide REPO_GAP line missing"
echo "$OUT" | grep -q "REPO_GAP TODOS.md missing" && ok "S1: per-gap REPO_GAP line for TODOS" || fail_test "S1: TODOS REPO_GAP line missing"
# install-level gap reported but does NOT count toward GAPS
echo "$OUT" | grep -q "INSTALL_GAPS=0" && ok "S1: INSTALL_GAPS=0 (pw assets present in fixture)" || fail_test "S1: expected INSTALL_GAPS=0"
rm -rf "$REPO"

# ─── S2: fix_then_noop ───────────────────────────────────────────────────────
echo "--- S2 fix_then_noop ---"
REPO=$(make_repo deploy); FH="$REPO/.fake-claude"
OUT=$(run_engine "$REPO" "$FH" --fix); RC=$?
if [ "$RC" -eq 0 ]; then ok "S2: --fix exits 0 after scaffolding"; else fail_test "S2: expected exit 0 after --fix, got $RC"; fi
[ -f "$REPO/cj-document-release.json" ] && ok "S2: cj-document-release.json created" || fail_test "S2: cj-document-release.json not created"
[ -f "$REPO/CJ-DOC-RELEASE.md" ] && ok "S2: CJ-DOC-RELEASE.md created" || fail_test "S2: CJ-DOC-RELEASE.md not created"
[ -f "$REPO/TODOS.md" ] && ok "S2: TODOS.md created" || fail_test "S2: TODOS.md not created"
[ -d "$REPO/work-items/features" ] && [ -d "$REPO/work-items/defects" ] && [ -d "$REPO/work-items/tasks" ] && ok "S2: work-items/{features,defects,tasks} created" || fail_test "S2: work-items dirs not created"
echo "$OUT" | grep -q "GAPS=0" && ok "S2: post-fix GAPS=0" || fail_test "S2: post-fix GAPS=0 not reported"
# Idempotent re-run: --fix again is a no-op, exit 0, no duplicate writes.
OUT2=$(run_engine "$REPO" "$FH" --fix); RC2=$?
[ "$RC2" -eq 0 ] && ok "S2: idempotent --fix re-run exits 0" || fail_test "S2: idempotent re-run expected 0, got $RC2"
echo "$OUT2" | grep -q "nothing — no repo-level gaps to fix" && ok "S2: re-run reports idempotent no-op" || fail_test "S2: re-run did not report no-op"
# Default re-run on healthy repo is also exit 0.
run_engine "$REPO" "$FH" >/dev/null 2>&1 && ok "S2: default run on healthy repo exits 0" || fail_test "S2: healthy default run expected exit 0"
rm -rf "$REPO"

# ─── S3: config_valid_and_invalid_detected ──────────────────────────────────
echo "--- S3 config_valid_and_invalid_detected ---"
REPO=$(make_repo deploy); FH="$REPO/.fake-claude"
run_engine "$REPO" "$FH" --fix >/dev/null 2>&1
# Generated config must pass the same checks validate.sh Check 16 enforces.
CFG="$REPO/cj-document-release.json"
jq empty "$CFG" 2>/dev/null && ok "S3: generated config is valid JSON" || fail_test "S3: generated config not valid JSON"
[ "$(jq -r '.schema_version' "$CFG")" = "1" ] && ok "S3: schema_version == 1" || fail_test "S3: schema_version != 1"
jq -e '.whitelist_patterns | type=="array" and length>0' "$CFG" >/dev/null 2>&1 && ok "S3: whitelist_patterns non-empty array" || fail_test "S3: whitelist_patterns bad shape"
jq -e '.categories | type=="object" and length>0' "$CFG" >/dev/null 2>&1 && ok "S3: categories non-empty object" || fail_test "S3: categories bad shape"
jq -e '[.categories|to_entries[].value|type=="array" and length>0]|all' "$CFG" >/dev/null 2>&1 && ok "S3: each category is non-empty array" || fail_test "S3: a category value is not a non-empty array"
# Now corrupt the config and confirm it is detected as a gap (invalid != ok).
echo 'not json {' > "$CFG"
OUT=$(run_engine "$REPO" "$FH"); RC=$?
echo "$OUT" | grep -q "REPO_GAP cj-document-release.json invalid" && ok "S3: unparseable config flagged as invalid gap" || fail_test "S3: invalid config not flagged"
[ "$RC" -eq 1 ] && ok "S3: invalid config -> exit 1" || fail_test "S3: invalid config expected exit 1, got $RC"
# --fix must NOT overwrite an invalid (present) config.
run_engine "$REPO" "$FH" --fix >/dev/null 2>&1
grep -q 'not json {' "$CFG" && ok "S3: --fix did not overwrite present-but-invalid config" || fail_test "S3: --fix clobbered an invalid config"
# Unsupported schema_version is also a gap.
echo '{"schema_version":2,"whitelist_patterns":["x"],"categories":{"a":["b"]}}' > "$CFG"
SV2_OUT=$(run_engine "$REPO" "$FH" 2>/dev/null)
echo "$SV2_OUT" | grep -q "REPO_GAP cj-document-release.json invalid" && ok "S3: unsupported schema_version flagged" || fail_test "S3: schema_version=2 not flagged"
rm -rf "$REPO"

# ─── S4: dry_run_no_write ────────────────────────────────────────────────────
echo "--- S4 dry_run_no_write ---"
REPO=$(make_repo deploy); FH="$REPO/.fake-claude"
BEFORE=$(find "$REPO" -not -path '*/.git/*' | sort)
OUT=$(run_engine "$REPO" "$FH" --dry-run); RC=$?
AFTER=$(find "$REPO" -not -path '*/.git/*' | sort)
[ "$BEFORE" = "$AFTER" ] && ok "S4: --dry-run created/modified no files" || fail_test "S4: --dry-run mutated the tree"
[ "$RC" -eq 1 ] && ok "S4: --dry-run exit reflects gap count (1)" || fail_test "S4: --dry-run expected exit 1, got $RC"
echo "$OUT" | grep -q "GAPS=4" && ok "S4: --dry-run still reports GAPS=4" || fail_test "S4: --dry-run GAPS=4 missing"
rm -rf "$REPO"

# ─── S5: degrades_cleanly ────────────────────────────────────────────────────
echo "--- S5 degrades_cleanly ---"
# 5a: not a git repo -> exit 2 with a clear message, no crash.
NOGIT=$(mktemp -d -t cjri-nogit-XXXXX)
OUT=$( cd "$NOGIT" && CJ_REPO_INIT_CLAUDE_HOME="$NOGIT/.fake" bash "$ENGINE" 2>&1 ); RC=$?
[ "$RC" -eq 2 ] && ok "S5a: not-a-git-repo exits 2" || fail_test "S5a: expected exit 2 outside git, got $RC"
echo "$OUT" | grep -q "not inside a git repository" && ok "S5a: clear not-a-git-repo message" || fail_test "S5a: missing clear error message"
rm -rf "$NOGIT"
# 5b: git repo but NO deployed manifest and NO skill dirs -> degrade (detect source none).
REPO=$(make_repo); FH="$REPO/.fake-claude"   # no "deploy" arg => empty fake home
OUT=$(run_engine "$REPO" "$FH"); RC=$?
echo "$OUT" | grep -q "Detect source:  none" && ok "S5b: degrades to detect source 'none' when no manifest/skills" || fail_test "S5b: did not degrade cleanly"
echo "$OUT" | grep -q "GAPS=" && ok "S5b: still emits a GAPS= line (no crash)" || fail_test "S5b: no GAPS line on degraded path"
rm -rf "$REPO"

# ─── S6: docguide_prereq ─────────────────────────────────────────────────────
echo "--- S6 docguide_prereq (CJ-DOC-RELEASE.md 4th prereq) ---"
REPO=$(make_repo deploy); FH="$REPO/.fake-claude"
DG="$REPO/CJ-DOC-RELEASE.md"
# 6a: missing -> reported as a REPO_GAP.
OUT=$(run_engine "$REPO" "$FH"); RC=$?
echo "$OUT" | grep -q "REPO_GAP CJ-DOC-RELEASE.md missing" && ok "S6a: missing CJ-DOC-RELEASE.md flagged as gap" || fail_test "S6a: missing docguide not flagged"
[ "$RC" -eq 1 ] && ok "S6a: missing docguide -> exit 1" || fail_test "S6a: expected exit 1, got $RC"
# 6b: --fix seeds it; re-verify reports ok.
run_engine "$REPO" "$FH" --fix >/dev/null 2>&1
[ -f "$DG" ] && ok "S6b: --fix seeded CJ-DOC-RELEASE.md" || fail_test "S6b: --fix did not seed CJ-DOC-RELEASE.md"
OUT=$(run_engine "$REPO" "$FH"); RC=$?
echo "$OUT" | grep -q "REPO_GAP CJ-DOC-RELEASE.md" && fail_test "S6b: seeded docguide still flagged as gap" || ok "S6b: present-and-valid docguide reports ok (no gap line)"
# 6c: the seed satisfies its own required-headings check (H1 + schema + registered-doc).
grep -Eq '^# .+'                           "$DG" && ok "S6c: seed has an H1 title" || fail_test "S6c: seed missing H1"
grep -Eq '^## .*cj-document-release\.json' "$DG" && ok "S6c: seed has a cj-document-release.json schema heading" || fail_test "S6c: seed missing schema heading"
grep -Eq '^## .*[Rr]egistered-doc'         "$DG" && ok "S6c: seed has a registered-doc section heading" || fail_test "S6c: seed missing registered-doc heading"
# 6d: present-but-headingless -> invalid; --fix does NOT overwrite it.
printf 'a stub with no required headings\n' > "$DG"
BEFORE=$(cat "$DG")
OUT=$(run_engine "$REPO" "$FH"); RC=$?
echo "$OUT" | grep -q "REPO_GAP CJ-DOC-RELEASE.md invalid" && ok "S6d: headingless docguide flagged invalid" || fail_test "S6d: headingless docguide not flagged invalid"
[ "$RC" -eq 1 ] && ok "S6d: invalid docguide -> exit 1" || fail_test "S6d: expected exit 1, got $RC"
run_engine "$REPO" "$FH" --fix >/dev/null 2>&1
[ "$(cat "$DG")" = "$BEFORE" ] && ok "S6d: --fix did NOT overwrite present-but-invalid docguide" || fail_test "S6d: --fix clobbered an invalid docguide"
rm -rf "$REPO"

# ─── summary ─────────────────────────────────────────────────────────────────
echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-repo-init.sh — all assertions passed"
  exit 0
else
  echo "FAIL: cj-repo-init.sh ($ERRORS assertion(s) failed)"
  exit 1
fi
