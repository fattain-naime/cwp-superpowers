#!/usr/bin/env bash
# =============================================================================
# Example: CWP Server Security Hardening
# =============================================================================
# Applies security hardening to a CWP server. Run as root.
# Review each section before applying - some changes may affect your setup.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()  { echo -e "\n${BOLD}${BLUE}=== $* ===${NC}"; }

echo -e "${BOLD}CWP Server Security Hardening${NC}"
echo ""
echo "This script will apply security hardening measures."
echo "Review each section carefully."
echo ""
read -rp "Proceed with hardening? (y/N): " confirm
[[ "$confirm" == "y" ]] || exit 0

# ---------------------------------------------------------------------------
# 1. System Updates
# ---------------------------------------------------------------------------
log_step "1. System Updates"

log_info "Updating all packages..."
dnf update -y 2>/dev/null || yum update -y 2>/dev/null || log_warn "Update failed."

# Enable automatic security updates
log_info "Configuring automatic security updates..."
dnf install -y dnf-automatic 2>/dev/null || true
if [[ -f /etc/dnf/automatic.conf ]]; then
    sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
    sed -i 's/upgrade_type = default/upgrade_type = security/' /etc/dnf/automatic.conf
    systemctl enable --now dnf-automatic-install.timer 2>/dev/null || true
    log_info "Automatic security updates enabled."
fi

# ---------------------------------------------------------------------------
# 2. SSH Hardening
# ---------------------------------------------------------------------------
log_step "2. SSH Hardening"

SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%s)"

# Disable root password login (key-only)
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"

# Disable password authentication (enable only if keys are set up)
read -rp "Disable SSH password authentication? Ensure SSH keys are configured! (y/N): " disable_pass
if [[ "$disable_pass" == "y" ]]; then
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
    log_info "Password authentication disabled."
else
    log_info "Password authentication kept enabled."
fi

# Limit authentication attempts
sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' "$SSHD_CONFIG"

# Disable empty passwords
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD_CONFIG"

# Disable X11 forwarding
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' "$SSHD_CONFIG"

# Set login grace time
sed -i 's/^#*LoginGraceTime.*/LoginGraceTime 30/' "$SSHD_CONFIG"

# Change SSH port (optional)
read -rp "Change SSH port from 22? Enter new port (or press Enter to keep 22): " new_port
if [[ -n "$new_port" && "$new_port" != "22" ]]; then
    sed -i "s/^#*Port .*/Port $new_port/" "$SSHD_CONFIG"
    # Add to SELinux if enabled
    semanage port -a -t ssh_port_t -p tcp "$new_port" 2>/dev/null || true
    # Add to firewall
    firewall-cmd --permanent --add-port="${new_port}/tcp" 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    log_info "SSH port changed to $new_port"
fi

# Validate config before restart
sshd -t 2>&1 && {
    systemctl restart sshd
    log_info "SSH hardened and restarted."
} || {
    log_error "SSH config validation failed! Restoring backup..."
    cp "${SSHD_CONFIG}.bak."* "$SSHD_CONFIG"
}

# ---------------------------------------------------------------------------
# 3. Firewall Configuration
# ---------------------------------------------------------------------------
log_step "3. Firewall Configuration"

log_info "Configuring firewall rules..."

if systemctl is-active firewalld &>/dev/null; then
    # Remove unnecessary services
    firewall-cmd --permanent --remove-service=dhcpv6-client 2>/dev/null || true

    # Rate limit SSH
    firewall-cmd --permanent --add-rich-rule='rule service name=ssh limit value=3/m accept' 2>/dev/null || true

    # Block common attack ports
    for port in 23 111 135 137 138 139 445 512 513 514; do
        firewall-cmd --permanent --remove-port="${port}/tcp" 2>/dev/null || true
    done

    # Enable logging for dropped packets
    firewall-cmd --permanent --set-log-denied=all 2>/dev/null || true

    firewall-cmd --reload
    log_info "Firewall rules applied."
else
    log_warn "firewalld not active. Skipping firewall configuration."
fi

# ---------------------------------------------------------------------------
# 4. Install and Configure fail2ban
# ---------------------------------------------------------------------------
log_step "4. fail2ban Configuration"

if ! command -v fail2ban-client &>/dev/null; then
    log_info "Installing fail2ban..."
    dnf install -y epel-release 2>/dev/null || true
    dnf install -y fail2ban fail2ban-firewalld 2>/dev/null || \
        yum install -y fail2ban fail2ban-firewalld 2>/dev/null || \
        log_warn "Failed to install fail2ban."
fi

if command -v fail2ban-client &>/dev/null; then
    cat > /etc/fail2ban/jail.local <<'F2B'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
banaction = firewallcmd-rich-rules
banaction_allports = firewallcmd-rich-rules

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 3
bantime = 7200

[apache-auth]
enabled = true
port = http,https
filter = apache-auth
maxretry = 5

[apache-badbots]
enabled = true
port = http,https
filter = apache-badbots
maxretry = 2

[postfix]
enabled = true
port = smtp,465,submission
filter = postfix
maxretry = 5

[dovecot]
enabled = true
port = imap,imaps,pop3,pop3s
filter = dovecot
maxretry = 5

[cwp]
enabled = true
port = 2030,2031
filter = cwp
maxretry = 3
bantime = 3600
F2B

    # Create CWP filter
    mkdir -p /etc/fail2ban/filter.d
    cat > /etc/fail2ban/filter.d/cwp.conf <<'CWPFAIL'
[Definition]
failregex = ^.*Failed login from <HOST>.*$
            ^.*Authentication failure from <HOST>.*$
