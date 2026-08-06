#!/bin/bash
# CWP Server Context Detection
# Detects CWP installation, OS, web server, PHP, and database versions
# Usage: bash load-server-context.sh [--export]
#   --export  Output as environment variable exports (for sourcing)
#   (default) Output as human-readable summary

set -euo pipefail

MODE="${1:-summary}"

detect_context() {
    local cwp_version="not installed"
    local os_info="unknown"
    local webserver="unknown"
    local php_version="unknown"
    local mysql_version="unknown"
    local redis_version="unknown"
    local varnish_port="unknown"
    local csf_version="not installed"
    local cwp_installed="false"

    # Detect CWP
    if [ -f "/scripts/cwp_version" ]; then
        cwp_version=$(sh /scripts/cwp_version 2>/dev/null || echo "unknown")
        cwp_installed="true"
    fi

    # Detect OS
    if [ -f "/etc/os-release" ]; then
        local os_id os_version
        os_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        os_version=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        os_info="$os_id $os_version"
    fi

    # Detect web server
    if systemctl is-active --quiet httpd 2>/dev/null && systemctl is-active --quiet nginx 2>/dev/null; then
        webserver="nginx+apache"
    elif systemctl is-active --quiet httpd 2>/dev/null; then
        webserver="apache"
    elif systemctl is-active --quiet nginx 2>/dev/null; then
        webserver="nginx"
    fi

    # Detect PHP
    php_version=$(php -v 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")

    # Detect MariaDB/MySQL
    mysql_version=$(mysql --version 2>/dev/null | awk '{print $5}' | tr -d ',' || echo "unknown")

    # Detect Redis
    redis_version=$(redis-server --version 2>/dev/null | awk '{print $3}' | cut -d= -f2 || echo "unknown")

    # Detect Varnish port
    varnish_port=$(ss -tlnp 2>/dev/null | grep varnish | grep -oP ':\K\d+' | head -1 || echo "not running")

    # Detect CSF
    if command -v csf &>/dev/null; then
        csf_version=$(csf -v 2>/dev/null | head -1 || echo "unknown")
    fi

    if [ "$MODE" = "--export" ]; then
        echo "export CWP_INSTALLED=\"$cwp_installed\""
        echo "export CWP_VERSION=\"$cwp_version\""
        echo "export CWP_OS=\"$os_info\""
        echo "export CWP_WEBSERVER=\"$webserver\""
        echo "export CWP_PHP_VERSION=\"$php_version\""
        echo "export CWP_MYSQL_VERSION=\"$mysql_version\""
        echo "export CWP_REDIS_VERSION=\"$redis_version\""
        echo "export CWP_VARNISH_PORT=\"$varnish_port\""
        echo "export CWP_CSF_VERSION=\"$csf_version\""
    else
        echo "=== CWP Server Context ==="
        echo "  CWP Version:    $cwp_version"
        echo "  OS:             $os_info"
        echo "  Web Server:     $webserver"
        echo "  PHP:            $php_version"
        echo "  MariaDB:        $mysql_version"
        echo "  Redis:          $redis_version"
        echo "  Varnish Port:   $varnish_port"
        echo "  CSF:            $csf_version"
    fi
}

detect_context
