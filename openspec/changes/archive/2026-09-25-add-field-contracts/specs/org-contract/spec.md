## ADDED Requirements

### Requirement: Org documents have a machine-checkable contract

The system SHALL define the Org tier as a JSON Schema so that any Org document
can be checked without a human reading it. The contract is the authority on what
an Org document contains; prose describing it elsewhere is commentary.

#### Scenario: A well-formed Org document is accepted

- **WHEN** an Org document declaring systems and their interfaces is validated
  against the Org contract
- **THEN** validation succeeds and reports no finding

#### Scenario: A document missing a required fact is rejected

- **WHEN** an Org document omits a fact the contract requires
- **THEN** validation fails and names the JSON path of the omission, so the
  author is told where to look rather than that something is wrong

### Requirement: Org documents carry no secret reference and no local path

The system SHALL reject an Org document containing a secret reference, a secret
value, or a path that only resolves on one machine. Shared facts travel between
people and repositories; a machine path in a shared document is wrong for every
reader but its author, and a credential in a public repository is not a defect
that can be fixed forward.

#### Scenario: A secret reference in a shared tier is rejected

- **WHEN** an Org document contains a secret reference anywhere in any string
- **THEN** validation fails and names the offending JSON path

#### Scenario: A local machine path in a shared tier is rejected

- **WHEN** an Org document contains a home-relative, volume-rooted, or
  absolute local filesystem path
- **THEN** validation fails and names the offending JSON path

#### Scenario: Prose that merely resembles a denied shape is accepted

- **WHEN** an Org document's descriptive text contains wording that overlaps a
  denylist pattern without being a secret or a path
- **THEN** validation succeeds, because a denylist that fires on ordinary prose
  gets disabled by its users

### Requirement: Interface URLs are transport-safe

The system SHALL require every interface URL in an Org document to be HTTPS,
and SHALL permit plain HTTP only for loopback addresses, which cannot leave the
machine.

#### Scenario: A plaintext remote URL is rejected

- **WHEN** an Org document declares an interface whose URL uses plain HTTP
  against a remote host
- **THEN** validation fails with a finding naming that interface

#### Scenario: A loopback development URL is accepted

- **WHEN** an Org document declares an interface whose URL uses plain HTTP
  against localhost or a loopback address
- **THEN** validation succeeds
