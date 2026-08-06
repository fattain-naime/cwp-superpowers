#!/usr/bin/env bash
# =============================================================================
# CWP Remote Execution - Execute commands on CWP server via SSH
# =============================================================================
# Usage: cwp-remote-exec.sh [options] <command>
# =============================================================================
set -euo pipefail

readonly VERSION="1.0.0"
readonly CONFIG_FILE="${CWP_CLI_CONF:-$HOME/.cwp-cli.conf}"
readonly SSH_TIMEOUT=10

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

CWP_HOST="${CWP_HOST:-}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()       { log_error "$@"; exit 1; }

# ---------------------------------------------------------------------------
# Build SSH command
# ---------------------------------------------------------------------------
build_ssh_cmd() {
    local cmd=("ssh" "-o" "StrictHostKeyChecking=accept-new"
               "-o" "ConnectTimeout=$SSH_TIMEOUT"
               "-o" "BatchMode=yes"
               "-o" "ServerAliveInterval=30"
               "-o" "ServerAliveCountMax=3")

    [[ -n "$SSH_KEY" ]] && cmd+=("-i" "$SSH_KEY")
    cmd+=("-p" "$SSH_PORT" "${SSH_USER}@${CWP_HOST}")
    echo "${cmd[@]}"
}

# ---------------------------------------------------------------------------
# Execute remote command
# ---------------------------------------------------------------------------
remote_exec() {
    [[ -z "$CWP_HOST" ]] && die "CWP_HOST not set. Run setup or export CWP_HOST."

    local ssh_cmd
    read -ra ssh_cmd <<< "$(build_ssh_cmd)"

    if [[ "$VERBOSE" -eq 1 ]]; then
        log_info "Executing on ${SSH_USER}@${CWP_HOST}: $*"
    fi

    "${ssh_cmd[@]}" "$@"
}

# ---------------------------------------------------------------------------
# Execute with sudo
# ---------------------------------------------------------------------------
remote_exec_sudo() {
    [[ -z "$CWP_HOST" ]] && die "CWP_HOST not set."

    local ssh_cmd
    read -ra ssh_cmd <<< "$(build_ssh_cmd)"

    if [[ "$VERBOSE" -eq 1 ]]; then
        log_info "Executing (sudo) on ${SSH_USER}@${CWP_HOST}: $*"
    fi

    "${ssh_cmd[@]}" "sudo bash -c '$*'"
}

# ---------------------------------------------------------------------------
# File transfer helpers
# ---------------------------------------------------------------------------
remote_upload() {
    local local_path="$1" remote_path="$2"
    [[ -z "$CWP_HOST" ]] && die "CWP_HOST not set."
    [[ ! -f "$local_path" ]] && die "Local file not found: $local_path"

    local scp_cmd=("scp" "-o" "StrictHostKeyChecking=accept-new"
                   "-o" "ConnectTimeout=$SSH_TIMEOUT"
                   "-P" "$SSH_PORT")
    [[ -n "$SSH_KEY" ]] && scp_cmd+=("-i" "$SSH_KEY")

    log_info "Uploading $local_path to ${SSH_USER}@${CWP_HOST}:${remote_path}"
    "${scp_cmd[@]}" "$local_path" "${SSH_USER}@${CWP_HOST}:${remote_path}"
}

remote_download() {
    local remote_path="$1" local_path="$2"
    [[ -z "$CWP_HOST" ]] && die "CWP_HOST not set."

    local scp_cmd=("scp" "-o" "StrictHostKeyChecking=accept-new"
                   "-o" "ConnectTimeout=$SSH_TIMEOUT"
                   "-P" "$SSH_PORT")
    [[ -n "$SSH_KEY" ]] && scp_cmd+=("-i" "$SSH_KEY")

    log_info "Downloading ${SSH_USER}@${CWP_HOST}:${remote_path} to $local_path"
    "${scp_cmd[@]}" "${SSH_USER}@${CWP_HOST}:${remote_path}" "$local_path"
}

