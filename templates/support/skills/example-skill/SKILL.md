---
workflow_id: example-skill
version: 1
status: enabled
owner: {{team or product area}}
source_of_truth: true
portable_across_harnesses: true
description: {{One sentence: what this skill does and when to use it.}}
argument-hint: "[{{what the user passes, if anything}}]"
---

# Example Skill

<!--
  This SKILL.md is the single source of truth for this procedure.
  Per-harness adapters point back to this file and must never fork the procedure.
  Keep it tool-neutral. Describe the goal and the output shape, not model-specific tricks.
-->

Use this skill when {{trigger conditions}}.

## Bindings

Reference paths through these named bindings, never hardcoded absolute paths. They
resolve per machine through the workspace descriptor — see
[the skill binding contract](../../docs/skill-binding-contract.md). List only the
bindings this skill actually consumes.

| Binding | Meaning | Resolution |
|---|---|---|
| `${AGENTIC_SUPPORT_ROOT}` | The support tree | The loaded support tree |
| `${AGENTIC_PRODUCT_WORK_ROOT}` | Shared product work | Descriptor, when declared; else an explicit caller input |

## Triggers

- {{"phrase a user might say"}}
- {{another trigger}}

## Required Context

Read these before acting:

1. The workspace root `AGENTS.md`
2. The relevant product-area `AGENTS.md` and its Context Fabric profile
3. {{any other required doc}}

If a required file is missing, continue with the best available local pattern and note the gap.

## Procedure

1. {{Step.}}
2. {{Step.}}
3. {{Step.}}

## Guardrails

- Never store or echo credentials, tokens, `op://` URIs, or raw authenticated responses.
- Stay within the product area's boundaries; do not write outside its lanes.
- {{skill-specific guardrails}}

## Output Shape

{{Describe exactly what the skill produces: file locations, format, sections. Keep this stable across harnesses.}}

## Failure Handling

{{What to do when inputs are missing, access fails, or the task is out of scope. Prefer a useful partial result with noted gaps over blocking.}}

## Harness Interpretation

Claude, Codex, OpenCode, and other harnesses preserve the same output shape. This file is the source of truth; if a per-harness adapter disagrees or is stale, this file wins.
