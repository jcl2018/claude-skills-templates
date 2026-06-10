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
#   6b. helper --list-front-table-docs emits ONLY front_table: required paths
#   7. helper --expand-whitelist includes doc-spec.md + every declared path
#   8. helper --seed emits the portable Common section
#   8b. growth-safe seed assertions: the seed registry (via the DOC_SPEC_PATH
#       temp-file idiom) --list-declared-includes the general-contract docs
#       (CLAUDE.md, TODOS.md, docs/doc-general.md) AND the seed body states the
#       literal rule "General docs are required"
#   9. strict gate: a bad schema_version HALTs with [doc-sync-no-config]
#  10. strict gate: an audit_class outside the enum HALTs with [doc-sync-no-config]
#  11. functional portability: the real helper reads the cwd-toplevel doc-spec.md
#      (run from a temp repo with no scripts/ dir)
#  12. self-bootstrap regression: --seed with NO doc-spec.md present exits 0 and
#      emits a doc-spec.md that PASSES --validate (the gate-before-dispatch bug)
#  13. no-drift: the embedded --seed heredoc == templates/doc-spec-common.md
#  14. cold-repo guard: a synthetic temp repo with doc-spec.md but NO
#      skills-catalog.json runs the Step 6.7.2 guard path with no `jq: Could not
#      open file` error and leaves no stray .cj-goal-feature/ artifact (S000097)

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
# Resolve the registry spec/-then-root (mirrors the helper's back-compat fallback).
DOC_SPEC="$REPO_ROOT/spec/doc-spec.md"
[ -f "$DOC_SPEC" ] || DOC_SPEC="$REPO_ROOT/doc-spec.md"
HELPER="$REPO_ROOT/scripts/doc-spec.sh"

echo "=== doc-spec.md registry + doc-spec.sh helper assertions ==="

# 1. doc-spec.md exists (at spec/ or, for a root-only consumer, at root)
if [ -f "$DOC_SPEC" ]; then
  ok "doc-spec.md registry present ($DOC_SPEC)"
else
  fail_test "doc-spec.md missing (looked in spec/ then root): $DOC_SPEC"
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
    ok "helper --list-declared includes the core human docs"
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

# 6b. --list-front-table-docs emits ONLY the front_table: required paths (F000052).
# Synthetic temp registry: one entry WITH front_table: required (docs/philosophy.md)
# and one WITHOUT (docs/architecture.md). Asserts the flagged path is emitted and
# the unflagged one is not — proving the new subcommand filters on the field.
if [ -x "$HELPER" ]; then
  _T=$(mktemp -d)
  printf '```yaml\nschema_version: 1\ndocs:\n  - path: docs/philosophy.md\n    section: common\n    audit_class: human-doc\n    front_table: required\n  - path: docs/architecture.md\n    section: common\n    audit_class: human-doc\n```\n' > "$_T/doc-spec.md"
  _FT=$(REPO_ROOT="$_T" bash "$HELPER" --list-front-table-docs 2>/dev/null)
  rm -rf "$_T"
  if printf '%s\n' "$_FT" | grep -qx 'docs/philosophy.md' \
     && ! printf '%s\n' "$_FT" | grep -qx 'docs/architecture.md'; then
    ok "helper --list-front-table-docs emits only front_table: required paths"
  else
    fail_test "helper --list-front-table-docs wrong set (expected only docs/philosophy.md, got: $_FT)"
  fi
else
  fail_test "helper --list-front-table-docs skipped (not executable)"
fi

# 7. --expand-whitelist includes the registry (spec/doc-spec.md) + every declared path
if [ -x "$HELPER" ]; then
  _WL=$(bash "$HELPER" --expand-whitelist 2>/dev/null)
  if { printf '%s\n' "$_WL" | grep -qx 'spec/doc-spec.md' || printf '%s\n' "$_WL" | grep -qx 'doc-spec.md'; } \
     && printf '%s\n' "$_WL" | grep -qx 'docs/workflow.md' \
     && printf '%s\n' "$_WL" | grep -qx 'README.md'; then
    ok "helper --expand-whitelist includes the doc-spec registry + declared paths"
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

