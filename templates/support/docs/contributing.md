---
purpose: How to change this support system safely.
audience: Maintainers and stewards.
status: Active.
---

# Contributing to the support tree

Update or add the canonical component, run `validation/check-workspace.sh`, then
change active guidance. In that order — a guidance change that points at a
component which does not yet validate is how a workspace starts lying to its
agents.

- **Admission rule.** Add a skill, tool, profile, or resource here only when its
  value is core and crosscutting across practices. One practice benefiting is not
  enough, because everything here loads into every practice's sessions.
  Practice-specific capability belongs in that practice's lane.
- **Unsure whether something is AGENTS.md guidance, a skill, a schema, or a
  tool?** Apply the four questions in
  [placement-doctrine.md](placement-doctrine.md); its schema-ownership rule
  decides skill asset vs `context-fabric/schemas/`.
- **Adding a capability.** Create `skills/<skill-name>/SKILL.md` and add its
  matching `id`, path, and availability state to `skills/skill-manifest.yaml` **in
  the same change**. Follow [skill-bundle-pattern.md](skill-bundle-pattern.md) for
  the canonical file contract and
  [skill-binding-contract.md](skill-binding-contract.md) for location resolution.
  Add references, assets, and adapters only when that capability owns them.
- **Adding a mechanic.** Put reusable mechanics in `tools/`; preserve inactive
  mechanics in `tools/paused/` with fail-closed messaging rather than deleting
  them, so the reason they are off stays discoverable.
- **`templates/checkouts-root/`** holds the canonical guidance template for each
  member's machine-local checkouts root; the `workspace-setup` skill instantiates
  it (filling the `{{AGENTIC_SUPPORT_ROOT}}` token) on each machine. Edit the
  template, never a member's local copy.
- **Context Fabric.** Keep schemas, record templates, and authoring guidance
  inside `context-fabric/`. Edit records snapshot-first. Schema changes go through
  the steward.
- **Validation.** Add cross-component checks to `validation/`, not to a single
  component's own tests.
- **Never add** credentials, local configuration, dependency folders, raw
  authenticated exports, checkout copies, or OS metadata.

## Recording learnings

When a session solves something durable — a bug, a workflow trap, a pattern worth
reusing — write it to `docs/solutions/<category>/<slug>.md` with YAML frontmatter
(`title`, `date`, `category`, `problem_type`, `applies_when`, `tags`). When it
introduces or sharpens a term the team will reuse, add it to `CONCEPTS.md`.

Both accrete deliberately. `docs/solutions/` is load-on-demand and can grow
without bound; `CONCEPTS.md` is read often and should stay a glossary, not a
catch-all.

## Upgrading from the kit

This tree was installed from the
[Agentic Workspace Starter Kit](https://github.com/navapbc/agentic-workspace).
Re-run the kit's `scripts/install-support.sh <workspace>` to pull a newer engine;
it refreshes the generic files and leaves `CONCEPTS.md`,
`docs/context-source-ladder.md`, `docs/solutions/`, your skills, and your records
untouched. If you have locally modified a generic file, the installer reports the
conflict rather than overwriting it — reconcile it deliberately, or upstream the
change so the next team gets it too.
