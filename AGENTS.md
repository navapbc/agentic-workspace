# Agentic Workspace Starter Kit -- Agent Instructions

You are working inside Nava's **Agentic Workspace Starter Kit**: a reusable kit that lets a PM stand up a shared, agentic product workspace with shared context, boundaries, and reusable procedures. It generalizes a mature internal operating model and is harness- and model-agnostic.

## Operating Modes

Identify which mode applies before doing anything else.

### Mode 1: Using the kit to stand up or extend a workspace

Someone is creating a new shared workspace, or adding to one, using these templates and scripts. In this mode:

- **Scaffold, don't hand-author from scratch.** Use `scripts/new-workspace.sh` or copy `templates/workspace/`. Copy record and skill templates rather than inventing structure.
- **Respect the phase.** Do not build Run-phase machinery (Context Fabric schema tooling, CI, validation) for a team at Crawl. Read `docs/phased-adoption.md` and match the team's phase.
- **Keep `AGENTS.md` files thin.** Boundaries, routing, and exceptions only. Never copy procedures or shared facts into them. Reference the support layer instead.
- **Bridge Claude Code with an import, not a copy.** Any folder with an `AGENTS.md` should have a `CLAUDE.md` containing the single line `@AGENTS.md` (Claude Code reads `CLAUDE.md`, not `AGENTS.md`). Never duplicate `AGENTS.md` content into `CLAUDE.md`.
- **Honor the safety invariants** in `docs/local-setup.md` and `docs/collaboration-and-governance.md`: no credentials, no code checkouts inside the workspace, no absolute machine paths in shared files, no OS metadata.
- **One source of truth.** Skills and Context Fabric records live in the support layer. Anything in a product folder that looks like shared context is a labeled pointer, never a second copy.

### Mode 2: Improving the kit itself

Someone is editing the kit's templates, docs, or scripts. In this mode:

- **Keep the layers coherent.** The kit teaches a three-layer model (guidance / support / product-work) and a phased adoption path. Any change must stay consistent with `docs/architecture.md` and `docs/phased-adoption.md`. If you change the model, update both.
- **Templates are copy-ready.** Files under `templates/` are scaffolding. Keep them generic (no internal-specific or client-specific content), with placeholders clearly marked.
- **Validate shell scripts.** Run `shellcheck` on any script in `scripts/` before considering it done. Keep scripts POSIX `sh` where the existing ones are.
- **Update the README map.** If you add, move, or rename files, update `README.md`'s "What's in the kit" table and any affected doc cross-links.
- **Keep the reference implementation accurate but separate.** `reference/reference-implementation.md` documents the source patterns. Do not let internal-specific details leak into the generic templates or docs.
- **The sandbox is generated, not hand-edited.** `reference/sandbox/` is produced by `scripts/seed-sandbox.sh` and is entirely fictional. To change it, edit the seed script and regenerate. It also serves as a regression test: after changing templates or scripts, run the seed and confirm `validate-workspace.sh reference/sandbox` still passes.

---

## Orientation

**Start here:** `README.md` for the map, then `START-HERE.md` for the model and adoption flow.

**Architecture:** `docs/architecture.md` is the authoritative description of the three layers and the authority chain.

**Templates:** `templates/` holds copy-ready scaffolding for workspaces, Context Fabric records, skills, and harness config.

**Scripts:** `scripts/new-workspace.sh` scaffolds a workspace; `scripts/validate-workspace.sh` checks invariants.

**Reference:** `reference/` documents how a mature internal deployment maps to this model, plus a fictional worked example.

## Conventions

- **Directory naming.** Lowercase kebab-case for all directories (`agentic-support/`, `context-fabric/`, `product-area/`). Matches the internal reference implementation and the skill/slug identifier convention, so paths never need quoting or encoding. Full rule in `docs/directory-and-naming-standard.md`.
- **Front matter.** Every markdown doc carries YAML front matter (`purpose`, `audience`, `status`, `last_updated`). Read it first to judge relevance.
- **Writing style.** Confident principal-PM voice. Lead with the answer. No em dashes. IC-level decision aids over frameworks. Actionable over descriptive.
- **Thin guidance, referenced facts.** The whole kit exists to avoid duplicated, drifting context. Practice what it teaches: reference, don't repeat.
- **Boundary.** This kit is Nava-primary and org-general. Do not embed client-sensitive, internal-only, or business-development material in it. Keep examples generic or clearly fictional.
