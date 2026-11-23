# Optional worker: ASUS ROG Strix G16 (G614JVR)

Status: **optional, not onboarded, not required.** Expected to become reachable around 2026-12-06.

The decision is ADR-0002. This document is the contract and the onboarding checklist.

## Why it is optional

The platform is one Oracle A1 node plus managed services. The ROG is spare capacity: it makes work faster, never possible. If it disappears tomorrow, the platform keeps running and the rebuild drill still passes.

That is the whole point of the contract below. A second machine that quietly becomes the only place a build works, or the only copy of a database, is worse than no second machine.

## Hardware

| Component | Value | Relevance |
|---|---|---|
| CPU | Intel i9-14900HX, 24 threads | Fast local builds; a real `buildx` remote builder |
| GPU | RTX 4070 Laptop, 8 GB VRAM | Only useful for an actual GPU workload |
| RAM | DDR5, upgradeable | Run WSL2 with 12–16 GB |
| OS | Windows 11 | WSL2 is acceptable; dual boot is ruled out |
| Location | Toronto | Same country as the node; Tailscale handles the path |

## Candidate roles, in order of value

| Role | Value | Risk | Verdict |
|---|---|---|---|
| **Remote Docker builder** (`buildx` + `buildkitd`) | Cuts multi-arch build time; no state | Low | Adopt first |
| **GPU batch workload** | Only if a real workload appears | Medium | Only on demand |
| **Second Compose host for a client** | Client isolation without a VPS | High: it can vanish | Needs an ADR |
| **Primary GitHub Actions runner** | Saves Actions minutes | High: merge path on a laptop | Reject |

## The optional-worker contract

Every role must satisfy all five. A role that fails one is rejected.

1. **No unique state.** Nothing lives only on the ROG. Caches and rebuildable artifacts only.
2. **No critical path.** Losing it degrades speed, never availability. `docs/runbooks/rebuild.md` must pass with the ROG powered off.
3. **Reachable only over Tailscale.** No inbound ports, no public DNS, no port forwarding.
4. **Bounded blast radius.** It joins as `tag:worker` and cannot reach port 22 or 5432 on the primary node.
5. **Revocable in one action.** Remove the node from the tailnet and revoke its token; the platform is back to its pre-ROG state.

## Onboarding checklist

Run this only when the machine is actually reachable, and only after iteration-01 is closed.

- [ ] Confirm physical access and agree with the owner on what may run and when.
- [ ] Decide the runtime: **Windows + WSL2** for a builder, or a single-boot Linux install if it is ever promoted to a host. Never dual boot.
- [ ] Install Tailscale, tag the node `tag:worker`, and apply an ACL that blocks 22 and 5432 to the primary.
- [ ] In WSL2: enable `systemd`, install Docker Engine inside the distro (not Docker Desktop), and cap memory at 12–16 GB in `.wslconfig`.
- [ ] Disable sleep while plugged in, or accept that builds pause and never make it a gate.
- [ ] Run `buildkitd` in the distro and register it with `docker buildx create --driver remote`.
- [ ] Measure one representative build with and without the remote builder. Keep the role only if the gain is real.
- [ ] Add the node to `docs/architecture.md` as a dashed optional edge.
- [ ] Run the dependency-guard drill before calling it done.

## Dependency-guard drill

1. Power the ROG off, or remove it from the tailnet.
2. Run `make check`, deploy from a clean clone, and execute one scheduled job.
3. Confirm the site, the database, and the backups are unaffected.
4. Record the result in the iteration-02 issue.

If any step fails, the ROG has become a dependency. Remove the dependency; do not relax this drill.

## What would promote it to required

- A client workload that needs a GPU, or more than 2 OCPU sustained.
- A second client database that no longer fits the primary node.

Promotion requires an ADR, a backup path for any state it would gain, and removal from the optional-worker contract.

## Anti-goals

- Hosting the issue tracker, monitoring, or anything that watches the primary.
- Holding the only copy of any data.
- Being the deploy target for production.
- Being a required check on a pull request.

## Why not just use it now

Because it is not reachable yet, and because a design that depends on an unreachable machine is a design that fails on the day the machine is late. The contract is written now so that day does not turn into a redesign.
