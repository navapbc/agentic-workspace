#!/usr/bin/env bash
# U1 -- the repository baseline. Smoke-level, as the unit's execution note asks:
# it proves the repurposing actually happened and that the invariants a later unit
# depends on are true from the first commit.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/lib.sh
. "$HERE/lib.sh"

ROOT="$(repo_root)"
cd "$ROOT"

EMPTY_TREE="$(git hash-object -t tree /dev/null)"

# --- history -----------------------------------------------------------------

empty_tree_commits=()
while IFS= read -r c; do
  [ "$(git rev-parse "$c^{tree}")" = "$EMPTY_TREE" ] && empty_tree_commits+=("$c")
done < <(git rev-list HEAD)

[ "${#empty_tree_commits[@]}" -eq 1 ] || \
  fail "expected exactly one commit with an empty tree, found ${#empty_tree_commits[@]}"
WIPE="${empty_tree_commits[0]}"
pass "one commit with an empty tree: $(git log -1 --format=%h "$WIPE")"

KIT_HEAD="$(git rev-parse "$WIPE^")"
[ "$(git rev-list --count "$KIT_HEAD")" -ge 2 ] || \
  fail "the empty-tree commit does not sit on the kit's history"
[ "$(git rev-list --count "$KIT_HEAD")" -ge 5 ] || \
  fail "kit history looks truncated: only $(git rev-list --count "$KIT_HEAD") commits below the wipe"
pass "kit history retained: $(git rev-list --count "$KIT_HEAD") commits below the wipe"

[ "$(git rev-list --count "$WIPE..HEAD")" -ge 1 ] || \
  fail "no baseline commit after the empty-tree commit"
pass "baseline commits after the wipe: $(git rev-list --count "$WIPE..HEAD")"

for t in v0.1.0 v0.2.0; do
  git rev-parse -q --verify "refs/tags/$t" >/dev/null || fail "tag $t is missing"
done
pass "kit tags present: v0.1.0, v0.2.0"

[ -n "$(git tag --points-at "$KIT_HEAD")" ] || \
  fail "no tag points at the kit head $KIT_HEAD; row 0 of docs/repurposing.md needs kit-final"
pass "a tag points at the kit head: $(git tag --points-at "$KIT_HEAD" | tr '\n' ' ')"

# --- the kit's tree is gone ---------------------------------------------------

for gone in scripts/new-workspace.sh scripts/install-support.sh templates/support reference llms.txt; do
  [ -e "$gone" ] && fail "kit artifact survived the wipe: $gone"
done
pass "kit artifacts are absent from the working tree"

kit_workflows="$(git ls-tree --name-only "$KIT_HEAD" .github/workflows/ | wc -l | tr -d ' ')"
[ "$kit_workflows" -gt 0 ] || fail "the kit had no workflows, so this check proves nothing"
[ "$(git ls-tree --name-only "$WIPE" -- .github 2>/dev/null | wc -l | tr -d ' ')" -eq 0 ] || \
  fail ".github/ survived the deletion commit"
workflows="$(find .github/workflows -maxdepth 1 -name '*.yml' -o -maxdepth 1 -name '*.yaml' 2>/dev/null | sort)"
[ "$workflows" = ".github/workflows/check.yml" ] || \
  fail "expected only .github/workflows/check.yml after the wipe, found: ${workflows:-none}"
pass "the kit's $kit_workflows workflow file(s) are gone; only check.yml remains"

# --- baseline files -----------------------------------------------------------

for f in AGENTS.md CLAUDE.md README.md START-HERE.md CHANGELOG.md LICENSE NOTICE \
         SECURITY.md CONTRIBUTING.md CODE_OF_CONDUCT.md .gitignore .gitattributes \
         framework.json docs/repurposing.md docs/experiments/README.md \
         tests/lib.sh tests/run.sh .github/workflows/check.yml; do
  [ -f "$f" ] || fail "baseline file missing: $f"
done
pass "every baseline file is present"

[ -L CLAUDE.md ] && fail "CLAUDE.md is a symlink; it must be a real file"
grep -qx '@AGENTS.md' CLAUDE.md || fail "CLAUDE.md does not import AGENTS.md with a bare @AGENTS.md line"
pass "CLAUDE.md is a real file importing AGENTS.md"

command -v jq >/dev/null 2>&1 || usage_error "jq is required for the framework.json checks"
jq -e . framework.json >/dev/null || fail "framework.json is not valid JSON"
for key in .version .contracts.org '.contracts["bounded-context"]' .contracts.individual \
           .contracts.view .tools.yq .tools.jq .tools.openspec .tools.openwiki \
           .lookup.individual_env; do
  jq -e "$key" framework.json >/dev/null || fail "framework.json is missing $key"
