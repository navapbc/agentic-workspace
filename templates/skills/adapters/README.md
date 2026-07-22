# Skill runtime adapters

`skills/<skill-name>/` is the canonical skill bundle. Keep the shared `SKILL.md`, `references/`, and `assets/` there.

Harness-specific files, when a harness genuinely needs a different runtime artifact, go under `skills/<skill-name>/adapters/<harness>/`. The sync script overlays that adapter onto the generated runtime mirror:

```
skills/<skill-name>/adapters/opencode/agents/openai.yaml
  -> ~/.config/opencode/skills/<skill-name>/agents/openai.yaml
```

## Rules

- An adapter is a **thin pointer**, not a copy. It names the harness and, if needed, that harness's discovery convention, then defers to the canonical `SKILL.md`.
- An adapter must state: "The canonical workflow controls behavior whenever this adapter is stale or disagrees with it."
- Do not fork shared workflow instructions into an adapter. If you find yourself copying the procedure, stop — put it in the canonical `SKILL.md`.
- Many harnesses (e.g. Codex) need no adapter at all; they consume the shared bundle directly. Add an adapter only when a harness requires a genuinely different artifact.

## Adapter SKILL.md shape (Claude/Anthropic style)

Some harnesses expect a minimal frontmatter shape:

```yaml
---
name: {{skill-slug}}
description: {{one sentence}}
---

This {{Harness}} skill is a thin adapter. Read the canonical source of truth at
`{{support-root}}/skills/{{skill-slug}}/SKILL.md`. That file and its output contract
control behavior whenever this adapter is stale or disagrees with them.
```
