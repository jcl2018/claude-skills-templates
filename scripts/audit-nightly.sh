#!/usr/bin/env bash
# Nightly agent-judged doc/test audit — relocated off the CJ_goal_* build hot path.
#
# F000076: the expensive Stage-2/3 audit (`/CJ_doc_audit` + `/CJ_test_audit`) used
# to run inline on every orchestrated build (the post-sync audit + QA-audit
# checkpoint). It is ADVISORY (findings never hard-block) and its deterministic
# Stage-1 already re-runs per-PR in validate.sh, so it was moved here: a nightly
# `claude --print` sweep of `main` that files findings to a GitHub issue instead
# of taxing every build. The per-PR deterministic gate (validate.sh) is untouched.
#
# SKIPs cleanly (exit 0) without a model key, so a normal `test.sh` and any
# secret-less fork never spend. Advisory by construction: a claude/gh hiccup is
# reported, never failed — this job never goes red on infra noise.
#
# Usage:
#   bash scripts/audit-nightly.sh                 # run the audit, file/update the drift issue
#   bash scripts/audit-nightly.sh --dry-run       # print the plan; run nothing, spend nothing
#   bash scripts/audit-nightly.sh --no-issue      # run the audit, print counts, do NOT touch gh
#   AUDIT_BUDGET_USD=3 bash scripts/audit-nightly.sh   # override the per-run budget cap
#
# Cadence: nightly on main (.github/workflows/audit-nightly.yml) + workflow_dispatch.
set -euo pipefail

. "$(dirname "$0")/lib.sh"

AUDIT_LABEL="${AUDIT_LABEL:-audit-drift}"
AUDIT_BUDGET_USD="${AUDIT_BUDGET_USD:-2.00}"
AUDIT_REPORT="${AUDIT_REPORT:-$REPO_ROOT/audit-nightly-report.md}"
DRY_RUN=0
FILE_ISSUE=1

for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=1 ;;
    --no-issue) FILE_ISSUE=0 ;;
    -h|--help)  sed -n '20,25p' "$0"; exit 0 ;;
    *) echo "audit-nightly: unknown argument: $arg" >&2; exit 2 ;;
  esac
done

# --- Parse the two machine-readable FINDINGS counts from the model's text -----
# Sourced-free helper kept tiny so the test can exercise it via a canned run.
# Prints "<doc> <test>" (defaulting a missing/garbled count to 0).
_parse_findings() {
  local txt d t
  txt=$(cat)
  d=$(printf '%s\n' "$txt" | sed -n 's/^DOC_AUDIT_FINDINGS=\([0-9][0-9]*\).*/\1/p'  | tail -1)
  t=$(printf '%s\n' "$txt" | sed -n 's/^TEST_AUDIT_FINDINGS=\([0-9][0-9]*\).*/\1/p' | tail -1)
  printf '%s %s\n' "${d:-0}" "${t:-0}"
}

# --- SKIP guard: no model access => SKIP (exit 0), never spend ----------------
if ! command -v claude >/dev/null 2>&1; then
  echo "SKIP: claude CLI not found in PATH (the nightly audit needs the claude CLI)."
  exit 0
fi
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "SKIP: ANTHROPIC_API_KEY not set (the nightly audit runs only with a model key; a normal test run never spends)."
  exit 0
fi

