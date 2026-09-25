## ADDED Requirements

### Requirement: Bounded Context documents have a machine-checkable contract

The system SHALL define the Bounded Context tier as a JSON Schema. A Bounded
Context names the context one set of workflows needs and references the Org
facts it depends on rather than copying them.

#### Scenario: A well-formed Bounded Context document is accepted

- **WHEN** a Bounded Context document referencing Org systems is validated
- **THEN** validation succeeds and reports no finding

#### Scenario: A Bounded Context may draw on more than one organization

- **WHEN** a Bounded Context document extends documents from two different
  organizations
- **THEN** validation succeeds, because a team whose work crosses
  organizational boundaries is the ordinary case, not an exception

### Requirement: A reference to an upstream fact is unambiguous

The system SHALL require every reference to an upstream system to name both the
document that owns the fact and the fact within it. A reference that names only
the fact cannot be resolved once documents live in more than one repository.

#### Scenario: An unqualified reference is rejected

- **WHEN** a Bounded Context document references an upstream system without
  naming the document that owns it
- **THEN** validation fails with a finding naming that reference

### Requirement: Bounded Context documents carry no secret reference and no local path

The system SHALL apply the same shared-tier prohibition to Bounded Context
documents that it applies to Org documents. The tier is shared, so the reasoning
is identical.

#### Scenario: A secret reference in a Bounded Context is rejected

- **WHEN** a Bounded Context document contains a secret reference anywhere in
  any string
- **THEN** validation fails and names the offending JSON path
