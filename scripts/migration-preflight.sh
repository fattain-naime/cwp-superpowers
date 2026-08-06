#!/bin/bash
# CWP Migration Pre-flight Check Script
# Validates source and destination servers before migration
set -euo pipefail

# Configuration
SOURCE_IP="$1"
SOURCE_USER="${2:-root}"
SSH_KEY="$3"

# Input validation
if [[ -n "$SOURCE_IP" && ! "$SOURCE_IP" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Invalid source IP: '$SOURCE_IP'"
    exit 1
fi
if [[ -n "$SOURCE_USER" && ! "$SOURCE_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid source user: '$SOURCE_USER'"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$SOURCE_IP" ]; then
    echo "Usage: $0 <source_ip> [source_user] [ssh_key]"
    echo "Example: $0 192.168.1.100 root ~/.ssh/id_rsa"
    exit 1
fi

echo -e "${BLUE}=== CWP Migration Pre-flight Check ===${NC}"
echo "Source: $SOURCE_USER@$SOURCE_IP"
echo "Destination: $(hostname) ($(hostname -I | awk '{print $1}'))"
echo ""

# SSH Command
SSH_CMD="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10"
if [ -n "$SSH_KEY" ]; then
    SSH_CMD="$SSH_CMD -i $SSH_KEY"
fi
SSH_CMD="$SSH_CMD $SOURCE_USER@$SOURCE_IP"

# Check SSH connectivity
echo -e "${BLUE}[1/8] Checking SSH connectivity...${NC}"
if $SSH_CMD "echo 'SSH OK'" > /dev/null 2>&1; then
    echo -e "${GREEN}[PASS]${NC} SSH connection successful"
else
    echo -e "${RED}[FAIL]${NC} Cannot connect to source server"
    echo "Check SSH credentials and firewall rules"
    exit 1
fi

# Check source server info
echo -e "${BLUE}[2/8] Checking source server...${NC}"
SOURCE_OS=$($SSH_CMD "cat /etc/redhat-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'\"' -f2")
SOURCE_KERNEL=$($SSH_CMD "uname -r")
echo "OS: $SOURCE_OS"
echo "Kernel: $SOURCE_KERNEL"

# Check source disk space
echo -e "${BLUE}[3/8] Checking source disk space...${NC}"
SOURCE_DISK=$($SSH_CMD "df -h / | tail -1 | awk '{print \$5}' | sed 's/%//'")
if [ "$SOURCE_DISK" -gt 90 ]; then
    echo -e "${RED}[WARNING]${NC} Source disk usage high: ${SOURCE_DISK}%"
else
    echo -e "${GREEN}[OK]${NC} Source disk usage: ${SOURCE_DISK}%"
fi

# Check destination disk space
echo -e "${BLUE}[4/8] Checking destination disk space...${NC}"
DEST_DISK=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
DEST_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
if [ "$DEST_DISK" -gt 90 ]; then
    echo -e "${RED}[WARNING]${NC} Destination disk usage high: ${DEST_DISK}%"
else
    echo -e "${GREEN}[OK]${NC} Destination disk usage: ${DEST_DISK}% (Available: $DEST_AVAIL)"
fi

# Check source accounts
echo -e "${BLUE}[5/8] Checking source accounts...${NC}"
SOURCE_ACCOUNTS=$($SSH_CMD "ls /home/ | wc -l")
echo "Accounts found: $SOURCE_ACCOUNTS"

# Check source databases
echo -e "${BLUE}[6/8] Checking source databases...${NC}"
SOURCE_DBS=$($SSH_CMD "mysql -e 'SHOW DATABASES;' 2>/dev/null | wc -l")
echo "Databases found: $SOURCE_DBS"

# Check source email
echo -e "${BLUE}[7/8] Checking source email...${NC}"
if $SSH_CMD "test -d /var/vmail" > /dev/null 2>&1; then
    SOURCE_EMAIL=$($SSH_CMD "ls /var/vmail/ | wc -l")
    echo "Email domains: $SOURCE_EMAIL"
else
    echo "No email data found"
fi

# Check network connectivity
echo -e "${BLUE}[8/8] Checking network connectivity...${NC}"
if ping -c 1 -W 5 "$SOURCE_IP" > /dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} Network connectivity good"
else
    echo -e "${YELLOW}[WARNING]${NC} Ping failed (may be blocked by firewall)"
fi

# Summary
echo ""
echo -e "${BLUE}=== Pre-flight Summary ===${NC}"
echo "Source: $SOURCE_USER@$SOURCE_IP"
echo "Source OS: $SOURCE_OS"
echo "Source Accounts: $SOURCE_ACCOUNTS"
echo "Source Databases: $SOURCE_DBS"
echo "Destination Available: $DEST_AVAIL"
echo ""

# Recommendations
echo -e "${BLUE}=== Recommendations ===${NC}"
if [ "$SOURCE_DISK" -gt 90 ]; then
    echo -e "${YELLOW}[WARN]${NC} Clean up source server before migration"
fi

if [ "$DEST_DISK" -gt 80 ]; then
    echo -e "${YELLOW}[WARN]${NC} Ensure enough space on destination"
fi

if [ "$SOURCE_ACCOUNTS" -gt 50 ]; then
    echo -e "${YELLOW}[INFO]${NC} Consider batch migration for $SOURCE_ACCOUNTS accounts"
fi

echo ""
echo "Pre-flight check completed at $(date)"
echo ""
echo "Next steps:"
echo "1. Create backups on source server"
echo "2. Transfer backups to destination"
echo "3. Restore accounts in CWP"
echo "4. Verify each account"
echo "5. Update DNS records"
