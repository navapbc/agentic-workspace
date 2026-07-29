---
workflow_id: notice-change-brief
version: 1
status: enabled
owner: Benefits Notices
source_of_truth: true
portable_across_harnesses: true
description: Draft a change brief for a proposed edit to a beneficiary notice, grounded in the BN product context.
argument-hint: "[notice ID, e.g. BN-072, and the proposed change]"
---

# Notice Change Brief

Use this skill when someone proposes changing the content or layout of a BN notice and
needs a reviewable brief before the change ships.

## Bindings

| Binding | Meaning | Resolution |
|---|---|---|
| `${AGENTIC_SUPPORT_ROOT}` | The support tree | The loaded support tree |
| `${AGENTIC_PRODUCT_WORK_ROOT}` | Shared product work | Descriptor, when declared; else an explicit caller input |

## Triggers

- "draft a change brief for BN-###"
- "we want to reword the renewal notice"

## Required Context

1. The workspace root `AGENTS.md`.
2. `product-work/benefits-notices/AGENTS.md` and the `product:benefits-notices` profile.
3. The current template set for the affected notice ID.
4. `reference:plain-language-standard`, checked against its own review window.

## Procedure

1. Confirm the notice ID (BN-###) and summarize the proposed change in one sentence.
2. Identify who is affected and any upstream dependency — check the profile's
   `eligibility-contract` repository, which is `reference` coverage: BN consumes the
   event shape and does not change it.
3. Check the proposed wording against the plain-language standard. Cite the specific rule.
4. Draft the brief and route it:
   `"${AGENTIC_SUPPORT_ROOT}/tools/route-artifact.sh" --type plan --area benefits-notices`.
   This area carries a registered variance; the tool prints it.

## Guardrails

- Never invent determination logic. Notices reflect upstream rules; they do not set them.
- Never reconstruct current notice text from memory — read the template set.
- Never renumber or reuse a notice ID.
- No credentials, no client-identifying data, no beneficiary data in the brief.

## Output Shape

A markdown brief with: Summary, Affected notices, Upstream dependency, Change detail,
Plain-language impact (with the cited rule), Accessibility impact, Rollback.

## Failure Handling

- Notice ID unknown or ambiguous: stop and ask. Do not infer it from a filename.
- Template set unavailable: produce the brief with the content section explicitly marked
  unverified, and say which template set is needed.
- Plain-language standard past its review window: treat it as unavailable, note the gap,
  and flag the wording for human review rather than asserting compliance.

## Harness Interpretation

Codex, Claude, OpenCode, and other harnesses produce the same brief shape. This file is
the source of truth for the procedure; an adapter that disagrees or is stale loses.
