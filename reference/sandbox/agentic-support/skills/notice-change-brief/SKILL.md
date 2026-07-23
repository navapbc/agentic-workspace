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

Use this skill when someone proposes changing the content or layout of a BN notice and needs a
reviewable brief before the change ships.

## Required Context
1. The workspace root `AGENTS.md`.
2. `product-work/benefits-notices/AGENTS.md` and the `product:benefits-notices` profile.
3. The current template set for the affected notice ID.

## Procedure
1. Confirm the notice ID (BN-###) and summarize the proposed change in one sentence.
2. Identify who is affected and any upstream dependency (check the profile's `eligibility-contract` repo).
3. Draft the brief: what changes, why, plain-language impact, accessibility impact, and rollback.
4. Save it to `product-work/benefits-notices/docs/plans/`.

## Guardrails
- Never invent determination logic; notices reflect upstream rules, they do not set them.
- No credentials, no client-identifying data.

## Output Shape
A markdown brief with: Summary, Affected notices, Upstream dependency, Change detail, Plain-language impact, Accessibility impact, Rollback.

## Harness Interpretation
Claude, Codex, OpenCode, and other harnesses produce the same brief shape. This file is the source of truth for the procedure.
