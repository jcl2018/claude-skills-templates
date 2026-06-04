<!--
  Per-workflow section template for doc/WORKFLOWS.md (F000034 / T000037).

  Copy this fragment into doc/WORKFLOWS.md under `## Orchestrators` and fill in
  every placeholder. Frontmatter is intentionally absent — this is a fragment,
  not a standalone doc.

  WORKFLOWS.md is the WORKFLOW altitude: it carries a section ONLY for each
  CJ_goal_* workflow orchestrator (today: CJ_goal_feature, CJ_goal_defect,
  CJ_goal_todo_fix). A non-orchestrator skill (phase-step, validator, utility)
  does NOT go here — add it to the doc/ARCHITECTURE.md `## Component skills
  (non-workflow roster)` instead (and always to doc/PHILOSOPHY.md's decision
  tree, the no-vanish safety net).

  Check 15b in scripts/validate.sh enforces, for every `CJ_goal_*` routable
  non-deprecated skill in skills-catalog.json:
    (a) the `### {name}` heading exists in doc/WORKFLOWS.md, AND
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
- **Scripts / tools:** {the helper scripts + tools it consumes — e.g. scripts/cj-goal-common.sh (--phase …, --mode …), scripts/cj-worktree-init.sh (--caller …), scripts/cj-worktree-cleanup.sh, scripts/check-version-queue.sh.}
- **Docs it updates:** {what the Step 5.5 /CJ_document-release pass folds into the PR — typically README.md, CHANGELOG.md, CLAUDE.md, and doc/** / templates/doc-* per the cj-document-release.json whitelist. Note any workflow-specific doc writes, e.g. the TODOS.md DONE-mark for CJ_goal_todo_fix.}

<!-- The Touches block is prose (human-readable), not a machine-parseable
     manifest. It answers "what does this workflow touch / what is its blast
     radius?" at a glance. Keep it to the three bullets above. -->
