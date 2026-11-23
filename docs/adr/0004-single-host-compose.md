# ADR-0004: Single-host Docker Compose, no orchestration

- **Status:** Proposed
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/architecture.md`, `docs/grill/brief.md`

## Context

The Phase 1 platform is one always-on node with 2 OCPU / 12 GB. The operator asked whether a "swarm" of Oracle free-tier servers or a small cluster would be better.

Constraints:

- Oracle permits one free account per person; the realistic ceiling is two tenancies (operator + partner), not a fleet.
- Each tenancy offers 2 OCPU / 12 GB, so splitting into more nodes reduces per-node capacity.
- k3s needs three healthy control-plane nodes for etcd quorum; a laptop that sleeps cannot provide it.
- Cross-tenancy networking is public internet plus a VPN, with no shared block storage and no SLA.
- Every additional node adds failure modes, upgrade work, and security surface.

## Decision

Use **Docker Compose on one host** for Phase 1. Do not introduce Kubernetes, k3s, Nomad, Docker Swarm, or a multi-account cluster.

Revisit only when there are at least five always-on nodes, or a workload that genuinely requires scheduling across hosts.

## Consequences

**Positive**

- One file describes the whole runtime.
- Fast rebuild and simple debugging.
- No control-plane quorum, CNI, CSI, or ingress controller to operate.
- Backups and restores are straightforward.

**Negative**

- The host is a single point of failure.
- No built-in rolling deploys or self-healing beyond Docker restart policies.
- Scaling is vertical until a migration.

**Mitigations**

- External uptime monitoring and a dead-man's switch.
- IaC + backups + a timed rebuild drill.
- Immutable image tags and a one-command rollback.
- A documented migration target (paid VPS, Cloud Run, managed Postgres).

## Alternatives rejected

- **k3s on two Oracle VMs + a laptop:** no etcd quorum, fragile storage, high operational cost for no product benefit.
- **Nomad on two nodes:** simpler than Kubernetes but still unnecessary for one host.
- **Docker Swarm:** effectively maintenance-mode; no reason to adopt it now.
- **Managed Kubernetes:** the free control plane does not cover worker nodes; cost and complexity are unjustified at this scale.
