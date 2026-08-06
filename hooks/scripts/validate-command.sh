#!/bin/bash
# Validate CWP commands before execution
# Blocks dangerous commands that could damage the server

set -euo pipefail

input=$(cat)
tool_input=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$tool_input" ]; then
    exit 0
fi

# Block dangerous commands
DANGEROUS_PATTERNS=(
    "rm -rf /"
    "rm -rf /\*"
    "mkfs"
    "dd if="
    "> /dev/sd"
    "chmod 777 /"
    "chmod -R 777 /"
    "chown -R root /"
    ":(){:|:&};:"
    "mv / /"
    "wget.*|.*sh"
    "curl.*|.*sh"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$tool_input" | grep -qE "$pattern"; then
        if command -v jq &>/dev/null; then
            jq -n --arg p "$pattern" '{"decision": "deny", "reason": ("Dangerous command detected: " + $p + ". This command could damage the server.")}' >&2
        else
            echo '{"decision": "deny", "reason": "Dangerous command detected. This command could damage the server."}' >&2
        fi
        exit 2
    fi
done

# Warn about sensitive operations
SENSITIVE_PATTERNS=(
    "rm -rf"
    "systemctl stop"
    "systemctl disable"
    "iptables -F"
    "csf -x"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if echo "$tool_input" | grep -qF "$pattern"; then
        if command -v jq &>/dev/null; then
            jq -n --arg p "$pattern" '{"systemMessage": ("⚠️ Sensitive operation detected: " + $p + ". Proceed with caution.")}' >&2
        else
            echo '{"systemMessage": "⚠️ Sensitive operation detected. Proceed with caution."}' >&2
        fi
        exit 0
    fi
done

exit 0
