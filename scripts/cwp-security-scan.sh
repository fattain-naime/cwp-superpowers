#!/usr/bin/env bash
# =============================================================================
# CWP Security Scanner - Scan CWP server for security issues
# =============================================================================
# Usage: cwp-security-scan.sh [options]
# =============================================================================
set -euo pipefail

readonly VERSION="1.0.0"
readonly CONFIG_FILE="${CWP_CLI_CONF:-$HOME/.cwp-cli.conf}"

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

CWP_HOST="${CWP_HOST:-}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

CRITICAL=0
WARNING=0
INFO=0
PASS=0

log_critical() { echo -e "${RED}[CRITICAL]${NC} $*"; ((CRITICAL++)) || true; }
log_warning()  { echo -e "${YELLOW}[WARNING]${NC} $*"; ((WARNING++)) || true; }
log_pass()     { echo -e "${GREEN}[PASS]${NC} $*"; ((PASS++)) || true; }
log_info()     { echo -e "${CYAN}[INFO]${NC} $*"; ((INFO++)) || true; }
log_header()   { echo -e "\n${BOLD}${BLUE}--- $* ---${NC}"; }

# ---------------------------------------------------------------------------
# SSH helper
# ---------------------------------------------------------------------------
remote_exec() {
    local cmd=("ssh" "-o" "StrictHostKeyChecking=accept-new" "-o" "ConnectTimeout=10" "-o" "BatchMode=yes")
    [[ -n "$SSH_KEY" ]] && cmd+=("-i" "$SSH_KEY")
    cmd+=("-p" "$SSH_PORT" "${SSH_USER}@${CWP_HOST}")
    "${cmd[@]}" "$@" 2>/dev/null
}

remote_exec_sudo() {
    remote_exec "sudo bash -c '$*'"
}

# ---------------------------------------------------------------------------
# Scan: System updates
# ---------------------------------------------------------------------------
scan_updates() {
    log_header "System Updates"

    local kernel_version
    kernel_version=$(remote_exec "uname -r" || echo "unknown")
    log_info "Kernel: $kernel_version"

    local updates_available
    updates_available=$(remote_exec_sudo "yum check-update --quiet 2>/dev/null | wc -l" || echo "0")
    if [[ "$updates_available" -gt 0 ]]; then
        log_warning "$updates_available package updates available"
    else
        log_pass "System is up to date"
    fi

    local security_updates
    security_updates=$(remote_exec_sudo "yum check-update --security --quiet 2>/dev/null | wc -l" || echo "0")
    if [[ "$security_updates" -gt 0 ]]; then
        log_critical "$security_updates security updates pending"
    else
        log_pass "No pending security updates"
    fi
}

# ---------------------------------------------------------------------------
# Scan: SSH security
# ---------------------------------------------------------------------------
scan_ssh() {
    log_header "SSH Security"

    local sshd_config
    sshd_config=$(remote_exec "cat /etc/ssh/sshd_config 2>/dev/null" || echo "")

    if [[ -z "$sshd_config" ]]; then
        log_warning "Could not read sshd_config"
        return
    fi

    # Check root login
    local root_login
    root_login=$(echo "$sshd_config" | grep -i "^PermitRootLogin" | awk '{print $2}' | head -1)
    if [[ "$root_login" == "yes" ]]; then
        log_critical "SSH: PermitRootLogin is 'yes' - should be 'prohibit-password' or 'no'"
    elif [[ "$root_login" == "prohibit-password" || "$root_login" == "no" ]]; then
        log_pass "SSH: Root login restricted ($root_login)"
    else
        log_warning "SSH: PermitRootLogin not explicitly set (default: yes)"
    fi

    # Check password auth
    local pass_auth
    pass_auth=$(echo "$sshd_config" | grep -i "^PasswordAuthentication" | awk '{print $2}' | head -1)
    if [[ "$pass_auth" == "yes" ]]; then
        log_warning "SSH: Password authentication enabled - consider key-only auth"
    elif [[ "$pass_auth" == "no" ]]; then
        log_pass "SSH: Password authentication disabled"
    fi

    # Check SSH port
    local ssh_port
    ssh_port=$(echo "$sshd_config" | grep -i "^Port " | awk '{print $2}' | head -1)
    if [[ -z "$ssh_port" ]]; then
        ssh_port="22 (default)"
    fi
    if [[ "$ssh_port" == "22" || "$ssh_port" == "22 (default)" ]]; then
        log_info "SSH: Using default port 22 - consider changing"
    else
        log_pass "SSH: Using non-default port $ssh_port"
    fi

    # Check MaxAuthTries
    local max_auth
    max_auth=$(echo "$sshd_config" | grep -i "^MaxAuthTries" | awk '{print $2}' | head -1)
    if [[ -n "$max_auth" && "$max_auth" -le 5 ]]; then
        log_pass "SSH: MaxAuthTries = $max_auth"
    else
        log_warning "SSH: MaxAuthTries not set or too high (default: 6)"
    fi
}

