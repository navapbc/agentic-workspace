# Changelog

All notable changes to Context Fabric are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Individual documents carry their own per-document changelog (`<document-id>.CHANGELOG.md`) and their own integer release counter. This file tracks the framework, not the documents.

## [Unreleased]

### Added
- Repository baseline for the schema-forward framework: community-health files, a thin `AGENTS.md`, `framework.json`, the shared test library, an Actions probe workflow, and the go/no-go repurposing checklist (`docs/repurposing.md`).

### Removed
- **BREAKING: the Agentic Workspace Starter Kit is retired in place.** Every tracked file from v0.2.0 was removed in a single commit on top of the kit's history. The kit remains reachable at tags `v0.1.0` and `v0.2.0`; nothing from it is installed or upgraded by this framework, and there is no migration path from a kit-built workspace.

---

Releases before this line belong to the Agentic Workspace Starter Kit, a different product that shared this repository.

## [0.2.0] - 2026-07-29

Starter kit: the support layer shipped as an installable engine. See tag `v0.2.0`.

## [0.1.0] - 2026-07-22

Starter kit: initial public release. See tag `v0.1.0`.
