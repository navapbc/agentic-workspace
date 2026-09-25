# Field contracts for the three document tiers

## Why

The framework's premise is that organizational facts are authored once in the
tier that owns them and projected into standalone views. Nothing enforces that
today: there is no machine-checkable definition of what an Org, Bounded Context,
or Individual document contains, so "a document" means whatever the last author
typed. Every later capability — validation, view generation, releases,
migrations — needs a contract to check against, and building them on an informal
shape would mean rewriting each one when the shape is finally pinned down.

This change establishes the three field contracts as JSON Schema, generates the
commented YAML templates from them, and lays down the fixture corpus that every
later capability extends.

## What changes

- Three tier contracts and one shared definitions file, as JSON Schema
  (Draft 2020-12), under `schemas/<tier>/<version>/`.
- A renderer that produces each tier's commented YAML template **from** its
  schema, so the template cannot drift from the contract.
- A fixture corpus: at least one valid document per tier, and one invalid
  document per schema-detectable rule, each named for the finding code it trips.
- The secrets boundary, enforced rather than described: Org and Bounded Context
  documents reject secret references and local machine paths; the Individual
  tier accepts `op://` references and rejects secret *values*.
- The migration rule and its guard, written before any migration exists.

## Non-goals

- The validator itself. This change ships the contracts and the fixtures that
  prove them; the structured-findings validator that consumes them is separate.
- Any real organizational document. Shipped examples are fictional.
- Contract version 2 of anything. Version 1 is the floor.

## Rejected alternatives

**One schema with a discriminated `kind`, instead of three files.** A single
schema would keep the shared definitions physically next to their use and avoid
cross-file `$ref` resolution entirely. Rejected because the tiers version
independently: the Individual tier is expected to move fastest (it tracks what
machines and harnesses exist) and the Org tier slowest. One file forces a
version bump on all three whenever any one changes, which makes the per-document
`release` number meaningless as a compatibility signal.

**Author the YAML templates by hand and validate them against the schemas.** The
obvious cheap option, and it reads better — a hand-written template can explain
a field in the voice a newcomer needs. Rejected because it creates two sources
of truth that drift silently: a field added to the schema and forgotten in the
template produces a template that validates but omits the field, which is the
failure a template exists to prevent. Generating the template from the schema
makes drift impossible and `--check` makes staleness a test failure. The cost is
that comment quality now depends on schema `description` text, which is a
constraint we accept and enforce by review.

**Let a secret value be caught by review rather than by the contract.** Review
is what most projects rely on and it costs nothing to build. Rejected because
this repository is public and a leaked credential is not a defect you fix
forward — it is one you rotate. A denylist in the contract is weaker than a
human in the sense that it only catches shapes it knows, and stronger in the
sense that it never gets tired, never approves its own change, and runs on every
document on every machine. We take the tireless one and say plainly in
`SECURITY.md` what it cannot catch.

**Defer the migration rule until the first contract bump.** Contract 1 has
nothing to migrate from, so the guard tests an empty set and looks like
ceremony. Rejected because the guard's value is entirely in existing *before*
the bump that needs it. Written after the fact, it is written by someone who has
already hand-migrated their documents and no longer feels the problem; written
now, it makes the first bump impossible to ship without its migration step.

**Snake_case fixture filenames matching the finding codes directly.**
`SECRET_VALUE_FORBIDDEN` → `secret_value_forbidden.yaml` is the mechanical
transform and needs no rule. Rejected because every other path the framework
creates is lowercase-kebab, and a single convenient exception is how a
convention erodes. The transform is stated explicitly instead: lowercase, then
replace `_` with `-`.
