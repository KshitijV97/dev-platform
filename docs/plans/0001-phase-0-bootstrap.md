# Plan 0001: Phase 0 bootstrap

- **Status:** Draft — refine after `grill-with-docs`
- **Date:** 2026-11-22
- **Owner:** Kshitij
- **Related:** `docs/architecture.md`, `docs/adr/`, `docs/grill/brief.md`

## Goal

Stand up one Oracle A1 node in Canada that runs the Compose stack, is reachable over Tailscale, serves a dynamic service over HTTPS, runs a scheduled job with an external dead-man's switch, and can be destroyed and rebuilt from this repo in under 30 minutes.

## Scope

In:

- Oracle tenancy and A1 instance.
- Ubuntu host hardening and Docker.
- Tailscale access.
- Caddy, app, Postgres, worker, Uptime Kuma, Dozzle.
- One static site on Cloudflare Pages.
- Nightly backups to OCI Object Storage.
- GitHub Actions build and deploy.
- External monitoring for one endpoint and one job.
- One rebuild drill and one restore drill.

Out:

- Multiple clients, staging, GPU, Kubernetes, multi-region.
- A custom domain is optional; a free subdomain is acceptable for the drill.

## Assumptions

- Oracle A1 capacity is available in at least one Canadian region.
- The operator can complete Oracle identity verification.
- A GitHub repository, a Cloudflare account, and a Tailscale account exist.
- The app image can build for `linux/arm64`.

## Tasks

### 1. Choose the region and create the tenancy

- [ ] Check A1 availability in `ca-toronto-1` and `ca-montreal-1`.
- [ ] Create one Oracle account with the chosen home region.
- [ ] Enable MFA on the Oracle account.
- [ ] Record the tenancy OCID, compartment OCID, and region in the password manager.

**Verify:** the console shows the chosen home region and the Always Free limits.

### 2. Provision the instance

- [ ] Create a VCN, public subnet, internet gateway, route table, and security list (or apply `infra/oracle/`).
- [ ] Create `VM.Standard.A1.Flex` with 2 OCPU / 12 GB and a 100 GB boot volume.
- [ ] Assign a reserved public IPv4.
- [ ] Confirm SSH access with the bootstrap key.

**Verify:** `ssh ubuntu@<ip>` works; `nproc` reports 2; `free -g` reports ~12 GB.

### 3. Harden the host

- [ ] Create a non-root deploy user with sudo and Docker group membership.
- [ ] Disable password SSH and root login.
- [ ] Enable UFW: deny incoming, allow 22 during bootstrap, 80, 443.
- [ ] Install and enable fail2ban.
- [ ] Enable unattended security upgrades.
- [ ] Add 2 GB swap.
- [ ] Set the timezone to `America/Toronto`.

**Verify:** a second SSH session works; `ufw status` shows the expected rules.

### 4. Join Tailscale and close public SSH

- [ ] Install Tailscale and join the tailnet with a tagged, single-use auth key.
- [ ] Confirm `tailscale status` and MagicDNS.
- [ ] Test `ssh <deploy-user>@dev-platform-1` over Tailscale.
- [ ] Remove the public SSH rule from the security list and UFW.

**Verify:** public port 22 is closed; Tailscale SSH works.

### 5. Install Docker and the stack

- [ ] Install Docker Engine and the Compose plugin.
- [ ] Clone this repo to `/srv/dev-platform`.
- [ ] Create `/srv/dev-platform/.env` from `.env.example`, mode 600.
- [ ] Start `compose/compose.yaml`.
- [ ] Confirm Postgres is healthy and the app responds on the Compose network.

**Verify:** `docker compose ps` shows healthy; `curl -I http://localhost:80` from the host returns 200.

### 6. DNS, TLS, and the first service

- [ ] Point a domain or subdomain at the Oracle public IP through Cloudflare.
- [ ] Set `DOMAIN` in `.env` and reload Caddy.
- [ ] Confirm HTTPS with a valid certificate.
- [ ] Confirm HTTP redirects to HTTPS.

**Verify:** `curl -I https://<domain>` returns 200 with a valid cert; SSL Labs grade A or better.

### 7. Static site

- [ ] Create a Cloudflare Pages project from the site repo.
- [ ] Attach the custom domain or `pages.dev` subdomain.
- [ ] Confirm a deploy and a rollback.

**Verify:** the site loads over HTTPS and survives the Oracle node being stopped.

