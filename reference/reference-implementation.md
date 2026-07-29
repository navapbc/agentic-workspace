---
purpose: How the kit's model maps onto a real, mature deployment. A worked reference, not a template.
audience: PMs and leads who want to see the model instantiated at full maturity.
status: Active reference.
last_updated: 2026-07-29
---

# Reference Implementation

This kit was generalized from a mature internal deployment of the same operating model. This page maps the kit's concepts to what they look like in a real, Run-phase instantiation, so you can see where a small Crawl-phase workspace is heading.

For a concrete, runnable example you can open and poke at, use [sandbox/](sandbox/) and [example-walkthrough.md](example-walkthrough.md). This page is the higher-altitude map.

---

## The layout at maturity

A mature deployment separates the layers into distinct top-level folders:

```
<workspace>/
  agentic-support/                 # SUPPORT LAYER (the "operating system")
    README.md, AGENTS.md
    docs/architecture.md           # authority chain + component roles
    skills/skill-manifest.yaml     # skill index with per-skill status
    skills/<name>/SKILL.md         # canonical procedures
    skills/<name>/adapters/{claude,codex,opencode}/   # thin per-harness pointers
    context-fabric/schemas/.../schema.json            # the record schema
    context-fabric/records/{systems,resources,profiles,sync-manifests}/
    tools/                         # approved shell mechanics (run by skills)
    validation/                    # the invariant checker
  product-work/                    # PRODUCT-WORK LAYER
    AGENTS.md                      # ~7-line two-lane charter
    <canonical>/                   # reviewed, profile-bound product areas
    <prototyping>/                 # spikes, mockups, experiments
  <repo-checkouts>/                # code checkouts, OUTSIDE the workspace
```

## Concept mapping

| Kit concept | What it is at maturity |
|---|---|
| Support layer | A dedicated top-level folder (e.g., `agentic-support/`) holding skills, Context Fabric, tools, and validation |
| Authority chain | Documented in the support layer's `docs/architecture.md` |
| Skill bundle + adapters | `skills/<name>/SKILL.md` plus thin `adapters/<harness>/` pointers; the richest bundles also carry `assets/` and paired `references/` fixtures |
| Skill manifest with status | `skills/skill-manifest.yaml` with `status: enabled | paused` so structure ships before every skill is finished |
| Binding tokens + a machine-local descriptor | A `${...}` bindings table at the top of portable skills, resolved per machine from a declared, never-synced descriptor |
| Context Fabric | A schema-governed JSON catalog with three record kinds: system, repository, product-profile |
| Product profile | `context-fabric/records/profiles/<slug>.json`, declared by a product area's `AGENTS.md` |
| Anchors | Validated exact references inside a system (a tracker project key, a wiki page ID) carried on a profile |
| Reference vs. operational | The catalog (`records/`) versus a versioned, reviewed sync manifest that lists repos to actually check out |
| Approved tools | Plain shell mechanics invoked by skills, with preview/apply safeguards and credential redaction |
| Validation | A script checking manifest resolution, required files, no secrets, no checkouts, JSON parseability, and boundary-language preservation |
| Two-lane charter | A short root `AGENTS.md` splitting canonical from prototyping |
| Context tiers: always-loaded / load-on-demand / audit-only (architecture §6) | A memory loop (`MEMORY.md` index → `memory/*.md`, plus a prompt log and a task list). The kit adopts the tiering and the accreting `docs/solutions/` + `CONCEPTS.md` lanes, and still declines to prescribe an auto-loaded prompt log. |
| Named onboarding | A `pm-onboarding` skill that walks a new PM through setup |
| Stewardship | A stewardship summary table plus `maintainers` on each profile |
| Review personas | Role personas an agent adopts to critique artifacts, plus human advisors for high-stakes work |

## The anatomy of a mature product area

The most developed areas in a real deployment show the full pattern:

- `AGENTS.md` declaring one Context Fabric profile, plus a `CLAUDE.md` `@AGENTS.md` import
- Persistent memory (the deployment's approach; the kit defers prescribing one — see architecture §6)
- A `deliverables/` folder of canonical outputs with a documented cross-reference/cascade map
- A read-only `reference/` corpus with its own `AGENTS.md` defining an evidence-with-provenance research workflow
- Extractions of source rules as paired natural-language + formal-rule files under a manifest
- Build scripts that regenerate binary deliverables reproducibly
- Standard `docs/` lanes

## What a mature deployment surfaced (and the kit resolves)

Two ambiguities are worth resolving up front in any new workspace:

1. **One source of truth.** Canonical skills and Context Fabric records live in the support layer. Anything in a product folder that looks like shared context is a labeled pointer, not a second "active" copy. Avoid the state where the same context is both "moved" and "active" in two places.
2. **One sharing mechanism.** Decide git-backed or synced-storage sharing per team and per phase, and finish wiring the one you pick. The choice changes the safety model, not just the plumbing. See [../docs/collaboration-and-governance.md](../docs/collaboration-and-governance.md).

## Where to go next

Anchor on the kit's own docs: [../docs/architecture.md](../docs/architecture.md), [../docs/context-fabric.md](../docs/context-fabric.md), and the generated example at [sandbox/](sandbox/).
