#!/usr/bin/env bash
# Export every issue, label, and milestone to a dated JSON snapshot.
#
# This is the tracker half of the escape hatch in ADR-0005. Run it before client
# work starts and before trusting any vendor's free tier.
#
# Usage:
#   ./scripts/export-issues.sh
#   OUT_DIR=exports/mine ./scripts/export-issues.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

REPO="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${OUT_DIR:-exports/${STAMP}}"

mkdir -p "${OUT_DIR}"

echo "repository: ${REPO}"
echo "output:     ${OUT_DIR}"

# Issues, including closed ones. Comments are fetched separately per issue only
# when needed; the body and metadata are what a migration requires.
gh issue list --repo "${REPO}" --state all --limit 1000 \
  --json number,title,body,state,stateReason,labels,milestone,author,assignees,createdAt,closedAt,url \
  >"${OUT_DIR}/issues.json"

gh label list --repo "${REPO}" --limit 200 --json name,description,color \
  >"${OUT_DIR}/labels.json"

gh api "repos/${REPO}/milestones?state=all&per_page=100" \
  --jq '[.[] | {number, title, description, state, due_on, created_at, closed_at}]' \
  >"${OUT_DIR}/milestones.json"

jq -n \
  --arg repo "${REPO}" \
  --arg exported "${STAMP}" \
  --argjson issues "$(jq 'length' "${OUT_DIR}/issues.json")" \
  --argjson labels "$(jq 'length' "${OUT_DIR}/labels.json")" \
  --argjson milestones "$(jq 'length' "${OUT_DIR}/milestones.json")" \
  '{repository: $repo, exported_at: $exported, counts: {issues: $issues, labels: $labels, milestones: $milestones}}' \
  >"${OUT_DIR}/summary.json"

cat "${OUT_DIR}/summary.json"

cat <<'EOF'

Next: import into a throwaway GitLab or Forgejo project and confirm that titles,
bodies, states, labels, and milestones survive. Record the outcome in the
iteration-02 escape-hatch issue. Keep the original number in the body as
`legacy-id: N` when re-creating issues elsewhere.

Note: comments are not in this export. Fetch them per issue with
`gh api repos/{owner}/{repo}/issues/{n}/comments` when a migration needs them.
EOF
