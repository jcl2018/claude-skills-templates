---
skill-name: "{name}"
version: 0.1.0
status: DRAFT
created: "{date}"
last-updated: "{date}"
---

# Skill Usage: {name}

## When to use

Concrete situations and operator/agent phrasings that should route to this skill.
Quote 2-4 of the routing triggers from `rules/skill-routing.md` or the SKILL.md
`description` so a reader knows in one glance whether their situation matches.

## When NOT to use

The lookalike situations that route somewhere else. Name the sibling skills explicitly
("for X use /Y instead") and call out anti-patterns or constraints that disqualify this
skill (deprecated callers, scope mismatches, depth/recursion limits).

## Mental model

The one-paragraph framing that survives reading the SKILL.md. Inputs in, outputs out,
key invariants the skill guarantees, and what kind of object lives at each boundary
(design doc, work-item dir, PR, journal entry). This is the "what is this skill, really?"
section — favor concrete nouns over instructions.

## Common pitfalls

Things operators get wrong, gotchas the skill won't auto-recover from, and gate/halt
behaviors that surprise people. Each pitfall is one sentence; if it needs more than
one sentence, link out to the SKILL.md section or a work-item that documents it.

## Related skills

Sibling skills the reader should know about — upstream callers, downstream callees,
peer alternatives, and the next skill in the typical chain. One bullet per related
skill, with a short why. Cross-link to their USAGE.md when present.
