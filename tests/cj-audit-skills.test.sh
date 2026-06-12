#!/usr/bin/env bash
# tests/cj-audit-skills.test.sh
#
# Regression test for the /CJ_doc_audit + /CJ_test_audit engines (F000060),
# end-to-end in a bare temp git repo. The skills are markdown-driven; this
# suite executes their DETERMINISTIC halves exactly as the SKILL.md files
# script them (seed delivery, merged validate, conformance/coverage), so the
# contract the agent executes inline at qa.md Step 8.6c/d is proven runnable.
#
# Asserts:
#   1. skill structure: both SKILL.md + USAGE.md exist; frontmatter names are
#      EXACTLY CJ_doc_audit / CJ_test_audit; the dual-posture contract + the
#      report literals (DOC_AUDIT:/TEST_AUDIT:, FINDINGS=, DOCS_AUDITED=/
#      UNITS_AUDITED=, seeded:) are documented; catalog entries + routing
#      lines present; qa.md Step 8.6a-d wired with the extended RESULT +
#      AUDIT_FINDINGS block
#   2. bare-repo seed delivery: first run creates spec/ + BOTH contract files
#      (seeded: yes semantics — files born valid, byte-identical to --seed);
#      second run is idempotent (seeded: no — no re-seed, no mutation)
#   3. seeded violations produce findings: an orphan root doc + a work-item ID
#      planted in a human doc surface as conformance findings; an unregistered
#      test file in a units-declaring repo flips the coverage check
#   4. the clean workbench run is green: doc-spec --validate OK +
#      test-spec --validate OK + --check-coverage findings=0 on the live tree
#
# Temp-dir isolated; never mutates the live tree.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
DOC_ENGINE="$REPO_ROOT/scripts/doc-spec.sh"
TEST_ENGINE="$REPO_ROOT/scripts/test-spec.sh"

_TMPS=""
mk_tmp() {
  _d=$(mktemp -d -t cj-audit-skills.XXXXXX)
  _TMPS="$_TMPS $_d"
  printf '%s' "$_d"
}
# shellcheck disable=SC2317,SC2329  # invoked indirectly via the EXIT trap below
cleanup() {
  for _d in $_TMPS; do
    [ -n "$_d" ] && [ -d "$_d" ] && rm -rf "$_d"
  done
}
trap cleanup EXIT

echo "=== audit-skill (CJ_doc_audit / CJ_test_audit) engine assertions ==="

# 1. skill structure + wiring
for _sk in CJ_doc_audit CJ_test_audit; do
  _MD="$REPO_ROOT/skills/$_sk/SKILL.md"
  _UM="$REPO_ROOT/skills/$_sk/USAGE.md"
  if [ -f "$_MD" ] && [ -f "$_UM" ]; then
    ok "$_sk: SKILL.md + USAGE.md present"
  else
    fail_test "$_sk: SKILL.md or USAGE.md missing"
    continue
  fi
  if grep -qE "^name: $_sk$" "$_MD"; then
    ok "$_sk: frontmatter name is the exact skill name"
  else
    fail_test "$_sk: frontmatter name != $_sk"
  fi
  if grep -qF 'seeded: yes' "$_MD" && grep -qF 'seeded: no' "$_MD"; then
    ok "$_sk: documents the seeded: yes / seeded: no idempotence contract"
  else
    fail_test "$_sk: seeded: yes/no contract missing from SKILL.md"
  fi
  if grep -qiF 'cannot spawn subagents' "$_MD"; then
    ok "$_sk: documents the dual posture (inline-in-subagent vs standalone)"
  else
    fail_test "$_sk: dual-posture (nested-subagent wall) doc missing"
  fi
  if grep -qF "\"$_sk\"" "$REPO_ROOT/skills-catalog.json"; then
    ok "$_sk: catalog entry present"
  else
    fail_test "$_sk: catalog entry missing"
  fi
  if grep -qF "/$_sk" "$REPO_ROOT/rules/skill-routing.md"; then
    ok "$_sk: routing line present in rules/skill-routing.md"
  else
    fail_test "$_sk: routing line missing"
  fi
done
if grep -qF 'DOC_AUDIT:' "$REPO_ROOT/skills/CJ_doc_audit/SKILL.md" \
   && grep -qF 'DOCS_AUDITED=' "$REPO_ROOT/skills/CJ_doc_audit/SKILL.md"; then
  ok "CJ_doc_audit: report shape (DOC_AUDIT: + FINDINGS= + DOCS_AUDITED=) documented"
else
  fail_test "CJ_doc_audit: report shape literals missing"
fi
if grep -qF 'TEST_AUDIT:' "$REPO_ROOT/skills/CJ_test_audit/SKILL.md" \
   && grep -qF 'UNITS_AUDITED=' "$REPO_ROOT/skills/CJ_test_audit/SKILL.md"; then
  ok "CJ_test_audit: report shape (TEST_AUDIT: + FINDINGS= + UNITS_AUDITED=) documented"
