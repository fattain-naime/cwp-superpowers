#!/bin/bash
# Validate configuration file syntax after edits
# Checks Apache, Nginx, PHP, and BIND configs for syntax errors

set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
    exit 0
fi

# Check Apache configs
if echo "$file_path" | grep -qE "(httpd|apache|vhost).*\.(conf|tpl)$"; then
    if httpd -t 2>&1 | grep -q "Syntax OK"; then
        exit 0
    else
        jq -n --arg fp "$file_path" '{"systemMessage": "⚠️ Apache config syntax error detected after editing \($fp). Run: httpd -t"}' >&2
        exit 2
    fi
fi

# Check Nginx configs
if echo "$file_path" | grep -qE "(nginx|vhost).*\.(conf|tpl)$"; then
    if nginx -t 2>&1 | grep -q "syntax is ok"; then
        exit 0
    else
        jq -n --arg fp "$file_path" '{"systemMessage": "⚠️ Nginx config syntax error detected after editing \($fp). Run: nginx -t"}' >&2
        exit 2
    fi
fi

# Check BIND zone files
if echo "$file_path" | grep -qE "\.db$|named|bind"; then
    if named-checkconf 2>&1 | grep -q "no errors"; then
        exit 0
    else
        jq -n --arg fp "$file_path" '{"systemMessage": "⚠️ BIND config syntax error detected after editing \($fp). Run: named-checkconf"}' >&2
        exit 2
    fi
fi

# Check PHP configs
if echo "$file_path" | grep -qE "php\.ini|php-fpm.*\.conf$"; then
    if php -l "$file_path" 2>&1 | grep -q "No syntax errors"; then
        exit 0
    else
        jq -n --arg fp "$file_path" '{"systemMessage": "⚠️ PHP config syntax error detected after editing \($fp). Run: php -l \($fp)"}' >&2
        exit 2
    fi
fi

exit 0
