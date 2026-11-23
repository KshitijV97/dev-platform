# ADR-0005: Unified issue tracker

- **Status:** Accepted (2026-11-22)
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/integrations/issue-tracker.md`, `docs/iterations/README.md`, `docs/grill/brief.md`

## Context

The platform needs one place to triage bugs, features, client requests, CI failures, and application errors. Requirements: generous free tier, good REST API, Telegram, email, repository links, CI/CD links. FOSS is preferred. Self-hosting is acceptable later but not now.

Options and limits are compared in `docs/integrations/issue-tracker.md`. Summary:

- **GitHub Issues + Projects** — best native integration with the existing repos and CI; unlimited issues; proprietary.
- **GitLab Free** — FOSS-open-core; native Telegram, REST, repos, CI; 5 users / 400 CI minutes.
- **Plane Cloud** — AGPL; 12 users; REST/webhooks; repository and Sentry integrations are paid; Telegram via bridge.
- **Huly Cloud** — EPL; unlimited users / 10 GB; native Telegram and GitHub sync; API is SDK-first, not REST-first.
- **YouTrack Free** — 10 users / 30 GB; excellent REST; Telegram via workflow; proprietary.
- **Forgejo** — fully FOSS and lightweight, but self-host only.

## Decision

Use **GitHub Issues + Projects** as the Phase 0/1 unified tracker.

**FOSS is a preference, not a hard constraint** (operator decision, 2026-11-22). The hard constraint is the inverse: **any proprietary tool must be escapable to a FOSS alternative without losing work.** That constraint is defined below and is treated as a requirement, not an aspiration.

The deciding factor for GitHub is that the code, pull requests, checks, Dependabot, and Sentry integration already live there. A separate tracker would add a second platform, a second identity, and a sync problem during the $0 phase, without improving the actual work.

## Escape hatch is a hard requirement

GitHub Free can change. The rule is: **if a capability already in use moves behind a paid tier, the platform must be able to leave.** "Escapable" means all four are true:

1. **All data is exportable** through a documented API: issues, bodies, states, labels, milestones, timestamps.
2. **A FOSS target exists** that is hosted or self-hostable: GitLab CE, Forgejo, or Plane CE.
3. **The path is proven, not asserted.** `scripts/export-issues.sh` runs on demand and the import into a throwaway GitLab or Forgejo project has been performed once (iteration-01, issue X2).
4. **The move is bounded in time:** tracker-only migration in **≤ 1 week**, full platform migration (code, CI, tracker) in **≤ 1 month.**

### Triggers

Any one of these starts the exit, without further debate:

- a capability already in use moves to a paid tier,
- a free-tier limit is cut below current usage,
- the smallest paid tier costs more than the work justifies,
- an account-level change (suspension, policy, region restriction) threatens access.

### Mechanism

- **Dated JSON snapshots.** `make export` writes issues, labels, and milestones to `exports/<timestamp>/`. The directory is gitignored; the snapshot is a backup, not a source.
- **Tracker-agnostic vocabulary.** Labels and states come from `docs/integrations/issue-tracker.md` and avoid provider-only concepts. States map to GitLab's open/closed and Forgejo's open/closed/closed-as.
- **Numbers are preserved.** On import, the original issue number is written into the body as `legacy-id: N`, so links in commits and docs keep meaning.
- **Boring CI.** Workflows use only first-party actions (`checkout`, `setup-terraform`) plus `gitleaks`. A GitHub → GitLab move is a YAML port, not a rewrite.
- **No provider-only field is load-bearing.** Project board fields are a view over labels and milestones, never the only place a value exists.

### Honest limitation

The tracker is the cheap half. Code hosting, pull requests, and Actions are the expensive half, and that is the real lock-in. The mitigation is not a promise; it is that the repo contains no GitHub-specific build logic, images live in GHCR by SHA (portable to any OCI registry), and the deploy path is `ssh` plus `docker compose`, which works anywhere.

## Consequences

**Positive**

- One account, one permission model, one notification stream.
- Native issue ↔ pull request ↔ CI linkage; `Closes #123` works.
- Unlimited issues and the best API surface (REST + GraphQL).
- Telegram via a small Action; email notifications and reply-by-email are built in.
- Sentry and Dependabot integrations are first-class.
- $0, with a tested exit that costs a week, not a month.

**Negative**

- GitHub is proprietary.
- The free tier's 2,000 private Actions minutes are shared with CI.
- Migration later loses comment threads unless they are exported separately.
- Client-facing views are limited compared with a dedicated portal.

**Mitigations**

- Labels and states stay tracker-agnostic so an export maps cleanly.
- Issue bodies stay free of secrets and provider-specific markup.
- `make export` runs before client work starts and after any vendor pricing change.
- The import drill is a Phase 0 acceptance item, not a future task.

## Alternatives

- **GitLab Free now:** the strongest FOSS-native option, and the default escape target. Rejected for Phase 0 only because it requires moving or mirroring the repository and accepting a 5-user / 400-CI-minute free tier. It remains the first choice if the escape hatch is ever pulled.
- **Plane Cloud:** the best dedicated FOSS tracker, but its free tier puts GitHub, GitLab, and Sentry integrations behind Pro, so it needs a bridge for the core requirements.
- **Huly Cloud:** the most generous free tier and native Telegram/GitHub sync, but its API is SDK-first rather than a clean REST API, and self-hosting is heavy.
- **YouTrack Free:** excellent feature fit, but proprietary and no better than GitHub for this workflow.
- **Forgejo now:** fully FOSS and light enough to run on a small VPS, but self-hosting the tracker on the same box it monitors creates a circular dependency.

## Revisit triggers

- A vendor change forces a paid tier for something already in use — **immediate exit, no debate.**
- FOSS becomes a hard requirement for the operator or a client.
- GitHub changes its free-tier limits, API terms, or pricing.
- CI usage exceeds the included Actions minutes for two consecutive months.
- A client needs a branded portal, guest access, or an audit trail.
- The issue count or cross-repo reporting outgrows GitHub Projects.
