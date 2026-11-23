#!/usr/bin/env bash
# Restore a Postgres dump. Destructive: asks for confirmation.
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

BACKUP_DIR="${BACKUP_DIR:-backups}"

if [[ $# -gt 0 ]]; then
  FILE="$1"
else
  # shellcheck disable=SC2012
  FILE="$(ls -1t "${BACKUP_DIR}"/postgres-*.sql.gz 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${FILE}" || ! -f "${FILE}" ]]; then
  echo "no dump found in ${BACKUP_DIR}" >&2
  exit 1
fi

read -r -p "Restore ${FILE} into ${POSTGRES_DB}? Type 'restore' to continue: " answer
if [[ "${answer}" != "restore" ]]; then
  echo "aborted"
  exit 1
fi

echo "stopping app"
docker compose -f compose/compose.yaml --env-file .env stop app

echo "recreating database ${POSTGRES_DB}"
docker compose -f compose/compose.yaml --env-file .env exec -T postgres \
  dropdb --if-exists -U "${POSTGRES_USER}" "${POSTGRES_DB}"
docker compose -f compose/compose.yaml --env-file .env exec -T postgres \
  createdb -U "${POSTGRES_USER}" -O "${POSTGRES_USER}" "${POSTGRES_DB}"

gunzip -c "${FILE}" | docker compose -f compose/compose.yaml --env-file .env exec -T postgres \
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"

echo "starting app"
docker compose -f compose/compose.yaml --env-file .env start app

echo "restore complete; verify tables and row counts"
