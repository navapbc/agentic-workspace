#!/usr/bin/env bash
# shellcheck disable=SC2016  # literal backticks in generated markdown are intentional
set -euo pipefail

# route-artifact.sh — deterministic artifact routing for shared product work.
#
# Compiles the team's routing table into a zero-token answer: given an artifact
# type and product area, prints the destination plus any typed exception
# (grandfathered lane, or a variance that prefers a stronger lane) registered in
# <product-work>/area-manifest.yaml. Read-only.
#
# Why a tool and not a paragraph in AGENTS.md: routing is asked constantly and
# answered inconsistently. A lookup that returns the same answer for every
# teammate and every harness is cheaper than re-deriving it, and the exceptions
# stay in one reviewable file instead of drifting across area guidance.
#
# Usage:
#   route-artifact.sh --type <type> --area <area>
#   route-artifact.sh --list          # types and areas
#   route-artifact.sh --card          # write the generated one-page routing card
#
# Lane names come from the team's docs-lane choice. Edit lane_for_type() once if
# your team renamed lanes; everything downstream follows.

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace_root=$(cd "${support_root}/.." && pwd)
product_work_dir="${AGENTIC_PRODUCT_WORK_DIR:-product-work}"
product_work_root="${workspace_root}/${product_work_dir}"
area_manifest="${product_work_root}/area-manifest.yaml"
card_path="${support_root}/context-fabric/records/generated/routing-card.md"

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

[[ -f "${area_manifest}" ]] || fail "area manifest not found: ${area_manifest}"

known_areas() {
  awk '/^  - id: /{print $3}' "${area_manifest}"
}

area_exceptions() {
  # Prints "type<TAB>lanes<TAB>rationale" rows for one area.
  awk -v area="$1" '
    /^  - id: /      { in_area = ($3 == area); next }
    !in_area         { next }
    /^      - type: / { etype = $3; lanes = ""; rationale = ""; next }
    /^        lanes: /     { lanes = $0; sub(/^ *lanes: \[/, "", lanes); sub(/\]$/, "", lanes) }
    /^        rationale: / { rationale = $0; sub(/^ *rationale: /, "", rationale);
                             printf "%s\t%s\t%s\n", etype, lanes, rationale }
  ' "${area_manifest}"
}

lane_for_type() {
  case "$1" in
    ideation)                            printf 'docs/ideation/' ;;
    plan|plans|requirements)             printf 'docs/plans/' ;;
    solution|solutions|learning)         printf 'docs/solutions/' ;;
    pulse-report|pulse-reports|status)   printf 'docs/pulse-reports/' ;;
    dogfood-report|dogfood-reports)      printf 'docs/dogfood-reports/' ;;
    reference|references)                printf 'docs/references/<reference-set-slug>/' ;;
    prototype|mockup|spike)              printf 'PROTOTYPE' ;;
    synthesis)                           printf 'AREA_ROOT' ;;
    *) return 1 ;;
  esac
}

known_types='ideation plan solution pulse-report dogfood-report reference prototype synthesis'

write_card() {
  mkdir -p "$(dirname "${card_path}")"
  {
    printf -- '---\ngenerated_at: %s\nsource: %s/area-manifest.yaml + tools/route-artifact.sh\n---\n\n' \
      "$(date +%Y-%m-%d)" "${product_work_dir}"
    printf '# Routing card\n\n'
    printf 'One page: where an artifact goes. `tools/route-artifact.sh --type <type> --area <area>` gives the same answer with exceptions applied.\n\n'
    printf '| Artifact | Destination |\n|---|---|\n'
    printf '| Raw ideas, options | `<area>/docs/ideation/` |\n'
    printf '| Requirements, scope, delivery plans | `<area>/docs/plans/` |\n'
    printf '| Durable learnings, solved patterns | `<area>/docs/solutions/` |\n'
    printf '| Periodic health snapshots | `<area>/docs/pulse-reports/` |\n'
    printf '| Notes from using your own tools | `<area>/docs/dogfood-reports/` |\n'
    printf '| Read-only source bundles | `<area>/docs/references/<reference-set-slug>/` |\n'
    printf '| Mockups, spikes, prototypes | `<area>/prototypes/<name>-prototype/` |\n'
    printf '| Product synthesis | owning area folder (see its README) |\n'
    printf '| Repository source | stays in the machine-local checkouts root; never copied in |\n'
    printf '| Reusable workflow behavior | `agentic-support/skills/` |\n\n'
    printf '## Area exceptions\n\n'
    local any_exceptions=0
    while IFS= read -r area; do
      rows=$(area_exceptions "${area}")
      [[ -n "${rows}" ]] || continue
      any_exceptions=1
      printf '**%s**\n\n' "${area}"
      while IFS=$'\t' read -r etype lanes rationale; do
        printf -- '- %s: %s — %s\n' "${etype}" "${lanes}" "${rationale}"
      done <<< "${rows}"
      printf '\n'
    done < <(known_areas)
    (( any_exceptions )) || printf 'None registered.\n\n'
    printf 'Never create loose files at the product-work root or invent a parallel lane for work that fits an existing one. Unknown product area: ask which product owns the artifact; do not infer it from a checkout or alias name.\n'
  } > "${card_path}"
  printf 'Wrote %s\n' "${card_path}"
}

artifact_type=''
area=''
while (( $# > 0 )); do
  case "$1" in
    --type) artifact_type="${2:-}"; shift 2 ;;
    --area) area="${2:-}"; shift 2 ;;
    --card) write_card; exit 0 ;;
    --list)
      printf 'Types: %s\n' "${known_types}"
      printf 'Areas: %s\n' "$(known_areas | tr '\n' ' ')"
      exit 0 ;;
    -h|--help) sed -n '6,25p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) fail "unknown argument: $1 (try --list)" ;;
  esac
done

[[ -n "${artifact_type}" && -n "${area}" ]] || fail 'need --type and --area (or --list / --card)'

if ! known_areas | grep -Fxq "${area}"; then
  printf 'Unknown product area: %s\n' "${area}" >&2
  printf 'Ask which product owns the artifact; do not infer it from a checkout or alias.\n' >&2
  printf 'Known areas: %s\n' "$(known_areas | tr '\n' ' ')" >&2
  exit 1
fi

lane=$(lane_for_type "${artifact_type}") || fail "unknown artifact type: ${artifact_type} (try --list)"

case "${lane}" in
  PROTOTYPE) destination="${product_work_root}/${area}/prototypes/" ;;
  AREA_ROOT) destination="${product_work_root}/${area}/ (see the area README for the exact home)" ;;
  *)         destination="${product_work_root}/${area}/${lane}" ;;
esac

printf 'Destination: %s\n' "${destination}"

rows=$(area_exceptions "${area}")
if [[ -n "${rows}" ]]; then
  while IFS=$'\t' read -r etype lanes rationale; do
    case "${etype}" in
      variance)
        printf 'Check first (variance): stronger lanes %s\n  %s\n' "${lanes}" "${rationale}" ;;
      grandfathered)
        printf 'Grandfathered lane(s) %s: extend-only, do not expand.\n  %s\n' "${lanes}" "${rationale}" ;;
    esac
  done <<< "${rows}"
fi