# ---------------------------------------------------------------------------
# Scan: Firewall
# ---------------------------------------------------------------------------
scan_firewall() {
    log_header "Firewall"

    local iptables_rules
    iptables_rules=$(remote_exec_sudo "iptables -L -n 2>/dev/null | wc -l" || echo "0")

    if [[ "$iptables_rules" -le 3 ]]; then
        log_critical "Firewall: No iptables rules configured!"
    else
        log_pass "Firewall: iptables rules configured ($iptables_rules lines)"
    fi

    # Check for open ports
    local open_ports
    open_ports=$(remote_exec_sudo "ss -tlnp 2>/dev/null | grep LISTEN | awk '{print \$4}' | sed 's/.*://' | sort -un" || echo "")
    if [[ -n "$open_ports" ]]; then
        log_info "Open listening ports: $(echo "$open_ports" | tr '\n' ' ')"
    fi

    # Check fail2ban
    local f2b_status
    f2b_status=$(remote_exec_sudo "systemctl is-active fail2ban 2>/dev/null" || echo "inactive")
    if [[ "$f2b_status" == "active" ]]; then
        log_pass "fail2ban is active"
    else
        log_warning "fail2ban is not running"
    fi
}

# ---------------------------------------------------------------------------
# Scan: SSL/TLS
# ---------------------------------------------------------------------------
scan_ssl() {
    log_header "SSL/TLS"

    # Check Let's Encrypt certificates
    local le_certs
    le_certs=$(remote_exec_sudo "ls /etc/letsencrypt/live/ 2>/dev/null" || echo "")

    if [[ -n "$le_certs" ]]; then
        log_info "Let's Encrypt domains: $(echo "$le_certs" | tr '\n' ' ')"

        # Check expiry
        while IFS= read -r domain; do
            [[ -z "$domain" ]] && continue
            local expiry
            expiry=$(remote_exec_sudo "openssl x509 -enddate -noout -in /etc/letsencrypt/live/${domain}/cert.pem 2>/dev/null" || echo "")
            if [[ -n "$expiry" ]]; then
                local expiry_date
                expiry_date=$(echo "$expiry" | cut -d= -f2)
                local expiry_epoch
                expiry_epoch=$(remote_exec "date -d '$expiry_date' +%s 2>/dev/null" || echo "0")
                local now_epoch
                now_epoch=$(remote_exec "date +%s" || echo "0")
                local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

                if [[ "$days_left" -lt 0 ]]; then
                    log_critical "SSL: $domain certificate EXPIRED!"
                elif [[ "$days_left" -lt 14 ]]; then
                    log_critical "SSL: $domain expires in $days_left days"
                elif [[ "$days_left" -lt 30 ]]; then
                    log_warning "SSL: $domain expires in $days_left days"
                else
                    log_pass "SSL: $domain valid for $days_left days"
                fi
            fi
        done <<< "$le_certs"
    else
        log_info "No Let's Encrypt certificates found"
    fi
}

# ---------------------------------------------------------------------------
# Scan: File permissions
# ---------------------------------------------------------------------------
scan_permissions() {
    log_header "File Permissions"

    # Check world-writable files in web roots
    local ww_files
    ww_files=$(remote_exec_sudo "find /home/*/public_html -type f -perm -o+w 2>/dev/null | wc -l" || echo "0")
    if [[ "$ww_files" -gt 0 ]]; then
        log_warning "Found $ww_files world-writable files in public_html"
    else
        log_pass "No world-writable files in public_html"
    fi

    # Check SUID files
    local suid_files
    suid_files=$(remote_exec_sudo "find /home -perm -4000 -type f 2>/dev/null | wc -l" || echo "0")
    if [[ "$suid_files" -gt 0 ]]; then
        log_warning "Found $suid_files SUID files in /home"
    else
        log_pass "No SUID files in /home"
    fi

    # Check /tmp permissions
    local tmp_perms
    tmp_perms=$(remote_exec_sudo "stat -c '%a' /tmp 2>/dev/null" || echo "unknown")
    if [[ "$tmp_perms" == "1777" ]]; then
        log_pass "/tmp has correct permissions (1777)"
    elif [[ "$tmp_perms" != "unknown" ]]; then
        log_warning "/tmp permissions are $tmp_perms (expected 1777)"
    fi

    # Check .htpasswd files are not world-readable
    local exposed_htpasswd
    exposed_htpasswd=$(remote_exec_sudo "find /home -name '.htpasswd' -perm -o+r 2>/dev/null | wc -l" || echo "0")
    if [[ "$exposed_htpasswd" -gt 0 ]]; then
        log_warning "Found $exposed_htpasswd world-readable .htpasswd files"
    else
        log_pass ".htpasswd files are properly restricted"
    fi
}

