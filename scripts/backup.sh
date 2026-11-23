#!/usr/bin/env bash
# Dump Postgres and optionally push the dump to a restic repository.
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
mkdir -p "${BACKUP_DIR}"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DUMP="${BACKUP_DIR}/postgres-${STAMP}.sql.gz"

docker compose -f compose/compose.yaml --env-file .env exec -T postgres \
  pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" | gzip > "${DUMP}"

if [[ -n "${RESTIC_REPOSITORY:-}" ]]; then
  if ! command -v restic >/dev/null 2>&1; then
    echo "RESTIC_REPOSITORY is set but restic is not installed" >&2
    exit 1
  fi
  restic backup "${DUMP}" --tag postgres
  restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune
else
  echo "RESTIC_REPOSITORY is empty; dump kept locally only" >&2
fi

find "${BACKUP_DIR}" -type f -name 'postgres-*.sql.gz' -mtime +7 -delete

if [[ -n "${HEALTHCHECKS_PING_URL:-}" ]]; then
  curl -fsS -m 10 "${HEALTHCHECKS_PING_URL}" >/dev/null || true
fi

echo "backup written to ${DUMP}"
