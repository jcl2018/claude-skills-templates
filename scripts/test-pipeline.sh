#!/usr/bin/env bash
# test-pipeline.sh — parse + validate the test-pipeline.md registry; render the
# generated human view; run the coverage cross-check.
#
# test-pipeline.md is the machine source of truth for the repo's verification
# surface: one registry row per verification unit (validate.sh checks in both ID
# namespaces + warning checks, registered tests/*.test.sh sub-suites, inline
# test.sh families, standalone suites, CI workflows, git hooks). It is the
# fourth member of the doc-spec -> permission-policy -> gate-spec spec-registry
# family. This helper parses that registry (awk only — no python/yaml
# dependency, portable to bash 3.2) and mirrors scripts/gate-spec.sh /
# scripts/doc-spec.sh. It is consumed by scripts/validate.sh (Check 23
# view-sync + Check 24 coverage), scripts/generate-doc-views.sh (the third
# generated view, docs/test-pipeline.md), and scripts/test.sh.
#
# Strict posture (registry-reading subcommands): test-pipeline.md missing OR no
# yaml registry OR more than one yaml fence OR schema_version unsupported OR a
# unit missing id/family/label/anchor/source/layer/disposition/trigger/purpose
# OR an enum violation OR a duplicate id OR a work-item ID in a rendered field
# (label/purpose)  ->  HALT with `[test-pipeline-no-config] <reason>` on stdout
# + exit 1.
#
# Subcommands:
#   --validate         exit 0 + print `OK schema_version=<n>` if the registry
#                      is valid; exit 1 + halt-emit otherwise. Includes the
#                      rendered-field work-item-ID lint (label + purpose), so
#                      an ID slip fails here — before the human-doc lint ever
#                      sees the rendered view.
#   --list-units       echo every declared unit id (registry order).
#   --render           emit the full generated markdown view (AUTO-GENERATED
#                      header, leading per-family summary table, the single
#                      gate-spec pointer line for the pipeline-gate layer,
#                      per-family unit tables). Deterministic; no timestamps.
#   --check-coverage   the Check 24 engine. Forward: every unit's `anchor`
#                      must grep -F in its declared `source` file. Reverse:
#                      every live `=== Check N:` banner / `# Error check N:` /
#                      `# Warning check` comment in scripts/validate.sh, every
#                      tests/*.test.sh on disk, every .github/workflows/*.yml,
#                      and every `install_hook <name>` invocation in
#                      scripts/setup-hooks.sh must resolve to exactly one
#                      registry row in its namespace. Floor: reverse
#                      extraction must yield >= 20 tokens. Findings print as
#                      `FINDING: ...` lines; exit 1 on any finding.
#   --help|-h
#
# family closed enum:      validate | test | test-deploy | eval | windows-smoke | ci | hook.
# layer closed enum:       local-hook | ci.
# disposition closed enum: hard-fail | advisory.
# trigger token enum:      pre-commit | post-merge | pr-ci | push-main | nightly | manual.
# schema_version supported: 1.

set -eu

# Strip CRLF from any command output on Windows. No-op on Unix.
_strip_cr() { tr -d '\r'; }

# Resolve repo root (allows REPO_ROOT override for tests / temp-dir drills).
REPO_ROOT_RESOLVED="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"
# Resolution order: TEST_PIPELINE_PATH env override (outermost) ->
# spec/test-pipeline.md (this repo) -> root test-pipeline.md (root-only
# consumers). Same spec/-then-root idiom as the three sibling helpers.
TEST_PIPELINE_PATH="${TEST_PIPELINE_PATH:-$( [ -f "$REPO_ROOT_RESOLVED/spec/test-pipeline.md" ] && echo "$REPO_ROOT_RESOLVED/spec/test-pipeline.md" || echo "$REPO_ROOT_RESOLVED/test-pipeline.md" )}"
SUPPORTED_SCHEMA_VERSIONS="1"

emit_halt() {
  echo "[test-pipeline-no-config] $1"
  exit 1
}

# Extract the single fenced ```yaml ... ``` block from test-pipeline.md.
_extract_yaml() {
  awk '
    /^```yaml/ { if (!seen) { f=1; seen=1; next } }
    /^```/     { if (f) { f=0 } }
    f          { print }
  ' "$TEST_PIPELINE_PATH" | _strip_cr
}

_schema_version() {
  _extract_yaml | awk '/^schema_version:/ { print $2; exit }'
}

# Parse the units[] block into TSV rows (11 columns):
#   id, family, label, anchor, source, layer, disposition,
#   skips_when_absent, ratchet, trigger, purpose
# Flag-based, key-anchored — the same shape as gate-spec.sh / doc-spec.sh.
# label/anchor/trigger/purpose are quoted single-line values; they are
# extracted by stripping the `key: "…"` wrapper (so they may contain spaces
# and most punctuation, but no double quotes and no tabs — a documented
# parser constraint in the registry prose). Full-line comments inside the
# block (`  # ---- … ----`) are skipped.
#
# EMPTY fields (the optional skips_when_absent/ratchet, or a missing required
# key) are emitted as a literal `-` placeholder: a bash `read` with IFS=<tab>
# COLLAPSES consecutive tabs (tab is IFS whitespace), so empty TSV fields would
# silently shift every later column left. Readers normalize `-` back to "".
_parse_units() {
  _extract_yaml | awk '
    function strip(line,   v) {
      v=line
      sub(/^[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v)   # drop `  key: "`
      sub(/"[[:space:]]*$/, "", v)                          # drop trailing `"`
      return v
    }
    function nz(v) { return (v == "" ? "-" : v) }
    function flush() {
      if (cur_id != "") {
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
          nz(cur_id), nz(cur_family), nz(cur_label), nz(cur_anchor), nz(cur_source), nz(cur_layer), \
          nz(cur_disp), nz(cur_skips), nz(cur_ratchet), nz(cur_trigger), nz(cur_purpose)
      }
      cur_id=""; cur_family=""; cur_label=""; cur_anchor=""; cur_source=""
      cur_layer=""; cur_disp=""; cur_skips=""; cur_ratchet=""; cur_trigger=""
      cur_purpose=""
    }
    /^units:/          { in_units=1; next }
    !in_units          { next }
    /^[[:space:]]*#/   { next }
    /^[[:space:]]*-[[:space:]]*id:/ { flush(); cur_id=$3; next }
    /^[[:space:]]*family:/            { cur_family=$2; next }
    /^[[:space:]]*label:/             { cur_label=strip($0); next }
    /^[[:space:]]*anchor:/            { cur_anchor=strip($0); next }
    /^[[:space:]]*source:/            { cur_source=$2; next }
    /^[[:space:]]*layer:/             { cur_layer=$2; next }
    /^[[:space:]]*disposition:/       { cur_disp=$2; next }
    /^[[:space:]]*skips_when_absent:/ { cur_skips=$2; next }
    /^[[:space:]]*ratchet:/           { cur_ratchet=$2; next }
    /^[[:space:]]*trigger:/           { cur_trigger=strip($0); next }
    /^[[:space:]]*purpose:/           { cur_purpose=strip($0); next }
    END { flush() }
  '
}

# ---- Validation gates (run for every registry-reading subcommand) ----
_run_registry_gates() {
  [ -f "$TEST_PIPELINE_PATH" ] || emit_halt "test-pipeline.md missing (resolved spec/-then-root): $TEST_PIPELINE_PATH"

  _FENCES=$(grep -cE '^```yaml' "$TEST_PIPELINE_PATH" || true)
  [ "${_FENCES:-0}" -eq 1 ] || emit_halt "test-pipeline.md must carry exactly ONE fenced \`\`\`yaml registry block (found ${_FENCES:-0})"

  _YAML_BODY=$(_extract_yaml)
  [ -n "$_YAML_BODY" ] || emit_halt "test-pipeline.md has no fenced \`\`\`yaml registry block"

  SCHEMA_VERSION=$(_schema_version)
  [ -n "$SCHEMA_VERSION" ] || emit_halt "schema_version field missing in the test-pipeline registry"

  SCHEMA_OK=0
  for v in $SUPPORTED_SCHEMA_VERSIONS; do
    [ "$SCHEMA_VERSION" = "$v" ] && { SCHEMA_OK=1; break; }
  done
  [ "$SCHEMA_OK" -eq 1 ] || emit_halt "schema_version=${SCHEMA_VERSION} unsupported (this helper supports ${SUPPORTED_SCHEMA_VERSIONS})"

  _UNITS=$(_parse_units)
  [ -n "$_UNITS" ] || emit_halt "the test-pipeline registry declares no units (empty units[] list)"

  # Duplicate-id guard: total ids vs unique ids.
  _N_IDS=$(printf '%s\n' "$_UNITS" | awk -F'\t' '{print $1}' | grep -c . || true)
  _N_UNIQ=$(printf '%s\n' "$_UNITS" | awk -F'\t' '{print $1}' | sort -u | grep -c . || true)
  [ "$_N_IDS" -eq "$_N_UNIQ" ] || emit_halt "duplicate unit id(s): $(printf '%s\n' "$_UNITS" | awk -F'\t' '{print $1}' | sort | uniq -d | tr '\n' ' ')"

  # Per-unit required keys + closed enums + the rendered-field work-item-ID lint.
  while IFS="$(printf '\t')" read -r _id _family _label _anchor _source _layer _disp _skips _ratchet _trigger _purpose; do
    # Normalize the `-` empty-field placeholders back to "" (see _parse_units).
    [ "$_family" = "-" ] && _family=""
    [ "$_label" = "-" ] && _label=""
    [ "$_anchor" = "-" ] && _anchor=""
    [ "$_source" = "-" ] && _source=""
    [ "$_layer" = "-" ] && _layer=""
    [ "$_disp" = "-" ] && _disp=""
    [ "$_skips" = "-" ] && _skips=""
    [ "$_ratchet" = "-" ] && _ratchet=""
    [ "$_trigger" = "-" ] && _trigger=""
    [ "$_purpose" = "-" ] && _purpose=""
    [ -n "$_id" ] || emit_halt "a unit is missing 'id'"
    case "$_id" in
      *[!a-z0-9-]*) emit_halt "unit id '$_id' is not a slug ([a-z0-9-]+ only)" ;;
    esac
    [ -n "$_family" ]  || emit_halt "unit '$_id' is missing 'family'"
    [ -n "$_label" ]   || emit_halt "unit '$_id' is missing 'label'"
    [ -n "$_anchor" ]  || emit_halt "unit '$_id' is missing 'anchor'"
    [ -n "$_source" ]  || emit_halt "unit '$_id' is missing 'source'"
    [ -n "$_layer" ]   || emit_halt "unit '$_id' is missing 'layer'"
    [ -n "$_disp" ]    || emit_halt "unit '$_id' is missing 'disposition'"
    [ -n "$_trigger" ] || emit_halt "unit '$_id' is missing 'trigger'"
    [ -n "$_purpose" ] || emit_halt "unit '$_id' is missing 'purpose'"
    case "$_family" in
      validate|test|test-deploy|eval|windows-smoke|ci|hook) : ;;
      *) emit_halt "unit '$_id' has family '$_family' outside the closed enum {validate, test, test-deploy, eval, windows-smoke, ci, hook}" ;;
    esac
    case "$_layer" in
      local-hook|ci) : ;;
      *) emit_halt "unit '$_id' has layer '$_layer' outside the closed enum {local-hook, ci}" ;;
    esac
    case "$_disp" in
      hard-fail|advisory) : ;;
      *) emit_halt "unit '$_id' has disposition '$_disp' outside the closed enum {hard-fail, advisory}" ;;
    esac
    case "$_skips" in
      ""|true|false) : ;;
      *) emit_halt "unit '$_id' has skips_when_absent '$_skips' (must be true or false when present)" ;;
    esac
    case "$_ratchet" in
      ""|true|false) : ;;
      *) emit_halt "unit '$_id' has ratchet '$_ratchet' (must be true or false when present)" ;;
    esac
    for _tok in $_trigger; do
      case "$_tok" in
        pre-commit|post-merge|pr-ci|push-main|nightly|manual) : ;;
        *) emit_halt "unit '$_id' has trigger token '$_tok' outside the closed enum {pre-commit, post-merge, pr-ci, push-main, nightly, manual}" ;;
      esac
    done
    # Source pin for test rows (the silent-skip catch's load-bearing rule):
    # a family:test row anchored on a tests/*.test.sh runner path MUST declare
    # source: scripts/test.sh — the forward grep proves the file is WIRED into
    # the suite. Pointing source at the test file itself self-satisfies the
    # grep (every test file names itself in its header) and silently disarms
    # the catch, so a wrong fill fails HERE with a named reason.
    if [ "$_family" = "test" ]; then
      case "$_anchor" in
        tests/*.test.sh)
          [ "$_source" = "scripts/test.sh" ] || emit_halt "unit '$_id' is a test-runner row (anchor '$_anchor') but declares source '$_source' — test rows MUST declare source: scripts/test.sh so the forward grep proves the file is wired into the suite"
          ;;
      esac
    fi
    # Rendered-field work-item-ID lint: label + purpose render into the
    # generated human view (a hard-linted human-doc); anchors never render.
    if printf '%s %s' "$_label" "$_purpose" | grep -qE '[FSTD][0-9]{6}'; then
      emit_halt "unit '$_id' carries a work-item ID in a rendered field (label/purpose must be ID-free; literal ID-bearing strings belong in the non-rendered anchor)"
    fi
  done <<EOF
$_UNITS
EOF
}

# ---- Renderer (the docs/test-pipeline.md body) ----
# Pure function of the registry: AUTO-GENERATED header, intro, the leading
# per-family summary table (BEFORE the first `## ` heading — satisfies the
# front-table lint), the single gate-spec pointer line, then one section per
# family. Family display strings live here (renderer constants, ID-free).
_render_view() {
  printf '%s\n' "$_UNITS" | awk '
    BEGIN {
      FS="\t"
      nfam=7
      fam[1]="validate";      famh[1]="validate — scripts/validate.sh checks"
      fam[2]="test";          famh[2]="test — scripts/test.sh suite"
      fam[3]="test-deploy";   famh[3]="test-deploy — skills-deploy suite (scripts/test-deploy.sh)"
      fam[4]="eval";          famh[4]="eval — behavioral eval harness (scripts/eval.sh)"
      fam[5]="windows-smoke"; famh[5]="windows-smoke — Git Bash smoke (scripts/windows-smoke.sh)"
      fam[6]="ci";            famh[6]="ci — GitHub Actions workflows"
      fam[7]="hook";          famh[7]="hook — git hooks (scripts/setup-hooks.sh)"
      ntrig=6
      trigs[1]="pre-commit"; trigs[2]="post-merge"; trigs[3]="pr-ci"
      trigs[4]="push-main";  trigs[5]="nightly";    trigs[6]="manual"
    }
    {
      n++
      f[n]=$2; lab[n]=$3; disp[n]=$7; skp[n]=$8; rat[n]=$9; trg[n]=$10; pur[n]=$11
      gsub(/\|/, "\\|", lab[n]); gsub(/\|/, "\\|", pur[n])
      cnt[$2]++
      if ($7 == "hard-fail") hard[$2]++; else adv[$2]++
      m=split($10, tt, " ")
      for (i=1; i<=m; i++) ftrig[$2 "," tt[i]]=1
    }
    END {
      print "<!-- AUTO-GENERATED from scripts/test-pipeline.sh --render — do not edit. Edit spec/test-pipeline.md, then run scripts/generate-doc-views.sh. -->"
      print "# Test pipeline — the verification surface"
      print ""
      print "Every validator check, test family, standalone suite, CI workflow and git hook that protects this repo — what each asserts, how it fails (hard-fail vs advisory, with skip-when-absent and regression-ratchet flags), and when it runs. Generated from the machine registry; do not edit by hand."
      print ""
      print "| Family | Units | Hard / advisory | Triggers |"
      print "|--------|-------|-----------------|----------|"
      for (k=1; k<=nfam; k++) {
        fk=fam[k]
        if (!(fk in cnt)) continue
        ts=""
        for (i=1; i<=ntrig; i++) if ((fk "," trigs[i]) in ftrig) ts = ts (ts=="" ? "" : ", ") trigs[i]
        printf "| %s | %d | %d hard / %d advisory | %s |\n", famh[k], cnt[fk], hard[fk]+0, adv[fk]+0, ts
      }
      print ""
      print "Pipeline-gate enforcement (the inline goal-pipeline halts during a run) is deliberately not enumerated here — [spec/gate-spec.md](../spec/gate-spec.md) owns the gate sequence and the four-layer model."
      for (k=1; k<=nfam; k++) {
        fk=fam[k]
        if (!(fk in cnt)) continue
        print ""
        print "## " famh[k]
        print ""
        print "| Unit | What it asserts | Disposition | When it runs |"
        print "|------|-----------------|-------------|--------------|"
        for (j=1; j<=n; j++) {
          if (f[j] != fk) continue
          d=disp[j]
          if (skp[j] == "true") d = d " · skips when absent"
          if (rat[j] == "true") d = d " · ratchet"
          tl=trg[j]; gsub(/ /, ", ", tl)
          printf "| %s | %s | %s | %s |\n", lab[j], pur[j], d, tl
        }
      }
    }
  '
}

# ---- Coverage cross-check (the Check 24 engine) ----
# Forward + reverse + floor. Findings print as `FINDING: ...`; the summary line
# is the last line either way. Exit 1 on any finding.
_run_coverage() {
  _FINDINGS=0

  # Forward: every anchor must grep -F in its declared source file.
  _ROWCOUNT=0
  while IFS="$(printf '\t')" read -r _id _family _label _anchor _source _layer _disp _skips _ratchet _trigger _purpose; do
    [ -n "$_id" ] || continue
    _ROWCOUNT=$((_ROWCOUNT + 1))
    _src="$REPO_ROOT_RESOLVED/$_source"
    if [ ! -f "$_src" ]; then
      echo "FINDING: forward — unit '$_id' declares source '$_source' which does not exist"
      _FINDINGS=$((_FINDINGS + 1))
    elif ! grep -qF -- "$_anchor" "$_src"; then
      echo "FINDING: forward — unit '$_id' anchor not found in $_source (unit removed/renamed, or a test file no longer wired into the runner): $_anchor"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done <<EOF
$_UNITS
EOF

  # Reverse: every live unit on the swept surface must resolve to exactly one
  # registry row in its namespace. _TOKENS counts every extracted live token
  # for the floor assert.
  _TOKENS=0

  # (1) validate.sh banners + comments.
  _VAL_SRC="$REPO_ROOT_RESOLVED/scripts/validate.sh"
  if [ -f "$_VAL_SRC" ]; then
    # 1a. `=== Check N:` echo banners -> row id validate-check-N.
    while IFS= read -r _n; do
      [ -n "$_n" ] || continue
      _TOKENS=$((_TOKENS + 1))
      _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="validate-check-$_n" '$1 == want' | grep -c . || true)
      if [ "$_c" -ne 1 ]; then
        echo "FINDING: reverse — live banner 'Check $_n' in scripts/validate.sh resolves to $_c registry row(s); want exactly one (id: validate-check-$_n)"
        _FINDINGS=$((_FINDINGS + 1))
      fi
    done <<EOF
$(grep -E '^echo "=== Check [0-9]+[a-z]?:' "$_VAL_SRC" | sed -E 's/^echo "=== Check ([0-9]+[a-z]?):.*/\1/')
EOF
    # 1b. `# Error check N:` comments -> row id validate-error-check-N.
    while IFS= read -r _n; do
      [ -n "$_n" ] || continue
      _TOKENS=$((_TOKENS + 1))
      _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="validate-error-check-$_n" '$1 == want' | grep -c . || true)
      if [ "$_c" -ne 1 ]; then
        echo "FINDING: reverse — live comment 'Error check $_n' in scripts/validate.sh resolves to $_c registry row(s); want exactly one (id: validate-error-check-$_n)"
        _FINDINGS=$((_FINDINGS + 1))
      fi
    done <<EOF
