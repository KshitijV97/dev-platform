# Grilling brief

Use this with a grilling session. It is the list of things the current design has **not** settled. Each question includes the context, the realistic options, a recommendation, and what would change it.

Do not treat the recommendation as a decision. A decision becomes real when it is written into `docs/adr/` and the glossary or plan is updated.

## Current proposal

One Oracle Cloud Always Free `VM.Standard.A1.Flex` (2 OCPU / 12 GB) in Toronto or Montreal runs a Docker Compose stack: Caddy, an app, a worker, Postgres, Uptime Kuma, Dozzle, and a scheduler. Static sites live on Cloudflare Pages. CI runs on GitHub Actions and pushes multi-arch images to GHCR. Access is over Tailscale. Backups go to OCI Object Storage. The whole thing must be rebuildable from this repo in under 30 minutes.

## Settled decisions

- ADR-0001: Oracle Always Free is the Phase 1 primary.
- ADR-0002: the ROG laptop is an optional worker, never a dependency (revised 2026-11-22; it becomes reachable around 2026-12-06).
- ADR-0003: static sites go to Cloudflare Pages.
- ADR-0004: single-host Docker Compose, no orchestration.
- ADR-0005: GitHub Issues + Projects is the tracker; FOSS is a preference and the escape hatch is mandatory.
- ADR-0006: `ca-toronto-1` is the home region.
- ADR-0007: Postgres 16 in Docker, with a portability exit to managed Postgres.
- ADR-0008: Ofelia runs scheduled jobs; a Postgres queue drives triggered jobs.
- ADR-0009: external-first observability; no alerting path terminates on the box it monitors.
- ADR-0010: `.env` on the host plus GitHub Actions secrets, with the password manager as the source of truth.
- ADR-0011: one Compose project per client site, capped at 2–3 per host.
- ADR-0012: Cloudflare proxied A record with an Origin Certificate and Full (strict).

## Question status

| Question | Status | Where |
|---|---|---|
| Q1 region | Resolved 2026-11-22 | ADR-0006 |
| Q1b capacity / PAYG | **Open** | below |
| Q2 database | Resolved 2026-11-22 | ADR-0007 |
| Q3 scheduler | Resolved 2026-11-22 | ADR-0008 |
| Q4 queue | Open | round 2 |
| Q5 observability | Resolved 2026-11-22 | ADR-0009 |
| Q6 deploy and rollback | Open | round 2 |
| Q7 secrets | Resolved 2026-11-22 | ADR-0010 |
| Q8 staging | Open | round 2 |
| Q9 client isolation | Resolved 2026-11-22 | ADR-0011 |
| Q10 ingress | Resolved 2026-11-22 | ADR-0012 |
| Q11 backup policy | Open | round 2 |
| Q12 move-off triggers | Open | round 2 |
| Q13 security baseline | Open | round 2 |
| Q14 domain | Partly resolved (`antwater` prefix); buy timing open | below |
| Q15 non-goals | Open | round 2 |
| Q16 tracker and FOSS | Resolved 2026-11-22 | ADR-0005 |
| Q17 ROG role | **Open** | below |

## Open questions

### Q1. Toronto or Montreal? — **resolved 2026-11-22**

**Decision:** `ca-toronto-1`. See ADR-0006.

**Correction to the recommendation below:** "check A1 capacity in both regions, then fall back to Montreal" is not possible. Capacity cannot be measured before an account exists, the home region is fixed at signup, and a second account violates the one-account rule. The choice is a bet on Toronto, with an account upgrade as the only real capacity lever.

### Q1b. Do we upgrade the Oracle account to Pay As You Go?

**Context:** Always Free capacity in Toronto is a lottery, and there is no second-account fallback. Upgrading to PAYG keeps Always Free resources free but makes provisioning far more likely to succeed. The cost is a card on file, which can be charged if anything outside Always Free is ever created.

**Options:** upgrade at signup; stay free-only and retry for days; upgrade only if provisioning fails for 72 hours.

**Recommendation:** upgrade immediately after the tenancy exists, with a budget alarm at $0 and a written rule that nothing outside Always Free is created. Capacity risk is the project's best-known failure mode; buying it out for a card on file is cheap.

**Changes it:** Oracle starts charging for Always Free shapes, or the operator is unwilling to keep a card on file.

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

### Q10. Public IP, Cloudflare proxy, or Tunnel? — **resolved 2026-11-22**

