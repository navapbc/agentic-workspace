# Experiments log (R38)

What was tried, what was kept, and what was dropped. A dropped attempt is removed from the tree and recorded here instead, so the next person does not re-derive it. `tests/conventions.test.sh` (U11) fails on an abandoned attempt still sitting in the tree.

One entry per attempt. Keep it short: what was tried, what happened, and what the repository does now.

## Open design questions

- **Skills associated with a Bounded Context.** Whether and how a Bounded Context could name the skills relevant to its workflows without the framework turning into a skills solution. Context Fabric's standing rule is that operational skills are never reference resources. Not a v1 requirement; record findings here.

## Decisions taken during execution

### U1 -- `kit-final` tag not created

Row 0 offers `kit-final` only when no tag points at the kit head. `v0.2.0` points at `c4c0d19`, the kit head, so a second tag would add nothing. Recorded so row 0's proof is not read as a missed step.

### U1 -- kit history retained instead of a force-push

The baseline lands as a commit with an empty tree on top of the kit's history, rather than a force-push over it. History retention costs nothing here (the Desktop repository had no commits and no remote), and it keeps `v0.1.0` and `v0.2.0` reachable for anyone who adopted the kit.

### U1 -- what "scrub" means for `docs/plans/` and `docs/research/`

Those two trees were authored before the repository existed and would otherwise carry the maintainer's machine into history. The scrub replaces, and `tests/repo-baseline.test.sh` enforces the absence of:

- **Real machine paths** -- a home directory with a real account name, a Google Drive CloudStorage path, a harness attachment path, a scratch directory under `/tmp`. Replaced with angle-bracket placeholders (`<framework-repo>`, `<trial-workspace>`, `<shared-workspace>`, `<home>`, `<scratch>`).
- **Concrete secret references** -- an `op://` reference whose vault and item name a real vault, replaced with the placeholder grammar.
- **Personal identifiers** -- a real person's name or email address, replaced with the role (`the product owner`).

What deliberately **stays**, because removing it would break the work these documents describe:

- The `op://` scheme itself and its documented grammar (`op://<vault>/<item>/<field>`, `op://Example-Vault/...`). The Individual tier's whole secret contract is written in it.
- Denylist pattern literals (`/Users/`, `$HOME/`, `/Volumes/`, `file:///Users/`) and fictional path examples (`/Users/name/doc.yaml`). These are the shapes the validator must match; deleting them would delete the requirement.
- The maintainer's contact address in `CODE_OF_CONDUCT.md` and `SECURITY.md`, which is a published reporting channel, not an incidental identifier. Both files are outside the scrubbed trees.
- `joseoyolas/agentic-workspace-hawks-landing` in `docs/repurposing.md`, which is the fork a human has to act on. A checklist row that cannot name its target is not executable.

U6 adds the generic real-name patterns (`tests/lib/real-name-patterns.txt`) and the git-ignored exact list (`tests/local/real-names.txt`); `tests/repo-baseline.test.sh` already consumes the exact list when it is present.

### U1 -- `shellcheck` runs with `-x`

The Verification Contract names `shellcheck --severity=warning` and `--severity=style`. Every test script sources `tests/lib.sh`, and without `-x` shellcheck reports SC1091 ("not following") for each one at style severity. `-x` is added to the canonical invocation in `CONTRIBUTING.md` and the U11 workflow so the style run is meaningfully clean rather than clean-by-suppression.

### U1 -- two subshell bugs found by the tests, not by review

`tmp_repo_copy` and `assert_tree_unchanged` both registered their temp directories from inside a command substitution, so the global that held them was discarded with the subshell: the snapshot was never found and the copies were never cleaned up. Both now hang off one `_CE_TMP_ROOT` created when the library is sourced. Worth remembering when adding a helper to `tests/lib.sh`: **a helper whose result is captured with `$(...)` cannot mutate a global.**

### U1 -- the baseline test's leak scan is a denylist, not an allowlist

An earlier draft allowlisted the placeholder tokens that may follow `/Users/` or `op://`. That passes a real account name the moment someone adds a new placeholder spelling. The check now rejects any segment that *looks* like a real account or vault -- an ordinary identifier that is not an angle-bracket token, an ellipsis, or one of `name`, `x`, `user`, `you`, `vault`, `Example-Vault` -- and additionally rejects any email address, any `.codex/attachments/<uuid>` path, and any `/tmp/compound-engineering` scratch path. Proven by planting each shape in a throwaway copy and watching the test fail.
