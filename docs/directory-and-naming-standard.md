---
purpose: The directory-naming standard for the kit and for workspaces stood up from it.
audience: Anyone creating or organizing directories in the kit or a workspace.
status: Active.
last_updated: 2026-07-22
---

# Directory and Naming Standard

One rule, so directories are consistent across the kit and every workspace built from it.

## The rule

**Directories use lowercase kebab-case (words separated by hyphens, no spaces).** Examples: `agentic-support/`, `context-fabric/`, `harness-config/`, `product-area/`, `product-work/`, `prototyping/`, `docs/`, `templates/`, `reference/`, `scripts/`.

This matches the internal reference implementation's conventions (`context-fabric`, kebab-cased skill and Context Fabric slugs) and the identifiers the kit already requires, so there is a single convention with no exceptions to remember.

## Why kebab-case

- **No quoting or encoding, ever.** Paths in shell, the workspace descriptor, `opencode.json`, and markdown links all work unquoted and unescaped. (Cloud-mount paths *above* your workspace routinely contain spaces, so tools still quote every path — but nothing you name adds to the problem.)
- **One convention.** Skill bundle directories must be kebab-case (the folder name *is* the skill's invocable name) and Context Fabric slugs are kebab-case. Everything else matching removes the special cases.
- **Aligns with tool defaults.** Agent tools already expect lowercase directories like `skills/` and `docs/`, so there is no lane-casing conflict whatever docs lanes your team picks.
- **Portable and git-clean** across case-insensitive (macOS) and case-sensitive (Linux) filesystems.

## Scope and the one soft edge

- **Inside the kit and inside workspaces:** all directories are kebab-case.
- **A team's own top-level workspace folder** is the creator's choice. If a PM wants `Benefits Notices Workspace/` as the human-facing container, that is fine; scripts only `cd` into it once. Everything *inside* it is kebab-case.

## Files

Markdown doc files are lowercase-kebab (`architecture.md`, `local-setup.md`). Content files inside a workspace (deliverables, references) follow whatever the team prefers; there is no kit requirement.

## Proper nouns vs. paths

Concept names stay capitalized in prose even though their directory is kebab-case. Write "the **Context Fabric** is a catalog" (proper noun) but reference the directory as `context-fabric/` (path). The declaration keyword an `AGENTS.md` uses, `Context Fabric profile: product:<slug>`, is a label, not a path, and stays capitalized.

## Applying it

- New workspaces created by `scripts/new-workspace.sh` already follow this standard.
- When you add a directory by hand, use kebab-case.
- `scripts/validate-workspace.sh` does not fail on casing; this is a convention the team upholds, and it is easy to uphold because everything is simply lowercase.
