# ADR-0008: Ofelia for scheduled jobs

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** ADR-0004, `docs/grill/brief.md` Q3 and Q4

## Context

The platform must run scheduled jobs (nightly backup, data sync, cache warm) and triggered jobs (webhook, queue, user action). These have different failure modes and should not share a mechanism.

Options for schedules: host cron, Ofelia, an app-level scheduler, or GitHub Actions scheduled workflows.

The deciding constraint is not sophistication. It is that a schedule which exists only on the host is invisible to code review and invisible to the rebuild drill.

## Decision

Use **Ofelia**, configured by Docker labels in `compose/compose.yaml`. Every job:

- is a one-shot container with `restart: "no"`,
- is defined in the repo, so the schedule is reviewable in a diff,
- pings a **Healthchecks.io** check on success, and pings a failure URL on error,
- has a grace period long enough that a slow run does not page falsely.

Triggered jobs are **not** Ofelia's job. They go through a Postgres-backed queue drained by the `job-worker` container — the decision is recorded in ADR-0007's database and detailed in the plan.

## Consequences

**Positive**

- Schedules are versioned next to the services they drive.
- Adding a job is a label plus an image, not an SSH session.
- The rebuild drill restores the schedule automatically, because it is in the repo.
- One mechanism, one place to look.

**Negative**

- One more container to run and monitor.
- Ofelia failing is silent by default; a stopped scheduler looks exactly like nothing being scheduled.
- Label-based configuration is easy to typo and hard to lint.

**Mitigations**

- Every job carries its own dead-man's switch, so a dead scheduler produces missing pings rather than silence.
- A daily self-check job that pings Healthchecks.io even when it does nothing, so the scheduler itself is covered.
- Validate label syntax during `docker compose config` in CI.

## Alternatives rejected

- **Host cron:** simplest, but the crontab lives outside the repo and drifts from the rebuild runbook. Rejected on the "rebuild from this repo" requirement.
- **App-level scheduler:** more code, more failure modes, and it needs the app to be healthy to fire maintenance jobs.
- **GitHub Actions schedules:** free minutes, but schedules are delayed under load, capped, and disabled after 60 days of repository inactivity. Never the primary scheduler.
- **Kubernetes CronJob:** requires the orchestration this platform deliberately does not have.

## Revisit triggers

- Jobs need sub-minute precision or distributed locking.
- More than roughly 20 scheduled jobs, where label configuration stops being readable.
- Ofelia is abandoned upstream.