# ---------------------------------------------------------------------------
# Scan: CVE checks
# ---------------------------------------------------------------------------
scan_cves() {
    log_header "Known CVE Checks"

    # Check for common vulnerable packages
    local openssl_version
    openssl_version=$(remote_exec "openssl version 2>/dev/null" || echo "unknown")
    log_info "OpenSSL: $openssl_version"

    local apache_version
    apache_version=$(remote_exec "httpd -v 2>/dev/null | head -1" || echo "unknown")
    log_info "Apache: $apache_version"

    local mysql_version
    mysql_version=$(remote_exec_sudo "mysql --version 2>/dev/null" || echo "unknown")
    log_info "MySQL: $mysql_version"

    local php_version
    php_version=$(remote_exec "php -v 2>/dev/null | head -1" || echo "unknown")
    log_info "PHP: $php_version"

    # Check for outdated PHP versions
    if echo "$php_version" | grep -qE "PHP 5\.|PHP 7\.[0-3]\."; then
        log_critical "PHP version is outdated and unsupported"
    elif echo "$php_version" | grep -qE "PHP 7\.4\."; then
        log_warning "PHP 7.4 is in security-only mode"
    elif echo "$php_version" | grep -qE "PHP 8\.[0-2]\."; then
        log_pass "PHP version is supported"
    fi
}

# ---------------------------------------------------------------------------
# Scan: Services
# ---------------------------------------------------------------------------
scan_services() {
    log_header "Service Security"

    # Check if unnecessary services are running
    local services_to_check=("telnet" "rsh" "rlogin" "tftp" "vsftpd" "xinetd")
    for svc in "${services_to_check[@]}"; do
        local status
        status=$(remote_exec_sudo "systemctl is-active $svc 2>/dev/null" || echo "inactive")
        if [[ "$status" == "active" ]]; then
            log_warning "Potentially insecure service running: $svc"
        fi
    done

    # Check MySQL bind address
    local mysql_bind
    mysql_bind=$(remote_exec_sudo "grep -i 'bind-address' /etc/my.cnf 2>/dev/null | head -1" || echo "")
    if [[ -n "$mysql_bind" ]]; then
        if echo "$mysql_bind" | grep -q "0\.0\.0\.0"; then
            log_critical "MySQL: Bound to all interfaces (0.0.0.0)"
        else
            log_pass "MySQL: Bind address restricted"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print_summary() {
    echo ""
    echo -e "${BOLD}=== Security Scan Summary ===${NC}"
    echo -e "  ${RED}Critical:${NC}  $CRITICAL"
    echo -e "  ${YELLOW}Warnings:${NC}  $WARNING"
    echo -e "  ${GREEN}Passed:${NC}    $PASS"
    echo -e "  ${CYAN}Info:${NC}      $INFO"
    echo ""

    if [[ "$CRITICAL" -gt 0 ]]; then
        echo -e "${RED}${BOLD}SECURITY ISSUES DETECTED${NC} - $CRITICAL critical finding(s)."
        echo "Address critical issues immediately."
        exit 2
    elif [[ "$WARNING" -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}WARNINGS FOUND${NC} - $WARNING warning(s) detected."
        echo "Review and address warnings at your convenience."
        exit 1
    else
        echo -e "${GREEN}${BOLD}ALL CHECKS PASSED${NC} - No issues detected."
        exit 0
    fi
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}CWP Security Scanner${NC} v${VERSION}

${BOLD}USAGE:${NC}
    $0 [options]

${BOLD}OPTIONS:${NC}
    --host <host>      CWP server hostname or IP
    --ssh-user <user>  SSH username (default: root)
    --ssh-port <port>  SSH port (default: 22)
    --ssh-key <path>   SSH private key file
    -h, --help         Show this help

${BOLD}SCANS PERFORMED:${NC}
    - System updates and security patches
    - SSH configuration hardening
    - Firewall rules and fail2ban status
    - SSL certificate expiration
    - File permission issues
    - Known CVE checks (PHP, OpenSSL, Apache)
    - Insecure service detection

${BOLD}EXIT CODES:${NC}
    0  All checks passed
    1  Warnings detected
    2  Critical issues found

${BOLD}EXAMPLES:${NC}
    $0
    $0 --host 10.0.0.1 --ssh-key ~/.ssh/id_rsa
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)      CWP_HOST="$2"; shift 2 ;;
        --ssh-user)  SSH_USER="$2"; shift 2 ;;
        --ssh-port)  SSH_PORT="$2"; shift 2 ;;
        --ssh-key)   SSH_KEY="$2"; shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        *)           echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

[[ -z "$CWP_HOST" ]] && { echo "CWP_HOST required. Use --host or set in $CONFIG_FILE"; exit 1; }

echo -e "${BOLD}CWP Security Scanner v${VERSION}${NC}"
echo "  Target: ${CWP_HOST}"
echo "  Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

scan_updates
scan_ssh
scan_firewall
scan_ssl
scan_permissions
scan_cves
scan_services

print_summary
