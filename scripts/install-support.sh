#!/bin/sh
# Install or upgrade the agentic support engine in a workspace.
#
# The support engine is generic: every file installs verbatim except the two you
# author yourself (CONCEPTS.md and docs/context-source-ladder.md, both installed from
# a .template on first run and never touched again). That is what makes upgrades
# possible at all — a team can pull a newer engine without re-merging their own work.
#
# Usage:
#   ./install-support.sh <workspace-dir> [--dir-name agentic-support] [--check] [--force]
#
#     --check   report what would change; write nothing (use this first)
#     --force   overwrite generic files you have modified locally
#
# On upgrade, a generic file you have modified locally is reported as a CONFLICT and
# left alone. Reconcile it deliberately — or better, upstream the change so the next
# team gets it too.

set -eu

usage() {
  printf '%s\n' 'Usage: ./install-support.sh <workspace-dir> [--dir-name agentic-support] [--check] [--force]'
}

ws=""
dir_name="agentic-support"
mode=install
force=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir-name) shift; [ "$#" -gt 0 ] || { usage >&2; exit 2; }; dir_name=$1 ;;
    --check) mode=check ;;
    --force) force=1 ;;
    --help|-h) usage; exit 0 ;;
    -*) usage >&2; exit 2 ;;
    *) [ -z "$ws" ] || { usage >&2; exit 2; }; ws=$1 ;;
  esac
  shift
done

[ -n "$ws" ] || { printf 'error: workspace directory is required\n' >&2; usage >&2; exit 2; }
[ -d "$ws" ] || { printf 'error: not a directory: %s\n' "$ws" >&2; exit 1; }

unset CDPATH || true
kit_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
src="$kit_dir/templates/support"
[ -d "$src" ] || { printf 'error: support templates not found at %s\n' "$src" >&2; exit 1; }
ws=$(cd -- "$ws" && pwd)
dst="$ws/$dir_name"

# Team-owned files: seeded on first install, then never touched again. Two groups, same
# behavior, different reasons.
#
#   authored   — the team writes the content (installed from a .template)
#   seed_once  — the team owns the file after first install: the manifest lists THEIR
#                skills, and example-skill is a starting point they rename or delete
#
# Everything else is generic and upgrades in place, which is what makes upgrades possible.
authored="CONCEPTS.md docs/context-source-ladder.md tools/doctor.conf"
seed_once="skills/skill-manifest.yaml skills/example-skill/SKILL.md"
is_team_owned() {
  for a in $authored $seed_once; do [ "$1" = "$a" ] && return 0; done
  return 1
}

# On an upgrade (the manifest already exists) the seed-once files are skipped entirely,
# so a renamed or deleted example-skill does not reappear.
upgrading=0
[ -f "$dst/skills/skill-manifest.yaml" ] && upgrading=1
skip_on_upgrade() {
  [ "$upgrading" -eq 1 ] || return 1
  for a in $seed_once; do [ "$1" = "$a" ] && return 0; done
  return 1
}

added=0
conflicts=0

report() { printf '%-9s %s\n' "$1" "$2"; }

# Walk the template tree. Paths with a .template suffix install without it.
( cd "$src" && find . -type f -print ) | sed 's|^\./||' | sort | while IFS= read -r rel; do
  target_rel=$(printf '%s' "$rel" | sed 's/\.template$//')
  s="$src/$rel"
  d="$dst/$target_rel"

  skip_on_upgrade "$target_rel" && continue

  if [ ! -f "$d" ]; then
    report ADD "$target_rel"
    if [ "$mode" = install ]; then
      mkdir -p "$(dirname "$d")"
      cp "$s" "$d"
      case "$target_rel" in *.sh) chmod +x "$d" ;; esac
    fi
    continue
  fi

  if is_team_owned "$target_rel"; then
    report KEEP "$target_rel (yours)"
    continue
  fi

  if cmp -s "$s" "$d"; then
    continue
  fi

  # The file differs. If the installed copy still matches some shipped version we
  # cannot know, so treat any difference as a local modification unless --force.
  if [ "$force" -eq 1 ]; then
    report UPDATE "$target_rel"
    [ "$mode" = install ] && cp "$s" "$d"
    case "$target_rel" in *.sh) [ "$mode" = install ] && chmod +x "$d" ;; esac
  else
    report CONFLICT "$target_rel (locally modified; re-run with --force to overwrite)"
  fi
done

# Counts are lost to the subshell above; recompute cheaply for the summary.
added=$( ( cd "$src" && find . -type f -print ) | sed 's|^\./||' | while IFS= read -r rel; do
  t=$(printf '%s' "$rel" | sed 's/\.template$//')
  skip_on_upgrade "$t" && continue
  [ -f "$dst/$t" ] || printf 'x\n'; done | wc -l | tr -d ' ')
conflicts=$( ( cd "$src" && find . -type f -print ) | sed 's|^\./||' | while IFS= read -r rel; do
  t=$(printf '%s' "$rel" | sed 's/\.template$//')
  skip_on_upgrade "$t" && continue
  [ -f "$dst/$t" ] || continue
  is_team_owned "$t" && continue
  cmp -s "$src/$rel" "$dst/$t" || printf 'x\n'; done | wc -l | tr -d ' ')

printf '\n'
if [ "$mode" = check ]; then
  printf 'check only: nothing written. %s file(s) to add, %s difference(s).\n' "$added" "$conflicts"
  exit 0
fi

# Create the empty record directories the tools expect (find does not carry them).
mkdir -p "$dst/context-fabric/records/profiles" \
         "$dst/context-fabric/records/resources/repositories" \
         "$dst/context-fabric/records/resources/local" \
         "$dst/context-fabric/records/systems" \
         "$dst/context-fabric/records/sync-manifests/releases" \
         "$dst/context-fabric/records/generated" \
         "$dst/tools/paused" \
         "$dst/skills/adapters"

# Claude Code reads CLAUDE.md, not AGENTS.md. A one-line import means nothing to sync.
[ -f "$dst/CLAUDE.md" ] || printf '@AGENTS.md\n' > "$dst/CLAUDE.md"

printf 'Support engine installed at %s\n\n' "$dst"
printf 'Next:\n'
printf '  1. Author your two files: %s/CONCEPTS.md and %s/docs/context-source-ladder.md\n' "$dir_name" "$dir_name"
printf '  2. Declare your roots:  %s/tools/generate-workspace-descriptor.sh --checkout-root ... --working-materials-root ...\n' "$dst"
printf '     (or just ask your agent to run the workspace-setup skill, which interviews you)\n'
printf '  3. Check it:            %s/tools/workspace-doctor.sh\n' "$dst"
printf '  4. Gate it:             %s/validation/check-workspace.sh\n' "$dst"
if [ "$conflicts" -gt 0 ]; then
  printf '\n%s generic file(s) differ from the shipped engine and were left alone.\n' "$conflicts"
  printf 'Reconcile them, or re-run with --force to take the shipped version.\n'
fi
