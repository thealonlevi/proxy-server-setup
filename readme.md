# Proxy Server Setup Script (Riptide-Optimized)

A bash script to prepare an Ubuntu server for high-concurrency proxy workloads (Riptide/FlashProxy style).

## Overview

This script applies optimized system configurations for proxy servers, including:

- **Optimized sysctl configuration**: Tuned TCP memory buffers, reduced default socket buffers, high connection backlogs, BBR congestion control, and security hardening
- **Cloudflare DNS**: Configures resolv.conf to use Cloudflare's DNS servers (IPv4 and IPv6)
- **File descriptor limits**: Optional system-wide file descriptor limits via `/etc/security/limits.d/`
- **SMTP port blocking** (patcher.sh only): Blocks common SMTP and mail ports to prevent abuse

## System Requirements

**This configuration is tuned for a 40 vCPU, 124 GB RAM server.** If your server has different specifications (especially more CPU cores or RAM), you should adjust the sysctl values in `99-custom.conf` accordingly.

## Installation

### Full Patch (with SMTP blocking)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/thealonlevi/proxy-server-setup/main/patcher.sh)"
```

This script:
- Stops and disables systemd-resolved
- Configures Cloudflare DNS
- Downloads and applies optimized sysctl settings
- Sets file descriptor limits
- Installs iptables-persistent
- Blocks SMTP ports (25, 465, 587, 110, 995, 143, 993)

### Simple Patch (without SMTP blocking)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/thealonlevi/proxy-server-setup/main/simple-patch.sh)"
```

This script performs the same configuration as `patcher.sh` but skips iptables installation and SMTP port blocking. Use this if you don't need mail port restrictions.

## Notes

- **File descriptor limits**: This script sets system-wide limits via `/etc/security/limits.d/proxy-nofile.conf` for all users (`*`). For production proxy services, it's recommended to also set `LimitNOFILE` in your systemd service unit file for the proxy process. This provides more granular control and ensures the limit applies even if the system-wide limit changes.

- **Sysctl tuning**: The configuration in `99-custom.conf` is optimized for high-concurrency workloads. Key optimizations include:
  - BBR congestion control
  - Increased TCP memory buffers
  - High connection backlogs
  - Reduced TCP keepalive timers
  - Security hardening (source route filtering, redirect blocking, etc.)

- **Idempotency**: The scripts are designed to be run multiple times safely. They will overwrite existing configuration files. iptables rules are checked before adding to prevent duplicates.

- **Environment variables**: Advanced users can override defaults via environment variables:
  - `SYSCTL_URL`: Override the sysctl config URL (default: points to this repo)
  - `MAX_ULIMIT`: Override the file descriptor limit (default: 1048576)
  
  Example:
  ```bash
  MAX_ULIMIT=524288 sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/thealonlevi/proxy-server-setup/main/patcher.sh)"
  ```

## License

GPL-3.0

