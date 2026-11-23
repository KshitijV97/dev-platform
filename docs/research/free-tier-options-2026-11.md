# Free-tier research

Checked 2026-11-22. Free tiers change without notice; verify before relying on any number.

## Compute

| Provider | Canadian region | Free period | Included | Main catch |
|---|---|---|---|---|
| **Oracle Always Free** | `ca-toronto-1`, `ca-montreal-1` | Indefinite | 2 ARM OCPU / 12 GB, 2× AMD micro (1 GB), 200 GB block, 10 TB egress/month | Capacity errors; idle reclamation; ARM; allowance halved from 4/24 in June 2026 |
| **Azure free account** | Canada Central | 12 months | 750 h/mo of B1s, B2ats v2, or B2pts v2; 2×64 GB disks; $200 credit for 30 days | Credit expires at 30 days; B1s is being retired in some regions |
| **AWS Free Plan** | `ca-central-1` | 6 months | $100 + up to $100 credits | 12-month EC2 tier removed for accounts after 2025-07-15 |
| **GCP Free Trial** | Montreal, Toronto | 90 days | $300 credit | No always-free VM in Canada |
| **GCP Always Free** | US only for `e2-micro` | Indefinite | 1 `e2-micro`, 30 GB disk, 1 GB egress/month | Regions `us-west1`, `us-central1`, `us-east1` only |

### Oracle Always Free details

- `VM.Standard.A1.Flex`: 1,500 OCPU-hours and 9,000 GB-hours per month, equivalent to **2 OCPU / 12 GB** always-on.
- AMD `VM.Standard.E2.1.Micro`: 1/8 OCPU, 1 GB, up to two instances.
- 200 GB total block storage; 20 GB object storage; 10 TB/month outbound.
- Idle reclamation: over 7 days, 95th-percentile CPU < 20%, network < 20%, and A1 memory < 20%.
- Home region is fixed at signup; Always Free compute runs only there.
- The A1 allowance was halved from 4 OCPU / 24 GB to 2 OCPU / 12 GB on 2026-06-15 without a public announcement.

## Developer platform

| Service | Free allowance | Notes |
|---|---|---|
| **GitHub Actions** | 2,000 min/month private; free for public repos | Self-hosted runners are free |
| **GitHub Codespaces** | 120 core-hours/month, 15 GB-month storage | 60 hours on a 2-core machine |
| **GCP Cloud Shell** | 50 hours/week, 5 GB persistent | Ephemeral VM; 1-hour idle timeout |
| **Cloudflare Pages** | Unlimited static requests and bandwidth; 500 builds/month; 20,000 files | Good for static sites |
| **Cloudflare Workers** | 100,000 requests/day | Edge functions, not a VPS |

## Observability and tracking

| Service | Free allowance | Notes |
|---|---|---|
| **Healthchecks.io** | 20 checks, 3 team members | Dead-man's switch for cron and jobs |
| **Sentry** | 5,000 errors/month, 1 user, 5M spans, 50 replays | Developer plan |
| **Grafana Cloud** | 10k metrics series, 50 GB logs, 50 GB traces, 3 users, 14-day retention | Heavier than needed initially |
| **Uptime Kuma** | Self-hosted | On-box; pair with an external check |
| **Dozzle** | Self-hosted | Docker log viewer |
| **GitHub Issues** | Unlimited issues | Proprietary |
| **GitLab Free** | Unlimited issues, 5 users, 400 CI min/month, 10 GB/project | Native Telegram |
| **Plane Free** | 12 users, core PM, in-app Intake | GitHub/GitLab/Sentry integrations are paid |
| **Huly Common** | Unlimited users, unlimited objects, 10 GB | Native Telegram and GitHub sync; SDK-first API |
| **YouTrack Free** | 10 users, 30 GB | Proprietary; strong REST API |
| **Forgejo** | Self-host only | Fully FOSS; issues, repos, Actions |

## Network and access

| Service | Free allowance | Notes |
|---|---|---|
| **Tailscale** | 6 users, user devices unlimited; tagged resources limited | MagicDNS, SSH, ACLs |
| **Cloudflare DNS** | Free | Proxy, TLS, analytics |

## Sources

- Oracle Always Free resources: https://docs.oracle.com/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm
- Oracle regions: https://docs.oracle.com/iaas/Content/General/Concepts/regions.htm
- Oracle A1 halving (2026-06): https://www.infoq.com/news/2026/07/oracle-cloud-free-tier-limits/
- Azure free account: https://azure.microsoft.com/en-ca/free/
- AWS Free Tier: https://aws.amazon.com/free/
- GCP free features: https://cloud.google.com/free/docs/always-free-usage-limits
- Cloudflare Pages limits: https://developers.cloudflare.com/pages/platform/limits/
- GitHub Actions billing: https://docs.github.com/billing/managing-billing-for-github-actions/about-billing-for-github-actions
- GitHub Codespaces billing: https://docs.github.com/billing/managing-billing-for-github-codespaces/about-billing-for-github-codespaces
- Healthchecks.io pricing: https://healthchecks.io/pricing
- Sentry pricing: https://sentry.io/pricing/
- Grafana Cloud free tier: https://grafana.com/products/cloud/free-tier
- Plane pricing: https://plane.so/pricing
- GitLab free user limit: https://docs.gitlab.com/user/free_user_limit
- GitLab Telegram: https://docs.gitlab.com/user/project/integrations/telegram/
- Huly pricing: https://huly.io/pricing
- Huly GitHub: https://docs.huly.io/integrations/github
- YouTrack pricing: https://www.jetbrains.com/youtrack/buy/
- Forgejo API: https://forgejo.org/docs/latest/user/api/
- Tailscale pricing: https://tailscale.com/pricing
