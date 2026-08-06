#!/usr/bin/env bash
# =============================================================================
# CWP Health Check - Monitor CWP server health
# =============================================================================
# Usage: cwp-health-check.sh [options]
# Can be run via cron for automated monitoring.
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
NOTIFY_EMAIL="${NOTIFY_EMAIL:-}"
WEBHOOK_URL="${WEBHOOK_URL:-}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

HEALTH_STATUS="OK"
ISSUES=()

log_ok()    { echo -e "  ${GREEN}OK${NC}    $*"; }
log_warn()  { echo -e "  ${YELLOW}WARN${NC}  $*"; ISSUES+=("WARN: $*"); [[ "$HEALTH_STATUS" != "CRITICAL" ]] && HEALTH_STATUS="WARNING"; }
log_crit()  { echo -e "  ${RED}CRIT${NC}  $*"; ISSUES+=("CRIT: $*"); HEALTH_STATUS="CRITICAL"; }
log_header(){ echo -e "\n${BOLD}${BLUE}--- $* ---${NC}"; }

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
# Check: Services
# ---------------------------------------------------------------------------
check_services() {
    log_header "Service Health"

    local services=(
        "cwpsrv:CWP Web Server"
        "httpd:Apache"
        "nginx:Nginx"
        "mysql:MySQL/MariaDB"
        "postfix:Postfix SMTP"
        "dovecot:Dovecot IMAP"
        "named:DNS Server"
        "pure-ftpd:FTP Server"
        "php-fpm:PHP-FPM"
    )

    for entry in "${services[@]}"; do
        local svc="${entry%%:*}"
        local label="${entry#*:}"
        local status
        status=$(remote_exec_sudo "systemctl is-active $svc 2>/dev/null" || echo "unknown")

        if [[ "$status" == "active" ]]; then
            log_ok "$label ($svc)"
        elif [[ "$status" == "unknown" ]]; then
            log_warn "$label ($svc) - status unknown"
        else
            log_crit "$label ($svc) is $status"
        fi
    done
}

# ---------------------------------------------------------------------------
# Check: Disk usage
# ---------------------------------------------------------------------------
check_disk() {
    log_header "Disk Usage"

    local disk_output
    disk_output=$(remote_exec_sudo "df -h / /home /var /tmp 2>/dev/null | awk 'NR>1 {gsub(/%/,\"\",\$5); print \$6, \$5, \$4}'" || echo "")

    if [[ -z "$disk_output" ]]; then
        log_warn "Could not retrieve disk information"
        return
    fi

    while IFS=' ' read -r mount usage avail; do
        usage="${usage:-0}"
        if [[ "$usage" -ge 95 ]]; then
            log_crit "$mount is ${usage}% full (${avail} free)"
        elif [[ "$usage" -ge 85 ]]; then
            log_warn "$mount is ${usage}% full (${avail} free)"
        else
            log_ok "$mount is ${usage}% full (${avail} free)"
        fi
    done <<< "$disk_output"

    # Check inode usage
    local inode_output
    inode_output=$(remote_exec_sudo "df -i / /home 2>/dev/null | awk 'NR>1 {gsub(/%/,\"\",\$5); print \$6, \$5}'" || echo "")
    while IFS=' ' read -r mount iusage; do
        iusage="${iusage:-0}"
        if [[ "$iusage" -ge 90 ]]; then
            log_crit "$mount inodes ${iusage}% used"
        elif [[ "$iusage" -ge 75 ]]; then
            log_warn "$mount inodes ${iusage}% used"
        fi
    done <<< "$inode_output"
}

# ---------------------------------------------------------------------------
# Check: Memory
# ---------------------------------------------------------------------------
check_memory() {
    log_header "Memory Usage"

    local mem_info
    mem_info=$(remote_exec "free -m | awk '/Mem:/{printf \"%d %d %d\", \$2, \$3, \$7}'" || echo "")
    if [[ -n "$mem_info" ]]; then
        local total used available
        read -r total used available <<< "$mem_info"
        local pct=$(( used * 100 / total ))

        if [[ "$pct" -ge 95 ]]; then
            log_crit "Memory: ${used}M/${total}M used (${pct}%) - ${available}M available"
        elif [[ "$pct" -ge 85 ]]; then
            log_warn "Memory: ${used}M/${total}M used (${pct}%) - ${available}M available"
        else
            log_ok "Memory: ${used}M/${total}M used (${pct}%) - ${available}M available"
        fi
    fi

    # Check swap
    local swap_info
    swap_info=$(remote_exec "free -m | awk '/Swap:/{printf \"%d %d\", \$2, \$3}'" || echo "")
    if [[ -n "$swap_info" ]]; then
        local swap_total swap_used
        read -r swap_total swap_used <<< "$swap_info"
        if [[ "$swap_total" -gt 0 ]]; then
            local swap_pct=$(( swap_used * 100 / swap_total ))
            if [[ "$swap_pct" -ge 50 ]]; then
                log_warn "Swap: ${swap_used}M/${swap_total}M used (${swap_pct}%)"
            else
                log_ok "Swap: ${swap_used}M/${swap_total}M used (${swap_pct}%)"
            fi
        fi
    fi
}

# ---------------------------------------------------------------------------
# Check: CPU/Load
# ---------------------------------------------------------------------------
check_load() {
    log_header "CPU / Load Average"

    local load_1 load_5 load_15
    read -r load_1 load_5 load_15 _ < <(remote_exec "cat /proc/loadavg" || echo "0 0 0")
    local cpus
    cpus=$(remote_exec "nproc" || echo "1")

    local load_1_int="${load_1%%.*}"
    load_1_int="${load_1_int:-0}"

    if [[ "$load_1_int" -ge "$((cpus * 2))" ]]; then
        log_crit "Load: ${load_1} ${load_5} ${load_15} (${cpus} CPUs)"
    elif [[ "$load_1_int" -ge "$cpus" ]]; then
        log_warn "Load: ${load_1} ${load_5} ${load_15} (${cpus} CPUs)"
    else
        log_ok "Load: ${load_1} ${load_5} ${load_15} (${cpus} CPUs)"
    fi
}

# ---------------------------------------------------------------------------
# Check: MySQL
# ---------------------------------------------------------------------------
check_mysql() {
    log_header "MySQL / MariaDB"

    local mysql_status
    mysql_status=$(remote_exec_sudo "mysqladmin status 2>/dev/null" || echo "")

    if [[ -z "$mysql_status" ]]; then
        log_crit "MySQL not responding"
        return
    fi

    log_ok "MySQL is running"

    # Check connections
    local connections
    connections=$(remote_exec_sudo "mysql -e 'SHOW STATUS LIKE \"Threads_connected\";' 2>/dev/null | awk '/Threads_connected/{print \$2}'" || echo "0")
    local max_connections
    max_connections=$(remote_exec_sudo "mysql -e 'SHOW VARIABLES LIKE \"max_connections\";' 2>/dev/null | awk '/max_connections/{print \$2}'" || echo "0")

    if [[ -n "$connections" && -n "$max_connections" && "$max_connections" -gt 0 ]]; then
        local conn_pct=$(( connections * 100 / max_connections ))
        if [[ "$conn_pct" -ge 80 ]]; then
            log_warn "MySQL connections: ${connections}/${max_connections} (${conn_pct}%)"
        else
            log_ok "MySQL connections: ${connections}/${max_connections} (${conn_pct}%)"
        fi
    fi

    # Check slow queries
    local slow_queries
    slow_queries=$(remote_exec_sudo "mysql -e 'SHOW STATUS LIKE \"Slow_queries\";' 2>/dev/null | awk '/Slow_queries/{print \$2}'" || echo "0")
    log_info "MySQL slow queries: $slow_queries"
}

# ---------------------------------------------------------------------------
# Check: Recent errors
# ---------------------------------------------------------------------------
check_errors() {
    log_header "Recent Errors (last hour)"

    local ssh_errors
    ssh_errors=$(remote_exec_sudo "journalctl --since '1 hour ago' -p err --no-pager 2>/dev/null | wc -l" || echo "0")
    if [[ "$ssh_errors" -gt 50 ]]; then
        log_crit "$ssh_errors system errors in the last hour"
    elif [[ "$ssh_errors" -gt 10 ]]; then
        log_warn "$ssh_errors system errors in the last hour"
    else
        log_ok "$ssh_errors system errors in the last hour"
    fi

    # Check Apache errors
    local apache_errors
    apache_errors=$(remote_exec_sudo "tail -100 /usr/local/apache/logs/error_log 2>/dev/null | grep -c '\[error\]\|\[crit\]' || echo 0")
    if [[ "$apache_errors" -gt 20 ]]; then
        log_warn "Apache: $apache_errors errors in recent log"
    else
        log_ok "Apache: $apache_errors errors in recent log"
    fi

    # Check failed logins
    local failed_logins
    failed_logins=$(remote_exec_sudo "journalctl --since '1 hour ago' -u sshd 2>/dev/null | grep -c 'Failed password' || echo 0")
    if [[ "$failed_logins" -gt 20 ]]; then
        log_crit "$failed_logins failed SSH login attempts in the last hour"
    elif [[ "$failed_logins" -gt 5 ]]; then
        log_warn "$failed_logins failed SSH login attempts in the last hour"
    else
        log_ok "$failed_logins failed SSH login attempts"
    fi
}

# ---------------------------------------------------------------------------
# Check: Web server
# ---------------------------------------------------------------------------
check_webserver() {
    log_header "Web Server"

    # Check if sites respond
    local http_code
    http_code=$(remote_exec "curl -sS -o /dev/null -w '%{http_code}' --max-time 5 http://localhost/ 2>/dev/null" || echo "000")

    if [[ "$http_code" =~ ^[23] ]]; then
        log_ok "HTTP localhost responding (code: $http_code)"
    elif [[ "$http_code" == "000" ]]; then
        log_crit "HTTP localhost not responding"
    else
        log_warn "HTTP localhost returned code $http_code"
    fi
}