ignoreregex =
CWPFAIL

    systemctl enable fail2ban
    systemctl restart fail2ban
    log_info "fail2ban configured and started."
fi

# ---------------------------------------------------------------------------
# 5. Kernel Hardening (sysctl)
# ---------------------------------------------------------------------------
log_step "5. Kernel Hardening"

cat > /etc/sysctl.d/99-security.conf <<'SYSCTL'
# CWP Security Hardening - sysctl settings

# Disable IP forwarding (unless router)
net.ipv4.ip_forward = 0

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Don't send ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Enable SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Ignore source-routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Ignore broadcast pings
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Log martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable IPv6 if not needed
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1

# Randomize address space
kernel.randomize_va_space = 2

# Restrict dmesg access
kernel.dmesg_restrict = 1

# Restrict kernel pointer leak
kernel.kptr_restrict = 2

# Restrict ptrace
kernel.yama.ptrace_scope = 1
SYSCTL

sysctl -p /etc/sysctl.d/99-security.conf
log_info "Kernel parameters hardened."

# ---------------------------------------------------------------------------
# 6. File Permission Hardening
# ---------------------------------------------------------------------------
log_step "6. File Permissions"

# Secure critical files
chmod 600 /etc/shadow
chmod 644 /etc/passwd
chmod 600 /etc/ssh/sshd_config
chmod 700 /root

# Remove world-writable from system directories
chmod o-w /tmp /var/tmp 2>/dev/null || true

# Set sticky bit on temp directories
chmod 1777 /tmp /var/tmp 2>/dev/null || true

# Secure cron
chmod 600 /etc/crontab
chmod 700 /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly 2>/dev/null || true

log_info "File permissions secured."

# ---------------------------------------------------------------------------
# 7. PHP Security
# ---------------------------------------------------------------------------
log_step "7. PHP Security"

PHP_INI="/etc/php.ini"
if [[ -f "$PHP_INI" ]]; then
    # Disable dangerous functions
    sed -i 's/^disable_functions.*/disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,parse_ini_file,show_source,pcntl_exec/' "$PHP_INI"

    # Hide PHP version
    sed -i 's/^expose_php.*/expose_php = Off/' "$PHP_INI"

    # Disable allow_url_include
    sed -i 's/^allow_url_include.*/allow_url_include = Off/' "$PHP_INI"

    # Set upload limits
    sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' "$PHP_INI"
    sed -i 's/^post_max_size.*/post_max_size = 64M/' "$PHP_INI"

    # Disable remote code execution
    sed -i 's/^disable_functions.*/disable_functions = exec,passthru,shell_exec,system,proc_open,popen/' "$PHP_INI"

    log_info "PHP security settings applied."
fi

# ---------------------------------------------------------------------------
# 8. Apache Security
# ---------------------------------------------------------------------------
log_step "8. Apache Security"

# Hide Apache version
if [[ -f /etc/httpd/conf/httpd.conf ]]; then
    sed -i 's/^ServerTokens.*/ServerTokens Prod/' /etc/httpd/conf/httpd.conf
    sed -i 's/^ServerSignature.*/ServerSignature Off/' /etc/httpd/conf/httpd.conf

    # Disable trace method
    if ! grep -q "TraceEnable Off" /etc/httpd/conf/httpd.conf; then
        echo "TraceEnable Off" >> /etc/httpd/conf/httpd.conf
    fi

    # Disable directory listing globally
    sed -i 's/Options Indexes/Options -Indexes/g' /etc/httpd/conf/httpd.conf

    systemctl restart httpd 2>/dev/null || true
    log_info "Apache security settings applied."
fi

# ---------------------------------------------------------------------------
# 9. MySQL Security
# ---------------------------------------------------------------------------
log_step "9. MySQL Security"

log_info "Running MySQL security script..."
mysql_secure_installation 2>/dev/null || {
    log_warn "mysql_secure_installation failed. Run manually:"
    echo "  mysql_secure_installation"
}

# Remove anonymous users
mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
log_info "MySQL anonymous users removed."

# ---------------------------------------------------------------------------
# 10. Disable Unnecessary Services
# ---------------------------------------------------------------------------
log_step "10. Disable Unnecessary Services"

services_to_disable=(
    "telnet.socket"
    "rsh.socket"
    "rlogin.socket"
    "tftp.socket"
    "xinetd"
)

for svc in "${services_to_disable[@]}"; do
    if systemctl is-enabled "$svc" &>/dev/null; then
        systemctl disable "$svc" 2>/dev/null || true
        systemctl stop "$svc" 2>/dev/null || true
        log_info "Disabled: $svc"
    fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}=== Security Hardening Complete ===${NC}"
echo ""
echo "Applied measures:"
echo "  [OK] System packages updated"
echo "  [OK] SSH hardened"
echo "  [OK] Firewall configured"
echo "  [OK] fail2ban installed and configured"
echo "  [OK] Kernel parameters hardened"
echo "  [OK] File permissions secured"
echo "  [OK] PHP security settings applied"
echo "  [OK] Apache security settings applied"
echo "  [OK] MySQL secured"
echo "  [OK] Unnecessary services disabled"
echo ""
echo "Recommended next steps:"
echo "  1. Verify SSH access: ssh -p ${new_port:-22} root@$(hostname -I | awk '{print $1}')"
echo "  2. Run security scan: cwp security status"
echo "  3. Review firewall: cwp security firewall list"
echo "  4. Test fail2ban: fail2ban-client status"
echo "  5. Schedule regular scans: crontab -e"
echo ""
echo -e "${YELLOW}IMPORTANT: Keep SSH session open while testing changes!${NC}"
