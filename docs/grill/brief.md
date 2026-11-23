# Grilling brief

Use this with `grill-with-docs`. It is the list of things the current design has **not** settled. Each question includes the context, the realistic options, a recommendation, and what would change it.

Do not treat the recommendation as a decision. A decision becomes real when it is written into `docs/adr/` and the glossary or plan is updated.

## Current proposal

One Oracle Cloud Always Free `VM.Standard.A1.Flex` (2 OCPU / 12 GB) in Toronto or Montreal runs a Docker Compose stack: Caddy, an app, a worker, Postgres, Uptime Kuma, Dozzle, and a scheduler. Static sites live on Cloudflare Pages. CI runs on GitHub Actions and pushes multi-arch images to GHCR. Access is over Tailscale. Backups go to OCI Object Storage. The whole thing must be rebuildable from this repo in under 30 minutes.

## Settled decisions

- ADR-0001: Oracle Always Free is the Phase 1 primary.
- ADR-0002: the ROG laptop is out of scope.
- ADR-0003: static sites go to Cloudflare Pages.
- ADR-0004: single-host Docker Compose, no orchestration.

## Open questions

### Q1. Toronto or Montreal?

**Context:** The OCI home region is permanent. Both regions are in Canada and both have one availability domain. A1 capacity is the constraint, not feature parity.

**Options:** `ca-toronto-1` (lower latency if the operator and clients are in Ontario), `ca-montreal-1` (often better capacity).

**Recommendation:** Prefer Toronto for latency. At signup, check A1 capacity in both; if Toronto is exhausted, take Montreal. Do not create two accounts to get both.

**Changes it:** A client requirement for Quebec data residency, or sustained capacity failures in one region.

### Q2. Is Postgres in Docker the right Phase 1 database?

**Context:** 12 GB fits a small Postgres comfortably. A managed free tier adds a network hop, cold starts (Supabase pauses), and a second vendor.

**Options:** Postgres container with nightly dumps; managed free Postgres (Neon/Supabase); SQLite for small sites.

**Recommendation:** Postgres in Docker for Phase 1, with dumps and a tested restore. Move to managed Postgres at the first client that needs an SLA or point-in-time recovery.

**Changes it:** A client requires PITR, or the dump/restore drill cannot meet a 1-hour RTO.

### Q3. What runs the scheduler?

**Context:** Scheduled jobs and triggered jobs have different failure modes. Cron on the host is simple but invisible; an in-app queue is more code but more reliable.

**Options:** host cron + `docker compose run`; Ofelia labels; app-level scheduler; GitHub Actions scheduled workflows.

**Recommendation:** Ofelia for scheduled containers, with every job pinging Healthchecks.io. Use a Postgres-backed queue for triggered jobs. Do not use GitHub Actions as the primary scheduler; schedules can be delayed and minutes are finite.

**Changes it:** Jobs need sub-minute precision, distributed workers, or exactly-once semantics.

### Q4. How should triggered jobs be queued?

**Context:** The stack is small. Redis is another service to back up and monitor; Postgres is already there.

**Options:** Postgres queue (`SKIP LOCKED`, pg-boss, Procrastinate), Redis + BullMQ/Celery/RQ, cloud queue (SQS/Cloud Tasks).

**Recommendation:** Postgres-backed queue first. It preserves job state through restarts and keeps the backup story to one database.

**Changes it:** Sustained throughput makes `SKIP LOCKED` contention visible, or jobs need fan-out beyond one worker.

### Q5. What is the observability stack?

**Context:** Free logging and alerting is a hard requirement. Self-hosted monitoring dies with the host, so at least one check must be external.

**Options:**

| Layer | Option A (light) | Option B (centralized) |
|---|---|---|
| Logs | Dozzle + `docker logs` | Grafana Cloud free (50 GB logs, 14-day retention) |
| Uptime | Uptime Kuma on-box + Healthchecks.io off-box | Better Stack free |
| Errors | Sentry Developer (5k errors/month) | Sentry |
| Metrics | Docker stats + OCI monitoring | Grafana Cloud (10k series) |

