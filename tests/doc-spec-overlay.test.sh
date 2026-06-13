#!/usr/bin/env bash
# tests/doc-spec-overlay.test.sh
#
# Regression test for the two-tier doc-spec registry (F000060): the general
# spec/doc-spec.md (== doc-spec.sh --seed, byte-identical) merged with the
# optional spec/doc-spec-custom.md overlay by scripts/doc-spec.sh.
#
# Asserts:
#   1. live tree: --validate exits 0 on the MERGED registry; the merged
#      --list-declared carries general AND overlay paths; --render custom
#      renders the overlay rows; --list-front-table-docs lists the seed's
#      flagged docs
#   2. seed 3-way byte identity: the embedded --seed heredoc (templates/
#      absent) == spec/doc-spec.md == templates/doc-spec-common.md
#   3. overlay-absent fixture: general-only results, no finding, no error
#   4. overlay-present fixture: merged list + render-custom from the overlay
#   5. duplicate path across the two files => --validate halts
#      [doc-sync-no-config] naming the duplicate
#   6. present-but-invalid overlay (bad audit_class) => --validate halts
#   7. DOC_SPEC_PATH override stays hermetic: the overlay resolves NEXT TO the
#      overridden general file, never the live repo's overlay
#   8. --check-on-disk battery (the audit Stage-1 engine): clean fixture =>
#      all 6 check lines PASS + CHECKS_RUN=6 + FINDINGS=0 + exit 0; SEVEN
#      seeded violations (missing declared doc; orphan in docs/; orphan in
#      spec/ — a non-self-declaring overlay; undeclared root *.md; work-item
#      ID in a human-doc; missing front table; view-table drift) each flip
#      EXACTLY their own `FINDING: stage1/<id>` + FINDINGS=1 + exit 1;
#      registry-absent => REGISTRY=absent + exit 0 (probe before parse
#      gates); invalid registry => [doc-sync-no-config] + exit 1
#
# Temp-dir isolated; never mutates the live tree.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/doc-spec.sh"

