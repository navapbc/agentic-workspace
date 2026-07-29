#!/usr/bin/env bash
set -euo pipefail

# workspace-doctor.sh — fail-closed capability probe for a shared agentic workspace.
#
# Run at session start (or any time) to learn where you are, what you can do in
# this session, and what unlocks the rest. Read-only: makes no network calls and
# mutates nothing. Requires only bash and standard Unix tools so it runs
# directly from a synced (Drive/Dropbox) tree with nothing installed.
#
# Machine-local roots are DECLARED in the workspace descriptor
# (docs/skill-binding-contract.md, schema at
# context-fabric/schemas/workspace-descriptor/1.0.0/schema.json); the doctor
# never guesses them from directory shape. Lanes inside the shared workspace
# tree are physical siblings of the support tree and are derived from its
# location.
#
# Optional per-workspace configuration: tools/doctor.conf may set
#   CREDENTIAL_ENV_VARS="NAME_A NAME_B"   # session env vars that unlock a tier
#   CREDENTIAL_UNLOCK_HINT="..."          # what to tell a member who lacks them
#
# Exit codes: 0 = report produced (including degraded capability),
#             2 = support tree unresolvable (nothing to report against),
#             3 = workspace declaration missing or invalid (descriptor absent,
#                 incomplete, or naming roots that no longer exist on disk).

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace_root=$(cd "${support_root}/.." && pwd)
launch_dir="${PWD}"
descriptor="${AGENTIC_WORKSPACE_DESCRIPTOR:-${HOME}/.agentic-workspace/workspace-descriptor.yaml}"

fabric_root="${support_root}/context-fabric"
digest_root="${fabric_root}/records/generated/repo-digests"
manifest="${support_root}/skills/skill-manifest.yaml"
setup_skill='workspace-setup'

CREDENTIAL_ENV_VARS=''
CREDENTIAL_UNLOCK_HINT=''
# shellcheck source=/dev/null
[[ -f "${support_root}/tools/doctor.conf" ]] && . "${support_root}/tools/doctor.conf"

ok()   { printf '  [ok]      %s\n' "$*"; }
off()  { printf '  [locked]  %s\n' "$*"; }
note() { printf '            %s\n' "$*"; }

if [[ ! -f "${manifest}" ]]; then
  printf 'ERROR: cannot resolve the support tree (missing %s)\n' "${manifest}" >&2
  exit 2
fi

printf '== Agentic Workspace Doctor ==\n'
printf 'Workspace: %s\n' "${workspace_root}"
printf 'Date:      %s\n\n' "$(date +%Y-%m-%d)"

# --- Declared roots (the descriptor is the authority) ----------------------
if [[ ! -f "${descriptor}" ]]; then
  printf 'No workspace descriptor at %s\n' "${descriptor}"
  printf 'Declare your roots first: ask your agent to run the %s skill.\n' "${setup_skill}"
  printf 'It interviews you for your roots and writes the machine-local declaration.\n'
  exit 3
fi

read_binding() { sed -n "s/^$1: //p" "${descriptor}" | head -1; }

if [[ "$(read_binding descriptor_version)" != "1" ]]; then
  printf 'The descriptor at %s is not a version-1 declaration (missing or unrecognized descriptor_version).\n' "${descriptor}"
  printf 'Re-declare: ask your agent to run the %s skill.\n' "${setup_skill}"
  exit 3
fi

checkout_root="$(read_binding AGENTIC_REPO_CHECKOUT_ROOT)"
working_roots=()
while IFS= read -r p; do
  [[ -n "${p}" ]] && working_roots+=("${p}")
done < <(sed -n 's/^AGENTIC_WORKING_MATERIALS_ROOT_[0-9]*: //p' "${descriptor}")
extra_roots=()
while IFS= read -r p; do
  [[ -n "${p}" ]] && extra_roots+=("${p}")
