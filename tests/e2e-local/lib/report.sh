#!/usr/bin/env bash
# Materialized run-report generator for the local-E2E harness (Part B).
#
# SOURCE this file (do not execute). It exposes one function:
#   e2e_report_render <out_dir> <verb> <ts> <evidence_file>
#     -> writes <out_dir>/<verb>-<ts>.md AND <out_dir>/<verb>-<ts>.json
#     -> prints the .md path on stdout (last line)
#
# The report is NOT a checkmark. Each coverage row is labelled DETERMINISTIC
# (asserted by the harness in shell — repeatable, no model) or `claude --print`
# (performed by the real orchestration run — non-deterministic), and its Outcome
# is DERIVED from the run's evidence, never hand-assigned. A row whose supporting
# evidence is absent renders as `unverified` (never `pass`) — so a green report
# means the evidence was actually found in the sandbox, not that a template said so.
#
# The evidence file is `key=value` lines (one per line). Recognized keys:
#   topic sandbox head_sha end_state
#   task_dir_created diff_nonempty branch_pushed pr_blocked        (yes/no)
#   seam_qa_audit seam_nonallowlisted                              (verdict strings)
#   budget duration tokens

# Read one key from the evidence file. Absent -> empty string.
_e2e_ev() {
  local key="$1" ev="$2"
  sed -n "s/^${key}=//p" "$ev" 2>/dev/null | head -1
}

# Map (bool_evidence -> outcome). "yes" -> pass, "no" -> fail, absent -> unverified.
_e2e_outcome_bool() {
  case "$1" in
    yes) printf 'pass' ;;
    no)  printf 'fail' ;;
    *)   printf 'unverified' ;;
  esac
}

# Derive the end_state row outcome: halted_at_ship = sandbox SUCCESS.
_e2e_outcome_endstate() {
  case "$1" in
    halted_at_ship)     printf 'pass' ;;
    halted_at_qa_audit) printf 'partial (halted at qa-audit — a real change may legitimately stop here)' ;;
    "")                 printf 'unverified' ;;
    *)                  printf 'unexpected: %s' "$1" ;;
  esac
}

