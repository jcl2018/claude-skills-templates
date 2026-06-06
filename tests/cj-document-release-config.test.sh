#!/usr/bin/env bash
# tests/cj-document-release-config.test.sh
#
# Regression test for the doc-spec.md registry + the scripts/doc-spec.sh helper
# (F000050). Replaces the retired cj-document-release.json + cj-document-release-config.sh
# assertions. Validates the registry file itself + every helper subcommand +
# the strict failure gates.
#
# Asserts:
#   1. doc-spec.md exists at repo root
#   2. doc-spec.md carries exactly one fenced ```yaml registry block
#   3. scripts/doc-spec.sh exists + is executable
#   4. helper --validate exits 0 + prints OK schema_version=1
#   5. helper --list-declared returns the human docs (docs/philosophy.md etc.)
#   6. helper --list-human-docs returns ONLY human-doc paths (no operational)
#   7. helper --expand-whitelist includes doc-spec.md + every declared path
#   8. helper --seed emits the portable Common section
#   9. strict gate: a bad schema_version HALTs with [doc-sync-no-config]
#  10. strict gate: an audit_class outside the enum HALTs with [doc-sync-no-config]
#  11. functional portability: the real helper reads the cwd-toplevel doc-spec.md
#      (run from a temp repo with no scripts/ dir)
#  12. self-bootstrap regression: --seed with NO doc-spec.md present exits 0 and
#      emits a doc-spec.md that PASSES --validate (the gate-before-dispatch bug)
#  13. no-drift: the embedded --seed heredoc == templates/doc-spec-common.md

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
DOC_SPEC="$REPO_ROOT/doc-spec.md"
HELPER="$REPO_ROOT/scripts/doc-spec.sh"

echo "=== doc-spec.md registry + doc-spec.sh helper assertions ==="

# 1. doc-spec.md exists
if [ -f "$DOC_SPEC" ]; then
  ok "doc-spec.md exists at repo root"
else
  fail_test "doc-spec.md missing at repo root: $DOC_SPEC"
  echo "FAIL: cj-document-release-config ($ERRORS error(s))"
  exit 1
fi

# 2. exactly one fenced ```yaml block
_YAML_FENCES=$(grep -cE '^```yaml' "$DOC_SPEC" || true)
if [ "${_YAML_FENCES:-0}" -eq 1 ]; then
  ok "doc-spec.md has exactly one fenced \`\`\`yaml registry block"
else
  fail_test "doc-spec.md should have exactly 1 \`\`\`yaml block, found $_YAML_FENCES"
fi

# 3. helper exists + executable
if [ -x "$HELPER" ]; then
  ok "scripts/doc-spec.sh exists and is executable"
else
  fail_test "scripts/doc-spec.sh missing or not executable"
fi

# 4. --validate
if [ -x "$HELPER" ]; then
  _V_OUT=$(bash "$HELPER" --validate 2>&1)
  if [ $? -eq 0 ] && printf '%s' "$_V_OUT" | grep -qF 'OK schema_version=1'; then
    ok "helper --validate exits 0 + prints OK schema_version=1"
  else
    fail_test "helper --validate failed or wrong output: $_V_OUT"
  fi
else
  fail_test "helper --validate skipped (not executable)"
fi

# 5. --list-declared includes the human docs
if [ -x "$HELPER" ]; then
  _DECL=$(bash "$HELPER" --list-declared 2>/dev/null)
  if printf '%s\n' "$_DECL" | grep -qx 'docs/philosophy.md' \
     && printf '%s\n' "$_DECL" | grep -qx 'docs/workflow.md' \
     && printf '%s\n' "$_DECL" | grep -qx 'docs/architecture.md' \
     && printf '%s\n' "$_DECL" | grep -qx 'README.md'; then
    ok "helper --list-declared includes the four human docs"
  else
    fail_test "helper --list-declared missing one of the human docs (got: $_DECL)"
  fi
else
  fail_test "helper --list-declared skipped (not executable)"
