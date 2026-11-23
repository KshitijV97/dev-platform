#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu 24.04 host. Run as root.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run as root" >&2
  exit 1
fi

DEPLOY_USER="${DEPLOY_USER:-deploy}"

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  docker-compose-v2 \
  docker.io \
  fail2ban \
  git \
  jq \
  ufw \
  unattended-upgrades

systemctl enable --now docker

if ! id -u "${DEPLOY_USER}" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "${DEPLOY_USER}"
fi
usermod -aG sudo,docker "${DEPLOY_USER}"

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

systemctl enable --now fail2ban
systemctl enable --now unattended-upgrades

if [[ ! -f /swapfile ]]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "bootstrap complete; add the deploy user's SSH key, then close port 22 after Tailscale works"
