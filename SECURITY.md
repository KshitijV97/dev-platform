# Security policy

This repository is a design and scaffolding project. **Nothing in it is deployed**, and there is no public endpoint owned by this project to test against.

## Reporting a vulnerability

Use GitHub's [private vulnerability reporting](../../security/advisories/new) on this repository. Do not open a public issue for a security problem.

Please include:

- what is affected (file, workflow, or script),
- what an attacker could do with it,
- the smallest reproduction you can manage.

Expect an acknowledgement within a few days. There is no bug bounty; this is a one-person project.

## In scope

- Secrets accidentally committed to this repository or its history.
- A workflow that would leak secrets to a fork or an untrusted pull request.
- A script that runs untrusted input as root.
- A documented procedure that would destroy data if followed as written.

## Out of scope

- The Oracle, Cloudflare, Tailscale, GitHub, or Sentry accounts themselves.
- Findings that require access to infrastructure this project does not run.
- Generic hardening advice with no specific file or line behind it.
- Rate limiting, load testing, or denial-of-service tests against any host.

## If you find a leaked secret

Do not use it. Report it privately. Rotation is handled through the procedure in `docs/runbooks/incident.md`, and a leaked credential is treated as compromised even if it appears unused.