else
  fail_test "CJ_test_audit: report shape literals missing"
fi

# qa.md Step 8.6 wiring (the QA fixture assertions)
_QA="$REPO_ROOT/skills/CJ_qa-work-item/qa.md"
if grep -qF '## Step 8.6:' "$_QA" \
   && grep -qF '### 8.6a' "$_QA" && grep -qF '### 8.6b' "$_QA" \
   && grep -qF '### 8.6c' "$_QA" && grep -qF '### 8.6d' "$_QA"; then
  ok "qa.md: Step 8.6 audit block with sub-steps a-d present"
else
  fail_test "qa.md: Step 8.6a-d block missing"
fi
if grep -qF 'AUDITS=doc:<ok|findings:n>,test:<ok|findings:n>,spec_updates:<summary>' "$_QA" \
   && grep -qF 'AUDIT_FINDINGS' "$_QA"; then
  ok "qa.md: extended RESULT (AUDITS= field) + fenced AUDIT_FINDINGS block documented"
else
  fail_test "qa.md: extended RESULT / AUDIT_FINDINGS contract missing"
fi
if grep -qF '[qa-audit-waived]' "$_QA" && grep -qF '[qa-audit-declined]' "$_QA"; then
  ok "qa.md: waiver/decline journal-line contract documented"
else
  fail_test "qa.md: [qa-audit-waived]/[qa-audit-declined] contract missing"
fi
# All four orchestrators carry the checkpoint marker (Check 22's surface)
for _mode_file in "skills/CJ_goal_feature/pipeline.md" "skills/CJ_goal_defect/pipeline.md" \
                  "skills/CJ_goal_task/pipeline.md" "skills/CJ_goal_todo_fix/SKILL.md"; do
  if grep -qF '[qa-audit-declined]' "$REPO_ROOT/$_mode_file"; then
    ok "$_mode_file carries the literal [qa-audit-declined] checkpoint marker"
  else
    fail_test "$_mode_file missing the [qa-audit-declined] marker"
  fi
done

# 2. bare-repo seed delivery (the Step 2 logic from both SKILL.md files,
# executed verbatim: temp-write -> validate -> mv into spec/).
_BR=$(mk_tmp)
git -C "$_BR" init -q 2>/dev/null || true

_deliver_doc_seed() {
  # replicates CJ_doc_audit SKILL.md Step 2; echoes "seeded: yes|no"
  if [ ! -f "$_BR/spec/doc-spec.md" ] && [ ! -f "$_BR/doc-spec.md" ]; then
    _T=$(mktemp -d)
    if bash "$DOC_ENGINE" --seed > "$_T/doc-spec.md" 2>/dev/null \
       && [ -s "$_T/doc-spec.md" ] \
       && DOC_SPEC_PATH="$_T/doc-spec.md" bash "$DOC_ENGINE" --validate >/dev/null 2>&1; then
      mkdir -p "$_BR/spec"
      mv "$_T/doc-spec.md" "$_BR/spec/doc-spec.md"
      rm -rf "$_T"
      echo "seeded: yes"
      return 0
    fi
    rm -rf "$_T"
    echo "seeded: failed"
    return 1
  fi
  echo "seeded: no"
}
_deliver_test_seed() {
  # replicates CJ_test_audit SKILL.md Step 2
  if [ ! -f "$_BR/spec/test-spec.md" ] && [ ! -f "$_BR/test-spec.md" ]; then
    _T=$(mktemp -d)
    if bash "$TEST_ENGINE" --seed > "$_T/test-spec.md" 2>/dev/null \
       && [ -s "$_T/test-spec.md" ] \
       && TEST_SPEC_PATH="$_T/test-spec.md" bash "$TEST_ENGINE" --validate >/dev/null 2>&1; then
      mkdir -p "$_BR/spec"
      mv "$_T/test-spec.md" "$_BR/spec/test-spec.md"
      rm -rf "$_T"
      echo "seeded: yes"
      return 0
    fi
    rm -rf "$_T"
    echo "seeded: failed"
    return 1
  fi
  echo "seeded: no"
}

_R1=$(_deliver_doc_seed); _R2=$(_deliver_test_seed)
if [ "$_R1" = "seeded: yes" ] && [ "$_R2" = "seeded: yes" ] \
   && [ -f "$_BR/spec/doc-spec.md" ] && [ -f "$_BR/spec/test-spec.md" ]; then
  ok "bare repo: first run creates spec/ + delivers BOTH contract seeds (seeded: yes)"
else
  fail_test "bare repo: seed delivery failed ($_R1 / $_R2)"
fi
if REPO_ROOT="$_BR" bash "$DOC_ENGINE" --validate >/dev/null 2>&1 \
   && REPO_ROOT="$_BR" bash "$TEST_ENGINE" --validate >/dev/null 2>&1; then
  ok "bare repo: both seeded registries validate clean (born valid)"
else
  fail_test "bare repo: a seeded registry does not validate"
