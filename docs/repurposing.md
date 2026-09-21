# Repurposing checklist (human-only)

`navapbc/agentic-workspace` used to hold the Agentic Workspace Starter Kit. This framework takes over that repository. The steps below are the ones **no agent and no script may perform**: they change repository visibility, push history for the first time, cut a Release, or invite a collaborator.

## How to run this

- Execute the rows **top to bottom**. Stop at the first gate that does not hold or the first proof that does not come back as written.
- Fill in the Proof cell's result and the date as you go. A row is not closed until its proof is recorded here.
- **Rows 0-4 close before U2 opens.** OpenSpec is the first thing that writes framework-shaped content, and it should not do that while the remote is public or while there is no remote at all.
- Row 5 follows U7. Row 6 follows U13.
- Nothing in this repository automates these. `tests/repo-baseline.test.sh` asserts that no committed script calls `gh repo edit`, `git push`, `gh repo delete`, or `gh release delete`.

## Status

| # | Closed on | Result recorded by |
|---|---|---|
| 0 | | |
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |
| 6 | | |

## The rows

| # | Gate | Human action | Proof | Rollback |
|---|---|---|---|---|
| 0 | Local repo shows kit history, the empty-tree commit, then the baseline; `tests/run.sh` is green | Tag the kit head `kit-final` if no tag already points at it | `git tag --points-at c4c0d19` lists at least one tag. As shipped it lists `v0.2.0`, which already points at the kit head, so no new tag is needed | None needed: tagging adds a ref and removes nothing |
| 1 | None; this is the information-gathering row | Ask a `navapbc` org owner for: the plan tier; whether members may change repository visibility; whether Actions run on private repositories and which actions are allowed; whether secret-scanning push protection applies; and the org's default member repository permission. If that default is broader than read, set this repository's base access to read with named write collaborators. Run a one-time read-only `gitleaks detect` over the kit's history and record the outcome. Set `OPENSPEC_TELEMETRY=0`, `OPENSPEC_NO_UPDATE_CHECK=1`, `OPENWIKI_TELEMETRY_DISABLED=1`, and `DO_NOT_TRACK=1` in the maintainer's shell profile | Every answer and the `gitleaks` outcome written into the Notes section below, each with its date | None needed: this row only records answers and sets local environment variables |
| 2 | The fork's settings offer a visibility change. If GitHub refuses because the repository is a fork, either leave the fork network first (irreversible, and acceptable because upstream is being retired) or swap this row with row 3, because privatizing upstream detaches the fork automatically | Set `joseoyolas/agentic-workspace-hawks-landing` private | `gh repo view joseoyolas/agentic-workspace-hawks-landing --json visibility` reports `PRIVATE` | Set it public again (reversible). Leaving the fork network is **not** reversible |
| 3 | Row 2's proof holds; nothing framework-shaped has reached the remote | Set `navapbc/agentic-workspace` private (R39) and verify upstream shows zero public forks | `gh repo view navapbc/agentic-workspace --json visibility` reports `PRIVATE`; `gh repo view navapbc/agentic-workspace --json forkCount` reports `0` public forks | Set it public again -- only while row 4 has not run |
| 4 | Row 3's proof holds; local `main` fast-forwards remote `main`; the probe workflow file is present | Add `origin`, then push `main` and the tags for the first time | Remote log shows the kit history, the empty-tree commit, and the baseline commits; `v0.1.0` and `v0.2.0` are listed; the probe workflow run completed, or "Actions disabled" is recorded against row 1 | Forward-only: revert and push. Never force-push this branch |
| 5 | U7 is pushed; `release.sh` without `--publish` printed the command it would run; the changelog section for release 1 exists | Run the first `gh release create <document-id>@1 --notes-file <section>` under the product owner's own identity | `gh release view <document-id>@1` notes equal the changelog section byte for byte; `git ls-remote --tags` lists the tag | Never delete or renumber a release: mark the section `[YANKED]` and cut release 2 |
| 6 | U13 is complete; the rehearsal colleague is named | Invite the colleague as a read-only collaborator for the onboarding dress rehearsal | The colleague can open and clone the repository, and reports reaching a validated Org view from `START-HERE.md` in one fresh session | Remove the collaborator |

## Notes

Record row 1's answers here, each with its date.

- Plan tier:
- Members may change visibility:
- Actions on private repositories (and the allowed-actions policy):
- Secret-scanning push protection:
- Default member repository permission (and what this repository's base access was set to):
- `gitleaks detect` over kit history:
- Telemetry variables set in the maintainer's shell profile:
