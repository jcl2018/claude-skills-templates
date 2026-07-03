#!/usr/bin/env bash
# test-run.sh — execute the repo's test contract and report evidence-derived
# pass/fail (F000072/S000122). The "does it pass?" companion to /CJ_test_audit's
# "is it wired?".
#
# It reads the runners: axis of the merged test-spec registry (via
# scripts/test-spec.sh --list-runners), plans a tiered run, executes the selected
# runners ONCE each, and writes a materialized report (.md) + a machine-readable
# ledger (.json) under tests/test-run/reports/. Every outcome is DERIVED from
# captured evidence (rc + output): anything unrun is skipped(<named reason>); a
# runner failure attaches its FAIL lines; a skipped tier is NEVER counted green.
#
# Cost tiers are the hard UX law: a default run executes only tier: free.
#   (no flags)  free
#   --evals     + paid
#   --e2e       + local-only
#   --all       everything
#
# Registry edge states (distinct + honest):
#   absent registry            -> `REGISTRY=absent` + exit 0 (SKIP)
#   invalid registry           -> the [test-spec-no-config] passthrough + exit 1
#   valid, zero runners: rows  -> `SKIP: no runners declared` + exit 0, NO report/ledger
#
# Aggregate verdict is the closed enum {pass, fail, all-skipped}:
#   fail          any executed runner failed                     -> exit 1
#   pass          >=1 runner executed green AND none failed       -> exit 0
#   all-skipped   runners declared but ZERO executed              -> exit 0 (NEVER `pass`)
#
# POSIX + Windows Git Bash clean: every NEW jq consumption strips CR (the jq()
# wrapper below), and ALL JSON string encoding goes through jq -R/-Rs (never
# hand-escaped — verbatim output tails carry quotes/backslashes).
#
# Usage:
#   test-run.sh --dry-run [--evals] [--e2e] [--all]   # print the plan; execute nothing
#   test-run.sh [--evals] [--e2e] [--all]             # execute + write report + ledger
#   test-run.sh --category <workflow|CI> [--dry-run]  # (F000074) run one category's tests
#   test-run.sh <name> [--dry-run]                    # (F000074) run the single test of that name
#   test-run.sh --help
#
# Category selection (F000074) maps a category or a single test NAME to the
# declared command(s) via the categories: axis of the merged registry (reusing the
# docs/tests/<category>/<name>.md name), honoring the SAME cost tiers (default =
# free only). It is ADDITIVE: with no --category and no positional name, the
# runners: flow runs unchanged.
#
# Env overrides (for hermetic fixtures): REPO_ROOT / TEST_SPEC_PATH /
# TEST_SPEC_CUSTOM_PATH (forwarded to test-spec.sh), TEST_RUN_TS (fix the report
# timestamp), TEST_RUN_REPORTS_DIR (redirect the reports dir).

set -eu

# ---- Strip CR from any command output on Windows (jq.exe writes \r\n) ---------
# NEW jq consumption goes through this wrapper (the scripts/lib.sh:24 pattern),
# so a CRLF-emitting Windows jq build cannot corrupt a read or the ledger.
_strip_cr() { tr -d '\r'; }
jq() { command jq "$@" | _strip_cr; }

# ---- Resolve repo root (REPO_ROOT override for tests / temp-dir drills) -------
REPO_ROOT_RESOLVED="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"

# ---- Resolve test-spec.sh: sibling-in-scriptdir -> $REPO_ROOT/scripts -> _cj-shared
# (the established repo-local-first idiom; a consumer repo with no repo-local
# scripts/ still resolves the engine from the deployed shared home).
_resolve_test_spec() {
  _ts_self_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd 2>/dev/null || echo "")
  for _ts_cand in \
    "$_ts_self_dir/test-spec.sh" \
    "$REPO_ROOT_RESOLVED/scripts/test-spec.sh" \
    "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/test-spec.sh"; do
    [ -n "$_ts_cand" ] || continue
    if [ -x "$_ts_cand" ] || [ -f "$_ts_cand" ]; then
      echo "$_ts_cand"
      return 0
    fi
  done
  return 0
}

TEST_SPEC_SH=$(_resolve_test_spec)
if [ -z "$TEST_SPEC_SH" ]; then
  echo "test-run.sh: cannot resolve test-spec.sh (sibling / \$REPO_ROOT/scripts / _cj-shared) — cannot read the registry" >&2
  exit 2
fi