# --- The audit prompt (read-only; the two counts are the contract) ------------
AUDIT_PROMPT=$(cat <<'PROMPT'
Run /CJ_doc_audit and then /CJ_test_audit over the CURRENT repository, standalone,
all three stages each. This is a READ-ONLY report: do NOT write any doc/overlay
fixes. After both audits, output EXACTLY these two lines on their own (they are
machine-parsed), then a fenced ```audit block containing each skill's per-stage
findings detail verbatim:
DOC_AUDIT_FINDINGS=<integer total doc-audit findings>
TEST_AUDIT_FINDINGS=<integer total test-audit findings>
PROMPT
)

if [ "$DRY_RUN" = "1" ]; then
  echo "DRY-RUN: nightly doc/test audit plan (nothing run, nothing spent)"
  echo "  invoke:      claude --print /CJ_doc_audit + /CJ_test_audit (read-only, all stages)"
  echo "  plugin-dir:  $REPO_ROOT/skills"
  echo "  budget:      \$$AUDIT_BUDGET_USD"
  echo "  report file: $AUDIT_REPORT"
  if [ "$FILE_ISSUE" = "1" ]; then
    echo "  on findings: create-or-update the open GitHub issue labelled '$AUDIT_LABEL'; on clean, close it"
  else
    echo "  issue:       disabled (--no-issue) — counts printed only"
  fi
  exit 0
fi

# --- Run the audits headless. GH tokens are unset inside the subshell so the
#     model-driven run can never read them (defense-in-depth; run-case.sh idiom). -
echo "Running the nightly doc/test audit via claude --print (budget \$$AUDIT_BUDGET_USD)..." >&2
audit_out=$(
  unset GITHUB_TOKEN GH_TOKEN NPM_TOKEN
  claude -p "$AUDIT_PROMPT" \
    --print \
    --output-format json \
    --plugin-dir "$REPO_ROOT/skills" \
    --add-dir "$REPO_ROOT" \
    --model sonnet \
    --max-budget-usd "$AUDIT_BUDGET_USD" \
    --no-session-persistence \
    --permission-mode bypassPermissions \
    --allowedTools "Bash,Read,Glob,Grep" 2>&1
) && claude_rc=0 || claude_rc=$?

if [ "${claude_rc:-1}" -ne 0 ]; then
  # Advisory job: a cost-cap / auth / retry failure is reported, never failed.
  subtype=$(printf '%s' "$audit_out" | jq -r '.subtype // "unknown"' 2>/dev/null || echo unknown)
  echo "WARN: claude exited ${claude_rc} (subtype: ${subtype}) — advisory job, not failing." >&2
  echo "AUDIT_NIGHTLY: status=claude-error rc=${claude_rc}"
  exit 0
fi

result=$(printf '%s' "$audit_out" | jq -r '.result // empty' 2>/dev/null || true)
read -r doc_n test_n < <(printf '%s' "$result" | _parse_findings)
total=$((doc_n + test_n))

# --- Materialize the report (uploaded as a CI artifact / issue body) ----------
{
  echo "# Nightly doc/test audit — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  echo "HEAD: $(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  echo ""
  echo "- doc-audit findings:  **${doc_n}**"
  echo "- test-audit findings: **${test_n}**"
  echo ""
  echo "\`\`\`audit"
  printf '%s\n' "$result"
  echo "\`\`\`"
} > "$AUDIT_REPORT"

echo "AUDIT_NIGHTLY: doc:${doc_n},test:${test_n} total:${total} report:${AUDIT_REPORT}"

# --- File findings to a single GitHub issue (advisory, best-effort) -----------
if [ "$FILE_ISSUE" = "0" ]; then
  exit 0
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "AUDIT_NIGHTLY: issue=skipped-no-gh"
  exit 0
fi
if [ -z "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]; then
  echo "AUDIT_NIGHTLY: issue=skipped-no-token"
  exit 0
fi

# Ensure the label exists (idempotent; ignore "already exists").
gh label create "$AUDIT_LABEL" --color BFDADC \
  --description "Nightly doc/test audit drift (advisory)" >/dev/null 2>&1 || true

existing=$(gh issue list --label "$AUDIT_LABEL" --state open \
  --json number --jq '.[0].number' 2>/dev/null || true)

if [ "$total" -gt 0 ]; then
  if [ -n "$existing" ]; then
    gh issue comment "$existing" --body-file "$AUDIT_REPORT" >/dev/null 2>&1 \
      && echo "AUDIT_NIGHTLY: issue=updated#${existing}" \
      || echo "AUDIT_NIGHTLY: issue=comment-failed#${existing}"
  else
    gh issue create --title "Nightly doc/test audit drift ($(date -u +%Y-%m-%d))" \
      --label "$AUDIT_LABEL" --body-file "$AUDIT_REPORT" >/dev/null 2>&1 \
      && echo "AUDIT_NIGHTLY: issue=created" \
      || echo "AUDIT_NIGHTLY: issue=create-failed"
  fi
else
  if [ -n "$existing" ]; then
    gh issue close "$existing" \
      --comment "Nightly audit clean ($(date -u +%Y-%m-%d)) — no doc/test drift. Closing." >/dev/null 2>&1 \
      && echo "AUDIT_NIGHTLY: issue=closed#${existing}" \
      || echo "AUDIT_NIGHTLY: issue=close-failed#${existing}"
  else
    echo "AUDIT_NIGHTLY: issue=none-clean"
  fi
fi
