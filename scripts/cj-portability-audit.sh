#!/usr/bin/env bash
# cj-portability-audit.sh — static dependency lint for declared skill portability.
#
# The workbench ships skills meant to run in ANY repo, but some declare
# `portability: standalone` in skills-catalog.json while quietly depending on
# repo-local artifacts a target repo will not have (root scripts/*.sh helpers,
# root config, CLAUDE.md conventions, the manifest `.source` reach-back).
# This engine compares the declared `portability` field against each skill's
# ACTUAL executed dependencies and emits a per-skill verdict.
#
# Pattern precedent: scripts/cj-repo-init.sh (engine-in-script / AUQ-in-prose
# split, CLAUDE.md "Novel pattern callout"). This script does the static lint
# ONLY; the /CJ_portability-audit SKILL.md prose owns the rich report rendering.
#
# Two entry points share this engine:
#   - /CJ_portability-audit skill  -> rich per-skill report table.
#   - scripts/validate.sh advisory check -> prints findings, exits 0 in v1.
#
# STRICT TIER LADDER (the bar is "works in a repo that has never seen this
# workbench"). Each tier's ALLOWED dependency set:
#   standalone  — own bundled scripts (skills/<name>/scripts/) + the doc-spec
#                 contract files (spec/doc-spec.md, docs/**, TODOS.md,
#                 work-items/). NOTHING else.
#   local-only  — standalone's set PLUS the user's ~/.claude deployed state.
#   workbench   — everything PLUS root scripts/*.sh, the `.source` reach-back,
#                 CLAUDE.md reads, root config (skills-catalog.json, VERSION, …).
# A dep EXCEEDING the declared tier is a FINDING:
#   "<skill> declared <tier> but depends on <dep> (needs <higher-tier>)".
# An unknown `portability` value is itself a finding.
#
# EXECUTED vs DOCUMENTED precision (avoids an all-red table of noise): every
# SKILL.md *documents* scripts in prose; a naive grep flags all of them. So:
#   EXECUTED   = a ref in a runnable position — `bash "$X"` / `"$X" …` /
#                `source "$X"` / `[ -f "$X" ]` / `[ -x "$X" ]` inside a ```bash
#                fence or an engine script. Candidate findings.
#   DOCUMENTED = a ref only in prose / a table / a comment. Informational note,
#                NOT a finding.
#
# Carve-outs:
#   - Bundled-own-script: a scripts/*.sh ref resolving under the skill's OWN dir
#     (skills/<name>/scripts/…) is portable + deployed -> OK, never a finding.
#     Only ROOT (./scripts/…) helpers are candidates.
#   - Self-resolution preamble (SCOPED to declared tier): the engine-locate
#     block ("repo-local first via git rev-parse / [ -f .../scripts/X ], else
#     the manifest `.source`") references a ROOT scripts/*.sh. For a skill
#     declared workbench/local-only it is OK-with-note; for a skill declared
#     standalone it is a FINDING (it proves the skill cannot run with zero
#     workbench present, contradicting the standalone claim).
#   - portability_requires: an operator-adjudicated accepted-deps catalog field.
#     A listed dep is OK; a listed-but-unreferenced dep is an informational note
#     ("portability_requires entry 'X' no longer referenced"), never a finding.
#
# Modes:
#   (default)            audit the catalog-derived set; print the per-skill
#                        verdict table + a machine-readable FINDINGS=<n> tail.
#                        Honors portability_requires. Exit 0 (advisory) unless
#                        PORTABILITY_STRICT=1 (then exit 1 when findings remain).
#   --no-adjudication    same audit but IGNORE portability_requires (the raw,
#                        pre-adjudication view — demonstrates the audit is
#                        non-no-op; used by the test.sh fixture + E2E).
#   --skill <name>       restrict the audit to ONE catalog skill (testing).
#   --catalog <path>     audit a custom catalog (default skills-catalog.json).
#                        The skill source tree is resolved relative to the
#                        catalog's repo root (its files[] are repo-relative).
#   --help|-h            usage.
#
# Exit codes: 0 = advisory clean / advisory-with-findings (default v1 posture);
#             1 = findings remain AND PORTABILITY_STRICT=1, or a usage error.