# 8b. growth-safe seed assertions (general-docs-required): the seed registry
# declares the general-contract set and states the required rule. Seed written
# to a temp file and re-read via the DOC_SPEC_PATH override (reuses the parser —
# no hand-parsing of seed yaml). Inclusion-based, so future seed growth breaks
# nothing; dropping a seed entry or the rule bullet regresses loudly.
if [ -x "$HELPER" ]; then
  _T=$(mktemp -d)
  bash "$HELPER" --seed > "$_T/doc-spec.md" 2>/dev/null
  _SD=$(DOC_SPEC_PATH="$_T/doc-spec.md" bash "$HELPER" --list-declared 2>/dev/null)
  if printf '%s\n' "$_SD" | grep -qx 'CLAUDE.md' \
     && printf '%s\n' "$_SD" | grep -qx 'TODOS.md' \
     && printf '%s\n' "$_SD" | grep -qx 'docs/doc-general.md'; then
    ok "seed registry declares the general-contract docs (CLAUDE.md, TODOS.md, docs/doc-general.md)"
  else
    fail_test "seed registry missing a general-contract doc (got: $_SD)"
  fi
  if grep -qF 'General docs are required' "$_T/doc-spec.md"; then
    ok "seed states the rule: 'General docs are required'"
  else
    fail_test "seed missing the literal rule phrase 'General docs are required'"
  fi
  rm -rf "$_T"
else
  fail_test "growth-safe seed assertions skipped (helper not executable)"
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

# 14. cold-repo guard (S000097/AC-2): the Step 6.7.2 skill-MD audit half reads
# skills-catalog.json, which is workbench-only. In a consumer repo with no
# catalog the guard must skip cleanly — no `jq: Could not open file` stderr — and
# the Step 6.7.4 scratch write must be skipped so no stray (un-gitignored)
# .cj-goal-feature/ artifact is left behind. The guard lives as bash in
# skills/CJ_document-release/SKILL.md Step 6.7.2/6.7.4; this row reproduces that
# guard logic faithfully and asserts both properties in a synthetic temp repo
# with a doc-spec.md but NO skills-catalog.json.
_SKILL_MD="$REPO_ROOT/skills/CJ_document-release/SKILL.md"
if command -v jq >/dev/null 2>&1; then
  _T=$(mktemp -d)
  git -C "$_T" init -q 2>/dev/null || true
  # doc-spec.md present, skills-catalog.json deliberately ABSENT (cold repo).
  cat > "$_T/doc-spec.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: README.md
    section: common
    audit_class: human-doc
```
EOF
  # Reproduce the Step 6.7.2 guard (catalog read) + the Step 6.7.4 scratch-skip,
  # exactly as the SKILL.md prescribes. Run with `set -e` to PROVE no abort is
  # introduced by the guarded path. Capture stderr to assert no jq error noise.
  _ERR_FILE="$_T/stderr.log"
  (
    cd "$_T" || exit 9
    set -e
    _DS_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
    _CATALOG="$_DS_REPO_ROOT/skills-catalog.json"
    if [ ! -f "$_CATALOG" ]; then
      CATALOG_PRESENT=false
      echo "CJ_document-release: no skills-catalog.json — non-workbench mode; skipping the skill-MD audit half (registry-doc audit still runs)."
    else
      CATALOG_PRESENT=true
      SKILL_NAMES=$(jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' "$_CATALOG" 2>/dev/null || true)
      for _name in $SKILL_NAMES; do :; done
    fi
    # Step 6.7.4 scratch-write skip when CATALOG_PRESENT=false.
    if [ "${CATALOG_PRESENT:-true}" = "true" ]; then
      mkdir -p "$_DS_REPO_ROOT/.cj-goal-feature"
      echo "verdicts" > "$_DS_REPO_ROOT/.cj-goal-feature/registered-doc-verdicts.md"
    fi
  ) >/dev/null 2>"$_ERR_FILE"
  _GRC=$?
  # Assertions: (a) guard exited 0 (no set -e abort); (b) no jq "Could not open
  # file" stderr; (c) no stray .cj-goal-feature/ artifact in the cold repo.
  if grep -q 'Could not open file' "$_ERR_FILE" 2>/dev/null; then _JQ_NOISE=1; else _JQ_NOISE=0; fi
  if [ "$_GRC" -eq 0 ] \
     && [ "$_JQ_NOISE" -eq 0 ] \
     && [ ! -e "$_T/.cj-goal-feature" ]; then
    ok "cold-repo guard: no skills-catalog.json -> clean skip, no jq noise, no stray .cj-goal-feature/ artifact"
  else
    fail_test "cold-repo guard failed (rc=$_GRC jq_noise=$_JQ_NOISE scratch_exists=$([ -e "$_T/.cj-goal-feature" ] && echo yes || echo no))"
  fi
  # Sanity: the SKILL.md actually carries the guard literal (catches a regression
  # where the guard is removed from the prose the agent executes).
  if grep -qF 'no skills-catalog.json — non-workbench mode' "$_SKILL_MD" 2>/dev/null; then
    ok "SKILL.md Step 6.7.2 carries the non-workbench catalog guard note"
  else
    fail_test "SKILL.md Step 6.7.2 missing the non-workbench catalog guard note"
  fi
  rm -rf "$_T"
else
  fail_test "cold-repo guard test skipped (jq not available)"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-document-release-config"
  exit 0
else
  echo "FAIL: cj-document-release-config ($ERRORS error(s))"
  exit 1
fi
