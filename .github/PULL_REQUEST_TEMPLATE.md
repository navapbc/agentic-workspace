<!-- Thanks for contributing to the Agentic Workspace Starter Kit. -->

## What this changes

<!-- One or two sentences. What does this PR do, and why? -->

## Type

- [ ] Docs / guidance
- [ ] Template
- [ ] Script
- [ ] Sandbox / example
- [ ] Other:

## Pre-PR checklist

Run from the repo root (CI runs the same):

- [ ] `shellcheck scripts/*.sh templates/skills/*.sh` is clean
- [ ] `./scripts/seed-sandbox.sh` regenerated the sandbox and `git diff --exit-code reference/sandbox` is clean (regenerated sandbox committed if it changed)
- [ ] `./scripts/validate-workspace.sh reference/sandbox` passes
- [ ] No secrets, credentials, or absolute machine paths added
- [ ] Guidance stays thin and templates stay generic (see `AGENTS.md` Mode 2)
