#!/usr/bin/env bash
# =============================================================================
# CWP API Client - Shell wrapper for CWP REST API
# =============================================================================
# Usage: cwp-api-client.sh <command> [options]
# Requires: CWP_HOST and CWP_API_KEY environment variables or ~/.cwp-cli.conf
# =============================================================================
set -euo pipefail

readonly VERSION="1.0.0"
readonly CONFIG_FILE="${CWP_CLI_CONF:-$HOME/.cwp-cli.conf}"
readonly API_TIMEOUT=30

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

CWP_HOST="${CWP_HOST:-}"
CWP_API_KEY="${CWP_API_KEY:-}"
CWP_API_PORT="${CWP_API_PORT:-2304}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()       { log_error "$@"; exit 1; }

# ---------------------------------------------------------------------------
# API request helper
# ---------------------------------------------------------------------------
api_request() {
    local method="$1" endpoint="$2"
    shift 2
    local data=""

    if [[ "$method" == "POST" && $# -gt 0 ]]; then
        data="$1"
        shift
    fi

    [[ -z "$CWP_HOST" ]] && die "CWP_HOST not set. Run setup or export CWP_HOST."
    [[ -z "$CWP_API_KEY" ]] && die "CWP_API_KEY not set. Run setup or export CWP_API_KEY."

    local url="https://${CWP_HOST}:${CWP_API_PORT}/${endpoint}"
    local curl_args=(-sS --max-time "$API_TIMEOUT"
        -H "Authorization: Bearer ${CWP_API_KEY}"
        -H "Content-Type: application/json"
    )

    if [[ "$method" == "POST" ]]; then
        curl_args+=(-X POST -d "$data")
    fi

    local response
    response=$(curl "${curl_args[@]}" "$url" 2>&1) || die "API request failed: $response"

    # Try to pretty-print JSON if jq available
    if command -v jq &>/dev/null; then
        echo "$response" | jq . 2>/dev/null || echo "$response"
    else
        echo "$response"
    fi
}

# ---------------------------------------------------------------------------
# JSON helper (uses jq when available for safe construction)
# ---------------------------------------------------------------------------
json_create() {
    if command -v jq &>/dev/null; then
        jq -n "$@"
    else
        die "jq is required for JSON construction. Install with: yum install jq"
    fi
}

# ---------------------------------------------------------------------------
# Account commands
# ---------------------------------------------------------------------------
cmd_account() {
    local subcmd="${1:-list}"
    shift 2>/dev/null || true

    case "$subcmd" in
        list)
            api_request GET "v1/account/list"
            ;;
        info)
            local username="${1:-}"
            [[ -z "$username" ]] && die "Usage: $0 account info <username>"
            api_request GET "v1/account/info/${username}"
            ;;
        create)
            local username="${1:-}" plan="${2:-default}" domain="${3:-}"
            [[ -z "$username" ]] && die "Usage: $0 account create <username> [plan] [domain]"
            local data
            data=$(json_create --arg u "$username" --arg p "$plan" --arg d "$domain" \
                '{"username": $u, "plan": $p, "domain": $d}')
            api_request POST "v1/account/create" "$data"
            ;;
        delete)
            local username="${1:-}"
            [[ -z "$username" ]] && die "Usage: $0 account delete <username>"
            local data
            data=$(json_create --arg u "$username" '{"username": $u}')
            api_request POST "v1/account/delete" "$data"
            ;;
        suspend)
            local username="${1:-}" reason="${2:-}"
            [[ -z "$username" ]] && die "Usage: $0 account suspend <username> [reason]"
            local data
            data=$(json_create --arg u "$username" --arg r "$reason" \
                '{"username": $u, "reason": $r}')
            api_request POST "v1/account/suspend" "$data"
            ;;
        unsuspend)
            local username="${1:-}"
            [[ -z "$username" ]] && die "Usage: $0 account unsuspend <username>"
            local data
            data=$(json_create --arg u "$username" '{"username": $u}')
            api_request POST "v1/account/unsuspend" "$data"
            ;;
        change-plan)
            local username="${1:-}" plan="${2:-}"
            [[ -z "$username" || -z "$plan" ]] && die "Usage: $0 account change-plan <username> <plan>"
            local data
            data=$(json_create --arg u "$username" --arg p "$plan" \
                '{"username": $u, "plan": $p}')
            api_request POST "v1/account/change-plan" "$data"
            ;;
        *)
            die "Unknown account subcommand: $subcmd"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Database commands
