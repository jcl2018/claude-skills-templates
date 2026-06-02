<!--
  Per-skill section template for doc/SKILL-CATALOG.md (F000034).

  Copy this fragment into doc/SKILL-CATALOG.md under the appropriate role
  subsection (## Orchestrators / ## Phase-step skills / ## Validators / utilities)
  and fill in every placeholder. Frontmatter is intentionally absent — this is a
  fragment, not a standalone doc.

  Check 15 in scripts/validate.sh enforces:
    (a) the `### {name}` heading exists for every routable non-deprecated skill, AND
    (b) the section has EITHER a fenced ``` block (ASCII workflow chart) OR a
        tag line matching one of (single-step utility) / (validator) /
        (phase-step in /CJ_goal_feature chain).
  Silent omission (heading present, body empty) is forbidden — pick chart-or-tag.
-->

### {skill-name}

<!-- Replace {skill-name} with the catalog entry's `name` field exactly (case-sensitive).
     Examples: CJ_goal_feature, CJ_scaffold-work-item, CJ_system-health. -->

**Status:** {active | experimental} ({one-line rationale — why this status})

<!-- `active` = depended on by other skills or shipped to operators as a stable
     front door. `experimental` = under iteration; surface may change. Match the
     skills-catalog.json `status` field; the rationale is human-readable color. -->

**Source:** `skills/{skill-name}/SKILL.md` · `skills/{skill-name}/USAGE.md`

<!-- Two paths separated by ` · `. SKILL.md is the contract; USAGE.md is the
     operator/agent best-practice doc. Both required for routable non-deprecated
     skills (Check 13 enforces USAGE.md presence). -->

**Invoke when:** {one-to-two-line distilled invocation pattern, paraphrased from USAGE.md ## When to use}

<!-- Distilled. Aim for one sentence that captures the trigger condition + the
     skill's role. Avoid copy-pasting a bullet list — that's USAGE.md's job. -->

**Workflow:**

```
<input>
   │  {one-line phase description}
   ▼
{next phase}
   │
   ▼
{terminal state}
```

<!-- ASCII workflow chart (mandatory for orchestrators / use a tag instead for
     single-step skills). 10-15 lines max. Use `│` + `▼` for vertical flow,
     `└─` / `├─` for branches. Distill from the orchestrator's SKILL.md ##
     Overview section if one already exists. -->

<!--
  OR (for single-step skills — mandatory tag replacement for the chart above):

  `(single-step utility)` — {one-line behavioral summary}
  `(validator)` — {one-line behavioral summary}
  `(phase-step in /CJ_goal_feature chain)` — {one-line behavioral summary}

  Pick exactly ONE tag from the closed enum above. Check 15 regex matches these
  literals only; new tags require a Check 15 update.
-->
