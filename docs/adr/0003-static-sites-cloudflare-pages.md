# ADR-0003: Static sites on Cloudflare Pages

- **Status:** Proposed
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/architecture.md`

## Context

The platform hosts both static websites and dynamic web services. Serving static sites from the Oracle node would consume bandwidth, disk, and TLS management for no benefit, and would make the sites depend on the same single point of failure as the apps.

Cloudflare Pages' free plan (checked November 2026) includes unlimited static requests and bandwidth, 500 builds per month, 20,000 files per site, and 100 custom domains per project.

## Decision

Static sites are built and served by **Cloudflare Pages**. The Oracle node serves only dynamic services and jobs.

DNS lives at Cloudflare. Custom domains attach to Pages projects. The Oracle origin sits behind Cloudflare's proxy for dynamic services.

## Consequences

**Positive**

- Static sites stay up if the Oracle node is down.
- No bandwidth cost or TLS management on the VPS.
- Global CDN and preview deployments for free.
- A clean separation between static and dynamic deployment pipelines.

**Negative**

- A second vendor and a second deploy pipeline.
- Cloudflare's terms and free limits can change.
- Client sites inherit a Cloudflare dependency, which may matter to some clients.
- Preview URLs are public unless access control is configured.

**Mitigations**

- Keep the static source in Git; any static host can rebuild it.
- Document the Pages project settings in the site repo.
- Use Cloudflare Access for private previews when needed.
- Revisit if a client requires a non-Cloudflare CDN.

## Alternatives rejected

- **Serve static files from Caddy on the Oracle node:** simpler vendor count, but couples site uptime to the free-tier VM and wastes its bandwidth.
- **GitHub Pages:** viable, but weaker custom-domain and preview ergonomics for client work.
- **S3 + CloudFront:** not free at this scale and more moving parts.
