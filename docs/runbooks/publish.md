# Publish runbook: taking this repo public

**Publishing is effectively irreversible.** Forks, crawlers, and archive services copy a public repository within minutes. Scrubbing after the flip does not undo it: rewriting history leaves the old objects in any fork that already exists, and those are not yours to delete.

So: everything in "Before you flip" happens **before** the visibility change, and nothing is left to "we'll fix it after launch".

## Before you flip

### 1. Decide the three judgment calls

| Item | Why it matters | Default |
|---|---|---|
| **Brand name (`antwater`)** | Publishing reserves nothing and reveals the name before launch; domain and handle squatting become possible | Scrub to a placeholder, or buy the domain and lock the handles first |
| **Optional worker timing** | "A Windows laptop joins a Tailscale tailnet on 2026-12-06" is a date, a machine model, and an attack window | Replace with "available in the coming weeks" |
| **Operator identity and revenue plan** | `STRATEGY.md` names the operator and the pricing direction | Accept it; the repo sits on a public GitHub profile anyway, and the plan is not the moat |

To scrub the brand and the date in one pass:

```bash
grep -rl 'antwater' --exclude-dir=.git . | xargs sed -i '' 's/antwater/<slug>/g'
grep -rl '2026-12-06' --exclude-dir=.git . | xargs sed -i '' 's/2026-12-06/soon/g'
```

Then fix the grammar by hand. A blind `sed` leaves sentences like "every hostname derives from `<slug>`", which is fine, and "from ~soon", which is not.

### 2. Prove no credential reached history

```bash
# every path ever committed, filtered to secrets-shaped names
git rev-list --objects --all | awk '{print $2}' \
  | grep -Ei '(^|/)(\.env$|.*\.tfvars$|.*\.tfstate|.*\.pem$|.*\.key$|id_rsa|id_ed25519)' \
  && echo "REVIEW THESE" || echo "clean"

# full-history content scan
gitleaks detect --source . --log-opts="--all" --verbose

# a real .tfvars must be ignored, not merely absent
touch infra/oracle/terraform.tfvars
git status --porcelain infra/oracle/terraform.tfvars   # must print nothing
rm infra/oracle/terraform.tfvars
```

If gitleaks finds anything, **rotate the credential first**, then decide whether history rewriting is worth it. Rotation is the fix; hiding the blob is cosmetic.

### 3. Close the footguns

- `.gitignore` must cover `*.tfvars` — a real tfvars carries the SSH public key, the operator's home CIDR, and the Tailscale auth key. Covered since 2026-11-23.
- `git add -A` is what makes this dangerous. Prefer `git add <path>` for infrastructure changes.
- Confirm `.env` is untracked and `.env.example` holds placeholders only.

### 4. Decide where client work lives

A public repository means **public issues**. Client requests, bug reports, screenshots, and log excerpts become world-readable and searchable, and they stay that way after the client is gone.

This contradicts the assumption in ADR-0005. Choose one:

- **(a) Recommended.** Keep `dev-platform` public as the reference design. Put client sites in separate **private** repositories with their own tracker. The public repo links to nothing client-specific.
- **(b)** Keep one repository and accept that client work is public.
- **(c)** Move the tracker to a private tool and leave Issues disabled here.

Either way: never paste a log with a token into an issue, public or private.

### 5. Decide the licence

No `LICENSE` file means **all rights reserved**: people may read the repository but not reuse it. That is the correct default if the goal is "reference, not giveaway".

If you want reuse, split it: MIT or Apache-2.0 for `scripts/` and `infra/`, CC-BY-4.0 for `docs/`, and say so in `README.md`.

## Flip

```bash
gh repo edit --visibility public --accept-visibility-change-consequences
```

## Immediately after

Settings → Code security, in this order:

1. **Secret scanning** — on. Free for public repos, and it scans the entire history.
2. **Push protection** — on. It is the only control that stops a credential before it lands.
3. **Dependabot alerts** and **Dependabot security updates** — on.
4. **CodeQL default setup** — on for the shell and Terraform surface. Cheap, and it gives a public badge of diligence.
5. **Private vulnerability reporting** — on. `SECURITY.md` already points at it.

Settings → Actions:

6. Default workflow permissions: **read-only**.
7. Fork pull request workflows: **require approval** for all outside collaborators.
8. If a deploy job is added later, put it behind a `production` environment with required reviewers.

Then:

```bash
gh api repos/KshitijV97/dev-platform --jq '.security_and_analysis'
```

and confirm the toggles are actually on, because the API silently returns `null` when a feature is unavailable rather than complaining.

## What is safe to publish

Architecture, ADRs, runbooks, cost tables, and Terraform scaffolding with placeholder OCIDs. This is the commodity part of the stack, and it is also the part that makes you look like someone who finishes things. Publishing it costs no advantage.

Public repositories also get **unlimited GitHub Actions minutes**, which quietly removes the 2,000-minute ceiling this design was budgeting around.

## What is not safe to publish

- Client identities, pricing, contracts, or anything a client said in confidence.
- Live credentials, even expired ones — they reveal shape and naming.
- Hostnames or IPs of running hosts. Hidden behind Cloudflare or not.
- The brand before it is registered.
- The exact date a lightly-hardened machine joins your tailnet.
- Screenshots of a terminal, a dashboard, or an error page that contain a token, an email address, or a customer name.

## Revisit

- Before the first client: re-run this checklist and confirm client work lives in a private repository.
- Quarterly: review secret-scanning alerts and the fork network.
- After any incident: assume anything published is known to the attacker.
