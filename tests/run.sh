#!/usr/bin/env bash
# The gate. Runs every tests/*.test.sh and aggregates their exit codes.
#
#   0  every test passed and nothing was skipped
#   1  at least one check failed
#   2  usage or environment error
#   3  every test that ran passed, but at least one stage was skipped for a
#      missing optional tool -- a skipped stage never reports 0
#
# Precedence when several occur: 1 > 2 > 3 > 0.
#
# Behavioral tests copy the tree with tmp_repo_copy and run there; the real-tree
# checks run in place. Either way this script asserts the working tree and index
# are byte-identical afterwards.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/lib.sh
. "$HERE/lib.sh"

usage() {
  cat <<'USAGE'
Usage: tests/run.sh [--list] [--help] [<test-name>...]

  --list          print the test scripts that would run, one per line, and exit 0
  --help          print this message and exit 0
  <test-name>...  run only these tests (with or without the .test.sh suffix)

Exit codes: 0 pass  1 a check failed  2 usage/environment  3 a stage was skipped
USAGE
}

LIST_ONLY=0
SELECTED=()
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit "$EXIT_PASS" ;;
    --list) LIST_ONLY=1 ;;
    -*) usage >&2; usage_error "unknown flag: $1" ;;
    *) SELECTED+=("${1%.test.sh}") ;;
  esac
  shift
done

ROOT="$(repo_root)"
cd "$ROOT"

discover() {
  local f base
  for f in "$HERE"/*.test.sh; do
    [ -f "$f" ] || continue
    base="$(basename "$f" .test.sh)"
    if [ "${#SELECTED[@]}" -gt 0 ]; then
      local want found=0
      for want in "${SELECTED[@]}"; do
        [ "$want" = "$base" ] && found=1
      done
      [ "$found" -eq 1 ] || continue
    fi
    printf '%s\n' "$f"
  done
}

TESTS=()
while IFS= read -r line; do TESTS+=("$line"); done < <(discover)

if [ "$LIST_ONLY" -eq 1 ]; then
  printf '%s\n' "${TESTS[@]+"${TESTS[@]}"}"
  exit "$EXIT_PASS"
fi

if [ "${#TESTS[@]}" -eq 0 ]; then
  usage_error "no test scripts matched; tests/run.sh --list shows what is available"
fi

snapshot_tree "$ROOT"

worst=0
failed=()
skipped=()
for t in "${TESTS[@]}"; do
  name="$(basename "$t" .test.sh)"
  printf '\n=== %s ===\n' "$name"
  rc=0
  bash "$t" || rc=$?
  case "$rc" in
    0) printf -- '--- %s: pass\n' "$name" ;;
    3) printf -- '--- %s: skipped a stage\n' "$name"; skipped+=("$name")
       if [ "$worst" -eq 0 ]; then worst=3; fi ;;
    2) printf -- '--- %s: usage/environment error\n' "$name"; failed+=("$name")
       if [ "$worst" -ne 1 ]; then worst=2; fi ;;
    *) printf -- '--- %s: FAILED (exit %s)\n' "$name" "$rc"; failed+=("$name"); worst=1 ;;
  esac
done

assert_tree_unchanged "$ROOT"

printf '\n===============================\n'
printf 'ran %s test script(s)\n' "${#TESTS[@]}"
if [ "${#failed[@]}" -gt 0 ]; then printf 'failed: %s\n' "${failed[*]}"; fi
if [ "${#skipped[@]}" -gt 0 ]; then printf 'skipped a stage: %s\n' "${skipped[*]}"; fi
case "$worst" in
  0) printf 'result: pass\n' ;;
  3) printf 'result: pass, with a skipped stage (exit 3, not 0)\n' ;;
  2) printf 'result: usage or environment error (exit 2)\n' ;;
  *) printf 'result: FAILED (exit 1)\n' ;;
esac
exit "$worst"
