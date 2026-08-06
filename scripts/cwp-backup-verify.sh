#!/usr/bin/env bash
# =============================================================================
# CWP Backup Verification - Verify integrity of CWP backup archives
# =============================================================================
# Usage: cwp-backup-verify.sh [options] <backup-file>
# =============================================================================
set -euo pipefail

readonly VERSION="1.0.0"
readonly CONFIG_FILE="${CWP_CLI_CONF:-$HOME/.cwp-cli.conf}"

# Load config for remote operations
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

CWP_HOST="${CWP_HOST:-}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log_info()    { echo -e "${GREEN}[PASS]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $*"; }
log_header()  { echo -e "\n${BOLD}${BLUE}=== $* ===${NC}"; }
log_check()   { echo -e "  ${BLUE}[CHECK]${NC} $*"; }
die()         { log_error "$@"; exit 1; }

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

inc_pass() { ((PASS_COUNT++)) || true; }
inc_fail() { ((FAIL_COUNT++)) || true; }
inc_warn() { ((WARN_COUNT++)) || true; }

# ---------------------------------------------------------------------------
# SSH helper
# ---------------------------------------------------------------------------
remote_exec() {
    local cmd=("ssh" "-o" "StrictHostKeyChecking=accept-new" "-o" "ConnectTimeout=10" "-o" "BatchMode=yes")
    [[ -n "$SSH_KEY" ]] && cmd+=("-i" "$SSH_KEY")
    cmd+=("-p" "$SSH_PORT" "${SSH_USER}@${CWP_HOST}")
    "${cmd[@]}" "$@" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Local file verification
# ---------------------------------------------------------------------------
verify_local() {
    local backup_file="$1"

    log_header "File Integrity Checks"

    # Check file exists
    log_check "File exists"
    if [[ -f "$backup_file" ]]; then
        log_info "File found: $backup_file"
        inc_pass
    else
        die "File not found: $backup_file"
    fi

    # Check file size
    local size
    size=$(stat -c%s "$backup_file" 2>/dev/null || stat -f%z "$backup_file" 2>/dev/null || echo "0")
    log_check "File size: $(numfmt --to=iec "$size" 2>/dev/null || echo "${size} bytes")"
    if [[ "$size" -gt 0 ]]; then
        log_info "File is not empty"
        inc_pass
    else
        log_error "File is empty (0 bytes)"
        inc_fail
    fi

    # Check tar integrity
    log_check "Tar archive integrity"
    if tar -tzf "$backup_file" >/dev/null 2>&1; then
        log_info "Archive is valid gzip-compressed tar"
        inc_pass
    elif tar -tf "$backup_file" >/dev/null 2>&1; then
        log_info "Archive is valid tar (not gzip)"
        inc_pass
    else
        log_error "Archive is corrupt or not a tar file"
        inc_fail
        return
    fi

    # Check file type
    log_check "File type verification"
    local filetype
    filetype=$(file "$backup_file" 2>/dev/null)
    echo "  Type: $filetype"
    if echo "$filetype" | grep -qi "gzip\|tar\|compressed"; then
        log_info "File type matches expected format"
        inc_pass
    else
        log_warn "Unexpected file type"
        inc_warn
    fi

    # List archive contents
    log_header "Archive Contents"
    local file_count
    file_count=$(tar -tzf "$backup_file" 2>/dev/null | wc -l)
    echo "  Total entries: $file_count"

    # Check for expected directories
    log_check "Expected directory structure"
    local contents
    contents=$(tar -tzf "$backup_file" 2>/dev/null)

    local has_public_html=0 has_etc=0 has_mysql=0 has_mail=0 has_cron=0
    echo "$contents" | grep -q "public_html" && has_public_html=1
    echo "$contents" | grep -q "\.etc\|/etc/" && has_etc=1
    echo "$contents" | grep -qi "mysql\|\.sql" && has_mysql=1
    echo "$contents" | grep -qi "mail\|\.maildir" && has_mail=1
    echo "$contents" | grep -qi "cron" && has_cron=1

    [[ "$has_public_html" -eq 1 ]] && log_info "Contains public_html" && inc_pass || { log_warn "No public_html found"; inc_warn; }
    [[ "$has_etc" -eq 1 ]] && log_info "Contains etc config" && inc_pass || { log_warn "No etc config found"; inc_warn; }
    [[ "$has_mysql" -eq 1 ]] && log_info "Contains MySQL data" && inc_pass || { log_warn "No MySQL data found"; inc_warn; }
    [[ "$has_mail" -eq 1 ]] && log_info "Contains mail data" && inc_pass || { log_warn "No mail data found"; inc_warn; }
    [[ "$has_cron" -eq 1 ]] && log_info "Contains cron jobs" && inc_pass || { log_warn "No cron jobs found"; inc_warn; }

    # Check for suspicious files
    log_header "Security Checks"
    log_check "Suspicious files"
    local suspicious
    suspicious=$(echo "$contents" | grep -iE '\.(php|pl|py|sh)$' | grep -iE 'eval|base64|shell|hack|exploit|c99|r57' || true)
    if [[ -n "$suspicious" ]]; then
        log_warn "Suspicious files detected:"
        echo "$suspicious" | head -10
        inc_warn
    else
        log_info "No suspicious files detected"
        inc_pass
    fi

    # Check total size when extracted
    log_check "Estimated extracted size"
    local extracted_size
    extracted_size=$(tar -tzf "$backup_file" 2>/dev/null | awk '{total += $3} END {print total}' 2>/dev/null || echo "unknown")
    if [[ "$extracted_size" != "unknown" && "$extracted_size" -gt 0 ]]; then
        echo "  Estimated: $(numfmt --to=iec "$extracted_size" 2>/dev/null || echo "${extracted_size} bytes")"
        inc_pass
    else
        echo "  Could not estimate extracted size"
        inc_warn
    fi
}

# ---------------------------------------------------------------------------
# Remote backup verification
# ---------------------------------------------------------------------------
verify_remote() {
    local backup_path="$1"

    log_header "Remote Backup Verification"
    echo "  Server: ${CWP_HOST}"
    echo "  File: ${backup_path}"

    # Check if file exists on remote
    log_check "Remote file exists"
    if remote_exec "test -f '$backup_path'" 2>/dev/null; then
        log_info "File exists on remote server"
        inc_pass
    else
        die "File not found on remote: $backup_path"
    fi

    # Check remote file size
    log_check "Remote file size"
    local remote_size
    remote_size=$(remote_exec "stat -c%s '$backup_path' 2>/dev/null" || echo "0")
    echo "  Size: $(numfmt --to=iec "$remote_size" 2>/dev/null || echo "${remote_size} bytes")"
    if [[ "$remote_size" -gt 0 ]]; then
        log_info "File is not empty"
        inc_pass
    else
        log_error "File is empty"
        inc_fail
    fi

    # Check tar integrity on remote
    log_check "Remote tar integrity"
    if remote_exec "tar -tzf '$backup_path' >/dev/null 2>&1"; then
        log_info "Archive integrity OK"
        inc_pass
    else
        log_error "Archive is corrupt on remote server"
        inc_fail
    fi

    # List remote contents
    log_check "Remote archive contents"
    local remote_count
    remote_count=$(remote_exec "tar -tzf '$backup_path' 2>/dev/null | wc -l")
    echo "  Entries: $remote_count"
    inc_pass

    # Check md5sum on remote
    log_check "Remote checksum"
    local remote_md5
    remote_md5=$(remote_exec "md5sum '$backup_path' 2>/dev/null | awk '{print \$1}'")
    echo "  MD5: $remote_md5"
    inc_pass
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print_summary() {
    echo ""
    echo -e "${BOLD}=== Verification Summary ===${NC}"
    echo -e "  ${GREEN}Passed:${NC}  $PASS_COUNT"
    echo -e "  ${RED}Failed:${NC}  $FAIL_COUNT"
    echo -e "  ${YELLOW}Warnings:${NC} $WARN_COUNT"
    echo ""

    if [[ "$FAIL_COUNT" -gt 0 ]]; then
        echo -e "${RED}${BOLD}VERIFICATION FAILED${NC} - $FAIL_COUNT critical issue(s) found."
        exit 1
    elif [[ "$WARN_COUNT" -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}VERIFICATION PASSED WITH WARNINGS${NC} - $WARN_COUNT warning(s)."
        exit 0
    else
        echo -e "${GREEN}${BOLD}VERIFICATION PASSED${NC} - All checks OK."
        exit 0
    fi
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}CWP Backup Verification${NC} v${VERSION}

${BOLD}USAGE:${NC}
    $0 [options] <backup-file>
    $0 --remote [options] <remote-path>

${BOLD}OPTIONS:${NC}
    --remote           Verify backup on remote CWP server
    --host <host>      CWP server hostname or IP
    --ssh-user <user>  SSH username (default: root)
    --ssh-port <port>  SSH port (default: 22)
    --ssh-key <path>   SSH private key file
    -h, --help         Show this help

${BOLD}EXAMPLES:${NC}
    $0 /backup/user_20260101.tar.gz
    $0 --remote --host 10.0.0.1 /backup/user_20260101.tar.gz
    $0 --remote /backup/*.tar.gz
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
MODE="local"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --remote)    MODE="remote"; shift ;;
        --host)      CWP_HOST="$2"; shift 2 ;;
        --ssh-user)  SSH_USER="$2"; shift 2 ;;
        --ssh-port)  SSH_PORT="$2"; shift 2 ;;
        --ssh-key)   SSH_KEY="$2"; shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        -*)          die "Unknown option: $1" ;;
        *)           POSITIONAL+=("$1"); shift ;;
    esac
done

[[ ${#POSITIONAL[@]} -eq 0 ]] && { usage; exit 1; }

echo -e "${BOLD}CWP Backup Verification v${VERSION}${NC}"
echo "  Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

case "$MODE" in
    local)
        for f in "${POSITIONAL[@]}"; do
            verify_local "$f"
        done
        ;;
    remote)
        [[ -z "$CWP_HOST" ]] && die "CWP_HOST required for remote verification."
        for f in "${POSITIONAL[@]}"; do
            verify_remote "$f"
        done
        ;;
esac

print_summary