# ---------------------------------------------------------------------------
# Interactive shell
# ---------------------------------------------------------------------------
remote_shell() {
    [[ -z "$CWP_HOST" ]] && die "CWP_HOST not set."

    local ssh_cmd
    read -ra ssh_cmd <<< "$(build_ssh_cmd)"
    # Remove BatchMode for interactive
    local interactive_cmd=()
    for arg in "${ssh_cmd[@]}"; do
        [[ "$arg" == "BatchMode=yes" ]] && continue
        interactive_cmd+=("$arg")
    done

    log_info "Opening interactive shell on ${SSH_USER}@${CWP_HOST}"
    exec "${interactive_cmd[@]}"
}

# ---------------------------------------------------------------------------
# Run script on remote
# ---------------------------------------------------------------------------
remote_run_script() {
    local script_path="$1"
    shift
    [[ ! -f "$script_path" ]] && die "Script not found: $script_path"

    log_info "Running script on remote: $script_path"
    local ssh_cmd
    read -ra ssh_cmd <<< "$(build_ssh_cmd)"
    "${ssh_cmd[@]}" "bash -s -- $*" < "$script_path"
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}CWP Remote Execution${NC} v${VERSION}

${BOLD}USAGE:${NC}
    $0 [options] <command> [args...]
    $0 --upload <local-file> <remote-path>
    $0 --download <remote-path> <local-file>
    $0 --shell
    $0 --script <local-script> [args...]

${BOLD}OPTIONS:${NC}
    --host <host>      CWP server hostname or IP
    --ssh-user <user>  SSH username (default: root)
    --ssh-port <port>  SSH port (default: 22)
    --ssh-key <path>   SSH private key file
    --sudo             Execute with sudo
    --verbose          Show command being executed
    -h, --help         Show this help

${BOLD}MODES:${NC}
    (default)          Execute a command via SSH
    --upload           Upload a file via SCP
    --download         Download a file via SCP
    --shell            Open interactive SSH session
    --script           Execute a local script on remote server

${BOLD}CONFIG:${NC}
    Reads from: ${CONFIG_FILE}

${BOLD}EXAMPLES:${NC}
    $0 'systemctl status httpd'
    $0 --sudo 'yum update -y'
    $0 --upload ./config.txt /etc/myconfig.txt
    $0 --download /var/log/messages ./messages.log
    $0 --script ./maintenance.sh arg1 arg2
    $0 --shell
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
VERBOSE=0
USE_SUDO=0
MODE="exec"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)      CWP_HOST="$2"; shift 2 ;;
        --ssh-user)  SSH_USER="$2"; shift 2 ;;
        --ssh-port)  SSH_PORT="$2"; shift 2 ;;
        --ssh-key)   SSH_KEY="$2"; shift 2 ;;
        --sudo)      USE_SUDO=1; shift ;;
        --verbose)   VERBOSE=1; shift ;;
        --upload)    MODE="upload"; shift; break ;;
        --download)  MODE="download"; shift; break ;;
        --shell)     MODE="shell"; shift ;;
        --script)    MODE="script"; shift; break ;;
        -h|--help)   usage; exit 0 ;;
        -*)          die "Unknown option: $1" ;;
        *)           POSITIONAL+=("$1"); shift ;;
    esac
done

case "$MODE" in
    exec)
        [[ ${#POSITIONAL[@]} -eq 0 ]] && die "No command specified. Use --help for usage."
        if [[ "$USE_SUDO" -eq 1 ]]; then
            remote_exec_sudo "${POSITIONAL[*]}"
        else
            remote_exec "${POSITIONAL[@]}"
        fi
        ;;
    upload)
        [[ ${#POSITIONAL[@]} -lt 2 ]] && die "Usage: $0 --upload <local> <remote>"
        remote_upload "${POSITIONAL[0]}" "${POSITIONAL[1]}"
        ;;
    download)
        [[ ${#POSITIONAL[@]} -lt 2 ]] && die "Usage: $0 --download <remote> <local>"
        remote_download "${POSITIONAL[0]}" "${POSITIONAL[1]}"
        ;;
    shell)
        remote_shell
        ;;
    script)
        [[ ${#POSITIONAL[@]} -eq 0 ]] && die "No script specified."
        remote_run_script "${POSITIONAL[@]}"
        ;;
esac