**Recommendation:** Start with A: Dozzle, Uptime Kuma, Healthchecks.io, Sentry. Add Grafana Cloud only when log retention or cross-service search is needed. Every scheduled job and every public endpoint gets an external check.

**Changes it:** More than a handful of services, or a client asks for retained logs or a status page.

### Q6. How do deploys and rollbacks work?

**Context:** A single host can deploy by pulling an image and restarting. The risk is a bad image or a migration that cannot be reversed.

**Options:** GitHub Actions → SSH → `deploy.sh`; Watchtower; a GitOps agent (e.g., Argo CD); manual `docker compose pull`.

**Recommendation:** GitHub Actions builds a multi-arch image by commit SHA, then SSHes over Tailscale and runs `deploy.sh`. Keep the previous SHA. Migrations are a separate step, after a backup. No Watchtower in production.

**Changes it:** More than one host, or a need for canary/blue-green deploys.

### Q7. Where do secrets live?

**Context:** One operator, one host, a handful of services.

**Options:** `.env` on the host (mode 600) + GitHub Secrets; SOPS/age in the repo; a managed secret store (Infisical, Doppler, OCI Vault).

**Recommendation:** `.env` on the host plus GitHub Secrets for CI in Phase 1. Document rotation. Move to SOPS or OCI Vault before a second operator or a client handover.

**Changes it:** A second operator, a compliance requirement, or more than ~20 secrets.

### Q8. Is there a staging environment?

**Context:** 12 GB can hold a second small stack, but not a second full database plus app plus monitoring.

**Options:** no persistent staging; a second Compose project with a separate DB; ephemeral preview per PR on Cloud Run; a $5 VPS.

**Recommendation:** No persistent staging in Phase 1. Use local Compose and CI for tests. Add a small staging stack only when a client change needs review before production.

**Changes it:** First client work, or a change that cannot be validated locally.

### Q9. How are clients isolated?

**Context:** Multiple client sites on one host can share Caddy and Postgres, but not trust boundaries.

**Options:** one Compose project per client with its own DB and network; one shared app with tenant schemas; one VPS per client.

**Recommendation:** One Compose project per client, separate database and database user, separate subdomain. Share only Caddy and the host. Cap at 2–3 small clients before moving.

**Changes it:** A client requires dedicated infrastructure or a compliance boundary.

### Q10. Public IP, Cloudflare proxy, or Tunnel?

**Context:** Caddy needs ports 80/443. Cloudflare proxy hides the origin; a Tunnel removes the inbound ports entirely.

**Options:** direct A record + Caddy; Cloudflare proxy + Caddy; Cloudflare Tunnel + Caddy.

**Recommendation:** Cloudflare DNS + proxy in Phase 1. Keep the origin firewall closed to everything except Cloudflare ranges if practical. Evaluate Tunnel when the public IP becomes a nuisance or the host moves behind CGNAT.

**Changes it:** Cloudflare becomes unacceptable for a client, or Tunnel adds a failure mode you cannot monitor.

### Q11. What is the backup and restore policy?

**Context:** The database is the only irreplaceable state on the host. Container images are reproducible; volumes are not.

**Options:** nightly `pg_dump` + restic; continuous WAL archiving (pgBackRest); managed Postgres PITR.

**Recommendation:** Nightly `pg_dump`, restic to OCI Object Storage, 7 daily / 4 weekly / 3 monthly, monthly restore drill. Document RPO 24 h and RTO 1 h. Do not claim better than that.

**Changes it:** Client work with a tighter RPO, or a database too large for nightly dumps.

### Q12. What triggers the move off Oracle?

**Context:** "Free until it isn't" is not a plan. The move should be triggered by evidence, not vibes.

**Options:** fixed date; usage thresholds; client requirement; provider change.

