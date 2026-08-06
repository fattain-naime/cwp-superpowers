#!/usr/bin/env bash
# =============================================================================
# CWP CLI Tests - Unit tests for CLI commands
# =============================================================================
# Usage: bash tests/test-cli.sh
# Requires: CWP CLI installed and configured
# =============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly CWP_CMD="${PLUGIN_ROOT}/cli/cwp"

# Test framework
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------
pass() {
    ((TESTS_PASSED++)) || true
    echo -e "  ${GREEN}PASS${NC} $*"
}

fail() {
    ((TESTS_FAILED++)) || true
    echo -e "  ${RED}FAIL${NC} $*"
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
# Test: CLI exists and is executable
# ---------------------------------------------------------------------------
test_cli_exists() {
    [[ -x "$CWP_CMD" ]] || [[ -f "$CWP_CMD" ]]
}

test_cli_is_bash() {
    head -1 "$CWP_CMD" | grep -q "bash"
}

# ---------------------------------------------------------------------------
# Test: Help output
# ---------------------------------------------------------------------------
test_help_flag() {
    local output
    output=$(bash "$CWP_CMD" --help 2>&1)
    echo "$output" | grep -qi "usage\|USAGE"
}

test_help_short_flag() {
    local output
    output=$(bash "$CWP_CMD" -h 2>&1)
    echo "$output" | grep -qi "usage\|USAGE"
}

test_help_contains_commands() {
    local output
    output=$(bash "$CWP_CMD" --help 2>&1)
    echo "$output" | grep -q "status" && \
    echo "$output" | grep -q "user" && \
    echo "$output" | grep -q "database" && \
    echo "$output" | grep -q "email" && \
    echo "$output" | grep -q "dns" && \
    echo "$output" | grep -q "ssl" && \
    echo "$output" | grep -q "security" && \
    echo "$output" | grep -q "backup" && \
    echo "$output" | grep -q "service" && \
    echo "$output" | grep -q "php" && \
    echo "$output" | grep -q "fix" && \
    echo "$output" | grep -q "optimize" && \
    echo "$output" | grep -q "migrate" && \
    echo "$output" | grep -q "logs"
}

test_help_contains_options() {
    local output
    output=$(bash "$CWP_CMD" --help 2>&1)
    echo "$output" | grep -q "\-\-host" && \
    echo "$output" | grep -q "\-\-api-key" && \
    echo "$output" | grep -q "\-\-ssh-user" && \
    echo "$output" | grep -q "\-\-ssh-port"
}

# ---------------------------------------------------------------------------
# Test: Version output
# ---------------------------------------------------------------------------
test_version_flag() {
    local output
    output=$(bash "$CWP_CMD" --version 2>&1)
    echo "$output" | grep -q "1.0.0"
}

test_version_short_flag() {
    local output
    output=$(bash "$CWP_CMD" -v 2>&1)
    echo "$output" | grep -q "1.0.0"
}

# ---------------------------------------------------------------------------
# Test: Unknown command handling
# ---------------------------------------------------------------------------
test_unknown_command() {
    local output exit_code=0
    output=$(bash "$CWP_CMD" nonexistent_command 2>&1) || exit_code=$?
    [[ "$exit_code" -ne 0 ]]
}

test_unknown_option() {
    local output exit_code=0
    output=$(bash "$CWP_CMD" --invalid-option 2>&1) || exit_code=$?
    [[ "$exit_code" -ne 0 ]]
}

# ---------------------------------------------------------------------------
# Test: User subcommand help
# ---------------------------------------------------------------------------
test_user_subcommands_exist() {
    local output
    output=$(bash "$CWP_CMD" --help 2>&1)
    echo "$output" | grep -q "list" && \
    echo "$output" | grep -q "info" && \
    echo "$output" | grep -q "add" && \
    echo "$output" | grep -q "delete" && \
    echo "$output" | grep -q "suspend" && \
    echo "$output" | grep -q "password"
}

# ---------------------------------------------------------------------------
# Test: Database subcommand help
# ---------------------------------------------------------------------------
test_database_subcommands_exist() {
    local output
    output=$(bash "$CWP_CMD" --help 2>&1)
    echo "$output" | grep -q "list" && \
    echo "$output" | grep -q "create" && \
    echo "$output" | grep -q "delete" && \
    echo "$output" | grep -q "backup" && \
    echo "$output" | grep -q "restore"
}

# ---------------------------------------------------------------------------
# Test: Config file handling
# ---------------------------------------------------------------------------
test_config_file_option() {
    local output
    output=$(bash "$CWP_CMD" --help 2>&1)
    echo "$output" | grep -q "cwp-cli.conf\|config\|\.conf"
}

# ---------------------------------------------------------------------------
# Test: Bash completion file
# ---------------------------------------------------------------------------
test_bash_completion_exists() {
    [[ -f "${PLUGIN_ROOT}/cli/cwp-completion.bash" ]]
}

test_bash_completion_valid() {
    grep -q "_cwp_complete" "${PLUGIN_ROOT}/cli/cwp-completion.bash"
}

# ---------------------------------------------------------------------------
# Test: Zsh completion file
# ---------------------------------------------------------------------------
test_zsh_completion_exists() {
    [[ -f "${PLUGIN_ROOT}/cli/cwp-completion.zsh" ]]
}

test_zsh_completion_valid() {
    grep -q "compdef\|#compdef" "${PLUGIN_ROOT}/cli/cwp-completion.zsh"
}

# ---------------------------------------------------------------------------
# Test: Scripts are valid bash
# ---------------------------------------------------------------------------
test_scripts_are_bash() {
    local all_ok=true
    for script in "${PLUGIN_ROOT}/scripts/"*.sh; do
        if ! head -1 "$script" | grep -q "bash"; then
            echo "  Not bash: $script"
            all_ok=false
        fi
    done
    $all_ok
}

test_scripts_have_error_handling() {
    local all_ok=true
    for script in "${PLUGIN_ROOT}/scripts/"*.sh; do
        if ! grep -q "set -e\|set -euo pipefail" "$script"; then
            echo "  Missing error handling: $script"
            all_ok=false
        fi
    done
    $all_ok
}

# ---------------------------------------------------------------------------
# Test: Templates exist
# ---------------------------------------------------------------------------
test_templates_exist() {
    local templates=(
        "vhost-apache.tpl"
        "vhost-nginx.tpl"
        "vhost-varnish.tpl"
        "dns-zone.tpl"
        "backup-config.tpl"
        "email-config.tpl"
        "php-fpm-pool.tpl"
    )
    local all_ok=true
    for tpl in "${templates[@]}"; do
        if [[ ! -f "${PLUGIN_ROOT}/templates/$tpl" ]]; then
            echo "  Missing: templates/$tpl"
            all_ok=false
        fi
    done
    $all_ok
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== CWP CLI Tests ===${NC}"
echo ""

echo -e "${BOLD}--- CLI File Tests ---${NC}"
run_test "CLI file exists" test_cli_exists
run_test "CLI is bash script" test_cli_is_bash

echo ""
echo -e "${BOLD}--- Help Output Tests ---${NC}"
run_test "--help shows usage" test_help_flag
run_test "-h shows usage" test_help_short_flag
run_test "Help lists all commands" test_help_contains_commands
run_test "Help lists all options" test_help_contains_options

echo ""
echo -e "${BOLD}--- Version Tests ---${NC}"
run_test "--version shows version" test_version_flag
run_test "-v shows version" test_version_short_flag

echo ""
echo -e "${BOLD}--- Error Handling Tests ---${NC}"
run_test "Unknown command fails" test_unknown_command
run_test "Unknown option fails" test_unknown_option

echo ""
echo -e "${BOLD}--- Subcommand Tests ---${NC}"
run_test "User subcommands documented" test_user_subcommands_exist
run_test "Database subcommands documented" test_database_subcommands_exist

echo ""
echo -e "${BOLD}--- Config Tests ---${NC}"
run_test "Config file mentioned in help" test_config_file_option

echo ""
echo -e "${BOLD}--- Completion Tests ---${NC}"
run_test "Bash completion file exists" test_bash_completion_exists
run_test "Bash completion is valid" test_bash_completion_valid
run_test "Zsh completion file exists" test_zsh_completion_exists
run_test "Zsh completion is valid" test_zsh_completion_valid

echo ""
echo -e "${BOLD}--- Script Quality Tests ---${NC}"
run_test "All scripts use bash" test_scripts_are_bash
run_test "All scripts have error handling" test_scripts_have_error_handling

echo ""
echo -e "${BOLD}--- Template Tests ---${NC}"
run_test "All templates exist" test_templates_exist

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== Test Summary ===${NC}"
echo -e "  Total:  $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [[ "$TESTS_FAILED" -gt 0 ]]; then
    echo -e "${RED}${BOLD}TESTS FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}${BOLD}ALL TESTS PASSED${NC}"
    exit 0
fi
