#!/bin/sh
# Scaffold a new shared agentic workspace from the kit templates.
#
# Usage:
#   ./new-workspace.sh --name "My Product Workspace" [--dir /path/to/parent] [--with-support]
#
#   --name          workspace folder name (required)
#   --dir           parent directory to create it in (default: current directory)
#   --with-support  also install the support engine (skills, Context Fabric, tools,
#                   validation) via install-support.sh — the Walk/Run phases
#
# Creates a Crawl-phase workspace: thin AGENTS.md (+ CLAUDE.md import), README,
# the suggested docs lanes, and the product-work/ and prototyping/ lanes.
# Directory names follow the kit's kebab-case standard (see docs/directory-and-naming-standard.md).
# Fill in the placeholders afterward; keep AGENTS.md thin.
#
# Machine-local paths are NOT configured here. They are declared per machine by
# agentic-support/tools/generate-workspace-descriptor.sh (or the workspace-setup
# skill, which interviews you) and never stored in the shared tree.

set -eu

usage() {
  printf '%s\n' 'Usage: ./new-workspace.sh --name "<workspace>" [--dir <parent>] [--with-support]'
}

name=""
parent="$(pwd)"
with_support=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --name) shift; [ "$#" -gt 0 ] || { usage >&2; exit 2; }; name=$1 ;;
    --dir) shift; [ "$#" -gt 0 ] || { usage >&2; exit 2; }; parent=$1 ;;
    --with-support) with_support=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

[ -n "$name" ] || { printf 'error: --name is required\n' >&2; usage >&2; exit 2; }

unset CDPATH || true
kit_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
tpl="$kit_dir/templates/workspace"
[ -d "$tpl" ] || { printf 'error: templates not found at %s\n' "$tpl" >&2; exit 1; }

ws="$parent/$name"
if [ -e "$ws" ]; then
  printf 'error: %s already exists\n' "$ws" >&2
  exit 1
fi

mkdir -p "$ws/product-work" "$ws/prototyping" "$ws/docs"

# Copy templates, stripping the .template suffix and substituting the workspace name.
substitute() { sed "s/{{WORKSPACE_NAME}}/$name/g" "$1" > "$2"; }

substitute "$tpl/AGENTS.md.template" "$ws/AGENTS.md"
# Claude Code reads CLAUDE.md, not AGENTS.md. Make CLAUDE.md a one-line import so
# AGENTS.md stays the single source of truth (no duplicate content to keep in sync).
printf '@AGENTS.md\n' > "$ws/CLAUDE.md"
substitute "$tpl/README.md.template" "$ws/README.md"
cp "$tpl/docs/README.md" "$ws/docs/README.md"
substitute "$tpl/product-work/area-manifest.yaml.template" "$ws/product-work/area-manifest.yaml"

# Suggested docs lanes (rename, drop, or add your own — see docs/README.md).
for lane in ideation plans solutions; do
  mkdir -p "$ws/docs/$lane"
done

if [ "$with_support" -eq 1 ]; then
  "$kit_dir/scripts/install-support.sh" "$ws" >/dev/null
  cp "$kit_dir/templates/harness-config/opencode.json" "$ws/opencode.json"
fi

printf 'Created workspace: %s\n\n' "$ws"
printf 'Next:\n'
printf '  1. Edit "%s/AGENTS.md" (and CLAUDE.md) to set boundaries and vocabulary. Keep it thin.\n' "$name"
printf '  2. Point your agent tool at the workspace (see the kit docs/local-setup.md).\n'
if [ "$with_support" -eq 1 ]; then
  printf '  3. Author your two files: agentic-support/CONCEPTS.md and agentic-support/docs/context-source-ladder.md.\n'
  printf '  4. Declare your roots, then check: ask your agent to run the workspace-setup skill,\n'
  printf '     or run "%s/agentic-support/tools/generate-workspace-descriptor.sh --help".\n' "$ws"
  printf '  5. Rename example-skill and register real skills in skills/skill-manifest.yaml.\n'
  printf '  Gate it any time with: "%s/agentic-support/validation/check-workspace.sh"\n' "$ws"
else
  printf '  3. Add the support engine when you need shared skills or facts:\n'
  printf '     "%s/scripts/install-support.sh" "%s"\n' "$kit_dir" "$ws"
  printf '  Validate any time with: "%s/scripts/validate-workspace.sh" "%s"\n' "$kit_dir" "$ws"
fi
