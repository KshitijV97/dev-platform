# ADR-0005: Unified issue tracker

- **Status:** Proposed
- **Date:** 2026-11-22
- **Deciders:** Kshitij
- **Related:** `docs/integrations/issue-tracker.md`, `docs/grill/brief.md`

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

Use **GitHub Issues + Projects** as the Phase 0/1 unified tracker, with a documented exit to GitLab Free or self-hosted Forgejo/Plane.

This is a deliberate, reversible exception to the FOSS preference. The deciding factor is that the code, pull requests, checks, Dependabot, and Sentry integration already live on GitHub. A separate tracker would add a second platform, a second identity, and a sync problem during the $0 phase, without improving the actual work.

## Consequences

**Positive**

- One account, one permission model, one notification stream.
- Native issue ↔ pull request ↔ CI linkage; `Closes #123` works.
- Unlimited issues and the best API surface (REST + GraphQL).
- Telegram via a small Action; email notifications and reply-by-email are built in.
- Sentry and Dependabot integrations are first-class.
- $0.

**Negative**

- GitHub is proprietary, which conflicts with the stated FOSS preference.
- The free tier's 2,000 private Actions minutes are shared with CI.
- Migration to a FOSS tracker later requires an export/import and loses issue numbers.
- Client-facing views are limited compared with a dedicated portal.

**Mitigations**

- Keep labels and states tracker-agnostic so an export maps cleanly.
- Keep issue bodies free of secrets and provider-specific markup.
- Record the FOSS exit in this ADR and test an export before client work.
- If FOSS becomes a hard constraint, switch to GitLab Free before the issue count grows.

## Alternatives

- **GitLab Free now:** the strongest FOSS-native option. Rejected for Phase 0 only because it requires moving or mirroring the repository and accepting a 5-user / 400-CI-minute free tier. Revisit if FOSS becomes non-negotiable.
- **Plane Cloud:** the best dedicated FOSS tracker, but its free tier puts GitHub, GitLab, and Sentry integrations behind Pro, so it needs a bridge for the core requirements.
- **Huly Cloud:** the most generous free tier and native Telegram/GitHub sync, but its API is SDK-first rather than a clean REST API, and self-hosting is heavy.
- **YouTrack Free:** excellent feature fit, but proprietary and no better than GitHub for this workflow.
- **Forgejo now:** fully FOSS and light enough to run on a small VPS, but self-hosting the tracker on the same box it monitors creates a circular dependency.

## Revisit triggers

- FOSS becomes a hard requirement for the operator or a client.
- GitHub changes its free-tier limits, API terms, or pricing.
- CI usage exceeds the included Actions minutes for two consecutive months.
- A client needs a branded portal, guest access, or an audit trail.
- The issue count or cross-repo reporting outgrows GitHub Projects.
