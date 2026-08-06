#!/usr/bin/env bash
# =============================================================================
# CWP API Tests - Test API connection and endpoints
# =============================================================================
# Usage: bash tests/test-api.sh [--host HOST] [--api-key KEY]
# Requires: curl, CWP API access
# =============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly CONFIG_FILE="${CWP_CLI_CONF:-$HOME/.cwp-cli.conf}"
readonly API_TIMEOUT=10

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

CWP_HOST="${CWP_HOST:-}"
CWP_API_KEY="${CWP_API_KEY:-}"
CWP_API_PORT="${CWP_API_PORT:-2304}"

# Test framework
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

pass() {
    ((TESTS_PASSED++)) || true
    echo -e "  ${GREEN}PASS${NC} $*"
}

fail() {
    ((TESTS_FAILED++)) || true
    echo -e "  ${RED}FAIL${NC} $*"
}

skip() {
    ((TESTS_SKIPPED++)) || true
    echo -e "  ${YELLOW}SKIP${NC} $*"
}

run_test() {
    local test_name="$1"
    shift
    ((TESTS_RUN++)) || true
    echo -e "${YELLOW}[TEST]${NC} $test_name"
    if "$@"; then
        pass "$test_name"
    else
        fail "$test_name"
    fi
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)     CWP_HOST="$2"; shift 2 ;;
        --api-key)  CWP_API_KEY="$2"; shift 2 ;;
        --api-port) CWP_API_PORT="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--host HOST] [--api-key KEY] [--api-port PORT]"
            exit 0
            ;;
        *) shift ;;
    esac
done

# ---------------------------------------------------------------------------
# API helper
# ---------------------------------------------------------------------------
api_get() {
    local endpoint="$1"
    curl -sS --max-time "$API_TIMEOUT" \
        -H "Authorization: Bearer ${CWP_API_KEY}" \
        -H "Content-Type: application/json" \
        "https://${CWP_HOST}:${CWP_API_PORT}/${endpoint}" 2>&1
}

# ---------------------------------------------------------------------------
# Test: Configuration
# ---------------------------------------------------------------------------
test_host_configured() {
    [[ -n "$CWP_HOST" ]]
}

test_api_key_configured() {
    [[ -n "$CWP_API_KEY" ]]
}

test_api_port_configured() {
    [[ -n "$CWP_API_PORT" ]]
}

# ---------------------------------------------------------------------------
# Test: Connectivity
# ---------------------------------------------------------------------------
test_server_reachable() {
    ping -c 1 -W 3 "$CWP_HOST" &>/dev/null || \
        curl -sS --max-time 5 "https://${CWP_HOST}:${CWP_API_PORT}" &>/dev/null || \
        curl -sS --max-time 5 "http://${CWP_HOST}" &>/dev/null
}

test_api_port_open() {
    # Try to connect to API port
    timeout 5 bash -c "echo >/dev/tcp/${CWP_HOST}/${CWP_API_PORT}" 2>/dev/null || \
        curl -sS --max-time 5 "https://${CWP_HOST}:${CWP_API_PORT}" &>/dev/null
}

test_api_responds() {
    local response
    response=$(api_get "v1/test" 2>&1) || true
    # Any response (even error) means the API is responding
    [[ -n "$response" ]]
}

# ---------------------------------------------------------------------------
# Test: Authentication
# ---------------------------------------------------------------------------
test_api_auth() {
    local response
    response=$(api_get "v1/test" 2>&1) || true
    # Should not return 401/403
    ! echo "$response" | grep -qi "unauthorized\|forbidden\|401\|403"
}

test_api_invalid_key() {
    local response
    response=$(curl -sS --max-time "$API_TIMEOUT" \
        -H "Authorization: Bearer INVALID_KEY_12345" \
        "https://${CWP_HOST}:${CWP_API_PORT}/v1/test" 2>&1) || true
    # Should return an error for invalid key
    echo "$response" | grep -qi "error\|invalid\|unauthorized\|401\|403"
}

# ---------------------------------------------------------------------------
# Test: API Endpoints
# ---------------------------------------------------------------------------
test_account_endpoint() {
    local response
    response=$(api_get "v1/account/list" 2>&1) || true
    [[ -n "$response" ]] && ! echo "$response" | grep -qi "not found\|404"
}

test_database_endpoint() {
    local response
    response=$(api_get "v1/database/list" 2>&1) || true
    [[ -n "$response" ]] && ! echo "$response" | grep -qi "not found\|404"
}

test_email_endpoint() {
    local response
    response=$(api_get "v1/email/domains" 2>&1) || true
    [[ -n "$response" ]] && ! echo "$response" | grep -qi "not found\|404"
}

test_dns_endpoint() {
    local response
    response=$(api_get "v1/dns/list" 2>&1) || true
    [[ -n "$response" ]] && ! echo "$response" | grep -qi "not found\|404"
}