**Decision:** Cloudflare proxied A record, Caddy serving a Cloudflare Origin Certificate, SSL mode Full (strict), UFW allowing 443 only from Cloudflare's published ranges, and Cloudflare Access on admin subdomains. See ADR-0012 for the full comparison and the trade-offs.

**Options:** direct A record + Caddy; Cloudflare proxy + Caddy; Cloudflare Tunnel + Caddy.

**Recommendation (superseded by ADR-0012):** Cloudflare DNS + proxy in Phase 1. Keep the origin firewall closed to everything except Cloudflare ranges if practical. Evaluate Tunnel when the public IP becomes a nuisance or the host moves behind CGNAT.

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

### Q14. What is the domain strategy? — **partly resolved 2026-11-22**

**Decision so far:** the prefix is **`antwater`**. Every hostname derives from it: `antwater.<zone>`, `status.antwater.<zone>`, `logs.antwater.<zone>`. Paying for a domain is deferred.

**Remaining:** when to buy the domain. Recommendation stands: use a free subdomain for Phase 0 drills, buy at the first real client — defined as the first time a person other than the operator is asked to visit the site.

**Changes it:** A client insists on their own domain, which is normal; then the domain belongs to the client.

### Q15. What is explicitly not being built?

**Context:** The fastest way to fail is to build a platform instead of a product.

**Recommendation:** No Kubernetes, no Nomad, no k3s, no multi-region, no custom PaaS, no GPU worker on the critical path, no dual boot, no Android emulator, no self-service portal, no self-hosted tracker while the hosted tier is free. Revisit only with an ADR and a measured need.

**Changes it:** Five or more always-on nodes, or a workload that Compose genuinely cannot run.

### Q16. Which issue tracker, and is FOSS a hard constraint? — **resolved 2026-11-22**

**Decision:** FOSS is a **preference, not a hard constraint**. The hard constraint is the inverse: a proprietary tool must be escapable to a FOSS one without losing work. Recorded in ADR-0005 (Accepted).

GitHub Issues + Projects is the Phase 0/1 tracker. The escape hatch is a requirement, not an aspiration: `make export` snapshots issues, labels, and milestones; one import into a throwaway GitLab or Forgejo project is a Phase 0 acceptance item (iteration-01, issue X2); a tracker-only move must take ≤ 1 week.

If a capability in use moves behind a paid tier, the exit starts immediately, with no further debate.

The options table above is kept for the next time this is revisited.

### Q17. What role does the ROG play? — **open**

**Context:** The ASUS ROG Strix G16 is expected to become reachable around 2026-12-06, about two weeks out. It is Windows 11 with an i9-14900HX and an RTX 4070 Laptop. ADR-0002 already limits it to an optional worker: no unique state, no critical path, no inbound exposure, revocable in one action.

The open part is which role, if any, and on what runtime.

**Options:**

| Role | Value | Risk |
|---|---|---|
| Remote Docker builder (`buildx` + `buildkitd`) | Real build speedup, no state | Low |
| GPU batch workload | Only with a real workload | Medium |
| Second Compose host for a client | Isolation without a VPS | High: it can vanish |
| Primary CI runner | Saves Actions minutes | High: merge path on a laptop |

**Recommendation:** Onboard it as a remote builder only, inside WSL2, joined to the tailnet as `tag:worker`. Do not promote it to a host without an ADR and a backup path for any state it would hold. Never make it a required check.

**Changes it:** A client workload that needs the GPU or more than 2 OCPU sustained, or a second client database that no longer fits the primary.

**Definition of done:** the role is chosen, the runtime is chosen (WSL2, or single-boot Linux if it is ever promoted — never dual boot), the owner's agreement is recorded, and the dependency-guard drill passes with the machine switched off.

## Assumptions to test during Phase 0

- A1 capacity is available in at least one Canadian region.
- 2 OCPU / 12 GB is enough for one app, Postgres, a worker, and monitoring.
- GitHub Actions free minutes cover the build volume.
- Cloudflare Pages can host the static sites without paid features.
- A 30-minute rebuild is achievable with Terraform + cloud-init + Compose.
- Tailscale SSH is reliable enough to replace public SSH.

## What "done" looks like for the grilling

- Every question above is either decided (ADR) or explicitly deferred with a trigger.
- Each open question is tracked as an issue in the `iteration-00: settle decisions` milestone, so none can be quietly forgotten.
- `GLOSSARY.md` contains any new terms the discussion introduced.
- `docs/plans/0001-phase-0-bootstrap.md` reflects the settled decisions.
- No decision lives only in chat.
