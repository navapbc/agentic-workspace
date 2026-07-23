---
purpose: A fictional team standing up a shared agentic workspace end to end, across the three phases.
audience: PMs who want to see the kit used concretely before doing it themselves.
status: Active reference. Fictional example.
last_updated: 2026-07-22
---

# Walkthrough: The "Benefits Notices" Team Stands Up a Workspace

This is a fictional, generic example (no real client or program). It shows the kit used across Crawl, Walk, and Run so you can see the shape of the work before doing your own.

**The team:** Priya and Marcus, two Nava PMs, jointly own a product called *Benefits Notices* (BN). Priya uses Claude Code; Marcus uses Codex. They want their agents to share BN's context.

---

## Crawl — Priya stands up a workspace (day one, 30 minutes)

Priya runs the scaffold:

```bash
"/path/to/agentic-workspace-starter-kit/scripts/new-workspace.sh" --name "benefits-notices-workspace"
```

She edits the root `AGENTS.md` down to the essentials:

> Scope: Shared product workspace for Benefits Notices (BN), Nava-primary.
> - Product docs, research, and deliverables for BN live here.
> - No code checkouts, credentials, or client-identifying data in this workspace.
> - Client-sensitive material needs review before sharing outside the team.
> - Vocabulary: "notice" = an outbound beneficiary communication; "template set" = the versioned collection of notice layouts.

Because she uses Claude Code, the scaffold also created a `CLAUDE.md` that just says `@AGENTS.md`, so Claude Code reads the same instructions with nothing to keep in sync. She records the couple of durable facts that matter (the upstream systems BN reads from) directly in the root `AGENTS.md` vocabulary section, keeping it short.

**Result:** When Priya opens Claude Code in the workspace, it already knows what BN is, the boundaries, and the vocabulary. No dependencies were installed. This took half an hour and is useful immediately.

---

## Walk — Marcus joins and they share procedures (later that week)

Marcus needs in, and they keep repeating the same "draft a notice-change brief" procedure by hand.

1. **Share it.** They put the workspace in a shared Google Drive folder (Crawl-phase default; low friction). Marcus syncs it and points Codex at the root `AGENTS.md`.
2. **Stand up the support layer.** Priya runs the scaffold again with `--with-support`, or copies `templates/skills/` and `templates/context-fabric/` into a new `agentic-support/` folder.
3. **Write the first skill.** They turn the brief procedure into `agentic-support/skills/notice-change-brief/SKILL.md` from the example template: triggers, required context, the steps, the output shape, guardrails. They register it in `skill-manifest.yaml`.
4. **Sync.** Each of them runs `./sync-skills.sh --target all` once, so Claude Code and Codex both have the skill. Now Marcus on Codex and Priya on Claude Code run the *same* procedure and get the *same* brief.
5. **First Context Fabric profile.** BN reads from an upstream "Eligibility" system and lives in two repos. They create a `system:eligibility` record, two `repository:` records, and a `product:benefits-notices` profile that references them with tiers and `useWhen` triggers. They add `Context Fabric profile: product:benefits-notices` to the workspace's product-area `AGENTS.md`.
6. **Split the lanes.** Briefs the team relies on go in `product-work/benefits-notices/`; a throwaway notice-layout mockup goes in `prototyping/`.

**Result:** Two PMs, two different tools, one shared context and one shared procedure. The brief procedure now compounds instead of living in Priya's head.

---

## Run — the workspace grows to three products (the next quarter)

BN succeeds; the team now also owns *Appeals Status* and *Address Update*, and a third PM joins.

1. **More profiles.** Each new product gets its own `product:` profile. The shared "Eligibility" system record is reused, not recopied.
2. **Validation in the loop.** They move the `agentic-support/` layer into git and run `validate-workspace.sh` in CI. It catches a stray absolute path and a `.DS_Store` before either is shared.
3. **Ownership (the team's choice).** With three products, they decide it's worth naming an owner each: Priya on BN, Marcus on Appeals Status, the new PM on Address Update. A short table lists them, and for BN's higher-stakes notice language they agree a peer looks it over before it ships. Address Update, lower-stakes, skips the review step.
4. **Ship incrementally with `status`.** They sketch an "onboarding" skill but haven't finished it, so they mark it `paused` in the manifest. It's visible as intent without pretending to be done.
5. **Persona review for high-stakes work.** For a sensitive notice-language change, they have an agent critique the draft from a few role angles (plain-language, accessibility, policy-accuracy) before a human reviewer signs off.

**Result:** A versioned, validated, three-product operating system. A fourth PM can be onboarded by pointing them at the workspace and running the onboarding skill. Context and procedures are shared assets, independent of anyone's tool or model.

---

## What to copy from this

- Start tiny. One thin `AGENTS.md` and a couple of docs lanes are genuinely useful on day one.
- Add a skill the second time you repeat a procedure, not before.
- Add a Context Fabric profile when "which system/repo?" keeps coming up.
- Reuse system and repo records across products; never recopy them.
- Choose one sharing mechanism per phase and finish it.
- Use `status: paused` to show intent without faking completion.