### 8. Scheduled job and dead-man's switch

- [ ] Add one scheduled job (Ofelia label or cron).
- [ ] Make it write a row or a file and ping Healthchecks.io on success.
- [ ] Configure Healthchecks.io email alerts.
- [ ] Stop the job deliberately and confirm an alert arrives.

**Verify:** alert received within the configured grace period.

### 9. Backups

- [ ] Create an OCI Object Storage bucket and an S3-compatible access key.
- [ ] Configure `restic` with an encrypted repository.
- [ ] Run `scripts/backup.sh` manually.
- [ ] Schedule it nightly.
- [ ] Ping Healthchecks.io on success and on failure.

**Verify:** a snapshot exists in object storage; `restic check` passes.

### 10. Restore drill

- [ ] Restore the latest dump into a scratch database.
- [ ] Compare a row count and a checksum with production.
- [ ] Record the time taken in `docs/runbooks/restore.md`.

**Verify:** restore completes in under 15 minutes; data matches.

### 11. CI and deploy

- [ ] Add a GitHub Actions workflow that builds a multi-arch image and pushes it to GHCR by commit SHA.
- [ ] Add a deploy job that SSHes over Tailscale and runs `scripts/deploy.sh`.
- [ ] Confirm a deploy and a rollback to the previous SHA.

**Verify:** a push to `main` deploys; a bad image is rolled back in one command.

### 12. Monitoring and alerting

- [ ] Add an external uptime check for the public endpoint.
- [ ] Add a TLS expiry check.
- [ ] Add a disk-space alert at 80%.
- [ ] Add a billing/budget alert (even at $0).
- [ ] Add Sentry for application errors.

**Verify:** each alert fires in a test.

### 13. Rebuild drill

- [ ] Destroy the instance (keep the boot volume snapshot).
- [ ] Rebuild from `infra/oracle/` + cloud-init + Compose.
- [ ] Restore the database.
- [ ] Confirm the service is healthy.

**Verify:** end-to-end rebuild under 30 minutes, recorded in `docs/runbooks/rebuild.md`.

### 14. Issue tracker and alert routing

- [ ] Create the label set with `scripts/create-labels.sh`.
- [ ] Confirm the issue templates render and apply the right labels.
- [ ] Create one GitHub Project with the views in `docs/integrations/issue-tracker.md`.
- [ ] Create a Telegram bot, add it to a private channel, and set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.
- [ ] Confirm a new issue reaches Telegram through `issue-notify.yml`.
- [ ] Install the Sentry GitHub integration and confirm one error creates or links an issue.
- [ ] Confirm a CI failure opens or comments on exactly one `source:ci` issue.

**Verify:** a new bug, a client request, and a CI failure each land in the tracker and produce one Telegram message.

### 15. Decide the next phase

- [ ] Review cost, capacity, and incidents after 30 days.
- [ ] Decide whether to stay free, add a warm standby, or upgrade Oracle to PAYG.
- [ ] Record the decision as an ADR.

## Acceptance criteria

- One dynamic service is live over HTTPS on a Canadian Oracle node.
- One static site is live on Cloudflare Pages.
- One scheduled job alerts when it stops.
- A nightly encrypted backup exists off-box.
- A restore drill and a rebuild drill have both passed.
- A deploy and a rollback have both passed.
- One issue tracker is live with templates, labels, Telegram notifications, and CI/Sentry intake.
- `make check` is green in CI.
- Monthly cost is $0, excluding an optional domain.

## Rollback

- **Bad deploy:** redeploy the previous image SHA.
- **Bad host change:** revert the commit, re-run cloud-init, or rebuild the instance.
- **Bad database migration:** restore the pre-migration dump.
- **Abandon Oracle:** rebuild on a paid VPS using the same Compose file and restore the dump.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| A1 capacity unavailable | Medium | Try both regions; retry; consider PAYG |
| Oracle reclaims the instance | Low–medium | Keep workloads active; backups; rebuild drill |
| ARM image missing | Medium | Multi-arch build in CI from day one |
| Backup restore fails | Low | Monthly restore drill |
| Scope creep into platform work | High | ADR required for orchestration; timebox Phase 0 |

## Definition of done

- All acceptance criteria pass.
- `docs/runbooks/rebuild.md` and `restore.md` contain measured times.
- `docs/architecture.md` matches reality.
- Open decisions in `docs/grill/brief.md` are resolved or explicitly deferred.