# ---------------------------------------------------------------------------
cmd_database() {
    local subcmd="${1:-list}"
    shift 2>/dev/null || true

    case "$subcmd" in
        list)
            api_request GET "v1/database/list"
            ;;
        create)
            local name="${1:-}" charset="${2:-utf8}"
            [[ -z "$name" ]] && die "Usage: $0 database create <name> [charset]"
            local data
            data=$(json_create --arg n "$name" --arg c "$charset" '{"name": $n, "charset": $c}')
            api_request POST "v1/database/create" "$data"
            ;;
        delete)
            local name="${1:-}"
            [[ -z "$name" ]] && die "Usage: $0 database delete <name>"
            local data
            data=$(json_create --arg n "$name" '{"name": $n}')
            api_request POST "v1/database/delete" "$data"
            ;;
        user-add)
            local dbuser="${1:-}" dbname="${2:-}" dbpass="${3:-}"
            [[ -z "$dbuser" || -z "$dbname" ]] && die "Usage: $0 database user-add <user> <database> [password]"
            [[ -z "$dbpass" ]] && { read -rsp "Password: " dbpass; echo ""; }
            local data
            data=$(json_create --arg u "$dbuser" --arg d "$dbname" --arg p "$dbpass" \
                '{"user": $u, "database": $d, "password": $p}')
            api_request POST "v1/database/user-add" "$data"
            ;;
        user-delete)
            local dbuser="${1:-}"
            [[ -z "$dbuser" ]] && die "Usage: $0 database user-delete <user>"
            local data
            data=$(json_create --arg u "$dbuser" '{"user": $u}')
            api_request POST "v1/database/user-delete" "$data"
            ;;
        *)
            die "Unknown database subcommand: $subcmd"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Email commands
# ---------------------------------------------------------------------------
cmd_email() {
    local subcmd="${1:-list}"
    shift 2>/dev/null || true

    case "$subcmd" in
        list)
            local domain="${1:-}"
            if [[ -n "$domain" ]]; then
                api_request GET "v1/email/list/${domain}"
            else
                api_request GET "v1/email/domains"
            fi
            ;;
        create)
            local email="${1:-}" password="${2:-}" quota="${3:-0}"
            [[ -z "$email" ]] && die "Usage: $0 email create <email> [password] [quota]"
            [[ -z "$password" ]] && { read -rsp "Password: " password; echo ""; }
            local data
            data=$(json_create --arg e "$email" --arg p "$password" --arg q "$quota" \
                '{"email": $e, "password": $p, "quota": $q}')
            api_request POST "v1/email/create" "$data"
            ;;
        delete)
            local email="${1:-}"
            [[ -z "$email" ]] && die "Usage: $0 email delete <email>"
            local data
            data=$(json_create --arg e "$email" '{"email": $e}')
            api_request POST "v1/email/delete" "$data"
            ;;
        forwarder-add)
            local from="${1:-}" to="${2:-}"
            [[ -z "$from" || -z "$to" ]] && die "Usage: $0 email forwarder-add <from> <to>"
            local data
            data=$(json_create --arg f "$from" --arg t "$to" '{"from": $f, "to": $t}')
            api_request POST "v1/email/forwarder-add" "$data"
            ;;
        forwarder-delete)
            local from="${1:-}"
            [[ -z "$from" ]] && die "Usage: $0 email forwarder-delete <from>"
            local data
            data=$(json_create --arg f "$from" '{"from": $f}')
            api_request POST "v1/email/forwarder-delete" "$data"
            ;;
        *)
            die "Unknown email subcommand: $subcmd"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# DNS commands