# ---- Arg parse ---------------------------------------------------------------
DRY_RUN=0
SEL_PAID=0
SEL_LOCAL=0
SEL_CATEGORY=""   # (F000074) --category <workflow|CI>: run one category's tests
SEL_NAME=""       # (F000074) a bare positional: run the single test of that name
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --evals)   SEL_PAID=1; shift ;;
    --e2e)     SEL_LOCAL=1; shift ;;
    --all)     SEL_PAID=1; SEL_LOCAL=1; shift ;;
    --category)
      shift
      [ $# -gt 0 ] || { echo "test-run.sh: --category needs a value (workflow|CI)" >&2; exit 2; }
      SEL_CATEGORY="$1"; shift ;;
    --help|-h)
      sed -n '2,48p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --*) echo "test-run.sh: unknown arg: $1 (see --help)" >&2; exit 2 ;;
    *)
      # A bare positional is a single test NAME (F000074 category selection).
      [ -z "$SEL_NAME" ] || { echo "test-run.sh: only one single-test name may be given (got '$SEL_NAME' and '$1')" >&2; exit 2; }
      SEL_NAME="$1"; shift ;;
  esac
done

# --category and a single name are mutually exclusive (two different selections).
if [ -n "$SEL_CATEGORY" ] && [ -n "$SEL_NAME" ]; then
  echo "test-run.sh: --category and a single test name are mutually exclusive — pass one or the other" >&2
  exit 2
fi
# CATEGORY_MODE is on when either category-selection form is used.
CATEGORY_MODE=0
[ -n "$SEL_CATEGORY" ] && CATEGORY_MODE=1
[ -n "$SEL_NAME" ] && CATEGORY_MODE=1

# The flags string recorded in the ledger (canonical order).
FLAGS=""
[ "$DRY_RUN" = "1" ] && FLAGS="$FLAGS --dry-run"
[ "$SEL_PAID" = "1" ] && FLAGS="$FLAGS --evals"
[ "$SEL_LOCAL" = "1" ] && FLAGS="$FLAGS --e2e"
[ -n "$SEL_CATEGORY" ] && FLAGS="$FLAGS --category $SEL_CATEGORY"
[ -n "$SEL_NAME" ] && FLAGS="$FLAGS $SEL_NAME"
FLAGS="${FLAGS# }"
[ -n "$FLAGS" ] || FLAGS="(default)"

# ---- Registry edge classification (absent / invalid / zero-runners) ----------
# --validate is the single source of truth for absent-vs-invalid (its documented
# contract: REGISTRY=absent + exit 0 when absent; the [test-spec-no-config] halt
# + exit 1 when invalid; OK + exit 0 when valid). Capture both stream + rc.
_VALIDATE_OUT=$(bash "$TEST_SPEC_SH" --validate 2>&1) || _VALIDATE_RC=$?
_VALIDATE_RC=${_VALIDATE_RC:-0}

if printf '%s\n' "$_VALIDATE_OUT" | grep -q '^REGISTRY=absent$'; then
  echo "REGISTRY=absent"
  exit 0
fi
if [ "$_VALIDATE_RC" -ne 0 ]; then
  # Invalid registry: pass the [test-spec-no-config] halt through verbatim + exit 1.
  printf '%s\n' "$_VALIDATE_OUT"
  exit 1
fi

# Valid registry. Read the runners rows (tab-separated id/command/tier/covers/
# platform/note). Empty output => zero runners declared.
RUNNERS_TSV=$(bash "$TEST_SPEC_SH" --list-runners 2>/dev/null || true)
# The zero-runners SKIP is the RUNNERS-flow terminal only — in CATEGORY_MODE the
# categories: axis (not runners:) drives selection, so an empty runners: list must
# NOT short-circuit a --category / single-name run.
if [ -z "$RUNNERS_TSV" ] && [ "$CATEGORY_MODE" != "1" ]; then
  echo "SKIP: no runners declared (the runners: axis of spec/test-spec-custom.md is empty; declare runners to make the contract executable) — no report or ledger written"
  exit 0
fi

# Per-family covered-unit counts come from --list-units --with-family (id<TAB>family).
UNITS_WF=$(bash "$TEST_SPEC_SH" --list-units --with-family 2>/dev/null || true)

# The runnable families (must match test-spec.sh's covers enum).
RUNNABLE_FAMILIES="validate test test-deploy eval windows-smoke"

# ---- Platform detection ------------------------------------------------------
# windows = Git Bash / MSYS / Cygwin; anything else = posix. `any` always matches.
_host_platform() {
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*|Windows_NT) echo "windows" ;;
    *) echo "posix" ;;
  esac
}
HOST_PLATFORM=$(_host_platform)

# Does a runner's declared platform match the host? (empty/`-`/`any` always yes.)
_platform_matches() {
  case "$1" in
    ""|"-"|any) return 0 ;;
    "$HOST_PLATFORM") return 0 ;;
    *) return 1 ;;
  esac
}

