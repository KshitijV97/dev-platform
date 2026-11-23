# dev-platform

A zero-cost-first, Canadian platform for Dockerized web services, static sites, and scheduled jobs. It is designed to move to a paid VPS or managed cloud without a rewrite.

**Status: design phase.** Nothing is deployed. `infra/` and `compose/` are scaffolds to validate in Phase 0. Decisions live in `docs/adr/`; unresolved questions live in `docs/grill/brief.md`.

## Why this exists

The development machine is a MacBook Air M1 with 8 GB RAM and a 256 GB disk. It is a good thin client and a poor build server. This repo defines the smallest execution platform that:

- costs **$0** for the first few months,
- runs in **Canada**,
- handles Dockerized web services and scheduled/triggered jobs,
- has free logging, alerting, and backups,
- can move to a paid VPS or managed cloud later.

## Shape

```mermaid
flowchart LR
  Mac[MacBook Air<br/>thin client] -->|Tailscale| A1[Oracle A1<br/>2 OCPU / 12 GB<br/>Toronto or Montreal]
  Mac -->|git push| GH[GitHub<br/>Actions + GHCR]
  A1 --> PG[(Postgres)]
  A1 --> Jobs[Scheduled / triggered jobs]
  CF[Cloudflare<br/>DNS + Pages] --> Sites[Static sites]
  A1 -.->|migrate| Cloud[Cloud Run / paid VPS]
```

- **Primary node:** Oracle Cloud Always Free `VM.Standard.A1.Flex`, 2 OCPU / 12 GB, Ubuntu 24.04, Docker Compose.
- **Static sites:** Cloudflare Pages (free, unlimited bandwidth).
- **CI:** GitHub Actions (2,000 private minutes/month) + GHCR.
- **Access:** Tailscale; no public SSH after bootstrap.
- **Observability:** Uptime Kuma + Dozzle on the box, Healthchecks.io outside it, Sentry free for app errors.
- **State:** Git, Postgres volume + nightly dumps, OCI Object Storage (S3-compatible, 20 GB free).
- **Unified tracker:** GitHub Issues + Projects, with Telegram notifications and a documented FOSS exit.

## Cost

| Item | Phase 1 (hobby) | Phase 2 (client) |
|---|---|---|
| Compute | $0 (Oracle Always Free) | $0–6/mo (Oracle or small VPS) |
| Static hosting | $0 (Cloudflare Pages) | $0 |
| CI | $0 (GitHub Free) | $0–12/mo |
| Monitoring | $0 (free tiers) | $0–20/mo |
| Domain | $0 (provider subdomain) or ~$12/yr | ~$12/yr |
| Database | $0 (Postgres in Docker) | $0 (Neon/Supabase free) → paid |

## Read this first

1. `STRATEGY.md` — what this is for and how it evolves.
2. `docs/architecture.md` — the current design and failure modes.
3. `docs/grill/brief.md` — the questions to settle before building.
4. `docs/plans/0001-phase-0-bootstrap.md` — the first implementation plan.
5. `docs/integrations/issue-tracker.md` — intake, labels, and alert routing.
6. `GLOSSARY.md` and `docs/adr/` — vocabulary and decisions.

## Working in this repo

- `grill-with-docs` → settle open questions; it writes ADRs and updates `GLOSSARY.md`.
- Compound Engineering → run `/ce-setup` once per checkout, then `ce-brainstorm` / `ce-plan` / `ce-work` / `ce-compound`; plans live in `docs/plans/`, learnings in `docs/solutions/`.
- `make labels` → create the issue labels used by the templates.
- `make check` → validate Compose, Terraform formatting, and shell scripts.
- `make up` / `make down` / `make logs` → run the local stack (requires `.env`).

## Issue tracking

One queue for bugs, features, client requests, CI failures, and Sentry errors: **GitHub Issues + Projects**. Templates and labels live in `.github/` and `scripts/create-labels.sh`. Telegram notifications are wired through `.github/workflows/issue-notify.yml`. The FOSS exit — GitLab Free or self-hosted Forgejo/Plane — is documented in ADR-0005.

This is the one deliberate exception to the FOSS preference, because the code and CI already live on GitHub. If FOSS is a hard constraint, read the GitLab option in `docs/integrations/issue-tracker.md` before adopting it.

## Non-goals (for now)

- A Kubernetes or Nomad "swarm" across free-tier accounts.
- The ROG laptop as a worker (no physical access; see ADR-0002).
- Windows or dual-boot.
- Android emulators.
- Multi-region or high availability.