fi

# 6. --list-human-docs returns ONLY human-doc paths (CLAUDE.md is operational -> absent)
if [ -x "$HELPER" ]; then
  _HD=$(bash "$HELPER" --list-human-docs 2>/dev/null)
  if printf '%s\n' "$_HD" | grep -qx 'docs/philosophy.md' \
     && ! printf '%s\n' "$_HD" | grep -qx 'CLAUDE.md' \
     && ! printf '%s\n' "$_HD" | grep -qx 'CHANGELOG.md'; then
    ok "helper --list-human-docs returns only human-doc paths (operational docs excluded)"
  else
    fail_test "helper --list-human-docs wrong set (got: $_HD)"
  fi
else
  fail_test "helper --list-human-docs skipped (not executable)"
fi

# 7. --expand-whitelist includes doc-spec.md + every declared path
if [ -x "$HELPER" ]; then
  _WL=$(bash "$HELPER" --expand-whitelist 2>/dev/null)
  if printf '%s\n' "$_WL" | grep -qx 'doc-spec.md' \
     && printf '%s\n' "$_WL" | grep -qx 'docs/workflow.md' \
     && printf '%s\n' "$_WL" | grep -qx 'README.md'; then
    ok "helper --expand-whitelist includes doc-spec.md + declared paths"
  else
    fail_test "helper --expand-whitelist incomplete (got: $_WL)"
  fi
else
  fail_test "helper --expand-whitelist skipped (not executable)"
fi

# 8. --seed emits the portable Common section
if [ -x "$HELPER" ]; then
  _SEED=$(bash "$HELPER" --seed 2>/dev/null)
  if printf '%s' "$_SEED" | grep -qF 'what docs this repo carries'; then
    ok "helper --seed emits the portable Common section"
  else
    fail_test "helper --seed did not emit the Common section"
  fi
else
  fail_test "helper --seed skipped (not executable)"
fi

# 9. strict gate: bad schema_version
if [ -x "$HELPER" ]; then
  _T=$(mktemp -d)
  printf '```yaml\nschema_version: 9\ndocs:\n  - path: README.md\n    section: common\n    audit_class: human-doc\n```\n' > "$_T/doc-spec.md"
  _BAD=$(REPO_ROOT="$_T" bash "$HELPER" --validate 2>&1); _BRC=$?
  rm -rf "$_T"
  if [ "$_BRC" -ne 0 ] && printf '%s' "$_BAD" | grep -qF '[doc-sync-no-config]'; then
    ok "strict gate: bad schema_version HALTs with [doc-sync-no-config]"
  else
    fail_test "strict gate: bad schema_version did not halt (rc=$_BRC out=$_BAD)"
  fi
else
  fail_test "strict gate (schema) skipped (helper not executable)"
fi

# 10. strict gate: audit_class outside the enum
if [ -x "$HELPER" ]; then
  _T=$(mktemp -d)
  printf '```yaml\nschema_version: 1\ndocs:\n  - path: README.md\n    section: common\n    audit_class: not-a-class\n```\n' > "$_T/doc-spec.md"
  _BAD=$(REPO_ROOT="$_T" bash "$HELPER" --validate 2>&1); _BRC=$?
  rm -rf "$_T"
  if [ "$_BRC" -ne 0 ] && printf '%s' "$_BAD" | grep -qF '[doc-sync-no-config]'; then
    ok "strict gate: audit_class outside the enum HALTs with [doc-sync-no-config]"
  else
    fail_test "strict gate: bad audit_class did not halt (rc=$_BRC out=$_BAD)"
  fi
else
  fail_test "strict gate (enum) skipped (helper not executable)"
fi

