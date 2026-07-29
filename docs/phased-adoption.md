---
purpose: The phased adoption path for a shared agentic workspace. Crawl / Walk / Run, with entry criteria, what to build, and exit signals.
audience: PMs deciding how far to take agentic support for their product team.
status: Active.
last_updated: 2026-07-29
---

# Phased Adoption

**Start at Crawl. Move up only when you feel the specific pain the next phase removes.** Building Run-phase machinery on day one is the most common way these efforts stall. Each phase is independently useful; you can stop at any of them.

The three phases map onto Nava's AI-strategy maturity horizons (pilot → repeatable patterns → scaling), so the broader transformation effort can see where each team stands.

| Phase | You have | Effort to enter | Nava strategy horizon |
|---|---|---|---|
| **Crawl** | One workspace, thin `AGENTS.md`, a few docs lanes | ~30 min | Phase 1 — pilot-level shift |
| **Walk** | Shared skills + first Context Fabric profiles, shared with teammates | ~half a day | Phase 2 — repeatable patterns |
| **Run** | Full support layer, multi-product catalog, validation, stewardship | Ongoing | Phase 3 — scaling and system effects |

---

## Crawl — one workspace with shared context

**Enter when:** you use an agent for product work and are tired of re-explaining context.

**Build:**

1. Run `scripts/new-workspace.sh --name "<workspace>"` (or copy `templates/workspace/`).
2. Fill in the root `AGENTS.md`: what this workspace is, what does not belong, your product vocabulary, and any hard boundaries (for example, "never paste credentials," "client-sensitive material needs review before sharing"). Keep it thin.
3. If anyone uses Claude Code, add a `CLAUDE.md` containing just `@AGENTS.md` (the scaffold does this for the root). Nothing to keep in sync.
4. Use docs lanes as you work. The scaffold starts you with `docs/ideation/`, `docs/plans/`, `docs/solutions/`; rename, drop, or add lanes to fit your team (see the workspace `docs/README.md`). Just keep each lane meaning the same thing to everyone.