done < <(sed -n 's/^AGENTIC_EXTRA_ROOT_[0-9]*: //p' "${descriptor}")

if [[ -z "${checkout_root}" || ${#working_roots[@]} -eq 0 ]]; then
  printf 'The descriptor at %s is missing required declarations\n' "${descriptor}"
  printf '(a repo-checkouts root and at least one working-materials root).\n'
  printf 'Re-declare: ask your agent to run the %s skill.\n' "${setup_skill}"
  exit 3
fi

missing_roots=()
for r in "${checkout_root}" "${working_roots[@]}" ${extra_roots[@]+"${extra_roots[@]}"}; do
  [[ -d "${r}" ]] || missing_roots+=("${r}")
done
if [[ ${#missing_roots[@]} -gt 0 ]]; then
  printf 'Declared root(s) no longer exist on disk:\n'
  printf '  %s\n' "${missing_roots[@]}"
  printf 'Re-declare the full set: ask your agent to run the %s skill\n' "${setup_skill}"
  printf '(or re-run tools/generate-workspace-descriptor.sh with the full set of roots).\n'
  exit 3
fi

# The checkout root must sit outside the shared workspace tree — git internals
# inside a synced folder would replicate to the whole team. Physical comparison
# so no indirection evades the rule.
checkout_root_phys="$(cd -- "${checkout_root}" && pwd -P)"
workspace_root_phys="$(cd -- "${workspace_root}" && pwd -P)"
case "${checkout_root_phys}" in
  "${workspace_root_phys}"|"${workspace_root_phys}"/*)
    printf 'The declared repo-checkouts root sits inside the shared workspace tree:\n'
    printf '  %s\n' "${checkout_root}"
    printf 'Git internals must never land in a synced shared tree. Choose a machine-local\n'
    printf 'location and re-declare: ask your agent to run the %s skill.\n' "${setup_skill}"
    exit 3
    ;;
esac

# --- Orientation: where did this session open? ------------------------------
printf -- '-- Where you are --\n'
orient_role=''
if [[ "${launch_dir}" == "${checkout_root}" || "${launch_dir}" == "${checkout_root}"/* ]]; then
  orient_role='checkouts'
  if [[ "${launch_dir}" != "${checkout_root}" ]]; then
    repo="${launch_dir#"${checkout_root}"/}"; repo="${repo%%/*}"
    printf '  Repo-checkouts root, inside checkout: %s (read-only by intent)\n' "${repo}"
    note "Digest (if generated): ${digest_root}/${repo}.md"
  else
    printf '  Repo-checkouts root (machine-local)\n'
  fi
fi
if [[ -z "${orient_role}" ]]; then
  index=1
  for r in "${working_roots[@]}"; do
    if [[ "${launch_dir}" == "${r}" || "${launch_dir}" == "${r}"/* ]]; then
      orient_role='working-materials'
      printf '  Working-materials root %d: %s\n' "${index}" "${r}"
      [[ ${index} -eq 1 ]] && note 'This is the default output destination (first declared working-materials root)'
      break
    fi
    index=$((index + 1))
  done
fi
if [[ -z "${orient_role}" ]]; then
  for r in ${extra_roots[@]+"${extra_roots[@]}"}; do
    if [[ "${launch_dir}" == "${r}" || "${launch_dir}" == "${r}"/* ]]; then
      orient_role='extra'
      printf '  Extra root: %s (informational)\n' "${r}"
      break
    fi
  done
fi
if [[ -z "${orient_role}" ]]; then
  case "${launch_dir}" in
    "${support_root}"|"${support_root}"/*)
      orient_role='support'
      printf '  Agentic support tree (skills, tools, Context Fabric)\n'
      note "Orientation: ${support_root}/README.md"
      ;;
    "${workspace_root}")
      orient_role='workspace-root'
      printf '  Shared workspace root\n'
      note "Orientation: ${workspace_root}/AGENTS.md"
      ;;
    "${workspace_root}"/*)
      orient_role='shared-lane'
      lane="${launch_dir#"${workspace_root}"/}"; lane="${lane%%/*}"
      printf '  Shared workspace lane: %s\n' "${lane}"
      [[ -f "${workspace_root}/${lane}/README.md" ]] && note "Orientation: ${workspace_root}/${lane}/README.md"
      ;;
    *)
      printf '  Not inside any declared root (%s)\n' "${launch_dir}"
      note "Declared roots are listed below; the declaration lives at ${descriptor}"
      ;;
  esac
fi
printf '\n'

# --- Declared roots report ---------------------------------------------------
printf -- '-- Declared roots --\n'
ok "Repo checkouts: ${checkout_root}"
index=1
for r in "${working_roots[@]}"; do
  if [[ ${index} -eq 1 ]]; then
    ok "Working materials ${index}: ${r} (default output destination)"
  else
    ok "Working materials ${index}: ${r}"
  fi
  index=$((index + 1))
done
for r in ${extra_roots[@]+"${extra_roots[@]}"}; do
  note "Extra root (informational): ${r}"
done
printf '\n'

# --- Member-specific harness state must never live in the shared tree -------
# Always flag per-member files. Whole harness-config directories are flagged
# only when the workspace is not git-backed: without a review gate, sync IS the
# distribution channel, so one member's directory reaches everyone silently.
harness_hits=$(find "${workspace_root}" -maxdepth 4 \
  \( -name 'settings.local.json' -o -name '*.code-workspace' \) 2>/dev/null | head -5 || true)
if [[ ! -d "${workspace_root}/.git" ]]; then
  harness_hits+=$'\n'$(find "${workspace_root}" -maxdepth 3 \
    \( -name '.claude' -o -name '.codex' -o -name '.gemini' \) 2>/dev/null | head -5 || true)
fi
harness_hits=$(printf '%s\n' "${harness_hits}" | sed '/^$/d')
if [[ -n "${harness_hits}" ]]; then
  printf 'WARN: member-specific harness state found inside the shared workspace tree:\n'
  printf '%s\n' "${harness_hits}" | while IFS= read -r hit; do
    printf '        %s\n' "${hit}"
  done
  printf '        Harness settings belong in user scope on your machine (see docs/workspace-routing.md).\n'
  printf '        Fix the launch shape too: a session whose PRIMARY folder is a shared synced\n'
  printf '        folder recreates this file every time. Use a machine-local primary folder.\n\n'
fi

# --- Environment probes ---------------------------------------------------
have_git=0; command -v git >/dev/null 2>&1 && have_git=1

checkout_count=0
if [[ -d "${checkout_root}" ]]; then
  while IFS= read -r d; do
    [[ -d "${d}/.git" ]] && checkout_count=$((checkout_count + 1))
  done < <(find "${checkout_root}" -mindepth 1 -maxdepth 1 -type d)
fi

digest_count=0
if [[ -d "${digest_root}" ]]; then
  digest_count=$(find "${digest_root}" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
fi

profile_count=0
if [[ -d "${fabric_root}/records/profiles" ]]; then
  profile_count=$(find "${fabric_root}/records/profiles" -maxdepth 1 -type f -name '*.json' | wc -l | tr -d ' ')
fi

# --- Capability tiers -----------------------------------------------------
printf -- '-- What you can do today --\n'

if [[ -f "${fabric_root}/README.md" ]] && (( profile_count > 0 )); then
  ok "Shared context: Context Fabric reachable, ${profile_count} product profile(s) (no git needed)"
else
  off 'Shared context: Context Fabric has no product profiles yet'
  note "Unlock: author one from ${fabric_root}/templates/profile.template.json (see context-fabric/docs/authoring.md)"
fi

if (( digest_count > 0 )); then
  ok "Repo questions from digests: ${digest_count} repo digest(s) in shared context (no git needed)"
  # Warn (never block) when a hydrated checkout has moved past its digest.
  if (( have_git )); then
    stale_digests=0
    for digest_file in "${digest_root}"/*.md; do
      digest_name=$(basename "${digest_file}" .md)
      [[ "${digest_name}" == "README" ]] && continue
      [[ -d "${checkout_root}/${digest_name}/.git" ]] || continue
      digest_commit=$(sed -n 's/^source_commit: //p' "${digest_file}" | head -1)
      local_commit=$(git -C "${checkout_root}/${digest_name}" rev-parse --short HEAD 2>/dev/null || true)
      if [[ -n "${digest_commit}" && -n "${local_commit}" && "${digest_commit}" != "${local_commit}" ]]; then
        stale_digests=$((stale_digests + 1))
      fi
    done
    if (( stale_digests > 0 )); then
      printf 'WARN: %s digest(s) differ from local checkout commits; regenerate with tools/generate-repo-digests.sh\n' "${stale_digests}"
    fi
  fi
else
  off 'Repo questions from digests: none generated yet'
  note "Unlock: a steward runs tools/generate-repo-digests.sh (output: ${digest_root})"
fi

if (( have_git && checkout_count > 0 )); then
  ok "Checkout inspection: git present, ${checkout_count} checkout(s) hydrated (read-only by intent)"
elif (( have_git )); then
  off 'Checkout inspection: git present but no checkouts hydrated'
  note 'Unlock: run the repo-sync skill against a reviewed sync manifest'
else
  off 'Checkout inspection: git is not installed'
  note 'Unlock: install git (shared context and digests work without it)'
fi

if (( have_git )); then
  ok 'Checkout sync/refresh: git present (fetch and fast-forward only; never pushes)'
  note 'Preview first: tools/refresh-manifest-repos.sh --manifest <path> --checkout-root <path>'
else
  off 'Checkout sync/refresh: needs git'
  note 'Unlock: install git'
fi

if [[ -n "${CREDENTIAL_ENV_VARS}" ]]; then
  for var in ${CREDENTIAL_ENV_VARS}; do
    if [[ -n "${!var:-}" ]]; then
      ok "Credentialed access: ${var} is set for this session"
    else
      off "Credentialed access: ${var} is not loaded"
      [[ -n "${CREDENTIAL_UNLOCK_HINT}" ]] && note "Unlock: ${CREDENTIAL_UNLOCK_HINT}"
    fi
  done
fi
printf '\n'

# --- Skill availability (manifest is the authority) -----------------------
printf -- '-- Skill availability (skills/skill-manifest.yaml) --\n'
today=$(date +%Y-%m-%d)
current_id=''
current_status=''
current_review=''
emit_skill() {
  [[ -n "${current_id}" ]] || return 0
  local line="  ${current_id}: ${current_status}"
  current_review="${current_review//\'/}"
  current_review="${current_review//\"/}"
  if [[ -n "${current_review}" && ! "${current_review}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    line+=' (review date not set — replace the placeholder in skill-manifest.yaml)'
  elif [[ -n "${current_review}" ]]; then
    if [[ "${current_review}" < "${today}" ]]; then
      line+=" (review overdue since ${current_review})"
    else
      line+=" (review by ${current_review})"
    fi
  elif [[ "${current_status}" != "enabled" ]]; then
    line+=' (no review date recorded)'
  fi
  printf '%s\n' "${line}"
}
while IFS= read -r raw; do
  case "${raw}" in
    *'- id:'*)
      emit_skill
      current_id="${raw#*- id: }"; current_status=''; current_review='' ;;
    *'status:'*)    current_status="${raw#*status: }" ;;
    *'review_by:'*) current_review="${raw#*review_by: }" ;;
  esac
done < "${manifest}"
emit_skill
printf '\nReport complete. This probe is read-only; nothing was changed.\n'