# ---------------------------------------------------------------------------
# Check: Mail queue
# ---------------------------------------------------------------------------
check_mail() {
    log_header "Mail Queue"

    local queue_size
    queue_size=$(remote_exec_sudo "postqueue -p 2>/dev/null | tail -1" || echo "")
    if [[ -n "$queue_size" ]]; then
        if echo "$queue_size" | grep -qi "empty\|no messages"; then
            log_ok "Mail queue is empty"
        else
            local msg_count
            msg_count=$(echo "$queue_size" | grep -oP '\d+' | head -1 || echo "0")
            if [[ "$msg_count" -gt 100 ]]; then
                log_crit "Mail queue has $msg_count messages"
            elif [[ "$msg_count" -gt 20 ]]; then
                log_warn "Mail queue has $msg_count messages"
            else
                log_ok "Mail queue: $msg_count messages"
            fi
        fi
    else
        log_warn "Could not check mail queue"
    fi
}

# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------
send_notification() {
    local subject="$1" body="$2"

    # Email notification
    if [[ -n "$NOTIFY_EMAIL" ]]; then
        echo "$body" | mail -s "$subject" "$NOTIFY_EMAIL" 2>/dev/null || true
    fi

    # Webhook notification (Slack/Discord)
    if [[ -n "$WEBHOOK_URL" ]]; then
        local json_body
        json_body=$(printf '{"text":"%s\n%s"}' "$subject" "$body")
        curl -sS -X POST -H "Content-Type: application/json" -d "$json_body" "$WEBHOOK_URL" >/dev/null 2>&1 || true
    fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print_summary() {
    echo ""
    echo -e "${BOLD}=== Health Check Summary ===${NC}"
    echo -e "  Status: $(
        case "$HEALTH_STATUS" in
            OK)       echo -e "${GREEN}${BOLD}HEALTHY${NC}" ;;
            WARNING)  echo -e "${YELLOW}${BOLD}WARNING${NC}" ;;
            CRITICAL) echo -e "${RED}${BOLD}CRITICAL${NC}" ;;
        esac
    )"
    echo -e "  Issues: ${#ISSUES[@]}"
    echo -e "  Date:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo ""
        echo "Issues found:"
        for issue in "${ISSUES[@]}"; do
            echo "  - $issue"
        done

        # Send notification for non-OK status
        if [[ "$HEALTH_STATUS" != "OK" ]]; then
            local notify_body
            notify_body=$(printf '%s\n' "${ISSUES[@]}")
            send_notification "[CWP ${HEALTH_STATUS}] ${CWP_HOST}" "$notify_body"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}CWP Health Check${NC} v${VERSION}

${BOLD}USAGE:${NC}
    $0 [options]

${BOLD}OPTIONS:${NC}
    --host <host>         CWP server hostname or IP
    --ssh-user <user>     SSH username (default: root)
    --ssh-port <port>     SSH port (default: 22)
    --ssh-key <path>      SSH private key file
    --notify-email <addr> Email for notifications
    --webhook <url>       Webhook URL for notifications
    -h, --help            Show this help

${BOLD}CHECKS PERFORMED:${NC}
    - Service status (Apache, MySQL, Postfix, etc.)
    - Disk and inode usage
    - Memory and swap usage
    - CPU load average
    - MySQL health and connections
    - Recent system errors
    - Web server responsiveness
    - Mail queue size

${BOLD}EXAMPLES:${NC}
    $0
    $0 --host 10.0.0.1
    $0 --notify-email admin@example.com --webhook https://hooks.slack.com/...

${BOLD}CRON USAGE:${NC}
    */5 * * * * /path/to/cwp-health-check.sh --host myserver 2>&1 | logger -t cwp-health
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)          CWP_HOST="$2"; shift 2 ;;
        --ssh-user)      SSH_USER="$2"; shift 2 ;;
        --ssh-port)      SSH_PORT="$2"; shift 2 ;;
        --ssh-key)       SSH_KEY="$2"; shift 2 ;;
        --notify-email)  NOTIFY_EMAIL="$2"; shift 2 ;;
        --webhook)       WEBHOOK_URL="$2"; shift 2 ;;
        -h|--help)       usage; exit 0 ;;
        *)               echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

[[ -z "$CWP_HOST" ]] && { echo "CWP_HOST required. Use --host or set in $CONFIG_FILE"; exit 1; }

echo -e "${BOLD}CWP Health Check v${VERSION}${NC}"
echo "  Target: ${CWP_HOST}"
echo "  Time:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"

check_services
check_disk
check_memory
check_load
check_mysql
check_errors
check_webserver
check_mail

print_summary

# Exit code based on status
case "$HEALTH_STATUS" in
    OK)       exit 0 ;;
    WARNING)  exit 1 ;;
    CRITICAL) exit 2 ;;
esac
