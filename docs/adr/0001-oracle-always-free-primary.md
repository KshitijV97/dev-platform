# ADR-0001: Oracle Always Free A1 as the Phase 1 primary

- **Status:** Proposed
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/architecture.md`, `docs/grill/brief.md`

## Context

Phase 1 needs an always-on Linux host in Canada, capable of running Docker Compose, Postgres, a small web service, and a worker, for $0. The operator is in Canada and wants a path to a paid VPS or managed cloud later.

Options considered:

| Option | Canadian region | Free period | Practical capacity | Main catch |
|---|---|---|---|---|
| Oracle Always Free | Toronto, Montreal | Indefinite | 2 ARM OCPU / 12 GB, 200 GB block, 10 TB egress/month | Capacity errors, idle reclamation, ARM |
| Azure free account | Canada Central | 12 months | 750 h/mo B1s / B2ats v2 / B2pts v2 | $200 credit expires in 30 days |
| AWS Free Plan | `ca-central-1` | 6 months | $100 + up to $100 credits | 12-month EC2 tier removed for new accounts |
| GCP Free Trial | Montreal, Toronto | 90 days | $300 credit | Not free after 90 days; no always-free VM in Canada |
| Paid VPS | Canada or nearby | Forever, paid | ~$5–12/mo | Not $0 |

## Decision

Use one Oracle Cloud Infrastructure Always Free `VM.Standard.A1.Flex` instance with **2 OCPU / 12 GB RAM**, Ubuntu 24.04, in `ca-toronto-1` or `ca-montreal-1`, as the Phase 1 primary node.

The node runs Docker Compose only. It is treated as disposable: Terraform + cloud-init + Compose rebuild it, and all durable state is backed up off-box.

## Consequences

**Positive**

- The largest genuinely free, no-expiry compute available in Canada.
- 12 GB RAM comfortably fits the proposed stack; 10 TB/month egress removes a common free-tier trap.
- ARM64 matches the developer's Apple Silicon for native containers.
- A single host is simple to reason about, back up, and rebuild.

**Negative**

- A1 capacity can be unavailable at provisioning time; retries may take days.
- Always Free instances can be reclaimed if idle over a 7-day window (95th-percentile CPU, network, and A1 memory all below 20%).
- Oracle halved the A1 allowance from 4 OCPU / 24 GB to 2 OCPU / 12 GB in June 2026 without a public announcement. The allowance can change again.
- The home region is fixed at signup and Always Free compute must run there.
- ARM64 requires multi-arch images for a future x86 move.

**Mitigations**

- Keep real workloads on the instance; do not leave it idle.
- Keep Terraform, cloud-init, Compose, and backups in this repo.
- Run a rebuild drill and record the time.
- Re-check free-tier terms quarterly.
- If capacity or reclamation becomes chronic, upgrade to Oracle PAYG (Always Free resources stay free) or move to a paid VPS.

## Alternatives rejected

- **Azure:** better short-term capacity, but the free VM ends at 12 months and the credit ends at 30 days. Useful as a temporary burst, not a home.
- **AWS:** six months is too short for a platform that should compound.
- **GCP:** no always-free VM in Canada; the $300 credit is a 90-day trial.
- **Paid VPS now:** contradicts the $0 phase. Keep it as the first migration target.

## Revisit triggers

- Two reclaim or capacity incidents in one quarter.
- Sustained CPU > 70% or memory > 80%.
- A client requires an SLA, PITR, or a compliance boundary.
- Oracle changes the Always Free terms again.
