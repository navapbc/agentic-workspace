---
title: Multi-root workspaces over symlink assembly for agent harnesses
category: architecture-patterns
problem_type: architecture_pattern
component: development_workflow
severity: high
applies_when:
  - "A shared workspace must span synced folders (Drive, Dropbox, OneDrive) and machine-local folders (git checkouts, personal working dirs)"
  - "Team members work through agent harnesses whose file viewers and pickers are the primary navigation surface"
  - "Shared tools need stable per-machine paths without inferring them from directory shape"
tags: [multi-root, symlinks, workspace-descriptor, harness-portability, sync, binding-contract]
---

# Multi-root workspaces over symlink assembly for agent harnesses

## Context

The first shipped version of this workspace pattern assembled a single local root
by symlinking each synced collaboration lane next to a real machine-local
checkouts folder. One day of trialing exposed a blocking defect: **agent harness
file viewers do not display the contents of symlinked folders**, so the assembled
root was invisible exactly where members work. For at least one major harness this
is documented upstream behavior; for the others it was unverified rather than
known-safe — which is the same risk with less evidence.

A second failure followed. With the assembled root bypassed, the checkouts
folder's own `AGENTS.md` became the session's primary instruction file, and agents
adopted that narrow root's conventions as if they were the whole workspace.

## Guidance

**Hand the harness multiple physical directories instead of assembling one root
from links, and split orientation by consumer.**

- **Roots are physical and declared.** Each member declares their own set: the
  shared support tree, a machine-local checkouts root, one or more
  working-materials roots, plus optional extras. Every harness that supports
  multi-root has a mechanism for this (an additional-directories setting, a
  writable-roots list, a multi-root workspace file); use it rather than the
  filesystem.
- **Every root carries its own thin guidance file that points back to the support
  tree** and says, in as many words, *the root you opened in is not the whole
  workspace*. This is what stops a narrow root's conventions from being mistaken
  for the pattern.
- **Cross-root references use binding tokens** (`${AGENTIC_REPO_CHECKOUT_ROOT}/<repo>/`),
  never sibling-relative `../` paths — roots share no common parent, so `../`
  cannot resolve anywhere. A lint in `validation/check-workspace.sh` blocks
  reintroduction.
- **Member-specific harness configuration stays in user scope on the machine.** A
  settings folder inside a synced root replicates one member's personal
  configuration to the whole team. See the companion learning on the recurrence
  trap.

## Why this matters

Symlink assembly optimizes for shell tools, which traverse links fine with the
right flags. But the members' actual interface is the harness viewer, which does
not. The failure is silent: tools pass, doctors report green, and the workspace
simply does not appear in the UI members use.

The orientation split matters because the two consumers have opposite constraints.
In-session agents can only rely on files inside roots the harness exposes; shell
scripts can always read a home-directory file but cannot see the harness's root
selection. Designing each mechanism for the consumer that can actually reach it is
what made the pattern robust across harnesses — earlier single-registry designs
failed one consumer or the other.

## When to apply

- Designing any shared workspace that must span synced storage and machine-local
  storage that must never sync (git internals, credentials, personal settings).
- Writing onboarding or setup materials for teams working through agent harnesses.
  Check each harness's multi-root support explicitly; at least one popular harness
  had none as of mid-2026, which makes it unsuitable for this pattern rather than
  merely awkward.
- Any time you are tempted to make a workspace "simpler" by linking folders
  together. Verify the harness viewer first.

## Related

- `docs/workspace-routing.md` — the root-role model and cross-root guardrails.
- `docs/skill-binding-contract.md` — how bindings resolve, and why the descriptor
  lives in the home directory.
- `skills/workspace-setup/SKILL.md` — the per-harness multi-root mechanisms.
