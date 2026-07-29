---
title: Declare workspace roots explicitly; never derive them from directory shape
category: conventions
problem_type: convention
component: tooling
severity: medium
applies_when:
  - "A shared tool needs a machine-local path that differs per teammate"
  - "Writing a generator or doctor that discovers workspace structure"
  - "A tool is about to fall back to a sibling directory, a home-directory guess, or a prior user's default"
tags: [workspace-descriptor, fail-closed, declared-over-derived, tooling, portability]
---

# Declare workspace roots explicitly; never derive them from directory shape

## Context

The first descriptor generator inferred a member's roots from the filesystem: it
looked for sibling directories next to the support tree and assumed the ones whose
names matched known lanes were that member's roots. This worked on the machine it
was written on and produced quietly wrong answers everywhere else — a teammate who
kept checkouts in a different parent, or who had a similarly-named folder for
something else, got a descriptor that pointed at the wrong tree without any error.

The second failure mode was narrowing. A member who re-ran the generator after
moving one root, passing only that root, silently lost the declaration of every
other root. The next doctor run reported a workspace that was smaller than it
actually was, and skills started failing on lanes that existed.

## Guidance

**Every machine-local root is declared explicitly by the member. Tools resolve
from the declaration and fail closed when it is absent, stale, or invalid.**

- **Interview, don't infer.** The setup flow asks the member where each root is.
  Directory shape, sibling names, and home-directory conventions are never
  evidence.
- **Fail closed.** A missing declaration stops the operation with an instruction
  ("run the setup skill"), rather than falling back to a guess. A guess that is
  right nine times out of ten is worse than a stop, because the tenth is silent.
- **Never narrow on re-run.** The generator reads the existing declaration first
  and refuses a re-run that would drop a previously declared root. Retiring a root
  is an explicit act: delete the descriptor and re-declare the full set.
- **Validate the declaration itself.** Roots must exist on disk, must not nest,
  and must not repeat — nesting duplicates trees in harness pickers, makes role
  resolution ambiguous, and reopens the checkout-inside-a-synced-root hole.
  Comparisons use physical paths so symlink indirection cannot evade the checks.
- **One scoped exception.** Lanes inside the shared workspace tree *are* physical
  siblings of the support tree, so deriving them from its location is sound. The
  rule is about machine-local roots, which are the ones that legitimately differ
  per teammate.

## Why this matters

A descriptor is read by tools that then act on real directories — cloning into
them, writing outputs into them, refusing to touch them. A wrong-but-plausible
value turns every one of those actions into a wrong action, with no error to
trace back. Explicit declaration moves the failure from "did the wrong thing
silently" to "stopped and told you what to run", which is the only version a
teammate can act on.

There is also a portability argument. A tool that derives paths encodes one
person's folder habits into shared infrastructure. A tool that reads declarations
works for the teammate who organizes their machine differently, which is every
teammate.

## When to apply

- Writing any shared script that needs a per-machine path.
- Reviewing a tool that has a `||` fallback to `$HOME`, a sibling directory, or a
  hardcoded default. That fallback is the bug.
- Designing a regeneration step: ask what happens when someone re-runs it with
  partial arguments.

## Related

- `docs/skill-binding-contract.md` — resolution order and binding classes.
- `tools/generate-workspace-descriptor.sh` — the generator, including the
  no-narrowing and no-nesting guards.
- `context-fabric/schemas/workspace-descriptor/1.0.0/schema.json` — the declared
  shape.
