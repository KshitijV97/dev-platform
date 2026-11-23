#!/usr/bin/env bash
# Create or update the labels used by the issue templates and automation.
# Requires: gh, authenticated against the target repository.
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required" >&2
  exit 1
fi

labels=(
  "type:bug|Something is broken|d73a4a"
  "type:feature|New capability or improvement|0e8a16"
  "type:client|Client-requested work|5319e7"
  "type:ops|Infrastructure or reliability work|fbca04"
  "type:docs|Documentation|0075ca"
  "priority:p0|Drop everything|b60205"
  "priority:p1|Do next|d93f0b"
  "priority:p2|Scheduled|fbca04"
  "priority:p3|Someday|cfd3d7"
  "status:triage|Needs triage|ededed"
  "status:blocked|Blocked|000000"
  "status:waiting-client|Waiting on client|bfd4f2"
  "source:ci|Created by CI|1d76db"
  "source:sentry|Created by Sentry|6f42c1"
  "source:telegram|Created from Telegram|229ed9"
  "source:email|Created from email|006b75"
  "area:infra|Platform and infrastructure|0052cc"
  "area:app|Application code|1d76db"
  "area:docs|Documentation and runbooks|0075ca"
  "size:s|Small|0e8a16"
  "size:m|Medium|fbca04"
  "size:l|Large|d93f0b"
)

for entry in "${labels[@]}"; do
  IFS='|' read -r name description color <<< "${entry}"
  gh label create "${name}" \
    --description "${description}" \
    --color "${color}" \
    --force >/dev/null
  echo "label ${name}"
done

echo "done"
