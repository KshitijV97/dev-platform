# ADR-0002: The ROG laptop is an optional worker, never a dependency

- **Status:** Accepted (revised 2026-11-22)
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/workers/rog-g16.md`, `docs/grill/brief.md`

## Context

A second machine exists: an ASUS ROG Strix G16 (G614JVR) with an i9-14900HX, an RTX 4070 Laptop GPU, and upgradeable DDR5, running Windows 11.

The original decision excluded it entirely because it was physically in Toronto and inaccessible. That is no longer permanent: the machine is expected to become reachable around 2026-12-06, roughly two weeks after this decision. It would add substantial $0 capacity.

It would also add:

- a dependency on a consumer Windows machine that is not a server,
- WSL2 and Windows update behaviour,
- sleep, thermal, and power constraints,
- a security boundary around someone else's personal files,
- a coordination cost with the machine's owner.

## Decision

The ROG is **not part of the platform**. It is an **optional worker** with a hard contract:

1. **No unique state.** Nothing lives only on the ROG. It holds caches and rebuildable artifacts.
2. **No critical path.** Losing it degrades speed, never availability. The platform must pass its rebuild drill with the ROG powered off.
3. **No inbound exposure.** It joins the tailnet as a tagged node and is reachable only over Tailscale.
4. **Revocable in one action.** Removing the node from the tailnet and revoking its token returns the platform to its pre-ROG state.

Any role that cannot satisfy all four is rejected, not negotiated. Roles, onboarding, and anti-goals are in `docs/workers/rog-g16.md`.

## Consequences

**Positive**

- The $0 phase gains burst CPU and a GPU without changing the architecture.
- Builds can run on 24 threads instead of 2 OCPUs.
- The dependency risk is written down as an enforceable contract instead of a good intention.

**Negative**

- One more machine to patch, monitor, and trust.
- Windows and WSL2 add an operational surface that the Linux node does not have.
- The owner of the machine can take it away with no notice, so nothing may depend on it.

**Mitigations**

- GitHub Actions remains the only CI that gates a merge. The ROG is an accelerator, never a gate.
- The dependency-guard drill (iteration-02) proves the platform works with it switched off.
- A single-use Tailscale auth key and a tagged ACL keep the blast radius small.
- Revisit with an ADR if a workload genuinely needs the GPU or the cores.

## Alternatives rejected

- **Self-hosted GitHub Actions runner as the primary CI:** puts a consumer machine on the merge path, and a sleeping laptop becomes a failed check.
- **Second Compose host holding client data:** the machine can disappear without notice; client data may not.
- **Remote desktop into the laptop:** poor reliability profile and a wide security boundary for little gain.
- **Dual boot to Linux:** explicitly ruled out by the operator. WSL2 is acceptable; a single-boot Linux install is a later decision, not a dual boot.

## Revisit triggers

- A workload appears that needs the GPU or more than 2 OCPU sustained.
- A second client database no longer fits the primary node.
- The machine is replaced by something the operator owns outright.
