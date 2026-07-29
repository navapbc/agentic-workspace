---
title: A synced folder as the session's primary folder leaks personal harness settings to the team
category: workflow-issues
problem_type: workflow_issue
component: development_workflow
severity: medium
applies_when:
  - launching an agent session with a cloud-synced shared folder as the primary project folder
  - configuring multi-root access to synced roots
  - the workspace doctor or validation emits a WARN about harness config inside a shared root
symptoms:
  - "a local settings file reappears inside the shared workspace root after every session"
  - personal harness settings and permission grants reach the whole team through sync
  - the doctor and validation both WARN on the condition but nothing prevents it
root_cause: config_error
resolution_type: config_change
tags: [harness-config, sync, multi-root, launch-shape, settings-local, workspace-doctor]
---

# A synced folder as the session's primary folder leaks personal harness settings to the team

## Context

Once working directly in synced mount folders became first-class — members point
their harness at several physical directories, some of which live on shared synced
storage — it became natural, and easy, to open a session with the shared workspace
root as the session's *primary* folder.

The trap: harnesses persist session-local state (permission grants, local
overrides) under the primary project folder. When that folder is synced, the
harness recreates the file inside the shared tree and sync distributes it to every
teammate. This is not hypothetical; the trial that shipped the pattern had already
leaked one.

The recurrence problem is structural. Deleting the file fixes nothing, because the
next session launched with a synced primary folder recreates it. Detection WARNs
fire *after* the write — by which time it may already have synced.

## Guidance

**Never make a synced shared folder the primary folder of an agent session. Use a
machine-local primary folder, and attach the shared roots as additional
directories in user scope.**

- **Persistent:** add each non-primary root to your harness's user-scope
  additional-directories setting — never to a project-scope config inside the
  shared tree.
- **Per-session:** use the harness's per-session flag to add directories.
- A desktop app's folder picker selects one primary folder; user-scope additional
  directories still apply on top of it.

Then launch from any machine-local directory. The session sees the shared roots
read/write, but all harness-generated state lands under the machine-local primary
folder, where sync never sees it.

The shared guardrail lives in `docs/workspace-routing.md`: never store
member-specific harness configuration inside a synced root; keep it in user scope
on your machine. It generalizes across harnesses — each has its own user-scope
config file and its own additional-roots mechanism.

## Why this matters

A local settings file is personal and machine-specific: it carries one member's
permission grants and local overrides. In a git-backed repo this class of file is
gitignored, and even a mistaken commit is visible in review and revertible. A
workspace shared over synced storage has neither safety net:

- **Sync is the distribution channel.** Any file written under the shared root
  propagates to every teammate silently, with no review step, no diff, and no
  revert history beyond the provider's own version snapshots.
- **The blast radius is other people's sessions.** A synced local settings file
  sits in the project scope of every teammate who opens a session there, applying
  one person's permission grants to their harness.
- **Detection is WARN-only by design.** Both the doctor and validation warn rather
  than fail, because a harness can recreate the file at any time and a hard failure
  would block work over something already done. The WARN tells you it happened
  again; the launch shape is what stops it.

That last point is the transferable lesson: when designing validation for any
shared synced tree, decide explicitly whether a check can only *detect* or can
actually *prevent*, and put the real fix wherever prevention lives.

## When to apply

- Launching any agent session where a synced shared folder is a candidate primary
  folder.
- Setting up a new member's workspace — the setup skill's per-harness appendix is
  the authority; this file explains why the user-scope rule exists.
- Triaging a doctor or validation WARN about harness configuration in the shared
  tree: fix the launch shape, *then* delete the file. Deletion alone will not stick.

## Examples

Bad launch shape — synced root as primary folder:

```sh
cd "<synced workspace root>" && <harness>
# session writes its local settings file here; sync distributes it to the team
```

Good launch shape — machine-local primary, shared roots attached in user scope:

```sh
# once, in your harness's user-scope settings: add the shared roots as additional directories
cd ~/<your-local-projects-dir> && <harness>
```

Detection signal — the doctor scans the shared workspace tree for per-member
harness state and prints:

```text
WARN: member-specific harness state found inside the shared workspace tree:
        <hit path>
        Harness settings belong in user scope on your machine...
```

The check matches the harness config *directory*, not only the settings file
inside it, so an empty leftover directory still trips it. That is correct: the
directory's presence means some session used the shared root as project scope.

## Related

- `docs/workspace-routing.md` — the shared guardrail and root-role model.
- `docs/solutions/architecture-patterns/multi-root-workspace-over-symlink-assembly.md` — the companion architecture learning.
- `skills/workspace-setup/SKILL.md` — per-harness user-scope configuration.