$(grep -E '^# Error check [0-9]+[a-z]?:' "$_VAL_SRC" | sed -E 's/^# Error check ([0-9]+[a-z]?):.*/\1/')
EOF
    # 1c. `# Warning check` comments -> exactly one validate row whose anchor
    # is a substring of the live line (the warning namespace has an unnumbered
    # member, so matching is anchor-containment, not ID-derived).
    while IFS= read -r _wline; do
      [ -n "$_wline" ] || continue
      _TOKENS=$((_TOKENS + 1))
      _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v line="$_wline" '$2 == "validate" && index(line, $4) > 0' | grep -c . || true)
      if [ "$_c" -ne 1 ]; then
        echo "FINDING: reverse — live warning-check comment in scripts/validate.sh resolves to $_c registry row(s); want exactly one: $_wline"
        _FINDINGS=$((_FINDINGS + 1))
      fi
    done <<EOF
$(grep -E '^# Warning check' "$_VAL_SRC")
EOF
  fi

  # (2) tests/*.test.sh on disk -> exactly one family:test row whose anchor is
  # the literal runner path AND whose source is scripts/test.sh. This is the
  # silent-skip catch: the row's FORWARD anchor proves the file is wired into
  # scripts/test.sh; this REVERSE pass proves every file on disk has a row at
  # all. The source pin is load-bearing — a row pointing source at the test
  # file itself would self-satisfy the forward grep (the file names itself in
  # its header), turning the catch back into a convention.
  for _tf in "$REPO_ROOT_RESOLVED"/tests/*.test.sh; do
    [ -e "$_tf" ] || continue
    _tok="tests/$(basename "$_tf")"
    _TOKENS=$((_TOKENS + 1))
    _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="$_tok" '$2 == "test" && $4 == want && $5 == "scripts/test.sh"' | grep -c . || true)
    if [ "$_c" -ne 1 ]; then
      echo "FINDING: reverse — test file $_tok on disk resolves to $_c registry row(s); want exactly one (family: test, anchor: $_tok, source: scripts/test.sh — the runner, NOT the test file: the forward grep must prove the file is wired in)"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done

  # (3) .github/workflows/*.yml on disk -> exactly one family:ci row declaring
  # that workflow file as its source.
  for _wf in "$REPO_ROOT_RESOLVED"/.github/workflows/*.yml "$REPO_ROOT_RESOLVED"/.github/workflows/*.yaml; do
    [ -e "$_wf" ] || continue
    _wsrc=".github/workflows/$(basename "$_wf")"
    _TOKENS=$((_TOKENS + 1))
    _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="$_wsrc" '$2 == "ci" && $5 == want' | grep -c . || true)
    if [ "$_c" -ne 1 ]; then
      echo "FINDING: reverse — workflow $_wsrc on disk resolves to $_c registry row(s); want exactly one (family: ci, source: $_wsrc)"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done

  # (4) install_hook invocations in scripts/setup-hooks.sh -> exactly one
  # family:hook row per installed hook name.
  _SH_SRC="$REPO_ROOT_RESOLVED/scripts/setup-hooks.sh"
  if [ -f "$_SH_SRC" ]; then
    while IFS= read -r _hname; do
      [ -n "$_hname" ] || continue
      _TOKENS=$((_TOKENS + 1))
      _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="install_hook $_hname" '$2 == "hook" && $4 == want' | grep -c . || true)
      if [ "$_c" -ne 1 ]; then
        echo "FINDING: reverse — installed hook '$_hname' resolves to $_c registry row(s); want exactly one (family: hook, anchor: install_hook $_hname)"
        _FINDINGS=$((_FINDINGS + 1))
      fi
    done <<EOF
$(grep -E '^if install_hook [a-z][a-z-]*' "$_SH_SRC" | sed -E 's/^if install_hook ([a-z][a-z-]*).*/\1/')
EOF
  fi

  # Floor-assert: the reverse extraction must keep finding a healthy number of
  # live tokens, so extraction-grammar rot can never make this check
  # vacuously pass.
  if [ "$_TOKENS" -lt 20 ]; then
    echo "FINDING: floor — reverse extraction yielded only $_TOKENS live token(s) (< 20); the extraction grammar no longer matches the live surface"
    _FINDINGS=$((_FINDINGS + 1))
  fi

  if [ "$_FINDINGS" -gt 0 ]; then
    echo "COVERAGE: findings=$_FINDINGS (rows=$_ROWCOUNT reverse_tokens=$_TOKENS)"
    return 1
  fi
  echo "OK coverage rows=$_ROWCOUNT reverse_tokens=$_TOKENS findings=0"
  return 0
}

# ---- Subcommand dispatch ----

case "${1:-}" in
  --validate)
    _run_registry_gates
    echo "OK schema_version=$SCHEMA_VERSION"
    ;;
  --list-units)
    _run_registry_gates
    printf '%s\n' "$_UNITS" | awk -F'\t' '{print $1}'
    ;;
  --render)
    _run_registry_gates
    _render_view
    ;;
  --check-coverage)
    _run_registry_gates
    _run_coverage
    ;;
  --help|-h)
    cat <<'USAGE'
test-pipeline.sh — parse + validate the test-pipeline.md registry; render the
generated human view; run the coverage cross-check.

Usage:
  test-pipeline.sh --validate        # exit 0 if the registry schema is ok
  test-pipeline.sh --list-units      # every declared unit id (registry order)
  test-pipeline.sh --render          # the full generated markdown view
  test-pipeline.sh --check-coverage  # forward anchors + reverse sweep + floor
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--list-units|--render|--check-coverage}" >&2
    exit 2
    ;;
  *)
    echo "test-pipeline.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
