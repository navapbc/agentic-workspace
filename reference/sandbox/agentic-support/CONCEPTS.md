# Concepts

Shared vocabulary for the fictional Benefits Notices workspace. One of the two files a
team authors itself; everything else in this tree installed verbatim from the kit.

Glossary only — a few sentences per entry, because this file loads in every session.
Detail goes in `docs/solutions/` or a Context Fabric record.

## Benefits Notices domain

### Notice
An outbound beneficiary communication: an eligibility determination, a statement of
appeal rights, or a renewal reminder. A notice reflects upstream rules; it never sets
them.

### Template Set
The versioned collection of layouts a notice renders through. A content change and a
template-set change are different reviews with different risk.

### Notice ID
A stable identifier, BN-001 through BN-140. Referenced by the notice service, analytics,
and support macros, so renumbering breaks all three. Allocate the next unused number;
never reuse or renumber. See
`product-work/benefits-notices/docs/solutions/notice-id-stability.md`.

### Determination Event
The upstream message from the Eligibility Platform that triggers a notice. BN consumes
its shape and has no say in its contents — which is why the events repository is
`reference` coverage, not `direct`.

## Workspace pattern

The workspace-pattern vocabulary (Multi-Root Workspace, Primary Folder, Launch Shape,
Workspace Descriptor, Binding Token, Workspace Doctor, Capability Tier, Repo Digest)
ships with the engine and is preserved above this section in a real workspace. It is
elided here to keep the sandbox readable — see
`templates/support/CONCEPTS.md.template` in the kit for the full seeded set.
