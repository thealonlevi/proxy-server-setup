#!/usr/bin/env bash
set -euo pipefail

SYSCTL_URL="${SYSCTL_URL:-https://raw.githubusercontent.com/REPLACE_ME_USER/REPLACE_ME_REPO/main/99-custom.conf}"
MAX_ULIMIT="${MAX_ULIMIT:-1048576}"

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true

cat > /etc/resolv.conf << 'EOF'
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 2606:4700:4700::1111
nameserver 2606:4700:4700::1001
EOF

curl -fsSL "$SYSCTL_URL" -o /etc/sysctl.d/99-custom.conf

sysctl --system

cat > /etc/security/limits.d/proxy-nofile.conf << EOF
* soft nofile $MAX_ULIMIT
* hard nofile $MAX_ULIMIT
EOF

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

for port in 25 465 587 110 995 143 993; do
    iptables -A INPUT -p tcp --dport "$port" -j DROP
    iptables -A OUTPUT -p tcp --dport "$port" -j DROP
done

iptables-save > /etc/iptables/rules.v4

echo "Proxy server setup completed successfully"