(Carrying context across sessions is deliberately out of scope in this version; see architecture §6. Don't stand up an auto-loaded prompt log.)

**You now have:** an agent that knows your product's boundaries and vocabulary every session, on any tool, with zero re-explaining. This is real value on day one.

**Dependencies:** essentially none. A text editor and your agent tool. See [local-setup.md](local-setup.md).

**Exit signal → Walk:** more than one PM needs the same context, **or** you keep repeating the same multi-step procedure by hand, **or** "which system/repo does this product touch?" keeps coming up.

---

## Walk — shared, reusable, multi-person

**Enter when:** a second PM joins, or a procedure is worth writing down once.

**Build:**

1. **Install the support engine.** `./scripts/install-support.sh <workspace>` (run `--check` first to see what it would do). You get `skills/`, `context-fabric/`, `tools/`, `validation/`, and the doctrine docs whole — you do not build them. Then author your two files: `CONCEPTS.md` and `docs/context-source-ladder.md`.
2. **Declare your roots and check.** Ask your agent to run the `workspace-setup` skill; it interviews you for your roots, configures your harness, writes the machine-local declaration, and runs `tools/workspace-doctor.sh` until it is green. Every teammate does this once, on their own machine.
3. **Write your first skill.** Take a procedure you repeat and turn it into `skills/<id>/SKILL.md` from `skills/example-skill/SKILL.md`. Register it in `skill-manifest.yaml` in the same change.
4. **Set up skill sync.** Each teammate runs `skills/sync-skills.sh` to mirror skills into their harness. `--check` detects drift.
5. **Write your first Context Fabric profile.** For each product area, create a `product:<slug>` profile from `context-fabric/templates/profile.template.json`, plus the `system:` / `repository:` records it references. Declare the profile in the area's `AGENTS.md`.
6. **Share the workspace.** Pick git or synced storage (see [collaboration-and-governance.md](collaboration-and-governance.md)) and write the choice down. Each teammate does [local-setup.md](local-setup.md) once.
7. **Split the lanes.** Separate shared product work from prototyping.

**You now have:** a team that shares context and procedures across different tools and machines, and a session-start probe that tells each member what their session can actually do. Procedures compound instead of living in one person's head.

**Dependencies:** the harness config for each tool, plus `jq` for record validation. `git` only if you hydrate checkouts. See [local-setup.md](local-setup.md).

**Exit signal → Run:** several product areas, several PMs, and enough churn that you need validation and clear stewardship to keep it from drifting.

---

## Run — a durable multi-product operating system

**Enter when:** the workspace supports multiple products and PMs, and drift or ambiguity is starting to cost you.

**Build:**

1. **Turn on the rest of the engine.** Generate repo digests (`tools/generate-repo-digests.sh`) so repository questions stop needing checkouts. Register product areas with `tools/scaffold-product-area.sh` and regenerate the routing card (`tools/route-artifact.sh --card`). Author sync manifests for the repositories your products actually need.
2. **Adopt the gate in your loop.** Run `agentic-support/validation/check-workspace.sh` after structural changes and, if git-backed, in CI. It is stricter than the Crawl-phase `scripts/validate-workspace.sh` and is the authority once the engine exists.
3. **Formalize ownership if it helps.** For a larger multi-product team, name an owner per product area (in the profile's `maintainers` and an optional summary table) and decide whether product-work artifacts get a review before the team relies on them. Keep it as light as the team will actually follow. See [collaboration-and-governance.md](collaboration-and-governance.md).
4. **Use the `status` field to ship incrementally.** Mark unfinished skills `paused` so the structure is complete and visible while the machinery matures.
5. **Optionally, add review personas** where domain correctness matters — an agent critiques high-stakes work from a few role angles before a human signs off.
6. **Record learnings as they happen.** Write each durable finding to `agentic-support/docs/solutions/<category>/<slug>.md` and each new term to `CONCEPTS.md`. This is the lane that makes the workspace get better rather than merely bigger, and it costs nothing per session because it is load-on-demand.
7. **Decide the target sharing state deliberately.** For a durable multi-product system, a git-backed support layer with CI drift checks is usually right; product-work lanes can stay on synced storage if your team prefers it.

**You now have:** a versioned, validated, multi-product operating system that new members onboard into with one named workflow, that reports its own health at session start, and that stays consistent as it grows.

**Dependencies:** `jq` (required), `git` (for checkouts and digests), and optionally `rg`/`fd`/`shellcheck` — the tools use them when present and fall back to POSIX equivalents when not. See [local-setup.md](local-setup.md).

---

## Anti-patterns (how these efforts fail)

- **Building Run on day one.** Schema, selector scripts, and CI before you have a single product profile in use. Start at Crawl.
- **Fat `AGENTS.md` files.** Copying procedures and facts into every folder. They drift immediately. Reference, don't repeat.
- **Two sources of truth.** A "moved" pointer and an "active" copy of the same context. Pick one home (the support layer) and make everything else a labeled pointer.
- **Both sharing mechanisms half-wired.** Git and synced storage both partly set up. Choose one per phase and finish it.
- **Skills that fork per tool.** Editing the tool-specific adapter instead of the `SKILL.md`. The adapter is a pointer; the procedure has one home.
- **Assembling one root out of symlinks.** It looks tidier and it breaks silently: harness file viewers do not show symlinked folders' contents, so the workspace vanishes from the UI while every script still passes. Hand the harness real directories.
- **Tools that guess machine paths.** A fallback to `$HOME` or a sibling directory works on the author's machine and is quietly wrong on everyone else's. Declare roots; fail closed when the declaration is missing.
- **A shared folder as your session's primary folder.** Your harness writes personal settings there and sync hands them to the whole team — repeatedly, because the next session recreates the file.
