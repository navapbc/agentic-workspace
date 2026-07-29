# Solutions

Durable learnings from work already done: bugs with non-obvious causes, workflow
traps, and patterns worth reusing. One file per learning, filed under a category
directory, with YAML frontmatter so an agent can judge relevance before reading
the body.

This lane is **load-on-demand**. Nothing here is read at session start, so it can
grow without costing every session context. That is the whole reason it is a
directory of files rather than lines in an `AGENTS.md`.

## Frontmatter

```yaml
---
title: <one line, states the finding>
date: <YYYY-MM-DD>
category: architecture-patterns | conventions | workflow-issues | <your own>
problem_type: architecture_pattern | workflow_issue | bug | convention
applies_when:
  - <condition under which this learning is relevant>
tags: [<searchable terms>]
---
```

Add `symptoms`, `root_cause`, `resolution_type`, `severity`, or
`related_components` when they help someone match a live problem to this file.

## Body sections

**Context** (what happened, with enough specifics to be checkable) → **Guidance**
(the rule, stated as a rule) → **Why this matters** (the reasoning, so a reader can
generalize past the exact case) → **When to apply** → **Examples** →
**Related**.

The Guidance section is the payload. If a reader can only skim one heading, it has
to be the one that tells them what to do.

## Seeded learnings

The three files shipped here came from the deployment this kit generalizes. They
are real findings, kept because they explain *why* the workspace pattern is shaped
the way it is — and they double as worked examples of the format.

- [architecture-patterns/multi-root-workspace-over-symlink-assembly.md](architecture-patterns/multi-root-workspace-over-symlink-assembly.md)
- [conventions/declared-over-derived-workspace-descriptor.md](conventions/declared-over-derived-workspace-descriptor.md)
- [workflow-issues/synced-primary-folder-leaks-harness-settings.md](workflow-issues/synced-primary-folder-leaks-harness-settings.md)
