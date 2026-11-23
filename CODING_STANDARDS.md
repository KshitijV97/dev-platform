# Coding standards

These rules apply to `infra/`, `compose/`, `scripts/`, and the docs that describe them. They are enforced by `make check` and by review.

## Containers

- Pin a major/minor tag in the repo (for example `postgres:16-alpine`). Production deploys use an image digest.
- No `latest` in a production compose file. `latest` is acceptable only in a local example, with a comment.
- Images must build for `linux/arm64` (the Oracle node) and `linux/amd64` (most clouds) unless the image is infrastructure-only.
- Run as a non-root user where the image supports it.
- Declare a `healthcheck` for every stateful service.
- Set Docker log rotation (`max-size`, `max-file`) on every service.
- No secrets in image layers, build args, or committed files.

## Compose

- One `compose.yaml` per environment; use profiles for optional services.
- Use `name:` to namespace the project.
- Do not use the obsolete top-level `version:` key.
- Configuration comes from `.env`; commit only `.env.example`.
- Use named volumes for state. Bind mounts are for config files only.
- `restart: unless-stopped` for long-running services.
- A service that writes data needs a documented backup and restore path.

## Terraform / OpenTofu

- `terraform fmt -recursive` must pass.
- Every variable has a `description`; secrets are `sensitive = true`.
- Never commit state, plans, `.tfvars` with secrets, or private keys.
- Local state is acceptable for one operator; move to remote state before a second operator or a client handover.
- Destructive changes need a rollback note in the PR.

## Shell

- `#!/usr/bin/env bash` and `set -euo pipefail`.
- Quote variables; use arrays for argument lists.
- `shellcheck` must pass.
- Scripts must be idempotent or clearly state that they are not.
- No `curl | bash` in a script that runs unattended, unless the URL is pinned and checksum-verified.

## Documentation

- A decision that is hard to reverse, surprising without context, and a real trade-off gets an ADR in `docs/adr/`.
- A plan lives in `docs/plans/` and has acceptance criteria.
- A runbook lives in `docs/runbooks/` and is updated in the same PR that changes the procedure.
- Relative links must resolve.
- Date time-sensitive claims and link the source.

## Git

- Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
- One logical change per commit.
- Do not commit generated secrets, backups, or large binaries.

## Cost and region

- Default to a Canadian region (`ca-toronto-1` or `ca-montreal-1`).
- Any paid service needs an explicit monthly budget and an ADR or issue.
- Phase 1 must remain at $0 excluding an optional domain.

## Verification

```bash
make check
```

This validates the Compose file, Terraform formatting, shell scripts, and secret scanning in CI.
