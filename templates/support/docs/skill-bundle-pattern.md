---
purpose: The canonical shape of a skill bundle, its manifest entry, and its adapters.
audience: Anyone authoring or reviewing a skill.
status: Active.
---

# Skill bundle pattern

Each capability lives at `skills/<skill-name>/SKILL.md`. Its directory name,
`workflow_id`, and manifest `id` must match. The canonical file has YAML
frontmatter with `workflow_id`, `version`, `status`, `owner`, `source_of_truth`,
and `portable_across_harnesses`. It must define **Procedure**, **Guardrails**,
**Output Shape**, **Failure Handling**, and **Harness Interpretation**; add
Triggers, Required Context, Bindings, Checks, or command contracts when the
capability needs them.

`skills/skill-manifest.yaml` is the discovery and availability authority. Add or
remove a manifest entry in the same change as its canonical skill. Each entry uses
the matching `id` and `path: <skill-name>/SKILL.md`, and one of these availability
states:

| State | Meaning |
| --- | --- |
| `enabled` | Fully available. |
| `partially-paused` | Some steps unavailable; the skill documents which and why. |
| `paused` | Not runnable; the skill states the degraded path. |

A skill's frontmatter `status` describes its local workflow state and must not
override manifest availability. A `partially-paused` or `paused` entry also
carries a `review_by` date, so a pause is a decision with a deadline rather than
an indefinite state; `tools/workspace-doctor.sh` surfaces overdue reviews at
session start.

The `status` field is what lets you ship the structure before every skill is
finished. A visibly paused skill with a review date is honest; a missing skill is
just a gap nobody is tracking.

## Optional bundle contents

- `references/` — durable supporting material the procedure cites.
- `assets/` — reusable templates, fixtures, or output contracts owned by this one
  skill (see the schema-ownership rule in
  [placement-doctrine.md](placement-doctrine.md)).
- `adapters/<harness>/<skill-name>/SKILL.md` — a thin runtime pointer only. It
  identifies the canonical skill and any harness-specific capability discovery; it
  must defer to the canonical `SKILL.md`, never copy the complete procedure or
  broaden its authorization.

## What never goes in a skill bundle

Keep executable commands in `tools/` and shared facts in `context-fabric/`. A
canonical skill names the command or context it authorizes and its preconditions;
it must not embed a copy of reusable command logic or shared facts. Duplicated
logic drifts silently — the copy in the skill keeps working while the tool it was
copied from changes.

Use [the skill binding contract](skill-binding-contract.md) for support-root
discovery, explicit workspace lanes, and adapter hints. Do not publish a
user-specific absolute local default in a canonical skill or adapter.