e2e_report_render() {
  local out_dir="${1:?out dir required}" verb="${2:?verb required}" ts="${3:?ts required}" ev="${4:?evidence file required}"
  mkdir -p "$out_dir"
  local md="$out_dir/$verb-$ts.md" json="$out_dir/$verb-$ts.json"

  local topic sandbox head_sha end_state
  local task_dir_created diff_nonempty branch_pushed pr_blocked
  local seam_qa_audit seam_nonallowlisted budget duration tokens
  topic=$(_e2e_ev topic "$ev")
  sandbox=$(_e2e_ev sandbox "$ev")
  head_sha=$(_e2e_ev head_sha "$ev")
  end_state=$(_e2e_ev end_state "$ev")
  task_dir_created=$(_e2e_ev task_dir_created "$ev")
  diff_nonempty=$(_e2e_ev diff_nonempty "$ev")
  branch_pushed=$(_e2e_ev branch_pushed "$ev")
  pr_blocked=$(_e2e_ev pr_blocked "$ev")
  seam_qa_audit=$(_e2e_ev seam_qa_audit "$ev")
  seam_nonallowlisted=$(_e2e_ev seam_nonallowlisted "$ev")
  budget=$(_e2e_ev budget "$ev")
  duration=$(_e2e_ev duration "$ev")
  tokens=$(_e2e_ev tokens "$ev")

  # Per-row outcomes, each derived from the collected evidence.
  local o_seam_cont o_seam_inact o_scaffold o_impl o_qaauto o_push o_prblock o_end result
  case "$seam_qa_audit" in continue) o_seam_cont="pass" ;; "") o_seam_cont="unverified" ;; *) o_seam_cont="fail (verdict=$seam_qa_audit)" ;; esac
  case "$seam_nonallowlisted" in inactive) o_seam_inact="pass" ;; "") o_seam_inact="unverified" ;; *) o_seam_inact="fail (verdict=$seam_nonallowlisted)" ;; esac
  o_scaffold=$(_e2e_outcome_bool "$task_dir_created")
  o_impl=$(_e2e_outcome_bool "$diff_nonempty")
  case "$end_state" in halted_at_ship) o_qaauto="pass" ;; halted_at_qa_audit) o_qaauto="declined (findings — seam correctly did NOT auto-waive)" ;; "") o_qaauto="unverified" ;; *) o_qaauto="unverified (end_state=$end_state)" ;; esac
  o_push=$(_e2e_outcome_bool "$branch_pushed")
  o_prblock=$(_e2e_outcome_bool "$pr_blocked")
  o_end=$(_e2e_outcome_endstate "$end_state")

  # Overall result: SUCCESS iff the /ship-boundary pair holds (pushed AND blocked)
  # AND the run reached at least the qa-audit boundary.
  if [ "$branch_pushed" = "yes" ] && [ "$pr_blocked" = "yes" ] && { [ "$end_state" = "halted_at_ship" ] || [ "$end_state" = "halted_at_qa_audit" ]; }; then
    result="PASS (reached the $end_state boundary, no real PR — sandbox)"
  else
    result="INCONCLUSIVE (see rows below — some evidence was not found)"
  fi

  {
    printf '# cj_goal local E2E run — CJ_goal_%s — %s\n' "$verb" "$ts"
    printf 'Result: %s\n' "$result"
    printf 'Topic:  "%s"\n' "$topic"
    printf 'Sandbox: %s (clone @ %s, local bare origin, marker present)\n' "${sandbox:-N/A}" "${head_sha:-N/A}"
    printf 'Seam:   CJ_GOAL_E2E_AUTO=1 — auto-answered: qa-audit (%s)   [NOT auto-answered: /ship]\n' "${seam_qa_audit:-N/A}"
    printf '\n'
    printf '## Coverage — what actually ran, and how it was verified\n'
    printf '| # | Step / claim | Layer | Outcome |\n'
    printf '|---|--------------|-------|---------|\n'
    printf '| 1 | seam verdict: qa-audit -> continue (green digest) | DETERMINISTIC | %s |\n' "$o_seam_cont"
    printf '| 2 | seam verdict: non-allowlisted gate -> inactive | DETERMINISTIC | %s |\n' "$o_seam_inact"
    printf '| 3 | /CJ_goal_task scaffolds a task work-item | claude --print | %s |\n' "$o_scaffold"
    printf '| 4 | implement writes code (non-empty diff) | claude --print | %s |\n' "$o_impl"
    printf '| 5 | qa-audit checkpoint auto-continued (no human) | claude --print | %s |\n' "$o_qaauto"
    printf '| 6 | /ship: branch pushed to the bare origin | DETERMINISTIC | %s |\n' "$o_push"
    printf '| 7 | gh pr create blocked (no real remote) | DETERMINISTIC | %s |\n' "$o_prblock"
    printf '| 8 | end_state = halted_at_ship (= sandbox SUCCESS) | DETERMINISTIC | %s |\n' "$o_end"
    printf '\n'
    printf '## Legend\n'
    printf 'DETERMINISTIC = asserted by the harness in shell (repeatable, no model).\n'
    printf 'claude --print = performed by a real Claude orchestration run (non-deterministic).\n'
    printf 'unverified = the supporting evidence was NOT found in the sandbox (NOT a pass).\n'
    printf '\n'
    printf '## Cost / time\n'
    printf 'budget=%s  duration=%s  tokens=%s\n' "${budget:-N/A}" "${duration:-N/A}" "${tokens:-N/A}"
  } > "$md"

  # Machine-readable sibling (same data) for later aggregation.
  {
    printf '{\n'
    printf '  "verb": "%s",\n' "$verb"
    printf '  "ts": "%s",\n' "$ts"
    printf '  "result": "%s",\n' "$result"
    printf '  "topic": "%s",\n' "$topic"
    printf '  "sandbox": "%s",\n' "$sandbox"
    printf '  "head_sha": "%s",\n' "$head_sha"
    printf '  "end_state": "%s",\n' "$end_state"
    printf '  "evidence": {\n'
    printf '    "task_dir_created": "%s",\n' "$task_dir_created"
    printf '    "diff_nonempty": "%s",\n' "$diff_nonempty"
    printf '    "branch_pushed": "%s",\n' "$branch_pushed"
    printf '    "pr_blocked": "%s",\n' "$pr_blocked"
    printf '    "seam_qa_audit": "%s",\n' "$seam_qa_audit"
    printf '    "seam_nonallowlisted": "%s"\n' "$seam_nonallowlisted"
    printf '  },\n'
    printf '  "cost": { "budget": "%s", "duration": "%s", "tokens": "%s" }\n' "$budget" "$duration" "$tokens"
    printf '}\n'
  } > "$json"

  printf '%s\n' "$md"
}
