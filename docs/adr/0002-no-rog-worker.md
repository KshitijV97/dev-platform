# ADR-0002: The ROG laptop is not a worker

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/grill/brief.md`

## Context

A second machine is available in principle: an ASUS ROG Strix G16 (G614JVR) with an i9-14900HX, an RTX 4070 Laptop GPU, and upgradeable DDR5. It is physically in Toronto and the operator does not have access to it.

Using it as a build or GPU worker would add significant capacity at $0. It would also add:

- a dependency on a consumer Windows machine the operator does not control,
- WSL2 and Windows update behavior,
- sleep, thermal, and power constraints,
- a shared-machine social constraint,
- a security boundary around someone else's personal files.

## Decision

The ROG laptop is **out of scope** for this platform. No workflow may depend on it, and no runner, tunnel, or scheduled job targets it.

## Consequences

**Positive**

- The architecture has one less failure mode and one less security boundary.
- No coordination cost with the machine's owner.
- No Windows/WSL2 operational surface.

**Negative**

- No local GPU or 24-core burst capacity.
- Heavy builds must run in GitHub Actions or a paid cloud burst.
- The hardware is unused.

**Mitigations**

- Use GitHub Actions for x86 builds and tests.
- Use the GCP $300 trial for a short, deliberate burst if a workload needs more CPU for a few weeks.
- Revisit only if physical access and an explicit agreement exist.

## Alternatives rejected

- **Self-hosted runner over the internet:** requires access, a stable machine, and trust in the network path. Not available.
- **Remote desktop / VPN into the laptop:** same access problem, plus a poor reliability profile.

## Revisit triggers

- The operator gains physical access and the owner agrees to a bounded worker role.
- A workload appears that genuinely needs a GPU and cannot be served by a cloud burst.
