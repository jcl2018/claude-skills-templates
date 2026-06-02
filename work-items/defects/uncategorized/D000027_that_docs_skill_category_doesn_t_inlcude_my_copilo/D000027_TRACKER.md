---
type: defect
id: D000027
name: "that docs skill-category doesn't inlcude my copilot ones"
status: phase-1-investigating
created: 2026-06-02T08:17:18Z
auto_scaffolded: true
promoted_from_draft: .inbox/that_docs_skill_category_doesn_t_inlcude_my_copilo
---

# D000027: that docs skill-category doesn't inlcude my copilot ones

## Bug Report
that docs skill-category doesn't inlcude my copilot ones

## Journal
- 2026-06-02T08:17:18Z [auto-scaffolded] /CJ_goal_defect captured "that docs skill-category doesn't inlcude my copilot ones" as draft .inbox/that_docs_skill_category_doesn_t_inlcude_my_copilo, then promoted to D000027 after /investigate populated the root cause. Domain defaulted to 'uncategorized'; `mv` to a more specific subdir if needed.

- 2026-06-02 [qa-smoke] 1 (catalog has copilot mentions): green — grep returned 6 matches (≥1 expected)
- 2026-06-02 [qa-smoke] 2 (validate.sh passes): green — exit 0; 0 errors, 0 warnings; Check 15 emits 11 PASS lines
- 2026-06-02 [qa-smoke] 3 (non-skill bundle tag present): green — grep returned 2 matches (≥1 expected)
- 2026-06-02 [qa-smoke] 4 (### work-copilot section heading present): green — grep returned 1 match
- 2026-06-02 [qa-smoke-summary] green: 4/4 non-manual rows green (0 manual rows pending)
- 2026-06-02 [qa-pass-pending-commit] D000027 (defect): green smoke from test-plan rows (4 rows). Boundary check at Step 2 of qa.md cannot run because the auto-scaffolded tracker is minimal (missing tracker-defect.md sections: Lifecycle/Phase 1-3, Reproduction Steps, Todos, Log, PRs, Files, Insights) AND `Fix committed` gate is structurally unchecked (/ship is the commit step in /CJ_goal_defect's chain). Surfacing as AUQ to operator per task-type post-QA halt protocol. Phase 3 `Test-plan verified` gate awaits /ship-time inference.
