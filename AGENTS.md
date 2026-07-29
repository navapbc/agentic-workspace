# Agentic Workspace Starter Kit -- Agent Instructions

You are working inside Nava's **Agentic Workspace Starter Kit**: a reusable kit that lets a PM stand up a shared, agentic product workspace with shared context, boundaries, and reusable procedures. It generalizes a mature internal operating model and is harness- and model-agnostic.

## Operating Modes

Identify which mode applies before doing anything else.

### Mode 1: Using the kit to stand up or extend a workspace

Someone is creating a new shared workspace, or adding to one, using these templates and scripts. In this mode:

- **Scaffold and install, don't hand-author from scratch.** Use `scripts/new-workspace.sh` for the workspace and `scripts/install-support.sh` for the support engine. The engine is shipped whole — never hand-write a copy of a tool, skill, or schema that `templates/support/` already contains.
- **Roots are physical and declared.** Never assemble a workspace out of symlinks (harness viewers do not display symlinked contents). Never write a machine path into a shared file — declare roots with `tools/generate-workspace-descriptor.sh` and reference them by binding token. Never make a synced shared folder the session's primary folder.
- **Respect the phase.** Do not build Run-phase machinery (Context Fabric schema tooling, CI, validation) for a team at Crawl. Read `docs/phased-adoption.md` and match the team's phase.
- **Keep `AGENTS.md` files thin.** Boundaries, routing, and exceptions only. Never copy procedures or shared facts into them. Reference the support layer instead.
- **Bridge Claude Code with an import, not a copy.** Any folder with an `AGENTS.md` should have a `CLAUDE.md` containing the single line `@AGENTS.md` (Claude Code reads `CLAUDE.md`, not `AGENTS.md`). Never duplicate `AGENTS.md` content into `CLAUDE.md`.
- **Honor the safety invariants** in `docs/local-setup.md` and `docs/collaboration-and-governance.md`: no credentials, no code checkouts inside the workspace, no absolute machine paths in shared files, no member-specific harness state in the shared tree, no OS metadata.
- **Run the gate.** After a structural change to an installed workspace, run its `agentic-support/validation/check-workspace.sh` (or the lighter `scripts/validate-workspace.sh` before the engine exists).
- **One source of truth.** Skills and Context Fabric records live in the support layer. Anything in a product folder that looks like shared context is a labeled pointer, never a second copy.

### Mode 2: Improving the kit itself

Someone is editing the kit's templates, docs, or scripts. In this mode:

- **Keep the layers coherent.** The kit teaches a three-layer model (guidance / support / product-work) and a phased adoption path. Any change must stay consistent with `docs/architecture.md` and `docs/phased-adoption.md`. If you change the model, update both.
- **`templates/support/` is shipped code, not illustration.** It installs verbatim into real workspaces, so it must actually run: no placeholders in scripts, no `{{TOKENS}}` outside the two `.template` files (`CONCEPTS.md.template`, `docs/context-source-ladder.md.template`) and `templates/checkouts-root/`. Adding a file there means adding it to the engine every team gets.
- **Two authored files, and only two.** If a change would require every team to edit a third generic file, redesign it. That property is what makes `install-support.sh` able to upgrade in place.
- **Other templates are copy-ready.** Files under `templates/workspace/` are scaffolding. Keep them generic (no internal-specific or client-specific content), with placeholders clearly marked.
- **Validate shell scripts.** Run `shellcheck` on `scripts/*.sh` (clean at default severity) and `shellcheck -S warning` on `templates/support/{tools,validation,validation/test,skills}/*.sh`. Kit scripts are POSIX `sh`; engine tools are `bash` with `set -euo pipefail`. A new engine tool needs a test in `templates/support/validation/test/` when it has refusals worth protecting.
- **Update the README map.** If you add, move, or rename files, update `README.md`'s "What's in the kit" table and any affected doc cross-links.
- **Keep the reference implementation accurate but separate.** `reference/reference-implementation.md` documents the source patterns. Do not let internal-specific details leak into the generic templates or docs.
- **The sandbox is generated, not hand-edited.** `reference/sandbox/` is produced by `scripts/seed-sandbox.sh` and is entirely fictional. To change it, edit the seed script and regenerate. It is also the regression test: after changing templates or scripts, run the seed, then confirm both `scripts/validate-workspace.sh reference/sandbox` and `reference/sandbox/agentic-support/validation/check-workspace.sh` pass, and that `git diff reference/sandbox` shows only intended changes.

---

## Orientation

**Start here:** `README.md` for the map, then `START-HERE.md` for the model and adoption flow.

**Architecture:** `docs/architecture.md` is the authoritative description of the three layers and the authority chain.

**Templates:** `templates/support/` is the support engine (shipped code — see Mode 2); `templates/workspace/` is the workspace scaffold; `templates/harness-config/` holds per-harness notes.

**Scripts:** `scripts/new-workspace.sh` scaffolds a workspace; `scripts/install-support.sh` installs or upgrades the support engine; `scripts/validate-workspace.sh` is the lightweight pre-engine check; `scripts/seed-sandbox.sh` regenerates the fixture.

**Reference:** `reference/` documents how a mature internal deployment maps to this model, plus a fictional worked example.

## Conventions

- **Directory naming.** Lowercase kebab-case for all directories (`agentic-support/`, `context-fabric/`, `product-area/`). Matches the internal reference implementation and the skill/slug identifier convention, so paths never need quoting or encoding. Full rule in `docs/directory-and-naming-standard.md`.
- **Front matter.** Every markdown doc carries YAML front matter (`purpose`, `audience`, `status`, `last_updated`). Read it first to judge relevance.
- **Writing style.** Confident principal-PM voice. Lead with the answer. No em dashes. IC-level decision aids over frameworks. Actionable over descriptive.
- **Thin guidance, referenced facts.** The whole kit exists to avoid duplicated, drifting context. Practice what it teaches: reference, don't repeat.
- **Boundary.** This kit is Nava-primary and org-general. Do not embed client-sensitive, internal-only, or business-development material in it. Keep examples generic or clearly fictional.
