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
- `joseoyolas/agentic-workspace-hawks-landing` in `docs/repurposing.md`, which is the fork a human has to act on. A checklist row that cannot name its target is not executable.

U6 adds the generic real-name patterns (`tests/lib/real-name-patterns.txt`) and the git-ignored exact list (`tests/local/real-names.txt`); `tests/repo-baseline.test.sh` already consumes the exact list when it is present.

### U1 -- `shellcheck` runs with `-x`

The Verification Contract names `shellcheck --severity=warning` and `--severity=style`. Every test script sources `tests/lib.sh`, and without `-x` shellcheck reports SC1091 ("not following") for each one at style severity. `-x` is added to the canonical invocation in `CONTRIBUTING.md` and the U11 workflow so the style run is meaningfully clean rather than clean-by-suppression.

### U1 -- two subshell bugs found by the tests, not by review

`tmp_repo_copy` and `assert_tree_unchanged` both registered their temp directories from inside a command substitution, so the global that held them was discarded with the subshell: the snapshot was never found and the copies were never cleaned up. Both now hang off one `_CE_TMP_ROOT` created when the library is sourced. Worth remembering when adding a helper to `tests/lib.sh`: **a helper whose result is captured with `$(...)` cannot mutate a global.**

### U1 -- the baseline test's leak scan is a denylist, not an allowlist

An earlier draft allowlisted the placeholder tokens that may follow `/Users/` or `op://`. That passes a real account name the moment someone adds a new placeholder spelling. The check now rejects any segment that *looks* like a real account or vault -- an ordinary identifier that is not an angle-bracket token, an ellipsis, or one of `name`, `x`, `user`, `you`, `vault`, `Example-Vault` -- and additionally rejects any email address, any harness attachment path carrying a real id, and any agent scratch path under the system temp directory. Proven by planting each shape in a throwaway copy and watching the test fail.

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

### 2026-09-25 -- public, Apache-2.0, and the planning documents stay out

Two product decisions, taken before the first push.

**The repository stays public, under Apache-2.0.** The original plan (R39) made `navapbc/agentic-workspace` private before any framework content reached it. Public visibility is what lets a Nava program read the framework without an access request, and on GitHub's Free plan it is also the only way to get a set of controls a private repo would not have had at all: branch protection on `main`, secret scanning with push protection, code scanning, private vulnerability reporting, and unmetered Actions minutes. The license carried over from the starter kit unchanged, so the kit's history and the framework are under the same terms and there is no seam at the empty-tree commit. The fork `joseoyolas/agentic-workspace-hawks-landing` stays public and stays in the fork network, so the irreversible "Leave fork network" action is never needed.

A licensing detour is recorded here because the reasoning is worth keeping: for one revision the repository was public with `LICENSE` and `CODE_OF_CONDUCT.md` removed and `NOTICE` asserting that no rights were granted. That is a coherent position -- source-available, not open source -- but it is strictly more restrictive than the kit it succeeds, and "decide later" was not available: leaving the kit's `LICENSE` in place ships Apache-2.0 by default, and removing it ships all-rights-reserved. The decision was to keep Apache-2.0. **Public plus Apache-2.0 means this repository is open source in substance already.** What stays deferred is promotion and external contribution intake, not the license.

The one deviation from carrying the community files over verbatim: the Contributor Covenant's reporting contact is a non-personal channel rather than the maintainer's address. Every root Markdown file is screened for email addresses, and re-publishing a personal address on a new public repository when an internal route exists is a step backwards.

**The planning and research documents are not committed.** They carry the program and system detail the framework deliberately does not: the trial's reachability findings, internal system names, and the program vocabulary. A scrub is the wrong control for that on a public repository, because the judgement about what counts as internal has to be made per sentence and gets it wrong once. Absence is the control. `docs/plans/` and `docs/research/` are git-ignored and live in the maintainer's local tree.

**The part worth remembering:** untracking was not enough. Those 18 files had already landed in one commit, and a commit reachable from `HEAD` publishes on push whether or not the files are in the working tree. The branch was rebuilt to drop that commit before anything was pushed, and the backup tag that still carried it was deleted. `tests/repo-baseline.test.sh` now asserts both conditions -- nothing tracked, and nothing reachable from `HEAD` -- because only the second one survives a `git rm --cached`.

The leak screening that would have run over those two trees now runs over the prose the repository does publish, and it earned its place immediately: it caught an agent scratch path under the system temp directory that had reached this very file.

### 2026-09-25 -- two gaps found by reading the contract, not by running it

Both surfaced from questions about how the tiers evolve, before any of the mechanics were built. Recording them because in each case the *absence* was invisible: nothing failed, no test was red, and the contract read as complete.

**A schema migration that only migrates what it can see.** Bumping a field contract was defined as one change touching the schema, the rendered template, the renderer, the view contract, every shipped example and golden view, and a changelog note -- every artifact *inside this repository*. But real documents live in a practitioner's own documents root, outside it. Their document would simply stop validating, and they would hand-edit it against a changelog note. Fine for one maintainer; a real cost the moment a second program adopts the framework, which is the stated success criterion.

The fix is that a contract version which changes a tier's shape must ship `schemas/<tier>/<n>/migration.jq`, taking a document from `n-1` to `n`, composed in sequence so a document two contracts behind passes through every intermediate step. `framework.json` records the oldest contract the chain can still carry forward, so a document beyond it is told so plainly instead of failing part-way.

Two decisions inside that are worth keeping. First, **a migration bumps the release like any other content change.** Carving an exception was tempting -- a migration changes shape, not facts -- but the validator already warns when content changes without a bump and generation treats that warning as blocking, so an exception would need a second rule about which content changes count, and dependents would regenerate from a changed shape with no recorded reason. Second, **the guard ships before the first migration does.** The test that asserts every contract above 1 carries its step passes vacuously today over an empty set. Written after the first bump, it would have been written in response to forgetting.

**A private tier that could detect a problem but not fix one.** The Individual tier binds a person's machine to documents above it, and the trust boundary makes it read-only to everything upstream -- no generator, no release, nothing writes into it. That is what guarantees a practitioner's customizations cannot be clobbered by an update, and it is the right property.

The cost was that it had no way to *respond* to one either. An upstream rename would orphan a binding, raise a non-blocking warning, and stop. The tier above it has a script that shows the upstream's changelog between two releases and re-records the observed one; this tier had nothing, and no finding distinguished "this system was renamed" from "this system is gone", even though the data to tell them apart was already being recorded.

The fix keeps the boundary and closes the gap: a reconciler that **reports by default and writes only when asked**, whose write set is closed to three things -- a binding's reference, its secret-reference *keys*, and its recorded release. Every root, every harness preference, every location override, and every secret reference *value* is asserted byte-identical across a run by the unit's own test, rather than left alone by construction. A target that was renamed is re-pointed through the recorded previous identifiers; a target that is simply gone is reported and left alone, because guessing which system replaced it is exactly the judgement a script must not make.

**What generalizes:** both gaps were in the same place -- the seam where something the repository owns meets something it does not. The contract was complete for everything inside the boundary and silent about everything outside it. Worth checking every other mechanism against the same question.
