# Agent instructions

This repo is a design-first infrastructure project. Read the context before changing anything.

## Read first

1. `GLOSSARY.md` — the vocabulary is normative.
2. `docs/adr/` — decisions already made.
3. `docs/plans/` — the plan you are executing, if any.
4. `docs/architecture.md` — the current shape and failure modes.
5. `docs/integrations/issue-tracker.md` — intake, labels, and alert routing.
6. `docs/grill/brief.md` — unresolved questions. Do not silently decide these.

## Rules

- **Do not contradict `GLOSSARY.md`.** If a term needs to change, update the glossary in the same change.
- **Hard-to-reverse decisions need an ADR.** Region, provider, database, orchestration, and anything with a migration cost qualify.
- **Plans live in `docs/plans/`.** Each plan needs a goal, scope, tasks, acceptance criteria, and rollback.
- **Never commit secrets.** Use `.env` locally, GitHub Secrets in CI, and a password manager for the server. Update `.env.example` when a new variable appears.
- **Default to Canada.** Use `ca-toronto-1` or `ca-montreal-1` unless an ADR says otherwise.
- **Protect the $0 phase.** Do not add a paid service without an explicit budget, an ADR or issue, and a note in `STRATEGY.md`.
- **No orchestration by default.** Kubernetes, Nomad, k3s, and "swarms" need an ADR proving the single-host Compose setup is insufficient.
- **The ROG laptop is out of scope.** It is in Toronto and not accessible. Do not add it as a worker.
- **State needs backups.** Any new stateful service must land with a backup path and a restore step in `docs/runbooks/restore.md`.
- **Multi-arch by default.** Build `linux/arm64` and `linux/amd64` images.
- **Update the runbook in the same PR** that changes a deploy, backup, or restore procedure.
- **Every non-trivial change has an issue.** Use the templates and the label set in `docs/integrations/issue-tracker.md`.
- **Run `make check` before declaring done.**

## Working with grill-with-docs

`grill-with-docs` interviews the operator and writes ADRs and glossary entries. When it finishes, fold the settled decisions into the active plan or spec before ending the session. Do not leave decisions only in chat.

## Working with Compound Engineering

- `ce-brainstorm` → requirements-only plan in `docs/plans/`.
- `ce-plan` → implementation-ready plan in `docs/plans/`.
- `ce-work` → implement, simplify, review, and commit.
- `ce-compound` → durable learning in `docs/solutions/`.

## Definition of done

- `make check` passes.
- The change is reflected in `docs/architecture.md` or a runbook if it alters behavior.
- A rollback is written down.
- No secret, no unpinned production image, no unapproved paid service.
