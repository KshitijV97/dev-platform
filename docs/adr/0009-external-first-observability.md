# ADR-0009: External-first observability

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/architecture.md`, `docs/grill/brief.md` Q5 and Q13

## Context

Free logging and alerting is a hard requirement. The first draft of this design had Uptime Kuma, Dozzle, and the scheduler all on the same host, with "an external check" mentioned but unnamed.

That is a circular check: the monitor dies with the thing it monitors, and the failure you most need to know about is the one it cannot report.

## Decision

**No alerting path may terminate on the machine it monitors.**

| Layer | Tool | Where it runs | Why |
|---|---|---|---|
| Uptime + TLS expiry | Better Stack free (10 monitors, ~3 min) | External | Survives host loss |
| Job liveness | Healthchecks.io free (20 checks) | External | Dead-man's switch per job |
| Application errors | Sentry Developer (5k errors/mo) | External | Release tracking, PII scrubbing |
| Logs | Dozzle | On-box | Convenience, not alerting |
| Dashboards | Uptime Kuma | On-box, optional | Local view; never the paging path |

Rules that follow:

1. Every public endpoint has an external check, created before the endpoint is announced.
2. Every scheduled job pings an external check; absence of a ping is the alert.
3. On-box dashboards are for diagnosis, never for paging.
4. Admin interfaces (`logs.<domain>`, Kuma) sit behind Cloudflare Access, not the open internet.
5. Alerts route to Telegram and email. Alerts do **not** open issues automatically; a persistent alert becomes a `type:ops` issue by hand, so the tracker does not fill with noise.

## Consequences

**Positive**

- A dead host pages you, because the check lives elsewhere.
- Three free accounts instead of one paid Grafana stack.
- Log retention stays on-box, so no log volume limits are hit in Phase 1.

**Negative**

- Three vendors, three dashboards, three sets of credentials to rotate.
- Better Stack and Healthchecks free tiers have monitor caps; growth means pruning or paying.
- No metrics store: CPU and memory history is limited to what OCI reports.
- Logs die with the host, so post-mortems after a rebuild rely on what was shipped elsewhere.

**Mitigations**

- One password-manager entry per vendor, listed in the rotation procedure.
- Keep the check list in `docs/architecture.md` so nothing is monitored by memory.
- Add Grafana Cloud only when log retention or cross-service search is genuinely needed.

## Alternatives rejected

- **Uptime Kuma as the primary uptime check:** circular. Kept only as a dashboard.
- **Grafana Cloud free now:** 50 GB of logs and 10k series is more than Phase 1 needs, and it adds an agent plus a second query language. It is the documented upgrade path.
- **Self-hosted Prometheus + Alertmanager:** more moving parts, same circularity, no benefit at one node.

## Revisit triggers

- More than 10 public endpoints or 20 jobs.
- A client requires retained logs, a status page, or an SLA.
- A post-mortem is blocked because logs died with the host.
