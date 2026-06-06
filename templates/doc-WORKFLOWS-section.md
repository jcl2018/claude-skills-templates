<!--
  Per-workflow section template for docs/workflow.md (F000034 / T000037).

  Copy this fragment into docs/workflow.md under `## Orchestrators` and fill in
  every placeholder. Frontmatter is intentionally absent — this is a fragment,
  not a standalone doc.

  This fragment is for the `## Orchestrators` section — one full section per
  CJ_goal_* workflow orchestrator (today: CJ_goal_feature, CJ_goal_defect,
  CJ_goal_todo_fix), with an ASCII chart + the 4-bullet Touches block. A
  non-orchestrator skill (phase-step, validator, utility) does NOT use this
  fragment — add it to the docs/workflow.md `## Utilities & phase-step skills`
  section instead, using that section's LIGHTER per-skill shape (`### <skill>`
  heading + Status + Source + Invoke when + a compact Touches: Scripts · tools ·
  shell / Reads · writes; no chart, no 4-bullet Touches — single-step skills
  dispatch nothing and run no pipeline). Either way, always add the skill to
  docs/philosophy.md's decision tree, the no-vanish safety net.

  Check 15b in scripts/validate.sh enforces, for every `CJ_goal_*` routable
  non-deprecated skill in skills-catalog.json:
    (a) the `### {name}` heading exists in docs/workflow.md, AND
    (b) the section has a fenced ``` block (the ASCII workflow chart).
  Silent omission (heading present, no chart) is forbidden.
-->

### {workflow-name}

<!-- Replace {workflow-name} with the catalog entry's `name` field exactly
     (case-sensitive). Must be a CJ_goal_* orchestrator, e.g. CJ_goal_feature. -->

**Status:** {active | experimental} ({one-line rationale — why this status})

<!-- `active` = shipped to operators as a stable front door. `experimental` =
     under iteration; the chain may change. Match the skills-catalog.json
     `status` field; the rationale is human-readable color. -->

**Source:** `skills/{workflow-name}/SKILL.md` · `skills/{workflow-name}/USAGE.md`

<!-- Two paths separated by ` · `. SKILL.md is the contract; USAGE.md is the
     operator/agent best-practice doc. -->

**Invoke when:** {one-to-two-line distilled invocation pattern, paraphrased from USAGE.md ## When to use}

<!-- Distilled. One sentence that captures the trigger + the workflow's role and
     terminal state (stops at the PR? auto-deploys?). Avoid copy-pasting a bullet
     list — that's USAGE.md's job. -->

**Workflow:**

```
<input>
   │  {one-line phase description — e.g. cj-goal-common.sh --phase worktree}
   ▼
{next phase / dispatched skill}
   │
   ▼
{terminal state — e.g. STOP at PR / land-and-deploy / telemetry}
```

<!-- ASCII workflow chart (MANDATORY for a CJ_goal_* orchestrator — Check 15b
     requires the fenced block). 15-25 lines. Use `│` + `▼` for vertical flow,
     `└─` / `├─` / `↳` for branches + halts. Distill from the orchestrator's
     SKILL.md ## Overview chart if one already exists. -->

**Touches:**

- **Skills dispatched:** {the skills this workflow invokes, in order — e.g. /office-hours, /CJ_scaffold-work-item → /CJ_implement-from-spec → /CJ_qa-work-item, /CJ_document-release (Step 5.5), /ship[, /land-and-deploy]. Note any that run as leaf subagents vs inline, and /CJ_personal-workflow running transitively at boundaries.}
- **Steps · phases:** {the named pipeline steps + cj-goal-common.sh phases in order — e.g. --phase sync (pre-build skills-sync) → --phase worktree + Fork-1 base-freshness → isolation gate (--assert-isolated) → office-hours/design-gate → scaffold/implement/qa → doc-sync (Step 5.5) → /ship → registered-doc verdicts (Step 4.6/5.6/9.5) → terminal (STOP at PR / land-and-deploy) → worktree-cleanup (--phase cleanup) → telemetry. This bullet is the enforceable completeness anchor — enumerate the worktree-init … teardown lifecycle, not just the skills.}
- **Scripts · tools · shell:** {the named helper scripts + tools it consumes — e.g. scripts/cj-goal-common.sh (--phase sync / worktree / pr-check / cleanup / telemetry, --mode …), scripts/cj-worktree-init.sh (--caller …, Fork-1 base-freshness + --assert-isolated), scripts/cj-worktree-cleanup.sh, scripts/check-version-queue.sh. NAMED helpers only — NOT raw git/gh, and NOT post-land-sync.sh (it is the internal core --phase sync reuses + a manual operator step, not an orchestrator step).}
- **Docs touched:** {what the Step 5.5 /CJ_document-release pass folds into the PR — typically README.md, CHANGELOG.md, CLAUDE.md, and docs/** / templates/doc-* per the doc-spec.md registry-derived whitelist. Note any workflow-specific doc writes, e.g. the TODOS.md DONE-mark for CJ_goal_todo_fix.}

<!-- The Touches block is prose (human-readable), not a machine-parseable
     manifest. It answers "what does this workflow touch / what is its blast
     radius?" at a glance. ALL FOUR bullets are REQUIRED (Skills dispatched /
     Steps · phases / Scripts · tools · shell / Docs touched) — enumerate to the
     named-helper + named-step level (worktree init/teardown, --phase sync,
     isolation gate, check-version-queue, the verdict-surfacing producers). The
     four bullets are STRUCTURALLY enforced by validate.sh Check 15b (each must
     match `^- \*\*Skills` / `^- \*\*Steps` / `^- \*\*Scripts` / `^- \*\*Docs`);
     completeness within each bullet is agent-judged (Step 6.7 registered-doc
     audit). Granularity ceiling: named helpers + steps only, NOT raw git/gh,
     NOT post-land-sync.sh. -->
