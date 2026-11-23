# Review guide

Use this when reviewing a PR that changes infrastructure, deployment, or data handling.

## Blocking

- A secret is committed, logged, or baked into an image.
- A database, admin panel, or SSH port is exposed publicly without an explicit decision and an ADR.
- A stateful service has no backup and no restore path.
- A production image uses `latest` or an unpinned digest.
- A deploy has no rollback path.
- A paid service is added without a budget and an ADR/issue.
- A resource is created outside Canada without a stated reason.
- A single point of failure is introduced without a runbook entry.
- A proprietary tool is added with no export or migration path.
- A change makes the optional worker (ROG) required: it holds unique state, gates a merge, or sits on the critical path.

## Should fix before merge

- Missing healthcheck on a stateful service.
- Missing log rotation.
- No resource limits on a container that can exhaust the host.
- A runbook or diagram is now stale.
- A scheduled job has no dead-man's switch.
- A migration runs automatically on deploy with no backup step.
- Client-facing work has no linked issue or acceptance criteria.
- The issue is not assigned to an iteration milestone.

## Questions to ask

1. What happens if this node disappears right now?
2. What is the data loss window?
3. How does this fail loudly rather than silently?
4. What does it cost after the free tier?
5. How would this move to Cloud Run, a paid VPS, or managed Postgres?
6. Is the change reversible in one deploy?
7. If the vendor starts charging tomorrow, how long until we are off it?

## How to verify

```bash
make check
docker compose -f compose/compose.yaml --env-file .env.example config
./scripts/iteration-status.sh
```

For infra changes, read the plan and the rollback section before reading the diff.
