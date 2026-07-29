# Validation

`./check-workspace.sh` is the gate. Run it after any structural or routing change,
and in CI if this workspace is git-backed.

```bash
./check-workspace.sh [extra-lane-dir]...
```

The support tree and the shared workspace root are always checked. Pass additional
lane directories (a practice collaboration lane, a second product lane) to include
them in the guidance and secret checks.

## What it enforces

| Invariant | Why it fails rather than warns |
|---|---|
| Manifest ↔ skill consistency | A registered skill with no file, or a file with no entry, misinforms every session that reads the manifest. |
| Skill contract (frontmatter fields, required sections, `workflow_id` match) | A skill missing Guardrails or Failure Handling will be run anyway, without them. |
| No user-home absolute paths in skills, tools, or docs | One person's machine layout in shared infrastructure breaks it for everyone else. |
| No sibling-relative cross-root references | Roots share no common parent, so the path resolves nowhere — silently. |
| Thin `AGENTS.md` (procedure markers) | Always-loaded files are paid for in every session and drift from the skill they were copied from. |
| No token-shaped values, no secret-manager references | Shared verbatim with the whole team. |
| No dependency folders, no nested checkouts in the support tree | Both indicate something leaked into the shared tree that must never sync. |
| Every Context Fabric JSON parses, and passes the record lint | A malformed record breaks the fact it carries and every profile referencing it. |
| `shellcheck` clean (when installed) | Tools mutate real directories. |
| Component test suites pass | The descriptor and doctor contracts are what onboarding branches on. |

## What it warns about

Thinness-budget overruns, a missing `CLAUDE.md` import beside an `AGENTS.md`, OS
metadata, `shellcheck` not installed, and member-specific harness state inside the
shared tree.

That last one is warn-only on purpose: a harness recreates the file whenever a
session opens with a shared folder as its primary folder, so a hard failure would
block work over something already done. The durable fix is the launch shape — see
`../docs/solutions/workflow-issues/synced-primary-folder-leaks-harness-settings.md`.

## Test suites

`test/*.test.sh` are self-contained behavioral tests. They build fixtures in a temp
directory and point `AGENTIC_WORKSPACE_DESCRIPTOR` at a temp file, so they never read
or write the live machine-local declaration. Run one directly while iterating:

```bash
./test/workspace-doctor.test.sh
```

Add a suite here — not to a single component's own directory — when a check spans
two or more components.
