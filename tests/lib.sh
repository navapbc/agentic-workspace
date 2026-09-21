#!/usr/bin/env bash
# Shared test library. Source it once per test script:
#
#   . "$(dirname "$0")/lib.sh"
#
# Exit codes every test script and tests/run.sh honor:
#   0  pass
#   1  a check failed
#   2  usage or environment error (a required tool is missing, bad arguments)
#   3  a stage was skipped because an optional tool is absent -- never 0
#
# The library never sets shell options: the sourcing script owns `set -euo pipefail`.

# shellcheck shell=bash

EXIT_PASS=0
EXIT_FAIL=1
EXIT_USAGE=2
EXIT_SKIPPED=3
export EXIT_PASS EXIT_FAIL EXIT_USAGE EXIT_SKIPPED

_CE_TMPDIRS=()
_CE_SNAPSHOT_DIR=""

_ce_cleanup() {
  local d
  for d in "${_CE_TMPDIRS[@]+"${_CE_TMPDIRS[@]}"}"; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
  done
  [ -n "$_CE_SNAPSHOT_DIR" ] && [ -d "$_CE_SNAPSHOT_DIR" ] && rm -rf "$_CE_SNAPSHOT_DIR"
  return 0
}
trap _ce_cleanup EXIT

# fail <message...> -- report a failed check on stderr and exit 1.
fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit "$EXIT_FAIL"
}

# skip <message...> -- report a skipped stage on stderr and exit 3.
skip() {
  printf 'SKIP: %s\n' "$*" >&2
  exit "$EXIT_SKIPPED"
}

# usage_error <message...> -- report a usage or environment problem and exit 2.
usage_error() {
  printf 'ERROR: %s\n' "$*" >&2
  exit "$EXIT_USAGE"
}

# pass <message...> -- report a passing check on stdout.
pass() {
  printf 'ok: %s\n' "$*"
}

# _ce_mktemp_spaced <label> -- a temp directory whose path contains a space, so a
# test that forgets to quote a path fails here instead of on someone's machine.
_ce_mktemp_spaced() {
  local base
  base="$(mktemp -d "${TMPDIR:-/tmp}/ce-${1:-tmp}.XXXXXX")" || return 1
  mkdir -p "$base/with space" || return 1
  _CE_TMPDIRS+=("$base")
  printf '%s\n' "$base/with space"
}

# tmp_repo_copy -- copy the whole working tree, including .git, into a temp path
# containing a space. Prints the copy's path. Cleaned up on exit. Behavioral tests
# run in here so the real tree is never touched.
tmp_repo_copy() {
  local src dest
  src="$(repo_root)" || return 1
  dest="$(_ce_mktemp_spaced repo)" || return 1
  # -a keeps modes and symlinks; the trailing /. copies dotfiles including .git.
  cp -a "$src/." "$dest/" || return 1
  printf '%s\n' "$dest"
}

# repo_root -- absolute path of the framework root (the directory holding framework.json).
repo_root() {
  local dir="${CE_REPO_ROOT:-$PWD}"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/framework.json" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  usage_error "framework.json not found above ${CE_REPO_ROOT:-$PWD}; run from inside the framework repository"
}

# strip_from_path <tool> -- print a PATH with every directory that provides <tool>
# removed, so a test can prove the tiered behavior when the tool is absent.
strip_from_path() {
  local tool="${1:?strip_from_path needs a tool name}" out="" dir
  local IFS=:
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    if [ -x "$dir/$tool" ]; then continue; fi
    out="${out:+$out:}$dir"
  done
  printf '%s\n' "$out"
}

# make_git_dir <dir> -- initialize <dir> as a git repository with a deterministic
# identity, so a test never depends on the machine's git config.
make_git_dir() {
  local dir="${1:?make_git_dir needs a directory}"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.name "Framework Test"
  git -C "$dir" config user.email "test@example.invalid"
  git -C "$dir" config commit.gpgsign false
}

# sha256_of <file> -- print the file's sha256 hex digest, nothing else.
sha256_of() {
  local file="${1:?sha256_of needs a file}"
  [ -f "$file" ] || usage_error "sha256_of: no such file: $file"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | cut -d' ' -f1
  else
    usage_error "sha256_of: neither sha256sum nor shasum is available"
  fi
}

# isolated_home -- point HOME and XDG_CONFIG_HOME at a fresh temp directory and
# unset AGENTIC_WORKSPACE_INDIVIDUAL, so a test never reads or writes the real
# machine's Individual document. Exports into the calling shell.
isolated_home() {
  local home
  home="$(_ce_mktemp_spaced home)" || return 1
  mkdir -p "$home/.config"
  HOME="$home"
  XDG_CONFIG_HOME="$home/.config"
  export HOME XDG_CONFIG_HOME
  unset AGENTIC_WORKSPACE_INDIVIDUAL
  printf '%s\n' "$home"
}

_ce_tree_digest() {
  local dir="$1"
  {
    git -C "$dir" rev-parse HEAD 2>/dev/null || printf 'no-head\n'
    git -C "$dir" status --porcelain=v1 --untracked-files=all
    git -C "$dir" diff --cached --name-status
  } | {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi
  } | cut -d' ' -f1
}

# The snapshot directory must be created by a call that is NOT inside a command
# substitution, or the assignment is lost with the subshell.
_ce_ensure_snapshot_dir() {
  [ -n "$_CE_SNAPSHOT_DIR" ] && return 0
  _CE_SNAPSHOT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ce-snap.XXXXXX")"
}

_ce_snapshot_slot() {
  printf '%s/%s\n' "$_CE_SNAPSHOT_DIR" "$(printf '%s' "$1" | tr -c 'A-Za-z0-9' '_')"
}

# snapshot_tree <dir> -- record <dir>'s HEAD, working tree, and index state.
snapshot_tree() {
  local dir="${1:?snapshot_tree needs a directory}"
  _ce_ensure_snapshot_dir
  _ce_tree_digest "$dir" > "$(_ce_snapshot_slot "$dir")"
}

# assert_tree_unchanged <dir> -- fail if <dir>'s HEAD, working tree, or index moved
# since snapshot_tree was called for it. The real-tree checks use this so a test run
# can never leave the maintainer's tree or index dirty.
assert_tree_unchanged() {
  local dir="${1:?assert_tree_unchanged needs a directory}" slot
  _ce_ensure_snapshot_dir
  slot="$(_ce_snapshot_slot "$dir")"
  [ -f "$slot" ] || usage_error "assert_tree_unchanged: call snapshot_tree '$dir' first"
  if [ "$(_ce_tree_digest "$dir")" != "$(cat "$slot")" ]; then
    printf 'FAIL: %s changed during the run:\n' "$dir" >&2
    git -C "$dir" status --short --untracked-files=all >&2
    exit "$EXIT_FAIL"
  fi
}
