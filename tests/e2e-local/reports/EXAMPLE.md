# cj_goal local E2E run — CJ_goal_task — 20260630T204500Z
Result: PASS (reached the halted_at_ship boundary, no real PR — sandbox)
Topic:  "Append a single dated note line to the scratch fixture file tests/e2e-local/fixtures/scratch.txt (create it if missing). This is a deliberately trivial, non-sensitive, non-doc change whose only purpose is to exercise the cj_goal build pipeline end to end."
Sandbox: /tmp/cj-e2e-a1b2c3/clone (clone @ e8d764d, local bare origin, marker present)
Seam:   CJ_GOAL_E2E_AUTO=1 — auto-answered: qa-audit (continue)   [NOT auto-answered: /ship]

## Coverage — what actually ran, and how it was verified
| # | Step / claim | Layer | Outcome |
|---|--------------|-------|---------|
| 1 | seam verdict: qa-audit -> continue (green digest) | DETERMINISTIC | pass |
| 2 | seam verdict: non-allowlisted gate -> inactive | DETERMINISTIC | pass |
| 3 | /CJ_goal_task scaffolds a task work-item | claude --print | pass |
| 4 | implement writes code (non-empty diff) | claude --print | pass |
| 5 | qa-audit checkpoint auto-continued (no human) | claude --print | pass |
| 6 | /ship: branch pushed to the bare origin | DETERMINISTIC | pass |
| 7 | gh pr create blocked (no real remote) | DETERMINISTIC | pass |
| 8 | end_state = halted_at_ship (= sandbox SUCCESS) | DETERMINISTIC | pass |

## Legend
DETERMINISTIC = asserted by the harness in shell (repeatable, no model).
claude --print = performed by a real Claude orchestration run (non-deterministic).
unverified = the supporting evidence was NOT found in the sandbox (NOT a pass).

## Cost / time
budget=$8.00  duration=6:12  tokens=180000

<!--
This is a COMMITTED SAMPLE (the only tracked file under tests/e2e-local/reports/;
the rest is gitignored). It shows the shape a real run emits so the format is
reviewable in a PR. A real report's Outcome column is DERIVED from the run's
evidence — a row whose evidence was not found renders as `unverified`, never
`pass`. Regenerate a real one locally: CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh
-->
