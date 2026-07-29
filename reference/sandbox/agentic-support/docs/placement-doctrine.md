---
purpose: Where a new piece of guidance, procedure, data shape, or mechanic belongs.
audience: Anyone adding to the support tree.
status: Active.
---

# Placement doctrine

Answer the four questions in order; the first "yes" decides the home. State the
rule and the reason together so agents can generalize to cases this page does not
enumerate.

## The four questions

1. **Can a reader check or apply it in the directory without executing
   anything?** It is orientation, a boundary, a routing rule, or an exception →
   the directory's `AGENTS.md`. AGENTS.md files are always loaded, so they carry
   only what every session needs: keep them thin and point to canonical sources
   instead of copying them.
2. **Is it a stepwise procedure with preconditions, guardrails, and an output
   shape?** → a skill at `skills/<skill-name>/SKILL.md` per
   [skill-bundle-pattern.md](skill-bundle-pattern.md). Skills load on demand, so
   procedure depth costs nothing until invoked.
3. **Is it a machine-checkable data shape?** → a schema or contract (see the
   ownership rule below). Shapes belong where validators and consumers can resolve
   them, not inline in prose.
4. **Does it execute?** → `tools/` (active) or `tools/paused/` (inactive,
   fail-closed). A skill names the command it authorizes; it never embeds a copy
   of the logic.

The ordering is a cost ordering, not a taste ordering. Everything in an
`AGENTS.md` is paid for in every session; everything in a skill is paid for only
when invoked. That is why "keep AGENTS.md thin" is a budget rule rather than a
style preference.

## Schema-ownership rule

A contract or data shape consumed by **two or more skills, a validator, or an
external consumer** lives in `context-fabric/schemas/` as a registered schema. A
shape owned by **exactly one skill's own input or output** lives in that skill's
`assets/`.

The consumer count is the bright line: a second consumer means independent drift
is now possible, and only a shared registered schema lets validation catch it.
When a skill-owned contract gains its second consumer, move it to
`context-fabric/schemas/` in the same change that adds the consumer.

## Admission rule

Add a skill, tool, profile, or resource to this tree only when its value is core
and **crosscutting across practices**. One practice benefiting is not enough,
because everything here loads into every practice's sessions. Practice-specific
capability belongs in that practice's own lane.

## Enforcement

`validation/check-workspace.sh` checks descendant `AGENTS.md` files for procedure
content that belongs in a skill, and warns when a file exceeds the thinness
budget. This page is the reasoning behind that check, not a second authority.