set -uo pipefail

# Strip CRLF from jq output on Windows (jq.exe writes \r\n). No-op on Unix.
jq() { command jq "$@" | tr -d '\r'; }

PROG="cj-portability-audit.sh"

usage() {
  cat <<'USAGE'
cj-portability-audit.sh — static dependency lint for declared skill portability.

Usage:
  cj-portability-audit.sh                  audit all skills; print verdict table; exit 0 (advisory)
  cj-portability-audit.sh --no-adjudication audit IGNORING portability_requires (raw pre-adjudication view)
  cj-portability-audit.sh --skill <name>   audit a single catalog skill
  cj-portability-audit.sh --catalog <path> audit a custom catalog (skill tree resolved vs its repo root)
  cj-portability-audit.sh --help           this message

Env:
  PORTABILITY_STRICT=1   flip the default-mode exit code to 1 when findings remain
                         (the documented future hard-fail path; advisory by default).

Exit: 0 = advisory (default); 1 = findings remain under PORTABILITY_STRICT=1, or usage error.
USAGE
}

# ----- arg parse -----
MODE="audit"          # audit | audit-raw
ONLY_SKILL=""
CATALOG_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --no-adjudication) MODE="audit-raw" ;;
    --skill)           ONLY_SKILL="${2:-}"; shift ;;
    --catalog)         CATALOG_OVERRIDE="${2:-}"; shift ;;
    --help|-h)         usage; exit 0 ;;
    *) echo "$PROG: unknown argument '$1'" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || { echo "$PROG: error: jq is required." >&2; exit 1; }

# ----- locate the catalog + repo root -----
# The catalog's files[] entries are repo-root-relative, so the skill source
# tree resolves against the catalog's directory.
if [ -n "$CATALOG_OVERRIDE" ]; then
  CATALOG="$CATALOG_OVERRIDE"
  [ -f "$CATALOG" ] || { echo "$PROG: error: catalog not found at $CATALOG" >&2; exit 1; }
  REPO_ROOT="$(cd "$(dirname "$CATALOG")" && pwd)"
else
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [ -z "$REPO_ROOT" ]; then
    # Fall back to the script's parent dir (scripts/ -> repo root).
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi
  CATALOG="$REPO_ROOT/skills-catalog.json"
  [ -f "$CATALOG" ] || { echo "$PROG: error: skills-catalog.json not found at $CATALOG" >&2; exit 1; }
fi
jq empty "$CATALOG" >/dev/null 2>&1 || { echo "$PROG: error: $CATALOG is not valid JSON." >&2; exit 1; }

# ----- root config-file literals (only these + the slug are literals) -----
# Deliberately EXCLUDES the doc-spec contract files (spec/doc-spec.md, docs/**,
# TODOS.md, work-items/) — those are part of EVERY adopting repo's doc surface
# (doc-spec.md self-bootstraps; the docs are stub-scaffolded), so a skill reaching
# them is within EVERY tier's allowed set (not a workbench-coupling signal). Only
# artifacts that exist SOLELY in the workbench clone are listed here. (No skill
# NAME is hardcoded anywhere in this engine — the audited set is derived from the
# catalog at runtime.)
ROOT_CONFIG_FILES="skills-catalog.json template-registry.json VERSION"
GITHUB_SLUG="jcl2018/claude-skills-templates"

