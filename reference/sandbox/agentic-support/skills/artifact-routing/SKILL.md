---
workflow_id: artifact-routing
version: 1
status: enabled
owner: workspace stewardship
source_of_truth: true
portable_across_harnesses: true
---

# Artifact Routing Workflow

Decide where a finished or in-progress artifact belongs, consistently, across every
practice and every harness. The mechanical answer comes from
`${AGENTIC_SUPPORT_ROOT}/tools/route-artifact.sh`; this workflow covers the
judgment cases the lookup table cannot decide on its own.

Use the tool first. It is a zero-token lookup that applies the team's registered
exceptions. Reach for this workflow only when the tool cannot answer.

## Bindings

| Binding | Meaning | Resolution |
| --- | --- | --- |
| `${AGENTIC_SUPPORT_ROOT}` | Support tree holding the routing tool and the generated card. | The loaded support tree. |
| `${AGENTIC_PRODUCT_WORK_ROOT}` | The product-work lane, when the member declared it. | Workspace descriptor; otherwise an explicit caller input. |

## Triggers

- "Where should this go?" for a plan, brief, learning, report, reference bundle,
  mockup, or spike.
- An artifact type or product area the routing tool does not recognize.
- Two lanes both look correct, or a product area has a registered variance.
- A member is about to create a new lane.

## Required Context

- `${AGENTIC_SUPPORT_ROOT}/context-fabric/records/generated/routing-card.md` — the
  generated one-page answer, including registered area exceptions.
- The owning area's `AGENTS.md` — local boundaries and any local exception.

## Procedure

1. **Run the tool.**
   `"${AGENTIC_SUPPORT_ROOT}/tools/route-artifact.sh" --type <type> --area <area>`.
   If it returns a destination with no exception noted, use it and stop.
2. **Unknown area:** ask which product owns the artifact. Never infer ownership from
   a checkout name, a repository name, or a filename alias — those are the three
   ways artifacts end up in the wrong area.
3. **Unknown type:** classify by *what the artifact is for*, not what it is made of.
   - Exploring options, nothing decided → the ideation lane.
   - A decision, scope, or approach the team will execute against → the plans lane.
   - A durable learning from work already done → the solutions lane.
   - A read-only bundle of someone else's source material → the references lane, one
     folder per source with a short README.
   - Something not yet relied on → the area's prototypes lane.
   If two classifications genuinely fit, prefer the **stronger** lane (the one with
   more review or more expectation of reuse) and say why.
4. **Registered exception:** the tool prints it. A `variance` means check the
   stronger lanes first; a `grandfathered` lane is extend-only — add to it, never
   expand its scope.
5. **New lane requested:** do not create one for work that fits an existing lane. A
   new lane is justified only when the work has a genuinely different consumer or
   lifecycle. If it is justified, register it: add the lane to the routing tool's
   `lane_for_type()`, regenerate the card with `--card`, and note it in the
   workspace README's team decisions.
6. **State the destination and the reason** before writing. One line is enough: the
   reason is what lets the next person route the same artifact the same way.

## Guardrails

- Never create loose files at the product-work root or at the workspace root.
- Never copy repository source, credentials, or authenticated exports into a docs
  lane. Reference them by path or binding token.
- Never route an output into the checkouts root or into `agentic-support/`.
- Regenerate the routing card (`--card`) in the same change as any lane or exception
  edit; a stale card is worse than no card.

## Output Shape

- The destination path.
- The artifact type and area used to resolve it.
- Any exception applied, and what it means for this artifact.
- If a new lane was created: the registration steps taken.

## Failure Handling

- **Area manifest missing:** the product-work lane has no `area-manifest.yaml`. Stop
  and run `tools/scaffold-product-area.sh` for the first area, or ask the steward.
- **Tool reports an unknown area:** treat as step 2 — ask, do not guess.
- **Tool reports an unknown type:** treat as step 3 — classify by purpose, then
  either use an existing lane or register a new one deliberately.
- **Destination exists but is owned by another practice:** stop and ask that
  practice's steward. Cross-lane writes are a coordination question, not a routing
  question.

## Harness Interpretation

Any capable harness produces the same destination for the same inputs, because the
decision is a table lookup plus a documented tie-breaker. This file is the source of
truth for the judgment cases.
