# Changelog

All notable changes to the Agentic Workspace Starter Kit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Public open-source repository scaffolding: license, contributing/security/conduct docs, issue and PR templates, and CI that enforces the kit's own invariants (`shellcheck`, sandbox drift check, `validate-workspace.sh`).
- `reference/anatomy.md`: a one-page visual anatomy (Mermaid + tables) that renders directly on GitHub, alongside the existing standalone `anatomy.html`.

### Changed
- Docs lanes are now presented as a team-adjustable starting suggestion rather than a fixed set; removed the tool-/plugin-specific framing so the kit stays skill-agnostic.
- Renamed the reviewed product-work lane from `canonical/` to `product-work/`, and reframed the two lanes as a split by intent (work the team relies on vs. experiments). "Canonical" as a source-of-truth adjective is now stated plainly as "source of truth."
- Review, named ownership, and per-doc status labels are now optional practices a team opts into, not requirements.
- `collaboration-and-governance.md` now gives explicit, step-by-step Google Drive and git setup, including the recommended Shared Drive layout and sync gotchas.
- Lowered the barrier for non-technical users: a "No terminal? Start here" Quickstart (download-ZIP + a copy-paste prompt that has the agent scaffold the workspace) and a "Choosing a harness (least-technical first)" note in `local-setup.md` recommending graphical/web agents over the CLI.
- Broadened README/START-HERE from a PM-only audience to anyone leading shared work with agents; condensed the expert/user review-panel material to a single optional mention; light plain-language pass over the non-technical docs.

## [0.1.0] - 2026-07-22

### Added
- Initial kit: three-layer operating model (guidance / support / product-work), harness- and model-agnostic.
- Docs: architecture, phased adoption (Crawl / Walk / Run), local setup, harness-and-model-agnostic, collaboration and governance, Context Fabric, directory-and-naming standard, glossary.
- Templates: workspace scaffold, Context Fabric records, portable skill bundle with adapters and sync script, harness config.
- Scripts: `new-workspace.sh`, `validate-workspace.sh`, `seed-sandbox.sh`.
- Reference: generic reference implementation, a fictional worked walkthrough, and a generated, validated sandbox workspace.

[Unreleased]: https://github.com/navapbc/agentic-workspace/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/navapbc/agentic-workspace/releases/tag/v0.1.0
