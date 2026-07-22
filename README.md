# Agentic Workspace Starter Kit

A starter kit for Nava product managers to stand up a **shared, agentic product workspace**: a place where a group of PMs (and the agents they work with) share the same context, boundaries, vocabulary, and reusable procedures for the products they own together.

This kit generalizes an operating model proven on a mature internal deployment so any product team can adopt it without rebuilding the architecture from scratch. It is **harness-agnostic** (works with Claude Code, Codex, OpenCode, Cursor, and future tools) and **model-agnostic** (nothing here depends on a specific model).

---

## Who this is for

You are a Nava PM who:

- works on one or more products alongside other PMs, and
- wants your agent (Claude Code, Codex, etc.) to reliably know the product context, boundaries, and vocabulary without re-explaining it every session, and
- wants that shared context to be usable by teammates on their own machines and their own tools.

You do **not** need to be an engineer. You do not need to know the Context Fabric schema or write shell scripts. The kit is phased so you can start with a single markdown file and grow only as far as your team needs.

---

## Start here

1. Read **[START-HERE.md](START-HERE.md)** — what an agentic operating model is, and how to use this kit.
2. Pick your phase in **[docs/phased-adoption.md](docs/phased-adoption.md)** — Crawl, Walk, or Run. Most teams should start at Crawl.
3. Do the one-time setup in **[docs/local-setup.md](docs/local-setup.md)** — install the small set of dependencies and point your harness at the workspace.
4. Scaffold your workspace: run `scripts/new-workspace.sh` (see [START-HERE.md](START-HERE.md)) or copy `templates/workspace/` by hand.

If you only read one thing, read [START-HERE.md](START-HERE.md).

**Visual overview:** a one-page, shareable anatomy of the kit is published at https://claude.ai/code/artifact/5d730c6a-27db-4f97-baa5-d868ba4d7c03 (source: [reference/anatomy.html](reference/anatomy.html); redeploys from that file). Good for socializing the kit with teammates and stakeholders.

---

## What's in the kit

| Path | What it is |
|---|---|
| `START-HERE.md` | Entry point. The operating model in plain language and how to adopt it. |
| `AGENTS.md` / `CLAUDE.md` | Agent guidance for working **inside this kit** (using it vs. improving it). |
| `docs/architecture.md` | The clear architecture overview: layers, the authority chain, and how context flows. |
| `docs/phased-adoption.md` | Crawl / Walk / Run adoption path, mapped to Nava's AI-strategy phases. |
| `docs/local-setup.md` | Harness-agnostic and model-agnostic local setup, dependencies, and per-tool config. |
| `docs/harness-and-model-agnostic.md` | Why and how the kit stays portable across tools and models. |
| `docs/collaboration-and-governance.md` | Canonical vs. prototype, review gates, stewards, and git-vs-Drive sharing. |
| `docs/context-fabric.md` | What the Context Fabric is, when a team needs it, and how to author records. |
| `docs/directory-and-naming-standard.md` | The kebab-case directory-naming standard the kit and its workspaces follow. |
| `docs/glossary.md` | Shared vocabulary for the kit itself. |
| `templates/workspace/` | Copy-to-create scaffold for a new shared workspace (thin `AGENTS.md`, Docs lanes). |
| `templates/context-fabric/` | Record templates for the shared-context catalog (system / repository / product-profile). |
| `templates/skills/` | Portable skill-bundle template, manifest, adapters, and the sync script. |
| `templates/harness-config/` | Example config for OpenCode, Codex, and Claude Code. |
| `scripts/new-workspace.sh` | Scaffolds a new shared workspace from the templates. |
| `scripts/validate-workspace.sh` | Checks a workspace for the invariants (thin guidance, no secrets, no checkouts, valid JSON). |
| `scripts/seed-sandbox.sh` | (Re)generates the fictional sandbox workspace below. |
| `reference/sandbox/` | A fully populated, fictional workspace you can open and trial. Doubles as a regression test. |
| `reference/anatomy.html` | Source for the shareable visual one-pager (published Artifact). |
| `reference/reference-implementation.md` | How a mature internal deployment maps to this model, as a worked reference. |
| `reference/example-walkthrough.md` | A fictional team standing up a workspace end to end. |

---

## The one-paragraph version

A shared agentic workspace has three layers. A thin **guidance layer** (`AGENTS.md` files, one per directory) tells any agent the boundaries and where to route work. A **support layer** (skills + a shared-context catalog) holds the reusable procedures and machine-readable facts about your products, authored once and mirrored into whatever tool each teammate uses. A **product-work layer** holds the actual product artifacts, split into canonical (reviewed, shareable) and prototype (exploratory) lanes. Everything is plain markdown, JSON, and shell, so it is portable across tools, models, and machines, and it grows in phases so a new PM can start with a single file.

---

*Kit version 0.1.0. Maintained by Nava PBC. Generalized from a mature internal operating model. See `reference/reference-implementation.md` for the source patterns.*
