# Rebuild runbook

Use this when the primary node is lost, corrupted, or being replaced. Target: under 30 minutes.

## Prerequisites

- Access to the password manager: OCI credentials, Tailscale auth key, `.env`, restic password, object storage keys.
- The latest database dump in object storage.
- This repo cloned locally.
- DNS access at Cloudflare.

## Steps

1. **Snapshot what is left, if possible.**
   ```bash
   ssh deploy@old-host 'docker compose -f /srv/dev-platform/compose/compose.yaml ps'
   ```
   If the host is reachable, run `scripts/backup.sh` before destroying anything.

2. **Provision a new instance.**
   ```bash
   cd infra/oracle
   terraform apply
   ```
   Use the same region and shape. If capacity fails, see `infra/README.md`.

3. **Confirm cloud-init finished.**
   ```bash
   ssh deploy@$(terraform output -raw public_ip) 'cloud-init status --long'
   ```
   Expect `status: done`.

4. **Join Tailscale.**
   If `tailscale_auth_key` was empty:
   ```bash
   ssh deploy@<ip> 'sudo tailscale up --ssh --hostname=dev-platform-1'
   ```
   Then close port 22 to the world and use Tailscale SSH.

5. **Clone the repo and restore `.env`.**
   ```bash
   sudo mkdir -p /srv && sudo chown deploy:deploy /srv
   git clone <repo> /srv/dev-platform
   cd /srv/dev-platform
   # create .env from the password manager, mode 600
   chmod 600 .env
   ```

6. **Start the stack.**
   ```bash
   docker compose -f compose/compose.yaml --env-file .env up -d
   docker compose -f compose/compose.yaml --env-file .env ps
   ```

7. **Restore the database.**
   Follow `docs/runbooks/restore.md`.

8. **Repoint DNS if the public IP changed.**
   Update the Cloudflare A record. Keep TTL low during the change.

9. **Verify.**
   - `curl -I https://<domain>` returns 200 with a valid certificate.
   - `status.<domain>` and `logs.<domain>` load.
   - A scheduled job pings Healthchecks.io.
   - A test issue reaches Telegram.
   - `docker compose ps` shows healthy services.

10. **Record the time.**
    Update the measured rebuild time in this runbook.

## Timing log

| Date | Reason | Time to rebuild | Notes |
|---|---|---|---|
| — | — | — | — |

## Rollback

If the rebuild fails, keep the old instance or boot volume until the new one passes verification. Do not delete the old boot volume until a restore drill succeeds.
