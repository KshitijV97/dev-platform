# ADR-0011: One Compose project per client

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** ADR-0004, `docs/grill/brief.md` Q9

## Context

Client work will put more than one site on the primary node. Sharing Caddy and the host is obviously fine. Sharing a database, a database user, or an application process is a trust boundary, and trust boundaries that are not enforced by the platform are enforced by hope.

The vocabulary needed sharpening first: **Client** is the engagement (a person or company that pays). **Client site** is a deployment — one running stack serving one domain. They are not the same thing, and "client isolation" was ambiguous because of it.

## Decision

**One Compose project per client site**, with:

- its own `compose.yaml` and project name (`antwater-<client-slug>`),
- its own Postgres database and its own database user, not a shared superuser,
- its own subdomain, `Caddyfile` block, and TLS certificate,
- its own `.env` and its own backup set.

Shared on the host: Caddy, the Docker daemon, the OS, the Tailscale tailnet. Nothing else.

Cap: **2–3 small client sites per host** before moving to a second node.

## Consequences

**Positive**

- A bug or injection in one site cannot read another's tables, because it has no credentials for them.
- A client can be backed up, restored, or deleted as one unit.
- A client can be handed over or migrated by copying one directory and one dump.
- Resource limits can be set per project.

**Negative**

- More files, more `.env` files, more certificates to watch.
- Each site carries its own Postgres instance or shares one cluster with separate databases — the latter saves memory and is the Phase 1 default.
- Deleting a client site is a deliberate, scripted action with a backup step, not a `docker compose down`.
- The 2–3 cap is a judgment, not a measurement.

**Mitigations**

- A `clients/<slug>/` directory convention, so a site is one directory plus one database.
- A per-client backup job in Ofelia, each with its own dead-man's switch.
- A documented offboarding procedure that produces a dump and a handover note before deletion.
- A memory budget per site, enforced with Compose `deploy.resources`.

## Alternatives rejected

- **One shared app with tenant schemas:** cheapest in memory, worst in blast radius. A single missing `WHERE tenant_id` is a cross-client data leak, and there is no test that proves otherwise.
- **One host per client:** the correct long-term answer, and the reason the cap exists. Not affordable in Phase 1 and not needed for the first two clients.
- **One database with one schema per client and one shared user:** isolation without a credential boundary is naming, not isolation.

## Revisit triggers

- A client requires dedicated infrastructure or a compliance boundary.
- A third client site approaches the memory cap.
- Any requirement for per-client uptime SLAs.
