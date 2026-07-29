# Benefits Notices -- Agent Instructions

Context Fabric profile: product:benefits-notices

Steward: Priya Anand (fictional)

## Boundaries

- Covers the content, layout, and delivery logic of BN notices. Does not cover eligibility rules — those live upstream in the Eligibility Platform.
- This is a strategy and documentation area, not a software codebase. Code lives in the machine-local checkouts root.

## Where things live

- Reusable procedures: `agentic-support/skills/`. Do not duplicate them here.
- Shared facts about BN's systems and repositories: resolve `product:benefits-notices`.
- Route outputs with `agentic-support/tools/route-artifact.sh --type <type> --area benefits-notices`. This area has a registered variance — the tool prints it.

## Local conventions

- Notice IDs BN-001..BN-140 are stable; never renumber. See `agentic-support/CONCEPTS.md`.