# 11. functional portability: real helper reads cwd-toplevel doc-spec.md from a
# temp repo with NO scripts/ dir (the load-bearing property the deployed
# _cj-shared resolution depends on).
if [ -x "$HELPER" ]; then
  _TMP_REPO=$(mktemp -d 2>/dev/null || mktemp -d -t docspec) || _TMP_REPO=""
  if [ -n "$_TMP_REPO" ] && [ -d "$_TMP_REPO" ]; then
    (
      git -C "$_TMP_REPO" init -q 2>/dev/null
      cat > "$_TMP_REPO/doc-spec.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: README.md
    section: common
    audit_class: human-doc
```
EOF
      cd "$_TMP_REPO" || exit 3
      _OUT=$(bash "$HELPER" --validate 2>&1); _RC=$?
      [ "$_RC" -eq 0 ] || { echo "rc=$_RC out=$_OUT"; exit 1; }
      printf '%s' "$_OUT" | grep -qF 'OK schema_version=1' || { echo "unexpected: $_OUT"; exit 2; }
      exit 0
    )
    _FRC=$?
    rm -rf "$_TMP_REPO"
    if [ "$_FRC" -eq 0 ]; then
      ok "real helper reads cwd-toplevel doc-spec.md (portable: ran from a temp repo with no scripts/ dir)"
    else
      fail_test "real helper not cwd-portable (--validate from temp repo failed, rc=$_FRC)"
    fi
  else
    fail_test "could not create temp repo for portability test"
  fi
else
  fail_test "helper portability test skipped (not executable)"
fi

# 12. self-bootstrap regression (E1/AC-7): --seed with NO doc-spec.md present
# must exit 0 AND emit a doc-spec.md that PASSES --validate. The original
# gate-before-dispatch ran the "doc-spec.md must exist" gate on --seed, so --seed
# emitted a halt string the skill redirected into the new file (corrupt). Run in
# a temp repo with NO doc-spec.md and NO templates/ (forces the embedded heredoc).
if [ -x "$HELPER" ]; then
  _T=$(mktemp -d)
  git -C "$_T" init -q 2>/dev/null || true
  REPO_ROOT="$_T" bash "$HELPER" --seed > "$_T/doc-spec.md" 2>/dev/null; _SRC=$?
  _SVAL=$(REPO_ROOT="$_T" bash "$HELPER" --validate 2>&1); _SVRC=$?
  rm -rf "$_T"
  if [ "$_SRC" -eq 0 ] && [ "$_SVRC" -eq 0 ] && printf '%s' "$_SVAL" | grep -qF 'OK schema_version='; then
    ok "self-bootstrap: --seed with no doc-spec.md emits a VALID doc-spec.md (exit 0, passes --validate)"
  else
    fail_test "self-bootstrap broken: --seed rc=$_SRC, --validate rc=$_SVRC, out=$_SVAL"
  fi
else
  fail_test "self-bootstrap regression skipped (helper not executable)"
fi

# 13. no-drift: the embedded heredoc seed (used when templates/ is absent, i.e. a
# consumer repo) must be byte-identical to the published templates/doc-spec-common.md
# artifact a human copies.
_SEED_ARTIFACT="$REPO_ROOT/templates/doc-spec-common.md"
if [ -x "$HELPER" ] && [ -f "$_SEED_ARTIFACT" ]; then
  _T=$(mktemp -d)   # no templates/ here -> --seed falls back to the heredoc
  REPO_ROOT="$_T" bash "$HELPER" --seed > "$_T/seed.md" 2>/dev/null
  if diff -q "$_T/seed.md" "$_SEED_ARTIFACT" >/dev/null 2>&1; then
    ok "no-drift: embedded --seed heredoc == templates/doc-spec-common.md"
  else
    fail_test "drift: embedded --seed heredoc != templates/doc-spec-common.md"
    diff "$_T/seed.md" "$_SEED_ARTIFACT" | head -8 >&2 || true
  fi
  rm -rf "$_T"
else
  fail_test "no-drift test skipped (helper or templates/doc-spec-common.md missing)"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-document-release-config"
  exit 0
else
  echo "FAIL: cj-document-release-config ($ERRORS error(s))"
  exit 1
fi