# ----- derive the root scripts/*.sh helper set DYNAMICALLY (glob basenames) ---
# A hardcoded list is the exact "baked-in workbench specifics" rot this skill
# exists to catch — the repo adds root helpers often. Glob at runtime.
ROOT_SCRIPT_BASENAMES=""
if [ -d "$REPO_ROOT/scripts" ]; then
  for _s in "$REPO_ROOT"/scripts/*.sh; do
    [ -f "$_s" ] || continue
    ROOT_SCRIPT_BASENAMES="$ROOT_SCRIPT_BASENAMES $(basename "$_s")"
  done
fi

# ----- the audited skill set (runtime-derived, NEVER hardcoded) -----
# Check 14/15b selector: status != "deprecated" AND non-empty files[].
SKILL_SET=$(jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' "$CATALOG")
if [ -n "$ONLY_SKILL" ]; then
  SKILL_SET=$(printf '%s\n' "$SKILL_SET" | grep -Fx "$ONLY_SKILL" || true)
  [ -n "$SKILL_SET" ] || { echo "$PROG: error: '$ONLY_SKILL' is not an audited catalog skill." >&2; exit 1; }
fi

# ----- closed tier enum + ordering -----
# standalone(0) < local-only(1) < workbench(2). A dep's minimum tier is the
# lowest tier whose ALLOWED set contains it; a finding fires when that exceeds
# the declared tier.
_tier_rank() {
  case "$1" in
    standalone) echo 0 ;;
    local-only) echo 1 ;;
    workbench)  echo 2 ;;
    *)          echo 99 ;;   # unknown — sentinel
  esac
}

# ----- per-skill state (reset in audit_skill) -----
# Verdict accumulators.
FINDINGS=()     # finding strings for the current skill (deduped on text)
NOTES=()        # informational-note strings for the current skill (deduped on text)

# Append to FINDINGS[] only if the exact text isn't already present.
_add_finding() {
  local f
  for f in ${FINDINGS[@]+"${FINDINGS[@]}"}; do
    [ "$f" = "$1" ] && return 0
  done
  FINDINGS+=("$1")
}
# Append to NOTES[] only if the exact text isn't already present.
_add_note() {
  local n
  for n in ${NOTES[@]+"${NOTES[@]}"}; do
    [ "$n" = "$1" ] && return 0
  done
  NOTES+=("$1")
}

# Collect the files that belong to a skill: catalog files[] + the skill dir's
# *.md + any scripts/*.sh under the skill dir. Emits absolute paths, one/line.
_collect_skill_files() {
  local name="$1" f0 sdir
  # catalog files[] (repo-relative)
  jq -r --arg n "$name" '.[] | select(.name==$n) | .files[]?' "$CATALOG" 2>/dev/null \
    | while IFS= read -r f; do [ -n "$f" ] && echo "$REPO_ROOT/$f"; done
  # the skill's source dir = dirname(files[0])
  f0=$(jq -r --arg n "$name" '.[] | select(.name==$n) | (.files // []) | .[0] // ""' "$CATALOG" 2>/dev/null)
  [ -n "$f0" ] || return 0
  sdir="$REPO_ROOT/$(dirname "$f0")"
  [ -d "$sdir" ] || return 0
  # every *.md and scripts/*.sh under the skill dir (deduped against files[] below)
  find "$sdir" -type f \( -name '*.md' -o -name '*.sh' \) 2>/dev/null
}

# Read the skill's declared portability tier.
_skill_tier() {
  jq -r --arg n "$1" '.[] | select(.name==$n) | .portability // ""' "$CATALOG" 2>/dev/null
}

# Read the skill's portability_requires accepted-deps (one per line).
_skill_accepted() {
  jq -r --arg n "$1" '.[] | select(.name==$n) | (.portability_requires // [])[]' "$CATALOG" 2>/dev/null
}

# ----- the awk classifier program (written once to a temp file) ---------------
# Kept in an external program file (NOT an inline -v-interpolated string) so the
# regexes can use single + double quotes freely without shell-quoting hazards.
# Reads one source FILE on stdin-equiv (passed as ARGV). Tracks ```bash / ```sh
# fences. For each repo-local dependency token, decides EXECUTED vs DOCUMENTED
# vs PREAMBLE and emits a TAB record: <class>\t<dep-token>\t<dep-kind>.
#   class    ∈ {EXECUTED, DOCUMENTED, PREAMBLE}
#   dep-kind ∈ {root-script, source-reachback, config, claude-md, slug}
# PREAMBLE = an executed ref inside the self-resolution / engine-locate block (a
# `.source`-guarded root-script reach-back) — tier-scoped downstream.
_AWK_PROG=""
_init_awk_prog() {
  _AWK_PROG=$(mktemp "${TMPDIR:-/tmp}/cj-pa-awk.XXXXXX") || { echo "$PROG: mktemp failed" >&2; exit 1; }
  cat > "$_AWK_PROG" <<'AWK'
BEGIN {
  n = split(root_scripts, a, " "); for (i=1;i<=n;i++) if (a[i]!="") RS_set[a[i]]=1
  n = split(cfgs, c, " ");         for (i=1;i<=n;i++) if (c[i]!="") CFG_set[c[i]]=1
  infence = 0
}
# Fence tracking. A bare ``` toggles; an opening ```bash/```sh is runnable (1);
# any other opening fence is a non-shell block whose body is DOCUMENTED (2).
/^[ \t]*```/ {
  if (infence) { infence = 0 }
  else if ($0 ~ /^[ \t]*```(bash|sh)[ \t]*$/) { infence = 1 }
  else { infence = 2 }
  next
}
{
  line = $0
  # *.sh source files are runnable throughout (CJ_PA_RUNNABLE=1); *.md only
  # inside a bash/sh fence.
  runnable = (ENVIRON["CJ_PA_RUNNABLE"] == "1") || (infence == 1)
  # A shell comment line (first non-blank char #) executes nothing — its tokens
  # are DOCUMENTED, never EXECUTED. Without this, a prose comment containing a
  # paren or a $VAR/scripts path (e.g. `# (CLAUDE.md), so ...` or `# see
  # scripts/foo.sh`) trips is_exec's statement-start cue and is mis-read as an
  # executed read (the D000032 quoted-literal FP class, applied to comment lines).
  if (line ~ /^[ \t]*#/) runnable = 0

  # ---- root scripts/<base>.sh refs (each occurrence on the line) ----
  tmp = line
  while (match(tmp, /scripts\/[A-Za-z0-9._-]+\.sh/)) {
    tok = substr(tmp, RSTART, RLENGTH)
    base = tok; sub(/^scripts\//, "", base)
    if (base in RS_set) {
      if (runnable && is_exec(line, tok)) {
        if (is_preamble(line)) emit("PREAMBLE", tok, "root-script")
        else                   emit("EXECUTED", tok, "root-script")
      } else {
        emit("DOCUMENTED", tok, "root-script")
      }
    }
    tmp = substr(tmp, RSTART + RLENGTH)
  }

  # ---- .source reach-back (manifest .source read in the engine-locate idiom) --
  if (line ~ /skills-templates\.json/ && line ~ /\.source/) {
    if (runnable) emit("PREAMBLE", ".source", "source-reachback")
    else          emit("DOCUMENTED", ".source", "source-reachback")
  }

  # ---- root config files ----
  for (cf in CFG_set) {
    if (index(line, cf) > 0) {
      if (runnable && is_exec(line, cf)) emit("EXECUTED", cf, "config")
      else                               emit("DOCUMENTED", cf, "config")
    }
  }

  # ---- CLAUDE.md convention reads ----
  if (index(line, "CLAUDE.md") > 0) {
    if (runnable && is_exec(line, "CLAUDE.md")) emit("EXECUTED", "CLAUDE.md", "claude-md")
    else                                        emit("DOCUMENTED", "CLAUDE.md", "claude-md")
  }

  # ---- GitHub slug ----
  if (index(line, slug) > 0) {
    if (runnable) emit("EXECUTED", slug, "slug")
    else          emit("DOCUMENTED", slug, "slug")
  }
}
# is_exec: does TOKEN sit in a runnable position on LINE? Cues immediately
# before the token: bash|sh|source|. / [ -f|-x|-r|-s|-d / start-of-command /
# command-substitution; OR a $VAR/scripts/ derived path anywhere on the line.
function is_exec(l, t,    pre, idx) {
  idx = index(l, t)
  if (idx == 0) return 0
  pre = substr(l, 1, idx-1)
  if (pre ~ /(bash|sh|source|\.)[ \t]+[^ \t]*$/) return 1
  if (pre ~ /\[[ \t]+-[fxrsd][ \t]+[^ \t]*$/) return 1
  # statement-start command: the token must come IMMEDIATELY after a delimiter +
  # optional whitespace (nothing between). The old `[^ \t]*$` tail let a quote
  # through, so a quoted seed-data literal at line-start (e.g. `    "CLAUDE.md",`
  # inside a whitelist array the engine WRITES) was mis-read as an executed read.
  # Requiring `$` after the whitespace keeps real bare-command execution while
  # dropping indented/quoted string literals (the seed-data false positive).
  if (pre ~ /(^|[;&|(])[ \t]*$/) return 1
  if (pre ~ /\$\([ \t]*$/) return 1
  if (l ~ /\$(REPO_ROOT|_SRC|_S|_RI|root|ROOT|src|SRC)[^ \t]*\/?scripts\//) return 1
  return 0
}
# is_preamble: is LINE part of the engine-locate / self-resolution block?
function is_preamble(l) {
  if (l ~ /rev-parse[ \t]+--show-toplevel/) return 1
  if (l ~ /\$_SRC\/scripts\//) return 1
  if (l ~ /\$_S\/scripts\//) return 1
  if (l ~ /skills-templates\.json/) return 1
  return 0
}
function emit(cls, tok, kind) { printf "%s\t%s\t%s\n", cls, tok, kind }
AWK
}

# Classify one source FILE -> TAB records on stdout. Honors CJ_PA_RUNNABLE.
_classify_file() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk -v slug="$GITHUB_SLUG" -v root_scripts="$ROOT_SCRIPT_BASENAMES" \
      -v cfgs="$ROOT_CONFIG_FILES" -f "$_AWK_PROG" "$file"
}

# ----- per-skill audit --------------------------------------------------------
# Populates FINDINGS[] + NOTES[] and echoes the verdict line.
audit_skill() {
  local name="$1"
  FINDINGS=(); NOTES=()
  local tier; tier=$(_skill_tier "$name")
  local declared_rank; declared_rank=$(_tier_rank "$tier")
  local sdir f0; f0=$(jq -r --arg n "$name" '.[] | select(.name==$n) | (.files // []) | .[0] // ""' "$CATALOG" 2>/dev/null)
  sdir="$REPO_ROOT/$(dirname "$f0")"

  # F000049/S000085: a skill that wires a deployed `_cj-shared/scripts/`
  # resolution tier resolves its shared root scripts from the user's ~/.claude
  # deployed home (local-only tier), not the source clone (workbench). Detect
  # that tier so a root-script reach downgrades workbench->local-only for such a
  # skill. Precise: only skills that actually wire the deployed tier are
  # downgraded — a skill reaching $_REPO_ROOT/scripts or $_S/scripts with NO
  # `_cj-shared` fallback stays workbench (no false-negative).
  local has_deployed_tier=0 _sf
  while IFS= read -r _sf; do
    [ -n "$_sf" ] || continue
    # shellcheck disable=SC2016  # literal $_SHARED / $_CR_SHARED are grep-regex tokens, not shell expansions
    if grep -qE '_cj-shared|\$_SHARED/|\$_CR_SHARED/|\$\{_SHARED|\$\{_CR_SHARED' "$_sf" 2>/dev/null; then
      has_deployed_tier=1; break
    fi
  done <<EOF
$(_collect_skill_files "$name")
EOF

  # Unknown tier is itself a finding.
  if [ "$declared_rank" = "99" ]; then
    FINDINGS+=("$name declared '$tier' but '$tier' is not a known portability tier (expected standalone|local-only|workbench)")
  fi

  # Accepted-deps set (adjudicated). In --no-adjudication mode we ignore it.
  local accepted=""
  if [ "$MODE" = "audit" ]; then
    accepted=$(_skill_accepted "$name")
  fi
  # Track which accepted entries we actually saw referenced (for stale notes).
  local accepted_seen=""

  # Gather all classified hits across the skill's files. De-dup per (dep,class).
  local seen_keys=""
  local files; files=$(_collect_skill_files "$name" | LC_ALL=C sort -u)

  local file cls tok kind runflag
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    # *.sh files are runnable throughout; *.md only inside ```bash fences.
    case "$file" in
      *.sh) runflag=1 ;;
      *)    runflag=0 ;;
    esac
    while IFS=$'\t' read -r cls tok kind; do
      [ -n "$cls" ] || continue

      # Bundled-own-script carve-out: a root-script token is only a candidate if
      # it is a ROOT helper. A scripts/*.sh ref that resolves under the skill's
      # OWN dir is OK and never reaches here as kind=root-script (we check the
      # basename against the ROOT set), but double-guard: if a same-named file
      # exists under the skill dir, treat as bundled-own -> skip.
      if [ "$kind" = "root-script" ]; then
        local base="${tok#scripts/}"
        if [ -f "$sdir/scripts/$base" ]; then
          continue   # bundled own script — OK, never a finding
        fi
      fi

      # Dedup identical (class,dep) pairs within the skill.
      local key="$cls|$tok"
      case " $seen_keys " in *" $key "*) continue ;; esac
      seen_keys="$seen_keys $key"

      # DOCUMENTED hits are ALWAYS informational notes, NEVER findings — the
      # EXECUTED-vs-documented precision rule (SPEC AC-2): every SKILL.md
      # *documents* scripts in prose; a naive grep would flag them all and the
      # table would be an all-red wall of noise. Only an EXECUTED reach (or, for
      # config/CLAUDE/slug, an executed read) is a candidate finding. We surface a
      # note ONLY for a prose mention of a ROOT script / .source reach-back (the
      # interesting class); config/CLAUDE/slug prose mentions are ubiquitous and
      # not even worth a note.
      # DOCUMENTED hits are dropped silently — they are true-but-uninteresting
      # (every SKILL.md mentions scripts in prose). Surfacing them would bloat the
      # table; the verdict that matters is whether an EXECUTED reach exceeds the
      # declared tier. (A prose mention is recorded nowhere — keeps the table
      # scannable, AC-2.)
      if [ "$cls" = "DOCUMENTED" ]; then
        continue
      fi

      # The bare `.source` reach-back (the manifest read in the engine-locate /
      # passive-update-nudge idiom) is NOT itself the finding — it is the SIGNAL
      # of a self-resolution preamble. The ROOT scripts/*.sh the preamble guards
      # carries the tier finding (below). On its own, `.source` reaching only a
      # NON-.sh root helper (e.g. the `skills-update-check` update nudge present
      # in every CJ_ SKILL.md) must not red-flag every standalone skill — it is a
      # fail-soft nudge, not a hard dependency. Workbench/local-only declared ->
      # an OK-with-note (the meaningful "this skill reaches .source" signal);
      # standalone -> dropped silently (the root .sh engine reach, if any, is
      # flagged on its own token; the bare nudge is not a finding).
      if [ "$kind" = "source-reachback" ]; then
        if [ "$declared_rank" -ge 1 ]; then
          _add_note "self-resolution preamble reads manifest .source (OK for $tier)"
        fi
        continue
      fi

      # The minimum tier this dep requires.
      local need_tier need_rank
      case "$kind" in
        root-script)
          # A shared root script now travels with the install (deposited to the
          # `_cj-shared/scripts/` home by skills-deploy). A skill that wires the
          # deployed tier resolves it from ~/.claude (local-only); without that
          # tier it still needs the source clone (workbench).
          if [ "$has_deployed_tier" = "1" ]; then need_tier="local-only"; need_rank=1
          else need_tier="workbench"; need_rank=2; fi ;;
        config|claude-md|slug)
          need_tier="workbench"; need_rank=2 ;;
        workitems)
          need_tier="standalone"; need_rank=0 ;;   # repo-init prereq
        *)
          need_tier="workbench"; need_rank=2 ;;
      esac

      # PREAMBLE root-script (self-resolution / engine-locate reach to a ROOT
      # scripts/*.sh), scoped to tier:
      #   workbench / local-only -> OK-with-note (those tiers may need the workbench).
      #   standalone             -> FINDING (proves it can't run with zero workbench).
      if [ "$cls" = "PREAMBLE" ]; then
        if [ "$declared_rank" -ge 1 ]; then
          _add_note "self-resolution preamble reaches $tok (OK for $tier)"
          continue
        fi
        need_tier="workbench"; need_rank=2   # standalone: fall through to finding
      fi

      # Adjudication: a portability_requires-listed dep is OK.
      if [ "$MODE" = "audit" ] && [ -n "$accepted" ]; then
        if printf '%s\n' "$accepted" | grep -Fxq "$tok"; then
          accepted_seen="$accepted_seen
$tok"
          continue
        fi
      fi

      # Within-tier deps are OK.
      if [ "$need_rank" -le "$declared_rank" ]; then
        continue
      fi

      # Otherwise: a dep exceeding the declared tier -> FINDING (deduped on text).
      _add_finding "$name declared $tier but depends on $tok (needs $need_tier)"
    done <<EOF
$(CJ_PA_RUNNABLE="$runflag" _classify_file "$file")
EOF
  done <<EOF
$files
EOF

  # Stale portability_requires entries: listed but never referenced.
  if [ "$MODE" = "audit" ] && [ -n "$accepted" ]; then
    local a
    while IFS= read -r a; do
      [ -n "$a" ] || continue
      case "$accepted_seen" in
        *"$a"*) : ;;
        *) NOTES+=("portability_requires entry '$a' no longer referenced") ;;
      esac
    done <<EOF
$accepted
EOF
  fi

  # ----- verdict -----
  # Emit the verdict as line 1, then one `note: <text>` line per note. The caller
  # reads line 1 as the verdict and renders the rest indented. (audit_skill runs
  # in a command substitution, so NOTES[]/FINDINGS[] do NOT survive into the
  # parent — everything the caller needs must go to stdout here.)
  if [ "${#FINDINGS[@]}" -gt 0 ]; then
    local joined=""
    local fitem
    for fitem in ${FINDINGS[@]+"${FINDINGS[@]}"}; do
      joined="${joined:+$joined; }$fitem"
    done
    echo "findings: $joined"
  elif [ "${#NOTES[@]}" -gt 0 ]; then
    echo "portable-with-notes"
  else
    echo "portable"
  fi
  local nt
  for nt in ${NOTES[@]+"${NOTES[@]}"}; do
    echo "note: $nt"
  done
}

# ----- run over the set + render the table -----
_init_awk_prog
trap 'rm -f "$_AWK_PROG"' EXIT INT TERM

TOTAL_FINDINGS=0
TOTAL_SKILLS=0

echo "CJ_portability-audit — declared-vs-actual portability lint"
echo "Repo:    $REPO_ROOT"
echo "Catalog: ${CATALOG#"$REPO_ROOT"/}"
[ "$MODE" = "audit-raw" ] && echo "Mode:    raw (ignoring portability_requires adjudication)"
echo ""
printf '%-26s | %-11s | %s\n' "skill" "declared" "verdict"
printf '%-26s-+-%-11s-+-%s\n' "--------------------------" "-----------" "----------------------------------------"

while IFS= read -r name; do
  [ -n "$name" ] || continue
  TOTAL_SKILLS=$((TOTAL_SKILLS + 1))
  tier=$(_skill_tier "$name")
  # audit_skill emits the verdict on line 1, then `note: <text>` lines. Capture
  # all of it, then split (the array does NOT survive the subshell — see the
  # verdict-emission comment in audit_skill).
  audit_out=$(audit_skill "$name")
  verdict=$(printf '%s\n' "$audit_out" | head -1)
  printf '%-26s | %-11s | %s\n' "$name" "$tier" "$verdict"
  # Render any note lines indented under the verdict row.
  printf '%s\n' "$audit_out" | tail -n +2 | while IFS= read -r nl; do
    [ -n "$nl" ] || continue
    printf '%-26s | %-11s |   %s\n' "" "" "$nl"
  done
  case "$verdict" in
    findings:*) TOTAL_FINDINGS=$((TOTAL_FINDINGS + 1)) ;;
  esac
done <<EOF
$SKILL_SET
EOF

echo ""
echo "FINDINGS=$TOTAL_FINDINGS"
echo "SKILLS_AUDITED=$TOTAL_SKILLS"

# ----- exit code: advisory by default; strict opt-in -----
if [ "$TOTAL_FINDINGS" -gt 0 ] && [ "${PORTABILITY_STRICT:-0}" = "1" ]; then
  echo "RESULT: FINDINGS (PORTABILITY_STRICT=1 -> non-zero exit)"
  exit 1
fi
echo "RESULT: OK (advisory)"
exit 0
