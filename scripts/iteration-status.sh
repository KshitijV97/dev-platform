#!/usr/bin/env bash
# Report progress per iteration milestone, and gate the retro.
#
# Milestones marked "optional": true in the manifest are reported but never gate
# a retro. That is how optional capacity (iteration-02) stays out of the way.
#
# Usage:
#   ./scripts/iteration-status.sh
#   ./scripts/iteration-status.sh --check
#   ./scripts/iteration-status.sh --check "iteration-01: phase 0 bootstrap"
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

MANIFEST="${MANIFEST:-docs/iterations/manifest.json}"

command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

check=0
if [[ "${1:-}" == "--check" ]]; then
  check=1
  shift
fi

REPO="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"

titles=()
optional=()

if [[ $# -gt 0 ]]; then
  titles=("$1")
  optional=("false")
elif [[ -f "${MANIFEST}" ]]; then
  while IFS=$'\t' read -r title opt; do
    titles+=("${title}")
    optional+=("${opt:-false}")
  done < <(jq -r '.milestones[] | [.title, (.optional // false)] | @tsv' "${MANIFEST}")
else
  while IFS= read -r title; do
    titles+=("${title}")
    optional+=("false")
  done < <(gh api "repos/${REPO}/milestones?state=open&per_page=100" --jq '.[].title')
fi

if [[ ${#titles[@]} -eq 0 ]]; then
  echo "no iterations found; run ./scripts/seed-issues.sh" >&2
  exit 1
fi

printf '%-40s %6s %6s %6s  %s\n' "ITERATION" "OPEN" "DONE" "TOTAL" "GATE"
blocked=0

for i in "${!titles[@]}"; do
  milestone="${titles[$i]}"
  is_optional="${optional[$i]}"

  issues="$(gh issue list --repo "${REPO}" --milestone "${milestone}" \
    --state all --limit 500 --json number,state,title 2>/dev/null || echo '[]')"

  total="$(jq 'length' <<<"${issues}")"
  open_n="$(jq '[.[] | select(.state == "OPEN")] | length' <<<"${issues}")"
  closed_n="$(jq '[.[] | select(.state == "CLOSED")] | length' <<<"${issues}")"

  gate="required"
  [[ "${is_optional}" == "true" ]] && gate="optional"

  printf '%-40s %6s %6s %6s  %s\n' "${milestone}" "${open_n}" "${closed_n}" "${total}" "${gate}"

  if [[ "${open_n}" -gt 0 ]]; then
    jq -r '.[] | select(.state == "OPEN") | "  open  #\(.number)  \(.title)"' <<<"${issues}"
    if [[ "${check}" == "1" && "${is_optional}" != "true" ]]; then
      blocked=$((blocked + 1))
    fi
  fi
done

if [[ "${check}" == "1" ]]; then
  if [[ "${blocked}" -gt 0 ]]; then
    echo
    echo "retro gate: ${blocked} required iteration(s) still have open issues." >&2
    echo "Close them, or carry at most two with a 'carry-over:' reason, then re-run." >&2
    exit 1
  fi
  echo
  echo "retro gate: every required iteration is closed."
fi
