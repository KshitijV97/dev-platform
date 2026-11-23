# Architecture decisions

| ID | Title | Status |
|---|---|---|
| [0001](0001-oracle-always-free-primary.md) | Oracle Always Free A1 as the Phase 1 primary | Accepted |
| [0002](0002-no-rog-worker.md) | The ROG laptop is an optional worker, never a dependency | Accepted |
| [0003](0003-static-sites-cloudflare-pages.md) | Static sites on Cloudflare Pages | Proposed |
| [0004](0004-single-host-compose.md) | Single-host Docker Compose, no orchestration | Proposed |
| [0005](0005-issue-tracker.md) | Unified issue tracker, with a mandatory FOSS escape hatch | Accepted |
| [0006](0006-toronto-home-region.md) | Toronto as the Oracle home region | Accepted |
| [0007](0007-postgres-in-docker.md) | Postgres 16 in Docker, with a portability exit | Accepted |
| [0008](0008-ofelia-scheduler.md) | Ofelia for scheduled jobs | Accepted |
| [0009](0009-external-first-observability.md) | External-first observability | Accepted |
| [0010](0010-secrets-management.md) | Secrets in `.env` and GitHub Actions secrets | Accepted |
| [0011](0011-one-compose-project-per-client.md) | One Compose project per client site | Accepted |
| [0012](0012-cloudflare-proxied-origin-cert.md) | Cloudflare proxied A record with an Origin Certificate | Accepted |

A decision that is hard to reverse, surprising without context, and a real trade-off gets an ADR. Keep the table current when a status changes.