test_ssl_endpoint() {
    local response
    response=$(api_get "v1/ssl/list" 2>&1) || true
    [[ -n "$response" ]] && ! echo "$response" | grep -qi "not found\|404"
}

# ---------------------------------------------------------------------------
# Test: API Response Format
# ---------------------------------------------------------------------------
test_api_returns_json() {
    local response
    response=$(api_get "v1/test" 2>&1) || true
    # Check if response looks like JSON
    echo "$response" | grep -qE '^\{|^\[' || \
        echo "$response" | grep -qi "success\|error\|status"
}

# ---------------------------------------------------------------------------
# Test: API Client Script
# ---------------------------------------------------------------------------
test_api_client_exists() {
    [[ -f "${PLUGIN_ROOT}/scripts/cwp-api-client.sh" ]]
}

test_api_client_is_bash() {
    head -1 "${PLUGIN_ROOT}/scripts/cwp-api-client.sh" | grep -q "bash"
}

test_api_client_has_commands() {
    local content
    content=$(cat "${PLUGIN_ROOT}/scripts/cwp-api-client.sh")
    echo "$content" | grep -q "account" && \
    echo "$content" | grep -q "database" && \
    echo "$content" | grep -q "email" && \
    echo "$content" | grep -q "dns" && \
    echo "$content" | grep -q "ssl"
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== CWP API Tests ===${NC}"
echo "  Host: ${CWP_HOST:-NOT SET}"
echo "  Port: ${CWP_API_PORT}"
echo "  Key:  ${CWP_API_KEY:+****}${CWP_API_KEY:-NOT SET}"
echo ""

echo -e "${BOLD}--- Configuration Tests ---${NC}"
if test_host_configured; then
    run_test "Host configured" test_host_configured
else
    run_test "Host configured" test_host_configured
    echo -e "\n${RED}CWP_HOST not set. Use --host or set in $CONFIG_FILE${NC}"
    echo "Skipping remaining tests."
    echo ""
    echo -e "${BOLD}=== Test Summary ===${NC}"
    echo -e "  Total:    $TESTS_RUN"
    echo -e "  ${GREEN}Passed:   $TESTS_PASSED${NC}"
    echo -e "  ${RED}Failed:   $TESTS_FAILED${NC}"
    echo -e "  ${YELLOW}Skipped:  $((TESTS_RUN - TESTS_PASSED - TESTS_FAILED))${NC}"
    exit 1
fi

run_test "API key configured" test_api_key_configured
run_test "API port configured" test_api_port_configured

echo ""
echo -e "${BOLD}--- Connectivity Tests ---${NC}"
run_test "Server reachable" test_server_reachable
run_test "API port open" test_api_port_open
run_test "API responds" test_api_responds

echo ""
echo -e "${BOLD}--- Authentication Tests ---${NC}"
if test_api_key_configured; then
    run_test "API authentication works" test_api_auth
    run_test "Invalid key rejected" test_api_invalid_key
else
    skip "API authentication works (no key)"
    skip "Invalid key rejected (no key)"
fi

echo ""
echo -e "${BOLD}--- Endpoint Tests ---${NC}"
if test_api_key_configured; then
    run_test "Account endpoint" test_account_endpoint
    run_test "Database endpoint" test_database_endpoint
    run_test "Email endpoint" test_email_endpoint
    run_test "DNS endpoint" test_dns_endpoint
    run_test "SSL endpoint" test_ssl_endpoint
else
    skip "Account endpoint (no key)"
    skip "Database endpoint (no key)"
    skip "Email endpoint (no key)"
    skip "DNS endpoint (no key)"
    skip "SSL endpoint (no key)"
fi

echo ""
echo -e "${BOLD}--- Response Format Tests ---${NC}"
if test_api_key_configured; then
    run_test "API returns valid response" test_api_returns_json
else
    skip "API returns valid response (no key)"
fi

echo ""
echo -e "${BOLD}--- API Client Script Tests ---${NC}"
run_test "API client script exists" test_api_client_exists
run_test "API client is bash script" test_api_client_is_bash
run_test "API client has all commands" test_api_client_has_commands

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== Test Summary ===${NC}"
echo -e "  Total:    $TESTS_RUN"
echo -e "  ${GREEN}Passed:   $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed:   $TESTS_FAILED${NC}"
echo -e "  ${YELLOW}Skipped:  $TESTS_SKIPPED${NC}"
echo ""

if [[ "$TESTS_FAILED" -gt 0 ]]; then
    echo -e "${RED}${BOLD}SOME TESTS FAILED${NC}"
    exit 1
elif [[ "$TESTS_SKIPPED" -gt 0 ]]; then
    echo -e "${YELLOW}${BOLD}TESTS PASSED (with skips)${NC}"
    exit 0
else
    echo -e "${GREEN}${BOLD}ALL TESTS PASSED${NC}"
    exit 0
fi
