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

### U1 -- the review found the skip ledger missing, and it mattered

An adversarial review of the baseline caught the unit's own central invariant being violated by the unit's own test. `tests/local/` is git-ignored, so the exact real-name screening list can never exist in a CI checkout; the test's absent-file branch printed a note and let the script run to the end, which exits 0. The one personal-identifier control was permanently skipped behind a green check.

The fix is a skip ledger in `tests/lib.sh`: `note_skip` records a skipped stage and keeps going, and `finish` -- now the last line of every test script -- exits 3 when the ledger is non-empty. `skip` still exits 3 immediately for a script that cannot run at all. **The lesson generalizes: a test script that can skip one stage and keep running needs a deferred-skip primitive, or the exit taxonomy is honored only by the author's memory.**

`tests/lib/real-name-patterns.txt` is now committed with generic EREs, so the screening stage runs in CI instead of only reporting a skip. The exact list stays git-ignored and U6-owned, so CI will keep reporting exit 3 for that one stage; that matches the Definition of Done's "at most the not-validated warning annotation", with the maintainer's pre-push run as the real gate.

### U1 -- what a leak scan has to enumerate

Four more holes in the same scan, each confirmed by planting the shape:

- It scanned two **directory names**, with `grep`'s stderr discarded. A renamed or emptied tree produced zero matches and the scan printed the positive claim. It now enumerates with `git ls-files -co --exclude-standard` and fails when the enumeration is empty. That also fixes symlinked content, which `grep -r` does not traverse.
- It knew only `/Users/`, while the `AGENTS.md` check ten lines above already knew `/Users/`, `/home/`, `/Volumes/` and `~/`. One file, two definitions of a machine path. The roots now match.
- The empty segment was allowlisted, so a **line-wrapped** real path -- `/Users/` at the end of one line, the account name at the start of the next -- read as a placeholder. A bare root at end of line is now a leak in its own right.
- Every check was a byte-level ASCII match, so a UTF-16 document was scanned clean with the path and the email plainly readable in it. Unscannable encoding is now a failure, not a pass.

A note on a false start: a `~/` and `$HOME/` segment scan was written and then removed. A home-relative path *cannot* carry an account name -- that is what the tilde replaces -- so it only fired on `~/.claude`, `~/.config`, `~/Dropbox` and friends. The real risk in that shape is a Drive path carrying an account email, which the `GoogleDrive-` and email checks already cover.

The committed pattern list also cannot contain a shape these documents legitimately specify. `-----BEGIN ... PRIVATE KEY-----` was in the first draft and matched the plan's own denylist specification. A banner a spec quotes verbatim belongs in the document denylist (U3), not in the screening list for the documents that describe it.

### U1 -- the human-only guard was defeated by ordinary spellings

The check matched six fixed strings against `find . -name '*.sh'`. `git -C "$d" push` (a flag between the words), a file named `publish` with no extension, and `gh release create` -- the human action row 5 reserves for the product owner -- all passed. It now selects files by extension **or shebang** from `git ls-files -co`, and matches whitespace-tolerant extended regexes covering push, release create/delete/edit/upload, repo create/edit/rename/archive/transfer/delete, and `gh api` with a mutating method. `docs/repurposing.md` was reworded to describe the same set, so the prose and the check agree.

### U1 -- `assert_tree_unchanged` was comparing names, not bytes

The digest was built from `rev-parse HEAD`, `status --porcelain` and `diff --cached --name-status`: three name-and-status views with no content in any of them. Two mutations passed. Rewriting a file that was **already dirty** at snapshot time left its status letter unchanged, and the reviewed tree was itself dirty in three files, so that was the live case. And any write under a git-ignored path was invisible -- which points straight at `tests/local/real-names.txt` and `documents/**/individual/*.yaml`, the two trees the framework most wants a test run never to touch. The digest now carries `diff HEAD --binary`, the index diff, hashes of untracked files, and hashes of those two ignored trees. `tests/run.test.sh` asserts both mutations are caught.

### U1 -- `repo_root` looped forever instead of exiting 2

`dirname` of a relative path bottoms out at `.` and stays there, so the ascent's `while [ "$dir" != "/" ]` never terminated and the `usage_error` below it was unreachable. A hang is outside the 0/1/2/3 taxonomy entirely: a wrapper sees a timeout, not a verdict. The function now absolutizes first and stops at a fixed point.

`tests/run.sh` had a related split: `HERE` came from `BASH_SOURCE` and `ROOT` from `$PWD`, so it could discover one checkout's tests and assert another's tree. It now anchors `CE_REPO_ROOT` to its own parent and refuses (exit 2) when the two disagree -- which `tests/run.test.sh` exercises, and which is why that test must clear `CE_REPO_ROOT` before invoking a runner inside a temp copy.

Two more gaps surfaced while verifying those fixes, both from planting the shape rather than reading the code: `git ls-files -c` lists a tracked path whether or not it still exists, so a **moved or deleted** document was silently dropped from the scan instead of failing it; and `grep` is line-based, so a **backslash continuation** (`git \` / `  push --force`) slipped every human-only pattern. The scan now fails on a tracked-but-absent file, and joins continuations with `awk` before matching.
