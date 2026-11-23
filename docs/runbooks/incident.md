# Incident runbook

## First five minutes

1. Confirm the scope: one service, the whole host, or only DNS/TLS?
2. Check the external uptime monitor and Healthchecks.io.
3. Check `docker compose ps` and `docker compose logs --tail=200`.
4. Check disk: `df -h` and `docker system df`.
5. Write a timestamped note in the incident issue. Do not rely on memory.

## Triage table

| Symptom | Likely cause | First action |
|---|---|---|
| Whole site down, SSH works | Caddy or app crash | `docker compose ps`, restart the failing service |
| Whole host unreachable | Instance stopped, network, or provider issue | Check OCI console; reboot; if gone, start rebuild |
| 502 from Caddy | App container down or wrong port | `docker compose logs app`; check Caddyfile upstream |
| 526/525 from Cloudflare | Origin certificate or port issue | Check Caddy logs and port 443 |
| Disk full | Images, logs, or backups | `docker system prune`, rotate logs, move backups off-box |
| Postgres refuses connections | Disk full, OOM, or corruption | Check logs; free space; restore if corrupt |
| Cron job silent | Scheduler or worker down | Check Healthchecks.io; run the job manually |
| Unexpected process or login | Possible compromise | Snapshot, isolate, rotate secrets, rebuild |

## Specific playbooks

### Host unreachable

1. Check the OCI console: running, stopped, or terminated?
2. If stopped, start it. If terminated or reclaimed, follow `docs/runbooks/rebuild.md`.
3. Check Cloudflare status and DNS.
4. If the public IP changed, update DNS.

### Disk full

```bash
df -h
docker system df
docker image prune -f
docker builder prune -f
sudo journalctl --vacuum-time=7d
```

Do not delete the Postgres volume. Move `backups/` off-box if it is on the root volume.

### Bad deploy

```bash
# In .env, set APP_IMAGE to the previous SHA
docker compose -f compose/compose.yaml --env-file .env up -d
```

If a migration caused the problem, restore the pre-migration dump.

### Suspected compromise

1. Do not keep running the old host.
2. Take a snapshot for forensics.
3. Rotate every secret: SSH keys, Tailscale keys, database password, API tokens, Telegram bot token.
4. Rebuild from IaC, restore data from a known-good backup.
5. Check Cloudflare and GitHub audit logs.

## Communication

- Internal: one issue in the tracker with `type:ops` and `priority:p0`.
- Client-facing: only after facts are confirmed. Use a short status note with impact, start time, and next update.
- Do not speculate about cause in writing.

## After

Write a short postmortem in the issue:

- timeline,
- impact,
- root cause,
- what worked,
- what to change,
- one action with an owner and a date.

If the lesson is durable, capture it with `ce-compound` in `docs/solutions/`.