# Is this tier selected given the flags?
_tier_selected() {
  case "$1" in
    free) return 0 ;;
    paid) [ "$SEL_PAID" = "1" ] && return 0 || return 1 ;;
    local-only) [ "$SEL_LOCAL" = "1" ] && return 0 || return 1 ;;
    *) return 1 ;;  # unknown tier (should never reach — --validate gated it)
  esac
}

# ---- CATEGORY MODE (F000074): --category <cat> / single test NAME selection ---
# The category-based selection path: map a category or a single test name to the
# declared command(s) via the categories: axis of the merged registry (via
# test-spec.sh --list-categories), then plan (--dry-run) or execute exactly those
# tests, honoring cost tiers (default = free tier only, no surprise model spend).
# It is ADDITIVE: it runs ONLY when --category or a positional name is passed;
# otherwise the runners: flow below is unchanged. Reuses _tier_selected. Writes a
# category-shaped report + ledger under tests/test-run/reports/ (ledger schema 1,
# mode: category). Every outcome is evidence-derived (rc); a skipped-tier test is
# NEVER counted green; a self-gate (rc 0 + first line ^SKIP:) is skipped(self-gated).
_run_category_mode() {
  # Read the category rows: name<TAB>category<TAB>command<TAB>tier<TAB>doc<TAB>purpose.
  _CM_ROWS=$(bash "$TEST_SPEC_SH" --list-categories 2>/dev/null || true)
  if [ -z "$_CM_ROWS" ]; then
    echo "category contract not adopted / inactive — no categories: axis in spec/test-spec-custom.md; declare category tests to use --category / single-name selection"
    exit 0
  fi

  # Build the SELECTED subset (name<TAB>category<TAB>command<TAB>tier).
  if [ -n "$SEL_NAME" ]; then
    _CM_SEL=$(printf '%s\n' "$_CM_ROWS" | awk -F'\t' -v n="$SEL_NAME" 'NF && $1 == n {print $1"\t"$2"\t"$3"\t"$4}')
    if [ -z "$_CM_SEL" ]; then
      echo "test-run.sh: no category test named '$SEL_NAME' (see: test-spec.sh --list-categories --names)" >&2
      exit 2
    fi
    _CM_LABEL="name=$SEL_NAME"
  else
    case "$SEL_CATEGORY" in
      workflow|CI) : ;;
      *) echo "test-run.sh: --category '$SEL_CATEGORY' is outside the V1 taxonomy {workflow, CI}" >&2; exit 2 ;;
    esac
    _CM_SEL=$(printf '%s\n' "$_CM_ROWS" | awk -F'\t' -v c="$SEL_CATEGORY" 'NF && $2 == c {print $1"\t"$2"\t"$3"\t"$4}')
    if [ -z "$_CM_SEL" ]; then
      echo "SKIP: category '$SEL_CATEGORY' declares no tests — nothing to run"
      exit 0
    fi
    _CM_LABEL="category=$SEL_CATEGORY"
  fi

  # ---- PLAN (--dry-run): print per-test command/tier/decision; execute nothing.
  if [ "$DRY_RUN" = "1" ]; then
    echo "=== test-run CATEGORY PLAN ($_CM_LABEL; flags: $FLAGS) ==="
    echo "registry: valid   selection: $_CM_LABEL"
    echo ""
    while IFS="$(printf '\t')" read -r _cm_name _cm_cat _cm_cmd _cm_tier; do
      [ -n "$_cm_name" ] || continue
      if _tier_selected "$_cm_tier"; then _cm_dec="will-run"; else _cm_dec="skip(tier-not-selected)"; fi
      echo "test: $_cm_name ($_cm_cat)"
      echo "  command:  $_cm_cmd"
      echo "  tier:     $_cm_tier"
      echo "  decision: $_cm_dec"
    done <<EOF
$_CM_SEL
EOF
    echo ""
    echo "(--dry-run: no test executed, no report or ledger written)"
    exit 0
  fi

  # ---- EXECUTE: run each selected + tier-selected test ONCE; derive outcomes.
  _cm_ts="${TEST_RUN_TS:-$(date -u +%Y%m%dT%H%M%SZ)}"
  _cm_reports="${TEST_RUN_REPORTS_DIR:-$REPO_ROOT_RESOLVED/tests/test-run/reports}"
  _cm_head=$(git -C "$REPO_ROOT_RESOLVED" rev-parse --short HEAD 2>/dev/null || echo "unknown")
  _cm_json=""            # comma-joined test objects
  _cm_md_rows=""         # markdown table rows
  _cm_fail_blocks=""     # verbatim FAIL tails
  _cm_executed=0; _cm_green=0; _cm_failed=0
  _cm_json_str() { printf '%s' "$1" | jq -Rs .; }

  echo "=== test-run CATEGORY EXECUTE ($_CM_LABEL; flags: $FLAGS) ==="
  echo "registry: valid   selection: $_CM_LABEL   HEAD: $_cm_head"
  echo ""

  while IFS="$(printf '\t')" read -r _cm_name _cm_cat _cm_cmd _cm_tier; do
    [ -n "$_cm_name" ] || continue
    if ! _tier_selected "$_cm_tier"; then
      _cm_out="skipped:tier-not-selected"
      echo "  SKIP $_cm_name ($_cm_tier) — tier-not-selected"
      _cm_obj=$(printf '{"name": %s, "category": %s, "command": %s, "tier": %s, "rc": null, "outcome": %s}' \
        "$(_cm_json_str "$_cm_name")" "$(_cm_json_str "$_cm_cat")" "$(_cm_json_str "$_cm_cmd")" "$(_cm_json_str "$_cm_tier")" "$(_cm_json_str "$_cm_out")")
      _cm_json="${_cm_json:+$_cm_json,}$_cm_obj"
      _cm_md_rows="$_cm_md_rows
