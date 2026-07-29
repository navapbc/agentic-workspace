# Generated records

**Tool output. Never hand-edit anything in this directory** — the next regeneration
overwrites it, and an edited projection silently disagrees with the records it was
derived from.

| Path | Produced by | Regenerate when |
|---|---|---|
| `repo-digests/` | `tools/generate-repo-digests.sh` | after any checkout sync |
| `routing-card.md` | `tools/route-artifact.sh --card` | after any lane or area-exception change |

Each generated file carries `generated_at` and, where relevant,
`do_not_rely_after`. A file past that date is treated as unavailable, not as a
slightly-stale fact.