# ---------------------------------------------------------------------------
cmd_dns() {
    local subcmd="${1:-list}"
    shift 2>/dev/null || true

    case "$subcmd" in
        list)
            api_request GET "v1/dns/list"
            ;;
        zone)
            local domain="${1:-}"
            [[ -z "$domain" ]] && die "Usage: $0 dns zone <domain>"
            api_request GET "v1/dns/zone/${domain}"
            ;;
        add-record)
            local domain="${1:-}" type="${2:-}" name="${3:-}" value="${4:-}"
            [[ -z "$domain" || -z "$type" || -z "$name" || -z "$value" ]] && \
                die "Usage: $0 dns add-record <domain> <type> <name> <value>"
            local data
            data=$(json_create --arg d "$domain" --arg t "$type" --arg n "$name" --arg v "$value" \
                '{"domain": $d, "type": $t, "name": $n, "value": $v}')
            api_request POST "v1/dns/record/add" "$data"
            ;;
        delete-record)
            local domain="${1:-}" record_id="${2:-}"
            [[ -z "$domain" || -z "$record_id" ]] && die "Usage: $0 dns delete-record <domain> <record-id>"
            local data
            data=$(json_create --arg d "$domain" --arg r "$record_id" \
                '{"domain": $d, "record_id": $r}')
            api_request POST "v1/dns/record/delete" "$data"
            ;;
        *)
            die "Unknown dns subcommand: $subcmd"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# SSL commands
# ---------------------------------------------------------------------------
cmd_ssl() {
    local subcmd="${1:-list}"
    shift 2>/dev/null || true

    case "$subcmd" in
        list)
            api_request GET "v1/ssl/list"
            ;;
        generate)
            local domain="${1:-}"
            [[ -z "$domain" ]] && die "Usage: $0 ssl generate <domain>"
            local data
            data=$(json_create --arg d "$domain" '{"domain": $d}')
            api_request POST "v1/ssl/generate" "$data"
            ;;
        install)
            local domain="${1:-}" cert="${2:-}" key="${3:-}" ca="${4:-}"
            [[ -z "$domain" || -z "$cert" || -z "$key" ]] && \
                die "Usage: $0 ssl install <domain> <cert-file> <key-file> [ca-file]"
            local cert_content key_content ca_content
            cert_content=$(cat "$cert")
            key_content=$(cat "$key")
            ca_content=""
            [[ -n "$ca" ]] && ca_content=$(cat "$ca")
            local data
            data=$(json_create --arg d "$domain" --arg c "$cert_content" --arg k "$key_content" --arg a "$ca_content" \
                '{"domain": $d, "cert": $c, "key": $k, "ca": $a}')
            api_request POST "v1/ssl/install" "$data"
            ;;
        letsencrypt)
            local domain="${1:-}"
            [[ -z "$domain" ]] && die "Usage: $0 ssl letsencrypt <domain>"
            local data
            data=$(json_create --arg d "$domain" '{"domain": $d}')
            api_request POST "v1/ssl/letsencrypt" "$data"
            ;;
        *)
            die "Unknown ssl subcommand: $subcmd"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}CWP API Client${NC} v${VERSION}

${BOLD}USAGE:${NC}
    $0 <command> <subcommand> [args...]

${BOLD}COMMANDS:${NC}
    ${CYAN}account${NC}    list|info|create|delete|suspend|unsuspend|change-plan
    ${CYAN}database${NC}   list|create|delete|user-add|user-delete
    ${CYAN}email${NC}      list|create|delete|forwarder-add|forwarder-delete
    ${CYAN}dns${NC}        list|zone|add-record|delete-record
    ${CYAN}ssl${NC}        list|generate|install|letsencrypt

${BOLD}ENVIRONMENT:${NC}
    CWP_HOST       CWP server hostname or IP
    CWP_API_KEY    CWP API key
    CWP_API_PORT   CWP API port (default: 2304)

${BOLD}CONFIG:${NC}
    Reads from: ${CONFIG_FILE}
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
case "${1:-}" in
    account)  shift; cmd_account "$@" ;;
    database) shift; cmd_database "$@" ;;
    email)    shift; cmd_email "$@" ;;
    dns)      shift; cmd_dns "$@" ;;
    ssl)      shift; cmd_ssl "$@" ;;
    -h|--help|help|"") usage ;;
    *) die "Unknown command: $1. Use --help for usage." ;;
esac
