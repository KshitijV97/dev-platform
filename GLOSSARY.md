# Glossary

The single source of truth for terms used in this repo. If a plan or ADR conflicts with a definition here, fix one of them before proceeding.

| Term | Meaning | Not to be confused with |
|---|---|---|
| **Control plane** | The tools a person uses to edit, review, and trigger work: editor, browser, Git, SSH client. Runs on the Mac. | The cloud provider's control plane. |
| **Execution plane** | Where code actually runs: containers, language servers, builds, databases, jobs. Runs on the Oracle node. | The developer's laptop. |
| **State plane** | Durable data that must survive a node: Git history, database dumps, object storage, registry images. | Container volumes on a single host. |
| **Primary node** | The one always-on Oracle A1 instance that hosts the Compose stack. | A "swarm" or cluster. |
| **Job worker** | The container that claims queued jobs and executes them. One process, one queue. | An optional worker, which is a machine. |
| **Optional worker** | A machine that may accelerate work but whose absence must not break anything. Today: the ROG Strix G16. Holds no unique state and is never a required check. | A warm standby, which is expected to be able to take over. |
| **Dev container** | A reproducible development environment defined by `devcontainer.json` and a Dockerfile. | A production container. |
| **Golden path** | The documented, supported way to deploy and operate the platform. | Every possible configuration. |
| **Rebuild drill** | Destroying the primary node and recreating it from this repo and backups, timed. | A restart. |
| **RPO** | Recovery point objective: the maximum acceptable data loss, measured in time. | Backup frequency (related, not identical). |
| **RTO** | Recovery time objective: the maximum acceptable time to restore service. | Rebuild time (related, not identical). |
| **Free-tier risk** | The chance that a free resource is reclaimed, resized, capacity-blocked, or removed by the provider. | A normal outage. |
| **Home region** | The OCI region chosen at account creation. Always Free compute must run there and it cannot be changed later. | The nearest region to a user. |
| **A1** | Oracle's Arm-based Ampere compute shape, `VM.Standard.A1.Flex`. Currently 2 OCPU / 12 GB on Always Free. | The AMD `E2.1.Micro` shape. |
| **Warm standby** | A small paid node kept ready to take over, with the same Compose stack. | A backup. |
| **Static site** | Pre-built HTML/CSS/JS served by a CDN. No server-side process. | A web service. |
| **Web service** | A long-running HTTP process in a container, usually behind Caddy. | A scheduled job. |
| **Scheduled job** | A process that runs on a timetable (cron-like) and exits. | A triggered job. |
| **Triggered job** | A process started by an event (webhook, queue message, user action). | A request/response API. |
| **Dead-man's switch** | An external check that alerts when a job or service stops reporting. | A health check that only runs on the box. |
| **Issue tracker** | The single queue for bugs, features, client requests, and ops work. Phase 1: GitHub Issues + Projects. | A chat thread or a TODO list. |
| **Triage** | The recurring act of assigning type, priority, area, and client to a new issue. | Fixing the issue. |
| **Intake** | The inbound surface where requests arrive: templates, email, Telegram, CI, Sentry. | The tracker itself. |
| **Bridge** | A small service that translates webhooks or messages between systems, for example Telegram to a tracker. | A native integration. |
| **Iteration** | One bounded window of work, represented by one GitHub milestone named `iteration-NN: <theme>`, ending in a retro. | A sprint of fixed calendar length; there is no fixed length here yet. |
| **Retro gate** | The check that an iteration has no open issues before `ce-retro` runs. `make iteration-check` fails while any remain. | The retro itself. |
| **Carry-over** | An issue moved from one iteration to the next with a recorded reason. Bounded to two per iteration. | Reopening a closed iteration. |
| **Escape hatch** | A documented, scripted, and drilled path from a proprietary tool to a FOSS one, with a bounded migration time. Required by ADR-0005, not optional. | A vague intention to migrate someday. |
| **Portability exit** | A documented path that moves a workload to another provider or a managed service. FOSS is not the point; avoiding operational lock-in is. | An escape hatch, which is specifically about replacing proprietary software. |
| **Client** | The engagement: a person or company that pays for work. | A client site. |
| **Client site** | One deployment serving one domain: its own Compose project, database, database user, and subdomain. | The client. |
| **Project slug** | The short name used in domains, Compose project names, image names, and directories. Current: `antwater`. | A client slug, which names one client site. |
| **Client-ready** | Has backups, monitoring, a support boundary, and a documented handover. | Feature-complete. |
| **Revenue-ready** | Has per-project cost tracking, an SLA, and a migration path. | Client-ready. |
