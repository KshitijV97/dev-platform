# Strategy

## One line

Build a $0-first, Canadian, portable execution platform for one developer's web services and jobs, then let it grow into client and revenue work without re-platforming.

## Problem

The current development machine is a MacBook Air M1 with 8 GB RAM and a 256 GB disk. It cannot comfortably run an editor, a browser, Docker, a database, and a build at the same time. The bottleneck is memory and disk, not willingness to work.

At the same time, free-tier compute is volatile: capacity disappears, allowances shrink, and idle instances get reclaimed. A naive "free VPS" plan produces a fragile pet server.

This project separates the durable parts of the workflow from the disposable parts, so the machine can fail without taking the work with it.

## Users

- **Primary:** Kshitij, a developer in Canada, working on hobby projects that may become client and revenue work.
- **Secondary:** future clients who need a small hosted site, API, or scheduled job. They care about uptime, backups, and a clean handover, not the underlying provider.

## Principles

1. **Boring beats clever.** Docker Compose on one host, not Kubernetes on three.
2. **State outlives compute.** Code in Git, data in backups, images in a registry. Any node can be rebuilt.
3. **Free is a phase, not an identity.** Every choice must have a paid or managed exit.
4. **Canada by default.** Latency to the user and data residency both point to `ca-toronto-1` or `ca-montreal-1`.
5. **Observability is part of the product.** If a job fails silently, the platform is not working.
6. **No surprise bills.** Every paid service needs an explicit budget and an owner.
7. **One queue.** Every non-trivial change has an issue, and every issue has a label that says what it is.
8. **Proprietary is fine, locked-in is not.** Any tool that can start charging must have a documented, scripted, and drilled exit to a FOSS alternative.

## Iterations

Work is organised as iterations, not as an open backlog. Each iteration is a GitHub milestone (`iteration-NN: <theme>`) and ends in a retro. The retro does not close while the milestone has open issues, except at most two with a written carry-over reason. See `docs/iterations/README.md`.

The point is honesty: work either finishes or is explicitly abandoned. Optional capacity gets its own `optional: true` milestone so it can never stall the platform.

## Phases

### Phase 0 — Bootstrap (weeks 1–2)

Tracked as `iteration-01: phase 0 bootstrap`. Design questions are `iteration-00: settle decisions`.

Goal: one Oracle A1 instance running the Compose stack, reachable over Tailscale, with TLS, backups, and external monitoring.

Exit criteria:

- A web service is reachable on a real domain over HTTPS.
- A scheduled job runs and pings Healthchecks.io.
- A nightly database dump exists in object storage.
- The instance can be destroyed and rebuilt from this repo in under 30 minutes.
- One issue tracker is live with templates, labels, and Telegram notifications.
- `make check` passes in CI.

### Phase 1 — Hobby (months 1–3)

Goal: daily-driver development from the Mac against the Oracle node, at $0.

Exit criteria:

- The Mac stays under ~6 GB RAM during normal work.
- Deploys happen from GitHub Actions, not by hand.
- At least one restore drill has succeeded.
- Monthly cost is $0 (excluding an optional domain).

### Phase 2 — First client

Goal: host a small client site or service with a clear support boundary.

Triggers to leave the free tier:

- A client needs an uptime commitment or a maintenance window.
- Sustained CPU above ~70% or memory above ~80%.
- More than one stateful client database on the box.
- A need for zero-downtime deploys.

Likely moves: a $5–12/mo VPS, managed Postgres (Neon/Supabase), or Cloud Run for stateless services.

### Phase 3 — Revenue

Goal: a small portfolio of sites/services with predictable costs and documented recovery.

Exit criteria:

- Monitoring, backups, and restore drills are routine.
- Costs are tracked per project.
- A client can be handed over or migrated without the original developer.

## Success metrics

| Metric | Target (Phase 1) | Target (Phase 2) |
|---|---|---|
| Monthly infra cost | $0 | < $25 |
| Deploy time | < 10 min | < 10 min |
| Rebuild from scratch | < 30 min | < 30 min |
| Recovery point objective | 24 h | 1 h |
| Recovery time objective | 1 h | 30 min |
| Interactive latency from Canada | < 60 ms | < 60 ms |
| Silent job failures | 0 | 0 |
| Triage time for a new issue | < 1 day | < 4 hours |
| Issues still open at a retro | ≤ 2 carry-overs | 0 |
| Time to leave a paid tracker | 1 week | 1 week |

## Constraints

- $0 for the first few months.
- Canadian region preferred.
- Dockerized web services and hosted websites.
- Scheduled and triggered jobs.
- No Android emulators.
- Free logging and alerting preferred.
- One developer, part-time operations.
- A second machine (ROG Strix G16) may join as an optional worker, never as a dependency.

## Non-goals

- Multi-region or high availability.
- A free-tier "swarm".
- GPU workloads as a required capability. The ROG may run one as optional work.
- Windows or dual boot as a platform requirement. Windows plus WSL2 is acceptable for the optional worker.
- A custom PaaS or Kubernetes distribution.
- Self-hosting the issue tracker while the hosted tier is free.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Oracle reclaims an idle instance | Outage | Keep real workloads on it; IaC + backups; rebuild runbook |
| A1 capacity unavailable at signup | Delay | Try both Canadian regions; retry; consider PAYG upgrade |
| Free tier changes | Cost/outage | Re-check quarterly; keep migration path |
| Single host fails | Outage | External monitoring; fast rebuild; optional warm standby |
| Client data loss | Reputation | Nightly dumps; monthly restore test; off-box storage |
| Scope creep into platform engineering | No product work | ADR required for orchestration; Compose until 5+ nodes |
| The issue tracker becomes a second backlog | Lost work | One queue, weekly triage, close or schedule every issue |
| The tracker starts charging for something in use | Cost or forced move | `make export` and the GitLab Free procedure in ADR-0005; triggered immediately |
| The ROG arrives and quietly becomes a dependency | Outage when it leaves | Optional-worker contract; ACL; dependency-guard drill with it switched off |
| Retro becomes theatre | Unclosed work hides | `make iteration-check` gates the retro; carry-over capped at two per iteration |

## Open decisions

See `docs/grill/brief.md`. Decisions that are hard to reverse get an ADR in `docs/adr/`.
