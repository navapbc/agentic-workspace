# Changelog

All notable changes to the Agentic Workspace Starter Kit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-07-29

The support layer stops being something you build and becomes something you **install**. This release carries the current, matured architecture from the deployment the kit generalizes — including two failures that version 0.1.0's model would have walked teams straight into.

### Added
- **`templates/support/`: the complete, runnable support engine.** Skills, Context Fabric (schemas, record templates, authoring guidance), eight tools, a validation gate with two behavioral test suites, and the doctrine docs. Every file installs verbatim except two the team authors (`CONCEPTS.md`, `docs/context-source-ladder.md`), which is what makes in-place upgrades possible.
- **`scripts/install-support.sh`** — install or upgrade the engine in any workspace. `--check` previews; team-owned files are preserved; a locally modified generic file is reported as a conflict rather than silently overwritten.
- **Multi-root workspace model.** Roots are physical directories handed to the harness, declared per machine in `~/.agentic-workspace/workspace-descriptor.yaml` (schema included) and referenced from shared documents by binding token.
- **`tools/workspace-doctor.sh`** — read-only session-start probe: where am I, which roots are declared, which capability tiers are available, and the one step that unlocks each locked tier. Fail-closed exit codes (2 = support tree unresolvable, 3 = declaration missing or invalid) that skills and onboarding branch on.
- **`tools/generate-workspace-descriptor.sh`** — writes the declaration, refusing roots that do not exist, roots that nest or repeat, a re-run that would silently narrow a previous declaration, and a checkout root inside the shared tree.
- **`tools/generate-repo-digests.sh`** — per-repository summaries in shared context, so repository questions can be answered with no git installed and no checkout open. Carries `generated_at` / `do_not_rely_after`.
- **`tools/refresh-manifest-repos.sh`** — checkout hydration from a reviewed sync manifest, with a digest-bound preview→apply contract, a full preflight, and fetch/fast-forward only. Host-agnostic; authentication is delegated entirely to the caller's git credential helper.
- **`tools/route-artifact.sh`** and **`tools/scaffold-product-area.sh`** — deterministic artifact placement with typed, rationalized area exceptions, and one-command compliant product areas. `product-work/area-manifest.yaml` is the registry.
- **`tools/snapshot-context-fabric-record.sh`** and **`tools/lint-context-fabric-records.sh`** — snapshot-first record editing (the safety net where sync, not review, is the distribution channel) and dependency-free field-level record rules, including syncability preconditions and dangling-reference detection.
- **Three enabled skills:** `workspace-setup` (interviews a new member from folder access to doctor-green, with a per-harness multi-root appendix), `artifact-routing`, and `repo-sync`.
- **`validation/check-workspace.sh`** — the workspace gate: manifest↔skill consistency, the skill contract, no user-home paths, no sibling-relative cross-root references, thin `AGENTS.md`, secrets, record lint, `shellcheck`, and the component test suites.
- **Accreting context lanes**: `docs/solutions/<category>/` for durable learnings (with three seeded, de-identified findings that explain why the workspace pattern is shaped as it is) and `CONCEPTS.md` for vocabulary.
- **`localReferenceResource`**, a fourth Context Fabric record kind for governed cross-product sources, admitted only when it can answer "how does a reader verify an artifact from here?"
- Architecture §0 (the multi-root topology) and §6 (context tiers: always-loaded / load-on-demand / audit-only). Twelve new glossary terms.

