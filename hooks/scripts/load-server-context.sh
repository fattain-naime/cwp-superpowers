#!/bin/bash
# Load CWP server context on session start
# Detects CWP installation, OS, web server, and PHP version

set -euo pipefail

# Detect CWP installation
if [ -f "/scripts/cwp_version" ]; then
    CWP_VERSION=$(sh /scripts/cwp_version 2>/dev/null || echo "unknown")
    echo "export CWP_VERSION=\"$CWP_VERSION\"" >> "$CLAUDE_ENV_FILE"
    echo "export CWP_INSTALLED=true" >> "$CLAUDE_ENV_FILE"

    # Detect OS
    if [ -f "/etc/os-release" ]; then
        OS_ID=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        echo "export CWP_OS=\"$OS_ID $OS_VERSION\"" >> "$CLAUDE_ENV_FILE"
    fi

    # Detect web server
    if systemctl is-active --quiet httpd 2>/dev/null; then
        echo "export CWP_WEBSERVER=apache" >> "$CLAUDE_ENV_FILE"
    elif systemctl is-active --quiet nginx 2>/dev/null; then
        echo "export CWP_WEBSERVER=nginx" >> "$CLAUDE_ENV_FILE"
    fi

    # Detect PHP version
    PHP_VERSION=$(php -v 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
    echo "export CWP_PHP_VERSION=\"$PHP_VERSION\"" >> "$CLAUDE_ENV_FILE"

    # Detect MariaDB version
    MYSQL_VERSION=$(mysql --version 2>/dev/null | awk '{print $5}' | tr -d ',' || echo "unknown")
    echo "export CWP_MYSQL_VERSION=\"$MYSQL_VERSION\"" >> "$CLAUDE_ENV_FILE"

    echo "CWP context loaded: v$CWP_VERSION on $OS_ID $OS_VERSION"
else
    echo "export CWP_INSTALLED=false" >> "$CLAUDE_ENV_FILE"
    echo "CWP not detected on this server"
fi
