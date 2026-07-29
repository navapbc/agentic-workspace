#!/usr/bin/env bash
set -euo pipefail

# scaffold-product-area.sh — stand up a compliant new product area in minutes.
#
# Creates <area>/ under the product-work lane with a thin AGENTS.md (plus the
# CLAUDE.md import), a README stub, and the team's default docs lanes, then
# appends a registry entry to area-manifest.yaml. Refuses to touch an existing
# area or re-register a known one.
#
# Usage: scaffold-product-area.sh <area-slug> "<Display Name>"

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace_root=$(cd "${support_root}/.." && pwd)
product_work_dir="${AGENTIC_PRODUCT_WORK_DIR:-product-work}"
product_work_root="${workspace_root}/${product_work_dir}"
area_manifest="${product_work_root}/area-manifest.yaml"

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

slug="${1:-}"
display="${2:-}"
[[ -n "${slug}" && -n "${display}" ]] || fail 'usage: scaffold-product-area.sh <area-slug> "<Display Name>"'
[[ "${slug}" =~ ^[a-z0-9][a-z0-9-]*$ ]] || fail "area slug must be kebab-case: ${slug}"
[[ -f "${area_manifest}" ]] || fail "area manifest not found: ${area_manifest}"
[[ ! -e "${product_work_root}/${slug}" ]] || fail "area already exists: ${product_work_root}/${slug}"
! grep -q "^  - id: ${slug}\$" "${area_manifest}" || fail "area already registered in area-manifest.yaml: ${slug}"

area_root="${product_work_root}/${slug}"
mkdir -p "${area_root}"/docs/{ideation,plans,solutions,references}

cat > "${area_root}/AGENTS.md" <<EOF
# ${display} Product Work

Context Fabric profile: product:${slug}

Steward: unassigned

- This folder is the ${display} product area inside \`${product_work_dir}/\`.
- Reusable procedures live in \`agentic-support/skills/\`; shared facts resolve through the profile above. Do not copy either here.
- Route outputs with \`agentic-support/tools/route-artifact.sh --type <type> --area ${slug}\`.
- Store read-only source bundles in \`docs/references/<reference-set-slug>/\`.
- Route mockups and spikes to \`prototypes/<name>-prototype/\` until the team relies on them.
EOF

printf '@AGENTS.md\n' > "${area_root}/CLAUDE.md"

cat > "${area_root}/README.md" <<EOF
# ${display}

Entry point for the ${display} product area. Describe the product scope, active
workstreams, and key artifacts here.

Routing and boundaries live in \`AGENTS.md\`; the workspace-wide routing answer
is \`agentic-support/tools/route-artifact.sh --list\`.
EOF

{
  printf '  - id: %s\n' "${slug}"
  printf '    profile: product:%s\n' "${slug}"
  printf '    steward: unassigned\n'
} >> "${area_manifest}"

printf 'Scaffolded %s\n' "${area_root}"
printf 'Registered in %s (set the steward to a named person).\n' "${area_manifest}"
printf 'Next: author the product profile in Context Fabric when the area needs shared facts.\n'