done
pass "framework.json carries the version, four contract versions, tool pins, and the lookup"

# --- AGENTS.md is thin --------------------------------------------------------

managed_start="$(grep -n 'OPENWIKI:START' AGENTS.md | head -1 | cut -d: -f1 || true)"
if [ -n "$managed_start" ]; then
  handwritten="$(head -n "$((managed_start - 1))" AGENTS.md)"
  grep -q 'OPENWIKI:END' AGENTS.md || fail "AGENTS.md opens a managed block it never closes"
else
  handwritten="$(cat AGENTS.md)"
fi
lines="$(printf '%s\n' "$handwritten" | wc -l | tr -d ' ')"
[ "$lines" -le 10 ] || fail "the hand-written part of AGENTS.md is $lines lines; the limit is 10"
printf '%s\n' "$handwritten" | grep -qE '(^|[^A-Za-z0-9])(/Users/|/home/|/Volumes/|~/)' && \
  fail "AGENTS.md contains an absolute or home-relative path"
printf '%s\n' "$handwritten" | grep -q 'START-HERE.md' || \
  fail "AGENTS.md does not state the reading order (START-HERE.md first)"
printf '%s\n' "$handwritten" | grep -q 'views/' || \
  fail "AGENTS.md does not point at views/"
printf '%s\n' "$handwritten" | grep -q 'openwiki/' || \
  fail "AGENTS.md does not say what openwiki/ is"
pass "AGENTS.md: $lines hand-written lines, no absolute path, reading order stated"

# --- SECURITY.md --------------------------------------------------------------

grep -qi 'Individual' SECURITY.md || fail "SECURITY.md does not mention the Individual tier"
grep -q 'op://' SECURITY.md || fail "SECURITY.md does not name the op:// reference form"
grep -qi 'Individual documents only' SECURITY.md || \
  fail "SECURITY.md does not state that Individual documents are the only place a secret reference may appear"
grep -qi 'not a proof of absence\|never "this document is safe' SECURITY.md || \
  fail "SECURITY.md does not state the denylist's limits"
pass "SECURITY.md scopes secret references to the Individual tier and states the denylist's limits"

# --- docs/repurposing.md ------------------------------------------------------

rows=0
while IFS= read -r line; do
  case "$line" in
    '| '[0-9]' | '*) : ;;
    *) continue ;;
  esac
  rows=$((rows + 1))
  # "| n | gate | action | proof | rollback |" splits on | into fields 3..6.
  num="$(printf '%s' "$line" | awk -F'|' '{gsub(/[ \t]/, "", $2); print $2}')"
  empty="$(printf '%s' "$line" | awk -F'|' '
    { for (i = 3; i <= 6; i++) { c = $i; gsub(/[ \t]/, "", c); if (c == "") printf "%d ", i - 2 } }')"
  [ -z "$empty" ] || \
    fail "docs/repurposing.md row $num has empty cell(s) #${empty% } (1=gate 2=action 3=proof 4=rollback)"
done < <(sed -n '/^## The rows/,$p' docs/repurposing.md)
[ "$rows" -eq 7 ] || fail "docs/repurposing.md has $rows numbered rows; expected 7 (rows 0-6)"
pass "docs/repurposing.md: 7 rows, every gate/action/proof/rollback cell non-empty"

# --- no script performs a human-only action -----------------------------------
# The patterns are assembled from fragments so this test file does not match itself.
forbidden=("gh repo ed""it" "git ""push" "gh repo del""ete" "gh release del""ete" \
           "gh repo ren""ame" "git ""push --force")
while IFS= read -r script; do
  for pat in "${forbidden[@]}"; do
    if grep -qF -- "$pat" "$script"; then
      fail "$script runs a human-only action: $pat (see docs/repurposing.md)"
    fi
  done
done < <(find . -name '*.sh' -not -path './.git/*' | sort)
pass "no committed shell script pushes, renames, deletes, or changes repository visibility"

# --- .gitignore ---------------------------------------------------------------

probe_dir="tests/fixtures/__ignore_probe__"
mkdir -p "$probe_dir"
: > "$probe_dir/probe.yaml"
if git check-ignore -q "$probe_dir/probe.yaml"; then
  rm -rf "$probe_dir"
  fail "something under tests/fixtures/ is git-ignored; a fixture must always reach the validator"
fi
rm -rf "$probe_dir"