fi
_SUM1=$(cat "$_BR/spec/doc-spec.md" "$_BR/spec/test-spec.md" | cksum)
_R3=$(_deliver_doc_seed); _R4=$(_deliver_test_seed)
_SUM2=$(cat "$_BR/spec/doc-spec.md" "$_BR/spec/test-spec.md" | cksum)
if [ "$_R3" = "seeded: no" ] && [ "$_R4" = "seeded: no" ] && [ "$_SUM1" = "$_SUM2" ]; then
  ok "bare repo: second run is idempotent (seeded: no; no re-seed, no byte changed)"
else
  fail_test "bare repo: second run not idempotent ($_R3 / $_R4)"
fi
# The seeded consumer's coverage posture: rules-only => named inactive note.
_CV=$(REPO_ROOT="$_BR" bash "$TEST_ENGINE" --check-coverage 2>&1); _CV_RC=$?
if [ "$_CV_RC" -eq 0 ] && printf '%s' "$_CV" | grep -qF 'coverage cross-check inactive'; then
  ok "bare repo: rules-only coverage reports the named inactive note (never findings)"
else
  fail_test "bare repo: rules-only coverage mis-reported (rc=$_CV_RC): $_CV"
fi

# 3. seeded violations produce findings.
# 3a. doc conformance: an undeclared root doc + a work-item ID in a human doc.
#     (Replicates the CJ_doc_audit Step 4 root-declared + no-ID checks.)
echo "stray" > "$_BR/STRAY.md"
mkdir -p "$_BR/docs"
printf '# stub\n\nShipped by F000999.\n' > "$_BR/docs/philosophy.md"
_DECL=$(REPO_ROOT="$_BR" bash "$DOC_ENGINE" --list-declared 2>/dev/null)
_F_COUNT=0
for _root_md in "$_BR"/*.md; do
  [ -e "$_root_md" ] || continue
  _b=$(basename "$_root_md")
  printf '%s\n' "$_DECL" | grep -qFx "$_b" || _F_COUNT=$((_F_COUNT + 1))
done
if [ "$_F_COUNT" -ge 1 ]; then
  ok "seeded violation: an undeclared root doc surfaces as a conformance finding (root-declared check)"
else
  fail_test "seeded violation: undeclared root doc NOT caught"
fi
_ID_HITS=0
while IFS= read -r _hd; do
  [ -n "$_hd" ] || continue
  [ -f "$_BR/$_hd" ] || continue
  grep -qE '[FSTD][0-9]{6}' "$_BR/$_hd" && _ID_HITS=$((_ID_HITS + 1))
done <<EOF
$(REPO_ROOT="$_BR" bash "$DOC_ENGINE" --list-human-docs 2>/dev/null)
EOF
if [ "$_ID_HITS" -ge 1 ]; then
  ok "seeded violation: a work-item ID planted in a human doc surfaces as a finding (no-ID lint)"
else
  fail_test "seeded violation: work-item ID in human doc NOT caught"
fi

# 3b. test coverage: declare a unit whose anchored runner is absent ->
#     --check-coverage flips red (the deterministic Step 4 of CJ_test_audit).
mkdir -p "$_BR/scripts" "$_BR/tests"
printf '#!/usr/bin/env bash\necho suite\n' > "$_BR/scripts/test.sh"
: > "$_BR/tests/zz-orphan.test.sh"
cat > "$_BR/spec/test-spec-custom.md" <<'EOF'
```yaml
schema_version: 1
units:
  - id: test-zz-orphan
    family: test
    label: "Orphan drill suite"
    anchor: "tests/zz-orphan.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A drill purpose."
```
EOF
_OV=$(REPO_ROOT="$_BR" TEST_SPEC_REVERSE_FLOOR=1 bash "$TEST_ENGINE" --check-coverage 2>&1); _OV_RC=$?
if [ "$_OV_RC" -ne 0 ] && printf '%s' "$_OV" | grep -qF 'test-zz-orphan' \
   && printf '%s' "$_OV" | grep -qF 'forward'; then
  ok "seeded violation: a units-declaring repo with an unwired test flips --check-coverage red"
else
  fail_test "seeded violation: unwired-test coverage finding NOT produced (rc=$_OV_RC): $_OV"
fi

# 4. clean workbench baseline is green (FINDINGS=0 semantics).
if bash "$DOC_ENGINE" --validate >/dev/null 2>&1; then
  ok "workbench baseline: merged doc-spec registry validates clean"
else
  fail_test "workbench baseline: doc-spec --validate failed"
fi
_WB=$(bash "$TEST_ENGINE" --check-coverage 2>&1); _WB_RC=$?
if [ "$_WB_RC" -eq 0 ] && printf '%s' "$_WB" | grep -qF 'findings=0'; then
  ok "workbench baseline: test-spec coverage cross-check clean (findings=0)"
else
  fail_test "workbench baseline: coverage not clean (rc=$_WB_RC): $_WB"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-audit-skills"
  exit 0
else
  echo "FAIL: cj-audit-skills ($ERRORS error(s))"
  exit 1
fi
