#!/usr/bin/env bash
# =============================================================================
# CWP AI Agent Plugin - Uninstaller
# =============================================================================
set -euo pipefail

readonly VERSION="1.0.0"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

echo -e "${BOLD}CWP AI Agent Plugin - Uninstaller v${VERSION}${NC}"
echo ""

# Confirm
read -rp "This will remove the CWP CLI and related files. Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

# Remove CLI
if [[ -f /usr/local/bin/cwp ]]; then
    rm -f /usr/local/bin/cwp
    log_info "Removed /usr/local/bin/cwp"
fi

# Remove completions
if [[ -f /etc/bash_completion.d/cwp ]]; then
    rm -f /etc/bash_completion.d/cwp
    log_info "Removed bash completion"
fi

if [[ -f /usr/local/share/zsh/site-functions/_cwp ]]; then
    rm -f /usr/local/share/zsh/site-functions/_cwp
    log_info "Removed zsh completion"
fi

# Ask about config
read -rp "Remove configuration file (~/.cwp-cli.conf)? (y/N): " remove_conf
if [[ "$remove_conf" == "y" || "$remove_conf" == "Y" ]]; then
    rm -f "$HOME/.cwp-cli.conf"
    log_info "Removed configuration file."
else
    log_info "Configuration file kept."
fi

# Ask about node_modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -d "${PLUGIN_ROOT}/node_modules" ]]; then
    read -rp "Remove node_modules? (y/N): " remove_nm
    if [[ "$remove_nm" == "y" || "$remove_nm" == "Y" ]]; then
        rm -rf "${PLUGIN_ROOT}/node_modules"
        log_info "Removed node_modules."
    fi
fi

echo ""
echo -e "${GREEN}Uninstall complete.${NC}"
echo "Note: Plugin source files at ${PLUGIN_ROOT} were not removed."
echo "Delete that directory manually if no longer needed."
