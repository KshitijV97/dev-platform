# ADR-0012: Cloudflare proxied A record with an Origin Certificate

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** ADR-0006, ADR-0013 in `docs/grill/brief.md`, `docs/architecture.md`

## Context

Requests need to reach Caddy on the Oracle node over HTTPS, from a domain that is not owned yet and might be a free subdomain for the first few weeks.

Three shapes were considered. They differ in who terminates TLS, who sees the traffic, and what fails when something goes wrong.

| Shape | DNS | Browser talks to | Origin IP | TLS | Failure mode when it breaks |
|---|---|---|---|---|---|
| **Direct** | A record, DNS-only (grey cloud) | Oracle IP:443 | Public and discoverable | Caddy + Let's Encrypt ACME | Certificate renewal fails silently |
| **Proxied** | A record, proxied (orange cloud) | Cloudflare edge | Hidden from DNS, still discoverable by scanning | Cloudflare at the edge + Origin Cert on Caddy | SSL mode or origin cert mismatch → 525/526 |
| **Tunnel** | CNAME to `*.cfargotunnel.com` | Cloudflare edge | None; no inbound ports | Cloudflare at the edge + tunnel | `cloudflared` dies → site down, firewall shows nothing |

## Decision

**Cloudflare proxied A record, Caddy serving a Cloudflare Origin Certificate, SSL mode Full (strict).**

Layer by layer:

1. **DNS.** `antwater.<zone>` is an A record pointing at the Oracle reserved public IP, proxied (orange cloud). Cloudflare answers with its own anycast IPs, not the origin's.
2. **Edge TLS.** Cloudflare presents a certificate for the hostname and terminates TLS. The visitor never talks to Oracle directly.
3. **Origin TLS.** The edge→origin leg uses a **Cloudflare Origin Certificate** — a 15-year certificate issued by Cloudflare's private CA for that hostname — installed in Caddy. Because Cloudflare trusts its own CA, `Full (strict)` validates without ACME.
4. **Firewall.** UFW allows 443 only from Cloudflare's published IP ranges (refreshed quarterly), plus Tailscale for admin. No public 80.
5. **Admin surfaces.** `logs.<domain>` and the Kuma dashboard are behind **Cloudflare Access** (free for up to 50 users), so Dozzle is not public even though it is proxied.

## Why an Origin Certificate instead of Let's Encrypt

ACME behind the proxy usually works and occasionally does not: Cloudflare passes the HTTP-01 challenge through, but the failure shows up as 525/526 at 3 a.m. and looks like a TLS outage rather than a renewal problem. The Origin Certificate removes the renewal loop entirely: nothing expires for 15 years, and `Full (strict)` still proves the origin is the expected host.

The trade is honest: a 15-year private key in `/data/caddy/certificates` is a long-lived secret. It is regenerated in Cloudflare if the host is rebuilt or the key is suspected, and it is listed in the rotation procedure.

## Why not Tunnel yet

The Tunnel removes inbound ports entirely, which is genuinely better security posture. It also adds a daemon whose death is invisible to the firewall and whose logs live on the same host as the service. For Phase 1, with one host and one public endpoint, the extra moving part costs more than it saves. Revisit when the origin IP becomes a nuisance, or if the node ever sits behind CGNAT.

## Why not direct

A DNS-only A record publishes the origin IP. Every scanner finds it within hours, and then Cloudflare's rate limiting, WAF, and DDoS absorption are decorative because the attacker goes around them. The cost of hiding it is one certificate and one SSL mode.

## Consequences

**Positive**

- The origin IP is not in DNS, so casual scanning and direct-to-IP attacks are pushed through the edge.
- Free WAF rules, rate limiting, and DDoS absorption apply to every request.
- No ACME, no renewal job, no 525 class of failure from certificate challenges.
- Admin interfaces are authenticated at the edge, not by obscurity.
- Changing hosts is a DNS record plus a new Origin Certificate, not a certificate-issuance dance.

**Negative**

- **Cloudflare terminates TLS, so Cloudflare sees plaintext.** This is the real trade-off. A client with a hard requirement against that cannot use this shape.
- Cloudflare outage means the site is down even if Oracle is healthy.
- Cloudflare's IP ranges change; a stale UFW rule silently blocks traffic.
- The Origin Certificate key is long-lived and must be rotated deliberately, not automatically.
- Direct `curl` against the origin for debugging requires Tailscale.

**Mitigations**

- Refresh the UFW allow-list quarterly from Cloudflare's published ranges, and keep it a single scripted step.
- A canary check through Cloudflare, so an edge failure pages as loudly as an origin failure.
- Document the Origin Certificate in the rotation runbook with an explicit "rotate on rebuild or suspicion" line.
- If a client forbids Cloudflare, the fallback is direct + ACME, which is a two-line Caddy change and a DNS mode flip.

## Alternatives rejected

- **Direct A record + Let's Encrypt:** simplest to reason about, exposes the origin, and loses the edge protections. Acceptable only as the client-driven fallback.
- **Cloudflare Tunnel:** better posture, one more daemon to monitor, and a failure mode the firewall cannot show. Deferred, not rejected.
- **Proxied + ACME:** works until it does not, and fails in a way that looks like something else.

## Revisit triggers

- The node moves behind CGNAT, or the public IP becomes a problem.
- A client requires Cloudflare to be out of the data path.
- A Cloudflare outage causes an incident that a direct record would have survived.
