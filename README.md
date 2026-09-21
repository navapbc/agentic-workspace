# Agentic Workspace

> **Skeleton.** U13 writes the full README; U12 decides the product name. This file exists so the repository is navigable from the first commit.

A schema-forward framework for giving an agent the context it needs, in three nested, versioned document tiers:

| Tier | Answers | Owned by |
|---|---|---|
| **Org** | What systems and interfaces does this organization run? | An organization's maintainer |
| **Bounded Context** | What does *this* team, product, or workstream work on, and where does it look first? | A team or workstream |
| **Individual** | Where do those things live on *my* machine, and how do I reach them? | One person, never shared |

Facts are authored once in `documents/` and projected into standalone `views/` an agent reads directly. A view is generated; it is never hand-edited.

## Map

| Path | What it holds |
|---|---|
| `START-HERE.md` | The entry point for a person or an agent new to this repository |
| `AGENTS.md` | Thin routing for an agent; the reading order lives here |
| `schemas/` | JSON Schemas: the three tier contracts, the shared definitions, the view contract |
| `templates/` | Commented YAML templates, generated from the schemas |
| `documents/examples/` | Fictional worked examples -- the only documents in this repository |
| `views/` | Generated standalone views; `linguist-generated` |
| `proposals/` | Correction proposals filed across a maintainer boundary |
| `scripts/` | Validation, generation, release, proposal, and setup scripts |
| `.agents/skills/` | The four skill bundles, mirrored at `.claude/skills/` |
| `tests/` | `tests/run.sh` is the gate |
| `docs/` | Authoring guidance, the maintenance interface, secret handling, experiments, marketing |
| `openspec/` | The specification changes every framework change goes through |
| `openwiki/` | Generated contributor documentation -- not governed fact |

## Status

Pre-release. `framework.json` carries the framework version and the contract versions. The repurposing checklist in `docs/repurposing.md` tracks the steps that move this repository from the retired starter kit to the framework.

## License

Apache-2.0. See `LICENSE` and `NOTICE`. Every organization, system, person, and secret reference in this repository is fictional.
