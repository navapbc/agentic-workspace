---
purpose: What this support tree is, what authority it carries, and what it never owns.
audience: Maintainers of the support tree.
status: Active.
---

# Architecture

`agentic-support/` is the canonical support boundary for this workspace's agents
and maintainers, across every practice. **Skills define behavior, Context Fabric
defines shared records, tools perform approved mechanics, and validation checks
their integration.** Capabilities live here only when they are core and
crosscutting across practices.

Authority runs from active user instructions, to this support-system guidance, to
a selected skill, to the relevant Context Fabric record and lane-local
instructions. Lane guidance can narrow a support-system rule; it does not duplicate
a shared procedure or shared facts.

The support system guides work; it never changes the destination of synthesis.
Product artifacts remain in their owning area; practice artifacts in their owning
practice lane; code checkouts outside both.

Support-owned resources resolve from the loaded support tree. Product work,
prototypes, and checkouts are explicit workspace lanes, not assumed siblings of
that tree. The binding-resolution rules live in
[skill-binding-contract.md](skill-binding-contract.md).

## The four components, and why they are separate

| Component | Owns | Fails how, if merged into another |
| --- | --- | --- |
| `skills/` | Behavior: stepwise procedures with guardrails and output shapes. | Merged into guidance files, procedures load in every session and drift across copies. |
| `context-fabric/` | Facts: small machine-readable records under a versioned schema. | Written as prose, facts get restated per document and diverge silently. |
| `tools/` | Mechanics: the executable steps a skill is allowed to invoke. | Embedded in skills, logic forks per skill and the copies stop matching. |
| `validation/` | Integration: the invariants across all three. | Absent, nothing notices when the other three drift apart. |

## Sharing model

This tree works under either sharing mechanism, but the safety model differs, and
the difference is worth stating out loud in your workspace README:

- **Git-backed.** Review and revert are the safety net. Diffs are visible;
  mistakes are recoverable. Snapshot-first record editing is optional.
- **Synced storage (Drive, Dropbox, OneDrive).** There is no review gate and no
  diff: sync *is* the distribution channel, so any saved file reaches every
  teammate silently. Snapshot-first record editing plus `records/CHANGELOG.md` is
  what replaces review, and the "no member-specific harness state in the shared
  tree" rule stops being hygiene and becomes a data-safety rule.

Pick one deliberately and finish it. Two half-wired mechanisms is the most common
way these workspaces rot.

## What this tree has no lifecycle for

Whether the shared tree carries branches, pull requests, releases, or CI is a team
decision, recorded in the workspace README. If it does not, say so here too, so
nobody authors guidance that assumes a review gate that does not exist.
