---
purpose: The phased adoption path for a shared agentic workspace. Crawl / Walk / Run, with entry criteria, what to build, and exit signals.
audience: PMs deciding how far to take agentic support for their product team.
status: Active.
last_updated: 2026-07-22
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

1. **Stand up the support layer.** Create the support folder (e.g. `agentic-support/`) with `skills/` and `context-fabric/`. Copy from `templates/skills/` and `templates/context-fabric/`.
2. **Write your first skill.** Take a procedure you repeat and turn it into `skills/<name>/SKILL.md` from `templates/skills/example-skill/SKILL.md`. Register it in `skill-manifest.yaml`.
3. **Set up sync.** Copy `templates/skills/sync-skills.sh`. Each teammate runs it to mirror skills into their tool. Run it with `--check` to detect drift.
4. **Write your first Context Fabric profile.** For each product area, create a `product:<slug>` profile from `templates/context-fabric/profile.template.json`, and the `system:` / `repository:` records it references. Declare the profile in the product area's `AGENTS.md`.
5. **Share the workspace.** Pick git or Google Drive (see [collaboration-and-governance.md](collaboration-and-governance.md)). Each teammate does [local-setup.md](local-setup.md) once.
6. **Split the lanes.** Separate shared product work from prototyping.

**You now have:** a team that shares context and procedures across different tools and machines. Procedures compound instead of living in one person's head.

**Dependencies:** the harness config for each tool, plus `yq`/`jq` if you validate Context Fabric records. See [local-setup.md](local-setup.md).

**Exit signal → Run:** several product areas, several PMs, and enough churn that you need validation and clear stewardship to keep it from drifting.

---

## Run — a durable multi-product operating system

**Enter when:** the workspace supports multiple products and PMs, and drift or ambiguity is starting to cost you.

**Build:**

1. **Complete the support layer:** `tools/` for approved mechanics, `validation/` for invariants, `docs/architecture.md` for your specific setup.
2. **Adopt validation in your loop.** Run `scripts/validate-workspace.sh` after structural changes and, if git-backed, in CI.
3. **Formalize ownership if it helps.** For a larger multi-product team, name an owner per product area (in the profile's `maintainers` and an optional summary table) and decide whether product-work artifacts get a review before the team relies on them. Keep it as light as the team will actually follow. See [collaboration-and-governance.md](collaboration-and-governance.md).
4. **Use the `status` field to ship incrementally.** Mark unfinished skills `paused` so the structure is complete and visible while the machinery matures.
5. **Optionally, add review personas** where domain correctness matters — an agent critiques high-stakes work from a few role angles before a human signs off.
6. **Decide the target sharing state deliberately.** For a durable multi-product system, git-backed support layer with drift checks is usually right; product-work lanes can stay on Drive if your PMs prefer it.

**You now have:** a versioned, validated, multi-product operating system that new PMs can onboard into with a named workflow, and that stays consistent as it grows.

**Dependencies:** git (if git-backed), the full CLI toolchain (`jq`, `yq`, `rg`, `fd`), and Node only if you run the Context Fabric selector/validator. See [local-setup.md](local-setup.md).

---

## Anti-patterns (how these efforts fail)

- **Building Run on day one.** Schema, selector scripts, and CI before you have a single product profile in use. Start at Crawl.
- **Fat `AGENTS.md` files.** Copying procedures and facts into every folder. They drift immediately. Reference, don't repeat.
- **Two sources of truth.** A "moved" pointer and an "active" copy of the same context. Pick one home (the support layer) and make everything else a labeled pointer.
- **Both sharing mechanisms half-wired.** Git and Drive both partly set up. Choose one per phase and finish it.
- **Skills that fork per tool.** Editing the tool-specific adapter instead of the `SKILL.md`. The adapter is a pointer; the procedure has one home.