| $_cm_name | $_cm_cat | \`$_cm_cmd\` | $_cm_tier | — | skipped(tier-not-selected) |"
      continue
    fi
    echo "  RUN  $_cm_name ($_cm_tier): $_cm_cmd"
    _cm_o=$( (cd "$REPO_ROOT_RESOLVED" && eval "$_cm_cmd") 2>&1 ) && _cm_rc=0 || _cm_rc=$?
    _cm_first=$(printf '%s\n' "$_cm_o" | head -1)
    if [ "$_cm_rc" -eq 0 ] && printf '%s' "$_cm_first" | grep -q '^SKIP:'; then
      _cm_out="skipped:self-gated"
      echo "       -> skipped(self-gated): $_cm_first"
    elif [ "$_cm_rc" -eq 0 ]; then
      _cm_out="pass"; _cm_executed=$((_cm_executed + 1)); _cm_green=$((_cm_green + 1))
      echo "       -> pass (rc=0)"
    else
      _cm_out="fail"; _cm_executed=$((_cm_executed + 1)); _cm_failed=$((_cm_failed + 1))
      echo "       -> FAIL (rc=$_cm_rc)"
      _cm_f=$(printf '%s\n' "$_cm_o" | grep -iE '^\s*(FAIL|ERROR)' || true)
      [ -n "$_cm_f" ] || _cm_f=$(printf '%s\n' "$_cm_o" | tail -20)
      _cm_fail_blocks="$_cm_fail_blocks

### $_cm_name — FAIL (rc=$_cm_rc)
\`\`\`
$_cm_f
\`\`\`"
    fi
    _cm_rcj="$_cm_rc"; printf '%s' "$_cm_out" | grep -q '^skipped:' && _cm_rcj="null"
    _cm_obj=$(printf '{"name": %s, "category": %s, "command": %s, "tier": %s, "rc": %s, "outcome": %s}' \
      "$(_cm_json_str "$_cm_name")" "$(_cm_json_str "$_cm_cat")" "$(_cm_json_str "$_cm_cmd")" "$(_cm_json_str "$_cm_tier")" "$_cm_rcj" "$(_cm_json_str "$_cm_out")")
    _cm_json="${_cm_json:+$_cm_json,}$_cm_obj"
    _cm_md_rows="$_cm_md_rows
| $_cm_name | $_cm_cat | \`$_cm_cmd\` | $_cm_tier | $_cm_rcj | $_cm_out |"
  done <<EOF
$_CM_SEL
EOF

  # Aggregate (evidence-derived, same closed enum as the runners flow).
  if [ "$_cm_failed" -gt 0 ]; then _cm_agg="fail"; _cm_exit=1
  elif [ "$_cm_executed" -ge 1 ] && [ "$_cm_green" -ge 1 ]; then _cm_agg="pass"; _cm_exit=0
  else _cm_agg="all-skipped"; _cm_exit=0
  fi

  mkdir -p "$_cm_reports"
  _cm_report_md="$_cm_reports/$_cm_ts.md"
  _cm_ledger="$_cm_reports/$_cm_ts.json"
  {
    echo "# test-run report (category mode) — $_cm_ts"
    echo "Selection: $_CM_LABEL"
    echo "Aggregate: $_cm_agg"
    echo "Flags:     $FLAGS"
    echo "HEAD:      $_cm_head"
    echo ""
    echo "## Tests"
    echo "| name | category | command | tier | rc | outcome |"
    echo "|------|----------|---------|------|----|---------|"
    printf '%s\n' "$_cm_md_rows" | sed '/^$/d'
    if [ -n "$_cm_fail_blocks" ]; then
      echo ""
      echo "## Failures (verbatim)"
      printf '%s\n' "$_cm_fail_blocks"
    fi
    echo ""
    echo "## Legend"
    echo "outcome pass/fail = the test executed (rc derived). skipped(<reason>) = not executed"
    echo "(tier-not-selected / self-gated). all-skipped aggregate is NEVER rendered pass."
  } > "$_cm_report_md"
  {
    printf '{\n'
    printf '  "schema": 1,\n'
    printf '  "mode": "category",\n'
    printf '  "timestamp": %s,\n' "$(_cm_json_str "$_cm_ts")"
    printf '  "head_sha": %s,\n' "$(_cm_json_str "$_cm_head")"
    printf '  "selection": %s,\n' "$(_cm_json_str "$_CM_LABEL")"
    printf '  "flags": %s,\n' "$(_cm_json_str "$FLAGS")"
    printf '  "aggregate": %s,\n' "$(_cm_json_str "$_cm_agg")"
    printf '  "tests": [%s]\n' "$_cm_json"
    printf '}\n'
  } > "$_cm_ledger"
  if command -v jq >/dev/null 2>&1; then
    jq empty "$_cm_ledger" 2>/dev/null || echo "test-run.sh: WARNING — category ledger is not valid JSON ($_cm_ledger)" >&2
  fi

  echo ""
  echo "aggregate: $_cm_agg (executed=$_cm_executed green=$_cm_green failed=$_cm_failed)"
  echo "report: $_cm_report_md"
  echo "ledger: $_cm_ledger"
  exit "$_cm_exit"
}

# Expand a runner's covers into the concrete family list (`all` -> every runnable).
_expand_covers() {
  case "$1" in
    all) echo "$RUNNABLE_FAMILIES" ;;
    *) echo "$1" ;;
  esac
}

# Count the units in a family (from UNITS_WF). 0 when none / no units declared.
_family_unit_count() {
  [ -n "$UNITS_WF" ] || { echo 0; return 0; }
  printf '%s\n' "$UNITS_WF" | awk -F'\t' -v fam="$1" '$2 == fam' | grep -c . || true
}

# Sum covered-unit counts across a runner's covered families.
_covered_unit_count() {
  _cuc_total=0
  for _cuc_fam in $(_expand_covers "$1"); do
    _cuc_n=$(_family_unit_count "$_cuc_fam")
    _cuc_total=$((_cuc_total + _cuc_n))
  done
  echo "$_cuc_total"
}

# The set of families covered by ANY declared runner (for the uncovered-family
# sweep), ONE family per line — a covers value can be a space-separated list, so
# each token must land on its own line for the grep -qxF membership test.
_all_covered_families() {
  while IFS="$(printf '\t')" read -r _acf_id _acf_cmd _acf_tier _acf_covers _acf_plat _acf_note; do
    [ -n "$_acf_id" ] || continue
    for _acf_fam in $(_expand_covers "$_acf_covers"); do
      echo "$_acf_fam"
    done
  done <<EOF
$RUNNERS_TSV
EOF
}

# ---- CATEGORY-MODE dispatch (F000074) ----------------------------------------
# When --category or a single test name was passed, run the category-based
# selection path and EXIT — the runners: flow below is not reached. Additive:
# a normal (no --category, no name) invocation falls straight through to the
# runners flow, behavior-unchanged.
if [ "$CATEGORY_MODE" = "1" ]; then
  _run_category_mode
fi

# ---- PLAN --------------------------------------------------------------------
# For each runner: resolved command, tier, platform guard, covered families,
# covered unit count, will-run / skip(reason). Skip reasons form a closed enum:
# per-runner {tier-not-selected, platform, self-gated}; per-family {no-covering-runner}.
# self-gated is NOT knowable at plan time (it needs rc + output), so --dry-run
# reports will-run for a selected+platform-ok runner and notes self-gate at run time.
_print_plan_header() {
  echo "=== test-run PLAN (flags: $FLAGS) ==="
  echo "registry: valid   host-platform: $HOST_PLATFORM"
  echo ""
}

# Emit one plan line per runner. Sets no globals; pure print.
_print_runner_plan() {
  while IFS="$(printf '\t')" read -r _pr_id _pr_cmd _pr_tier _pr_covers _pr_plat _pr_note; do
    [ -n "$_pr_id" ] || continue
    [ "$_pr_plat" = "-" ] && _pr_plat="any"
    _pr_families=$(_expand_covers "$_pr_covers")
    _pr_ucount=$(_covered_unit_count "$_pr_covers")
    _pr_decision=""
    if ! _tier_selected "$_pr_tier"; then
      _pr_decision="skip(tier-not-selected)"
    elif ! _platform_matches "$_pr_plat"; then
      _pr_decision="skip(platform: needs $_pr_plat, host $HOST_PLATFORM)"
    else
      _pr_decision="will-run"
    fi
    echo "runner: $_pr_id"
    echo "  command:  $_pr_cmd"
    echo "  tier:     $_pr_tier"
    echo "  platform: $_pr_plat (host $HOST_PLATFORM)"
    echo "  covers:   $_pr_families ($_pr_ucount unit(s))"
    echo "  decision: $_pr_decision"
  done <<EOF
$RUNNERS_TSV
EOF
}

# The uncovered-family sweep: every runnable family no runner covers.
#   ci   -> ci-only (runs on GitHub)          [reported informationally]
#   hook -> verified-installed check          [reported informationally]
#   else -> skipped(no-covering-runner)
_print_uncovered_families() {
  _cov=$(_all_covered_families | sort -u)
  echo ""
  echo "uncovered families:"
  for _uf in $RUNNABLE_FAMILIES; do
    if ! printf '%s\n' "$_cov" | grep -qxF "$_uf"; then
      echo "  $_uf -> skipped(no-covering-runner)"
    fi
  done
  # ci + hook are runner-less-by-design (never coverable), reported specially.
  echo "  ci -> ci-only (runs on GitHub)"
  if _hook_check >/dev/null 2>&1; then
    echo "  hook -> hook-check: installed pre-commit hook present"
  else
    echo "  hook -> hook-check: no installed pre-commit hook found"
  fi
}

# ---- Hook-family check (minimal v1) ------------------------------------------
# The hook family is runner-less-by-design; instead of executing it we verify the
# pre-commit hook is INSTALLED and references the validator (per the design doc:
# "installed pre-commit hook present + grep for the validator reference"). Returns
# 0 (installed) / 1 (absent). Best-effort; a repo with no .git/hooks is a clean 1.
_hook_check() {
  _hc_dir=$(git -C "$REPO_ROOT_RESOLVED" rev-parse --git-path hooks 2>/dev/null || echo "")
  [ -n "$_hc_dir" ] || _hc_dir="$REPO_ROOT_RESOLVED/.git/hooks"
  _hc_pc="$_hc_dir/pre-commit"
  [ -f "$_hc_pc" ] || return 1
  # A minimal "references the validator" grep (validate.sh is the workbench
  # validator; a consumer may reference its own — we accept validate.sh here).
  grep -q 'validate' "$_hc_pc" 2>/dev/null || return 1
  return 0
}

if [ "$DRY_RUN" = "1" ]; then
  _print_plan_header
  _print_runner_plan
  _print_uncovered_families
  echo ""
  echo "(--dry-run: no runner executed, no report or ledger written)"
  exit 0
fi

# ---- EXECUTE -----------------------------------------------------------------
TS="${TEST_RUN_TS:-$(date -u +%Y%m%dT%H%M%SZ)}"
REPORTS_DIR="${TEST_RUN_REPORTS_DIR:-$REPO_ROOT_RESOLVED/tests/test-run/reports}"
HEAD_SHA=$(git -C "$REPO_ROOT_RESOLVED" rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Per-runner ledger accumulation. We build a JSON array of runner objects and a
# parallel .md table. Each runner: id, command, tier, rc, outcome, covered
# families, covered unit count, duration. jq -R/-Rs encodes every string.
_RUNNER_JSON=""          # comma-joined runner objects
_FAMILY_JSON=""          # comma-joined family-level rows (ci/hook)
_MD_RUNNER_ROWS=""       # markdown table rows
_MD_FAIL_BLOCKS=""       # verbatim FAIL tails
_N_EXECUTED=0
_N_FAILED=0
_N_GREEN=0

# JSON-encode a string via jq -Rs (raw, slurped -> a quoted JSON string incl. the
# surrounding quotes). CR-stripped by the jq() wrapper.
_json_str() { printf '%s' "$1" | jq -Rs .; }

# Append a runner object to the JSON accumulator.
_add_runner_json() {
  # $1=id $2=command $3=tier $4=rc $5=outcome $6=families $7=ucount $8=duration
  _ar_obj=$(printf '{"id": %s, "command": %s, "tier": %s, "rc": %s, "outcome": %s, "covered_families": %s, "covered_unit_count": %s, "duration": %s}' \
    "$(_json_str "$1")" "$(_json_str "$2")" "$(_json_str "$3")" "$4" \
    "$(_json_str "$5")" "$(_json_str "$6")" "$7" "$(_json_str "$8")")
  if [ -z "$_RUNNER_JSON" ]; then _RUNNER_JSON="$_ar_obj"; else _RUNNER_JSON="$_RUNNER_JSON,$_ar_obj"; fi
}

_add_family_json() {
  # $1=family $2=status
  _af_obj=$(printf '{"family": %s, "status": %s}' "$(_json_str "$1")" "$(_json_str "$2")")
  if [ -z "$_FAMILY_JSON" ]; then _FAMILY_JSON="$_af_obj"; else _FAMILY_JSON="$_FAMILY_JSON,$_af_obj"; fi
}

echo "=== test-run EXECUTE (flags: $FLAGS) ==="
echo "registry: valid   host-platform: $HOST_PLATFORM   HEAD: $HEAD_SHA"
echo ""

while IFS="$(printf '\t')" read -r _r_id _r_cmd _r_tier _r_covers _r_plat _r_note; do
  [ -n "$_r_id" ] || continue
  [ "$_r_plat" = "-" ] && _r_plat="any"
  _r_families=$(_expand_covers "$_r_covers")
  _r_ucount=$(_covered_unit_count "$_r_covers")

  # Selection gates (no execution).
  if ! _tier_selected "$_r_tier"; then
    _r_outcome="skipped:tier-not-selected"
    echo "  SKIP $_r_id ($_r_tier) — tier-not-selected"
    _add_runner_json "$_r_id" "$_r_cmd" "$_r_tier" "null" "$_r_outcome" "$_r_families" "$_r_ucount" "n/a"
    _MD_RUNNER_ROWS="$_MD_RUNNER_ROWS
| $_r_id | \`$_r_cmd\` | $_r_tier | — | skipped(tier-not-selected) | $_r_families | $_r_ucount | n/a |"
    continue
  fi
  if ! _platform_matches "$_r_plat"; then
    _r_outcome="skipped:platform"
    echo "  SKIP $_r_id — platform (needs $_r_plat, host $HOST_PLATFORM)"
    _add_runner_json "$_r_id" "$_r_cmd" "$_r_tier" "null" "$_r_outcome" "$_r_families" "$_r_ucount" "n/a"
    _MD_RUNNER_ROWS="$_MD_RUNNER_ROWS
| $_r_id | \`$_r_cmd\` | $_r_tier | — | skipped(platform) | $_r_families | $_r_ucount | n/a |"
    continue
  fi

  # Execute ONCE. Capture rc + output + duration.
  echo "  RUN  $_r_id ($_r_tier): $_r_cmd"
  _r_start=$(date +%s 2>/dev/null || echo 0)
  _r_out=$( (cd "$REPO_ROOT_RESOLVED" && eval "$_r_cmd") 2>&1 ) && _r_rc=0 || _r_rc=$?
  _r_end=$(date +%s 2>/dev/null || echo 0)
  _r_dur=$((_r_end - _r_start))
  [ "$_r_dur" -ge 0 ] 2>/dev/null || _r_dur=0
  _r_duration="${_r_dur}s"

  # Self-gate detection: rc=0 AND the FIRST output line matching ^SKIP: (the
  # e2e-local.sh self-skip emit). A mid-output SKIP never triggers it.
  _r_first_line=$(printf '%s\n' "$_r_out" | head -1)
  if [ "$_r_rc" -eq 0 ] && printf '%s' "$_r_first_line" | grep -q '^SKIP:'; then
    _r_outcome="skipped:self-gated"
    echo "       -> skipped(self-gated): $_r_first_line"
    _add_runner_json "$_r_id" "$_r_cmd" "$_r_tier" "0" "$_r_outcome" "$_r_families" "$_r_ucount" "$_r_duration"
    _MD_RUNNER_ROWS="$_MD_RUNNER_ROWS
| $_r_id | \`$_r_cmd\` | $_r_tier | 0 | skipped(self-gated) | $_r_families | $_r_ucount | $_r_duration |"
    continue
  fi

  _N_EXECUTED=$((_N_EXECUTED + 1))
  if [ "$_r_rc" -eq 0 ]; then
    _r_outcome="pass"
    _N_GREEN=$((_N_GREEN + 1))
    echo "       -> pass (rc=0, $_r_duration)"
  else
    _r_outcome="fail"
    _N_FAILED=$((_N_FAILED + 1))
    echo "       -> FAIL (rc=$_r_rc, $_r_duration)"
    # Attach the verbatim FAIL lines (or the output tail if no FAIL: lines).
    _r_fail=$(printf '%s\n' "$_r_out" | grep -iE '^\s*(FAIL|ERROR)' || true)
    [ -n "$_r_fail" ] || _r_fail=$(printf '%s\n' "$_r_out" | tail -20)
    _MD_FAIL_BLOCKS="$_MD_FAIL_BLOCKS

### $_r_id — FAIL (rc=$_r_rc)
\`\`\`
$_r_fail
\`\`\`"
  fi
  _add_runner_json "$_r_id" "$_r_cmd" "$_r_tier" "$_r_rc" "$_r_outcome" "$_r_families" "$_r_ucount" "$_r_duration"
  _MD_RUNNER_ROWS="$_MD_RUNNER_ROWS
| $_r_id | \`$_r_cmd\` | $_r_tier | $_r_rc | $_r_outcome | $_r_families | $_r_ucount | $_r_duration |"
done <<EOF
$RUNNERS_TSV
EOF

# ---- Runner-less families (ci / hook) — family-level ledger rows -------------
# These appear in the ledger OUTSIDE the skipped(<reason>) enum: ci is ci-only,
# hook is a pass/fail installed check. They do NOT touch the aggregate verdict.
_add_family_json "ci" "ci-only"
_MD_FAMILY_ROWS="
| ci | ci-only (runs on GitHub) |"
if _hook_check >/dev/null 2>&1; then
  _add_family_json "hook" "hook-check:pass"
  _MD_FAMILY_ROWS="$_MD_FAMILY_ROWS
| hook | hook-check: pass (installed pre-commit hook present) |"
else
  _add_family_json "hook" "hook-check:fail"
  _MD_FAMILY_ROWS="$_MD_FAMILY_ROWS
| hook | hook-check: fail (no installed pre-commit hook found) |"
fi

# ---- Aggregate (evidence-derived, closed enum) -------------------------------
#   fail        any executed runner failed
#   pass        >=1 executed green AND none failed
#   all-skipped zero executed (all tier/platform/self-gated)  -> NEVER pass
if [ "$_N_FAILED" -gt 0 ]; then
  AGGREGATE="fail"
  EXIT_CODE=1
elif [ "$_N_EXECUTED" -ge 1 ] && [ "$_N_GREEN" -ge 1 ]; then
  AGGREGATE="pass"
  EXIT_CODE=0
else
  AGGREGATE="all-skipped"
  EXIT_CODE=0
fi

# ---- Write report (.md) + ledger (.json) -------------------------------------
mkdir -p "$REPORTS_DIR"
REPORT_MD="$REPORTS_DIR/$TS.md"
LEDGER_JSON="$REPORTS_DIR/$TS.json"

{
  echo "# test-run report — $TS"
  echo "Aggregate: $AGGREGATE"
  echo "Flags:     $FLAGS"
  echo "HEAD:      $HEAD_SHA"
  echo "Host:      $HOST_PLATFORM"
  echo ""
  echo "## Runners"
  echo "| id | command | tier | rc | outcome | covered families | units | duration |"
  echo "|----|---------|------|----|---------|------------------|-------|----------|"
  printf '%s\n' "$_MD_RUNNER_ROWS" | sed '/^$/d'
  echo ""
  echo "## Runner-less families (by design — not skipped)"
  echo "| family | status |"
  echo "|--------|--------|"
  printf '%s\n' "$_MD_FAMILY_ROWS" | sed '/^$/d'
  if [ -n "$_MD_FAIL_BLOCKS" ]; then
    echo ""
    echo "## Failures (verbatim)"
    printf '%s\n' "$_MD_FAIL_BLOCKS"
  fi
  echo ""
  echo "## Legend"
  echo "outcome pass/fail = the runner executed (rc derived). skipped(<reason>) = not executed"
  echo "(tier-not-selected / platform / self-gated). all-skipped aggregate is NEVER rendered pass."
} > "$REPORT_MD"

# Ledger: every string encoded via jq -Rs (CR-stripped). Assemble the top-level
# object from the pre-encoded pieces. Runner + family arrays are raw JSON.
{
  printf '{\n'
  printf '  "schema": 1,\n'
  printf '  "timestamp": %s,\n' "$(_json_str "$TS")"
  printf '  "head_sha": %s,\n' "$(_json_str "$HEAD_SHA")"
  printf '  "repo_root": %s,\n' "$(_json_str "$REPO_ROOT_RESOLVED")"
  printf '  "host_platform": %s,\n' "$(_json_str "$HOST_PLATFORM")"
  printf '  "flags": %s,\n' "$(_json_str "$FLAGS")"
  printf '  "aggregate": %s,\n' "$(_json_str "$AGGREGATE")"
  printf '  "runners": [%s],\n' "$_RUNNER_JSON"
  printf '  "families": [%s]\n' "$_FAMILY_JSON"
  printf '}\n'
} > "$LEDGER_JSON"

# Validate the ledger parses (a corrupt ledger is worse than none — fail loud).
if command -v jq >/dev/null 2>&1; then
  jq empty "$LEDGER_JSON" 2>/dev/null || {
    echo "test-run.sh: WARNING — the generated ledger is not valid JSON ($LEDGER_JSON)" >&2
  }
fi

echo ""
echo "aggregate: $AGGREGATE (executed=$_N_EXECUTED green=$_N_GREEN failed=$_N_FAILED)"
echo "report: $REPORT_MD"
echo "ledger: $LEDGER_JSON"
exit "$EXIT_CODE"
