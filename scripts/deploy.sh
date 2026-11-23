#!/usr/bin/env bash
# Pull the configured images and restart the stack.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f .env ]]; then
  echo ".env is missing" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

PREVIOUS_IMAGE="$(grep -E '^APP_IMAGE=' .env | cut -d= -f2- || true)"
echo "previous APP_IMAGE: ${PREVIOUS_IMAGE:-unset}"

docker compose -f compose/compose.yaml --env-file .env pull
docker compose -f compose/compose.yaml --env-file .env up -d --remove-orphans

sleep 5
docker compose -f compose/compose.yaml --env-file .env ps

if [[ -n "${DOMAIN:-}" ]]; then
  if ! curl -fsS -o /dev/null -m 15 "https://${DOMAIN}"; then
    echo "health check failed for https://${DOMAIN}" >&2
    echo "roll back by setting APP_IMAGE to ${PREVIOUS_IMAGE:-the previous tag} and re-running" >&2
    exit 1
  fi
fi

echo "deploy complete"
