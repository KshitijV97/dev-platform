# Requirements

Captured 2026-11-22. This is the brief the architecture and plan must satisfy.

## Operator context

| Item | Value |
|---|---|
| Primary machine | MacBook Air M1, 8 GB RAM, 256 GB disk |
| Secondary machine | ASUS ROG Strix G16 (G614JVR), i9-14900HX, RTX 4070, in Toronto |
| Access to secondary | **Expected around 2026-12-06.** Optional worker only — never a dependency |
| Location | Canada |
| Budget | $0 for the first few months, then possibly a paid VPS or cloud |
| Stage | Hobby → client work → revenue |
| Operations | One developer, part-time |

## Functional requirements

1. Host Dockerized web services (HTTP APIs and server-rendered apps).
2. Host static websites.
3. Run scheduled jobs (cron-like) and triggered jobs (webhook, queue, user action).
4. Provide logging and alerting using free tiers where possible.
5. Support a repeatable deploy from Git.
6. Support backups and a tested restore.
7. Provide one unified issue tracker for bugs, features, client requests, CI failures, and application errors.
8. Group work into iterations that end in a retro, with no issue left open by accident.
9. Allow a future move to a paid VPS, managed platform, or cloud without rewriting the app.
10. Allow any proprietary tool that starts charging to be replaced by a FOSS equivalent without losing work.

## Non-functional requirements

| Requirement | Target |
|---|---|
| Region | Canada (`ca-toronto-1` or `ca-montreal-1`) |
| Phase 1 cost | $0 excluding an optional domain |
| Interactive latency from Canada | < 60 ms |
| Deploy time | < 10 minutes |
| Rebuild time | < 30 minutes |
| RPO / RTO | 24 h / 1 h in Phase 1 |
| Availability | Best effort in Phase 1; documented in Phase 2 |
| Security | No public SSH after bootstrap; no public database |
| Portability | Container images run on ARM64 and AMD64 |
| Observability | External uptime check + dead-man's switch for every job |
| Issue tracking | REST API, Telegram, email, repository and CI links; free tier |
| Iteration hygiene | Every issue in one milestone; ≤ 2 carry-overs per retro |
| Vendor escape | Tracker export + import proven; tracker move ≤ 1 week |

## Constraints

- No Kubernetes, Nomad, or free-tier swarm in Phase 1.
- No dual boot. Windows plus WSL2 is acceptable for the optional worker.
- No dependency on the ROG: it may not hold unique state, gate a merge, or sit on the critical path.
- No Android emulators.
- No paid service without an explicit budget.
- Do not create multiple Oracle accounts to build a cluster; it violates the one-account-per-person rule.
- FOSS is preferred, not absolute. ADR-0005 requires a tested exit instead.

## Assumptions to validate

- Oracle A1 capacity is available in at least one Canadian region at signup.
- 2 OCPU / 12 GB is enough for one small web service, Postgres, and a worker.
- Cloudflare Pages is acceptable for static sites, including client sites.
- A custom domain is optional in Phase 1.
- GitHub Actions' free minutes cover build and deploy volume.

## Out of scope

- High availability across regions.
- GPU or machine-learning workloads as a required capability. The optional worker may run one.
- A self-service platform for other developers.
- macOS build agents.
- Mobile app builds.

## Open questions

See `docs/grill/brief.md`.
