#!/bin/bash
# CWP Diagnostic Script
# Comprehensive diagnostic tool for CWP server issues

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CWP Server Diagnostics ===${NC}"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""

# Function to check service
check_service() {
    local service="$1"
    local display_name="${2:-$service}"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}[RUNNING]${NC} $display_name"
    else
        echo -e "${RED}[STOPPED]${NC} $display_name"
        # Show last 3 log lines
        journalctl -u "$service" --no-pager -n 3 2>/dev/null | tail -3
    fi
}

# Step 1: System Resources
echo -e "${BLUE}[1/8] System Resources${NC}"
echo "CPU: $(nproc) cores, Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo "Memory:"
free -h | head -2
echo "Disk:"
df -h | grep -E "^/dev/" | awk '{print "  " $6 ": " $5 " used (" $4 " free)"}'
echo ""

# Step 2: Service Status
echo -e "${BLUE}[2/8] Service Status${NC}"
check_service httpd "Apache"
check_service nginx "Nginx"
check_service mariadb "MariaDB"
check_service postfix "Postfix"
check_service dovecot "Dovecot"
check_service named "BIND DNS"
check_service cwpsrv "CWP Panel"
check_service pure-ftpd "Pure-FTPd"
echo ""

# Step 3: PHP-FPM Status
echo -e "${BLUE}[3/8] PHP-FPM Status${NC}"
for fpm in /opt/alt/php-fpm*/usr/var/run/*.sock; do
    if [ -S "$fpm" ]; then
        echo -e "${GREEN}[OK]${NC} $(basename $fpm)"
    fi
done
echo ""

# Step 4: Port Status
echo -e "${BLUE}[4/8] Listening Ports${NC}"
ss -tlnp | grep LISTEN | awk '{print "  " $4 " - " $6}' | head -15
echo ""

# Step 5: Recent Errors
echo -e "${BLUE}[5/8] Recent Errors${NC}"
echo "Apache errors:"
tail -3 /usr/local/apache/logs/error_log 2>/dev/null | grep -i error || echo "  None"
echo "Nginx errors:"
tail -3 /var/log/nginx/error.log 2>/dev/null | grep -i error || echo "  None"
echo "MariaDB errors:"
tail -3 /var/log/mysql/error.log 2>/dev/null | grep -i error || echo "  None"
echo "Mail errors:"
grep -i error /var/log/maillog 2>/dev/null | tail -3 || echo "  None"
echo ""

# Step 6: Mail Queue
echo -e "${BLUE}[6/8] Mail Queue${NC}"
MAIL_QUEUE=$(mailq 2>/dev/null | tail -1)
echo "  $MAIL_QUEUE"
echo ""

# Step 7: Firewall Status
echo -e "${BLUE}[7/8] Firewall Status${NC}"
if command -v csf &> /dev/null; then
    if csf -s | grep -q "Firewall is running"; then
        echo -e "${GREEN}[RUNNING]${NC} CSF Firewall"
        BLOCKED=$(csf -t 2>/dev/null | grep -c "Blocked" || echo "0")
        echo "  Temporary blocks: $BLOCKED"
    else
        echo -e "${RED}[STOPPED]${NC} CSF Firewall"
    fi
else
    echo -e "${YELLOW}[NOT INSTALLED]${NC} CSF"
fi
echo ""

# Step 8: Disk Usage Alert
echo -e "${BLUE}[8/8] Disk Usage Alerts${NC}"
df -h | grep -E "^/dev/" | while read line; do
    USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    MOUNT=$(echo "$line" | awk '{print $6}')
    if [ "$USAGE" -gt 90 ]; then
        echo -e "${RED}[CRITICAL]${NC} $MOUNT: ${USAGE}% used"
    elif [ "$USAGE" -gt 80 ]; then
        echo -e "${YELLOW}[WARNING]${NC} $MOUNT: ${USAGE}% used"
    fi
done
echo ""

# Summary
echo -e "${BLUE}=== Diagnostic Summary ===${NC}"
echo "Run 'cwp-status' for detailed status"
echo "Run 'cwp-logs <service>' for specific logs"
echo "Run 'cwp-service <service> restart' to restart a service"
