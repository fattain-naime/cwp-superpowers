#!/bin/bash
# Check server health after CWP operations
# Warns if critical services are down after commands

set -euo pipefail

input=$(cat)
tool_input=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only check after CWP-related commands
if ! echo "$tool_input" | grep -qE "(cwp|httpd|nginx|mariadb|postfix|dovecot|named|csf)"; then
    exit 0
fi

# Check critical services
ISSUES=()

if ! systemctl is-active --quiet httpd 2>/dev/null && ! systemctl is-active --quiet nginx 2>/dev/null; then
    ISSUES+=("Web server (httpd/nginx) is not running")
fi

if ! systemctl is-active --quiet mariadb 2>/dev/null; then
    ISSUES+=("MariaDB is not running")
fi

if [ ${#ISSUES[@]} -gt 0 ]; then
    MSG="⚠️ Server health issues detected after command execution:"
    for issue in "${ISSUES[@]}"; do
        MSG="$MSG\n  - $issue"
    done
    if command -v jq &>/dev/null; then
        jq -n --arg msg "$MSG" '{"systemMessage": $msg}' >&2
    else
        # Fallback: escape for JSON safety
        ESCAPED_MSG=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')
        echo "{\"systemMessage\": \"$ESCAPED_MSG\"}" >&2
    fi
    exit 2
fi

exit 0
