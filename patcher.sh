#!/usr/bin/env bash
set -euo pipefail

SYSCTL_URL="${SYSCTL_URL:-https://raw.githubusercontent.com/thealonlevi/proxy-server-setup/main/99-custom.conf}"
MAX_ULIMIT="${MAX_ULIMIT:-1048576}"

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true

fix_resolv_conf() {
  if command -v chattr >/dev/null 2>&1; then
    chattr -i /etc/resolv.conf 2>/dev/null || true
  fi

  if [ -L /etc/resolv.conf ] || [ ! -e /etc/resolv.conf ]; then
    rm -f /etc/resolv.conf 2>/dev/null || true
  fi

  if ! cat > /etc/resolv.conf << 'EOF'; then
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 2606:4700:4700::1111
nameserver 2606:4700:4700::1001
EOF
    echo "Warning: failed to write /etc/resolv.conf, DNS may be broken" >&2
  fi

  chmod 644 /etc/resolv.conf 2>/dev/null || true
}

fix_resolv_conf

curl -fsSL "$SYSCTL_URL" -o /etc/sysctl.d/99-custom.conf
sysctl --system

cat > /etc/security/limits.d/proxy-nofile.conf << EOF
* soft nofile $MAX_ULIMIT
* hard nofile $MAX_ULIMIT
EOF

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

for port in 25 465 587 110 995 143 993; do
  if ! iptables -C INPUT -p tcp --dport "$port" -j DROP 2>/dev/null; then
    iptables -A INPUT -p tcp --dport "$port" -j DROP
  fi
  if ! iptables -C OUTPUT -p tcp --dport "$port" -j DROP 2>/dev/null; then
    iptables -A OUTPUT -p tcp --dport "$port" -j DROP
  fi
done

iptables-save > /etc/iptables/rules.v4

echo "Proxy server setup completed successfully"
