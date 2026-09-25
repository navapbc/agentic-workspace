# individual-contract Specification

## Purpose

The Individual tier is where one person's machine meets the shared tiers. It
binds a document to local roots, names the harness in use, and points at the
credentials a task needs.

It exists to keep two things apart that most projects let blur: facts that
travel, and facts that do not. A machine path is wrong for every reader but its
author; a credential in a shared document is not a defect that can be fixed
forward. So this is the only tier that may carry either -- and the only tier
that never travels. Its defining asymmetry is that a secret *reference* is
accepted and a secret *value* is refused: the tier's permission is to point at
a credential, never to hold one.

## Requirements

### Requirement: Individual documents have a machine-checkable contract

The system SHALL define the Individual tier as a JSON Schema. The Individual
tier is where one person's machine meets the shared tiers: it binds a document
to local roots and names the harness in use.

#### Scenario: A well-formed Individual document is accepted

- **WHEN** an Individual document binding a Bounded Context to local roots is
  validated
- **THEN** validation succeeds and reports no finding

### Requirement: The Individual tier is the only place a secret reference may appear

The system SHALL accept a secret *reference* in an Individual document and
SHALL reject a secret *value* there. This is the one asymmetry in the framework
and it is the point of the tier: a reference names where a credential lives
without carrying it, and an Individual document is the only document that never
travels.

#### Scenario: A well-formed secret reference is accepted

- **WHEN** an Individual document declares an environment variable whose value
  is a well-formed secret reference
- **THEN** validation succeeds

#### Scenario: A literal secret value is rejected

- **WHEN** an Individual document declares an environment variable whose value
  is a literal credential rather than a reference
- **THEN** validation fails, because the tier's permission is to point at a
  secret, never to hold one

#### Scenario: A credential-shaped token is rejected wherever it appears

- **WHEN** any string in an Individual document matches a known credential shape
- **THEN** validation fails, independently of which field it appeared in

### Requirement: A cross-tree location cannot escape the tree that owns it

The system SHALL constrain a document-to-document location so that it resolves
inside the tree that owns the referring document, and SHALL require a URL form
for anything outside it. A relative path that climbs out of its own tree
resolves differently on every machine.

#### Scenario: A path that climbs out of its tree is rejected

- **WHEN** a location contains any upward traversal segment
- **THEN** validation fails, because the rule is no upward segment at all,
  rather than no net escape — a normalizing rule makes every reviewer redo the
  arithmetic

#### Scenario: A path inside the owning tree is accepted

- **WHEN** a location names a path that stays within the tree that owns the
  document
- **THEN** validation succeeds