_TMPS=""
mk_tmp() {
  _d=$(mktemp -d -t doc-spec-overlay.XXXXXX)
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

echo "=== doc-spec two-tier overlay merge assertions ==="

[ -x "$HELPER" ] || { fail_test "scripts/doc-spec.sh missing or not executable"; echo "FAIL: doc-spec-overlay ($ERRORS error(s))"; exit 1; }

# 1. live tree: merged validate + lists + render
_V=$(bash "$HELPER" --validate 2>&1); _VRC=$?
if [ "$_VRC" -eq 0 ] && printf '%s' "$_V" | grep -qF 'OK schema_version=1'; then
  ok "live --validate exits 0 on the merged registry"
else
  fail_test "live --validate failed (rc=$_VRC): $_V"
fi

_LD=$(bash "$HELPER" --list-declared 2>/dev/null)
if printf '%s\n' "$_LD" | grep -qx 'docs/philosophy.md' \
   && printf '%s\n' "$_LD" | grep -qx 'spec/test-spec.md' \
   && printf '%s\n' "$_LD" | grep -qx 'spec/gate-spec.md' \
   && printf '%s\n' "$_LD" | grep -qx 'spec/doc-spec-custom.md' \
   && printf '%s\n' "$_LD" | grep -qx 'spec/test-spec-custom.md'; then
  ok "live --list-declared carries general (philosophy, test-spec) AND overlay (gate-spec, both overlay self-rows) paths"
else
  fail_test "live --list-declared missing merged paths (got: $(printf '%s' "$_LD" | tr '\n' ' '))"
fi

_RC_OUT=$(bash "$HELPER" --render custom 2>/dev/null)
if printf '%s\n' "$_RC_OUT" | grep -qF 'spec/gate-spec.md' \
   && printf '%s\n' "$_RC_OUT" | grep -qF 'CONTRIBUTING.md' \
   && printf '%s\n' "$_RC_OUT" | grep -qF 'spec/permission-policy.md'; then
  ok "live --render custom renders the overlay's migrated rows"
else
  fail_test "live --render custom missing overlay rows: $_RC_OUT"
fi
if printf '%s\n' "$_RC_OUT" | grep -qF 'docs/philosophy.md'; then
  fail_test "live --render custom leaked a section:common row"
else
  ok "live --render custom carries no section:common rows"
fi

_FT=$(bash "$HELPER" --list-front-table-docs 2>/dev/null)
if [ "$(printf '%s\n' "$_FT" | grep -c .)" -eq 2 ] \
   && printf '%s\n' "$_FT" | grep -qx 'docs/philosophy.md' \
   && printf '%s\n' "$_FT" | grep -qx 'docs/workflow.md'; then
  ok "live --list-front-table-docs == the seed's two flagged docs"
else
  fail_test "front-table list wrong (got: $(printf '%s' "$_FT" | tr '\n' ' '))"
fi

# 2. seed 3-way byte identity (heredoc forced via empty REPO_ROOT temp)
_S=$(mk_tmp)
REPO_ROOT="$_S" bash "$HELPER" --seed > "$_S/seed-heredoc.md" 2>/dev/null
if cmp -s "$_S/seed-heredoc.md" "$REPO_ROOT/spec/doc-spec.md"; then
  ok "seed (embedded heredoc) == spec/doc-spec.md byte-for-byte (general file IS the seed)"
else
  fail_test "spec/doc-spec.md != --seed output (the general file must be byte-identical to the seed)"
fi
if cmp -s "$_S/seed-heredoc.md" "$REPO_ROOT/templates/doc-spec-common.md"; then
  ok "seed (embedded heredoc) == templates/doc-spec-common.md byte-for-byte"
else
  fail_test "templates/doc-spec-common.md != --seed output (3-way lockstep broken)"
fi

# 3. overlay-absent fixture: general-only results, no finding
_GA=$(mk_tmp)
bash "$HELPER" --seed > "$_GA/doc-spec.md" 2>/dev/null
_GA_V=$(REPO_ROOT="$_GA" bash "$HELPER" --validate 2>&1); _GA_RC=$?
if [ "$_GA_RC" -eq 0 ]; then
  ok "overlay-absent fixture: --validate exits 0 (nothing to merge, no finding)"
else
  fail_test "overlay-absent fixture errored (rc=$_GA_RC): $_GA_V"
fi
_GA_C=$(REPO_ROOT="$_GA" bash "$HELPER" --render custom 2>/dev/null | { grep -c '^| ' || true; })
# 2 = header + delimiter rows only (no data rows render with a leading '| path')
if [ "${_GA_C:-0}" -eq 0 ]; then
  ok "overlay-absent fixture: --render custom has no custom data rows"
else
  # header rows start with '| Doc' / '|---'; data rows are '| <path> |'
  _GA_DATA=$(REPO_ROOT="$_GA" bash "$HELPER" --render custom 2>/dev/null | { grep -vc '^| Doc\|^|---' || true; })
  if [ "${_GA_DATA:-0}" -eq 0 ]; then
    ok "overlay-absent fixture: --render custom has no custom data rows"
  else
    fail_test "overlay-absent fixture rendered unexpected custom data rows"
  fi
fi

# 4. overlay-present fixture: merged list + render-custom from the overlay
cat > "$_GA/doc-spec-custom.md" <<'EOF'
# overlay fixture
```yaml
schema_version: 1
docs:
  - path: EXTRA.md
    section: custom
    audit_class: operational
    purpose: "An overlay fixture doc."
    requirement: "Present."
```
EOF
_GA_LD=$(REPO_ROOT="$_GA" bash "$HELPER" --list-declared 2>/dev/null)
if printf '%s\n' "$_GA_LD" | grep -qx 'EXTRA.md' && printf '%s\n' "$_GA_LD" | grep -qx 'README.md'; then
  ok "overlay-present fixture: --list-declared is the MERGE (general + overlay row)"
else
  fail_test "overlay-present fixture merge broken (got: $(printf '%s' "$_GA_LD" | tr '\n' ' '))"
fi
if REPO_ROOT="$_GA" bash "$HELPER" --render custom 2>/dev/null | grep -qF 'EXTRA.md'; then
  ok "overlay-present fixture: --render custom reads the overlay"
else
  fail_test "overlay-present fixture: --render custom missing the overlay row"
fi
if REPO_ROOT="$_GA" bash "$HELPER" --expand-whitelist 2>/dev/null | grep -qx 'EXTRA.md'; then
  ok "overlay-present fixture: --expand-whitelist includes the overlay path"
else
  fail_test "overlay-present fixture: --expand-whitelist missing the overlay path"
fi

# 5. duplicate path across the two files => --validate halts
cat > "$_GA/doc-spec-custom.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: README.md
    section: custom
    audit_class: operational
    purpose: "Duplicate of a general row."
    requirement: "Present."
```
EOF
_DUP=$(REPO_ROOT="$_GA" bash "$HELPER" --validate 2>&1); _DUP_RC=$?
if [ "$_DUP_RC" -ne 0 ] && printf '%s' "$_DUP" | grep -qF '[doc-sync-no-config]' \
   && printf '%s' "$_DUP" | grep -qF 'duplicate path' \
   && printf '%s' "$_DUP" | grep -qF 'README.md'; then
  ok "duplicate path across general + overlay halts [doc-sync-no-config] naming the path"
else
  fail_test "duplicate-path guard did not fire (rc=$_DUP_RC): $_DUP"
fi

# 6. present-but-invalid overlay halts
cat > "$_GA/doc-spec-custom.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: BAD.md
    section: custom
    audit_class: not-a-class
```
EOF
_BAD=$(REPO_ROOT="$_GA" bash "$HELPER" --validate 2>&1); _BAD_RC=$?
if [ "$_BAD_RC" -ne 0 ] && printf '%s' "$_BAD" | grep -qF '[doc-sync-no-config]' \
   && printf '%s' "$_BAD" | grep -qF 'overlay'; then
  ok "present-but-invalid overlay halts [doc-sync-no-config] naming the overlay"
else
  fail_test "invalid-overlay gate did not fire (rc=$_BAD_RC): $_BAD"
fi
rm -f "$_GA/doc-spec-custom.md"

# 7. DOC_SPEC_PATH override stays hermetic (overlay resolves NEXT TO the override)
_H=$(mk_tmp)
bash "$HELPER" --seed > "$_H/doc-spec.md" 2>/dev/null
_H_LD=$(DOC_SPEC_PATH="$_H/doc-spec.md" bash "$HELPER" --list-declared 2>/dev/null)
if printf '%s\n' "$_H_LD" | grep -qx 'spec/gate-spec.md'; then
  fail_test "DOC_SPEC_PATH override leaked the live repo's overlay rows (not hermetic)"
else
  ok "DOC_SPEC_PATH override is hermetic (live overlay rows NOT merged into the temp parse)"
fi
cat > "$_H/doc-spec-custom.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: SIBLING.md
    section: custom
    audit_class: operational
    purpose: "Sibling overlay of an overridden general file."
    requirement: "Present."
```
EOF
_H_LD2=$(DOC_SPEC_PATH="$_H/doc-spec.md" bash "$HELPER" --list-declared 2>/dev/null)
if printf '%s\n' "$_H_LD2" | grep -qx 'SIBLING.md'; then
  ok "the overlay resolves next to the overridden general file (sibling merge)"
else
  fail_test "sibling overlay of an overridden general file was not merged"
fi

# 8. --check-on-disk battery (the audit Stage-1 engine; F000061)

# Fixture builder: a COMPLETE clean repo for the seeded general contract —
# every declared doc present, front-table docs open with a table, generated
# views' table blocks match fresh --render output. Echoes the fixture dir.
mk_cod_fixture() {
  _cf=$(mk_tmp)
  mkdir -p "$_cf/spec" "$_cf/docs"
  bash "$HELPER" --seed > "$_cf/spec/doc-spec.md" 2>/dev/null
  printf '# philosophy\n\n| Principle | Summary |\n|---|---|\n| 1 | first |\n\n## Principle 1\n\nBody.\n' > "$_cf/docs/philosophy.md"
  printf '# workflow\n\n| Workflow | Entry |\n|---|---|\n| build | /go |\n\n## Flows\n\nBody.\n' > "$_cf/docs/workflow.md"
  printf '# architecture\n\nMachinery prose.\n' > "$_cf/docs/architecture.md"
  printf '# readme\n\nFolder structure + getting started.\n' > "$_cf/README.md"
  printf '# agent instructions\n' > "$_cf/CLAUDE.md"
  printf '# changelog\n' > "$_cf/CHANGELOG.md"
  printf '# todos\n' > "$_cf/TODOS.md"
  printf '# test contract stub\n' > "$_cf/spec/test-spec.md"
  { printf '<!-- view stub -->\n# general view\n\nprose\n\n'; REPO_ROOT="$_cf" bash "$HELPER" --render general 2>/dev/null; } > "$_cf/docs/doc-general.md"
  { printf '<!-- view stub -->\n# custom view\n\nprose\n\n'; REPO_ROOT="$_cf" bash "$HELPER" --render custom 2>/dev/null; } > "$_cf/docs/doc-custom.md"
  printf '%s' "$_cf"
}

# Runs --check-on-disk on $1; asserts FINDINGS=1 + exit 1 + EXACTLY the one
# expected `FINDING: stage1/<id>` ($2) fires — the isolation contract.
assert_one_finding() {
  _af_dir="$1"; _af_id="$2"; _af_label="$3"
  _af_out=$(REPO_ROOT="$_af_dir" bash "$HELPER" --check-on-disk 2>&1); _af_rc=$?
  if [ "$_af_rc" -eq 1 ] \
     && printf '%s\n' "$_af_out" | grep -qF "FINDING: stage1/$_af_id" \
     && printf '%s\n' "$_af_out" | grep -qx 'FINDINGS=1'; then
    ok "seeded violation ($_af_label) flips exactly FINDING: stage1/$_af_id (FINDINGS=1, exit 1)"
  else
    fail_test "seeded violation ($_af_label) not isolated to stage1/$_af_id (rc=$_af_rc): $_af_out"
  fi
}

# 8a. clean fixture: all 6 PASS, CHECKS_RUN=6, FINDINGS=0, exit 0
_CF=$(mk_cod_fixture)
_COD=$(REPO_ROOT="$_CF" bash "$HELPER" --check-on-disk 2>&1); _COD_RC=$?
if [ "$_COD_RC" -eq 0 ] \
   && [ "$(printf '%s\n' "$_COD" | grep -c '^check: .* — PASS$')" -eq 6 ] \
   && printf '%s\n' "$_COD" | grep -qx 'CHECKS_RUN=6' \
   && printf '%s\n' "$_COD" | grep -qx 'FINDINGS=0'; then
  ok "--check-on-disk clean fixture: 6 PASS lines + CHECKS_RUN=6 + FINDINGS=0 + exit 0"
else
  fail_test "--check-on-disk clean fixture not clean (rc=$_COD_RC): $_COD"
fi

# 8b. violation 1 — missing declared doc
_V=$(mk_cod_fixture); rm -f "$_V/docs/architecture.md"
assert_one_finding "$_V" "declared-exists" "missing declared doc"

# 8c. violation 2 — orphan in docs/
_V=$(mk_cod_fixture); printf 'stray doc\n' > "$_V/docs/extra.md"
assert_one_finding "$_V" "orphans" "orphan in docs/"

# 8d. violation 3 — orphan in spec/: a NON-SELF-DECLARING overlay (declares
# EXTRA.md but not itself => the overlay file IS the orphan, by design). The
# custom view is regenerated against the merged registry and EXTRA.md is
# created, so the ONLY finding is the orphan overlay.
_V=$(mk_cod_fixture)
cat > "$_V/spec/doc-spec-custom.md" <<'EOF'
```yaml
schema_version: 1
docs:
  - path: EXTRA.md
    section: custom
    audit_class: operational
    purpose: "An overlay-declared extra doc."
    requirement: "Present."
```
EOF
printf 'extra doc\n' > "$_V/EXTRA.md"
{ printf '<!-- view stub -->\n# custom view\n\nprose\n\n'; REPO_ROOT="$_V" bash "$HELPER" --render custom 2>/dev/null; } > "$_V/docs/doc-custom.md"
_OV_OUT=$(REPO_ROOT="$_V" bash "$HELPER" --check-on-disk 2>&1); _OV_RC=$?
if [ "$_OV_RC" -eq 1 ] \
   && printf '%s\n' "$_OV_OUT" | grep -qF 'FINDING: stage1/orphans' \
   && printf '%s\n' "$_OV_OUT" | grep -qF 'spec/doc-spec-custom.md' \
   && printf '%s\n' "$_OV_OUT" | grep -qx 'FINDINGS=1'; then
  ok "seeded violation (non-self-declaring overlay) is an orphan finding NAMING the overlay (FINDINGS=1)"
else
  fail_test "non-self-declaring overlay not flagged as the lone orphan (rc=$_OV_RC): $_OV_OUT"
fi

# 8e. violation 4 — undeclared root *.md
_V=$(mk_cod_fixture); printf 'stray root\n' > "$_V/STRAY.md"
assert_one_finding "$_V" "root-declared" "undeclared root *.md"

# 8f. violation 5 — work-item ID in a human-doc
_V=$(mk_cod_fixture); printf '\nShipped by F000999.\n' >> "$_V/docs/architecture.md"
assert_one_finding "$_V" "human-doc-ids" "work-item ID in a human-doc"

# 8g. violation 6 — missing front table on a front_table: required doc
_V=$(mk_cod_fixture)
printf '# philosophy\n\nNo table here.\n\n## Principle 1\n\nBody.\n' > "$_V/docs/philosophy.md"
assert_one_finding "$_V" "front-table" "missing front table"

# 8h. violation 7 — view-table drift (a hand-added row in the generated view)
_V=$(mk_cod_fixture)
printf '| fake.md | hand-added | drift |\n' >> "$_V/docs/doc-general.md"
assert_one_finding "$_V" "views-render" "view-table drift"

# 8i. registry-absent => REGISTRY=absent + exit 0 (probe BEFORE parse gates)
_AB=$(mk_tmp)
_AB_OUT=$(REPO_ROOT="$_AB" bash "$HELPER" --check-on-disk 2>&1); _AB_RC=$?
if [ "$_AB_RC" -eq 0 ] && printf '%s\n' "$_AB_OUT" | grep -qx 'REGISTRY=absent'; then
  ok "--check-on-disk registry-absent: REGISTRY=absent + exit 0 (no [doc-sync-no-config] halt)"
else
  fail_test "--check-on-disk registry-absent mis-handled (rc=$_AB_RC): $_AB_OUT"
fi

# 8j. present-but-invalid registry => [doc-sync-no-config] + exit 1
printf 'garbage, no yaml block\n' > "$_AB/doc-spec.md"
_IV_OUT=$(REPO_ROOT="$_AB" bash "$HELPER" --check-on-disk 2>&1); _IV_RC=$?
if [ "$_IV_RC" -eq 1 ] && printf '%s\n' "$_IV_OUT" | grep -qF '[doc-sync-no-config]'; then
  ok "--check-on-disk present-but-invalid registry keeps the [doc-sync-no-config] halt (exit 1)"
else
  fail_test "--check-on-disk invalid-registry posture broken (rc=$_IV_RC): $_IV_OUT"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: doc-spec-overlay"
  exit 0
else
  echo "FAIL: doc-spec-overlay ($ERRORS error(s))"
  exit 1
fi
