# Restore runbook

Target: restore the database in under 15 minutes, with a documented data-loss window.

## Database restore

1. **Pick the dump.**
   ```bash
   ls -lh backups/postgres-*.sql.gz
   ```
   Or list restic snapshots:
   ```bash
   restic snapshots --tag postgres
   ```

2. **Restore the dump into a scratch database first.**
   ```bash
   docker compose -f compose/compose.yaml --env-file .env exec -T postgres \
     createdb -U "$POSTGRES_USER" restore_check
   gunzip -c backups/postgres-<stamp>.sql.gz \
     | docker compose -f compose/compose.yaml --env-file .env exec -T postgres \
         psql -U "$POSTGRES_USER" -d restore_check
   ```

3. **Verify the scratch copy.**
   ```bash
   docker compose -f compose/compose.yaml --env-file .env exec -T postgres \
     psql -U "$POSTGRES_USER" -d restore_check -c '\dt'
   ```
   Compare a row count and a recent timestamp with the source. Drop the scratch database when done:
   ```bash
   docker compose -f compose/compose.yaml --env-file .env exec -T postgres \
     dropdb -U "$POSTGRES_USER" restore_check
   ```

4. **Restore for real.**
   ```bash
   ./scripts/restore.sh backups/postgres-<stamp>.sql.gz
   ```
   The script stops the app, recreates `POSTGRES_DB`, restores, and starts the app again.

5. **Check the app.**
   `curl -I https://<domain>` and one authenticated read path.

## Volume restore

If a non-database volume is lost, restore it from the restic snapshot into a temporary directory, then copy it into the volume:

```bash
restic restore latest --target /tmp/restore --path /srv/dev-platform
docker run --rm -v dev-platform_<volume>:/target -v /tmp/restore:/source alpine \
  sh -c 'cp -a /source/. /target/'
```

Stop the service before replacing its volume.

## Verification checklist

- [ ] Database accepts connections.
- [ ] Expected tables and row counts exist.
- [ ] The app serves a 200 on a real route.
- [ ] A scheduled job runs and pings Healthchecks.io.
- [ ] The restore time is recorded below.

## Timing log

| Date | Dump timestamp | Restore time | Data loss | Notes |
|---|---|---|---|---|
| — | — | — | — | — |

## If the restore fails

1. Do not delete the failed target.
2. Try the previous daily dump.
3. If both fail, check `restic check` and the object storage bucket.
4. Escalate by writing an incident note in `docs/runbooks/incident.md`.
