#!/bin/sh
# Mirror the source-of-truth skills into each harness's runtime directory.
#
# Source of truth: the directory this script lives in must be the support layer's
# `skills/` folder, containing `skill-manifest.yaml` and `<skill-name>/SKILL.md`.
# Runtime copies are GENERATED; never edit them directly. Edit the source-of-truth bundle.
#
# Usage:
#   ./sync-skills.sh [--target opencode|codex|claude|all] [--check]
#     --check   report missing/stale runtime mirrors without writing (for preflight/CI)
#
# Target directories are read from the `targets:` block of skill-manifest.yaml when
# `yq` is available; otherwise the built-in defaults below are used. Adjust to taste.

set -eu

usage() {
  printf '%s\n' 'Usage: ./sync-skills.sh [--target opencode|codex|claude|all] [--check]'
}

mode=sync
target=all

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) mode=check ;;
    --target)
      shift
      [ "$#" -gt 0 ] || { usage >&2; exit 2; }
      target=$1
      ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

case "$target" in
  opencode|codex|claude|all) ;;
  *) usage >&2; exit 2 ;;
esac

# Resolve the directory this script lives in (the source-of-truth skills/ dir).
unset CDPATH || true
skills_dir=$(cd -- "$(dirname -- "$0")" && pwd)
manifest="$skills_dir/skill-manifest.yaml"
[ -f "$manifest" ] || { printf 'error: no skill-manifest.yaml in %s\n' "$skills_dir" >&2; exit 1; }

# Default runtime target directories. Overridden by manifest `targets:` if yq is present.
dir_opencode="$HOME/.config/opencode/skills"
dir_codex="$HOME/.agents/skills"
dir_claude="$HOME/.claude/skills"

if command -v yq >/dev/null 2>&1; then
  v=$(yq -r '.targets.opencode // ""' "$manifest" 2>/dev/null || echo "")
  [ -n "$v" ] && dir_opencode=$(eval echo "$v")
  v=$(yq -r '.targets.codex // ""' "$manifest" 2>/dev/null || echo "")
  [ -n "$v" ] && dir_codex=$(eval echo "$v")
  v=$(yq -r '.targets.claude // ""' "$manifest" 2>/dev/null || echo "")
  [ -n "$v" ] && dir_claude=$(eval echo "$v")
fi

# Enumerate enabled skills. Prefer the manifest; fall back to on-disk SKILL.md files
# (also used if yq is absent or the manifest fails to parse).
list_from_disk() {
  for d in "$skills_dir"/*/; do
    [ -f "${d}SKILL.md" ] || continue
    basename "$d"
  done
}

list_skills() {
  if command -v yq >/dev/null 2>&1; then
    out=$(yq -r '.skills[] | select((.status // "enabled") == "enabled") | .name' "$manifest" 2>/dev/null || true)
    if [ -n "$out" ]; then printf '%s\n' "$out"; else list_from_disk; fi
  else
    list_from_disk
  fi
}

targets_for() {
  case "$1" in
    all) printf '%s\n' opencode codex claude ;;
    *) printf '%s\n' "$1" ;;
  esac
}

dir_for() {
  case "$1" in
    opencode) echo "$dir_opencode" ;;
    codex) echo "$dir_codex" ;;
    claude) echo "$dir_claude" ;;
  esac
}

drift=0

for t in $(targets_for "$target"); do
  base=$(dir_for "$t")
  for skill in $(list_skills); do
    src="$skills_dir/$skill"
    dst="$base/$skill"
    [ -d "$src" ] || continue

    if [ "$mode" = check ]; then
      if [ ! -d "$dst" ]; then
        printf 'MISSING  %s/%s\n' "$t" "$skill"
        drift=1
      elif ! diff -r -q -x adapters "$src" "$dst" >/dev/null 2>&1; then
        printf 'STALE    %s/%s\n' "$t" "$skill"
        drift=1
      fi
      continue
    fi

    # sync: refresh the source-of-truth bundle (minus adapters/), then overlay this harness's adapter.
    mkdir -p "$dst"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --delete --exclude adapters/ "$src"/ "$dst"/
    else
      rm -rf "$dst"; mkdir -p "$dst"
      ( cd "$src" && find . -path ./adapters -prune -o -type f -print | while read -r f; do
          mkdir -p "$dst/$(dirname "$f")"; cp "$f" "$dst/$f"; done )
    fi
    if [ -d "$src/adapters/$t" ]; then
      ( cd "$src/adapters/$t" && find . -type f -print | while read -r f; do
          mkdir -p "$dst/$(dirname "$f")"; cp "$f" "$dst/$f"; done )
    fi
    printf 'synced   %s/%s\n' "$t" "$skill"
  done
done

if [ "$mode" = check ] && [ "$drift" -ne 0 ]; then
  printf '\ndrift detected: run ./sync-skills.sh --target all to fix\n' >&2
  exit 1
fi
