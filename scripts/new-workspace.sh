#!/bin/sh
# Scaffold a new shared agentic workspace from the kit templates.
#
# Usage:
#   ./new-workspace.sh --name "My Product Workspace" [--dir /path/to/parent] [--with-support]
#
#   --name          workspace folder name (required)
#   --dir           parent directory to create it in (default: current directory)
#   --with-support  also scaffold the Walk-phase support layer (skills/ + context-fabric/)
#
# Creates a Crawl-phase workspace: thin AGENTS.md (+ CLAUDE.md mirror), README,
# the suggested docs lanes, and the product-work/ and prototyping/ lanes.
# Directory names follow the kit's kebab-case standard (see docs/directory-and-naming-standard.md).
# Fill in the placeholders afterward; keep AGENTS.md thin.

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
substitute "$tpl/bindings.env.template" "$ws/bindings.env.template"
cp "$tpl/docs/README.md" "$ws/docs/README.md"

# Suggested docs lanes (rename, drop, or add your own — see docs/README.md).
for lane in ideation plans solutions; do
  mkdir -p "$ws/docs/$lane"
done

if [ "$with_support" -eq 1 ]; then
  mkdir -p "$ws/agentic-support/skills" \
           "$ws/agentic-support/context-fabric/records/systems" \
           "$ws/agentic-support/context-fabric/records/resources" \
           "$ws/agentic-support/context-fabric/records/profiles" \
           "$ws/agentic-support/context-fabric/templates"
  cp -R "$kit_dir/templates/skills/." "$ws/agentic-support/skills/"
  cp -R "$kit_dir/templates/context-fabric/." "$ws/agentic-support/context-fabric/templates/"
  cp "$kit_dir/templates/harness-config/opencode.json" "$ws/opencode.json"
fi

printf 'Created workspace: %s\n\n' "$ws"
printf 'Next:\n'
printf '  1. Edit "%s/AGENTS.md" (and CLAUDE.md) to set boundaries and vocabulary. Keep it thin.\n' "$name"
printf '  2. Point your agent tool at the workspace (see the kit docs/local-setup.md).\n'
if [ "$with_support" -eq 1 ]; then
  printf '  3. Rename the example-skill directory and register real skills in skill-manifest.yaml.\n'
  printf '  4. Author Context Fabric records from "agentic-support/context-fabric/templates/".\n'
fi
printf '  Validate any time with: "%s/scripts/validate-workspace.sh" "%s"\n' "$kit_dir" "$ws"
