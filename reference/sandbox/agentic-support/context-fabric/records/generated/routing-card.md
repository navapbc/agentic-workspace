---
generated_at: 2026-07-29
source: product-work/area-manifest.yaml + tools/route-artifact.sh
---

# Routing card

One page: where an artifact goes. `tools/route-artifact.sh --type <type> --area <area>` gives the same answer with exceptions applied.

| Artifact | Destination |
|---|---|
| Raw ideas, options | `<area>/docs/ideation/` |
| Requirements, scope, delivery plans | `<area>/docs/plans/` |
| Durable learnings, solved patterns | `<area>/docs/solutions/` |
| Periodic health snapshots | `<area>/docs/pulse-reports/` |
| Notes from using your own tools | `<area>/docs/dogfood-reports/` |
| Read-only source bundles | `<area>/docs/references/<reference-set-slug>/` |
| Mockups, spikes, prototypes | `<area>/prototypes/<name>-prototype/` |
| Product synthesis | owning area folder (see its README) |
| Repository source | stays in the machine-local checkouts root; never copied in |
| Reusable workflow behavior | `agentic-support/skills/` |

## Area exceptions

**benefits-notices**

- variance: docs/plans — Notice changes ship to real beneficiaries, so ideas graduate straight to a reviewed plan rather than resting in the ideation lane.

Never create loose files at the product-work root or invent a parallel lane for work that fits an existing one. Unknown product area: ask which product owns the artifact; do not infer it from a checkout or alias name.
