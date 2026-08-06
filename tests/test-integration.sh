#!/usr/bin/env bash
# =============================================================================
# CWP Integration Tests - Test full workflows
# =============================================================================
# Usage: bash tests/test-integration.sh [--host HOST] [--api-key KEY]
# Requires: CWP server access (SSH and/or API)
# =============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly CONFIG_FILE="${CWP_CLI_CONF:-$HOME/.cwp-cli.conf}"

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

CWP_HOST="${CWP_HOST:-}"
CWP_API_KEY="${CWP_API_KEY:-}"
CWP_API_PORT="${CWP_API_PORT:-2304}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"

# Test framework
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

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
        --ssh-user) SSH_USER="$2"; shift 2 ;;
        --ssh-port) SSH_PORT="$2"; shift 2 ;;
        --ssh-key)  SSH_KEY="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--host HOST] [--api-key KEY] [--ssh-user USER]"
            exit 0
            ;;
        *) shift ;;
    esac
done

# SSH helper
remote_exec() {
    local cmd=("ssh" "-o" "StrictHostKeyChecking=no" "-o" "ConnectTimeout=10" "-o" "BatchMode=yes")
    [[ -n "$SSH_KEY" ]] && cmd+=("-i" "$SSH_KEY")
    cmd+=("-p" "$SSH_PORT" "${SSH_USER}@${CWP_HOST}")
    "${cmd[@]}" "$@" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Test: Plugin Structure
# ---------------------------------------------------------------------------
test_plugin_root_exists() {
    [[ -d "$PLUGIN_ROOT" ]]
}

test_cli_directory() {
    [[ -d "${PLUGIN_ROOT}/cli" ]]
}

test_scripts_directory() {
    [[ -d "${PLUGIN_ROOT}/scripts" ]]
}

test_templates_directory() {
    [[ -d "${PLUGIN_ROOT}/templates" ]]
}

test_examples_directory() {
    [[ -d "${PLUGIN_ROOT}/examples" ]]
}

test_tests_directory() {
    [[ -d "${PLUGIN_ROOT}/tests" ]]
}

# ---------------------------------------------------------------------------
# Test: File Counts
# ---------------------------------------------------------------------------
test_cli_file_count() {
    local count
    count=$(find "${PLUGIN_ROOT}/cli" -type f | wc -l)
    [[ "$count" -ge 3 ]]
}

test_scripts_file_count() {
    local count
    count=$(find "${PLUGIN_ROOT}/scripts" -type f -name "*.sh" | wc -l)
    [[ "$count" -ge 6 ]]
}

test_templates_file_count() {
    local count
    count=$(find "${PLUGIN_ROOT}/templates" -type f | wc -l)
    [[ "$count" -ge 7 ]]
}

test_examples_file_count() {
    local count
    count=$(find "${PLUGIN_ROOT}/examples" -type f -name "*.sh" | wc -l)
    [[ "$count" -ge 5 ]]
}

# ---------------------------------------------------------------------------
# Test: SSH Connection (requires server)
# ---------------------------------------------------------------------------
test_ssh_connection() {
    [[ -n "$CWP_HOST" ]] || return 1
    remote_exec "echo ok" | grep -q "ok"
}

test_ssh_sudo() {
    [[ -n "$CWP_HOST" ]] || return 1
    remote_exec "sudo whoami" | grep -q "root"
}

# ---------------------------------------------------------------------------
# Test: Remote Services (requires server)
# ---------------------------------------------------------------------------
test_remote_cwp_running() {
    [[ -n "$CWP_HOST" ]] || return 1
    remote_exec "systemctl is-active cwpsrv" | grep -q "active"
}

test_remote_httpd_running() {
    [[ -n "$CWP_HOST" ]] || return 1
    remote_exec "systemctl is-active httpd" | grep -q "active"
}

test_remote_mysql_running() {
    [[ -n "$CWP_HOST" ]] || return 1
    remote_exec "systemctl is-active mysql || systemctl is-active mariadb" | grep -q "active"
}

test_remote_postfix_running() {
    [[ -n "$CWP_HOST" ]] || return 1
    remote_exec "systemctl is-active postfix" | grep -q "active"
}

# ---------------------------------------------------------------------------
# Test: CLI Installation Workflow
# ---------------------------------------------------------------------------
test_install_script_exists() {
    [[ -f "${PLUGIN_ROOT}/scripts/install.sh" ]]
}

test_uninstall_script_exists() {
    [[ -f "${PLUGIN_ROOT}/scripts/uninstall.sh" ]]
}

test_setup_script_exists() {
    [[ -f "${PLUGIN_ROOT}/scripts/setup.sh" ]]
}

# ---------------------------------------------------------------------------
# Test: Template Variables
# ---------------------------------------------------------------------------
test_templates_have_variables() {
    local all_ok=true
    for tpl in "${PLUGIN_ROOT}/templates/"*.tpl; do
        if ! grep -q '{{' "$tpl"; then
            echo "  No variables in: $(basename "$tpl")"
            all_ok=false
        fi
    done
    $all_ok
}

test_vhost_apache_has_domain_var() {
    grep -q '{{DOMAIN}}' "${PLUGIN_ROOT}/templates/vhost-apache.tpl"
}

test_vhost_nginx_has_domain_var() {
    grep -q '{{DOMAIN}}' "${PLUGIN_ROOT}/templates/vhost-nginx.tpl"
}

test_dns_zone_has_records() {
    grep -q 'SOA\|A \|MX\|TXT' "${PLUGIN_ROOT}/templates/dns-zone.tpl"
}

# ---------------------------------------------------------------------------
# Test: Documentation
# ---------------------------------------------------------------------------
test_readme_exists() {
    [[ -f "${PLUGIN_ROOT}/README.md" ]]
}

test_changelog_exists() {
    [[ -f "${PLUGIN_ROOT}/CHANGELOG.md" ]]
}

test_license_exists() {
    [[ -f "${PLUGIN_ROOT}/LICENSE" ]]
}

test_contributing_exists() {
    [[ -f "${PLUGIN_ROOT}/CONTRIBUTING.md" ]]
}

test_config_json_exists() {
    [[ -f "${PLUGIN_ROOT}/config.json" ]]
}

# ---------------------------------------------------------------------------
# Test: Workflow - Backup Verification (local)
# ---------------------------------------------------------------------------
test_backup_verify_script() {
    [[ -f "${PLUGIN_ROOT}/scripts/cwp-backup-verify.sh" ]]
    grep -q "verify_local\|verify_remote\|tar -tzf" "${PLUGIN_ROOT}/scripts/cwp-backup-verify.sh"
}

# ---------------------------------------------------------------------------
# Test: Workflow - Security Scan (local check)
# ---------------------------------------------------------------------------
test_security_scan_script() {
    [[ -f "${PLUGIN_ROOT}/scripts/cwp-security-scan.sh" ]]
    grep -q "scan_ssh\|scan_firewall\|scan_ssl" "${PLUGIN_ROOT}/scripts/cwp-security-scan.sh"
}

# ---------------------------------------------------------------------------
# Test: Workflow - Health Check (local check)
# ---------------------------------------------------------------------------
test_health_check_script() {
    [[ -f "${PLUGIN_ROOT}/scripts/cwp-health-check.sh" ]]
    grep -q "check_services\|check_disk\|check_memory" "${PLUGIN_ROOT}/scripts/cwp-health-check.sh"
}

# ---------------------------------------------------------------------------
# Test: Remote Execution Script
# ---------------------------------------------------------------------------
test_remote_exec_script() {
    [[ -f "${PLUGIN_ROOT}/scripts/cwp-remote-exec.sh" ]]
    grep -q "remote_exec\|scp\|ssh" "${PLUGIN_ROOT}/scripts/cwp-remote-exec.sh"
}

# ---------------------------------------------------------------------------
# Test: Example Scripts
# ---------------------------------------------------------------------------
test_example_install_cwp() {
    [[ -f "${PLUGIN_ROOT}/examples/install-cwp.sh" ]]
    grep -q "AlmaLinux\|CWP\|cwp" "${PLUGIN_ROOT}/examples/install-cwp.sh"
}

test_example_create_account() {
    [[ -f "${PLUGIN_ROOT}/examples/create-account.sh" ]]
    grep -q "DOMAIN\|USERNAME\|account" "${PLUGIN_ROOT}/examples/create-account.sh"
}

test_example_setup_email() {
    [[ -f "${PLUGIN_ROOT}/examples/setup-email.sh" ]]
    grep -q "DKIM\|SPF\|Postfix" "${PLUGIN_ROOT}/examples/setup-email.sh"
}

test_example_configure_ssl() {
    [[ -f "${PLUGIN_ROOT}/examples/configure-ssl.sh" ]]
    grep -q "certbot\|SSL\|letsencrypt" "${PLUGIN_ROOT}/examples/configure-ssl.sh"
}

test_example_security_hardening() {
    [[ -f "${PLUGIN_ROOT}/examples/security-hardening.sh" ]]
    grep -q "SSH\|firewall\|fail2ban" "${PLUGIN_ROOT}/examples/security-hardening.sh"
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== CWP Integration Tests ===${NC}"
echo "  Server: ${CWP_HOST:-LOCAL ONLY}"
echo "  Date:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

echo -e "${BOLD}--- Plugin Structure Tests ---${NC}"
run_test "Plugin root directory" test_plugin_root_exists
run_test "CLI directory" test_cli_directory
run_test "Scripts directory" test_scripts_directory
run_test "Templates directory" test_templates_directory
run_test "Examples directory" test_examples_directory
run_test "Tests directory" test_tests_directory

echo ""
echo -e "${BOLD}--- File Count Tests ---${NC}"
run_test "CLI files >= 3" test_cli_file_count
run_test "Script files >= 6" test_scripts_file_count
run_test "Template files >= 7" test_templates_file_count
run_test "Example files >= 5" test_examples_file_count

echo ""
echo -e "${BOLD}--- CLI Installation Tests ---${NC}"
run_test "Install script exists" test_install_script_exists
run_test "Uninstall script exists" test_uninstall_script_exists
run_test "Setup script exists" test_setup_script_exists

echo ""
echo -e "${BOLD}--- Template Tests ---${NC}"
run_test "Templates have variables" test_templates_have_variables
run_test "Apache vhost has DOMAIN var" test_vhost_apache_has_domain_var
run_test "Nginx vhost has DOMAIN var" test_vhost_nginx_has_domain_var
run_test "DNS zone has records" test_dns_zone_has_records

echo ""
echo -e "${BOLD}--- Documentation Tests ---${NC}"
run_test "README.md exists" test_readme_exists
run_test "CHANGELOG.md exists" test_changelog_exists
run_test "LICENSE exists" test_license_exists
run_test "CONTRIBUTING.md exists" test_contributing_exists
run_test "config.json exists" test_config_json_exists

echo ""
echo -e "${BOLD}--- Script Workflow Tests ---${NC}"
run_test "Backup verification script" test_backup_verify_script
run_test "Security scan script" test_security_scan_script
run_test "Health check script" test_health_check_script
run_test "Remote execution script" test_remote_exec_script

echo ""
echo -e "${BOLD}--- Example Script Tests ---${NC}"
run_test "Install CWP example" test_example_install_cwp
run_test "Create account example" test_example_create_account
run_test "Setup email example" test_example_setup_email
run_test "Configure SSL example" test_example_configure_ssl
run_test "Security hardening example" test_example_security_hardening

# Remote tests (only if server configured)
echo ""
echo -e "${BOLD}--- Remote Server Tests ---${NC}"
if [[ -n "$CWP_HOST" ]]; then
    run_test "SSH connection" test_ssh_connection
    run_test "SSH sudo access" test_ssh_sudo
    run_test "CWP service running" test_remote_cwp_running
    run_test "Apache running" test_remote_httpd_running
    run_test "MySQL running" test_remote_mysql_running
    run_test "Postfix running" test_remote_postfix_running
else
    skip "SSH connection (no host)"
    skip "SSH sudo access (no host)"
    skip "CWP service running (no host)"
    skip "Apache running (no host)"
    skip "MySQL running (no host)"
    skip "Postfix running (no host)"
fi

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
else
    echo -e "${GREEN}${BOLD}ALL TESTS PASSED${NC}"
    exit 0
fi