### Changed
- **BREAKING: `bindings.env` is retired.** Per-machine paths now live in one machine-local, never-synced declaration and resolve through binding tokens (`${AGENTIC_SUPPORT_ROOT}`, `${AGENTIC_REPO_CHECKOUT_ROOT}`, …). A shared file containing a machine path is now a hard validation failure.
- **BREAKING: `templates/skills/` and `templates/context-fabric/` are consolidated into `templates/support/`.** Two copies of the same templates contradicted the kit's own one-source-of-truth rule.
- `skill-manifest.yaml` schema: entries are `id` / `path` / `status` (`enabled` / `partially-paused` / `paused`), and a paused entry **requires** a `review_by` date so a pause is a decision with a deadline. The doctor surfaces overdue reviews.
- `new-workspace.sh --with-support` now installs the engine via `install-support.sh` and creates the area registry.
- Walk and Run phases are rewritten around installing and turning on the engine rather than assembling it. Five new anti-patterns, including symlink-assembled roots, tools that guess machine paths, and a synced folder as the session's primary folder.
- The sandbox demonstrates the full model: the engine installed, both authored files filled in, six records including a reference resource, a reviewed sync manifest, a generated repo digest, a generated routing card, and a typed routing exception.
- CI additionally lints the engine, runs the engine's own gate against a copy of the sandbox, and asserts the installer is idempotent.
- Records now require `contentLocations`, and repository resources require `organization`, `repository`, and `checkoutDirectory`; `accessState` uses `available` (was `accessible`).
- Synced-storage sharing is described by its safety model rather than by the provider name, and the git-vs-synced choice is framed as a choice of safety net.

### Fixed
- **Symlink-assembled roots.** Version 0.1.0 assumed a single workspace folder that teams naturally built by linking shared and local folders together. Harness file viewers do not display symlinked folders' contents, so the workspace vanishes from the UI members work in while every script still reports success. Roots are now physical.
- **Sibling-relative cross-root paths.** `../repo-checkouts/` cannot resolve once roots share no common parent. The gate now fails on reintroduction.
- **Personal harness settings leaking to the whole team.** A session whose primary folder is a synced shared folder writes its local settings file there, and sync distributes it. Documented as a launch-shape rule, flagged (warn-only, deliberately) by both the doctor and the gate, and explained in a seeded solutions file.

### Added — earlier in this cycle
- Public open-source repository scaffolding: license, contributing/security/conduct docs, issue and PR templates, and CI that enforces the kit's own invariants.
- `reference/anatomy.md`: a one-page visual anatomy (Mermaid + tables) that renders directly on GitHub, alongside the standalone `anatomy.html`.
- `docs/images/download-zip.svg`: a visual in the no-terminal Quickstart showing where GitHub's **Download ZIP** option is.

### Changed — earlier in this cycle
- List Codex (OpenAI's agent, now offered through ChatGPT) first wherever harnesses are enumerated, and note the ChatGPT rename in the definitional spots.
- Docs lanes are now presented as a team-adjustable starting suggestion rather than a fixed set; removed the tool-/plugin-specific framing so the kit stays skill-agnostic.
- Renamed the reviewed product-work lane from `canonical/` to `product-work/`, and reframed the two lanes as a split by intent (work the team relies on vs. experiments). "Canonical" as a source-of-truth adjective is now stated plainly as "source of truth."
- Review, named ownership, and per-doc status labels are now optional practices a team opts into, not requirements.
- `collaboration-and-governance.md` now gives explicit, step-by-step synced-storage and git setup, including the recommended shared-drive layout and sync gotchas.
- Lowered the barrier for non-technical users: a "No terminal? Start here" Quickstart and a "Choosing a harness (least-technical first)" note in `local-setup.md`.
- Broadened README/START-HERE from a PM-only audience to anyone leading shared work with agents; light plain-language pass over the non-technical docs.

## [0.1.0] - 2026-07-22

### Added
- Initial kit: three-layer operating model (guidance / support / product-work), harness- and model-agnostic.
- Docs: architecture, phased adoption (Crawl / Walk / Run), local setup, harness-and-model-agnostic, collaboration and governance, Context Fabric, directory-and-naming standard, glossary.
- Templates: workspace scaffold, Context Fabric records, portable skill bundle with adapters and sync script, harness config.
- Scripts: `new-workspace.sh`, `validate-workspace.sh`, `seed-sandbox.sh`.
- Reference: generic reference implementation, a fictional worked walkthrough, and a generated, validated sandbox workspace.

[Unreleased]: https://github.com/navapbc/agentic-workspace/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/navapbc/agentic-workspace/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/navapbc/agentic-workspace/releases/tag/v0.1.0
