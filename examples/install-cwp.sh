#!/usr/bin/env bash
# =============================================================================
# Example: Install CWP on AlmaLinux 9
# =============================================================================
# This script demonstrates how to install Control Web Panel (CWP) on a fresh
# AlmaLinux 9 server. Run as root.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()       { log_error "$@"; exit 1; }

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
echo -e "${BOLD}=== CWP Installation on AlmaLinux 9 ===${NC}"

# Check root
[[ $EUID -eq 0 ]] || die "This script must be run as root."

# Check OS
if [[ ! -f /etc/almalinux-release ]] && [[ ! -f /etc/centos-release ]]; then
    log_warn "This script is designed for AlmaLinux/CentOS. Detected:"
    cat /etc/os-release 2>/dev/null | head -3
    read -rp "Continue anyway? (y/N): " confirm
    [[ "$confirm" == "y" ]] || exit 1
fi

# Check RAM
local_mem=$(free -m | awk '/Mem:/{print $2}')
if [[ "$local_mem" -lt 1024 ]]; then
    die "Minimum 1GB RAM required. Found: ${local_mem}MB"
fi
log_info "RAM: ${local_mem}MB OK"

# Check disk
local_disk=$(df -BG / | awk 'NR==2{gsub("G",""); print $4}')
if [[ "$local_disk" -lt 20 ]]; then
    die "Minimum 20GB free disk space required. Found: ${local_disk}GB"
fi
log_info "Disk: ${local_disk}GB free OK"

# ---------------------------------------------------------------------------
# Set hostname
# ---------------------------------------------------------------------------
echo ""
read -rp "Enter server hostname (e.g., server.example.com): " HOSTNAME
if [[ -n "$HOSTNAME" ]]; then
    hostnamectl set-hostname "$HOSTNAME"
    log_info "Hostname set to: $HOSTNAME"
fi

# ---------------------------------------------------------------------------
# Update system
# ---------------------------------------------------------------------------
log_info "Updating system packages..."
dnf update -y
dnf install -y wget curl perl net-tools bash-completion

# ---------------------------------------------------------------------------
# Disable SELinux (required for CWP)
# ---------------------------------------------------------------------------
log_info "Disabling SELinux..."
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 2>/dev/null || true
log_info "SELinux disabled."

# ---------------------------------------------------------------------------
# Configure firewall
# ---------------------------------------------------------------------------
log_info "Configuring firewall..."
if systemctl is-active firewalld &>/dev/null; then
    # CWP ports
    firewall-cmd --permanent --add-port=2030/tcp   # CWP Admin
    firewall-cmd --permanent --add-port=2031/tcp   # CWP User Panel
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --add-service=smtp
    firewall-cmd --permanent --add-service=smtps
    firewall-cmd --permanent --add-service=pop3
    firewall-cmd --permanent --add-service=pop3s
    firewall-cmd --permanent --add-service=imap
    firewall-cmd --permanent --add-service=imaps
    firewall-cmd --permanent --add-service=dns
    firewall-cmd --permanent --add-service=ftp
    firewall-cmd --permanent --add-port=22/tcp
    firewall-cmd --reload
    log_info "Firewall configured."
else
    log_warn "firewalld not running. Configure iptables manually."
fi

# ---------------------------------------------------------------------------
# Download and install CWP
# ---------------------------------------------------------------------------
log_info "Downloading CWP installer..."
cd /usr/local/src

# CWP for AlmaLinux 9 / RHEL 9
CWP_URL="https://dl.alui.cloud.eu.org/9/cwp-el9-latest.rpm"

if [[ ! -f "cwp-el9-latest.rpm" ]]; then
    wget "$CWP_URL" -O cwp-el9-latest.rpm || die "Failed to download CWP"
fi

log_info "Installing CWP..."
rpm -Uvh cwp-el9-latest.rpm || die "Failed to install CWP RPM"

# ---------------------------------------------------------------------------
# Run CWP installer
# ---------------------------------------------------------------------------
log_info "Running CWP installer (this will take 10-30 minutes)..."
echo "The installer will:"
echo "  - Install Apache, Nginx, MySQL/MariaDB"
echo "  - Install PHP (multiple versions)"
echo "  - Install Postfix, Dovecot, Pure-FTPd"
echo "  - Install BIND DNS server"
echo "  - Configure all services"
echo ""

read -rp "Proceed with installation? (y/N): " proceed
[[ "$proceed" == "y" ]] || die "Installation aborted."

sh /scripts/cwp-el9-latest || die "CWP installation failed"

# ---------------------------------------------------------------------------
# Post-install steps
# ---------------------------------------------------------------------------
log_info "CWP installation complete!"

echo ""
echo -e "${BOLD}=== Post-Installation Steps ===${NC}"
echo ""
echo "1. Access CWP Admin Panel:"
echo "   URL: https://$(hostname -I | awk '{print $1}'):2030"
echo "   Username: root"
echo "   Password: (your root password)"
echo ""
echo "2. Complete the setup wizard in the admin panel"
echo ""
echo "3. Configure your server:"
echo "   - Set nameservers"
echo "   - Configure PHP versions"
echo "   - Set up SSL for the panel"
echo "   - Create hosting packages"
echo ""
echo "4. Install CWP CLI (from this plugin):"
echo "   cd $(dirname "$0")/.."
echo "   bash scripts/install.sh"
echo "   cwp setup"
echo ""
echo "5. Recommended security hardening:"
echo "   bash examples/security-hardening.sh"
echo ""

log_info "Server will reboot in 10 seconds. Press Ctrl+C to cancel."
sleep 10
reboot
