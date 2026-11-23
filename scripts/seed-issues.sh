#!/usr/bin/env bash
# Create iteration milestones and their issues from docs/iterations/manifest.json.
# Idempotent: existing milestones and issues are matched on exact title.
#
# Usage:
#   ./scripts/seed-issues.sh
#   DRY_RUN=1 ./scripts/seed-issues.sh
#   REPO=owner/name ./scripts/seed-issues.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

MANIFEST="${MANIFEST:-docs/iterations/manifest.json}"
DRY_RUN="${DRY_RUN:-0}"

command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

if [[ ! -f "${MANIFEST}" ]]; then
  echo "manifest not found: ${MANIFEST}" >&2
  exit 1
fi

jq -e . "${MANIFEST}" >/dev/null || { echo "${MANIFEST} is not valid JSON" >&2; exit 1; }

REPO="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
echo "repository: ${REPO}"
echo "manifest:   ${MANIFEST}"
[[ "${DRY_RUN}" == "1" ]] && echo "mode:       dry run"

# --- milestones ---------------------------------------------------------------

existing_milestones="$(gh api "repos/${REPO}/milestones?state=all&per_page=100" --jq '.[].title')"

while IFS=$'\t' read -r title description; do
  [[ -z "${title}" ]] && continue

  if printf '%s\n' "${existing_milestones}" | grep -Fxq -- "${title}"; then
    echo "milestone exists: ${title}"
    continue
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "would create milestone: ${title}"
    continue
  fi

  gh api "repos/${REPO}/milestones" \
    -f title="${title}" \
    -f description="${description}" \
    -f state=open >/dev/null
  echo "milestone created: ${title}"
done < <(jq -r '.milestones[] | [.title, .description] | @tsv' "${MANIFEST}")

# --- issues -------------------------------------------------------------------

existing_titles="$(gh issue list --repo "${REPO}" --state all --limit 1000 --json title --jq '.[].title')"

created=0
skipped=0

while IFS= read -r issue; do
  title="$(jq -r '.title' <<<"${issue}")"
  milestone="$(jq -r '.milestone' <<<"${issue}")"
  summary="$(jq -r '.summary' <<<"${issue}")"
  source="$(jq -r '.source' <<<"${issue}")"
  labels=()
  while IFS= read -r label; do
    labels+=("${label}")
  done < <(jq -r '.labels[]' <<<"${issue}")

  if printf '%s\n' "${existing_titles}" | grep -Fxq -- "${title}"; then
    echo "issue exists:   ${title}"
    skipped=$((skipped + 1))
    continue
  fi

  body="$(
    printf '## What\n\n%s\n\n' "${summary}"
    printf '## Done when\n\n'
    while IFS= read -r line; do
      printf -- '- [ ] %s\n' "${line}"
    done < <(jq -r '.acceptance[]' <<<"${issue}")
    # shellcheck disable=SC2016
    printf '\n## Source\n\n`%s`\n\n' "${source}"
    # shellcheck disable=SC2016
    printf 'Part of milestone **%s**. Close it, or carry it forward with a recorded reason, before the iteration retro. See `docs/iterations/README.md`.\n' "${milestone}"
  )"

  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "would create issue: ${title}  [${milestone}]"
    created=$((created + 1))
    continue
  fi

  label_args=()
  for label in "${labels[@]}"; do
    label_args+=(--label "${label}")
  done

  gh issue create \
    --repo "${REPO}" \
    --title "${title}" \
    --body "${body}" \
    --milestone "${milestone}" \
    "${label_args[@]}" >/dev/null

  echo "issue created:  ${title}"
  created=$((created + 1))
done < <(jq -c '.issues[]' "${MANIFEST}")

echo
echo "created ${created}, already present ${skipped}"