**Recommendation:** Move when any of these is true: sustained CPU > 70%, memory > 80%, a client SLA, more than one stateful client DB, egress > 1 TB/month, or two reclaim/capacity incidents in a quarter. Record the trigger and the target in an ADR when it fires.

**Changes it:** A provider announces a free-tier change; treat that as an immediate trigger.

### Q13. What is the security baseline?

**Context:** A public VPS with Docker is a target. The free tier does not include a managed WAF.

**Options:** UFW + fail2ban + Tailscale; Cloudflare WAF; CrowdSec; no public SSH.

**Recommendation:** UFW default deny, 80/443 only, SSH closed after Tailscale is working. Unattended security upgrades. Cloudflare proxy in front. No root containers where avoidable. Sentry PII scrubbing on.

**Changes it:** A client requires an audit log, SSO, or a compliance certification.

### Q14. What is the domain strategy?

**Context:** A domain is the only likely Phase 1 cost. Free subdomains exist but look unprofessional for client work.

**Options:** `*.duckdns.org` or similar; a cheap `.dev`/`.ca` domain; Cloudflare Registrar at cost.

**Recommendation:** Use a free subdomain until the first client, then buy one domain at cost and put it on Cloudflare. Keep DNS TTL low during migrations.

**Changes it:** A client insists on their own domain, which is normal; then the domain belongs to the client.

### Q15. What is explicitly not being built?

**Context:** The fastest way to fail is to build a platform instead of a product.

**Recommendation:** No Kubernetes, no Nomad, no k3s, no multi-region, no custom PaaS, no GPU worker, no Windows, no Android emulator, no self-service portal. Revisit only with an ADR and a measured need.

**Changes it:** Five or more always-on nodes, or a workload that Compose genuinely cannot run.

### Q16. Which issue tracker, and is FOSS a hard constraint?

**Context:** The tracker must have a generous free tier, a good REST API, Telegram, email, repository links, and CI/CD links. The operator prefers FOSS but is willing to use a hosted service for now.

**Options:**

| Option | Fit | Tradeoff |
|---|---|---|
| GitHub Issues + Projects | Best native repo/CI integration; unlimited issues; REST + GraphQL | Proprietary |
| GitLab Free | FOSS-open-core; native Telegram, REST, repos, CI | 5 users, 400 CI min; move or mirror the repo |
| Plane Cloud | AGPL; 12 users; REST + webhooks | GitHub/GitLab/Sentry integrations are paid; Telegram needs a bridge |
| Huly Cloud | EPL; unlimited users, 10 GB; native Telegram and GitHub sync | API is SDK-first, not REST-first; heavy self-host |
| YouTrack Free | 10 users, 30 GB; excellent REST; GitHub/GitLab | Proprietary |

**Recommendation:** GitHub Issues + Projects for Phase 0/1, as a deliberate, reversible exception to the FOSS preference. The code, PRs, checks, Dependabot, and Sentry already live on GitHub; a separate tracker adds a second platform and a sync problem during the $0 phase.

If FOSS is a hard constraint, choose **GitLab Free** now. It is the only hosted option that natively covers issues, repos, CI, REST, and Telegram.

**Changes it:** FOSS becomes non-negotiable; a client needs a branded portal or guest access; GitHub changes its free-tier terms; CI outgrows the included minutes.

## Assumptions to test during Phase 0

- A1 capacity is available in at least one Canadian region.
- 2 OCPU / 12 GB is enough for one app, Postgres, a worker, and monitoring.
- GitHub Actions free minutes cover the build volume.
- Cloudflare Pages can host the static sites without paid features.
- A 30-minute rebuild is achievable with Terraform + cloud-init + Compose.
- Tailscale SSH is reliable enough to replace public SSH.

## What "done" looks like for the grilling

- Every question above is either decided (ADR) or explicitly deferred with a trigger.
- `GLOSSARY.md` contains any new terms the discussion introduced.
- `docs/plans/0001-phase-0-bootstrap.md` reflects the settled decisions.
- No decision lives only in chat.
