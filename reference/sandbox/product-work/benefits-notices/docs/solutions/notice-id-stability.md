---
title: Notice IDs are stable identifiers; never renumber
category: conventions
problem_type: convention
applies_when:
  - adding a new notice
  - tempted to renumber or reuse a retired notice ID
tags: [notice-id, stable-identifiers, analytics]
last_updated: 2026-07-29
---

# Notice IDs are stable identifiers; never renumber

Fictional example learning. Shows what belongs in a `docs/solutions/` lane.

## Context
Notice IDs (BN-001..BN-140) are referenced by the notice service, the analytics pipeline,
and support macros. None of the three learns about a renumber.

## Guidance
To add a notice, allocate the next unused BN-### and record it. Never reuse a retired ID
and never renumber an existing one.

## Why this matters
The ID is a contract across three systems owned by three different teams. A renumber is
cheap in the template set and expensive everywhere it is read.