mkdir -p documents/examples/individual
: > documents/examples/individual/__probe__.yaml
ignored_other=0
git check-ignore -q documents/examples/individual/__probe__.yaml && ignored_other=1
rm -f documents/examples/individual/__probe__.yaml
rmdir -p documents/examples/individual 2>/dev/null || true
[ "$ignored_other" -eq 1 ] || fail ".gitignore does not ignore an Individual document under documents/"
pass ".gitignore: Individual documents ignored, tests/fixtures/ never ignored"

# --- tests/lib.sh contract ----------------------------------------------------

for fn in fail tmp_repo_copy strip_from_path make_git_dir sha256_of isolated_home assert_tree_unchanged; do
  grep -qE "^${fn}\(\)" tests/lib.sh || fail "tests/lib.sh does not define $fn"
done
pass "tests/lib.sh defines all seven required functions"

copy_path="$(bash -c '. "'"$ROOT"'/tests/lib.sh"; tmp_repo_copy')"
case "$copy_path" in
  *' '*) : ;;
  *) fail "tmp_repo_copy returned a path with no space in it: $copy_path" ;;
esac
[ -e "$copy_path" ] && fail "tmp_repo_copy did not clean up on exit: $copy_path"
pass "tmp_repo_copy returns a spaced path and removes it on exit"

copy_check="$(bash -c '. "'"$ROOT"'/tests/lib.sh"; c="$(tmp_repo_copy)"; \
  [ -d "$c/.git" ] && [ -f "$c/framework.json" ] && echo preserved')"
[ "$copy_check" = "preserved" ] || fail "tmp_repo_copy did not preserve .git in the copy"
pass "tmp_repo_copy preserves .git and the framework root marker"

# --- docs/plans and docs/research are scrubbed --------------------------------
# A placeholder is an <angle-bracket> token, an ellipsis, or one of a tiny
# documented set. Anything that looks like a real account, vault, or attachment id
# is a leak. docs/experiments/README.md records the full rule.

# Characters that end a path or a reference in prose. ']' must come first inside
# a POSIX bracket expression, which is why this is built as a variable.
TOKEN_STOP='] `"'"'"')|,'

leaks=0
report_leak() { printf 'LEAK %s\n' "$*" >&2; leaks=$((leaks + 1)); }

while IFS= read -r seg; do
  case "$seg" in
    ''|'...'|'…'|name|x|user|you|'<'*) : ;;
    *) report_leak "/Users/$seg looks like a real account name" ;;
  esac
done < <(grep -rEoh "/Users/[^${TOKEN_STOP}]*" docs/plans docs/research 2>/dev/null \
         | sed 's#^/Users/##; s#/.*##' | sort -u)

while IFS= read -r seg; do
  case "$seg" in
    ''|'...'|'…'|vault|x|name|'<'*|'[^'*) : ;;
    Example-Vault) : ;;
    *) report_leak "op://$seg/ names a real vault" ;;
  esac
done < <(grep -rEoh "op://[^${TOKEN_STOP}]*" docs/plans docs/research 2>/dev/null \
         | sed 's#^op://##; s#/.*##' | sort -u)

if grep -rEq 'GoogleDrive-[^ ]*@' docs/plans docs/research 2>/dev/null; then
  report_leak "a CloudStorage path carries an account email"
fi
if grep -rEq '\.codex/attachments/[0-9a-f]{8}-' docs/plans docs/research 2>/dev/null; then
  report_leak "a harness attachment path carries a real attachment id"
fi
if grep -rqF '/tmp/compound-engineering' docs/plans docs/research 2>/dev/null; then
  report_leak "a scratch path under /tmp survived the scrub"
fi
if grep -rEq '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' docs/plans docs/research 2>/dev/null; then
  report_leak "an email address survived the scrub"
fi

REAL_NAMES="tests/local/real-names.txt"
if [ -f "$REAL_NAMES" ]; then
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    case "$name" in \#*) continue ;; esac
    if grep -rqiF -- "$name" docs/plans docs/research 2>/dev/null; then
      report_leak "a name from $REAL_NAMES appears under docs/plans or docs/research"
    fi
  done < "$REAL_NAMES"
  pass "checked docs/plans and docs/research against $REAL_NAMES"
else
  printf 'note: %s is absent (U6 adds it); the exact real-name check did not run\n' "$REAL_NAMES"
fi

[ "$leaks" -eq 0 ] || fail "$leaks leak(s) under docs/plans or docs/research"
pass "docs/plans and docs/research carry no machine path, secret reference, or personal identifier"

printf '\nrepo-baseline: all checks passed\n'
