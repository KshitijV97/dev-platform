# ADR-0010: Secrets in `.env` and GitHub Actions secrets

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/runbooks/rebuild.md`, `docs/grill/brief.md` Q7

## Context

One operator, one host, roughly fifteen secrets. Options: a mode-600 `.env` on the host plus GitHub Actions secrets; SOPS/age encrypted files in the repo; a managed secret store (Infisical, Doppler, OCI Vault).

The requirement is not "the most secure possible". It is: no secret in Git, every secret reconstructible after the host is lost, and rotation that a single person can actually perform.

## Decision

Three storage locations, each with a defined job.

### 1. Password manager — the source of truth

Holds every secret, plus the `.env` file as a note. This is the only place a secret is authored.

### 2. Host `.env` — `/srv/dev-platform/.env`, mode 600, owner `deploy`

Read by `docker compose` at start. Never in Git (`.gitignore` covers `.env` and `.env.*`, with `!.env.example`).

### 3. GitHub Actions secrets — CI only

Injected as environment variables at workflow runtime, masked in logs, never readable after creation.

## Inventory

| Secret | Lives in | Read by | Rotates when |
|---|---|---|---|
| `DOMAIN`, `TZ` | `.env` (not secret) | Compose | On domain change |
| `POSTGRES_PASSWORD` | Password manager → `.env` | Postgres, app, worker | Suspicion, handover |
| `RESTIC_PASSWORD` | Password manager → `.env` | `backup.sh`, `restore.sh` | Yearly, or on suspicion |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Password manager → `.env` | restic (OCI S3) | Yearly |
| `HEALTHCHECKS_PING_URL` | Password manager → `.env` | jobs, `backup.sh` | On check recreation |
| `SENTRY_DSN` | Password manager → `.env` | app | On project recreation |
| `TELEGRAM_BOT_TOKEN` | Password manager → Actions secrets | `issue-notify.yml` | On suspicion (revoke in BotFather) |
| `TELEGRAM_CHAT_ID` | Password manager → Actions secrets | `issue-notify.yml` | On channel change |
| `TAILSCALE_AUTH_KEY` | Password manager → Actions secret / Terraform var | deploy job, cloud-init | **Every use.** Single-use, revoked after join |
| SSH private key | Password manager only | operator | Yearly, or on suspicion |
| OCI API key | Password manager + `~/.oci/config` | Terraform | Yearly |
| Oracle tenancy/compartment OCIDs | Password manager | Terraform | Never |

## Rules

1. **A secret exists in the password manager before it exists anywhere else.** If it is only on the host, the host is the source of truth and the rebuild is a guess.
2. **The rebuild runbook names where each secret comes from.** "Create `.env` from the password manager" is a step, not a hand-wave.
3. **Terraform state is a secret.** `tailscale_auth_key` lands in state and in instance metadata, which is why it is single-use and revoked immediately after boot.
4. **Nothing secret in issue bodies.** The templates say so; Sentry must scrub PII before it reaches GitHub.
5. **Rotation is a checklist, not a virtue.** Every entry above has a trigger and a procedure in `docs/runbooks/`.
6. **CI never holds a long-lived deploy key** beyond what the job needs, and the deploy job is scoped to `main`.

## Consequences

**Positive**

- One file to restore, one place to look, no encryption tooling to learn.
- The rebuild drill has a real, testable source for secrets.
- No new vendor on the boot path.

**Negative**

- Root on the host can read every secret. A compromised host means full rotation.
- No audit trail for who read what. There is one operator, so the trail would be one line.
- `.env` can drift from the password manager if someone edits in place.

**Mitigations**

- Rotation procedure covers all of it; the incident runbook makes rotation step three of a compromise.
- `.env` is regenerated from the password manager during a rebuild rather than copied forward.
- Secrets are scoped: the Telegram token can only post messages; the OCI key can only reach one bucket.

## Why not SOPS or a managed store now

SOPS needs an age key, and that key has to live somewhere — usually on the host or the laptop, which moves the problem rather than solving it. A managed store puts a network dependency on the boot path: if Infisical is down, the stack does not start. Both are correct answers at two operators or a client handover, which is exactly when this ADR should be superseded.

## Revisit triggers

- A second operator, or a client handover.
- More than ~20 secrets.
- A compliance requirement for audit logs or envelope encryption.
- A secret leaks; the incident runbook then forces the move forward.
