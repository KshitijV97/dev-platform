# ADR-0007: Postgres 16 in Docker, with a portability exit

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** ADR-0004, `docs/grill/brief.md` Q2 and Q11

## Context

Phase 1 needs one relational database for a small web service, a job queue, and a couple of client sites later. 12 GB of RAM fits a small Postgres comfortably.

Options: Postgres in Docker with nightly dumps; a managed free tier (Neon, Supabase) with cold starts and a second vendor; SQLite for small sites.

The operator asked for the escape hatch to stay open. Note the vocabulary: this is a **portability exit** (move the workload to another provider or a managed service), not a **vendor escape** (replace a proprietary tool with a FOSS one). Postgres is already FOSS; the risk here is operational lock-in, not licensing.

## Decision

Run **`postgres:16-alpine` in the Compose stack**, with a named volume, nightly `pg_dump` to restic, and a monthly restore drill.

The portability exit is a property of the schema and the backup format, not of the host:

- Logical `pg_dump` output is the migration artifact, not a physical volume snapshot.
- Standard SQL only. No superuser-only features, no unlisted extensions. `pgcrypto` and `pg_trgm` are fine; anything a managed tier does not offer is not used.
- Migrations are plain-forward SQL applied by a tool that can target any Postgres, so the same files run against Neon or Cloud SQL.
- The connection string comes from `DATABASE_URL`, so switching targets is configuration, not code.

## Consequences

**Positive**

- No second vendor, no cold starts, no network hop for queries.
- One backup path and one restore procedure for all state.
- The dump/restore path is the same one that would migrate to a managed tier.

**Negative**

- No point-in-time recovery. RPO is the dump interval: 24 hours.
- No automatic failover. A host loss is a restore, not a promote.
- The database competes for the same 12 GB and 2 OCPUs as everything else.
- Someone must run the drill; an untested backup is a belief.

**Mitigations**

- Monthly restore drill with a recorded time, into a scratch database first.
- Retention of 7 daily / 4 weekly / 3 monthly so a bad dump is not fatal.
- Backups land in object storage, off the host that holds the database.

## Exit triggers

Move to managed Postgres (Neon, Supabase, Cloud SQL) when any of these is true:

- A client requires PITR, an SLA, or a maintenance window.
- The database exceeds roughly 5 GB, where a nightly dump stops fitting the backup window.
- More than one client database needs independent scaling or isolation guarantees.
- Postgres sustains more than ~1 GB of RAM or becomes the CPU bottleneck.

The move is `pg_dump | psql` plus a connection-string change, measured in hours, not weeks.

## Alternatives rejected

- **Managed free Postgres now:** adds a vendor, a network hop, and idle-pause behaviour for a database that fits on the box. It is the documented exit target, not the starting point.
- **SQLite per site:** excellent for static-ish sites, poor for a shared queue and concurrent writers.
