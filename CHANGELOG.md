# Changelog

All notable changes to the Agentic Workspace Starter Kit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Public open-source repository scaffolding: license, contributing/security/conduct docs, issue and PR templates, and CI that enforces the kit's own invariants (`shellcheck`, sandbox drift check, `validate-workspace.sh`).

## [0.1.0] - 2026-07-22

### Added
- Initial kit: three-layer operating model (guidance / support / product-work), harness- and model-agnostic.
- Docs: architecture, phased adoption (Crawl / Walk / Run), local setup, harness-and-model-agnostic, collaboration and governance, Context Fabric, directory-and-naming standard, glossary.
- Templates: workspace scaffold, Context Fabric records, portable skill bundle with adapters and sync script, harness config.
- Scripts: `new-workspace.sh`, `validate-workspace.sh`, `seed-sandbox.sh`.
- Reference: generic reference implementation, a fictional worked walkthrough, and a generated, validated sandbox workspace.

[Unreleased]: https://github.com/navapbc/agentic-workspace/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/navapbc/agentic-workspace/releases/tag/v0.1.0
