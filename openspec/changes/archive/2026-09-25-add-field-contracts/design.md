# Design

## Shape

Four schema files. One shared definitions file holds the vocabulary every tier
uses — identifiers, upstream references, locations, release numbers, the
denylist data — and each tier contract `$ref`s it by relative path. Validation
passes an explicit base URI so reference resolution never leaves the tree and
never reaches the network.

```
schemas/
  shared/1/defs.json          the vocabulary
  org/1/schema.json           ─┐
  bounded-context/1/schema.json │ $ref ../../shared/1/defs.json
  individual/1/schema.json    ─┘
```

Contract versions are integer directories. A released directory is **immutable**:
changing a tier's shape means creating `<n+1>`, never editing `<n>` in place.
This is what makes the migration guard bind — the guard fires on the existence
of a new numbered directory, so an in-place edit would slip past it, and
in-place editing is the cheaper move exactly while the schemas are still young.
Frozen hashes over every released directory turn that from a convention into a
test.

## Templates are generated, not written

`scripts/render-templates.sh` walks a schema and emits commented YAML: each key
carries its schema `description` as a comment, and example values are marked as
examples. `--check` compares the rendered output to the committed template and
fails on drift. Two consequences worth naming: the template can never omit a
field the contract requires, and comment quality is now a property of the
schema's `description` text, which review has to hold to a standard.

## The secrets boundary

Two denylists, differing only in scope. The `all` scope applies to every string
in every tier and catches credential shapes — key headers, bearer tokens,
provider-prefixed keys. The `shared` scope applies to Org and Bounded Context
only and additionally catches secret references and local machine roots.

The Individual tier's asymmetry — references allowed, values forbidden — is
expressed as a grammar the reference must match, not as an absence of checking.
A value that is not a well-formed reference fails, so "no check ran" and "the
check passed" cannot be confused.

The denylist lives as data in the shared definitions and is composed into each
tier's schema pattern. A test asserts the composed patterns equal the
composition of the data, so the two cannot drift.

## Fixture corpus

```
tests/fixtures/valid/<tier>/<name>.yaml
tests/fixtures/invalid/<tier>/<finding-code>[-<variant>].yaml
tests/fixtures/invalid/evasions/
tests/fixtures/migrations/<tier>/<n>/{before,after}.yaml
```

A finding code maps to a fixture filename by lowercasing and replacing `_` with
`-`, so `SECRET_VALUE_FORBIDDEN` becomes `secret-value-forbidden.yaml`. Stated
explicitly because the mechanical transform would produce snake_case and every
other path the framework creates is lowercase-kebab.

Each invalid fixture trips exactly the code it is named for and no other error,
which is what lets a later coverage test derive the expected fixture from the
code registry.

## The optional schema stage

`check-jsonschema` runs under `uv` and is optional: a machine without it still
gets the always-on checks. But "optional" must not silently mean "never ran" —
the stage reports a named skipped-stage code rather than passing, and CI
installs the tool so the stage actually executes there. Its version is pinned in
`framework.json` alongside the other tools; an unpinned validator means the
contract is checked against whatever version happened to resolve.
